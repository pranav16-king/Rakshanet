"""
DBSCAN Spatial Incident Clustering Engine for RakshaNet.
Feature 15 & Feature 19 from the SignalRescue AI White Paper.

Merges dozens of scattered raw civilian SOS distress signals within an epsilon
geographic radius into unified master operational incident tickets.
Accounts for 'Devices != People' statistical population modeling.
"""

import numpy as np
import math
import time
import hashlib
from typing import List, Dict, Any, Optional
from pydantic import BaseModel, Field


class MasterIncident(BaseModel):
    incident_id: str = Field(..., description="Unique Master Incident Ticket ID")
    category: str = Field(..., description="Primary disaster category: FLOOD, COLLAPSE, MEDICAL, FIRE")
    urgency: str = Field(..., description="Highest urgency level: CRITICAL, HIGH, MEDIUM, LOW")
    centroid_lat: float = Field(..., description="Geographic latitude center of the cluster")
    centroid_lng: float = Field(..., description="Geographic longitude center of the cluster")
    radius_meters: float = Field(default=50.0, description="Bounding radius of impacted cluster in meters")
    total_devices: int = Field(..., description="Count of physical handsets transmitting in cluster")
    estimated_casualties: int = Field(..., description="Estimated population impacted (Devices != People)")
    vulnerabilities: List[str] = Field(default_factory=list, description="Aggregated vulnerabilities: ELDERLY, INFANT, INJURED")
    device_ids: List[str] = Field(default_factory=list, description="List of participant device pseudonyms")
    raw_packet_ids: List[str] = Field(default_factory=list, description="IDs of all distress pings merged")
    status: str = Field(default="OPEN", description="OPEN, DISPATCHED, IN_PROGRESS, RESOLVED")
    first_reported_at: int
    last_reported_at: int


