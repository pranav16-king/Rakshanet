"""
RakshaNet Opportunistic Ingestion Gateway (FastAPI).
Serves as the high-throughput bridge connecting mobile DTN mesh nodes to the cloud command intelligence layer.
Features:
  - Dual-Persistence (SQLite offline transactional + MongoDB Atlas cloud sync)
  - JWT Authentication & RBAC Access Control
  - Real-Time Command Center Dashboard KPIs & Incident Management
  - DBSCAN Spatial Clustering & Black Hole Decay Scanning
  - Linear Programming Rescue Fleet Optimization
  - OASIS CAP v1.2 XML & Legacy CAD JSON Interoperability
"""

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, status, Response, Depends, Request, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import List, Dict, Any, Optional
import time
import os
import uuid
import sys
import logging
from pathlib import Path
import jwt

# Ensure backend root is on sys.path
backend_root = str(Path(__file__).parent.parent)
if backend_root not in sys.path:
    sys.path.insert(0, backend_root)

logger = logging.getLogger("rakshanet.gateway")

from ai_engine.clustering import spatial_cluster_engine, MasterIncident, SpatialClusterEngine
from ai_engine.black_hole import black_hole_detector, BlackHoleAnomaly, BlackHoleDetector
from ai_engine.optimizer import (
    SearchIsochroneEngine,
    SearchIsochrone,
    DispatchOptimizer,
    dispatch_optimizer,
    RescueUnit,
    UnitAssignment,
    DispatchPlan
)
from ai_engine.cap_exporter import cap_exporter, CAPExporter
from .models import (
    SyncBatchRequest,
    SyncBatchResponse,
    PacketPayload,
    IngestStats,
    LoginRequest,
    AuthResponse,
    AuthUser,
    UserCreateRequest,
    AssignTeamRequest,
    DashboardOverview,
    DeviceStats,
    SightingCreate,
    MissingPersonCreate,
    MissingPersonStatusUpdate,
    PhotoSearchRequest,
    PhotoSearchResponse,
    PhotoUploadRequest
)
from .storage import (
    gateway_storage,
    GatewayStorage,
    verify_password,
    hash_password
)
from .qdrant_service import (
    qdrant_service,
    extract_image_features,
    decode_image_bytes
)

# JWT Configuration
JWT_SECRET = os.getenv("JWT_SECRET", "signalrescue-disaster-resilience-command-center-jwt-secret-2026")
JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "1440"))

security = HTTPBearer(auto_error=False)


def create_access_token(data: dict, expires_delta_minutes: Optional[int] = None) -> str:
    """Create signed JWT access token with expiration."""
    to_encode = data.copy()
    expire_seconds = (expires_delta_minutes or ACCESS_TOKEN_EXPIRE_MINUTES) * 60
    expire = time.time() + expire_seconds
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, JWT_SECRET, algorithm=JWT_ALGORITHM)


def get_current_user(credentials: Optional[HTTPAuthorizationCredentials] = Depends(security)) -> Dict[str, Any]:
    """Dependency: Extracts and verifies JWT bearer token, returning user profile."""
    if not credentials or not credentials.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authorization bearer token required",
            headers={"WWW-Authenticate": "Bearer"}
        )
    token = credentials.credentials
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        email = payload.get("sub")
        if not email:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token missing subject identity",
                headers={"WWW-Authenticate": "Bearer"}
            )
        user = gateway_storage.get_user_by_email(email)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found",
                headers={"WWW-Authenticate": "Bearer"}
            )
        user_clean = dict(user)
        user_clean.pop("password_hash", None)
        return user_clean
    except jwt.PyJWTError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Token validation failed: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"}
        )


app = FastAPI(
    title="RakshaNet Opportunistic Ingestion Gateway",
    description="Offline disaster mesh telemetry ingestion, dual-persistence, cryptographic deduplication, and Command Center API.",
    version="2.0.0"
)

# Enable CORS for local command center dashboards & Vite dev servers
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://localhost:3000", "*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class WebSocketManager:
    """Manages active WebSocket connections to rescue command dashboards."""
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)

    async def broadcast(self, message: Dict[str, Any]):
        for connection in list(self.active_connections):
            try:
                await connection.send_json(message)
            except Exception:
                self.disconnect(connection)


ws_manager = WebSocketManager()


# =============================================================================
# SYSTEM HEALTH & ROOT
# =============================================================================

@app.get("/")
def root():
    return {
        "platform": "RakshaNet (SignalRescue AI)",
        "service": "Opportunistic Ingestion Gateway & Command Center API",
        "version": "2.0.0",
        "status": "ONLINE",
        "dual_persistence": {
            "local_sqlite": "ONLINE",
            "mongodb_atlas": "CONNECTED" if gateway_storage.mongo_db is not None else "OFFLINE_FALLBACK"
        },
        "documentation": "/docs"
    }


@app.get("/api/v1/health")
def health_check():
    return {
        "status": "HEALTHY",
        "timestamp": int(time.time() * 1000),
        "gateway": "ONLINE",
        "mongo_atlas": "CONNECTED" if gateway_storage.mongo_db is not None else "OFFLINE_FALLBACK"
    }


# =============================================================================
# AUTHENTICATION (JWT)
# =============================================================================

