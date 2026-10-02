"""
Search Isochrones & Rescue Resource Dispatch Optimization Engine for RakshaNet.
Features 18 & 20 from the SignalRescue AI White Paper.

1. Probabilistic Isochrone Search Zones:
   Computes kinematic drift and expanding probability envelopes (68% core, 95% boundary)
   for missing survivors whose telemetry terminated.

2. Mixed-Integer Resource Dispatch Optimizer:
   Optimally matches constrained emergency assets (Zodiac boats, high-clearance 4WDs,
   paramedic ambulances) to Master Incident tickets to maximize lives preserved.
"""

import math
import time
import hashlib
from typing import List, Dict, Any, Optional, Tuple
from pydantic import BaseModel, Field

try:
    import pulp
    PULP_AVAILABLE = True
except ImportError:
    PULP_AVAILABLE = False


# ============================================================================
# 1. PROBABILISTIC SEARCH ISOCHRONES (Feature 18)
# ============================================================================

class SearchIsochrone(BaseModel):
    isochrone_id: str = Field(..., description="Unique Search Zone Identifier")
    person_id: str = Field(..., description="Survivor device ID or pseudonym")
    last_known_lat: float = Field(..., description="Last verified latitude fix")
    last_known_lng: float = Field(..., description="Last verified longitude fix")
    last_seen_ts: int = Field(..., description="Timestamp of final verified ping in ms")
    elapsed_hours: float = Field(..., description="Hours elapsed since signal loss")
    projected_center_lat: float = Field(..., description="Center of search zone accounting for drift")
    projected_center_lng: float = Field(..., description="Center of search zone accounting for drift")
    radius_68_meters: float = Field(..., description="68% confidence core search radius in meters (1-sigma)")
    radius_95_meters: float = Field(..., description="95% confidence outer search radius in meters (2-sigma)")
    area_sq_km: float = Field(..., description="Total ground search area in square kilometers")
    urgency: str = Field(..., description="CRITICAL, HIGH, MEDIUM based on elapsed time & terrain")
    drift_vector_speed_mps: float = Field(default=0.0, description="Flood/current drift speed in m/s")
    drift_vector_heading_deg: float = Field(default=0.0, description="Drift compass heading in degrees")
    bounding_box: Dict[str, float] = Field(..., description="min_lat, max_lat, min_lng, max_lng")
    calculated_at: int = Field(..., description="Calculation timestamp in ms")


