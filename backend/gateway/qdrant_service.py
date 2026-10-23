"""
RakshaNet Qdrant Vector DB & Visual Biometric Search Service.

Provides visual feature embedding extraction (512-D) and vector similarity search
for identifying and cross-referencing missing persons, disaster victims, and survivors.
"""

import io
import logging
import os
import re
import time
import urllib.request
import uuid
from base64 import b64decode
from pathlib import Path
from typing import Any, Dict, List, Optional, Union

import cv2
import httpx
import numpy as np
from dotenv import load_dotenv
from PIL import Image

# Load environment configuration
backend_env = Path(__file__).parent.parent / ".env"
load_dotenv(backend_env)

logger = logging.getLogger("rakshanet.qdrant")
if not logger.handlers:
    handler = logging.StreamHandler()
    handler.setFormatter(
        logging.Formatter("[%(asctime)s] [%(levelname)s] [QdrantService] %(message)s")
    )
    logger.addHandler(handler)
    logger.setLevel(logging.INFO)

DEFAULT_QDRANT_URL = "https://bb8c57f8-a718-473d-add8-7180143b3794.sa-east-1-0.aws.cloud.qdrant.io"
DEFAULT_QDRANT_API_KEY = (
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9."
    "eyJhY2Nlc3MiOiJtIiwic3ViamVjdCI6ImFwaS1rZXk6M2FiZjZiYzQtMzM0NS00ZTllLTk5MzgtODhiNTJjNjM0ZjNjIn0."
    "-WzpaQtV3568nDAw5ogdM7Fh8rsK6U54E1j8ic2vepw"
)
COLLECTION_NAME = "missing_persons"
VECTOR_SIZE = 512


def to_point_uuid(identifier: str) -> str:
    """Convert an arbitrary identifier into a deterministic UUID string for Qdrant point IDs."""
    try:
        return str(uuid.UUID(str(identifier)))
    except (ValueError, AttributeError):
        return str(uuid.uuid5(uuid.NAMESPACE_DNS, str(identifier)))


def decode_image_bytes(data: Union[bytes, str]) -> bytes:
    """
    Decodes image input from raw bytes, base64 strings, data URIs, or HTTP/HTTPS URLs.

    Args:
        data: Raw image bytes, data URI string, base64 string, or web URL.

    Returns:
        Raw image bytes.
    """
    if isinstance(data, bytes):
        return data

    if not isinstance(data, str) or not data.strip():
        raise ValueError("Invalid image input: data is empty or not string/bytes")

    data = data.strip()

    # Case 1: Web URL (http:// or https://)
    if data.startswith("http://") or data.startswith("https://"):
        req = urllib.request.Request(
            data,
            headers={"User-Agent": "RakshaNet-Biometric-Agent/1.0"}
        )
        with urllib.request.urlopen(req, timeout=10) as response:
            return response.read()

    # Case 2: Data URI (data:image/jpeg;base64,....)
    if data.startswith("data:") and ";base64," in data:
        base64_part = data.split(";base64,", 1)[1]
        return b64decode(base64_part)

    # Case 3: Raw base64 string
    try:
        # Check if looks like base64
        cleaned = re.sub(r"\s+", "", data)
        return b64decode(cleaned)
    except Exception as e:
        raise ValueError(f"Failed to decode base64 image data: {e}")


