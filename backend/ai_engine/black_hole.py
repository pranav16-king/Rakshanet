"""
Communication-Gap & Black Hole Anomaly Detector for RakshaNet.
Feature 16 from the SignalRescue AI White Paper.

Monitors spatial grid sectors over time-series windows to detect sudden drops
in active peer heartbeats (e.g. 500 -> 150 -> 20 nodes). Identifies isolated
villages and cut-off sectors before anyone is able to transmit an SOS, automatically
triggering aerial drone reconnaissance and mobile relay deployment recommendations.
"""

import math
import time
import hashlib
from typing import List, Dict, Any, Tuple, Optional
from pydantic import BaseModel, Field


class BlackHoleAnomaly(BaseModel):
    anomaly_id: str = Field(..., description="Unique Black Hole Anomaly ID")
    sector_id: str = Field(..., description="Grid sector code, e.g. SEC-13.01N-80.25E")
    center_lat: float = Field(..., description="Center latitude of silenced sector")
    center_lng: float = Field(..., description="Center longitude of silenced sector")
    radius_meters: float = Field(default=750.0, description="Effective radius of affected sector in meters")
    bounds: Dict[str, float] = Field(..., description="Bounding box: min_lat, max_lat, min_lng, max_lng")
    baseline_nodes: int = Field(..., description="Peak active node count prior to signal collapse")
    current_nodes: int = Field(..., description="Current active node count")
    drop_percentage: float = Field(..., description="Percentage collapse in telemetry: ((baseline - current) / baseline) * 100")
    decay_rate_per_hour: float = Field(..., description="Linear rate of node loss per hour")
    estimated_silenced_people: int = Field(..., description="Estimated human population in blackout (Devices != People)")
    severity: str = Field(..., description="CRITICAL, WARNING, WATCH")
    recommended_action: str = Field(..., description="Tactical action: DISPATCH_AERIAL_RECON_DRONE, DEPLOY_RELAY_BALLOON, etc.")
    silence_duration_minutes: float = Field(default=0.0, description="Duration in minutes since catastrophic drop occurred")
    detected_at: int = Field(..., description="Timestamp of anomaly detection in epoch milliseconds")
    time_series: List[Dict[str, Any]] = Field(default_factory=list, description="Historical active node counts across time buckets")


