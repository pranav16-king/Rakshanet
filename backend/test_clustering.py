"""
Automated Test Suite for RakshaNet Spatial Incident Clustering (Task 2).
Tests DBSCAN with Haversine distance, 'Devices != People' casualty math,
urgency escalation, and FastAPI incident endpoints.
"""

import sys
import os
import math
import random
from pathlib import Path

# Add backend directory to sys.path
backend_dir = Path(__file__).parent
if str(backend_dir) not in sys.path:
    sys.path.insert(0, str(backend_dir))

from fastapi.testclient import TestClient
from ai_engine.clustering import SpatialClusterEngine, spatial_cluster_engine, MasterIncident
from gateway.app import app
from gateway.storage import gateway_storage


def generate_offset_coord(center_lat: float, center_lng: float, offset_meters: float, bearing_deg: float):
    """Offsets a coordinate by a specific distance in meters in a given compass bearing."""
    R = 6371000.0
    bearing_rad = math.radians(bearing_deg)
    dist_rad = offset_meters / R
    lat_rad = math.radians(center_lat)
    lng_rad = math.radians(center_lng)

    new_lat = math.asin(math.sin(lat_rad) * math.cos(dist_rad) +
                        math.cos(lat_rad) * math.sin(dist_rad) * math.cos(bearing_rad))
    new_lng = lng_rad + math.atan2(math.sin(bearing_rad) * math.sin(dist_rad) * math.cos(lat_rad),
                                   math.cos(dist_rad) - math.sin(lat_rad) * math.sin(new_lat))
    return math.degrees(new_lat), math.degrees(new_lng)


def test_dbscan_clustering_accuracy():
    print("[TEST 1] Running DBSCAN with Spherical Haversine Distance...")
    engine = SpatialClusterEngine(eps_meters=120.0, min_samples=2)

    # Cluster 1: Adyar River Inundation (10 distress nodes within 80 meters)
    cluster1_center = (13.0100, 80.2500)
    cluster1_pings = []
    for i in range(10):
        dist = random.uniform(5.0, 75.0)
        bearing = random.uniform(0, 360)
        lat, lng = generate_offset_coord(cluster1_center[0], cluster1_center[1], dist, bearing)
        cluster1_pings.append({
            "msg_id": f"SOS-ADYAR-{i:03d}",
            "sender_id": f"NODE-ADYAR-{i:03d}",
            "type": "SOS",
            "payload": "Trapped on terrace, water level rising rapidly",
            "location": {"lat": lat, "lng": lng, "accuracy": 5.0},
            "meta": {
                "category": "FLOOD",
                "urgency": "CRITICAL" if i == 0 else "HIGH",
                "casualties": 3 if i % 2 == 0 else 1,
                "vulnerabilities": ["ELDERLY"] if i == 2 else (["INFANT"] if i == 4 else [])
            },
            "timestamp": 1700000000000 + i * 5000
        })

    # Cluster 2: Tambaram Overpass Collapse (8 distress nodes within 50 meters, ~16 km away)
    cluster2_center = (12.9200, 80.1200)
    cluster2_pings = []
    for i in range(8):
        dist = random.uniform(5.0, 45.0)
        bearing = random.uniform(0, 360)
        lat, lng = generate_offset_coord(cluster2_center[0], cluster2_center[1], dist, bearing)
        cluster2_pings.append({
            "msg_id": f"SOS-TAMB-{i:03d}",
            "sender_id": f"NODE-TAMB-{i:03d}",
            "type": "SOS",
            "payload": "Structural debris blocking access, injuries reported",
            "location": {"lat": lat, "lng": lng, "accuracy": 4.0},
            "meta": {
                "category": "COLLAPSE",
                "urgency": "HIGH",
                "casualties": 2,
                "vulnerabilities": ["INJURED"]
            },
            "timestamp": 1700000050000 + i * 3000
        })

    # Outliers: 2 Isolated pings far away
    outlier_pings = [
        {
            "msg_id": "SOS-OUTLIER-001",
            "sender_id": "NODE-OUTLIER-001",
            "type": "SOS",
            "payload": "Single stranded traveler near Chengalpattu",
            "location": {"lat": 12.6900, "lng": 79.9800},
            "meta": {"urgency": "MEDIUM", "casualties": 1},
            "timestamp": 1700000100000
        },
        {
            "msg_id": "SOS-OUTLIER-002",
            "sender_id": "NODE-OUTLIER-002",
            "type": "SOS",
            "payload": "Medical emergency in Sriperumbudur",
            "location": {"lat": 12.9600, "lng": 79.9400},
            "meta": {"urgency": "CRITICAL", "casualties": 1, "vulnerabilities": ["CARDIAC"]},
            "timestamp": 1700000120000
        }
    ]

    all_pings = cluster1_pings + cluster2_pings + outlier_pings
    assert len(all_pings) == 20

    master_incidents = engine.cluster_distress_signals(all_pings)

    # We expect: 2 dense clusters + 2 single-node outlier incidents = 4 master incidents total
    assert len(master_incidents) == 4, f"Expected 4 incidents, got {len(master_incidents)}"

    # Find the two multi-point clusters
    c_adyar = next((inc for inc in master_incidents if inc.total_devices == 10), None)
    c_tamb = next((inc for inc in master_incidents if inc.total_devices == 8), None)

    assert c_adyar is not None, "Failed to identify 10-device Adyar cluster"
    assert c_tamb is not None, "Failed to identify 8-device Tambaram cluster"

    # Centroid verification: within 100 meters of true centers
    dist_adyar = engine._haversine_distance(c_adyar.centroid_lat, c_adyar.centroid_lng, cluster1_center[0], cluster1_center[1])
    dist_tamb = engine._haversine_distance(c_tamb.centroid_lat, c_tamb.centroid_lng, cluster2_center[0], cluster2_center[1])
    assert dist_adyar < 100.0, f"Adyar centroid drifted too far: {dist_adyar}m"
    assert dist_tamb < 100.0, f"Tambaram centroid drifted too far: {dist_tamb}m"

    # Urgency escalation: Since 1 ping in Adyar was CRITICAL, whole cluster must be CRITICAL
    assert c_adyar.urgency == "CRITICAL", f"Adyar urgency expected CRITICAL, got {c_adyar.urgency}"
    assert c_adyar.category == "FLOOD"

    # Radius verification: All points within 120m
    assert c_adyar.radius_meters <= 120.0
    assert c_tamb.radius_meters <= 120.0

    print("  [OK] DBSCAN formed 2 dense clusters + 2 isolated pings with centroid precision < 100m")


