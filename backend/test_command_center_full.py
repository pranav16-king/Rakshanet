"""End-to-end checks that do not depend on seeded operational records."""

import importlib
import time

import pytest
from fastapi.testclient import TestClient

from backend.gateway.storage import GatewayStorage

gateway_app_module = importlib.import_module("backend.gateway.app")


@pytest.fixture()
def client(tmp_path, monkeypatch):
    storage = GatewayStorage(str(tmp_path / "e2e-gateway.db"))
    monkeypatch.setattr(gateway_app_module, "gateway_storage", storage)
    return TestClient(gateway_app_module.app)


def test_command_center_full_suite(client):
    assert client.get("/api/v1/health").status_code == 200
    assert client.get("/api/v1/incidents?source=db").json() == []
    assert client.get("/api/v1/devices").json() == []

    created = client.post("/api/v1/users", json={
        "email": "e2e.operator@example.test", "name": "E2E Operator", "role": "Administrator",
        "agency": "Test Operations", "password": "explicit-e2e-password",
    })
    assert created.status_code == 200
    login = client.post("/api/v1/auth/login", json={"email": "e2e.operator@example.test", "password": "explicit-e2e-password"})
    assert login.status_code == 200
    headers = {"Authorization": f"Bearer {login.json()['access_token']}"}
    assert client.get("/api/v1/auth/me", headers=headers).json()["email"] == "e2e.operator@example.test"

    timestamp = int(time.time() * 1000)
    sync = client.post("/api/v1/telemetry/sync", json={
        "device_id": "E2E-UPLINK", "sync_timestamp": timestamp,
        "packets": [{
            "ver": 1, "msg_id": "e2e-observed-sos", "sender_id": "E2E-SENDER", "ts": timestamp,
            "ttl": 4, "hops": 1, "type": "SOS", "payload": "E2E SOS", "location": {"lat": 18.5204, "lng": 73.8567},
        }],
    })
    assert sync.status_code == 200 and sync.json()["accepted_count"] == 1
    device = next(item for item in client.get("/api/v1/devices", headers=headers).json() if item["device_id"] == "E2E-SENDER")
    assert (device["lat"], device["lng"], device["hops_away"]) == (18.5204, 73.8567, 1)
    incident = client.get("/api/v1/incidents/e2e-observed-sos", headers=headers).json()
    assert (incident["lat"], incident["lng"], incident["associated_devices"]) == (18.5204, 73.8567, ["E2E-SENDER"])
    assert client.get("/api/v1/messages", headers=headers).status_code == 200
    assert client.get("/api/v1/dashboard/overview", headers=headers).status_code == 200
    assert client.get("/api/v1/interop/cap/feed.xml").status_code == 200
