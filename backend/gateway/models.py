"""
Pydantic data models for the RakshaNet Opportunistic Ingestion Gateway.
Enforces strict schema validation, cryptographic payload types, and triage taxonomy.
"""

from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field
import time
import uuid


class LocationPayload(BaseModel):
    lat: float = Field(..., description="Latitude in decimal degrees")
    lng: float = Field(..., description="Longitude in decimal degrees")
    altitude: Optional[float] = Field(None, description="Altitude in meters")
    accuracy: Optional[float] = Field(None, description="Horizontal accuracy radius in meters")
    fix_type: Optional[str] = Field(None, description="Reported location source, when known")


class PacketPayload(BaseModel):
    ver: int = Field(default=1, description="Protocol version")
    msg_id: str = Field(..., description="Globally unique message identifier")
    sender_id: str = Field(..., description="Anonymous device pseudonym (e.g. SR-8F42)")
    sender_name: Optional[str] = Field(None, description="Author display name, when shared")
    conv_id: str = Field(default="CONV_COMMUNITY", description="Target channel or conversation")
    ts: int = Field(..., description="Device timestamp in milliseconds since epoch")
    ttl: int = Field(default=5, description="Remaining Time-To-Live hops")
    hops: int = Field(default=0, description="Cumulative relay hops traversed")
    type: str = Field(default="TEXT", description="Packet type: TEXT, SOS, REPORT, SAFE, BEACON")
    payload: str = Field(..., description="Message text or distress payload")
    recipient_target: Optional[str] = Field(None, description="Target: Nearby, Rescue Team, Gov")
    location: Optional[LocationPayload] = Field(None, description="Geospatial location fix")
    meta: Optional[Dict[str, Any]] = Field(None, description="Extended metadata (urgency, casualties)")
    chk: Optional[str] = Field(None, description="Cryptographic checksum / digital signature")


class SyncBatchRequest(BaseModel):
    device_id: str = Field(..., description="Gateway or data mule device uploading the batch")
    sync_timestamp: int = Field(default_factory=lambda: int(time.time() * 1000))
    lat: Optional[float] = None
    lng: Optional[float] = None
    accuracy: Optional[float] = None
    location: Optional[Dict[str, Any]] = None
    metadata: Optional[Dict[str, Any]] = None
    packets: List[PacketPayload] = Field(default_factory=list, description="Array of buffered packets")


class SyncBatchResponse(BaseModel):
    status: str = "SUCCESS"
    accepted_count: int
    duplicate_count: int
    receipt_id: str
    server_timestamp: int
    synced_packet_ids: List[str]


class IngestStats(BaseModel):
    total_packets_received: int
    unique_packets_stored: int
    duplicates_dropped: int
    active_mules: int
    sos_beacons_count: int
    active_incidents: int


# =============================================================================
# COMMAND CENTER & DUAL-PERSISTENCE API MODELS
# =============================================================================

class LoginRequest(BaseModel):
    email: str = Field(..., description="User email address")
    password: str = Field(..., description="Account password")


class AuthUser(BaseModel):
    id: str
    email: str
    name: str
    role: str
    agency: str
    phone: Optional[str] = None
    status: Optional[str] = "Active"
    location: Optional[str] = None


class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: AuthUser


class UserCreateRequest(BaseModel):
    email: str
    name: str
    role: str = "Responder"
    agency: Optional[str] = None
    phone: Optional[str] = None
    location: Optional[str] = None
    password: str = Field(min_length=12)


class AssignTeamRequest(BaseModel):
    team_id: Optional[str] = None
    team_name: Optional[str] = None


class DashboardOverview(BaseModel):
    total_active_users: int
    active_incidents: int
    critical_incidents: int
    connected_devices: int
    messages_relayed: int
    incident_distribution: Dict[str, int]
    recent_incidents: List[Dict[str, Any]]


class DeviceStats(BaseModel):
    total: int
    online: int
    relay: int
    offline: int


# =============================================================================
# MISSING PERSONS MODELS
# =============================================================================

class SightingCreate(BaseModel):
    reported_by: str = Field(default="Anonymous Citizen")
    location: str = Field(..., description="Location where person was sighted")
    timestamp: Optional[int] = None
    notes: Optional[str] = None
    lat: Optional[float] = None
    lng: Optional[float] = None
    photo_url: Optional[str] = None
    photo_base64: Optional[str] = None