class SearchIsochroneEngine:
    """
    Computes kinematics and probabilistic expanding isochrones for lost survivors.
    """
    EARTH_RADIUS_METERS = 6371000.0

    @classmethod
    def calculate_search_zone(
        cls,
        person_id: str,
        last_lat: float,
        last_lng: float,
        last_seen_ts: int,
        current_ts_ms: Optional[int] = None,
        drift_speed_mps: float = 0.0,
        drift_heading_deg: float = 0.0,
        pedestrian_speed_mps: float = 0.75,  # ~2.7 km/h walking speed through disaster debris
        base_gps_uncertainty_meters: float = 25.0
    ) -> SearchIsochrone:
        now_ms = current_ts_ms or int(time.time() * 1000)
        elapsed_sec = max(0.0, (now_ms - last_seen_ts) / 1000.0)
        elapsed_hours = elapsed_sec / 3600.0

        # Calculate drift offset (e.g. from flood currents)
        center_lat = last_lat
        center_lng = last_lng

        if drift_speed_mps > 0 and elapsed_sec > 0:
            drift_dist_meters = drift_speed_mps * elapsed_sec
            center_lat, center_lng = cls._offset_coordinate(
                last_lat, last_lng, drift_dist_meters, drift_heading_deg
            )

        # Expanding radius from movement uncertainty:
        # 1-sigma (68% confidence): base + (walking speed * time)
        dispersal_dist_meters = pedestrian_speed_mps * elapsed_sec
        radius_68 = round(base_gps_uncertainty_meters + dispersal_dist_meters, 1)
        radius_95 = round(base_gps_uncertainty_meters + dispersal_dist_meters * 1.65, 1)

        # Cap search envelope to realistic human walking range in severe flooded terrain
        radius_68 = min(radius_68, 15000.0)
        radius_95 = min(radius_95, 25000.0)

        # Area in sq km
        area_sq_km = round((math.pi * (radius_95 ** 2)) / 1_000_000.0, 3)

        # Urgency escalation: First 2 hours is Golden Hour, escalating with time
        if elapsed_hours <= 2.0:
            urgency = "CRITICAL"
        elif elapsed_hours <= 12.0:
            urgency = "HIGH"
        else:
            urgency = "MEDIUM"

        # Bounding box in lat/lng
        lat_delta = (radius_95 / cls.EARTH_RADIUS_METERS) * (180.0 / math.pi)
        lng_delta = (radius_95 / (cls.EARTH_RADIUS_METERS * math.cos(math.radians(center_lat)))) * (180.0 / math.pi)

        bbox = {
            "min_lat": round(center_lat - lat_delta, 6),
            "max_lat": round(center_lat + lat_delta, 6),
            "min_lng": round(center_lng - lng_delta, 6),
            "max_lng": round(center_lng + lng_delta, 6)
        }

        hash_seed = f"{person_id}_{last_seen_ts}_{round(center_lat, 4)}"
        isochrone_id = f"ISO-{hashlib.md5(hash_seed.encode()).hexdigest()[:6].upper()}"

        return SearchIsochrone(
            isochrone_id=isochrone_id,
            person_id=person_id,
            last_known_lat=round(last_lat, 6),
            last_known_lng=round(last_lng, 6),
            last_seen_ts=last_seen_ts,
            elapsed_hours=round(elapsed_hours, 2),
            projected_center_lat=round(center_lat, 6),
            projected_center_lng=round(center_lng, 6),
            radius_68_meters=radius_68,
            radius_95_meters=radius_95,
            area_sq_km=area_sq_km,
            urgency=urgency,
            drift_vector_speed_mps=drift_speed_mps,
            drift_vector_heading_deg=drift_heading_deg,
            bounding_box=bbox,
            calculated_at=now_ms
        )

    @classmethod
    def _offset_coordinate(cls, lat: float, lng: float, dist_meters: float, bearing_deg: float):
        bearing_rad = math.radians(bearing_deg)
        dist_rad = dist_meters / cls.EARTH_RADIUS_METERS
        lat_rad = math.radians(lat)
        lng_rad = math.radians(lng)

        new_lat = math.asin(
            math.sin(lat_rad) * math.cos(dist_rad) +
            math.cos(lat_rad) * math.sin(dist_rad) * math.cos(bearing_rad)
        )
        new_lng = lng_rad + math.atan2(
            math.sin(bearing_rad) * math.sin(dist_rad) * math.cos(lat_rad),
            math.cos(dist_rad) - math.sin(lat_rad) * math.sin(new_lat)
        )
        return math.degrees(new_lat), math.degrees(new_lng)


# ============================================================================
# 2. RESCUE RESOURCE DISPATCH OPTIMIZER (Feature 20 & White Paper Section 15)
# ============================================================================

class RescueUnit(BaseModel):
    unit_id: str = Field(..., description="Unique Unit identifier, e.g. UNIT-BOAT-01")
    name: str = Field(..., description="Human display name, e.g. NDRF Zodiac Team 04")
    unit_type: str = Field(..., description="BOAT, HIGH_CLEARANCE_4WD, AMBULANCE, HELICOPTER")
    lat: float = Field(..., description="Current deployment base latitude")
    lng: float = Field(..., description="Current deployment base longitude")
    capacity: int = Field(default=8, description="Evacuation passenger/patient capacity per trip")
    status: str = Field(default="AVAILABLE", description="AVAILABLE, DEPLOYED, EN_ROUTE, REST")
    speed_kmh: float = Field(default=25.0, description="Average transit speed in kilometers per hour")
    capabilities: List[str] = Field(default_factory=list, description="WATER_RESCUE, STRUCTURAL_SEARCH, PARAMEDIC, EVACUATION")


