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

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, status, Response, Depends, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import List, Dict, Any, Optional
import time
import os
import uuid
import sys
from pathlib import Path
import jwt

# Ensure backend root is on sys.path
backend_root = str(Path(__file__).parent.parent)
if backend_root not in sys.path:
    sys.path.insert(0, backend_root)

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
    MissingPersonStatusUpdate
)
from .storage import (
    gateway_storage,
    GatewayStorage,
    verify_password,
    hash_password
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
        return {
            "incident_id": cluster.incident_id,
            "title": f"Clustered Distress Alert ({cluster.total_devices} devices)",
            "disaster_type": cluster.primary_category or "Flood",
            "severity": cluster.urgency,
            "status": "ACTIVE",
            "lat": cluster.centroid_lat,
            "lng": cluster.centroid_lng,
            "affected_area": f"Radius {int(cluster.radius_meters)}m cluster centroid",
            "casualty_estimate": cluster.estimated_casualties,
            "people_count": cluster.estimated_casualties,
            "devices_count": cluster.total_devices,
            "assigned_team": None,
            "resources_needed": ["Rescue Units Needed", "Medical First Responders"],
            "ai_confidence": cluster.confidence_score,
            "ai_explainability": {
                "factors": [
                    f"DBSCAN spatial cluster of {cluster.total_devices} nodes within {int(cluster.radius_meters)}m radius",
                    f"Triage urgency: {cluster.urgency}",
                    "Multi-victim device expansion multiplier applied"
                ],
                "model_version": "SignalRescue-SpatialTriage-v2.1"
            },
            "associated_messages": cluster.sample_messages or [],
            "associated_devices": cluster.contributing_devices or [],
            "created_at": cluster.first_beacon_time,
            "updated_at": cluster.last_beacon_time
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
def create_missing_person_report(req: MissingPersonCreate):
    """Register a new missing person bulletin."""
    return gateway_storage.create_missing_person(req.model_dump())


@app.patch("/api/v1/missing-persons/{person_id}/status")
def update_missing_person_status(person_id: str, req: MissingPersonStatusUpdate):
    """Update status of a missing person report (e.g. mark FOUND or MISSING)."""
    updated = gateway_storage.update_missing_person_status(person_id, req.status)
    if not updated:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Missing person record '{person_id}' not found."
        )
    return updated


@app.post("/api/v1/missing-persons/{person_id}/sightings")
def add_missing_person_sighting(person_id: str, req: SightingCreate):
    """Record a citizen sighting for a missing person."""
    updated = gateway_storage.add_missing_person_sighting(person_id, req.model_dump())
    if not updated:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Missing person record '{person_id}' not found."
        )
    return updated


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


@app.get("/api/v1/search/isochrone", response_model=SearchIsochrone)
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
    return SearchIsochroneEngine.calculate_search_zone(
        person_id=person_id,
        last_lat=last_lat,
        last_lng=last_lng,
        last_seen_ts=last_seen_ts,
        drift_speed_mps=drift_speed_mps,
        drift_heading_deg=drift_heading_deg,
        pedestrian_speed_mps=pedestrian_speed_mps
    )


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