def test_devices_not_equal_people_casualty_math():
    print("[TEST 2] Testing 'Devices != People' Population Math & Vulnerability Aggregation...")
    engine = SpatialClusterEngine(eps_meters=150.0, min_samples=2)

    # 3 physical phones transmitting, but representing a family of 12 people
    pings = [
        {
            "msg_id": "SOS-FAMILY-001",
            "sender_id": "PHONE-DAD",
            "type": "SOS",
            "location": {"lat": 13.0827, "lng": 80.2707},
            "meta": {"casualties": 6, "vulnerabilities": ["ELDERLY", "MOBILITY_IMPAIRED"]},
            "timestamp": 1700000000000
        },
        {
            "msg_id": "SOS-FAMILY-002",
            "sender_id": "PHONE-MOM",
            "type": "SOS",
            "location": {"lat": 13.0829, "lng": 80.2709},
            "meta": {"casualties": 4, "vulnerabilities": ["INFANT", "ASTHMA"]},
            "timestamp": 1700000002000
        },
        {
            "msg_id": "SOS-FAMILY-003",
            "sender_id": "PHONE-SON",
            "type": "SOS",
            "location": {"lat": 13.0828, "lng": 80.2708},
            "meta": {"casualties": 2, "vulnerabilities": []},
            "timestamp": 1700000004000
        }
    ]

    incidents = engine.cluster_distress_signals(pings)
    assert len(incidents) == 1
    master = incidents[0]

    assert master.total_devices == 3
    # 6 + 4 + 2 = 12 estimated casualties
    assert master.estimated_casualties == 12, f"Expected 12 casualties, got {master.estimated_casualties}"

    # Aggregated unique vulnerabilities
    assert "ELDERLY" in master.vulnerabilities
    assert "MOBILITY_IMPAIRED" in master.vulnerabilities
    assert "INFANT" in master.vulnerabilities
    assert "ASTHMA" in master.vulnerabilities

    print(f"  [OK] Successfully scaled 3 handsets -> {master.estimated_casualties} casualties across {len(master.vulnerabilities)} vulnerable demographics")


