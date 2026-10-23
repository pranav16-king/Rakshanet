"""Focused gateway tests for observed-only incident and mesh data."""

import time
import importlib

import pytest
from fastapi.testclient import TestClient

from backend.gateway.storage import GatewayStorage

gateway_app_module = importlib.import_module("backend.gateway.app")


@pytest.fixture()
def client(tmp_path, monkeypatch):
    """Each test uses an empty local gateway: no operational records are seeded."""
    storage = GatewayStorage(str(tmp_path / "gateway.db"))
    monkeypatch.setattr(gateway_app_module, "gateway_storage", storage)
    return TestClient(gateway_app_module.app)


def test_gateway_starts_empty_and_requires_explicit_credentials(client):
    assert client.get("/api/v1/users").json() == []
    assert client.get("/api/v1/devices").json() == []
    unknown = client.post("/api/v1/auth/login", json={"email": "unknown@example.test", "password": "not-a-real-password"})
    assert unknown.status_code == 401

    created = client.post("/api/v1/users", json={
        "email": "operator@example.test",
        "name": "Test Operator",
        "role": "Administrator",
        "password": "a-long-test-password",
    })
    assert created.status_code == 200
    assert created.json()["location"] is None

    login = client.post("/api/v1/auth/login", json={"email": "operator@example.test", "password": "a-long-test-password"})
    assert login.status_code == 200


def test_ingested_sos_preserves_observed_device_and_location_values(client):
    now = int(time.time() * 1000)
    sync = client.post("/api/v1/telemetry/sync", json={
        "device_id": "TEST-UPLINK",
        "sync_timestamp": now,
        "packets": [{
            "ver": 1,
            "msg_id": "test-sos-001",
            "sender_id": "TEST-SENDER",
            "sender_name": "Test Sender",
            "conv_id": "test-sos-001",
            "ts": now,
            "ttl": 5,
            "hops": 2,
            "type": "SOS",
            "payload": "Test SOS payload",
            "location": {"lat": 12.9716, "lng": 77.5946, "accuracy": 9.0, "fix_type": "LIVE_GPS"},
            "meta": {"urgency": "CRITICAL", "people_count": 2, "battery_percent": 47},
        }],
    })
    assert sync.status_code == 200
    assert sync.json()["accepted_count"] == 1

    devices = client.get("/api/v1/devices").json()
    device = next(item for item in devices if item["device_id"] == "TEST-SENDER")
    assert device["lat"] == 12.9716
    assert device["lng"] == 77.5946
    assert device["battery_pct"] == 47
    assert device["hops_away"] == 2
    assert device["name"] == "Test Sender"

    incidents = client.get("/api/v1/incidents?source=db").json()
    assert len(incidents) == 1
    incident = incidents[0]
    assert incident["incident_id"] == "test-sos-001"
    assert incident["lat"] == 12.9716
    assert incident["lng"] == 77.5946
    assert incident["people_count"] == 2
    assert incident["associated_devices"] == ["TEST-SENDER"]
    communications = client.get("/api/v1/incidents/test-sos-001/communications").json()
    assert communications["summary"]["sos_count"] == 1
    assert communications["sos_alerts"][0]["lat"] == 12.9716
    assert communications["sos_alerts"][0]["battery_pct"] == 47
    assert client.post("/api/v1/telemetry/sync", json={
        "device_id": "TEST-UPLINK", "sync_timestamp": now, "packets": [{
            "ver": 1, "msg_id": "test-sos-001", "sender_id": "TEST-SENDER", "ts": now,
            "ttl": 5, "hops": 2, "type": "SOS", "payload": "Test SOS payload",
        }],
    }).json()["duplicate_count"] == 1


def test_targeted_command_without_verified_key_is_refused(client):
    response = client.post("/api/v1/incidents/TEST-INCIDENT/messages", json={
        "message": "Move to a safer location.",
        "recipient_device_id": "TEST-RECIPIENT",
        "priority": "HIGH",
        "channel": "MESH",
    })
    assert response.status_code == 409
    assert "key" in response.json()["detail"].lower()
