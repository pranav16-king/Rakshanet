"""
Automated Test Suite for RakshaNet Communication-Gap & Black Hole Anomaly Detector (Task 3).
Tests spatiotemporal decay curve analysis, critical silence detection,
'Devices != People' casualty scaling, and FastAPI anomaly endpoints.
"""

import sys
import time
from pathlib import Path

# Add backend directory to sys.path
backend_dir = Path(__file__).parent
if str(backend_dir) not in sys.path:
    sys.path.insert(0, str(backend_dir))

from fastapi.testclient import TestClient
from ai_engine.black_hole import BlackHoleDetector, black_hole_detector, BlackHoleAnomaly
from gateway.app import app
from gateway.storage import gateway_storage


def test_black_hole_catastrophic_decay():
    print("[TEST 1] Testing Catastrophic Telemetry Collapse (50 -> 2 Nodes)...")
    detector = BlackHoleDetector(
        min_baseline_nodes=10,
        critical_drop_pct=75.0,
        warning_drop_pct=45.0,
        time_bucket_minutes=30,
        num_buckets=4
    )

    now_ms = 1700000000000
    # 4 buckets of 30 mins each:
    # Bucket 0: [now - 120m, now - 90m]
    # Bucket 1: [now - 90m, now - 60m]
    # Bucket 2: [now - 60m, now - 30m]
    # Bucket 3: [now - 30m, now]

    packets = []

    # Sector A (Isolated Hamlet like Tiru): lat 13.0550, lng 80.2150
    # Bucket 0: 50 active unique devices
    b0_time = now_ms - 105 * 60 * 1000
    for i in range(50):
        packets.append({
            "msg_id": f"BEACON-SEC-A-B0-{i:03d}",
            "sender_id": f"DEV-TIRU-{i:03d}",
            "type": "BEACON",
            "lat": 13.0550 + (i % 5) * 0.0005,
            "lng": 80.2150 + (i % 5) * 0.0005,
            "ts": b0_time + i * 100
        })

    # Bucket 1: 45 active unique devices
    b1_time = now_ms - 75 * 60 * 1000
    for i in range(45):
        packets.append({
            "msg_id": f"BEACON-SEC-A-B1-{i:03d}",
            "sender_id": f"DEV-TIRU-{i:03d}",
            "type": "BEACON",
            "lat": 13.0550 + (i % 5) * 0.0005,
            "lng": 80.2150 + (i % 5) * 0.0005,
            "ts": b1_time + i * 100
        })

    # Bucket 2: 12 active unique devices (flash flood hit)
    b2_time = now_ms - 45 * 60 * 1000
    for i in range(12):
        packets.append({
            "msg_id": f"BEACON-SEC-A-B2-{i:03d}",
            "sender_id": f"DEV-TIRU-{i:03d}",
            "type": "BEACON",
            "lat": 13.0550 + (i % 5) * 0.0005,
            "lng": 80.2150 + (i % 5) * 0.0005,
            "ts": b2_time + i * 100
        })

    # Bucket 3: Only 2 active unique devices left (total blackout)
    b3_time = now_ms - 15 * 60 * 1000
    for i in range(2):
        packets.append({
            "msg_id": f"BEACON-SEC-A-B3-{i:03d}",
            "sender_id": f"DEV-TIRU-{i:03d}",
            "type": "BEACON",
            "lat": 13.0550 + (i % 5) * 0.0005,
            "lng": 80.2150 + (i % 5) * 0.0005,
            "ts": b3_time + i * 100
        })

    anomalies = detector.detect_anomalies(packets, current_time_ms=now_ms)

    assert len(anomalies) == 1, f"Expected 1 black hole anomaly, got {len(anomalies)}"
    anom = anomalies[0]

    assert anom.severity == "CRITICAL", f"Expected CRITICAL severity, got {anom.severity}"
    assert anom.baseline_nodes == 50
    assert anom.current_nodes == 2
    assert anom.drop_percentage >= 95.0, f"Expected >= 95% drop, got {anom.drop_percentage}%"
    assert "AERIAL_RECON_DRONE" in anom.recommended_action
    # 48 devices lost * 2.5 = 120 silenced people
    assert anom.estimated_silenced_people >= 100

    print(f"  [OK] Successfully detected CRITICAL Black Hole in {anom.sector_id}: "
          f"{anom.baseline_nodes} -> {anom.current_nodes} nodes ({anom.drop_percentage}% drop, "
          f"~{anom.estimated_silenced_people} silenced people)")