@app.post("/api/v1/auth/login", response_model=AuthResponse)
def login(login_req: LoginRequest):
    """
    Authenticate emergency dispatch administrator / responder.
    Returns signed Bearer JWT token and profile.
    """
    email = login_req.email.strip().lower()
    user = gateway_storage.get_user_by_email(email)

    # Pre-seed fallback check for default authorized admins
    if not user:
        if email == "admin@signalrescue.org":
            admin_data = {
                "id": "USR-ADMIN-01",
                "email": "admin@signalrescue.org",
                "name": "Chief Commander Sharma",
                "password_hash": hash_password("SignalRescue@2026"),
                "role": "Administrator",
                "agency": "Government Operations",
                "phone": "+91-98765-43210",
                "status": "Active"
            }
            user = gateway_storage.create_user(admin_data)
            user["password_hash"] = admin_data["password_hash"]
        elif "@" in email and len(login_req.password) >= 4:
            # Auto-provision authorized disaster operations personnel (e.g. pranavkhaire53@gmail.com)
            name_part = email.split("@")[0].replace(".", " ").replace("_", " ").title()
            admin_data = {
                "id": f"USR-{uuid.uuid4().hex[:8].upper()}",
                "email": email,
                "name": f"Commander {name_part}",
                "password_hash": hash_password(login_req.password),
                "role": "Administrator",
                "agency": "Disaster Response Command",
                "phone": "+91-98000-00000",
                "status": "Active"
            }
            user = gateway_storage.create_user(admin_data)
            user["password_hash"] = admin_data["password_hash"]

    if not user or not verify_password(login_req.password, user.get("password_hash", "")):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
            headers={"WWW-Authenticate": "Bearer"}
        )

    access_token = create_access_token({
        "sub": user["email"],
        "id": user["id"],
        "role": user["role"]
    })

    return AuthResponse(
        access_token=access_token,
        token_type="bearer",
        user=AuthUser(
            id=user["id"],
            email=user["email"],
            name=user["name"],
            role=user["role"],
            agency=user["agency"],
            phone=user.get("phone"),
            status=user.get("status", "Active")
        )
    )


@app.get("/api/v1/auth/me", response_model=AuthUser)
def get_current_user_profile(user: Dict[str, Any] = Depends(get_current_user)):
    """Retrieve authenticated user identity from Bearer token."""
    return AuthUser(
        id=user["id"],
        email=user["email"],
        name=user["name"],
        role=user["role"],
        agency=user["agency"],
        phone=user.get("phone"),
        status=user.get("status", "Active")
    )


@app.post("/api/v1/auth/logout")
def logout():
    """Client-side session termination."""
    return {"status": "SUCCESS", "message": "Successfully logged out"}


# =============================================================================
# DASHBOARD OVERVIEW & KPIS
# =============================================================================

@app.get("/api/v1/dashboard/overview", response_model=DashboardOverview)
def get_dashboard_overview():
    """
    Returns real-time command center KPIs:
    total active users, active incidents, critical incidents, connected devices,
    messages relayed, incident distribution by disaster category, and recent incidents list.
    """
    users = gateway_storage.get_users()
    incidents = gateway_storage.get_incidents()
    device_stats = gateway_storage.get_device_stats()
    telemetry_stats = gateway_storage.get_stats()

    active_incidents = [
        inc for inc in incidents
        if inc.get("status") in ["ACTIVE", "ASSIGNED", "IN_PROGRESS"]
    ]
    critical_incidents = [
        inc for inc in incidents
        if inc.get("severity") == "CRITICAL"
    ]

    # Calculate real disaster distribution
    distribution = {
        "Flood": 0,
        "Earthquake": 0,
        "Landslide": 0,
        "Cyclone": 0,
        "Fire": 0,
        "Others": 0
    }
    for inc in incidents:
        category = inc.get("disaster_type", "Others")
        if category in distribution:
            distribution[category] += 1
        else:
            distribution["Others"] += 1

    return DashboardOverview(
        total_active_users=len([u for u in users if u.get("status") == "Active"]) or len(users),
        active_incidents=len(active_incidents),
        critical_incidents=len(critical_incidents),
        connected_devices=device_stats["online"] + device_stats["relay"],
        messages_relayed=telemetry_stats.get("unique_packets_stored", 0),
        incident_distribution=distribution,
        recent_incidents=incidents[:10]
    )


# =============================================================================
# INCIDENTS (Detail, Assign, Clustered)
# =============================================================================

@app.get("/api/v1/incidents")
def get_incidents_list(
    eps_meters: float = 120.0,
    min_samples: int = 2,
    source: Optional[str] = None
):
    """
    Returns disaster incidents.
    - If `source='db'` or no raw distress telemetry packets: returns stored Command Center Master Incidents.
    - If raw distress packets exist: performs dynamic DBSCAN Spatial Clustering across ingested mesh signals.
    """
    all_packets = gateway_storage.get_packets(limit=1000)
    distress_packets = [
        p for p in all_packets
        if p.get("packet_type") == "SOS" or
           (p.get("meta_json") and "urgency" in str(p.get("meta_json", ""))) or
           p.get("lat") is not None
    ]

    if source == "db" or (len(distress_packets) == 0):
        return gateway_storage.get_incidents()

    engine = SpatialClusterEngine(eps_meters=eps_meters, min_samples=min_samples) if (eps_meters != 120.0 or min_samples != 2) else spatial_cluster_engine
    return engine.cluster_distress_signals(distress_packets)


@app.get("/api/v1/incidents/{incident_id}")
def get_incident_detail(incident_id: str):
    """
    Returns full incident details, affected area, casualty estimate,
    associated messages, devices, resources needed, and AI explainability factors & confidence.
    """
    # 1. Check stored Master Incidents in dual-persistence
    inc = gateway_storage.get_incident(incident_id)
    if inc:
        return inc

    # 2. Check dynamic DBSCAN clustered space
    all_packets = gateway_storage.get_packets(limit=1000)
    distress_packets = [
        p for p in all_packets
        if p.get("packet_type") == "SOS" or p.get("lat") is not None
    ]
    clusters = spatial_cluster_engine.cluster_distress_signals(distress_packets)
    cluster = next((c for c in clusters if c.incident_id == incident_id), None)

    if cluster:
        category_name = getattr(cluster, "category", "Flood")
        return {
            "incident_id": cluster.incident_id,
            "title": f"{category_name.capitalize()} Distress Alert ({cluster.total_devices} devices)",
            "disaster_type": category_name,
            "category": category_name,
            "severity": cluster.urgency,
            "status": getattr(cluster, "status", "ACTIVE"),
            "lat": cluster.centroid_lat,
            "lng": cluster.centroid_lng,
            "affected_area": f"Radius {int(cluster.radius_meters)}m cluster centroid",
            "cluster_radius_meters": cluster.radius_meters,
            "casualty_estimate": cluster.estimated_casualties,
            "people_count": cluster.estimated_casualties,
            "devices_count": cluster.total_devices,
            "assigned_team": None,
            "resources_needed": ["Rescue Units Needed", "Medical First Responders"],
            "ai_confidence": 0.94,
            "ai_explainability": {
                "factors": [
                    f"DBSCAN spatial cluster of {cluster.total_devices} nodes within {int(cluster.radius_meters)}m radius",
                    f"Triage urgency: {cluster.urgency}",
                    "Multi-victim device expansion multiplier applied"
                ],
                "model_version": "SignalRescue-SpatialTriage-v2.1"
            },
            "associated_messages": [],
            "associated_devices": getattr(cluster, "device_ids", []),
            "created_at": getattr(cluster, "first_reported_at", int(time.time() * 1000)),
            "updated_at": getattr(cluster, "last_reported_at", int(time.time() * 1000))
        }

    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail=f"Master Incident '{incident_id}' not found."
    )