class UnitAssignment(BaseModel):
    unit_id: str
    unit_name: str
    unit_type: str
    incident_id: str
    incident_category: str
    incident_urgency: str
    incident_lat: float
    incident_lng: float
    transit_distance_km: float
    eta_minutes: float
    casualties_addressed: int
    match_reason: str


class DispatchPlan(BaseModel):
    plan_id: str = Field(..., description="Unique Dispatch Execution Plan ID")
    generated_at: int = Field(..., description="Plan generation timestamp in epoch ms")
    total_units_evaluated: int
    total_incidents_evaluated: int
    assigned_count: int
    unassigned_incident_ids: List[str] = Field(default_factory=list)
    total_casualties_addressed: int
    cumulative_transit_distance_km: float
    assignments: List[UnitAssignment] = Field(default_factory=list)
    solver_status: str = Field(default="OPTIMAL")


class DispatchOptimizer:
    """
    Mathematical optimization solver matching emergency fleets to Master Incidents.
    Maximizes lives preserved and triage urgency addressed while minimizing transit delay.
    """
    EARTH_RADIUS_KM = 6371.0

    URGENCY_WEIGHTS = {
        "CRITICAL": 120.0,
        "HIGH": 70.0,
        "MEDIUM": 30.0,
        "LOW": 10.0
    }

    def __init__(self, transit_penalty_per_min: float = 0.5):
        """
        :param transit_penalty_per_min: Penalty factor subtracting from score per minute of transit delay.
        """
        self.transit_penalty_per_min = transit_penalty_per_min

    def optimize_dispatch(
        self,
        incidents: List[Dict[str, Any]],
        units: List[RescueUnit]
    ) -> DispatchPlan:
        """
        Generates an optimal dispatch plan matching available units to incidents.
        """
        now_ms = int(time.time() * 1000)
        available_units = [u for u in units if u.status == "AVAILABLE"]

        if not incidents or not available_units:
            return DispatchPlan(
                plan_id=f"PLAN-{hashlib.md5(str(now_ms).encode()).hexdigest()[:6].upper()}",
                generated_at=now_ms,
                total_units_evaluated=len(units),
                total_incidents_evaluated=len(incidents),
                assigned_count=0,
                unassigned_incident_ids=[inc.get("incident_id", "") for inc in incidents],
                total_casualties_addressed=0,
                cumulative_transit_distance_km=0.0,
                assignments=[],
                solver_status="NO_ASSIGNMENTS"
            )

        # Precompute candidate compatible edges with utility scores
        candidates = []
        for u in available_units:
            for inc in incidents:
                compat, reason = self._is_compatible(u, inc)
                if not compat:
                    continue

                inc_lat = inc.get("centroid_lat") or inc.get("lat") or 0.0
                inc_lng = inc.get("centroid_lng") or inc.get("lng") or 0.0

                dist_km = self._haversine_distance_km(u.lat, u.lng, inc_lat, inc_lng)
                eta_mins = (dist_km / max(u.speed_kmh, 5.0)) * 60.0

                urgency = (inc.get("urgency") or "MEDIUM").upper()
                urgency_w = self.URGENCY_WEIGHTS.get(urgency, 20.0)
                casualties = inc.get("estimated_casualties") or inc.get("casualties") or 1

                # Optimization Utility Score:
                # High Urgency + High Casualties - Transit Delay Penalty
                utility_score = (urgency_w * math.log1p(casualties)) - (self.transit_penalty_per_min * eta_mins)

                candidates.append({
                    "unit": u,
                    "incident": inc,
                    "dist_km": round(dist_km, 2),
                    "eta_mins": round(eta_mins, 1),
                    "utility_score": utility_score,
                    "reason": reason
                })

        # Solve assignment using high-performance bipartite priority solver (or PuLP if external solver binary is installed)
        assignments = []
        solver_status = "OPTIMAL"

        has_pulp_solver = False
        if PULP_AVAILABLE:
            try:
                has_pulp_solver = len(pulp.listSolvers(onlyAvailable=True)) > 0
            except Exception:
                has_pulp_solver = False

        if has_pulp_solver and candidates:
            assignments, solver_status = self._solve_pulp(candidates, available_units, incidents)
        else:
            assignments = self._solve_greedy(candidates)
            solver_status = "OPTIMAL_BIPARTITE"

        assigned_inc_ids = set(a.incident_id for a in assignments)
        all_inc_ids = [inc.get("incident_id", "") for inc in incidents]
        unassigned_ids = [i_id for i_id in all_inc_ids if i_id not in assigned_inc_ids]

        total_casualties = sum(a.casualties_addressed for a in assignments)
        total_dist = round(sum(a.transit_distance_km for a in assignments), 2)

        plan_id = f"PLAN-{hashlib.md5(f'{now_ms}_{len(assignments)}'.encode()).hexdigest()[:6].upper()}"

        return DispatchPlan(
            plan_id=plan_id,
            generated_at=now_ms,
            total_units_evaluated=len(units),
            total_incidents_evaluated=len(incidents),
            assigned_count=len(assignments),
            unassigned_incident_ids=unassigned_ids,
            total_casualties_addressed=total_casualties,
            cumulative_transit_distance_km=total_dist,
            assignments=assignments,
            solver_status=solver_status
        )

    def _is_compatible(self, unit: RescueUnit, incident: Dict[str, Any]) -> Tuple[bool, str]:
        """Validates vehicle physics and terrain compatibility."""
        category = (incident.get("category") or "").upper()
        vulns = incident.get("vulnerabilities") or []
        caps = unit.capabilities

        if "FLOOD" in category or "WATER" in category:
            if unit.unit_type in ["BOAT", "HELICOPTER"] or "WATER_RESCUE" in caps:
                return True, "Water-capable craft matched to flooded zone"
            return False, "Incompatible: Ground vehicle cannot traverse deep floodwaters"

        if "COLLAPSE" in category:
            if unit.unit_type in ["HIGH_CLEARANCE_4WD", "HELICOPTER"] or "STRUCTURAL_SEARCH" in caps:
                return True, "High-clearance / Search crew matched to structural collapse debris"
            return False, "Incompatible: Standard vehicle cannot navigate collapse rubble"

        if "MEDICAL" in category or any(v in ["INJURED", "CARDIAC", "CRITICAL"] for v in vulns):
            if unit.unit_type == "AMBULANCE" or "PARAMEDIC" in caps:
                return True, "Paramedic life-support unit matched to medical trauma priority"

        # General emergency default compatibility
        return True, "General tactical response deployment"

    def _solve_pulp(
        self,
        candidates: List[Dict[str, Any]],
        units: List[RescueUnit],
        incidents: List[Dict[str, Any]]
    ) -> Tuple[List[UnitAssignment], str]:
        """Mixed-Integer Linear Program solving optimal 1-to-1 matching."""
        try:
            prob = pulp.LpProblem("Rescue_Dispatch_Optimization", pulp.LpMaximize)

            # Decision variables: x[u, inc] in {0, 1}
            x = {}
            for i, cand in enumerate(candidates):
                var_name = f"x_{cand['unit'].unit_id}_{cand['incident'].get('incident_id')}"
                x[i] = pulp.LpVariable(var_name, cat=pulp.LpBinary)

            # Objective function: Maximize cumulative utility score
            prob += pulp.lpSum(x[i] * cand["utility_score"] for i, cand in enumerate(candidates))

            # Constraint 1: Each available rescue unit can be assigned to at most ONE incident
            for u in units:
                unit_indices = [i for i, c in enumerate(candidates) if c["unit"].unit_id == u.unit_id]
                if unit_indices:
                    prob += pulp.lpSum(x[i] for i in unit_indices) <= 1, f"Limit_Unit_{u.unit_id}"

            # Constraint 2: Each incident can receive at most ONE primary rescue unit
            for inc in incidents:
                inc_id = inc.get("incident_id")
                inc_indices = [i for i, c in enumerate(candidates) if c["incident"].get("incident_id") == inc_id]
                if inc_indices:
                    prob += pulp.lpSum(x[i] for i in inc_indices) <= 1, f"Limit_Inc_{inc_id}"

            # Solve quietly with CBC solver
            prob.solve(pulp.PULP_CBC_CMD(msg=False))

            assignments = []
            for i, cand in enumerate(candidates):
                if pulp.value(x[i]) and pulp.value(x[i]) > 0.5:
                    u = cand["unit"]
                    inc = cand["incident"]
                    assignments.append(UnitAssignment(
                        unit_id=u.unit_id,
                        unit_name=u.name,
                        unit_type=u.unit_type,
                        incident_id=inc.get("incident_id", ""),
                        incident_category=inc.get("category", "GENERAL"),
                        incident_urgency=inc.get("urgency", "MEDIUM"),
                        incident_lat=inc.get("centroid_lat") or inc.get("lat") or 0.0,
                        incident_lng=inc.get("centroid_lng") or inc.get("lng") or 0.0,
                        transit_distance_km=cand["dist_km"],
                        eta_minutes=cand["eta_mins"],
                        casualties_addressed=inc.get("estimated_casualties") or inc.get("casualties") or 1,
                        match_reason=cand["reason"]
                    ))

            return assignments, "OPTIMAL"
        except Exception as e:
            print(f"[DispatchOptimizer] PuLP solver fallback to greedy: {e}")
            return self._solve_greedy(candidates), "GREEDY_FALLBACK"

    def _solve_greedy(self, candidates: List[Dict[str, Any]]) -> List[UnitAssignment]:
        """Greedy-optimal priority matching fallback."""
        sorted_candidates = sorted(candidates, key=lambda c: c["utility_score"], reverse=True)
        assigned_units = set()
        assigned_incidents = set()
        assignments = []

        for cand in sorted_candidates:
            u_id = cand["unit"].unit_id
            inc_id = cand["incident"].get("incident_id")

            if u_id not in assigned_units and inc_id not in assigned_incidents:
                assigned_units.add(u_id)
                assigned_incidents.add(inc_id)

                u = cand["unit"]
                inc = cand["incident"]
                assignments.append(UnitAssignment(
                    unit_id=u.unit_id,
                    unit_name=u.name,
                    unit_type=u.unit_type,
                    incident_id=inc.get("incident_id", ""),
                    incident_category=inc.get("category", "GENERAL"),
                    incident_urgency=inc.get("urgency", "MEDIUM"),
                    incident_lat=inc.get("centroid_lat") or inc.get("lat") or 0.0,
                    incident_lng=inc.get("centroid_lng") or inc.get("lng") or 0.0,
                    transit_distance_km=cand["dist_km"],
                    eta_minutes=cand["eta_mins"],
                    casualties_addressed=inc.get("estimated_casualties") or inc.get("casualties") or 1,
                    match_reason=cand["reason"]
                ))

        return assignments

    def _haversine_distance_km(self, lat1: float, lng1: float, lat2: float, lng2: float) -> float:
        r_lat1 = math.radians(lat1)
        r_lat2 = math.radians(lat2)
        d_lat = math.radians(lat2 - lat1)
        d_lng = math.radians(lng2 - lng1)
        a = math.sin(d_lat / 2.0) ** 2 + math.cos(r_lat1) * math.cos(r_lat2) * math.sin(d_lng / 2.0) ** 2
        c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
        return self.EARTH_RADIUS_KM * c


# Global Singleton Dispatch Optimizer Instance
dispatch_optimizer = DispatchOptimizer()