class BlackHoleDetector:
    """
    Spatiotemporal grid anomaly detector.
    Analyzes historical packet breadcrumbs and heartbeats to surface communication black holes.
    """
    # 0.01 degrees is ~1.11 km in latitude
    LAT_GRID_STEP = 0.0100
    LNG_GRID_STEP = 0.0100
    HOUSEHOLD_MULTIPLIER = 2.5  # Devices != People statistical scaling factor

    def __init__(
        self,
        min_baseline_nodes: int = 10,
        critical_drop_pct: float = 75.0,
        warning_drop_pct: float = 45.0,
        time_bucket_minutes: int = 30,
        num_buckets: int = 4
    ):
        """
        :param min_baseline_nodes: Minimum initial active nodes required to evaluate a sector for a black hole.
        :param critical_drop_pct: Percentage loss to flag as CRITICAL anomaly (>75% drop).
        :param warning_drop_pct: Percentage loss to flag as WARNING anomaly (>45% drop).
        :param time_bucket_minutes: Duration of each temporal analysis bucket.
        :param num_buckets: Number of time intervals analyzed (e.g. 4 buckets of 30 mins = 2 hours window).
        """
        self.min_baseline_nodes = min_baseline_nodes
        self.critical_drop_pct = critical_drop_pct
        self.warning_drop_pct = warning_drop_pct
        self.time_bucket_minutes = time_bucket_minutes
        self.num_buckets = num_buckets
        self.total_window_ms = self.num_buckets * self.time_bucket_minutes * 60 * 1000

    def _grid_sector_key(self, lat: float, lng: float) -> Tuple[str, Tuple[float, float, float, float]]:
        """
        Quantizes coordinates into a deterministic geographic grid cell.
        Returns: (sector_id, (min_lat, max_lat, min_lng, max_lng))
        """
        grid_lat = math.floor(lat / self.LAT_GRID_STEP) * self.LAT_GRID_STEP
        grid_lng = math.floor(lng / self.LNG_GRID_STEP) * self.LNG_GRID_STEP

        min_lat = round(grid_lat, 4)
        max_lat = round(grid_lat + self.LAT_GRID_STEP, 4)
        min_lng = round(grid_lng, 4)
        max_lng = round(grid_lng + self.LNG_GRID_STEP, 4)

        sector_id = f"SEC-{abs(min_lat):.2f}{'N' if min_lat >= 0 else 'S'}-{abs(min_lng):.2f}{'E' if min_lng >= 0 else 'W'}"
        return sector_id, (min_lat, max_lat, min_lng, max_lng)

    def detect_anomalies(
        self,
        packets: List[Dict[str, Any]],
        current_time_ms: Optional[int] = None
    ) -> List[BlackHoleAnomaly]:
        """
        Evaluates a collection of telemetry packets over the observation window
        and returns detected communication black hole zones.
        """
        if not packets:
            return []

        now_ms = current_time_ms or int(time.time() * 1000)
        window_start_ms = now_ms - self.total_window_ms
        bucket_size_ms = self.time_bucket_minutes * 60 * 1000

        # Filter packets within observation window and with spatial fixes
        sector_buckets: Dict[str, Dict[str, Any]] = {}

        for p in packets:
            ts = p.get("timestamp") or p.get("ts") or 0
            if ts < window_start_ms or ts > now_ms:
                continue

            loc = p.get("location") or {}
            lat = loc.get("lat") or p.get("lat")
            lng = loc.get("lng") or p.get("lng")

            if lat is None or lng is None:
                meta = p.get("meta") or {}
                if isinstance(meta, str):
                    try:
                        import json
                        meta = json.loads(meta)
                    except Exception:
                        meta = {}
                lat = meta.get("lat")
                lng = meta.get("lng")

            if lat is None or lng is None:
                continue

            lat = float(lat)
            lng = float(lng)
            sender_id = p.get("sender_id", "SR-UNKNOWN")

            # Determine time bucket index (0 is oldest, num_buckets-1 is newest)
            bucket_idx = int((ts - window_start_ms) // bucket_size_ms)
            if bucket_idx >= self.num_buckets:
                bucket_idx = self.num_buckets - 1
            if bucket_idx < 0:
                continue

            sector_id, bounds = self._grid_sector_key(lat, lng)

            if sector_id not in sector_buckets:
                sector_buckets[sector_id] = {
                    "bounds": bounds,
                    "center_lat": round((bounds[0] + bounds[1]) / 2.0, 6),
                    "center_lng": round((bounds[2] + bounds[3]) / 2.0, 6),
                    "buckets": [set() for _ in range(self.num_buckets)],
                    "last_seen_ts": ts
                }

            sector_buckets[sector_id]["buckets"][bucket_idx].add(sender_id)
            if ts > sector_buckets[sector_id]["last_seen_ts"]:
                sector_buckets[sector_id]["last_seen_ts"] = ts

        # Evaluate decay curves for each sector
        anomalies: List[BlackHoleAnomaly] = []

        for sector_id, data in sector_buckets.items():
            bucket_counts = [len(dev_set) for dev_set in data["buckets"]]

            # Baseline is peak count in earlier half of the window
            earlier_half = bucket_counts[:max(1, self.num_buckets // 2)]
            baseline_nodes = max(earlier_half) if earlier_half else 0

            # Current nodes is latest bucket count
            current_nodes = bucket_counts[-1]

            # Only analyze sectors that had meaningful communication activity
            if baseline_nodes < self.min_baseline_nodes:
                continue

            drop_nodes = baseline_nodes - current_nodes
            drop_pct = (drop_nodes / baseline_nodes) * 100.0

            if drop_pct >= self.warning_drop_pct:
                # Calculate decay rate: nodes lost per hour
                hours_elapsed = (self.num_buckets * self.time_bucket_minutes) / 60.0
                decay_rate = round(drop_nodes / max(hours_elapsed, 0.5), 1)

                silence_duration_mins = max(0.0, round((now_ms - data["last_seen_ts"]) / 60000.0, 1))

                if drop_pct >= self.critical_drop_pct:
                    severity = "CRITICAL"
                    rec_action = "DISPATCH_AERIAL_RECON_DRONE_AND_RELAY_BALLOON"
                else:
                    severity = "WARNING"
                    rec_action = "DISPATCH_MOBILE_RECON_GROUND_VESSEL"

                # Devices != People: scale silenced devices by household multiplier
                silenced_people = int(drop_nodes * self.HOUSEHOLD_MULTIPLIER)

                # Format time-series breadcrumbs for visualization
                time_series_data = []
                for b_i, count in enumerate(bucket_counts):
                    b_ts = window_start_ms + b_i * bucket_size_ms
                    time_series_data.append({
                        "bucket_index": b_i,
                        "timestamp": b_ts,
                        "active_nodes": count
                    })

                hash_input = f"{sector_id}_{now_ms}"
                anomaly_hash = hashlib.md5(hash_input.encode()).hexdigest()[:6].upper()
                anomaly_id = f"ANOM-BLK-{anomaly_hash}"

                anomaly = BlackHoleAnomaly(
                    anomaly_id=anomaly_id,
                    sector_id=sector_id,
                    center_lat=data["center_lat"],
                    center_lng=data["center_lng"],
                    radius_meters=750.0,
                    bounds={
                        "min_lat": data["bounds"][0],
                        "max_lat": data["bounds"][1],
                        "min_lng": data["bounds"][2],
                        "max_lng": data["bounds"][3]
                    },
                    baseline_nodes=baseline_nodes,
                    current_nodes=current_nodes,
                    drop_percentage=round(drop_pct, 1),
                    decay_rate_per_hour=decay_rate,
                    estimated_silenced_people=max(silenced_people, drop_nodes),
                    severity=severity,
                    recommended_action=rec_action,
                    silence_duration_minutes=silence_duration_mins,
                    detected_at=now_ms,
                    time_series=time_series_data
                )
                anomalies.append(anomaly)

        # Sort: CRITICAL first, then by highest percentage drop
        severity_rank = {"CRITICAL": 0, "WARNING": 1, "WATCH": 2}
        anomalies.sort(key=lambda a: (severity_rank.get(a.severity, 3), -a.drop_percentage))

        return anomalies


# Global Singleton Black Hole Detector Instance
black_hole_detector = BlackHoleDetector()