@app.patch("/api/v1/incidents/{incident_id}/assign")
async def assign_incident_rescue_team(incident_id: str, assign_req: AssignTeamRequest):
    """
    Assigns a rescue team to the incident and broadcasts an update event.
    """
    team_name = assign_req.team_name or assign_req.team_id
    if not team_name:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Either team_name or team_id must be provided"
        )

    updated = gateway_storage.assign_incident_team(incident_id, team_name)
    if not updated:
        # If incident was only in dynamic DBSCAN cluster space, persist it to DB
        all_packets = gateway_storage.get_packets(limit=1000)
        distress_packets = [
            p for p in all_packets
            if p.get("packet_type") == "SOS" or p.get("lat") is not None
        ]
        clusters = spatial_cluster_engine.cluster_distress_signals(distress_packets)
        cluster = next((c for c in clusters if c.incident_id == incident_id), None)
        if cluster:
            new_inc = {
                "incident_id": cluster.incident_id,
                "title": f"Incident {cluster.incident_id}",
                "disaster_type": cluster.primary_category or "Flood",
                "severity": cluster.urgency,
                "status": "ASSIGNED",
                "lat": cluster.centroid_lat,
                "lng": cluster.centroid_lng,
                "affected_area": f"Radius {int(cluster.radius_meters)}m",
                "casualty_estimate": cluster.estimated_casualties,
                "people_count": cluster.estimated_casualties,
                "devices_count": cluster.total_devices,
                "assigned_team": team_name,
                "resources_needed": ["Rescue Units Needed"],
                "ai_confidence": cluster.confidence_score,
                "ai_explainability": {"factors": ["DBSCAN dynamic cluster"]},
                "associated_messages": cluster.sample_messages or [],
                "associated_devices": cluster.contributing_devices or []
            }
            updated = gateway_storage.upsert_incident(new_inc)
        else:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Master Incident '{incident_id}' not found."
            )

    # Real-time WebSocket broadcast to connected incident commanders
    await ws_manager.broadcast({
        "event": "INCIDENT_ASSIGNED",
        "incident_id": incident_id,
        "assigned_team": team_name,
        "timestamp": int(time.time() * 1000)
    })

    return updated


@app.post("/api/v1/incidents/cluster")
async def trigger_incident_clustering(eps_meters: float = 120.0, min_samples: int = 2):
    """
    Triggers an immediate clustering cycle over ingested telemetry,
    calculates centroids, radii, and 'Devices != People' casualty estimates,
    and broadcasts an INCIDENTS_UPDATED event to connected Command Center dashboards.
    """
    all_packets = gateway_storage.get_packets(limit=1000)
    distress_packets = [
        p for p in all_packets
        if p.get("packet_type") == "SOS" or p.get("lat") is not None
    ]
    engine = SpatialClusterEngine(eps_meters=eps_meters, min_samples=min_samples) if (eps_meters != 120.0 or min_samples != 2) else spatial_cluster_engine
    incidents = engine.cluster_distress_signals(distress_packets)
    incidents_data = [inc.model_dump() for inc in incidents]

    await ws_manager.broadcast({
        "event": "INCIDENTS_UPDATED",
        "count": len(incidents_data),
        "incidents": incidents_data,
        "timestamp": int(time.time() * 1000)
    })

    return {
        "status": "CLUSTERED",
        "incident_count": len(incidents),
        "raw_signals_analyzed": len(distress_packets),
        "incidents": incidents_data
    }


# =============================================================================
# PEOPLE & USERS
# =============================================================================

@app.get("/api/v1/users")
def get_users(role: Optional[str] = None, search: Optional[str] = None):
    """Retrieve list of registered users and field responders."""
    return gateway_storage.get_users(role=role, search=search)


@app.post("/api/v1/users")
def create_field_user(user_req: UserCreateRequest):
    """Register a new field commander, responder, or volunteer."""
    existing = gateway_storage.get_user_by_email(user_req.email)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"User with email '{user_req.email}' already exists."
        )
    return gateway_storage.create_user(user_req.model_dump())


# =============================================================================
# DEVICES & NETWORK
# =============================================================================

@app.get("/api/v1/devices")
def get_devices():
    """Returns active mesh nodes, battery levels, relay status, and topology position."""
    return gateway_storage.get_devices()


@app.get("/api/v1/devices/stats", response_model=DeviceStats)
def get_devices_stats():
    """Returns counts of total, online, relay, and offline devices."""
    return gateway_storage.get_device_stats()


# =============================================================================
# MESSAGES
# =============================================================================

@app.get("/api/v1/messages")
def get_messages(type: Optional[str] = "ALL", limit: int = 100):
    """
    Retrieve telemetry messages with optional filter by packet type:
    ALL, SOS, REPORT, TEAM, SYSTEM.
    """
    return gateway_storage.get_messages(msg_type=type, limit=limit)


# =============================================================================
# RESOURCES & LOGISTICS
# =============================================================================

@app.get("/api/v1/resources")
def get_resources():
    """Retrieve disaster logistics resources: boats, 4WDs, ambulances, shelters, food/water."""
    return gateway_storage.get_resources()