def test_api_gateway_incident_clustering():
    print("[TEST 3] Testing FastAPI Ingestion Gateway + DBSCAN Clustering Endpoints...")
    gateway_storage.clear()
    client = TestClient(app)

    # 1. Ingest 15 raw distress packets into the gateway via /api/v1/telemetry/sync
    cluster_packets = []
    base_lat, base_lng = 13.0400, 80.2400

    for i in range(12):
        dist = random.uniform(10.0, 70.0)
        bearing = random.uniform(0, 360)
        lat, lng = generate_offset_coord(base_lat, base_lng, dist, bearing)
        cluster_packets.append({
            "msg_id": f"SOS-SYNC-{i:03d}",
            "sender_id": f"MULE-NODE-{i:03d}",
            "type": "SOS",
            "payload": f"Emergency rescue request sector {i}",
            "location": {"lat": lat, "lng": lng, "accuracy": 3.0},
            "meta": {"category": "MEDICAL", "urgency": "CRITICAL" if i == 0 else "HIGH", "casualties": 2},
            "ts": 1700000000000 + i * 1000
        })

    # Add 3 isolated packets
    for i in range(3):
        cluster_packets.append({
            "msg_id": f"SOS-SOLO-{i:03d}",
            "sender_id": f"SOLO-NODE-{i:03d}",
            "type": "SOS",
            "payload": f"Isolated distress ping {i}",
            "location": {"lat": 13.1500 + i * 0.1, "lng": 80.3500 + i * 0.1},
            "meta": {"category": "GENERAL_EMERGENCY", "urgency": "LOW", "casualties": 1},
            "ts": 1700000050000 + i * 1000
        })

    sync_payload = {
        "device_id": "SR-MULE-VEHICLE-01",
        "mesh_hop_count": 3,
        "packets": cluster_packets
    }

    res = client.post("/api/v1/telemetry/sync", json=sync_payload)
    assert res.status_code == 200
    assert res.json()["accepted_count"] == 15

    # 2. Query GET /api/v1/incidents
    res_inc = client.get("/api/v1/incidents?eps_meters=120.0&min_samples=2")
    assert res_inc.status_code == 200
    incidents = res_inc.json()

    # 1 cluster of 12 pings + 3 isolated = 4 Master Incidents
    assert len(incidents) == 4, f"Expected 4 incidents from API, got {len(incidents)}"

    top_incident = incidents[0]
    assert top_incident["total_devices"] == 12
    assert top_incident["urgency"] == "CRITICAL"
    assert top_incident["estimated_casualties"] >= 24

    # 3. Trigger POST /api/v1/incidents/cluster
    res_trigger = client.post("/api/v1/incidents/cluster?eps_meters=120.0&min_samples=2")
    assert res_trigger.status_code == 200
    trigger_data = res_trigger.json()
    assert trigger_data["status"] == "CLUSTERED"
    assert trigger_data["incident_count"] == 4
    assert trigger_data["raw_signals_analyzed"] == 15

    print(f"  [OK] Ingested 15 raw packets -> Clustered via API into {len(incidents)} Master Incidents (Top incident: {top_incident['incident_id']})")


if __name__ == "__main__":
    print("=" * 70)
    print("RAKSHANET SPATIAL CLUSTERING TEST SUITE (TASK 2 - DBSCAN AI ENGINE)")
    print("=" * 70)
    test_dbscan_clustering_accuracy()
    test_devices_not_equal_people_casualty_math()
    test_api_gateway_incident_clustering()
    print("=" * 70)
    print("[ALL TESTS PASSED 100%] TASK 2 DBSCAN CLUSTERING VERIFIED SUCCESSFULLY")
    print("=" * 70)