def extract_image_features(image_bytes: bytes) -> List[float]:
    """
    Extract a robust 512-dimensional visual feature embedding vector from image bytes.

    Architecture:
    1. Preprocessing: Resized to 224x224 RGB, HSV, and Grayscale representations.
    2. Spatial Color Moments (96 floats):
       - 4x4 spatial grid (16 blocks).
       - Mean and standard deviation computed across H, S, and V channels (6 values per block).
       - 16 blocks * 6 moments = 96 floats.
    3. Grayscale Gradient Orientations (256 floats):
       - Sobel horizontal and vertical gradients (ksize=3).
       - Polar magnitude and orientation angles [0..360 deg).
       - 4x4 spatial blocks (16 blocks).
       - Magnitude-weighted 16-bin orientation histogram per block.
       - 16 blocks * 16 bins = 256 floats.
    4. Luminance & Texture Distribution (160 floats):
       - 5 spatial zones (Top-Left, Top-Right, Bottom-Left, Bottom-Right, Center).
       - Zone luminance intensity histogram (16 bins, range 0..256) -> 5 * 16 = 80 floats.
       - Zone Laplacian texture magnitude histogram (16 bins, range 0..256) -> 5 * 16 = 80 floats.
       - 80 + 80 = 160 floats.
    5. Normalization:
       - Concatenated to 512-D vector and normalized with Euclidean L2 norm.

    Args:
        image_bytes: Raw bytes of the image file.

    Returns:
        List of 512 normalized float values.
    """
    try:
        pil_image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    except Exception as e:
        raise ValueError(f"Unable to parse image bytes with PIL: {e}")

    # Resize to standard canonical resolution: 224x224
    rgb_arr = np.array(pil_image)
    rgb_resized = cv2.resize(rgb_arr, (224, 224), interpolation=cv2.INTER_AREA)

    hsv_resized = cv2.cvtColor(rgb_resized, cv2.COLOR_RGB2HSV)
    gray_resized = cv2.cvtColor(rgb_resized, cv2.COLOR_RGB2GRAY)

    # 1. Spatial Color Moments in HSV (4x4 blocks = 16 blocks * 6 moments = 96 floats)
    color_moments: List[float] = []
    block_h = 56
    block_w = 56
    for r in range(4):
        for c in range(4):
            block = hsv_resized[r * block_h:(r + 1) * block_h, c * block_w:(c + 1) * block_w, :]
            for ch in range(3):
                ch_slice = block[:, :, ch].astype(np.float32)
                color_moments.append(float(np.mean(ch_slice)))
                color_moments.append(float(np.std(ch_slice)))

    # 2. Grayscale gradient orientations (Sobel/HOG spatial bins = 256 floats)
    gx = cv2.Sobel(gray_resized, cv2.CV_32F, 1, 0, ksize=3)
    gy = cv2.Sobel(gray_resized, cv2.CV_32F, 0, 1, ksize=3)
    mag, angle = cv2.cartToPolar(gx, gy, angleInDegrees=True)

    hog_features: List[float] = []
    for r in range(4):
        for c in range(4):
            b_mag = mag[r * block_h:(r + 1) * block_h, c * block_w:(c + 1) * block_w]
            b_ang = angle[r * block_h:(r + 1) * block_h, c * block_w:(c + 1) * block_w]
            hist, _ = np.histogram(b_ang, bins=16, range=(0.0, 360.0), weights=b_mag)
            hog_features.extend([float(v) for v in hist])

    # 3. Luminance & texture distribution (160 floats)
    # 5 Spatial Zones: 4 quadrants + center zone
    zones = [
        (0, 112, 0, 112),        # Top-Left
        (0, 112, 112, 224),      # Top-Right
        (112, 224, 0, 112),      # Bottom-Left
        (112, 224, 112, 224),    # Bottom-Right
        (56, 168, 56, 168),      # Center region
    ]
    laplacian = np.abs(cv2.Laplacian(gray_resized, cv2.CV_32F))

    texture_features: List[float] = []
    # 5 zones * 16 luminance bins = 80 floats
    for y1, y2, x1, x2 in zones:
        z_gray = gray_resized[y1:y2, x1:x2]
        lum_hist, _ = np.histogram(z_gray, bins=16, range=(0.0, 256.0))
        texture_features.extend([float(v) for v in lum_hist])

    # 5 zones * 16 texture bins = 80 floats
    for y1, y2, x1, x2 in zones:
        z_lap = laplacian[y1:y2, x1:x2]
        lap_hist, _ = np.histogram(z_lap, bins=16, range=(0.0, 256.0))
        texture_features.extend([float(v) for v in lap_hist])

    # Concatenate all components (96 + 256 + 160 = 512)
    embedding = np.array(color_moments + hog_features + texture_features, dtype=np.float32)

    if embedding.shape[0] != VECTOR_SIZE:
        raise ValueError(f"Feature vector dimension mismatch: expected {VECTOR_SIZE}, got {embedding.shape[0]}")

    # Euclidean L2 normalization
    norm = np.linalg.norm(embedding)
    if norm > 1e-8:
        embedding = embedding / norm

    return embedding.tolist()


