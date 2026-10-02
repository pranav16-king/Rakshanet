"""
Verification test suite for the FastAPI Opportunistic Ingestion Gateway.
Verifies idempotent batch synchronization, duplicate dropping, and telemetry stats.
"""

import pytest
from fastapi.testclient import TestClient
import time
import os
import tempfile
import sys
from pathlib import Path

# Add backend directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from backend.gateway.app import app
from backend.gateway.storage import gateway_storage

client = TestClient(app)


def setup_function():
    """Reset storage before each test."""
    gateway_storage.clear()


def test_health_check():
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "HEALTHY"
    assert data["gateway"] == "ONLINE"


def test_batch_sync_and_deduplication():
    # Batch 1: Phone A uploads 3 distress packets
    now = int(time.time() * 1000)
    batch_1 = {
        "device_id": "MULE-PHONE-A",
        "sync_timestamp": now,
        "packets": [
            {
                "ver": 1,
                "msg_id": "SOS-TEST-1001",
                "sender_id": "SR-7B1A",
                "sender_name": "Survivor Ankit",
                "conv_id": "CONV_COMMUNITY",
                "ts": now - 5000,
                "ttl": 4,
                "hops": 1,
                "type": "SOS",
                "payload": "Water rising rapidly on 1st floor",
                "location": {"lat": 28.6139, "lng": 77.2090, "accuracy": 10.0, "fix_type": "LIVE_GPS"},
                "meta": {"casualties": 3, "urgency": "CRITICAL"}
            },
            {
                "ver": 1,
                "msg_id": "MSG-TEST-1002",
                "sender_id": "SR-3E9C",
                "sender_name": "Priya",
                "conv_id": "CONV_COMMUNITY",
                "ts": now - 3000,
                "ttl": 5,
                "hops": 0,
                "type": "TEXT",
                "payload": "Bridge road is submerged, do not take south path",
                "location": {"lat": 28.6145, "lng": 77.2095}
            }
        ]
    }

    res1 = client.post("/api/v1/telemetry/sync", json=batch_1)
    assert res1.status_code == 200
    data1 = res1.json()
    assert data1["accepted_count"] == 2
    assert data1["duplicate_count"] == 0
    assert "SOS-TEST-1001" in data1["synced_packet_ids"]

    # Batch 2: Phone B (another data mule) encounters gateway with the SAME SOS-TEST-1001 packet + 1 new packet
    batch_2 = {
        "device_id": "MULE-PHONE-B",
        "sync_timestamp": now + 2000,
        "packets": [
            batch_1["packets"][0],  # Duplicate echo!
            {
                "ver": 1,
                "msg_id": "MSG-TEST-1003",
                "sender_id": "SR-9A2F",
                "sender_name": "Relief Volunteer",
                "conv_id": "CONV_COMMUNITY",
                "ts": now,
                "ttl": 5,
                "hops": 0,
                "type": "TEXT",
                "payload": "Relief camp 2 active with dry food rations"
            }
        ]
    }

    res2 = client.post("/api/v1/telemetry/sync", json=batch_2)
    assert res2.status_code == 200
    data2 = res2.json()
    # Exactly 1 new packet accepted, exactly 1 duplicate dropped!
    assert data2["accepted_count"] == 1
    assert data2["duplicate_count"] == 1
    assert "MSG-TEST-1003" in data2["synced_packet_ids"]
    assert "SOS-TEST-1001" not in data2["synced_packet_ids"]

    # Verify telemetry stats
    stats_res = client.get("/api/v1/telemetry/stats")
    assert stats_res.status_code == 200
    stats = stats_res.json()
    assert stats["unique_packets_stored"] == 3
    assert stats["sos_beacons_count"] == 1
    assert stats["active_mules"] == 2


if __name__ == "__main__":
    setup_function()
    test_health_check()
    test_batch_sync_and_deduplication()
    print("\n  [OK] ALL GATEWAY INGESTION & DEDUPLICATION TESTS PASSED (100%)\n")