def test_steady_and_gradual_sectors():
    print("[TEST 2] Testing Resilience Against False Positives (Steady & Evacuation Sectors)...")
    detector = BlackHoleDetector(
        min_baseline_nodes=10,
        critical_drop_pct=75.0,
        warning_drop_pct=45.0,
        time_bucket_minutes=30,
        num_buckets=4
    )

    now_ms = 1700000000000
    packets = []

    # Sector B: Steady Relief Camp (30 devices active across all buckets)
    for b_idx, count in enumerate([30, 32, 29, 31]):
        b_time = now_ms - (105 - b_idx * 30) * 60 * 1000
        for i in range(count):
            packets.append({
                "msg_id": f"BEACON-SEC-B-{b_idx}-{i:03d}",
                "sender_id": f"DEV-CAMP-{i:03d}",
                "lat": 13.0120,
                "lng": 80.2310,
                "ts": b_time + i * 100
            })

    # Sector C: Orderly Evacuation (Gradual 25% drop: 20 -> 18 -> 16 -> 15)
    for b_idx, count in enumerate([20, 18, 16, 15]):
        b_time = now_ms - (105 - b_idx * 30) * 60 * 1000
        for i in range(count):
            packets.append({
                "msg_id": f"BEACON-SEC-C-{b_idx}-{i:03d}",
                "sender_id": f"DEV-EVAC-{i:03d}",
                "lat": 12.9800,
                "lng": 80.1800,
                "ts": b_time + i * 100
            })

    anomalies = detector.detect_anomalies(packets, current_time_ms=now_ms)
    assert len(anomalies) == 0, f"Expected 0 false positive anomalies, got {len(anomalies)}"

    print("  [OK] Zero false positives: Steady relief camps and orderly evacuations correctly ignored")


def test_api_gateway_black_hole_endpoints():
    print("[TEST 3] Testing FastAPI Black Hole Endpoints & Alert Broadcasts...")
    gateway_storage.clear()
    client = TestClient(app)

    now_ms = int(time.time() * 1000)
    packets = []

    # Inject collapsing sector: 20 nodes 90 mins ago, 1 node right now
    for i in range(20):
        packets.append({
            "msg_id": f"SOS-COLLAPSE-OLD-{i:03d}",
            "sender_id": f"SURVIVOR-{i:03d}",
            "type": "BEACON",
            "payload": "Sector health beacon",
            "location": {"lat": 13.0300, "lng": 80.2200},
            "ts": now_ms - 90 * 60 * 1000 + i * 1000
        })

    packets.append({
        "msg_id": "SOS-COLLAPSE-LATEST-001",
        "sender_id": "SURVIVOR-000",
        "type": "BEACON",
        "payload": "Sole surviving radio beacon",
        "location": {"lat": 13.0300, "lng": 80.2200},
        "ts": now_ms - 5 * 60 * 1000
    })

    sync_payload = {
        "device_id": "SR-MULE-SCOUT-09",
        "mesh_hop_count": 2,
        "packets": packets
    }

    # 1. Ingest via gateway
    res_sync = client.post("/api/v1/telemetry/sync", json=sync_payload)
    assert res_sync.status_code == 200
    assert res_sync.json()["accepted_count"] == 21

    # 2. Query GET /api/v1/anomalies/black-holes
    res_get = client.get("/api/v1/anomalies/black-holes?min_baseline_nodes=10&critical_drop_pct=70.0")
    assert res_get.status_code == 200
    anomalies = res_get.json()
    assert len(anomalies) >= 1
    assert anomalies[0]["severity"] == "CRITICAL"
    assert anomalies[0]["drop_percentage"] >= 90.0

    # 3. Trigger POST /api/v1/anomalies/black-holes/scan
    res_scan = client.post("/api/v1/anomalies/black-holes/scan?min_baseline_nodes=10&critical_drop_pct=70.0")
    assert res_scan.status_code == 200
    scan_result = res_scan.json()
    assert scan_result["status"] == "SCANNED"
    assert scan_result["critical_count"] >= 1
    assert scan_result["anomaly_count"] >= 1

    print(f"  [OK] Ingested 21 telemetry points -> API surfaced {scan_result['anomaly_count']} Black Hole anomaly: "
          f"{scan_result['anomalies'][0]['anomaly_id']} ({scan_result['anomalies'][0]['drop_percentage']}% drop)")


if __name__ == "__main__":
    print("=" * 70)
    print("RAKSHANET BLACK HOLE ANOMALY DETECTOR TEST SUITE (TASK 3)")
    print("=" * 70)
    test_black_hole_catastrophic_decay()
    test_steady_and_gradual_sectors()
    test_api_gateway_black_hole_endpoints()
    print("=" * 70)
    print("[ALL TESTS PASSED 100%] TASK 3 BLACK HOLE DETECTOR VERIFIED SUCCESSFULLY")
    print("=" * 70)
