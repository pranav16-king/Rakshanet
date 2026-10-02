"""
RakshaNet Opportunistic Ingestion Gateway (FastAPI).
Serves as the high-throughput bridge connecting mobile DTN mesh nodes to the cloud command intelligence layer.
"""

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, status, Response
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Dict, Any, Optional
import time
import uuid
import sys
from pathlib import Path

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
from .models import SyncBatchRequest, SyncBatchResponse, PacketPayload, IngestStats
from .storage import gateway_storage, GatewayStorage

app = FastAPI(
    title="RakshaNet Opportunistic Ingestion Gateway",
    description="Offline disaster mesh telemetry ingestion, cryptographic deduplication, and WebSocket broadcast hub.",
    version="2.0.0"
)

# Enable CORS for local command center dashboards
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
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


@app.get("/")
def root():
    return {
        "platform": "RakshaNet (SignalRescue AI)",
        "service": "Opportunistic Ingestion Gateway",
        "version": "2.0.0",
        "status": "ONLINE",
        "documentation": "/docs"
    }


@app.get("/api/v1/health")
def health_check():
    return {
        "status": "HEALTHY",
        "timestamp": int(time.time() * 1000),
        "gateway": "ONLINE"
    }


@app.post("/api/v1/telemetry/sync", response_model=SyncBatchResponse)
async def sync_telemetry_batch(batch: SyncBatchRequest):
    """
    Opportunistic batch ingestion endpoint.
    Invoked when any handset reaches cellular fringe, field Wi-Fi, or satellite uplink.
    Idempotently deduplicates all packets carried by moving data mules.
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


@app.get("/api/v1/incidents", response_model=List[MasterIncident])
def get_clustered_incidents(eps_meters: float = 120.0, min_samples: int = 2):
    """
    DBSCAN Spatial Incident Clustering (Feature 15 & 19).
    Scans stored distress/SOS telemetry and aggregates nearby signals into Master Incidents.
    """
    all_packets = gateway_storage.get_packets(limit=1000)
    distress_packets = [
        p for p in all_packets
        if p.get("packet_type") == "SOS" or 
           (p.get("meta_json") and "urgency" in str(p.get("meta_json", ""))) or
           p.get("lat") is not None
    ]
    engine = SpatialClusterEngine(eps_meters=eps_meters, min_samples=min_samples) if (eps_meters != 120.0 or min_samples != 2) else spatial_cluster_engine
    return engine.cluster_distress_signals(distress_packets)


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

    # Real-time WebSocket broadcast to connected incident command dispatchers
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


# Standard active disaster response fleet registry
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
    # 1. Gather active incidents
    distress_packets = [
        p for p in gateway_storage.get_packets(limit=1000)
        if p.get("packet_type") == "SOS" or p.get("lat") is not None
    ]
    incidents = spatial_cluster_engine.cluster_distress_signals(distress_packets)
    incidents_dict = [inc.model_dump() for inc in incidents]

    # 2. Select fleet
    units_to_use = custom_units if (custom_units and len(custom_units) > 0) else ACTIVE_RESCUE_FLEET

    # 3. Solve optimization
    plan = dispatch_optimizer.optimize_dispatch(incidents=incidents_dict, units=units_to_use)

    # 4. Broadcast dispatch plan to incident command dashboards
    await ws_manager.broadcast({
        "event": "DISPATCH_PLAN_GENERATED",
        "plan_id": plan.plan_id,
        "assigned_count": plan.assigned_count,
        "total_casualties_addressed": plan.total_casualties_addressed,
        "assignments": [a.model_dump() for a in plan.assignments],
        "timestamp": int(time.time() * 1000)
    })

    return plan


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
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Master Incident '{incident_id}' not found in active cluster space."
        )

    xml_content = cap_exporter.incident_to_cap_xml(target)
    return Response(content=xml_content, media_type="application/xml")


@app.get("/api/v1/interop/cap/feed.xml")
def get_cap_alert_feed():
    """
    Aggregated CAP v1.2 XML alert feed containing all active Master Incidents.
    """
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
        # Strip header from individual XML documents for feed inclusion
        raw_xml = cap_exporter.incident_to_cap_xml(inc)
        lines = [line for line in raw_xml.split("\n") if not line.strip().startswith("<?xml")]
        feed_lines.append("\n".join(lines))

    feed_lines.append("</alerts>")
    return Response(content="\n".join(feed_lines), media_type="application/xml")


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
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Master Incident '{incident_id}' not found."
        )

    return cap_exporter.incident_to_cad_json(target)


@app.get("/api/v1/interop/cad/incidents")
def get_all_cad_incidents():
    """Returns all active Master Incidents formatted for CAD dispatch consoles."""
    distress_packets = [
        p for p in gateway_storage.get_packets(limit=1000)
        if p.get("packet_type") == "SOS" or p.get("lat") is not None
    ]
    incidents = spatial_cluster_engine.cluster_distress_signals(distress_packets)
    return [cap_exporter.incident_to_cad_json(inc) for inc in incidents]


@app.websocket("/ws/mesh")
async def websocket_mesh_endpoint(websocket: WebSocket):
    """Real-time WebSocket stream for government command centers and live dashboards."""
    await ws_manager.connect(websocket)
    try:
        # Send initial connection handshake and stats
        await websocket.send_json({
            "event": "CONNECTED",
            "message": "Connected to RakshaNet Real-Time Mesh Feed",
            "stats": gateway_storage.get_stats()
        })
        while True:
            # Keep connection alive & listen for client pings
            data = await websocket.receive_text()
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket)
    except Exception:
        ws_manager.disconnect(websocket)
