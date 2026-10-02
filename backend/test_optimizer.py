"""
Automated Test Suite for RakshaNet Search Isochrones & Linear Resource Dispatch Optimizer (Task 4).
Tests kinematic drift envelopes (68% & 95%), Mixed-Integer Linear Programming (MILP)
fleet dispatch matching, and FastAPI dispatch endpoints.
"""

import sys
import time
from pathlib import Path

# Add backend directory to sys.path
backend_dir = Path(__file__).parent
if str(backend_dir) not in sys.path:
    sys.path.insert(0, str(backend_dir))

from fastapi.testclient import TestClient
from ai_engine.optimizer import (
    SearchIsochroneEngine,
    SearchIsochrone,
    DispatchOptimizer,
    dispatch_optimizer,
    RescueUnit,
    DispatchPlan
)
from gateway.app import app
from gateway.storage import gateway_storage


def test_probabilistic_search_isochrones():
    print("[TEST 1] Testing Missing-Person Probabilistic Isochrone Expansion & Drift...")
    now_ms = 1700000000000

    # 1. Stationary Pedestrian Debris Search (1 hour elapsed)
    one_hour_ago = now_ms - (3600 * 1000)
    iso_ped = SearchIsochroneEngine.calculate_search_zone(
        person_id="SR-SURVIVOR-PED-01",
        last_lat=13.0400,
        last_lng=80.2200,
        last_seen_ts=one_hour_ago,
        current_ts_ms=now_ms,
        drift_speed_mps=0.0,
        pedestrian_speed_mps=0.75
    )

    assert iso_ped.person_id == "SR-SURVIVOR-PED-01"
    assert iso_ped.elapsed_hours == 1.0
    assert iso_ped.urgency == "CRITICAL"
    # Radius = base 25m + (0.75 * 3600 = 2700m) = ~2725m
    assert 2600.0 <= iso_ped.radius_68_meters <= 2800.0
    assert iso_ped.radius_95_meters > iso_ped.radius_68_meters
    assert iso_ped.area_sq_km > 0.0
    assert iso_ped.bounding_box["min_lat"] < iso_ped.projected_center_lat < iso_ped.bounding_box["max_lat"]

    # 2. Downstream River Flood Drift (2 hours elapsed, 1.5 m/s current eastward at 90 deg)
    two_hours_ago = now_ms - (7200 * 1000)
    iso_drift = SearchIsochroneEngine.calculate_search_zone(
        person_id="SR-SURVIVOR-DRIFT-02",
        last_lat=13.0100,
        last_lng=80.2000,
        last_seen_ts=two_hours_ago,
        current_ts_ms=now_ms,
        drift_speed_mps=1.5,
        drift_heading_deg=90.0,
        pedestrian_speed_mps=0.0
    )

    # 1.5 m/s * 7200s = 10,800 meters eastward
    # Longitude should have shifted east (greater than 80.2000)
    assert iso_drift.projected_center_lng > iso_drift.last_known_lng
    dist_shifted = SearchIsochroneEngine._offset_coordinate(13.0100, 80.2000, 10800.0, 90.0)
    assert abs(iso_drift.projected_center_lat - dist_shifted[0]) < 0.001
    assert abs(iso_drift.projected_center_lng - dist_shifted[1]) < 0.001

    print(f"  [OK] Isochrone calculated: 1h Pedestrian Search envelope ({iso_ped.radius_68_meters}m 68% core) "
          f"& 2h Flood Drift vector shifted center east to {iso_drift.projected_center_lng} E")