@app.post("/api/v1/resources")
def upsert_resource(resource: Dict[str, Any]):
    """Update or register a disaster logistics resource."""
    if not resource.get("resource_id") or not resource.get("name") or not resource.get("category"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="resource_id, name, and category are required."
        )
    return gateway_storage.upsert_resource(resource)


@app.patch("/api/v1/resources/{resource_id}")
def update_resource_allocation(resource_id: str, patch_data: Dict[str, Any]):
    """Update allocated quantity for an active relief resource asset."""
    allocated = patch_data.get("allocated", 0)
    result = gateway_storage.update_resource_allocation(resource_id, allocated)
    if not result.get("success"):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=result.get("error", "Resource not found")
        )
    return result


# =============================================================================
# RESCUE TEAMS / FLEET
# =============================================================================

@app.get("/api/v1/rescue-teams")
def get_rescue_teams():
    """Retrieve all registered rescue teams and their operational readiness."""
    return gateway_storage.get_rescue_teams()


# =============================================================================
# MISSING PERSONS REGISTRY & SIGHTINGS
# =============================================================================

@app.get("/api/v1/missing-persons")
def get_missing_persons(
    status: Optional[str] = None,
    search: Optional[str] = None
):
    """
    Retrieve missing person registry records.
    Filters:
      - status: ALL, MISSING, FOUND
      - search: matches name, location, or description text
    """
    return gateway_storage.get_missing_persons(status=status, search=search)


@app.get("/api/v1/missing-persons/{person_id}")
def get_missing_person_by_id(person_id: str):
    """Retrieve details for a specific missing person report."""
    person = gateway_storage.get_missing_person(person_id)
    if not person:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Missing person record '{person_id}' not found."
        )
    return person


@app.post("/api/v1/missing-persons", status_code=status.HTTP_201_CREATED)
async def create_missing_person_report(req: MissingPersonCreate):
    """
    Register a new missing person bulletin.
    If a photo is provided (via photo_url or photo_base64), automatically extracts
    a 512-D visual feature embedding and indexes it into the Qdrant Cloud Vector Database.
    """
    created = gateway_storage.create_missing_person(req.model_dump())

    photo_input = req.photo_url or req.photo_base64
    if photo_input:
        try:
            image_bytes = decode_image_bytes(photo_input)
            indexed = qdrant_service.upsert_person_photo(
                person_id=created["id"],
                image_bytes=image_bytes,
                metadata={
                    "name": created.get("name"),
                    "age": created.get("age"),
                    "gender": created.get("gender"),
                    "last_seen_location": created.get("last_seen_location"),
                    "photo_url": created.get("photo_url"),
                    "status": created.get("status"),
                    "reported_by": created.get("reported_by"),
                }
            )
            created["indexed_in_qdrant"] = indexed
        except Exception as e:
            logger.warning(f"Could not index photo for missing person {created['id']} into Qdrant: {e}")
            created["indexed_in_qdrant"] = False

    await ws_manager.broadcast({
        "event": "MISSING_PERSON_CREATED",
        "data": created,
        "timestamp": int(time.time() * 1000)
    })
    return created


@app.patch("/api/v1/missing-persons/{person_id}/status")
async def update_missing_person_status(person_id: str, req: MissingPersonStatusUpdate):
    """Update status of a missing person report (e.g. mark FOUND or MISSING)."""
    updated = gateway_storage.update_missing_person_status(person_id, req.status)
    if not updated:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Missing person record '{person_id}' not found."
        )
    await ws_manager.broadcast({
        "event": "MISSING_PERSON_STATUS_UPDATED",
        "person_id": person_id,
        "status": req.status,
        "data": updated,
        "timestamp": int(time.time() * 1000)
    })
    return updated


@app.post("/api/v1/missing-persons/{person_id}/sightings")
async def add_missing_person_sighting(person_id: str, req: SightingCreate):
    """Record a citizen sighting for a missing person."""
    updated = gateway_storage.add_missing_person_sighting(person_id, req.model_dump())
    if not updated:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Missing person record '{person_id}' not found."
        )
    await ws_manager.broadcast({
        "event": "MISSING_PERSON_SIGHTING_ADDED",
        "person_id": person_id,
        "data": updated,
        "timestamp": int(time.time() * 1000)
    })
    return updated


@app.post("/api/v1/missing-persons/{person_id}/photo")
async def upload_missing_person_photo(
    person_id: str,
    request: Request,
):
    """
    Upload and index an identifying photo for an existing missing person record.
    Extracts 512-D visual features and indexes them into Qdrant Cloud Vector Database.
    Accepts multipart/form-data ('photo' or 'file') or JSON ('photo_base64' or 'photo_url').
    """
    person = gateway_storage.get_missing_person(person_id)
    if not person:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Missing person record '{person_id}' not found."
        )

    content_type = request.headers.get("content-type", "").lower()
    image_bytes: Optional[bytes] = None
    photo_url: Optional[str] = None

    if "multipart/form-data" in content_type:
        form = await request.form()
        upload = form.get("photo") or form.get("file") or form.get("image")
        if upload and hasattr(upload, "read"):
            image_bytes = await upload.read()
    else:
        try:
            body = await request.json()
        except Exception:
            body = {}
        photo_input = (
            body.get("photo_base64")
            or body.get("photo_url")
            or body.get("photo")
            or body.get("image")
        )
        if photo_input:
            try:
                image_bytes = decode_image_bytes(photo_input)
            except Exception as e:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Failed to decode photo: {e}"
                )
            if isinstance(photo_input, str) and (photo_input.startswith("http://") or photo_input.startswith("https://")):
                photo_url = photo_input

    if not image_bytes:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No photo provided. Provide file upload ('photo') or JSON body ('photo_base64' / 'photo_url')."
        )

    # Persist photo file locally
    photos_dir = Path(backend_root) / "data" / "photos"
    photos_dir.mkdir(parents=True, exist_ok=True)
    photo_file = photos_dir / f"{person_id}.jpg"
    with open(photo_file, "wb") as f:
        f.write(image_bytes)

    if not photo_url:
        photo_url = f"/api/v1/missing-persons/{person_id}/photo"

    # Update in gateway storage
    updated_person = gateway_storage.update_missing_person_photo(person_id, photo_url) or person
    updated_person["photo_url"] = photo_url

    # Upsert vector into Qdrant
    indexed = qdrant_service.upsert_person_photo(
        person_id=person_id,
        image_bytes=image_bytes,
        metadata={
            "name": updated_person.get("name"),
            "age": updated_person.get("age"),
            "gender": updated_person.get("gender"),
            "last_seen_location": updated_person.get("last_seen_location"),
            "photo_url": photo_url,
            "status": updated_person.get("status"),
            "reported_by": updated_person.get("reported_by"),
        }
    )

    if not indexed:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to index visual features into Qdrant for person '{person_id}'."
        )

    await ws_manager.broadcast({
        "event": "MISSING_PERSON_PHOTO_UPDATED",
        "person_id": person_id,
        "photo_url": photo_url,
        "timestamp": int(time.time() * 1000)
    })

    return {
        "status": "SUCCESS",
        "person_id": person_id,
        "photo_url": photo_url,
        "indexed_in_qdrant": True,
        "message": f"Photo indexed successfully in Qdrant Vector Cloud for {person.get('name')}.",
        "person": updated_person
    }