class CollectionConfig:
    def __init__(self, data: dict):
        params = data.get("params", {})
        vectors = params.get("vectors", {})
        if isinstance(vectors, dict):
            size = vectors.get("size", 512)
            distance = vectors.get("distance", "Cosine")
        else:
            size = 512
            distance = "Cosine"
        self.params = type("Params", (), {
            "vectors": type("Vectors", (), {
                "size": size,
                "distance": distance,
            })()
        })()


class CollectionInfo:
    def __init__(self, data: dict):
        result = data.get("result", {})
        self.status = result.get("status", "ok")
        self.points_count = result.get("points_count", 0)
        self.config = CollectionConfig(result.get("config", {}))


class QdrantHttpClient:
    def __init__(self, base_url: str, api_key: str, timeout: float = 30.0):
        self.http = httpx.Client(
            base_url=base_url,
            headers={"api-key": api_key, "Content-Type": "application/json"},
            timeout=timeout,
        )

    def collection_exists(self, collection_name: str) -> bool:
        res = self.http.get(f"/collections/{collection_name}")
        return res.is_success and bool(res.json().get("result"))

    def get_collection(self, collection_name: str) -> CollectionInfo:
        res = self.http.get(f"/collections/{collection_name}")
        res.raise_for_status()
        return CollectionInfo(res.json())

    def get(self, *args, **kwargs):
        return self.http.get(*args, **kwargs)

    def post(self, *args, **kwargs):
        return self.http.post(*args, **kwargs)

    def put(self, *args, **kwargs):
        return self.http.put(*args, **kwargs)

    def delete(self, *args, **kwargs):
        return self.http.delete(*args, **kwargs)