def test_linear_dispatch_optimization_matching():
    print("[TEST 2] Testing Mixed-Integer Linear Resource Dispatch Optimizer (MILP)...")
    optimizer = DispatchOptimizer()

    # Define 3 Master Incidents requiring distinct tactical capabilities
    incidents = [
        {
            "incident_id": "INC-FLOOD-001",
            "category": "FLOOD_INUNDATION",
            "urgency": "CRITICAL",
            "centroid_lat": 13.0100,
            "centroid_lng": 80.2500,
            "estimated_casualties": 8,
            "vulnerabilities": ["ELDERLY", "INFANT"]
        },
        {
            "incident_id": "INC-COLLAPSE-002",
            "category": "STRUCTURAL_COLLAPSE",
            "urgency": "HIGH",
            "centroid_lat": 12.9200,
            "centroid_lng": 80.1200,
            "estimated_casualties": 5,
            "vulnerabilities": ["TRAPPED"]
        },
        {
            "incident_id": "INC-TRAUMA-003",
            "category": "MEDICAL_TRAUMA",
            "urgency": "CRITICAL",
            "centroid_lat": 13.0400,
            "centroid_lng": 80.2200,
            "estimated_casualties": 2,
            "vulnerabilities": ["CARDIAC", "SEVERE_BLEEDING"]
        }
    ]

    # Define 3 available rescue units
    units = [
        RescueUnit(
            unit_id="BOAT-ALPHA",
            name="NDRF Inflatable Zodiac 01",
            unit_type="BOAT",
            lat=13.0120,
            lng=80.2480,
            capacity=10,
            speed_kmh=25.0,
            capabilities=["WATER_RESCUE", "EVACUATION"]
        ),
        RescueUnit(
            unit_id="TRUCK-BRAVO",
            name="SDRF 4WD Heavy Rescue 02",
            unit_type="HIGH_CLEARANCE_4WD",
            lat=12.9230,
            lng=80.1180,
            capacity=6,
            speed_kmh=45.0,
            capabilities=["STRUCTURAL_SEARCH", "EVACUATION"]
        ),
        RescueUnit(
            unit_id="AMB-CHARLIE",
            name="Paramedic Life Support 03",
            unit_type="AMBULANCE",
            lat=13.0420,
            lng=80.2180,
            capacity=2,
            speed_kmh=50.0,
            capabilities=["PARAMEDIC", "ADVANCED_LIFE_SUPPORT"]
        )
    ]

    plan = optimizer.optimize_dispatch(incidents, units)

    assert plan.assigned_count == 3, f"Expected 3 assignments, got {plan.assigned_count}"
    assert len(plan.unassigned_incident_ids) == 0
    assert plan.total_casualties_addressed == 15  # 8 + 5 + 2

    # Check vehicle compatibility constraints:
    assignment_map = {a.unit_id: a for a in plan.assignments}

    # BOAT-ALPHA must be assigned to FLOOD
    assert assignment_map["BOAT-ALPHA"].incident_id == "INC-FLOOD-001"
    assert assignment_map["BOAT-ALPHA"].eta_minutes < 15.0

    # TRUCK-BRAVO must be assigned to COLLAPSE
    assert assignment_map["TRUCK-BRAVO"].incident_id == "INC-COLLAPSE-002"
    assert assignment_map["TRUCK-BRAVO"].eta_minutes < 15.0

    # AMB-CHARLIE must be assigned to MEDICAL TRAUMA
    assert assignment_map["AMB-CHARLIE"].incident_id == "INC-TRAUMA-003"
    assert assignment_map["AMB-CHARLIE"].eta_minutes < 15.0

    print(f"  [OK] MILP Solver generated optimal dispatch plan {plan.plan_id}: "
          f"3 units matched, {plan.total_casualties_addressed} casualties protected, solver status: {plan.solver_status}")


def test_api_gateway_dispatch_endpoints():
    print("[TEST 3] Testing FastAPI Isochrone & Dispatch Optimization Endpoints...")
    gateway_storage.clear()
    client = TestClient(app)

    # 1. Test GET /api/v1/search/isochrone
    now_ms = int(time.time() * 1000)
    res_iso = client.get(
        f"/api/v1/search/isochrone?person_id=SR-TEST-SURVIVOR&last_lat=13.05&last_lng=80.25&last_seen_ts={now_ms - 1800000}"
    )
    assert res_iso.status_code == 200
    iso_data = res_iso.json()
    assert iso_data["person_id"] == "SR-TEST-SURVIVOR"
    assert iso_data["radius_68_meters"] > 0
    assert "bounding_box" in iso_data

    # 2. Test GET /api/v1/dispatch/units
    res_units = client.get("/api/v1/dispatch/units")
    assert res_units.status_code == 200
    fleet = res_units.json()
    assert len(fleet) >= 4

    # 3. Ingest flood distress packet and test POST /api/v1/dispatch/optimize
    sync_payload = {
        "device_id": "MULE-DISPATCH-01",
        "mesh_hop_count": 1,
        "packets": [
            {
                "msg_id": "SOS-DISPATCH-TEST-001",
                "sender_id": "SURVIVOR-FLOOD",
                "type": "SOS",
                "payload": "Trapped on roof surrounded by floodwater",
                "location": {"lat": 13.0110, "lng": 80.2410},
                "meta": {"category": "FLOOD", "urgency": "CRITICAL", "casualties": 6},
                "ts": now_ms
            }
        ]
    }
    client.post("/api/v1/telemetry/sync", json=sync_payload)

    # Run optimizer via API
    res_plan = client.post("/api/v1/dispatch/optimize")
    assert res_plan.status_code == 200
    plan_data = res_plan.json()
    assert plan_data["assigned_count"] >= 1
    assert plan_data["total_casualties_addressed"] >= 6
    # Verify water craft was chosen
    top_assignment = plan_data["assignments"][0]
    assert top_assignment["unit_type"] in ["BOAT", "HELICOPTER"]

    print(f"  [OK] Ingested flood distress -> API Dispatch Optimizer produced Plan {plan_data['plan_id']} "
          f"assigning {top_assignment['unit_name']} (ETA: {top_assignment['eta_minutes']} mins)")


if __name__ == "__main__":
    print("=" * 70)
    print("RAKSHANET SEARCH ISOCHRONES & DISPATCH OPTIMIZER TEST SUITE (TASK 4)")
    print("=" * 70)
    test_probabilistic_search_isochrones()
    test_linear_dispatch_optimization_matching()
    test_api_gateway_dispatch_endpoints()
    print("=" * 70)
    print("[ALL TESTS PASSED 100%] TASK 4 OPTIMIZER VERIFIED SUCCESSFULLY")
    print("=" * 70)
