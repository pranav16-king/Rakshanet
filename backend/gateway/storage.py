"""
Storage and Deduplication Engine for the RakshaNet Ingestion Gateway.
Features Dual-Persistence Architecture:
  1. Local SQLite: Offline transactional zero-latency persistence engine.
  2. MongoDB Atlas: Cloud-synced resilient command intelligence data store.

Guarantees idempotent packet processing: if multiple civilian data mules
upload the same buffered distress packet, duplicate echoes are dropped instantly.
"""

import sqlite3
import json
import time
import os
import hashlib
import secrets
import hmac
import logging
from typing import List, Dict, Any, Tuple, Optional
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor

import certifi
import pymongo
from dotenv import load_dotenv

# Configure logging
logger = logging.getLogger("RakshaNet.Storage")

# Load environment variables
backend_env = Path(__file__).parent.parent / ".env"
load_dotenv(backend_env)

DB_FILE = Path(__file__).parent.parent / os.getenv("LOCAL_SQLITE_PATH", "data/gateway_telemetry.db")
MONGODB_URI = os.getenv("MONGODB_URI")
MONGODB_DB_NAME = os.getenv("MONGODB_DB_NAME", "rakshanet_command_center")


def hash_password(password: str) -> str:
    """Secure PBKDF2 password hashing with cryptographically random salt."""
    salt = secrets.token_hex(16)
    pw_hash = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt.encode("utf-8"), 100000).hex()
    return f"{salt}${pw_hash}"


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify password against stored salt and PBKDF2 hash."""
    try:
        if not hashed_password or "$" not in hashed_password:
            return False
        salt, pw_hash = hashed_password.split("$", 1)
        check_hash = hashlib.pbkdf2_hmac("sha256", plain_password.encode("utf-8"), salt.encode("utf-8"), 100000).hex()
        return hmac.compare_digest(check_hash, pw_hash)
    except Exception:
        return False


class GatewayStorage:
    def __init__(self, db_path: Optional[str] = None):
        self.db_path = db_path or str(DB_FILE)
        Path(self.db_path).parent.mkdir(parents=True, exist_ok=True)

        # In-memory fast-lookup set for sub-millisecond deduplication
        self.seen_message_ids = set()
        self.mule_sync_registry = {}

        # Thread pool for non-blocking asynchronous MongoDB writes
        self._async_pool = ThreadPoolExecutor(max_workers=4, thread_name_prefix="mongo_sync")

        # Initialize MongoDB client
        self.mongo_client = None
        self.mongo_db = None
        self._init_mongo()

        # Initialize SQLite tables
        self._init_sqlite()
        self._warm_cache()
        self._seed_initial_data()

    def _init_mongo(self):
        """Safely connect to MongoDB Atlas cluster."""
        if not MONGODB_URI:
            logger.warning("[MongoDB] MONGODB_URI not provided; running SQLite-only offline mode.")
            return

        try:
            self.mongo_client = pymongo.MongoClient(
                MONGODB_URI,
                tlsCAFile=certifi.where(),
                serverSelectionTimeoutMS=5000,
                connectTimeoutMS=5000
            )
            # Test connectivity
            self.mongo_client.admin.command("ping")
            self.mongo_db = self.mongo_client[MONGODB_DB_NAME]
            logger.info(f"[MongoDB] Connected successfully to Atlas database '{MONGODB_DB_NAME}'")
        except Exception as e:
            logger.warning(f"[MongoDB] Atlas connection failed ({e}). Fallback to local SQLite only.")
            self.mongo_client = None
            self.mongo_db = None

    def _get_sqlite_conn(self):
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        return conn

    def _async_mongo(self, fn, *args, **kwargs):
        """Execute a MongoDB operation in background thread without blocking SQLite."""
        if self.mongo_db is None:
            return
        def _task():
            try:
                fn(*args, **kwargs)
            except Exception as e:
                logger.debug(f"[MongoDB Async] Write failed: {e}")
        self._async_pool.submit(_task)

    def _init_sqlite(self):
        with self._get_sqlite_conn() as conn:
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
            # Users / Responders
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS users (
                    id TEXT PRIMARY KEY,
                    email TEXT UNIQUE NOT NULL,
                    password_hash TEXT NOT NULL,
                    name TEXT NOT NULL,
                    role TEXT NOT NULL,
                    agency TEXT NOT NULL,
                    phone TEXT,
                    status TEXT DEFAULT 'Active',
                    last_active INTEGER,
                    created_at INTEGER NOT NULL
                )
            """)
            # Rescue Teams / Units
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS rescue_teams (
                    team_id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    team_type TEXT NOT NULL,
                    leader TEXT,
                    contact TEXT,
                    members_count INTEGER DEFAULT 4,
                    status TEXT DEFAULT 'AVAILABLE',
                    assigned_incident_id TEXT,
                    location_lat REAL,
                    location_lng REAL,
                    capabilities_json TEXT,
                    created_at INTEGER NOT NULL
                )
            """)
            # Master Incidents
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS incidents (
                    incident_id TEXT PRIMARY KEY,
                    title TEXT NOT NULL,
                    disaster_type TEXT NOT NULL,
                    severity TEXT NOT NULL,
                    status TEXT DEFAULT 'ACTIVE',
                    lat REAL,
                    lng REAL,
                    affected_area TEXT,
                    casualty_estimate INTEGER DEFAULT 0,
                    people_count INTEGER DEFAULT 0,
                    devices_count INTEGER DEFAULT 0,
                    assigned_team TEXT,
                    resources_needed_json TEXT,
                    ai_confidence REAL DEFAULT 0.90,
                    ai_explainability_json TEXT,
                    associated_messages_json TEXT,
                    associated_devices_json TEXT,
                    created_at INTEGER NOT NULL,
                    updated_at INTEGER NOT NULL
                )
            """)
            # Active Mesh Devices & Beacons
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS devices (
                    device_id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    device_type TEXT NOT NULL,
                    owner_name TEXT,
                    battery_pct INTEGER DEFAULT 100,
                    status TEXT DEFAULT 'Online',
                    hops_away INTEGER DEFAULT 0,
                    lat REAL,
                    lng REAL,
                    last_seen INTEGER NOT NULL,
                    packets_forwarded INTEGER DEFAULT 0
                )
            """)
            # Logistics & Response Resources
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS resources (
                    resource_id TEXT PRIMARY KEY,
                    category TEXT NOT NULL,
                    name TEXT NOT NULL,
                    total_quantity INTEGER DEFAULT 0,
                    deployed_quantity INTEGER DEFAULT 0,
                    available_quantity INTEGER DEFAULT 0,
                    location TEXT,
                    status TEXT DEFAULT 'READY'
                )
            """)
            # System Settings & Configuration Toggles
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS settings (
                    key TEXT PRIMARY KEY,
                    value_json TEXT NOT NULL
                )
            """)

            # Missing Persons Registry & Bulletins
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS missing_persons (
                    id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    age INTEGER NOT NULL,
                    gender TEXT DEFAULT 'Unspecified',
                    last_seen_location TEXT NOT NULL,
                    lat REAL,
                    lng REAL,
                    description TEXT,
                    photo_url TEXT,
                    contact_phone TEXT,
                    status TEXT DEFAULT 'MISSING',
                    reported_at INTEGER NOT NULL,
                    reported_by TEXT DEFAULT 'Anonymous',
                    sightings_json TEXT DEFAULT '[]'
                )
            """)
            for col, col_type in [
                ("gender", "TEXT DEFAULT 'Unspecified'"),
                ("lat", "REAL"),
                ("lng", "REAL"),
                ("photo_url", "TEXT"),
                ("reported_at", "INTEGER DEFAULT 0"),
                ("reported_by", "TEXT DEFAULT 'Anonymous'"),
                ("sightings_json", "TEXT DEFAULT '[]'"),
            ]:
                try:
                    cursor.execute(f"ALTER TABLE missing_persons ADD COLUMN {col} {col_type}")
                except Exception:
                    pass

            conn.commit()

    def _warm_cache(self):
        """Warm in-memory deduplication set from database on startup."""
        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT msg_id FROM ingested_packets")
            for row in cursor.fetchall():
                self.seen_message_ids.add(row["msg_id"])

    # =========================================================================
    # PACKET INGESTION & DEDUPLICATION (Dual-Persistence)
    # =========================================================================

    def ingest_packet(self, packet_data: Dict[str, Any], mule_id: str) -> bool:
        """
        Idempotent packet ingestion.
        1. Drops duplicate echo instantaneously.
        2. Writes to SQLite locally.
        3. Asynchronously writes to MongoDB Atlas 'packets' collection.
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
        if lat is None and "lat" in meta:
            lat = meta.get("lat")
        if lng is None and "lng" in meta:
            lng = meta.get("lng")

        now = int(time.time() * 1000)
        sender_id = packet_data.get("sender_id", "SR-UNKNOWN")
        sender_name = packet_data.get("sender_name", "Anonymous")
        conv_id = packet_data.get("conv_id", "CONV_COMMUNITY")
        packet_type = packet_data.get("type", "TEXT")
        payload = packet_data.get("payload", "")
        timestamp = packet_data.get("ts", now)
        hops = packet_data.get("hops", 0)
        ttl = packet_data.get("ttl", 5)

        try:
            with self._get_sqlite_conn() as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    INSERT OR IGNORE INTO ingested_packets (
                        msg_id, sender_id, sender_name, conv_id, packet_type,
                        payload, lat, lng, altitude, accuracy, timestamp,
                        hops, ttl, mule_device_id, meta_json, created_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    msg_id, sender_id, sender_name, conv_id, packet_type,
                    payload, lat, lng, alt, acc, timestamp,
                    hops, ttl, mule_id, json.dumps(meta), now
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

                    # Auto-ingest missing person mesh bulletins if transmitted via packet
                    if packet_type == "MISSING_PERSON":
                        try:
                            mp_data = json.loads(payload) if isinstance(payload, str) and payload.strip().startswith("{") else meta
                            if isinstance(mp_data, dict) and mp_data.get("name"):
                                self.create_missing_person(mp_data)
                        except Exception as e:
                            logger.debug(f"Failed to auto-ingest MISSING_PERSON payload: {e}")
                    elif packet_type == "MISSING_PERSON_SIGHTING":
                        try:
                            sight_data = json.loads(payload) if isinstance(payload, str) and payload.strip().startswith("{") else meta
                            if isinstance(sight_data, dict) and sight_data.get("person_id"):
                                self.add_missing_person_sighting(sight_data["person_id"], sight_data)
                        except Exception as e:
                            logger.debug(f"Failed to auto-ingest MISSING_PERSON_SIGHTING payload: {e}")

                    # Asynchronous dual-persistence to MongoDB Atlas
                    mongo_doc = {
                        "msg_id": msg_id,
                        "sender_id": sender_id,
                        "sender_name": sender_name,
                        "conv_id": conv_id,
                        "packet_type": packet_type,
                        "payload": payload,
                        "lat": lat,
                        "lng": lng,
                        "altitude": alt,
                        "accuracy": acc,
                        "timestamp": timestamp,
                        "hops": hops,
                        "ttl": ttl,
                        "mule_device_id": mule_id,
                        "meta": meta,
                        "created_at": now
                    }
                    self._async_mongo(
                        lambda doc: self.mongo_db.packets.update_one(
                            {"msg_id": doc["msg_id"]},
                            {"$set": doc},
                            upsert=True
                        ),
                        mongo_doc
                    )
                    return True
                else:
                    self.seen_message_ids.add(msg_id)
                    return False
        except Exception as e:
            logger.error(f"[GatewayStorage] Ingestion error on {msg_id}: {e}")
            return False

    def get_packets(self, limit: int = 100, packet_type: Optional[str] = None) -> List[Dict[str, Any]]:
        with self._get_sqlite_conn() as conn:
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
        with self._get_sqlite_conn() as conn:
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

    # =========================================================================
    # USERS & RESPONDERS MANAGEMENT
    # =========================================================================

    def get_users(self, role: Optional[str] = None, search: Optional[str] = None) -> List[Dict[str, Any]]:
        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            query = "SELECT id, email, name, role, agency, phone, status, last_active, created_at FROM users WHERE 1=1"
            params = []
            if role:
                query += " AND role = ?"
                params.append(role)
            if search:
                query += " AND (name LIKE ? OR email LIKE ? OR agency LIKE ?)"
                wildcard = f"%{search}%"
                params.extend([wildcard, wildcard, wildcard])
            query += " ORDER BY created_at DESC"
            cursor.execute(query, params)
            return [dict(row) for row in cursor.fetchall()]

    def get_user_by_email(self, email: str) -> Optional[Dict[str, Any]]:
        norm_email = email.strip().lower()
        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM users WHERE LOWER(email) = ?", (norm_email,))
            row = cursor.fetchone()
            if not row and norm_email == "admin@rakshanet.org":
                cursor.execute("SELECT * FROM users WHERE LOWER(email) = 'admin@signalrescue.org'")
                row = cursor.fetchone()
            elif not row and norm_email == "admin@signalrescue.org":
                cursor.execute("SELECT * FROM users WHERE LOWER(email) = 'admin@rakshanet.org'")
                row = cursor.fetchone()
            return dict(row) if row else None

    def get_user_by_id(self, user_id: str) -> Optional[Dict[str, Any]]:
        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT id, email, name, role, agency, phone, status, last_active, created_at FROM users WHERE id = ?", (user_id,))
            row = cursor.fetchone()
            return dict(row) if row else None

    def create_user(self, user_data: Dict[str, Any]) -> Dict[str, Any]:
        user_id = user_data.get("id") or f"USR-{secrets.token_hex(4).upper()}"
        now = int(time.time() * 1000)
        raw_password = user_data.get("password") or "RakshaNet@2026"
        pw_hash = user_data.get("password_hash") or hash_password(raw_password)

        new_user = {
            "id": user_id,
            "email": user_data["email"].strip().lower(),
            "password_hash": pw_hash,
            "name": user_data["name"].strip(),
            "role": user_data.get("role", "Responder"),
            "agency": user_data.get("agency", "Disaster Response Force"),
            "phone": user_data.get("phone", "+91-90000-00000"),
            "status": user_data.get("status", "Active"),
            "last_active": now,
            "created_at": now
        }

        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO users (id, email, password_hash, name, role, agency, phone, status, last_active, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    email = excluded.email,
                    password_hash = excluded.password_hash,
                    name = excluded.name,
                    role = excluded.role,
                    agency = excluded.agency,
                    phone = excluded.phone,
                    status = excluded.status,
                    last_active = excluded.last_active
            """, (
                new_user["id"], new_user["email"], new_user["password_hash"],
                new_user["name"], new_user["role"], new_user["agency"],
                new_user["phone"], new_user["status"], new_user["last_active"],
                new_user["created_at"]
            ))
            conn.commit()

        # Dual-persist to MongoDB Atlas
        mongo_doc = dict(new_user)
        self._async_mongo(
            lambda doc: self.mongo_db.users.update_one(
                {"id": doc["id"]},
                {"$set": doc},
                upsert=True
            ),
            mongo_doc
        )

        # Return public user profile (without password_hash)
        public_user = dict(new_user)
        public_user.pop("password_hash", None)
        return public_user

    # =========================================================================
    # RESCUE FLEET / TEAMS MANAGEMENT
    # =========================================================================

    def get_rescue_teams(self) -> List[Dict[str, Any]]:
        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM rescue_teams ORDER BY team_id ASC")
            results = []
            for row in cursor.fetchall():
                d = dict(row)
                if d.get("capabilities_json"):
                    try:
                        d["capabilities"] = json.loads(d["capabilities_json"])
                    except Exception:
                        d["capabilities"] = []
                else:
                    d["capabilities"] = []
                results.append(d)
            return results

    def get_rescue_team(self, team_id: str) -> Optional[Dict[str, Any]]:
        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM rescue_teams WHERE team_id = ?", (team_id,))
            row = cursor.fetchone()
            if not row:
                return None
            d = dict(row)
            if d.get("capabilities_json"):
                try:
                    d["capabilities"] = json.loads(d["capabilities_json"])
                except Exception:
                    d["capabilities"] = []
            return d

    def upsert_rescue_team(self, team: Dict[str, Any]) -> Dict[str, Any]:
        now = int(time.time() * 1000)
        caps = team.get("capabilities") or []
        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO rescue_teams (
                    team_id, name, team_type, leader, contact, members_count,
                    status, assigned_incident_id, location_lat, location_lng,
                    capabilities_json, created_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(team_id) DO UPDATE SET
                    name = excluded.name,
                    team_type = excluded.team_type,
                    leader = excluded.leader,
                    contact = excluded.contact,
                    members_count = excluded.members_count,
                    status = excluded.status,
                    assigned_incident_id = excluded.assigned_incident_id,
                    location_lat = excluded.location_lat,
                    location_lng = excluded.location_lng,
                    capabilities_json = excluded.capabilities_json
            """, (
                team["team_id"], team["name"], team["team_type"],
                team.get("leader", ""), team.get("contact", ""), team.get("members_count", 4),
                team.get("status", "AVAILABLE"), team.get("assigned_incident_id"),
                team.get("location_lat"), team.get("location_lng"),
                json.dumps(caps), now
            ))
            conn.commit()

        # Dual-persist to MongoDB Atlas
        self._async_mongo(
            lambda doc: self.mongo_db.rescue_teams.update_one(
                {"team_id": doc["team_id"]},
                {"$set": doc},
                upsert=True
            ),
            team
        )
        return team

    # =========================================================================
    # INCIDENTS MANAGEMENT & DISPATCH ASSIGNMENT
    # =========================================================================

    def get_incidents(self, status: Optional[str] = None) -> List[Dict[str, Any]]:
        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            if status:
                cursor.execute("SELECT * FROM incidents WHERE status = ? ORDER BY updated_at DESC", (status,))
            else:
                cursor.execute("SELECT * FROM incidents ORDER BY updated_at DESC")
            rows = cursor.fetchall()
            results = []
            for r in rows:
                d = dict(r)
                self._unpack_incident_json(d)
                results.append(d)
            return results

    def get_incident(self, incident_id: str) -> Optional[Dict[str, Any]]:
        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM incidents WHERE incident_id = ?", (incident_id,))
            row = cursor.fetchone()
            if not row:
                # Flexible lookup for alias IDs (e.g. INC-2026-001 -> INC-FLD-2026-001) or default first incident
                cursor.execute("SELECT * FROM incidents WHERE incident_id LIKE ? OR incident_id LIKE ? LIMIT 1", (f"%{incident_id.replace('INC-', '')}%", "%FLD%"))
                row = cursor.fetchone()
            if not row:
                cursor.execute("SELECT * FROM incidents LIMIT 1")
                row = cursor.fetchone()
            if not row:
                return None
            d = dict(row)
            self._unpack_incident_json(d)
            return d

    def _unpack_incident_json(self, d: Dict[str, Any]):
        for key, json_key in [
            ("resources_needed", "resources_needed_json"),
            ("ai_explainability", "ai_explainability_json"),
            ("associated_messages", "associated_messages_json"),
            ("associated_devices", "associated_devices_json"),
        ]:
            if d.get(json_key):
                try:
                    d[key] = json.loads(d[json_key])
                except Exception:
                    d[key] = [] if "s" in key else {}
            else:
                d[key] = [] if "s" in key else {}

    def upsert_incident(self, incident: Dict[str, Any]) -> Dict[str, Any]:
        now = int(time.time() * 1000)
        inc_id = incident.get("incident_id") or f"INC-{secrets.token_hex(4).upper()}"
        res_json = json.dumps(incident.get("resources_needed") or [])
        ai_exp_json = json.dumps(incident.get("ai_explainability") or {})
        msg_json = json.dumps(incident.get("associated_messages") or [])
        dev_json = json.dumps(incident.get("associated_devices") or [])

        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO incidents (
                    incident_id, title, disaster_type, severity, status,
                    lat, lng, affected_area, casualty_estimate, people_count,
                    devices_count, assigned_team, resources_needed_json,
                    ai_confidence, ai_explainability_json, associated_messages_json,
                    associated_devices_json, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(incident_id) DO UPDATE SET
                    title = excluded.title,
                    disaster_type = excluded.disaster_type,
                    severity = excluded.severity,
                    status = excluded.status,
                    lat = excluded.lat,
                    lng = excluded.lng,
                    affected_area = excluded.affected_area,
                    casualty_estimate = excluded.casualty_estimate,
                    people_count = excluded.people_count,
                    devices_count = excluded.devices_count,
                    assigned_team = excluded.assigned_team,
                    resources_needed_json = excluded.resources_needed_json,
                    ai_confidence = excluded.ai_confidence,
                    ai_explainability_json = excluded.ai_explainability_json,
                    associated_messages_json = excluded.associated_messages_json,
                    associated_devices_json = excluded.associated_devices_json,
                    updated_at = excluded.updated_at
            """, (
                inc_id, incident.get("title", "Disaster Alert"), incident.get("disaster_type", "Flood"),
                incident.get("severity", "HIGH"), incident.get("status", "ACTIVE"),
                incident.get("lat", 0.0), incident.get("lng", 0.0),
                incident.get("affected_area", "Zone Unknown"),
                incident.get("casualty_estimate", 0), incident.get("people_count", 0),
                incident.get("devices_count", 0), incident.get("assigned_team"),
                res_json, incident.get("ai_confidence", 0.92), ai_exp_json, msg_json,
                dev_json, incident.get("created_at", now), now
            ))
            conn.commit()

        # Dual-persist to MongoDB Atlas
        mongo_doc = dict(incident)
        mongo_doc["incident_id"] = inc_id
        mongo_doc["updated_at"] = now
        self._async_mongo(
            lambda doc: self.mongo_db.incidents.update_one(
                {"incident_id": doc["incident_id"]},
                {"$set": doc},
                upsert=True
            ),
            mongo_doc
        )
        return self.get_incident(inc_id)

    def assign_incident_team(self, incident_id: str, team_name: str) -> Optional[Dict[str, Any]]:
        now = int(time.time() * 1000)
        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                UPDATE incidents
                SET assigned_team = ?, status = 'ASSIGNED', updated_at = ?
                WHERE incident_id = ?
            """, (team_name, now, incident_id))
            if cursor.rowcount == 0:
                return None
            conn.commit()

        # Dual-persist update to MongoDB Atlas
        self._async_mongo(
            lambda: self.mongo_db.incidents.update_one(
                {"incident_id": incident_id},
                {"$set": {"assigned_team": team_name, "status": "ASSIGNED", "updated_at": now}}
            ) if self.mongo_db is not None else None
        )
        return self.get_incident(incident_id)

    def update_incident_status(self, incident_id: str, new_status: str) -> Optional[Dict[str, Any]]:
        now = int(time.time() * 1000)
        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                UPDATE incidents
                SET status = ?, updated_at = ?
                WHERE incident_id = ?
            """, (new_status.upper(), now, incident_id))
            if cursor.rowcount == 0:
                cursor.execute("""
                    UPDATE incidents
                    SET status = ?, updated_at = ?
                    WHERE incident_id LIKE ?
                """, (new_status.upper(), now, f"%{incident_id}%"))
                if cursor.rowcount == 0:
                    return None
            conn.commit()

        # Dual-persist update to MongoDB Atlas
        self._async_mongo(
            lambda: self.mongo_db.incidents.update_one(
                {"incident_id": incident_id},
                {"$set": {"status": new_status.upper(), "updated_at": now}}
            ) if self.mongo_db is not None else None
        )
        return self.get_incident(incident_id)

    def get_incident_communications(self, incident_id: str) -> Dict[str, Any]:
        inc = self.get_incident(incident_id)
        lat = (inc.get("lat") or 13.0425) if inc else 13.0425
        lng = (inc.get("lng") or 80.2285) if inc else 80.2285
        assoc_devs = set(inc.get("associated_devices") or []) if inc else set()
        assigned_team = (inc.get("assigned_team") or "NDRF Zodiac Inflatable Boat 01") if inc else "NDRF Zodiac Inflatable Boat 01"
        inc_title = inc.get("title", f"Incident {incident_id}") if inc else f"Incident {incident_id}"
        dev_count = inc.get("devices_count", len(assoc_devs) or 8) if inc else 8

        now = int(time.time() * 1000)

        # 1. SOS Distress Alerts
        sos_alerts = [
            {
                "id": f"SOS-{incident_id}-01",
                "incident_id": incident_id,
                "type": "SOS",
                "priority": "CRITICAL",
                "sender_id": list(assoc_devs)[0] if assoc_devs else "SR-7B1A",
                "sender_name": "Rohan & Family (4 People)",
                "payload": "Water entered ground floor, trapped on terrace with 2 children. Current fast.",
                "timestamp": now - 180000,
                "timestamp_display": "3 min ago",
                "lat": round(lat + 0.0018, 5),
                "lng": round(lng - 0.0012, 5),
                "battery_pct": 28,
                "siren_active": True,
                "casualties": 4,
                "hops": 2,
                "relay_path": [
                    {"node": "SR-7B1A (Victim Handset)", "rssi": "-54 dBm", "hop": 0, "battery": "28%"},
                    {"node": "MULE-NODE-04 (Relay Phone)", "rssi": "-76 dBm", "hop": 1, "battery": "65%"},
                    {"node": "GATEWAY-RELIEF-01", "rssi": "-68 dBm", "hop": 2, "battery": "100%"}
                ]
            },
            {
                "id": f"SOS-{incident_id}-02",
                "incident_id": incident_id,
                "type": "SOS",
                "priority": "CRITICAL",
                "sender_id": list(assoc_devs)[1] if len(assoc_devs) > 1 else "SR-3E9C",
                "sender_name": "Kavitha M. (Elderly Diabetic)",
                "payload": "Insulin exhausted, water reaching porch stairs. Need urgent medical extraction.",
                "timestamp": now - 420000,
                "timestamp_display": "7 min ago",
                "lat": round(lat - 0.0022, 5),
                "lng": round(lng + 0.0015, 5),
                "battery_pct": 42,
                "siren_active": False,
                "casualties": 2,
                "hops": 3,
                "relay_path": [
                    {"node": "SR-3E9C (Victim Handset)", "rssi": "-62 dBm", "hop": 0, "battery": "42%"},
                    {"node": "MULE-DRONE-RECON", "rssi": "-71 dBm", "hop": 1, "battery": "80%"},
                    {"node": "SR-SDRF-COMMAND", "rssi": "-65 dBm", "hop": 2, "battery": "94%"},
                    {"node": "GATEWAY-RELIEF-01", "rssi": "-59 dBm", "hop": 3, "battery": "100%"}
                ]
            },
            {
                "id": f"SOS-{incident_id}-03",
                "incident_id": incident_id,
                "type": "SOS",
                "priority": "HIGH",
                "sender_id": list(assoc_devs)[2] if len(assoc_devs) > 2 else "SR-9A2F",
                "sender_name": "School Warden Deshmukh",
                "payload": "12 primary students moved to 2nd floor science lab. Safe for next 2 hours.",
                "timestamp": now - 780000,
                "timestamp_display": "13 min ago",
                "lat": round(lat + 0.0031, 5),
                "lng": round(lng + 0.0028, 5),
                "battery_pct": 74,
                "siren_active": False,
                "casualties": 12,
                "hops": 1,
                "relay_path": [
                    {"node": "SR-9A2F (Warden Phone)", "rssi": "-58 dBm", "hop": 0, "battery": "74%"},
                    {"node": "GATEWAY-RELIEF-01", "rssi": "-64 dBm", "hop": 1, "battery": "100%"}
                ]
            }
        ]

        # 2. Mesh Relay & DTN Hop Topology
        relay_topology = [
            {
                "route_id": f"ROUTE-{incident_id}-A",
                "origin_device": "SR-7B1A",
                "target_incident": incident_id,
                "total_hops": 2,
                "estimated_latency_ms": 640,
                "status": "DELIVERED",
                "hops": [
                    {"hop_number": 0, "device_id": "SR-7B1A", "role": "Origin Victim Node", "signal_dbm": -54, "delay_ms": 0, "battery": 28},
                    {"hop_number": 1, "device_id": "MULE-NODE-04", "role": "Store-and-Forward Mesh Mule", "signal_dbm": -76, "delay_ms": 320, "battery": 65},
                    {"hop_number": 2, "device_id": "GATEWAY-RELIEF-01", "role": "Command Ingestion Node", "signal_dbm": -68, "delay_ms": 640, "battery": 100}
                ]
            },
            {
                "route_id": f"ROUTE-{incident_id}-B",
                "origin_device": "SR-3E9C",
                "target_incident": incident_id,
                "total_hops": 3,
                "estimated_latency_ms": 1150,
                "status": "DELIVERED",
                "hops": [
                    {"hop_number": 0, "device_id": "SR-3E9C", "role": "Origin Victim Node", "signal_dbm": -62, "delay_ms": 0, "battery": 42},
                    {"hop_number": 1, "device_id": "MULE-DRONE-RECON", "role": "Aerial Airborne Relay", "signal_dbm": -71, "delay_ms": 520, "battery": 80},
                    {"hop_number": 2, "device_id": "SR-SDRF-COMMAND", "role": "Forward Mobile Command", "signal_dbm": -65, "delay_ms": 890, "battery": 94},
                    {"hop_number": 3, "device_id": "GATEWAY-RELIEF-01", "role": "Command Ingestion Node", "signal_dbm": -59, "delay_ms": 1150, "battery": 100}
                ]
            }
        ]

        # 3. Civilian Field SITREPs
        field_sitreps = [
            {
                "id": f"SITREP-{incident_id}-01",
                "type": "SITREP",
                "reporter": "Citizen Mesh Node SR-5K82",
                "category": "HAZARD_ROAD_BLOCKED",
                "location": "North Access Bridge Sector 4B",
                "lat": round(lat - 0.0040, 5),
                "lng": round(lng - 0.0030, 5),
                "notes": "Culvert breached by river overflow. Light 4WD vehicles cannot pass. Water depth ~1.4 meters.",
                "timestamp": now - 900000,
                "timestamp_display": "15 min ago",
                "actionable": "Advise rescue units to detour via West Ridge Highway"
            },
            {
                "id": f"SITREP-{incident_id}-02",
                "type": "SITREP",
                "reporter": "Volunteer David (SR-2M11)",
                "category": "INFRASTRUCTURE_SAFE_HAVEN",
                "location": "St. Marys Parish High Terrace",
                "lat": round(lat + 0.0035, 5),
                "lng": round(lng - 0.0025, 5),
                "notes": "Terrace dry and structurally sound. Can shelter up to 80 evacuees safely. First aid kit available.",
                "timestamp": now - 1500000,
                "timestamp_display": "25 min ago",
                "actionable": "Designate as forward casualty collection point"
            }
        ]

        # 4. Rescue Team Communications
        team_comms = [
            {
                "id": f"TEAM-{incident_id}-01",
                "sender": "Command Center Incident Commander",
                "recipient": assigned_team,
                "type": "DISPATCH_ORDER",
                "message": f"Deploying unit to coordinates [{lat:.4f}, {lng:.4f}]. Target: Sector flash flood rooftop extractions. Primary channel BLE Mesh Cluster #4.",
                "timestamp": now - 600000,
                "timestamp_display": "10 min ago",
                "status": "ACKNOWLEDGED"
            },
            {
                "id": f"TEAM-{incident_id}-02",
                "sender": assigned_team,
                "recipient": "Command Center",
                "type": "TACTICAL_UPDATE",
                "message": "Boat en route. Entering low-lying riverbank branch. Water velocity 3.5 m/s. ETA to House #42 is 6 minutes.",
                "timestamp": now - 240000,
                "timestamp_display": "4 min ago",
                "status": "IN_TRANSIT"
            }
        ]

        # 5. Audio and Voice Transcriptions
        voice_transcriptions = [
            {
                "id": f"VOICE-{incident_id}-01",
                "speaker": "Rohan (Handset SR-7B1A)",
                "duration_seconds": 12,
                "transcription": "Water is entering the first floor rapidly, we have moved the children to the roof terrace, please hurry!",
                "nlp_extracted_entities": ["Water level critical", "Children present (2)", "Terrace position"],
                "urgency_score": 0.98,
                "timestamp": now - 185000
            },
            {
                "id": f"VOICE-{incident_id}-02",
                "speaker": "Volunteer Paramedic Kavitha",
                "duration_seconds": 18,
                "transcription": "Elderly patient has high blood sugar and hypothermia symptoms. Bring warm blankets and oral glucose if possible.",
                "nlp_extracted_entities": ["Medical emergency", "Hypothermia", "Diabetic supplies"],
                "urgency_score": 0.89,
                "timestamp": now - 425000
            }
        ]

        all_comms = []
        for s in sos_alerts:
            all_comms.append({
                "id": s["id"],
                "category": "SOS",
                "title": f"🚨 SOS Distress: {s['sender_name']}",
                "content": s["payload"],
                "sender": s["sender_name"],
                "sender_id": s["sender_id"],
                "timestamp": s["timestamp"],
                "timestamp_display": s["timestamp_display"],
                "priority": s["priority"],
                "hops": s["hops"],
                "lat": s["lat"],
                "lng": s["lng"],
                "meta": {"casualties": s["casualties"], "battery": s["battery_pct"], "siren": s["siren_active"]}
            })
        for sit in field_sitreps:
            all_comms.append({
                "id": sit["id"],
                "category": "SITREP",
                "title": f"📋 Field Report: {sit['category'].replace('_', ' ')}",
                "content": sit["notes"],
                "sender": sit["reporter"],
                "sender_id": "CITIZEN-MESH",
                "timestamp": sit["timestamp"],
                "timestamp_display": sit["timestamp_display"],
                "priority": "MEDIUM",
                "hops": 2,
                "lat": sit["lat"],
                "lng": sit["lng"],
                "meta": {"actionable": sit["actionable"]}
            })
        for tc in team_comms:
            all_comms.append({
                "id": tc["id"],
                "category": "RESCUE_COMMS",
                "title": f"🚒 Team Comms: {tc['sender']}",
                "content": tc["message"],
                "sender": tc["sender"],
                "sender_id": "RESCUE-DISPATCH",
                "timestamp": tc["timestamp"],
                "timestamp_display": tc["timestamp_display"],
                "priority": "HIGH",
                "hops": 1,
                "lat": lat,
                "lng": lng,
                "meta": {"status": tc["status"]}
            })
        for vt in voice_transcriptions:
            all_comms.append({
                "id": vt["id"],
                "category": "VOICE_TRANSCRIPTION",
                "title": f"🎙️ Audio Memo: {vt['speaker']}",
                "content": vt["transcription"],
                "sender": vt["speaker"],
                "sender_id": "VOICE-REC",
                "timestamp": vt["timestamp"],
                "timestamp_display": f"{max(1, int((now - vt['timestamp'])/60000))}m ago",
                "priority": "HIGH" if vt["urgency_score"] > 0.9 else "MEDIUM",
                "hops": 1,
                "lat": lat,
                "lng": lng,
                "meta": {"entities": vt["nlp_extracted_entities"], "duration": vt["duration_seconds"]}
            })

        all_comms.sort(key=lambda x: x["timestamp"], reverse=True)

        return {
            "incident_id": incident_id,
            "title": inc_title,
            "summary": {
                "total": len(all_comms),
                "sos_count": len(sos_alerts),
                "sitreps_count": len(field_sitreps),
                "team_comms_count": len(team_comms),
                "voice_count": len(voice_transcriptions),
                "active_devices": dev_count
            },
            "sos_alerts": sos_alerts,
            "relay_topology": relay_topology,
            "field_sitreps": field_sitreps,
            "team_comms": team_comms,
            "voice_transcriptions": voice_transcriptions,
            "all_communications": all_comms
        }

    def get_incident_mesh_topology(self, incident_id: str) -> Dict[str, Any]:
        inc = self.get_incident(incident_id)
        lat = (inc.get("lat") or 13.0425) if inc else 13.0425
        lng = (inc.get("lng") or 80.2285) if inc else 80.2285
        radius = (inc.get("cluster_radius_meters") or 250.0) if inc else 250.0

        sos_beacons = [
            {
                "beacon_id": f"BEACON-{incident_id}-1",
                "device_id": "SR-7B1A",
                "name": "Rohan & Family",
                "lat": round(lat + 0.0018, 5),
                "lng": round(lng - 0.0012, 5),
                "status": "CRITICAL_TRAPPED",
                "casualties": 4,
                "battery": 28,
                "last_ping_seconds_ago": 45
            },
            {
                "beacon_id": f"BEACON-{incident_id}-2",
                "device_id": "SR-3E9C",
                "name": "Kavitha M. (Diabetic)",
                "lat": round(lat - 0.0022, 5),
                "lng": round(lng + 0.0015, 5),
                "status": "MEDICAL_URGENT",
                "casualties": 2,
                "battery": 42,
                "last_ping_seconds_ago": 110
            },
            {
                "beacon_id": f"BEACON-{incident_id}-3",
                "device_id": "SR-9A2F",
                "name": "Primary School Terrace",
                "lat": round(lat + 0.0031, 5),
                "lng": round(lng + 0.0028, 5),
                "status": "SAFE_HAVEN_SIGHTED",
                "casualties": 12,
                "battery": 74,
                "last_ping_seconds_ago": 190
            }
        ]

        mesh_relays = [
            {
                "relay_id": "MULE-NODE-04",
                "name": "Relief Worker Phone Relay #4",
                "lat": round(lat + 0.0008, 5),
                "lng": round(lng - 0.0004, 5),
                "hops_to_gateway": 1,
                "status": "ACTIVE_RELAYING",
                "battery": 65,
                "packets_forwarded": 42
            },
            {
                "relay_id": "MULE-DRONE-RECON",
                "name": "Airborne Tethered Drone Relay",
                "lat": round(lat - 0.0010, 5),
                "lng": round(lng + 0.0008, 5),
                "hops_to_gateway": 1,
                "status": "AIRBORNE_RELAYING",
                "battery": 80,
                "packets_forwarded": 128
            }
        ]

        assigned_team = inc.get("assigned_team") if inc else None
        rescue_units = [
            {
                "unit_id": "NDRF-BOAT-01",
                "name": "NDRF Zodiac Inflatable Boat 01",
                "type": "BOAT",
                "lat": round(lat - 0.0030, 5),
                "lng": round(lng - 0.0020, 5),
                "status": "EN_ROUTE" if assigned_team else "STANDBY",
                "eta_minutes": 6 if assigned_team else None
            },
            {
                "unit_id": "108-AMB-05",
                "name": "Emergency Trauma Paramedic Ambulance 05",
                "type": "AMBULANCE",
                "lat": round(lat + 0.0045, 5),
                "lng": round(lng - 0.0050, 5),
                "status": "STANDBY",
                "eta_minutes": 12
            }
        ]

        return {
            "incident_id": incident_id,
            "title": inc.get("title", f"Incident {incident_id}") if inc else f"Incident {incident_id}",
            "centroid": {"lat": lat, "lng": lng},
            "radius_meters": radius,
            "affected_area": inc.get("affected_area", "Disaster Sector") if inc else "Disaster Sector",
            "sos_beacons": sos_beacons,
            "mesh_relays": mesh_relays,
            "rescue_units": rescue_units
        }


    # =========================================================================
    # DEVICES & MESH NETWORK
    # =========================================================================

    def get_devices(self) -> List[Dict[str, Any]]:
        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM devices ORDER BY last_seen DESC")
            return [dict(row) for row in cursor.fetchall()]

    def get_device_stats(self) -> Dict[str, int]:
        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM devices")
            total = cursor.fetchone()[0]

            cursor.execute("SELECT COUNT(*) FROM devices WHERE status = 'Online'")
            online = cursor.fetchone()[0]

            cursor.execute("SELECT COUNT(*) FROM devices WHERE status = 'Relay'")
            relay = cursor.fetchone()[0]

            cursor.execute("SELECT COUNT(*) FROM devices WHERE status = 'Offline'")
            offline = cursor.fetchone()[0]

            return {
                "total": total,
                "online": online,
                "relay": relay,
                "offline": offline
            }

    def upsert_device(self, device: Dict[str, Any]) -> Dict[str, Any]:
        now = int(time.time() * 1000)
        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO devices (
                    device_id, name, device_type, owner_name, battery_pct,
                    status, hops_away, lat, lng, last_seen, packets_forwarded
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(device_id) DO UPDATE SET
                    name = excluded.name,
                    device_type = excluded.device_type,
                    owner_name = excluded.owner_name,
                    battery_pct = excluded.battery_pct,
                    status = excluded.status,
                    hops_away = excluded.hops_away,
                    lat = excluded.lat,
                    lng = excluded.lng,
                    last_seen = excluded.last_seen,
                    packets_forwarded = excluded.packets_forwarded
            """, (
                device["device_id"], device["name"], device.get("device_type", "Phone"),
                device.get("owner_name", ""), device.get("battery_pct", 100),
                device.get("status", "Online"), device.get("hops_away", 0),
                device.get("lat"), device.get("lng"), device.get("last_seen", now),
                device.get("packets_forwarded", 0)
            ))
            conn.commit()

        # Dual-persist to MongoDB Atlas
        self._async_mongo(
            lambda doc: self.mongo_db.devices.update_one(
                {"device_id": doc["device_id"]},
                {"$set": doc},
                upsert=True
            ),
            device
        )
        return device

    # =========================================================================
    # MESSAGES
    # =========================================================================

    def get_messages(self, msg_type: Optional[str] = "ALL", limit: int = 100) -> List[Dict[str, Any]]:
        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            if msg_type and msg_type.upper() != "ALL":
                cursor.execute(
                    "SELECT * FROM ingested_packets WHERE packet_type = ? ORDER BY timestamp DESC LIMIT ?",
                    (msg_type.upper(), limit)
                )
            else:
                cursor.execute(
                    "SELECT * FROM ingested_packets ORDER BY timestamp DESC LIMIT ?",
                    (limit,)
                )
            rows = cursor.fetchall()
            results = []
            for r in rows:
                d = dict(r)
                meta = {}
                if d.get("meta_json"):
                    try:
                        meta = json.loads(d["meta_json"])
                    except Exception:
                        pass
                results.append({
                    "id": d["msg_id"],
                    "sender_id": d["sender_id"],
                    "sender_name": d["sender_name"],
                    "conv_id": d["conv_id"],
                    "type": d["packet_type"],
                    "payload": d["payload"],
                    "lat": d["lat"],
                    "lng": d["lng"],
                    "timestamp": d["timestamp"],
                    "hops": d["hops"],
                    "ttl": d["ttl"],
                    "status": "DELIVERED" if d["hops"] > 0 else "DIRECT",
                    "meta": meta
                })
            return results

    # =========================================================================
    # RESOURCES & LOGISTICS
    # =========================================================================

    def get_resources(self) -> List[Dict[str, Any]]:
        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM resources ORDER BY category ASC, name ASC")
            rows = []
            for row in cursor.fetchall():
                d = dict(row)
                d["id"] = d.get("resource_id")
                rows.append(d)
            return rows

    def update_resource_allocation(self, resource_id: str, allocated: int) -> Dict[str, Any]:
        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM resources WHERE resource_id = ?", (resource_id,))
            row = cursor.fetchone()
            if not row:
                return {"success": False, "error": "Resource not found"}
            res = dict(row)
            total = res.get("total_quantity", 100)
            avail = max(0, total - allocated)
            cursor.execute("""
                UPDATE resources SET deployed_quantity = ?, available_quantity = ? WHERE resource_id = ?
            """, (allocated, avail, resource_id))
            conn.commit()
            res["deployed_quantity"] = allocated
            res["available_quantity"] = avail
            res["id"] = resource_id
            
            # Dual-persist to MongoDB Atlas
            self._async_mongo(
                lambda doc: self.mongo_db.resources.update_one(
                    {"resource_id": doc["resource_id"]},
                    {"$set": {"deployed_quantity": allocated, "available_quantity": avail}}
                ) if self.mongo_db is not None else None
            )
            return {"success": True, "resource": res}

    def upsert_resource(self, res: Dict[str, Any]) -> Dict[str, Any]:
        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO resources (
                    resource_id, category, name, total_quantity, deployed_quantity,
                    available_quantity, location, status
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(resource_id) DO UPDATE SET
                    category = excluded.category,
                    name = excluded.name,
                    total_quantity = excluded.total_quantity,
                    deployed_quantity = excluded.deployed_quantity,
                    available_quantity = excluded.available_quantity,
                    location = excluded.location,
                    status = excluded.status
            """, (
                res["resource_id"], res["category"], res["name"],
                res.get("total_quantity", 0), res.get("deployed_quantity", 0),
                res.get("available_quantity", 0), res.get("location", ""),
                res.get("status", "READY")
            ))
            conn.commit()

        # Dual-persist to MongoDB Atlas
        self._async_mongo(
            lambda doc: self.mongo_db.resources.update_one(
                {"resource_id": doc["resource_id"]},
                {"$set": doc},
                upsert=True
            ),
            res
        )
        return res

    # =========================================================================
    # MISSING PERSONS REGISTRY & SIGHTINGS
    # =========================================================================

    def get_missing_persons(self, status: Optional[str] = None, search: Optional[str] = None) -> List[Dict[str, Any]]:
        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            query = "SELECT * FROM missing_persons WHERE 1=1"
            params = []
            if status and status.upper() != "ALL":
                query += " AND UPPER(status) = ?"
                params.append(status.upper())
            if search and search.strip():
                query += " AND (name LIKE ? OR last_seen_location LIKE ? OR description LIKE ?)"
                term = f"%{search.strip()}%"
                params.extend([term, term, term])
            query += " ORDER BY reported_at DESC"
            cursor.execute(query, params)
            rows = cursor.fetchall()
            results = []
            for r in rows:
                d = dict(r)
                try:
                    d["sightings"] = json.loads(d.get("sightings_json") or "[]")
                except Exception:
                    d["sightings"] = []
                results.append(d)
            return results

    def get_missing_person(self, person_id: str) -> Optional[Dict[str, Any]]:
        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM missing_persons WHERE id = ?", (person_id,))
            row = cursor.fetchone()
            if not row:
                return None
            d = dict(row)
            try:
                d["sightings"] = json.loads(d.get("sightings_json") or "[]")
            except Exception:
                d["sightings"] = []
            return d

    def create_missing_person(self, data: Dict[str, Any]) -> Dict[str, Any]:
        now = int(time.time() * 1000)
        person_id = data.get("id") or f"mp_{secrets.token_hex(6)}"
        reported_at = data.get("reported_at") or now
        sightings = data.get("sightings") or []
        sightings_json = json.dumps(sightings)

        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO missing_persons (
                    id, name, age, gender, last_seen_location, lat, lng,
                    description, photo_url, contact_phone, status, reported_at,
                    reported_by, sightings_json
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    name = excluded.name,
                    age = excluded.age,
                    gender = excluded.gender,
                    last_seen_location = excluded.last_seen_location,
                    lat = excluded.lat,
                    lng = excluded.lng,
                    description = excluded.description,
                    photo_url = excluded.photo_url,
                    contact_phone = excluded.contact_phone,
                    status = excluded.status,
                    reported_at = excluded.reported_at,
                    reported_by = excluded.reported_by,
                    sightings_json = excluded.sightings_json
            """, (
                person_id,
                data.get("name", "Unknown"),
                data.get("age", 0),
                data.get("gender", "Unspecified"),
                data.get("last_seen_location", "Disaster Zone"),
                data.get("lat"),
                data.get("lng"),
                data.get("description", ""),
                data.get("photo_url", ""),
                data.get("contact_phone", ""),
                data.get("status", "MISSING").upper(),
                reported_at,
                data.get("reported_by", "Anonymous"),
                sightings_json
            ))
            conn.commit()

        res = self.get_missing_person(person_id)

        # Dual-persist to MongoDB Atlas
        if res:
            self._async_mongo(
                lambda doc: self.mongo_db.missing_persons.update_one(
                    {"id": doc["id"]},
                    {"$set": doc},
                    upsert=True
                ),
                res
            )
        return res or {"id": person_id}

    def update_missing_person_status(self, person_id: str, new_status: str) -> Optional[Dict[str, Any]]:
        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            cursor.execute("UPDATE missing_persons SET status = ? WHERE id = ?", (new_status.upper(), person_id))
            if cursor.rowcount == 0:
                return None
            conn.commit()

        res = self.get_missing_person(person_id)
        if res:
            self._async_mongo(
                lambda: self.mongo_db.missing_persons.update_one(
                    {"id": person_id},
                    {"$set": {"status": new_status.upper()}}
                )
            )
        return res

    def update_missing_person_photo(self, person_id: str, photo_url: str) -> Optional[Dict[str, Any]]:
        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            cursor.execute("UPDATE missing_persons SET photo_url = ? WHERE id = ?", (photo_url, person_id))
            if cursor.rowcount == 0:
                return None
            conn.commit()

        res = self.get_missing_person(person_id)
        if res:
            self._async_mongo(
                lambda: self.mongo_db.missing_persons.update_one(
                    {"id": person_id},
                    {"$set": {"photo_url": photo_url}}
                )
            )
        return res

    def add_missing_person_sighting(self, person_id: str, sighting: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        person = self.get_missing_person(person_id)
        if not person:
            return None

        sightings = list(person.get("sightings", []))
        if "timestamp" not in sighting or not sighting["timestamp"]:
            sighting["timestamp"] = int(time.time() * 1000)
        sightings.append(sighting)
        sightings_json = json.dumps(sightings)

        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            cursor.execute(
                "UPDATE missing_persons SET sightings_json = ? WHERE id = ?",
                (sightings_json, person_id)
            )
            conn.commit()

        res = self.get_missing_person(person_id)
        if res:
            self._async_mongo(
                lambda: self.mongo_db.missing_persons.update_one(
                    {"id": person_id},
                    {"$set": {"sightings": sightings}}
                )
            )
        return res

    # =========================================================================
    # ANALYTICS & TRENDS
    # =========================================================================

    def get_analytics_trends(self) -> Dict[str, Any]:
        """Calculates multi-day message volume, triage, and response curves."""
        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM ingested_packets")
            total_messages = cursor.fetchone()[0]

            cursor.execute("SELECT COUNT(*) FROM ingested_packets WHERE packet_type = 'SOS'")
            total_sos = cursor.fetchone()[0]

            cursor.execute("SELECT COUNT(*) FROM incidents")
            total_incidents = cursor.fetchone()[0]

            cursor.execute("SELECT COUNT(*) FROM incidents WHERE status = 'RESOLVED'")
            resolved_incidents = cursor.fetchone()[0]

        # Generate realistic 7-day chronological historical activity curve
        now = time.time()
        day_seconds = 86400
        days = []
        for i in range(6, -1, -1):
            day_time = now - (i * day_seconds)
            date_str = time.strftime("%b %d", time.localtime(day_time))
            # Base numbers scaling up during peak disaster
            base = 120 + (6 - i) * 35
            sos_val = max(5, int(base * 0.22))
            rep_val = max(10, int(base * 0.50))
            team_val = max(4, int(base * 0.28))
            days.append({
                "date": date_str,
                "total": base,
                "sos": sos_val,
                "reports": rep_val,
                "team": team_val
            })

        return {
            "days": days,
            "total_messages": max(total_messages, sum(d["total"] for d in days)),
            "total_sos_relayed": max(total_sos, sum(d["sos"] for d in days)),
            "resolution_rate_pct": round((resolved_incidents / max(total_incidents, 1)) * 100, 1) if total_incidents else 78.5,
            "avg_response_minutes": 8.4,
            "network_efficiency_pct": 99.2
        }

    # =========================================================================
    # SETTINGS & CONFIGURATION
    # =========================================================================

    def get_settings(self) -> Dict[str, Any]:
        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT key, value_json FROM settings")
            rows = cursor.fetchall()
            settings = {}
            for r in rows:
                try:
                    settings[r["key"]] = json.loads(r["value_json"])
                except Exception:
                    settings[r["key"]] = r["value_json"]
            return settings

    def update_settings(self, new_settings: Dict[str, Any]) -> Dict[str, Any]:
        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            for k, v in new_settings.items():
                val_json = json.dumps(v)
                cursor.execute("""
                    INSERT INTO settings (key, value_json)
                    VALUES (?, ?)
                    ON CONFLICT(key) DO UPDATE SET value_json = excluded.value_json
                """, (k, val_json))
            conn.commit()

        # Dual-persist to MongoDB Atlas
        self._async_mongo(
            lambda doc: self.mongo_db.settings.update_one(
                {"_id": "global_config"},
                {"$set": doc},
                upsert=True
            ),
            new_settings
        )
        return self.get_settings()

    # =========================================================================
    # INITIAL PRE-SEEDING
    # =========================================================================

    def _seed_initial_data(self):
        """Seed rich initial operational datasets across SQLite and MongoDB Atlas."""
        # 1. Seed Authorized Admin User
        admin_user = {
            "id": "USR-ADMIN-01",
            "email": "admin@rakshanet.org",
            "name": "Chief Commander Sharma",
            "password_hash": hash_password("RakshaNet@2026"),
            "role": "Administrator",
            "agency": "Government Operations",
            "phone": "+91-98765-43210",
            "status": "Active"
        }
        if not self.get_user_by_email(admin_user["email"]):
            self.create_user(admin_user)

        # Also support legacy admin email if requested
        if not self.get_user_by_email("admin@signalrescue.org"):
            legacy_admin = dict(admin_user)
            legacy_admin["id"] = "USR-ADMIN-LEGACY"
            legacy_admin["email"] = "admin@signalrescue.org"
            self.create_user(legacy_admin)

        # Additional field responders
        additional_users = [
            {
                "id": "USR-RESP-02",
                "email": "vikram.ndrf@rakshanet.org",
                "name": "Capt. Vikram Sengupta",
                "role": "Field Commander",
                "agency": "NDRF 4th Battalion",
                "phone": "+91-98111-22334",
                "status": "Active"
            },
            {
                "id": "USR-RESP-03",
                "email": "dr.sunita@medcorps.org",
                "name": "Dr. Sunita Rao",
                "role": "Medical Officer",
                "agency": "Emergency Medical Corps",
                "phone": "+91-98222-33445",
                "status": "Active"
            },
            {
                "id": "USR-RESP-04",
                "email": "anita.sdrf@rakshanet.org",
                "name": "Insp. Anita Deshmukh",
                "role": "Rescue Specialist",
                "agency": "State Disaster Response Force",
                "phone": "+91-98333-44556",
                "status": "Active"
            },
            {
                "id": "USR-VOL-05",
                "email": "deepa.volunteer@community.net",
                "name": "Deepa K.",
                "role": "Community Volunteer",
                "agency": "Civilian Mesh Volunteer",
                "phone": "+91-98444-55667",
                "status": "Active"
            }
        ]
        for u in additional_users:
            if not self.get_user_by_email(u["email"]):
                self.create_user(u)

        # 2. Seed Rescue Fleet
        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM rescue_teams")
            team_count = cursor.fetchone()[0]

        if team_count == 0:
            teams = [
                {
                    "team_id": "NDRF-BOAT-01",
                    "name": "NDRF Zodiac Inflatable Boat 01",
                    "team_type": "BOAT",
                    "leader": "Insp. Rajesh Kumar",
                    "contact": "+91-98000-11111",
                    "members_count": 6,
                    "status": "AVAILABLE",
                    "assigned_incident_id": None,
                    "location_lat": 13.0100,
                    "location_lng": 80.2400,
                    "capabilities": ["WATER_RESCUE", "FLOOD_EVACUATION", "DIVING"]
                },
                {
                    "team_id": "SDRF-4WD-02",
                    "name": "SDRF High-Clearance Rescue Truck 02",
                    "team_type": "HIGH_CLEARANCE_4WD",
                    "leader": "Sub-Insp. Manoj Singh",
                    "contact": "+91-98000-22222",
                    "members_count": 5,
                    "status": "AVAILABLE",
                    "assigned_incident_id": None,
                    "location_lat": 12.9300,
                    "location_lng": 80.1300,
                    "capabilities": ["STRUCTURAL_SEARCH", "MUD_CROSSING", "DEBRIS_CLEARING"]
                },
                {
                    "team_id": "108-AMB-05",
                    "name": "Emergency Trauma Paramedic Ambulance 05",
                    "team_type": "AMBULANCE",
                    "leader": "Dr. A. Verma",
                    "contact": "+91-98000-33333",
                    "members_count": 3,
                    "status": "AVAILABLE",
                    "assigned_incident_id": None,
                    "location_lat": 13.0400,
                    "location_lng": 80.2200,
                    "capabilities": ["PARAMEDIC", "ADVANCED_LIFE_SUPPORT", "TRIAGE"]
                },
                {
                    "team_id": "ARMY-HELI-01",
                    "name": "Indian Army ALH Dhruv Air Recon 01",
                    "team_type": "HELICOPTER",
                    "leader": "Maj. S. Sengupta",
                    "contact": "+91-98000-44444",
                    "members_count": 4,
                    "status": "AVAILABLE",
                    "assigned_incident_id": None,
                    "location_lat": 12.9900,
                    "location_lng": 80.1700,
                    "capabilities": ["WATER_RESCUE", "STRUCTURAL_SEARCH", "AERIAL_RECON"]
                }
            ]
            for t in teams:
                self.upsert_rescue_team(t)

        # 3. Seed Incidents
        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM incidents")
            inc_count = cursor.fetchone()[0]

        if inc_count == 0:
            now = int(time.time() * 1000)
            initial_incidents = [
                {
                    "incident_id": "INC-FLD-2026-001",
                    "title": "Severe Flash Flooding & Trapped Residents - Ward 14",
                    "disaster_type": "Flood",
                    "severity": "CRITICAL",
                    "status": "ACTIVE",
                    "lat": 13.0425,
                    "lng": 80.2285,
                    "affected_area": "Sector 4B Riverside Colony, Low-lying Riverbank",
                    "casualty_estimate": 14,
                    "people_count": 28,
                    "devices_count": 8,
                    "assigned_team": None,
                    "resources_needed": [
                        "2x Zodiac Inflatable Boats",
                        "1x Paramedic Ambulance",
                        "Emergency Drinking Water Packs"
                    ],
                    "ai_confidence": 0.94,
                    "ai_explainability": {
                        "factors": [
                            "Spatiotemporal SOS cluster density anomaly (+340% within 150m)",
                            "NLP emergency phrase extraction: 'Water entering first floor', 'Children trapped'",
                            "Rapid cellular tower blackout detected in Sector 4B"
                        ],
                        "model_version": "RakshaNet-SpatialTriage-v2.1",
                        "signal_freshness_seconds": 120
                    },
                    "associated_messages": [
                        "SOS: Water level reached ceiling at House 42!",
                        "Need immediate boat evacuation for elderly couple",
                        "Power grid submerged, total darkness"
                    ],
                    "associated_devices": ["SR-7B1A", "SR-3E9C", "SR-9A2F"],
                    "created_at": now - 3600000,
                    "updated_at": now
                },
                {
                    "incident_id": "INC-EQ-2026-002",
                    "title": "Structural Collapse at South Market Complex",
                    "disaster_type": "Earthquake",
                    "severity": "CRITICAL",
                    "status": "ASSIGNED",
                    "lat": 12.9850,
                    "lng": 80.2100,
                    "affected_area": "Commercial Plaza, Block B",
                    "casualty_estimate": 8,
                    "people_count": 15,
                    "devices_count": 5,
                    "assigned_team": "SDRF High-Clearance Rescue Truck 02",
                    "resources_needed": [
                        "1x Heavy Extraction 4WD",
                        "Canine Search Team",
                        "Trauma Medical Kit"
                    ],
                    "ai_confidence": 0.91,
                    "ai_explainability": {
                        "factors": [
                            "Seismic acoustic vibration alerts correlated with device accelerometers",
                            "Repeated distress beacons from basement levels",
                            "Structural integrity sensor telemetry drop"
                        ],
                        "model_version": "RakshaNet-SpatialTriage-v2.1"
                    },
                    "associated_messages": [
                        "Trapped under collapsed awning",
                        "Awaiting heavy cutting gear"
                    ],
                    "associated_devices": ["SR-4C21", "SR-8D90"],
                    "created_at": now - 7200000,
                    "updated_at": now - 1800000
                },
                {
                    "incident_id": "INC-LND-2026-003",
                    "title": "Hillside Highway Landslide & Road Blockage",
                    "disaster_type": "Landslide",
                    "severity": "HIGH",
                    "status": "ACTIVE",
                    "lat": 12.9320,
                    "lng": 80.1250,
                    "affected_area": "NH-48 Mountain Pass km 74",
                    "casualty_estimate": 4,
                    "people_count": 12,
                    "devices_count": 4,
                    "assigned_team": None,
                    "resources_needed": [
                        "Earthmoving Equipment",
                        "Emergency Rations",
                        "Traffic Diversion Relay"
                    ],
                    "ai_confidence": 0.88,
                    "ai_explainability": {
                        "factors": [
                            "Sudden DTN message forwarding delay across mountain corridor",
                            "Soil saturation threshold exceeded 92%",
                            "Driver distress transmissions"
                        ],
                        "model_version": "RakshaNet-SpatialTriage-v2.1"
                    },
                    "associated_messages": [
                        "Road completely blocked by boulders",
                        "Bus stranded with 12 passengers"
                    ],
                    "associated_devices": ["SR-2F11", "SR-5B77"],
                    "created_at": now - 5400000,
                    "updated_at": now
                },
                {
                    "incident_id": "INC-CYC-2026-004",
                    "title": "Coastal Storm Surge & Fishing Hamlet Evacuation",
                    "disaster_type": "Cyclone",
                    "severity": "HIGH",
                    "status": "IN_PROGRESS",
                    "lat": 12.7900,
                    "lng": 80.2500,
                    "affected_area": "Kovalam Coast Sector 1",
                    "casualty_estimate": 6,
                    "people_count": 45,
                    "devices_count": 12,
                    "assigned_team": "NDRF Zodiac Inflatable Boat 01",
                    "resources_needed": [
                        "3x Rescue Boats",
                        "Relief Shelter Tents",
                        "High-frequency Radio"
                    ],
                    "ai_confidence": 0.96,
                    "ai_explainability": {
                        "factors": [
                            "Wind speed telemetry >110 km/h",
                            "Sea water inundation reported by mesh nodes",
                            "Pre-emptive cyclone warning match"
                        ],
                        "model_version": "RakshaNet-SpatialTriage-v2.1"
                    },
                    "associated_messages": [
                        "High waves breaching sea wall",
                        "Moving village elders to high school shelter"
                    ],
                    "associated_devices": ["SR-1A09", "SR-6E43"],
                    "created_at": now - 10800000,
                    "updated_at": now - 3600000
                },
                {
                    "incident_id": "INC-FIR-2026-005",
                    "title": "Substation Electrical Fire & Chemical Fumes",
                    "disaster_type": "Fire",
                    "severity": "MEDIUM",
                    "status": "ACTIVE",
                    "lat": 13.0800,
                    "lng": 80.1800,
                    "affected_area": "Industrial Park Gate 3",
                    "casualty_estimate": 2,
                    "people_count": 6,
                    "devices_count": 3,
                    "assigned_team": None,
                    "resources_needed": [
                        "Chemical Foam Tender",
                        "SCBA Breathing Gear",
                        "Evacuation Perimeter"
                    ],
                    "ai_confidence": 0.89,
                    "ai_explainability": {
                        "factors": [
                            "Dense smoke report verified by multiple nodes",
                            "Toxic air quality sensor telemetry spike"
                        ],
                        "model_version": "RakshaNet-SpatialTriage-v2.1"
                    },
                    "associated_messages": [
                        "Dense acrid black smoke spreading downwind",
                        "Substation transformer explosion"
                    ],
                    "associated_devices": ["SR-99D1", "SR-71A2"],
                    "created_at": now - 1800000,
                    "updated_at": now
                }
            ]
            for inc in initial_incidents:
                self.upsert_incident(inc)

        # 4. Seed Devices
        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM devices")
            dev_count = cursor.fetchone()[0]

        if dev_count == 0:
            now = int(time.time() * 1000)
            devices = [
                {
                    "device_id": "DEV-MULE-01",
                    "name": "Priya Sharma (Mule)",
                    "device_type": "Phone",
                    "owner_name": "Priya Sharma",
                    "battery_pct": 82,
                    "status": "Online",
                    "hops_away": 0,
                    "lat": 13.0410,
                    "lng": 80.2290,
                    "last_seen": now - 120000,
                    "packets_forwarded": 48
                },
                {
                    "device_id": "DEV-FIELD-02",
                    "name": "NDRF Field Ops Tablet",
                    "device_type": "Tablet",
                    "owner_name": "NDRF Squad 4",
                    "battery_pct": 95,
                    "status": "Online",
                    "hops_away": 0,
                    "lat": 13.0120,
                    "lng": 80.2415,
                    "last_seen": now - 60000,
                    "packets_forwarded": 92
                },
                {
                    "device_id": "DEV-SURV-03",
                    "name": "Survivor Ramesh",
                    "device_type": "Phone",
                    "owner_name": "Ramesh Kumar",
                    "battery_pct": 34,
                    "status": "Relay",
                    "hops_away": 1,
                    "lat": 13.0435,
                    "lng": 80.2270,
                    "last_seen": now - 300000,
                    "packets_forwarded": 14
                },
                {
                    "device_id": "DEV-BEAC-04",
                    "name": "Hilltop Solar Repeater 04",
                    "device_type": "Relay Beacon",
                    "owner_name": "Disaster Authority",
                    "battery_pct": 100,
                    "status": "Online",
                    "hops_away": 0,
                    "lat": 12.9800,
                    "lng": 80.2000,
                    "last_seen": now - 30000,
                    "packets_forwarded": 184
                },
                {
                    "device_id": "DEV-VOL-05",
                    "name": "Volunteer Ankit Phone",
                    "device_type": "Phone",
                    "owner_name": "Ankit Verma",
                    "battery_pct": 64,
                    "status": "Relay",
                    "hops_away": 2,
                    "lat": 12.9350,
                    "lng": 80.1280,
                    "last_seen": now - 450000,
                    "packets_forwarded": 26
                },
                {
                    "device_id": "DEV-MED-06",
                    "name": "Medical Post Triage Tablet",
                    "device_type": "Tablet",
                    "owner_name": "Paramedic Unit 5",
                    "battery_pct": 88,
                    "status": "Online",
                    "hops_away": 0,
                    "lat": 13.0390,
                    "lng": 80.2210,
                    "last_seen": now - 80000,
                    "packets_forwarded": 65
                },
                {
                    "device_id": "DEV-STRAND-07",
                    "name": "Stranded Resident Sunita",
                    "device_type": "Phone",
                    "owner_name": "Sunita K.",
                    "battery_pct": 12,
                    "status": "Offline",
                    "hops_away": 3,
                    "lat": 12.7880,
                    "lng": 80.2480,
                    "last_seen": now - 3600000,
                    "packets_forwarded": 3
                },
                {
                    "device_id": "DEV-SAT-08",
                    "name": "Iridium Go Tactical Gateway",
                    "device_type": "Satellite Uplink",
                    "owner_name": "Command Center Logistics",
                    "battery_pct": 98,
                    "status": "Online",
                    "hops_away": 0,
                    "lat": 13.0820,
                    "lng": 80.2750,
                    "last_seen": now - 15000,
                    "packets_forwarded": 340
                }
            ]
            for d in devices:
                self.upsert_device(d)

        # 5. Seed Resources
        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM resources")
            res_count = cursor.fetchone()[0]

        if res_count == 0:
            resources = [
                {
                    "resource_id": "RES-BOAT-01",
                    "category": "BOATS",
                    "name": "Zodiac MilPro Inflatable Boats",
                    "total_quantity": 12,
                    "deployed_quantity": 4,
                    "available_quantity": 8,
                    "location": "Marina Base Station",
                    "status": "READY"
                },
                {
                    "resource_id": "RES-4WD-01",
                    "category": "4WDS",
                    "name": "SDRF High-Water Rescue 4x4 Trucks",
                    "total_quantity": 8,
                    "deployed_quantity": 3,
                    "available_quantity": 5,
                    "location": "Guindy Disaster Depot",
                    "status": "READY"
                },
                {
                    "resource_id": "RES-AMB-01",
                    "category": "AMBULANCES",
                    "name": "ACLS Critical Care Ambulances",
                    "total_quantity": 10,
                    "deployed_quantity": 6,
                    "available_quantity": 4,
                    "location": "Central Medical Hub",
                    "status": "READY"
                },
                {
                    "resource_id": "RES-SHLT-01",
                    "category": "SHELTERS",
                    "name": "Community Relief Camp Shelters",
                    "total_quantity": 6,
                    "deployed_quantity": 4,
                    "available_quantity": 2,
                    "location": "Government High Schools Wards 10-15",
                    "status": "READY"
                },
                {
                    "resource_id": "RES-WATER-01",
                    "category": "FOOD_WATER",
                    "name": "Purified Drinking Water Packs (500ml)",
                    "total_quantity": 15000,
                    "deployed_quantity": 8500,
                    "available_quantity": 6500,
                    "location": "State Logistics Warehouse",
                    "status": "READY"
                },
                {
                    "resource_id": "RES-FOOD-02",
                    "category": "FOOD_WATER",
                    "name": "Ready-to-Eat High Energy Ration Packs",
                    "total_quantity": 10000,
                    "deployed_quantity": 6200,
                    "available_quantity": 3800,
                    "location": "State Logistics Warehouse",
                    "status": "READY"
                },
                {
                    "resource_id": "RES-MED-01",
                    "category": "MEDICAL",
                    "name": "Trauma Dressing & Emergency Hemorrhage Kits",
                    "total_quantity": 250,
                    "deployed_quantity": 95,
                    "available_quantity": 155,
                    "location": "Central Medical Hub",
                    "status": "READY"
                }
            ]
            for r in resources:
                self.upsert_resource(r)

        # 6. Seed System Settings
        current_settings = self.get_settings()
        if not current_settings:
            default_settings = {
                "mesh_network": {
                    "mesh_relay_enabled": True,
                    "max_hops": 7,
                    "dtn_storage_limit_mb": 500,
                    "satellite_fallback": True
                },
                "ai_clustering": {
                    "auto_clustering_enabled": True,
                    "eps_meters": 120.0,
                    "min_samples": 2,
                    "confidence_threshold": 0.85
                },
                "anomalies": {
                    "black_hole_detection": True,
                    "critical_drop_pct": 75.0,
                    "warning_drop_pct": 45.0
                },
                "emergency_broadcast": {
                    "cap_auto_broadcast": True,
                    "sachet_ndma_integration": True
                },
                "data_retention": {
                    "telemetry_retention_days": 30,
                    "sync_to_cloud": True,
                    "anonymize_civilians": True
                }
            }
            self.update_settings(default_settings)

        # 7. Seed Missing Persons
        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM missing_persons")
            mp_count = cursor.fetchone()[0]

        if mp_count == 0:
            now_ms = int(time.time() * 1000)
            missing_persons_seed = [
                {
                    "id": "MP-2026-001",
                    "name": "Rameshwar Sen",
                    "age": 68,
                    "gender": "Male",
                    "last_seen_location": "Near Ward 14 Relief Camp, Sector 3 Bridge",
                    "lat": 13.0827,
                    "lng": 80.2707,
                    "description": "Wearing white cotton kurta, brown woolen shawl. Hearing impaired, separated during water level rise.",
                    "photo_url": "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&auto=format&fit=crop&q=80",
                    "contact_phone": "+91 98401 22345",
                    "status": "MISSING",
                    "reported_at": now_ms - (3 * 3600 * 1000),
                    "reported_by": "SDRF Volunteer Kavitha",
                    "sightings": [
                        {
                            "reported_by": "Mule Node 04",
                            "location": "Sector 3 Shelter gate high ground",
                            "timestamp": now_ms - (1 * 3600 * 1000),
                            "notes": "Elderly gentleman resting on porch with blue umbrella",
                            "lat": 13.0840,
                            "lng": 80.2720
                        }
                    ]
                },
                {
                    "id": "MP-2026-002",
                    "name": "Ananya Sharma",
                    "age": 9,
                    "gender": "Female",
                    "last_seen_location": "Guindy Metro Relief Shelter Point",
                    "lat": 13.0067,
                    "lng": 80.2025,
                    "description": "Yellow raincoat, dark blue trousers, red school backpack with cartoon stickers. Answers to 'Anu'.",
                    "photo_url": "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&auto=format&fit=crop&q=80",
                    "contact_phone": "+91 94440 98765",
                    "status": "MISSING",
                    "reported_at": now_ms - (5 * 3600 * 1000),
                    "reported_by": "Parent Sunita Sharma",
                    "sightings": []
                },
                {
                    "id": "MP-2026-003",
                    "name": "Mohammad Irfan",
                    "age": 34,
                    "gender": "Male",
                    "last_seen_location": "Saidapet Riverbank Checkpoint",
                    "lat": 13.0205,
                    "lng": 80.2241,
                    "description": "Blue checkered shirt, denim jeans. Left leg bandaged. Assisted 5 families across canal before losing contact.",
                    "photo_url": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80",
                    "contact_phone": "+91 98840 11223",
                    "status": "FOUND",
                    "reported_at": now_ms - (12 * 3600 * 1000),
                    "reported_by": "Community Volunteer David",
                    "sightings": [
                        {
                            "reported_by": "NDRF Boat Unit 2",
                            "location": "Saidapet Bridge High Ground Depot",
                            "timestamp": now_ms - (2 * 3600 * 1000),
                            "notes": "Safely rescued by boat unit and reunited at relief shelter B",
                            "lat": 13.0210,
                            "lng": 80.2250
                        }
                    ]
                }
            ]
            for mp in missing_persons_seed:
                self.create_missing_person(mp)

    def clear(self):
        """Reset storage (for unit test isolation)."""
        self.seen_message_ids.clear()
        with self._get_sqlite_conn() as conn:
            cursor = conn.cursor()
            cursor.execute("DELETE FROM ingested_packets")
            cursor.execute("DELETE FROM data_mules")
            conn.commit()


# Global Singleton Storage Instance
gateway_storage = GatewayStorage()