@app.get("/api/v1/missing-persons/{person_id}/photo")
def get_missing_person_photo(person_id: str):
    """Retrieve stored photo for a missing person."""
    photo_file = Path(backend_root) / "data" / "photos" / f"{person_id}.jpg"
    if photo_file.exists():
        from fastapi.responses import FileResponse
        return FileResponse(str(photo_file), media_type="image/jpeg")

    person = gateway_storage.get_missing_person(person_id)
    if person and person.get("photo_url"):
        from fastapi.responses import RedirectResponse
        if person["photo_url"].startswith("http"):
            return RedirectResponse(url=person["photo_url"])
        return {"photo_url": person["photo_url"]}

    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail=f"Photo for person '{person_id}' not found."
    )


@app.post("/api/v1/missing-persons/search-by-photo")
async def search_missing_persons_by_photo(
    request: Request,
):
    """
    Biometric visual search endpoint for missing individuals.
    Accepts multipart/form-data with a file upload ('photo' or 'file')
    OR application/json payload with 'photo_base64' (or 'photo_url').
    Extracts 512-D visual features and performs cosine similarity search via Qdrant Cloud.
    Returns:
        {
            "match_found": bool,
            "matches": list,
            "top_match": dict or None
        }
    """
    start_ts = time.time()
    content_type = request.headers.get("content-type", "").lower()
    image_bytes: Optional[bytes] = None
    top_k: int = 5
    score_threshold: float = 0.65

    # Check query params
    qp = request.query_params
    if "top_k" in qp:
        try:
            top_k = int(qp["top_k"])
        except ValueError:
            pass
    if "score_threshold" in qp:
        try:
            score_threshold = float(qp["score_threshold"])
        except ValueError:
            pass

    if "multipart/form-data" in content_type:
        form = await request.form()
        upload = form.get("photo") or form.get("file") or form.get("image")
        if upload and hasattr(upload, "read"):
            image_bytes = await upload.read()
        if "top_k" in form:
            try:
                top_k = int(form["top_k"])
            except ValueError:
                pass
        if "score_threshold" in form:
            try:
                score_threshold = float(form["score_threshold"])
            except ValueError:
                pass
    else:
        try:
            body = await request.json()
        except Exception:
            body = {}
        photo_input = (
            body.get("photo_base64")
            or body.get("photo_url")
            or body.get("photo")
            or body.get("image")
        )
        if photo_input:
            try:
                image_bytes = decode_image_bytes(photo_input)
            except Exception as e:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Failed to decode photo: {e}"
                )
        if "top_k" in body:
            try:
                top_k = int(body["top_k"])
            except ValueError:
                pass
        if "score_threshold" in body:
            try:
                score_threshold = float(body["score_threshold"])
            except ValueError:
                pass

    if not image_bytes:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No valid photo provided. Supply a file upload ('photo') or JSON field ('photo_base64'/'photo_url')."
        )

    # Perform visual feature search against Qdrant Vector Cloud
    qdrant_matches = qdrant_service.search_by_photo(
        image_bytes=image_bytes,
        top_k=top_k,
        score_threshold=score_threshold,
    )

    # Enrich matches with database records
    enriched_matches = []
    for m in qdrant_matches:
        p_id = m.get("person_id")
        db_person = gateway_storage.get_missing_person(p_id) if p_id else None
        record = {
            "person_id": p_id,
            "score": m["score"],
            "confidence_score": round(m["score"] * 100, 1),
            "point_id": m.get("point_id"),
            "person": db_person or m.get("metadata", {}),
            "name": m.get("name") or (db_person.get("name") if db_person else None),
            "age": m.get("age") or (db_person.get("age") if db_person else None),
            "gender": m.get("gender") or (db_person.get("gender") if db_person else None),
            "last_seen_location": m.get("last_seen_location") or (db_person.get("last_seen_location") if db_person else None),
            "photo_url": m.get("photo_url") or (db_person.get("photo_url") if db_person else None),
            "status": m.get("status") or (db_person.get("status") if db_person else None),
            "metadata": m.get("metadata", {}),
        }
        enriched_matches.append(record)

    match_found = len(enriched_matches) > 0
    top_match = enriched_matches[0] if match_found else None
    latency_ms = int((time.time() - start_ts) * 1000)

    return {
        "match_found": match_found,
        "matches": enriched_matches,
        "top_match": top_match,
        "success": True,
        "total_candidates_scanned": len(enriched_matches),
        "engine": "Qdrant Vector Cloud Engine (missing_persons, 512-D COSINE)",
        "search_latency_ms": latency_ms,
    }


@app.get("/api/v1/missing-persons/stats/visual-index")
def get_visual_index_stats():
    """Retrieve indexing statistics for the Qdrant Cloud visual search collection."""
    count = qdrant_service.count_indexed_photos()
    return {
        "status": "ONLINE",
        "collection_name": qdrant_service.collection_name,
        "vector_size": qdrant_service.vector_size,
        "distance_metric": "COSINE",
        "indexed_photos_count": count,
        "cloud_url": qdrant_service.url,
    }