class QdrantService:
    """Production client for Qdrant Cloud Vector Database visual search (REST API)."""

    def __init__(
        self,
        url: Optional[str] = None,
        api_key: Optional[str] = None,
        collection_name: str = COLLECTION_NAME,
        vector_size: int = VECTOR_SIZE,
    ):
        self.url = (url or os.getenv("QDRANT_URL", DEFAULT_QDRANT_URL)).rstrip("/")
        self.api_key = api_key or os.getenv("QDRANT_API_KEY", DEFAULT_QDRANT_API_KEY)
        self.collection_name = collection_name
        self.vector_size = vector_size

        logger.info(f"Connecting to Qdrant Vector Cloud: {self.url} (collection='{self.collection_name}')")
        self.client = QdrantHttpClient(
            base_url=self.url,
            api_key=self.api_key,
            timeout=30.0,
        )
        self._ensure_collection()

    def _ensure_collection(self) -> None:
        """Verify that the vector collection exists; create it with COSINE metric if missing."""
        try:
            res = self.client.get(f"/collections/{self.collection_name}")
            if res.status_code == 404 or (res.is_success and not res.json().get("result")):
                logger.info(f"Creating Qdrant collection '{self.collection_name}' (dim={self.vector_size}, metric=COSINE)...")
                create_payload = {
                    "vectors": {
                        "size": self.vector_size,
                        "distance": "Cosine",
                    }
                }
                create_res = self.client.put(f"/collections/{self.collection_name}", json=create_payload)
                create_res.raise_for_status()
                logger.info(f"Collection '{self.collection_name}' successfully provisioned.")
            else:
                logger.info(f"Collection '{self.collection_name}' is verified and operational.")
        except Exception as e:
            logger.error(f"Failed to ensure Qdrant collection '{self.collection_name}': {e}", exc_info=True)
            raise

    def upsert_person_photo(
        self,
        person_id: str,
        image_bytes: bytes,
        metadata: Optional[Dict[str, Any]] = None,
    ) -> bool:
        """
        Extract visual features from a person's photo and index them into Qdrant.

        Args:
            person_id: Unique identifier for the missing person record.
            image_bytes: Raw image file bytes.
            metadata: Additional metadata dictionary (name, age, last_seen, etc.) to store with the vector.

        Returns:
            bool: True if indexed successfully, False otherwise.
        """
        try:
            vector = extract_image_features(image_bytes)
            point_id = to_point_uuid(person_id)

            payload = dict(metadata or {})
            payload["person_id"] = str(person_id)
            payload["indexed_at"] = int(time.time() * 1000)

            body = {
                "points": [
                    {
                        "id": point_id,
                        "vector": vector,
                        "payload": payload,
                    }
                ]
            }

            res = self.client.put(f"/collections/{self.collection_name}/points?wait=true", json=body)
            res.raise_for_status()
            logger.info(f"Indexed photo vector for person '{person_id}' (point_id='{point_id}'): {res.status_code}")
            return True
        except Exception as e:
            logger.error(f"Error upserting photo for person '{person_id}': {e}", exc_info=True)
            return False

    def search_by_photo(
        self,
        image_bytes: bytes,
        top_k: int = 5,
        score_threshold: float = 0.65,
    ) -> List[Dict[str, Any]]:
        """
        Search Qdrant for missing persons with matching visual features.

        Args:
            image_bytes: Raw image bytes of the query photo / sighting.
            top_k: Maximum number of candidate matches to return.
            score_threshold: Minimum cosine similarity threshold (0.0 to 1.0).

        Returns:
            List of dicts containing person_id, score, point_id, and metadata payload.
        """
        try:
            query_vector = extract_image_features(image_bytes)

            body = {
                "vector": query_vector,
                "limit": top_k,
                "score_threshold": score_threshold,
                "with_payload": True,
            }

            res = self.client.post(f"/collections/{self.collection_name}/points/search", json=body)
            res.raise_for_status()
            data = res.json().get("result", [])

            results: List[Dict[str, Any]] = []
            for pt in data:
                payload = dict(pt.get("payload") or {})
                person_id = payload.get("person_id") or str(pt.get("id"))
                score = round(float(pt.get("score", 0.0)), 4)

                results.append({
                    "person_id": person_id,
                    "score": score,
                    "point_id": str(pt.get("id")),
                    "name": payload.get("name"),
                    "age": payload.get("age"),
                    "gender": payload.get("gender"),
                    "last_seen_location": payload.get("last_seen_location"),
                    "photo_url": payload.get("photo_url"),
                    "status": payload.get("status"),
                    "metadata": payload,
                })

            logger.info(f"Photo search completed: found {len(results)} matches (threshold={score_threshold})")
            return results
        except Exception as e:
            logger.error(f"Error during photo visual search: {e}", exc_info=True)
            return []

    def delete_person_photo(self, person_id: str) -> bool:
        """Remove a person's photo vector from the index."""
        try:
            point_id = to_point_uuid(person_id)
            body = {"points": [point_id]}
            res = self.client.post(f"/collections/{self.collection_name}/points/delete?wait=true", json=body)
            res.raise_for_status()
            logger.info(f"Deleted vector for person '{person_id}' (point_id='{point_id}')")
            return True
        except Exception as e:
            logger.error(f"Failed to delete photo vector for person '{person_id}': {e}", exc_info=True)
            return False

    def count_indexed_photos(self) -> int:
        """Return the total number of indexed vectors in the collection."""
        try:
            res = self.client.get(f"/collections/{self.collection_name}")
            if res.is_success:
                return res.json().get("result", {}).get("points_count", 0)
            return 0
        except Exception as e:
            logger.error(f"Failed to get collection count: {e}")
            return 0


# Global singleton instance of QdrantService
qdrant_service = QdrantService()
