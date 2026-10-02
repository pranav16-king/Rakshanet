"""
Storage and Deduplication Engine for the RakshaNet Ingestion Gateway.
Guarantees idempotent packet processing: if multiple civilian data mules
upload the same buffered distress packet, duplicate echoes are dropped instantly.
"""

import sqlite3
import json
import time
from typing import List, Dict, Any, Tuple, Optional
from pathlib import Path

DB_FILE = Path(__file__).parent.parent / "data" / "gateway_telemetry.db"


class GatewayStorage:
    def __init__(self, db_path: Optional[str] = None):
        self.db_path = db_path or str(DB_FILE)
        Path(self.db_path).parent.mkdir(parents=True, exist_ok=True)
        
        # In-memory fast-lookup set for sub-millisecond deduplication
        self.seen_message_ids = set()
        self.mule_sync_registry = {}
        
        self._init_db()
        self._warm_cache()

    def _get_connection(self):
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        return conn

    def _init_db(self):
        with self._get_connection() as conn:
            cursor = conn.cursor()
            # Raw Ingested Packets
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS ingested_packets (
                    msg_id TEXT PRIMARY KEY,
                    sender_id TEXT NOT NULL,
                    sender_name TEXT,
                    conv_id TEXT,
                    packet_type TEXT NOT NULL,
                    payload TEXT NOT NULL,
                    lat REAL,
                    lng REAL,
                    altitude REAL,
                    accuracy REAL,
                    timestamp INTEGER NOT NULL,
                    hops INTEGER DEFAULT 0,
                    ttl INTEGER DEFAULT 5,
                    mule_device_id TEXT,
                    meta_json TEXT,
                    created_at INTEGER NOT NULL
                )
            """)
            # Active Data Mules Tracker
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS data_mules (
                    device_id TEXT PRIMARY KEY,
                    last_sync_timestamp INTEGER NOT NULL,
                    total_packets_carried INTEGER DEFAULT 0
                )
            """)
            conn.commit()

    def _warm_cache(self):
        """Warm in-memory deduplication set from database on startup."""
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT msg_id FROM ingested_packets")
            for row in cursor.fetchall():
                self.seen_message_ids.add(row["msg_id"])

    def ingest_packet(self, packet_data: Dict[str, Any], mule_id: str) -> bool:
        """
        Idempotent packet ingestion.
        Returns True if packet was newly accepted; False if it was dropped as duplicate.
        """
        msg_id = packet_data.get("msg_id")
        if not msg_id:
            return False

        # Fast memory check
        if msg_id in self.seen_message_ids:
            return False

        loc = packet_data.get("location") or {}
        lat = loc.get("lat")
        lng = loc.get("lng")
        alt = loc.get("altitude")
        acc = loc.get("accuracy")

        meta = packet_data.get("meta") or {}
        # Also extract coordinates if embedded in meta
        if lat is None and "lat" in meta:
            lat = meta.get("lat")
        if lng is None and "lng" in meta:
            lng = meta.get("lng")

        now = int(time.time() * 1000)

        try:
            with self._get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    INSERT OR IGNORE INTO ingested_packets (
                        msg_id, sender_id, sender_name, conv_id, packet_type,
                        payload, lat, lng, altitude, accuracy, timestamp,
                        hops, ttl, mule_device_id, meta_json, created_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    msg_id,
                    packet_data.get("sender_id", "SR-UNKNOWN"),
                    packet_data.get("sender_name", "Anonymous"),
                    packet_data.get("conv_id", "CONV_COMMUNITY"),
                    packet_data.get("type", "TEXT"),
                    packet_data.get("payload", ""),
                    lat,
                    lng,
                    alt,
                    acc,
                    packet_data.get("ts", now),
                    packet_data.get("hops", 0),
                    packet_data.get("ttl", 5),
                    mule_id,
                    json.dumps(meta),
                    now
                ))

                if cursor.rowcount > 0:
                    self.seen_message_ids.add(msg_id)
                    # Update data mule stats
                    cursor.execute("""
                        INSERT INTO data_mules (device_id, last_sync_timestamp, total_packets_carried)
                        VALUES (?, ?, 1)
                        ON CONFLICT(device_id) DO UPDATE SET
                            last_sync_timestamp = excluded.last_sync_timestamp,
                            total_packets_carried = total_packets_carried + 1
                    """, (mule_id, now))
                    conn.commit()
                    return True
                else:
                    self.seen_message_ids.add(msg_id)
                    return False
        except Exception as e:
            print(f"[GatewayStorage] Ingestion error on {msg_id}: {e}")
            return False

    def get_packets(self, limit: int = 100, packet_type: Optional[str] = None) -> List[Dict[str, Any]]:
        with self._get_connection() as conn:
            cursor = conn.cursor()
            if packet_type:
                cursor.execute(
                    "SELECT * FROM ingested_packets WHERE packet_type = ? ORDER BY timestamp DESC LIMIT ?",
                    (packet_type, limit)
                )
            else:
                cursor.execute(
                    "SELECT * FROM ingested_packets ORDER BY timestamp DESC LIMIT ?",
                    (limit,)
                )
            rows = cursor.fetchall()
            return [dict(row) for row in rows]

    def get_sos_packets(self) -> List[Dict[str, Any]]:
        return self.get_packets(limit=500, packet_type="SOS")

    def get_stats(self) -> Dict[str, Any]:
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM ingested_packets")
            total = cursor.fetchone()[0]

            cursor.execute("SELECT COUNT(*) FROM ingested_packets WHERE packet_type = 'SOS'")
            sos_count = cursor.fetchone()[0]

            cursor.execute("SELECT COUNT(*) FROM data_mules")
            mule_count = cursor.fetchone()[0]

            return {
                "unique_packets_stored": total,
                "sos_beacons_count": sos_count,
                "active_mules": mule_count,
            }

    def clear(self):
        """Reset storage (for test execution)."""
        self.seen_message_ids.clear()
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("DELETE FROM ingested_packets")
            cursor.execute("DELETE FROM data_mules")
            conn.commit()


# Global Singleton Storage Instance
gateway_storage = GatewayStorage()