class MissingPersonCreate(BaseModel):
    id: Optional[str] = None
    name: str = Field(..., description="Name of the missing individual")
    age: int = Field(..., description="Age in years")
    gender: Optional[str] = "Unspecified"
    last_seen_location: str = Field(..., description="Last known location / landmark")
    lat: Optional[float] = None
    lng: Optional[float] = None
    description: Optional[str] = ""
    photo_url: Optional[str] = None
    photo_base64: Optional[str] = None
    contact_phone: Optional[str] = None
    status: Optional[str] = "MISSING"
    reported_by: Optional[str] = "Anonymous"
    # Extended disaster incident & identification attributes
    incident_id: Optional[str] = None
    incident_title: Optional[str] = None
    clothing_last_seen: Optional[str] = None
    height_cm: Optional[int] = 0
    identifying_marks: Optional[str] = None
    medical_needs: Optional[str] = None
    blood_group: Optional[str] = None
    priority: Optional[str] = "HIGH"
    assigned_team: Optional[str] = None
    biometric_indexed: Optional[bool] = False


class MissingPersonStatusUpdate(BaseModel):
    status: str = Field(..., description="New status: 'MISSING' or 'FOUND'")


class PhotoSearchRequest(BaseModel):
    photo_base64: Optional[str] = None
    photo_url: Optional[str] = None
    top_k: int = 5
    score_threshold: float = 0.65


class PhotoSearchResponse(BaseModel):
    match_found: bool
    matches: List[Dict[str, Any]] = Field(default_factory=list)
    top_match: Optional[Dict[str, Any]] = None


class PhotoUploadRequest(BaseModel):
    photo_base64: Optional[str] = None
    photo_url: Optional[str] = None


class IncidentStatusUpdate(BaseModel):
    status: str = Field(..., description="OPEN, INVESTIGATING, DISPATCHED, CONTAINED, or RESOLVED")
    notes: Optional[str] = Field(None, description="Optional transition notes")


class IncidentBroadcastMessage(BaseModel):
    message: str = Field(..., description="Message content to broadcast to the incident mesh area")
    priority: str = Field(default="HIGH", description="CRITICAL, HIGH, MEDIUM, LOW")
    channel: str = Field(default="ALL_CHANNELS", description="BLE_MESH, SATELLITE, LORA")
    recipient_device_id: Optional[str] = Field(None, description="Required for a targeted field instruction")
    recipient_encryption_key: Optional[str] = Field(None, description="Recipient's verified public encryption key")


class AiChatRequest(BaseModel):
    query: str = Field(..., description="Emergency survival query or message")
    conversation_history: Optional[List[Dict[str, str]]] = Field(default_factory=list, description="Prior conversational context")
    category: Optional[str] = Field(None, description="Disaster category (Medical, Hazards, Rescue, CBRN, Survival)")
    telemetry: Optional[Dict[str, Any]] = Field(None, description="Anonymized device telemetry (battery, mesh peers)")


class AiChatResponse(BaseModel):
    request_id: str
    answer: str
    engine: str
    status: str
    sources: List[Dict[str, str]] = Field(default_factory=list)
    warnings: Optional[str] = None
    steps: List[str] = Field(default_factory=list)
    category: str


# =============================================================================
# MESH GROUPS & CHAT CHANNELS
# =============================================================================

class MeshGroupMember(BaseModel):
    device_id: str
    name: str
    role: Optional[str] = "member"
    status: Optional[str] = "ACCEPTED"
    joined_at: Optional[int] = None


class MeshGroupCreate(BaseModel):
    group_id: str
    name: str
    description: Optional[str] = None
    creator_id: str
    conversation_id: Optional[str] = None
    member_count: Optional[int] = 1
    members: Optional[List[MeshGroupMember]] = None


class MeshGroupJoinRequest(BaseModel):
    device_id: str
    name: str
    role: Optional[str] = "member"


class MeshGroupResponse(BaseModel):
    group_id: str
    name: str
    description: Optional[str] = None
    creator_id: str
    conversation_id: str
    member_count: int
    created_at: int
    updated_at: int
    members: List[Dict[str, Any]] = Field(default_factory=list)

    urgency: str
    created_at: int
    error_detail: Optional[str] = None