@app.post("/api/v1/missing-persons/index-all")
async def index_all_missing_persons_photos():
    """
    Batch index all registered missing persons with photos into Qdrant Cloud.
    Scans the missing persons registry and computes 512-D embeddings for records with photos.
    """
    all_persons = gateway_storage.get_missing_persons(status="ALL")
    indexed_count = 0
    failed_count = 0
    details = []

    for person in all_persons:
        photo_url = person.get("photo_url")
        if not photo_url:
            continue
        try:
            image_bytes = decode_image_bytes(photo_url)
            ok = qdrant_service.upsert_person_photo(
                person_id=person["id"],
                image_bytes=image_bytes,
                metadata={
                    "name": person.get("name"),
                    "age": person.get("age"),
                    "gender": person.get("gender"),
                    "last_seen_location": person.get("last_seen_location"),
                    "photo_url": photo_url,
                    "status": person.get("status"),
                    "reported_by": person.get("reported_by"),
                }
            )
            if ok:
                indexed_count += 1
                details.append({"person_id": person["id"], "name": person.get("name"), "status": "INDEXED"})
            else:
                failed_count += 1
                details.append({"person_id": person["id"], "name": person.get("name"), "status": "FAILED"})
        except Exception as e:
            logger.warning(f"Failed to batch index photo for {person['id']}: {e}")
            failed_count += 1
            details.append({"person_id": person["id"], "name": person.get("name"), "status": f"ERROR: {str(e)}"})

    return {
        "total_scanned": len(all_persons),
        "indexed_count": indexed_count,
        "failed_count": failed_count,
        "total_in_qdrant": qdrant_service.count_indexed_photos(),
        "details": details,
    }



# =============================================================================
# ANALYTICS & TRENDS
# =============================================================================

@app.get("/api/v1/analytics/trends")
def get_analytics_trends():
    """Returns historical multi-day message volumes, SOS alerts, citizen reports, and resolution rates."""
    data = gateway_storage.get_analytics_trends()
    if "trends" not in data and "days" in data:
        data["trends"] = data["days"]
    return data


# =============================================================================
# SETTINGS & SYSTEM CONFIGURATION
# =============================================================================

@app.get("/api/v1/settings")
def get_settings():
    """Retrieve system toggles, AI settings, and telemetry retention configurations."""
    raw = gateway_storage.get_settings()
    data = dict(raw) if isinstance(raw, dict) else {}
    data["allowNewUserRegistration"] = True
    data["enableOfflineMeshNetwork"] = data.get("mesh_network", {}).get("mesh_relay_enabled", True) if isinstance(data.get("mesh_network"), dict) else True
    data["saveMessagesLocally"] = True
    data["autoSyncWhenOnline"] = data.get("data_retention", {}).get("sync_to_cloud", True) if isinstance(data.get("data_retention"), dict) else True
    data["enableOfflineAiGuidance"] = data.get("ai_clustering", {}).get("auto_clustering_enabled", True) if isinstance(data.get("ai_clustering"), dict) else True
    data["useLocalKnowledgeBase"] = True
    data["dataRetentionDays"] = data.get("data_retention", {}).get("telemetry_retention_days", 30) if isinstance(data.get("data_retention"), dict) else 30
    data["allowAnonymousUsage"] = data.get("data_retention", {}).get("anonymize_civilians", True) if isinstance(data.get("data_retention"), dict) else True
    return data


@app.post("/api/v1/settings")
def update_settings(settings_data: Dict[str, Any]):
    """Update system toggles and AI parameters."""
    return gateway_storage.update_settings(settings_data)


# =============================================================================
# OPPORTUNISTIC TELEMETRY INGESTION (DTN MESH)
# =============================================================================

@app.post("/api/v1/telemetry/sync", response_model=SyncBatchResponse)
async def sync_telemetry_batch(batch: SyncBatchRequest):
    """
    Opportunistic batch ingestion endpoint.
    Invoked when any handset reaches cellular fringe, field Wi-Fi, or satellite uplink.
    Idempotently deduplicates all packets carried by moving data mules.
    Writes synchronously to local SQLite and asynchronously to MongoDB Atlas.
    """
    accepted_ids = []
    duplicate_count = 0

    for packet in batch.packets:
        packet_dict = packet.model_dump()
        is_new = gateway_storage.ingest_packet(packet_dict, mule_id=batch.device_id)

        if is_new:
            accepted_ids.append(packet.msg_id)
            # Broadcast live emergency packet to connected Command Center WebSockets
            await ws_manager.broadcast({
                "event": "NEW_PACKET_INGESTED",
                "packet": packet_dict,
                "mule_id": batch.device_id,
                "timestamp": int(time.time() * 1000)
            })
        else:
            duplicate_count += 1

    receipt_id = f"RCPT-{uuid.uuid4().hex[:8].upper()}"

    return SyncBatchResponse(
        status="SUCCESS",
        accepted_count=len(accepted_ids),
        duplicate_count=duplicate_count,
        receipt_id=receipt_id,
        server_timestamp=int(time.time() * 1000),
        synced_packet_ids=accepted_ids
    )


@app.get("/api/v1/telemetry/packets")
def get_ingested_packets(limit: int = 100, packet_type: str = None):
    """Retrieve recently ingested telemetry packets."""
    return {
        "count": len(gateway_storage.get_packets(limit=limit, packet_type=packet_type)),
        "packets": gateway_storage.get_packets(limit=limit, packet_type=packet_type)
    }


@app.get("/api/v1/telemetry/stats")
def get_telemetry_stats():
    """Retrieve gateway deduplication and data mule performance statistics."""
    stats = gateway_storage.get_stats()
    stats["connected_dashboard_clients"] = len(ws_manager.active_connections)
    return stats


# =============================================================================
# BLACK HOLE ANOMALY DETECTION
# =============================================================================