class SpatialClusterEngine:
    """
    Spatial clustering engine leveraging DBSCAN over spherical Haversine coordinates.
    Implements a zero-DLL, vectorized spherical distance matrix for maximum resilience
    in low-resource tactical field hardware and restricted enterprise systems.
    """
    EARTH_RADIUS_METERS = 6371000.0

    def __init__(self, eps_meters: float = 120.0, min_samples: int = 2):
        """
        :param eps_meters: Maximum spatial distance (in meters) between distress signals to be considered a single incident.
        :param min_samples: Minimum raw pings required to form a multi-device cluster.
        """
        self.eps_meters = eps_meters
        self.min_samples = min_samples

    def _haversine_distance_matrix(self, coords: np.ndarray) -> np.ndarray:
        """Vectorized pairwise Haversine distance matrix in meters across all coordinate points."""
        lat = np.radians(coords[:, 0])
        lng = np.radians(coords[:, 1])

        dlat = lat[:, np.newaxis] - lat[np.newaxis, :]
        dlng = lng[:, np.newaxis] - lng[np.newaxis, :]

        a = np.sin(dlat / 2.0) ** 2 + np.cos(lat[:, np.newaxis]) * np.cos(lat[np.newaxis, :]) * np.sin(dlng / 2.0) ** 2
        a = np.clip(a, 0.0, 1.0)
        c = 2.0 * np.arctan2(np.sqrt(a), np.sqrt(1.0 - a))
        return self.EARTH_RADIUS_METERS * c

    def _dbscan(self, coords: np.ndarray) -> np.ndarray:
        """Pure NumPy DBSCAN implementation with spherical Haversine distance."""
        n = len(coords)
        if n == 0:
            return np.array([], dtype=int)
        if n == 1:
            return np.array([0 if self.min_samples <= 1 else -1], dtype=int)

        dist_matrix = self._haversine_distance_matrix(coords)
        # Precompute epsilon neighbors for each point
        neighbors = [np.where(dist_matrix[i] <= self.eps_meters)[0] for i in range(n)]

        labels = np.full(n, -1, dtype=int)
        visited = np.zeros(n, dtype=bool)
        cluster_id = 0

        for i in range(n):
            if visited[i]:
                continue
            visited[i] = True

            neighbor_pts = list(neighbors[i])
            if len(neighbor_pts) < self.min_samples:
                labels[i] = -1
            else:
                labels[i] = cluster_id
                queue = [p for p in neighbor_pts if p != i]

                while queue:
                    current_pt = queue.pop(0)
                    if not visited[current_pt]:
                        visited[current_pt] = True
                        cur_neighbors = neighbors[current_pt]
                        if len(cur_neighbors) >= self.min_samples:
                            for neighbor_candidate in cur_neighbors:
                                if neighbor_candidate not in queue and not visited[neighbor_candidate]:
                                    queue.append(neighbor_candidate)

                    if labels[current_pt] == -1:
                        labels[current_pt] = cluster_id

                cluster_id += 1

        return labels

    def cluster_distress_signals(self, raw_packets: List[Dict[str, Any]]) -> List[MasterIncident]:
        """
        Takes raw SOS and emergency packets from the gateway and clusters them into Master Incidents.
        """
        # Filter packets that have valid spatial coordinates
        valid_packets = []
        coordinates = []

        for p in raw_packets:
            loc = p.get("location") or {}
            lat = loc.get("lat")
            lng = loc.get("lng")
            if lat is None or lng is None:
                lat = p.get("lat")
                lng = p.get("lng")
            if lat is None or lng is None:
                meta = p.get("meta") or {}
                if isinstance(meta, str):
                    try:
                        import json
                        meta = json.loads(meta)
                    except Exception:
                        meta = {}
                lat = meta.get("lat")
                lng = meta.get("lng")

            if lat is not None and lng is not None:
                valid_packets.append(p)
                coordinates.append([float(lat), float(lng)])

        if not valid_packets:
            return []

        # If only 1 packet exists, return it directly as a single-node incident
        if len(valid_packets) == 1:
            return [self._create_single_incident(valid_packets[0])]

        coords_np = np.array(coordinates)
        labels = self._dbscan(coords_np)

        incidents: List[MasterIncident] = []
        unique_labels = set(labels)

        # Process each multi-point cluster
        for label in unique_labels:
            if label == -1:
                # Noise / Outliers: Process each isolated ping individually
                outlier_indices = np.where(labels == -1)[0]
                for idx in outlier_indices:
                    incidents.append(self._create_single_incident(valid_packets[idx]))
                continue

            # Multi-point cluster member indices
            cluster_indices = np.where(labels == label)[0]
            cluster_packets = [valid_packets[i] for i in cluster_indices]
            cluster_coords = coords_np[cluster_indices]

            # 1. Centroid calculation
            centroid_lat = float(np.mean(cluster_coords[:, 0]))
            centroid_lng = float(np.mean(cluster_coords[:, 1]))

            # 2. Maximum cluster radius calculation (meters)
            max_dist_meters = 0.0
            for pt in cluster_coords:
                dist = self._haversine_distance(centroid_lat, centroid_lng, pt[0], pt[1])
                if dist > max_dist_meters:
                    max_dist_meters = dist
            radius_meters = max(round(max_dist_meters, 1), 35.0)

            # 3. Urgency Hierarchy: CRITICAL > HIGH > MEDIUM > LOW
            urgencies = [self._extract_urgency(p) for p in cluster_packets]
            if "CRITICAL" in urgencies:
                highest_urgency = "CRITICAL"
            elif "HIGH" in urgencies:
                highest_urgency = "HIGH"
            elif "MEDIUM" in urgencies:
                highest_urgency = "MEDIUM"
            else:
                highest_urgency = "LOW"

            # 4. Dominant Disaster Category
            categories = [self._extract_category(p) for p in cluster_packets]
            dominant_category = max(set(categories), key=categories.count)

            # 5. Devices != People Population Estimation (Feature 19)
            device_ids = list(set(p.get("sender_id", "SR-UNKNOWN") for p in cluster_packets))
            total_casualties = 0
            all_vulnerabilities = set()

            for p in cluster_packets:
                meta = self._get_packet_meta(p)
                # Add declared family/group casualties in SOS beacon
                declared = meta.get("casualties") or meta.get("people") or meta.get("casualty_count") or 1
                try:
                    total_casualties += int(declared)
                except (ValueError, TypeError):
                    total_casualties += 1

                vulns = meta.get("vulnerabilities") or meta.get("special_needs") or []
                if isinstance(vulns, list):
                    for v in vulns:
                        all_vulnerabilities.add(str(v).upper())

            # Avoid double-counting: estimated casualties must be at least total unique devices
            estimated_casualties = max(total_casualties, len(device_ids))

            # 6. Temporal bounds
            timestamps = [p.get("timestamp") or p.get("ts") or int(time.time() * 1000) for p in cluster_packets]
            first_seen = min(timestamps)
            last_seen = max(timestamps)

            # 7. Deterministic Incident ID
            hash_input = f"{centroid_lat:.4f}_{centroid_lng:.4f}_{first_seen}"
            incident_hash = hashlib.md5(hash_input.encode()).hexdigest()[:6].upper()
            incident_id = f"INC-CLUST-{incident_hash}"

            incident = MasterIncident(
                incident_id=incident_id,
                category=dominant_category,
                urgency=highest_urgency,
                centroid_lat=round(centroid_lat, 6),
                centroid_lng=round(centroid_lng, 6),
                radius_meters=radius_meters,
                total_devices=len(device_ids),
                estimated_casualties=estimated_casualties,
                vulnerabilities=list(all_vulnerabilities),
                device_ids=device_ids,
                raw_packet_ids=[p.get("msg_id", "") for p in cluster_packets],
                status="OPEN",
                first_reported_at=first_seen,
                last_reported_at=last_seen
            )
            incidents.append(incident)

        # Sort incidents: CRITICAL first, then by casualty count descending
        urgency_rank = {"CRITICAL": 0, "HIGH": 1, "MEDIUM": 2, "LOW": 3}
        incidents.sort(key=lambda inc: (urgency_rank.get(inc.urgency, 4), -inc.estimated_casualties))

        return incidents

    def _get_packet_meta(self, packet: Dict[str, Any]) -> Dict[str, Any]:
        meta = packet.get("meta")
        if meta is None and "meta_json" in packet:
            meta = packet.get("meta_json")
        if isinstance(meta, str):
            try:
                import json
                return json.loads(meta)
            except Exception:
                return {}
        if isinstance(meta, dict):
            return meta
        return {}

    def _create_single_incident(self, packet: Dict[str, Any]) -> MasterIncident:
        loc = packet.get("location") or {}
        lat = loc.get("lat") or packet.get("lat") or 0.0
        lng = loc.get("lng") or packet.get("lng") or 0.0
        meta = self._get_packet_meta(packet)

        msg_id = packet.get("msg_id", "")
        short_id = msg_id.replace("SOS-", "").replace("MSG-", "")[:6].upper()
        incident_id = f"INC-NODE-{short_id}"

        casualties = meta.get("casualties") or meta.get("people") or 1
        try:
            casualties = int(casualties)
        except (ValueError, TypeError):
            casualties = 1

        vulns = meta.get("vulnerabilities") or []
        ts = packet.get("timestamp") or packet.get("ts") or int(time.time() * 1000)

        return MasterIncident(
            incident_id=incident_id,
            category=self._extract_category(packet),
            urgency=self._extract_urgency(packet),
            centroid_lat=round(float(lat), 6),
            centroid_lng=round(float(lng), 6),
            radius_meters=30.0,
            total_devices=1,
            estimated_casualties=casualties,
            vulnerabilities=[str(v).upper() for v in vulns] if isinstance(vulns, list) else [],
            device_ids=[packet.get("sender_id", "SR-UNKNOWN")],
            raw_packet_ids=[msg_id],
            status="OPEN",
            first_reported_at=ts,
            last_reported_at=ts
        )

    def _extract_urgency(self, packet: Dict[str, Any]) -> str:
        meta = self._get_packet_meta(packet)
        urgency = meta.get("urgency") or ""
        if urgency:
            return str(urgency).upper()
        pkt_type = packet.get("type") or packet.get("packet_type")
        if pkt_type == "SOS":
            return "CRITICAL"
        return "MEDIUM"

    def _extract_category(self, packet: Dict[str, Any]) -> str:
        meta = self._get_packet_meta(packet)
        cat = meta.get("category") or meta.get("hazard") or ""
        if cat:
            return str(cat).upper()
        payload = (packet.get("payload") or "").lower()
        if "water" in payload or "flood" in payload:
            return "FLOOD_INUNDATION"
        if "trapped" in payload or "rubble" in payload or "collapse" in payload:
            return "STRUCTURAL_COLLAPSE"
        if "bleed" in payload or "injury" in payload or "medical" in payload:
            return "MEDICAL_TRAUMA"
        if "fire" in payload:
            return "FIRE"
        return "GENERAL_EMERGENCY"

    def _haversine_distance(self, lat1: float, lng1: float, lat2: float, lng2: float) -> float:
        """Computes great-circle distance between two points on Earth in meters."""
        r_lat1 = math.radians(lat1)
        r_lat2 = math.radians(lat2)
        d_lat = math.radians(lat2 - lat1)
        d_lng = math.radians(lng2 - lng1)

        a = math.sin(d_lat / 2.0) ** 2 + math.cos(r_lat1) * math.cos(r_lat2) * math.sin(d_lng / 2.0) ** 2
        c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
        return self.EARTH_RADIUS_METERS * c


# Global Singleton Spatial Clustering Instance (default 120m neighborhood radius)
spatial_cluster_engine = SpatialClusterEngine(eps_meters=120.0, min_samples=2)
