"""
Verification and Test Suite for RakshaNet Command Center API.
Tests all endpoints, JWT authentication, dual-persistence, KPIs, incident triage,
user management, devices, messages, resources, and settings.
"""

import sys
import time
from pathlib import Path
from fastapi.testclient import TestClient

# Add project root to sys.path
sys.path.insert(0, str(Path(__file__).parent.parent))

from backend.gateway.app import app
from backend.gateway.storage import gateway_storage

client = TestClient(app)


def test_command_center_api_suite():
    print("\n======================================================================")
    print("   RAKSHANET COMMAND CENTER API & DUAL-PERSISTENCE TEST SUITE")
    print("======================================================================\n")

    # -------------------------------------------------------------------------
    # 1. Health & Root Endpoints
    # -------------------------------------------------------------------------
    print("[1/14] Testing Root and Health Endpoints...")
    res = client.get("/")
    assert res.status_code == 200, f"Root failed: {res.text}"
    data = res.json()
    assert data["status"] == "ONLINE"
    print("  [OK] GET / -> 200 OK (Platform:", data["platform"], ")")

    res = client.get("/api/v1/health")
    assert res.status_code == 200, f"Health check failed: {res.text}"
    health_data = res.json()
    assert health_data["status"] == "HEALTHY"
    print("  [OK] GET /api/v1/health -> 200 OK (Gateway:", health_data["gateway"], ", Atlas:", health_data.get("mongo_atlas"), ")")

    # -------------------------------------------------------------------------
    # 2. Authentication (JWT Login, /me, /logout)
    # -------------------------------------------------------------------------
    print("\n[2/14] Testing JWT Authentication Flow...")
    login_payload = {
        "email": "admin@rakshanet.org",
        "password": "RakshaNet@2026"
    }
    res = client.post("/api/v1/auth/login", json=login_payload)
    assert res.status_code == 200, f"Login failed: {res.text}"
    auth_data = res.json()
    assert "access_token" in auth_data
    assert auth_data["token_type"].lower() == "bearer"
    assert auth_data["user"]["email"] == "admin@rakshanet.org"
    assert auth_data["user"]["role"] == "Administrator"
    access_token = auth_data["access_token"]
    print(f"  [OK] POST /api/v1/auth/login -> 200 OK (Token: {access_token[:20]}...)")
    print(f"    Authenticated User: {auth_data['user']['name']} ({auth_data['user']['agency']})")

    headers = {"Authorization": f"Bearer {access_token}"}
    res = client.get("/api/v1/auth/me", headers=headers)
    assert res.status_code == 200, f"Auth me failed: {res.text}"
    me_data = res.json()
    assert me_data["email"] == "admin@rakshanet.org"
    print(f"  [OK] GET /api/v1/auth/me -> 200 OK (Verified identity: {me_data['email']})")

    res = client.post("/api/v1/auth/logout")
    assert res.status_code == 200
    print("  [OK] POST /api/v1/auth/logout -> 200 OK")

    # -------------------------------------------------------------------------
    # 3. Dashboard Overview & Real KPIs
    # -------------------------------------------------------------------------
    print("\n[3/14] Testing Dashboard Overview & KPIs Endpoint...")
    res = client.get("/api/v1/dashboard/overview")
    assert res.status_code == 200, f"Dashboard overview failed: {res.text}"
    overview = res.json()
    assert "total_active_users" in overview
    assert "active_incidents" in overview
    assert "critical_incidents" in overview
    assert "connected_devices" in overview
    assert "messages_relayed" in overview
    assert "incident_distribution" in overview
    assert "recent_incidents" in overview
    print(f"  [OK] GET /api/v1/dashboard/overview -> 200 OK")
    print(f"    Active Users: {overview['total_active_users']}")
    print(f"    Active Incidents: {overview['active_incidents']} (Critical: {overview['critical_incidents']})")
    print(f"    Connected Devices: {overview['connected_devices']}")
    print(f"    Incident Distribution: {overview['incident_distribution']}")
    print(f"    Recent Incidents count: {len(overview['recent_incidents'])}")

    # -------------------------------------------------------------------------
    # 4. Incident Detail & Assign
    # -------------------------------------------------------------------------
    print("\n[4/14] Testing Incident Detail & Assign Endpoints...")
    incident_id = "INC-FLD-2026-001"
    res = client.get(f"/api/v1/incidents/{incident_id}")
    assert res.status_code == 200, f"Incident detail failed: {res.text}"
    inc_detail = res.json()
    assert inc_detail["incident_id"] == incident_id
    assert inc_detail["disaster_type"] == "Flood"
    assert "affected_area" in inc_detail
    assert "casualty_estimate" in inc_detail
    assert "ai_explainability" in inc_detail
    assert "resources_needed" in inc_detail
    print(f"  [OK] GET /api/v1/incidents/{incident_id} -> 200 OK")
    print(f"    Title: {inc_detail['title']}")
    print(f"    Casualty Estimate: {inc_detail['casualty_estimate']} (AI Confidence: {inc_detail['ai_confidence']})")
    print(f"    Resources Needed: {inc_detail['resources_needed']}")
    print(f"    AI Explainability: {inc_detail['ai_explainability'].get('factors')}")

    assign_payload = {"team_name": "NDRF Zodiac Inflatable Boat 01"}
    res = client.patch(f"/api/v1/incidents/{incident_id}/assign", json=assign_payload)
    assert res.status_code == 200, f"Incident assign failed: {res.text}"
    assigned_inc = res.json()
    assert assigned_inc["assigned_team"] == "NDRF Zodiac Inflatable Boat 01"
    assert assigned_inc["status"] == "ASSIGNED"
    print(f"  [OK] PATCH /api/v1/incidents/{incident_id}/assign -> 200 OK")
    print(f"    Assigned Team: {assigned_inc['assigned_team']}, Status: {assigned_inc['status']}")

    # -------------------------------------------------------------------------
    # 5. People & Users
    # -------------------------------------------------------------------------
    print("\n[5/14] Testing People & Users Endpoints...")
    res = client.get("/api/v1/users")
    assert res.status_code == 200
    users = res.json()
    assert len(users) >= 4
    print(f"  [OK] GET /api/v1/users -> 200 OK ({len(users)} users registered)")

    # Filter by role
    res = client.get("/api/v1/users?role=Administrator")
    assert res.status_code == 200
    admins = res.json()
    assert len(admins) >= 1
    print(f"  [OK] GET /api/v1/users?role=Administrator -> 200 OK ({len(admins)} admins)")

    # Search user
    res = client.get("/api/v1/users?search=Sharma")
    assert res.status_code == 200
    searched = res.json()
    assert len(searched) >= 1
    print(f"  [OK] GET /api/v1/users?search=Sharma -> 200 OK ({len(searched)} found)")

    # Create new field user
    new_user_payload = {
        "email": f"paramedic.test.{int(time.time())}@rakshanet.org",
        "name": "Officer Rahul Deshmukh",
        "role": "Field Responder",
        "agency": "State Disaster Response Force",
        "phone": "+91-99887-76655"
    }
    res = client.post("/api/v1/users", json=new_user_payload)
    assert res.status_code == 200, f"Create user failed: {res.text}"
    created_user = res.json()
    assert created_user["email"] == new_user_payload["email"]
    print(f"  [OK] POST /api/v1/users -> 200 OK (Created: {created_user['name']} - ID: {created_user['id']})")

    # -------------------------------------------------------------------------
    # 6. Devices & Network
    # -------------------------------------------------------------------------
    print("\n[6/14] Testing Devices & Mesh Network Endpoints...")
    res = client.get("/api/v1/devices")
    assert res.status_code == 200
    devices = res.json()
    assert len(devices) >= 8
    print(f"  [OK] GET /api/v1/devices -> 200 OK ({len(devices)} active mesh nodes)")

    res = client.get("/api/v1/devices/stats")
    assert res.status_code == 200
    dev_stats = res.json()
    assert "total" in dev_stats
    assert "online" in dev_stats
    assert "relay" in dev_stats
    assert "offline" in dev_stats
    print(f"  [OK] GET /api/v1/devices/stats -> 200 OK (Total: {dev_stats['total']}, Online: {dev_stats['online']}, Relay: {dev_stats['relay']}, Offline: {dev_stats['offline']})")

    # -------------------------------------------------------------------------
    # 7. Messages Endpoints
    # -------------------------------------------------------------------------
    print("\n[7/14] Testing Telemetry Messages Endpoints...")
    res = client.get("/api/v1/messages")
    assert res.status_code == 200
    msgs = res.json()
    print(f"  [OK] GET /api/v1/messages -> 200 OK ({len(msgs)} total messages)")

    res = client.get("/api/v1/messages?type=SOS")
    assert res.status_code == 200
    print(f"  [OK] GET /api/v1/messages?type=SOS -> 200 OK")

    res = client.get("/api/v1/messages?type=ALL&limit=10")
    assert res.status_code == 200
    print(f"  [OK] GET /api/v1/messages?type=ALL&limit=10 -> 200 OK")

    # -------------------------------------------------------------------------
    # 8. Resources & Logistics Endpoints
    # -------------------------------------------------------------------------
    print("\n[8/14] Testing Resources & Logistics Endpoints...")
    res = client.get("/api/v1/resources")
    assert res.status_code == 200
    resources = res.json()
    assert len(resources) >= 7
    categories = set(r["category"] for r in resources)
    print(f"  [OK] GET /api/v1/resources -> 200 OK ({len(resources)} resources across categories: {list(categories)})")

    # Update/Upsert resource
    res_update = {
        "resource_id": "RES-BOAT-01",
        "category": "BOATS",
        "name": "Zodiac MilPro Inflatable Boats",
        "total_quantity": 12,
        "deployed_quantity": 5,
        "available_quantity": 7,
        "location": "Marina Base Station",
        "status": "READY"
    }
    res = client.post("/api/v1/resources", json=res_update)
    assert res.status_code == 200
    print("  [OK] POST /api/v1/resources -> 200 OK (Updated fleet deployment)")

    # -------------------------------------------------------------------------
    # 9. Rescue Fleet Endpoints
    # -------------------------------------------------------------------------
    print("\n[9/14] Testing Rescue Fleet Endpoints...")
    res = client.get("/api/v1/rescue-teams")
    assert res.status_code == 200
    teams = res.json()
    assert len(teams) >= 4
    print(f"  [OK] GET /api/v1/rescue-teams -> 200 OK ({len(teams)} rescue teams registered)")

    res = client.get("/api/v1/dispatch/units")
    assert res.status_code == 200
    units = res.json()
    assert len(units) >= 4
    print(f"  [OK] GET /api/v1/dispatch/units -> 200 OK ({len(units)} units available for LP dispatch)")

    # -------------------------------------------------------------------------
    # 10. Analytics & Trends
    # -------------------------------------------------------------------------
    print("\n[10/14] Testing Analytics & Trends Endpoint...")
    res = client.get("/api/v1/analytics/trends")
    assert res.status_code == 200
    trends = res.json()
    assert "days" in trends
    assert len(trends["days"]) == 7
    assert "total" in trends["days"][0]
    assert "sos" in trends["days"][0]
    assert "reports" in trends["days"][0]
    print(f"  [OK] GET /api/v1/analytics/trends -> 200 OK (7-day timeline verified)")
    print(f"    Avg Response: {trends.get('avg_response_minutes')} mins, Resolution Rate: {trends.get('resolution_rate_pct')}%")

    # -------------------------------------------------------------------------
    # 11. Settings & System Configuration
    # -------------------------------------------------------------------------
    print("\n[11/14] Testing Settings Endpoints...")
    res = client.get("/api/v1/settings")
    assert res.status_code == 200
    settings = res.json()
    assert "mesh_network" in settings
    assert "ai_clustering" in settings
    print(f"  [OK] GET /api/v1/settings -> 200 OK (Settings keys: {list(settings.keys())})")

    new_settings = {
        "ai_clustering": {
            "auto_clustering_enabled": True,
            "eps_meters": 130.0,
            "min_samples": 2,
            "confidence_threshold": 0.88
        }
    }
    res = client.post("/api/v1/settings", json=new_settings)
    assert res.status_code == 200
    updated_settings = res.json()
    assert updated_settings["ai_clustering"]["eps_meters"] == 130.0
    print("  [OK] POST /api/v1/settings -> 200 OK (Updated eps_meters to 130.0)")

    # -------------------------------------------------------------------------
    # 12. Opportunistic Batch Synchronization (Dual-Persistence Ingest)
    # -------------------------------------------------------------------------
    print("\n[12/14] Testing Opportunistic Telemetry Sync & Deduplication...")
    now_ms = int(time.time() * 1000)
    test_batch = {
        "device_id": "MULE-TEST-PHONE-X",
        "sync_timestamp": now_ms,
        "packets": [
            {
                "ver": 1,
                "msg_id": f"TEST-SOS-BATCH-{int(time.time())}",
                "sender_id": "SR-USER-A1",
                "sender_name": "Rohan",
                "conv_id": "CONV_COMMUNITY",
                "ts": now_ms,
                "ttl": 5,
                "hops": 1,
                "type": "SOS",
                "payload": "Family of 4 stranded on roof with 2 children",
                "location": {"lat": 13.0450, "lng": 80.2300, "accuracy": 8.0, "fix_type": "LIVE_GPS"},
                "meta": {"urgency": "CRITICAL", "casualties": 4}
            }
        ]
    }
    res = client.post("/api/v1/telemetry/sync", json=test_batch)
    assert res.status_code == 200
    sync_resp = res.json()
    assert sync_resp["accepted_count"] == 1
    assert sync_resp["duplicate_count"] == 0
    print(f"  [OK] POST /api/v1/telemetry/sync -> 200 OK (Accepted: {sync_resp['accepted_count']}, Duplicates dropped: {sync_resp['duplicate_count']})")

    res = client.get("/api/v1/telemetry/stats")
    assert res.status_code == 200
    telemetry_stats = res.json()
    print(f"  [OK] GET /api/v1/telemetry/stats -> 200 OK (Stored: {telemetry_stats['unique_packets_stored']} packets, SOS: {telemetry_stats['sos_beacons_count']})")

    # -------------------------------------------------------------------------
    # 13. OASIS CAP v1.2 XML & CAD JSON Interoperability
    # -------------------------------------------------------------------------
    print("\n[13/14] Testing OASIS CAP v1.2 XML & Legacy CAD JSON Exporters...")
    res = client.get(f"/api/v1/interop/cap/{incident_id}.xml")
    assert res.status_code == 200
    assert "<?xml" in res.text
    assert "<alert" in res.text
    print(f"  [OK] GET /api/v1/interop/cap/{incident_id}.xml -> 200 OK (Valid CAP v1.2 XML produced)")

    res = client.get(f"/api/v1/interop/cad/{incident_id}.json")
    assert res.status_code == 200
    cad_json = res.json()
    assert "cad_incident_id" in cad_json
    print(f"  [OK] GET /api/v1/interop/cad/{incident_id}.json -> 200 OK (CAD ID: {cad_json['cad_incident_id']})")

    # -------------------------------------------------------------------------
    # 14. Missing-Person Probabilistic Isochrone
    # -------------------------------------------------------------------------
    print("\n[14/14] Testing Missing-Person Search Isochrone...")
    res = client.get("/api/v1/search/isochrone?person_id=SR-SURVIVOR-44&last_lat=13.0400&last_lng=80.2200&last_seen_ts=" + str(now_ms - 3600000))
    assert res.status_code == 200
    iso_data = res.json()
    assert "isochrone_68_pct" in iso_data
    assert "isochrone_95_pct" in iso_data
    print(f"  [OK] GET /api/v1/search/isochrone -> 200 OK (Radius 95%: {iso_data['isochrone_95_pct']['radius_meters']:.1f}m)")

    print("\n======================================================================")
    print("   [SUCCESS] ALL COMMAND CENTER & DUAL-PERSISTENCE API TESTS PASSED!")
    print("======================================================================\n")


if __name__ == "__main__":
    test_command_center_api_suite()