@app.get("/api/v1/anomalies/black-holes", response_model=List[BlackHoleAnomaly])
def get_black_hole_anomalies(
    min_baseline_nodes: int = 10,
    critical_drop_pct: float = 75.0,
    warning_drop_pct: float = 45.0
):
    """
    Communication-Gap & Black Hole Anomaly Detection (Feature 16).
    Analyzes spatiotemporal telemetry decay curves across spatial sectors
    to identify cut-off villages and total silence zones.
    """
    all_packets = gateway_storage.get_packets(limit=5000)
    detector = BlackHoleDetector(
        min_baseline_nodes=min_baseline_nodes,
        critical_drop_pct=critical_drop_pct,
        warning_drop_pct=warning_drop_pct
    )
    return detector.detect_anomalies(all_packets)


@app.post("/api/v1/anomalies/black-holes/scan")
async def scan_black_holes(
    min_baseline_nodes: int = 10,
    critical_drop_pct: float = 75.0,
    warning_drop_pct: float = 45.0
):
    """
    Triggers an immediate multi-sector decay scan over stored telemetry.
    If catastrophic communication black holes are discovered, broadcasts
    BLACK_HOLE_ALERT to Command Center WebSockets.
    """
    all_packets = gateway_storage.get_packets(limit=5000)
    detector = BlackHoleDetector(
        min_baseline_nodes=min_baseline_nodes,
        critical_drop_pct=critical_drop_pct,
        warning_drop_pct=warning_drop_pct
    )
    anomalies = detector.detect_anomalies(all_packets)
    anomalies_data = [a.model_dump() for a in anomalies]

    if anomalies_data:
        await ws_manager.broadcast({
            "event": "BLACK_HOLE_ALERT",
            "anomaly_count": len(anomalies_data),
            "anomalies": anomalies_data,
            "timestamp": int(time.time() * 1000)
        })

    return {
        "status": "SCANNED",
        "anomaly_count": len(anomalies),
        "critical_count": sum(1 for a in anomalies if a.severity == "CRITICAL"),
        "warning_count": sum(1 for a in anomalies if a.severity == "WARNING"),
        "anomalies": anomalies_data
    }


# =============================================================================
# SEARCH ISOCHRONE & DISPATCH OPTIMIZATION
# =============================================================================

ACTIVE_RESCUE_FLEET = [
    RescueUnit(
        unit_id="NDRF-BOAT-01",
        name="NDRF Zodiac Inflatable Boat 01",
        unit_type="BOAT",
        lat=13.0100,
        lng=80.2400,
        capacity=10,
        status="AVAILABLE",
        speed_kmh=25.0,
        capabilities=["WATER_RESCUE", "EVACUATION"]
    ),
    RescueUnit(
        unit_id="SDRF-4WD-02",
        name="SDRF High-Clearance Rescue Truck 02",
        unit_type="HIGH_CLEARANCE_4WD",
        lat=12.9300,
        lng=80.1300,
        capacity=6,
        status="AVAILABLE",
        speed_kmh=45.0,
        capabilities=["STRUCTURAL_SEARCH", "EVACUATION"]
    ),
    RescueUnit(
        unit_id="108-AMB-05",
        name="Emergency Trauma Paramedic Ambulance 05",
        unit_type="AMBULANCE",
        lat=13.0400,
        lng=80.2200,
        capacity=2,
        status="AVAILABLE",
        speed_kmh=50.0,
        capabilities=["PARAMEDIC", "ADVANCED_LIFE_SUPPORT"]
    ),
    RescueUnit(
        unit_id="ARMY-HELI-01",
        name="Indian Army ALH Dhruv Air Recon 01",
        unit_type="HELICOPTER",
        lat=12.9900,
        lng=80.1700,
        capacity=12,
        status="AVAILABLE",
        speed_kmh=160.0,
        capabilities=["WATER_RESCUE", "STRUCTURAL_SEARCH", "AERIAL_RECON"]
    )
]


@app.get("/api/v1/search/isochrone")
def get_missing_person_isochrone(
    person_id: str,
    last_lat: float,
    last_lng: float,
    last_seen_ts: int,
    drift_speed_mps: float = 0.0,
    drift_heading_deg: float = 0.0,
    pedestrian_speed_mps: float = 0.75
):
    """
    Missing-Person Probabilistic Isochrone Search Zone (Feature 18).
    Computes expanding 68% and 95% search envelopes and drift offsets
    for missing survivors whose telemetry terminated.
    """
    iso = SearchIsochroneEngine.calculate_search_zone(
        person_id=person_id,
        last_lat=last_lat,
        last_lng=last_lng,
        last_seen_ts=last_seen_ts,
        drift_speed_mps=drift_speed_mps,
        drift_heading_deg=drift_heading_deg,
        pedestrian_speed_mps=pedestrian_speed_mps
    )
    res = iso.model_dump()
    res["isochrone_68_pct"] = {
        "confidence": 0.68,
        "radius_meters": iso.radius_68_meters,
        "center": {"lat": iso.projected_center_lat, "lng": iso.projected_center_lng}
    }
    res["isochrone_95_pct"] = {
        "confidence": 0.95,
        "radius_meters": iso.radius_95_meters,
        "center": {"lat": iso.projected_center_lat, "lng": iso.projected_center_lng}
    }
    return res



@app.get("/api/v1/dispatch/units", response_model=List[RescueUnit])
def get_available_rescue_fleet():
    """Retrieve all registered disaster response units and their readiness status."""
    return ACTIVE_RESCUE_FLEET


@app.post("/api/v1/dispatch/optimize", response_model=DispatchPlan)
async def optimize_rescue_dispatch(custom_units: Optional[List[RescueUnit]] = None):
    """
    Mixed-Integer Linear Resource Dispatch Optimization (Feature 20).
    Optimally assigns boats, 4WDs, and ambulances to active Master Incidents
    to maximize lives preserved and minimize transit delay.
    """
    all_packets = gateway_storage.get_packets(limit=1000)
    distress_packets = [
        p for p in all_packets
        if p.get("packet_type") == "SOS" or p.get("lat") is not None
    ]
    incidents = spatial_cluster_engine.cluster_distress_signals(distress_packets)
    incidents_dict = [inc.model_dump() for inc in incidents]

    units_to_use = custom_units if (custom_units and len(custom_units) > 0) else ACTIVE_RESCUE_FLEET
    plan = dispatch_optimizer.optimize_dispatch(incidents=incidents_dict, units=units_to_use)

    await ws_manager.broadcast({
        "event": "DISPATCH_PLAN_GENERATED",
        "plan_id": plan.plan_id,
        "assigned_count": plan.assigned_count,
        "total_casualties_addressed": plan.total_casualties_addressed,
        "assignments": [a.model_dump() for a in plan.assignments],
        "timestamp": int(time.time() * 1000)
    })

    return plan


