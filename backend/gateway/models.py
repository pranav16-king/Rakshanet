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
    fix_type: str = Field(default="LIVE_GPS", description="LIVE_GPS, LAST_KNOWN, or ESTIMATED_ZONE")


class PacketPayload(BaseModel):
    ver: int = Field(default=1, description="Protocol version")
    msg_id: str = Field(..., description="Globally unique message identifier")
    sender_id: str = Field(..., description="Anonymous device pseudonym (e.g. SR-8F42)")
    sender_name: str = Field(default="Anonymous Survivor", description="Author display name")
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