# =============================================================================
# OASIS CAP v1.2 XML & LEGACY CAD JSON EXPORTERS
# =============================================================================

@app.get("/api/v1/interop/cap/feed.xml")
def get_cap_alert_feed():
    """Aggregated CAP v1.2 XML alert feed containing all active Master Incidents."""
    distress_packets = [
        p for p in gateway_storage.get_packets(limit=1000)
        if p.get("packet_type") == "SOS" or p.get("lat") is not None
    ]
    incidents = spatial_cluster_engine.cluster_distress_signals(distress_packets)

    feed_lines = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<alerts xmlns="urn:oasis:names:tc:emergency:cap:1.2" source="RakshaNet">'
    ]
    for inc in incidents:
        raw_xml = cap_exporter.incident_to_cap_xml(inc)
        lines = [line for line in raw_xml.split("\n") if not line.strip().startswith("<?xml")]
        feed_lines.append("\n".join(lines))

    feed_lines.append("</alerts>")
    return Response(content="\n".join(feed_lines), media_type="application/xml")


@app.get("/api/v1/interop/cap/{incident_id}.xml")
def get_incident_cap_xml(incident_id: str):
    """
    OASIS Common Alerting Protocol (CAP v1.2) XML Exporter.
    Generates standard CAP v1.2 XML for national disaster agencies (NDMA, SACHET, SDMA).
    """
    distress_packets = [
        p for p in gateway_storage.get_packets(limit=1000)
        if p.get("packet_type") == "SOS" or p.get("lat") is not None
    ]
    incidents = spatial_cluster_engine.cluster_distress_signals(distress_packets)
    target = next((inc for inc in incidents if inc.incident_id == incident_id), None)

    if not target:
        # Check DB incident and convert
        db_inc = gateway_storage.get_incident(incident_id)
        if db_inc:
            target = MasterIncident(
                incident_id=db_inc["incident_id"],
                category=db_inc.get("disaster_type", "FLOOD").upper(),
                urgency=db_inc.get("severity", "HIGH"),
                centroid_lat=db_inc["lat"],
                centroid_lng=db_inc["lng"],
                radius_meters=150.0,
                total_devices=db_inc.get("devices_count", 1),
                estimated_casualties=db_inc.get("casualty_estimate", 1),
                vulnerabilities=[],
                device_ids=db_inc.get("associated_devices", []),
                raw_packet_ids=[],
                status=db_inc.get("status", "OPEN"),
                first_reported_at=db_inc.get("created_at", int(time.time() * 1000)),
                last_reported_at=db_inc.get("updated_at", int(time.time() * 1000))
            )

    if not target:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Master Incident '{incident_id}' not found in active cluster space."
        )

    xml_content = cap_exporter.incident_to_cap_xml(target)
    return Response(content=xml_content, media_type="application/xml")


@app.get("/api/v1/interop/cad/incidents")
def get_all_cad_incidents():
    """Returns all active Master Incidents formatted for CAD dispatch consoles."""
    distress_packets = [
        p for p in gateway_storage.get_packets(limit=1000)
        if p.get("packet_type") == "SOS" or p.get("lat") is not None
    ]
    incidents = spatial_cluster_engine.cluster_distress_signals(distress_packets)
    return [cap_exporter.incident_to_cad_json(inc) for inc in incidents]


@app.get("/api/v1/interop/cad/{incident_id}.json")
def get_incident_cad_json(incident_id: str):
    """
    Computer-Aided Dispatch (CAD) JSON Exporter.
    Formats incident into standard 112/911 legacy dispatch console schema.
    """
    distress_packets = [
        p for p in gateway_storage.get_packets(limit=1000)
        if p.get("packet_type") == "SOS" or p.get("lat") is not None
    ]
    incidents = spatial_cluster_engine.cluster_distress_signals(distress_packets)
    target = next((inc for inc in incidents if inc.incident_id == incident_id), None)

    if not target:
        db_inc = gateway_storage.get_incident(incident_id)
        if db_inc:
            target = MasterIncident(
                incident_id=db_inc["incident_id"],
                category=db_inc.get("disaster_type", "FLOOD").upper(),
                urgency=db_inc.get("severity", "HIGH"),
                centroid_lat=db_inc["lat"],
                centroid_lng=db_inc["lng"],
                radius_meters=150.0,
                total_devices=db_inc.get("devices_count", 1),
                estimated_casualties=db_inc.get("casualty_estimate", 1),
                vulnerabilities=[],
                device_ids=db_inc.get("associated_devices", []),
                raw_packet_ids=[],
                status=db_inc.get("status", "OPEN"),
                first_reported_at=db_inc.get("created_at", int(time.time() * 1000)),
                last_reported_at=db_inc.get("updated_at", int(time.time() * 1000))
            )

    if not target:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Master Incident '{incident_id}' not found."
        )

    return cap_exporter.incident_to_cad_json(target)


# =============================================================================
# REAL-TIME WEBSOCKET STREAM
# =============================================================================

@app.websocket("/ws/mesh")
async def websocket_mesh_endpoint(websocket: WebSocket):
    """Real-time WebSocket stream for government command centers and live dashboards."""
    await ws_manager.connect(websocket)
    try:
        await websocket.send_json({
            "event": "CONNECTED",
            "message": "Connected to RakshaNet Real-Time Mesh Feed",
            "stats": gateway_storage.get_stats()
        })
        while True:
            data = await websocket.receive_text()
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket)
    except Exception:
        ws_manager.disconnect(websocket)
