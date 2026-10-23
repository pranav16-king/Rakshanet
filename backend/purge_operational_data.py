"""
Purge all operational data from RakshaNet database (SQLite + MongoDB Atlas)
while retaining user accounts and credentials (id and password hash).
All purged data is permanently preserved in rakshanet_database_backup.xlsx.
"""

import os
import sqlite3
from pathlib import Path
import certifi
import pymongo
from dotenv import load_dotenv

# Load backend environment
load_dotenv(Path(__file__).parent / ".env")

SQLITE_PATH = Path(__file__).parent / os.getenv("LOCAL_SQLITE_PATH", "data/gateway_telemetry.db")
MONGODB_URI = os.getenv("MONGODB_URI")
MONGODB_DB_NAME = os.getenv("MONGODB_DB_NAME", "rakshanet_command_center")
BACKUP_FILE = Path(__file__).parent.parent / "rakshanet_database_backup.xlsx"

OPERATIONAL_SQLITE_TABLES = [
    "incidents",
    "devices",
    "missing_persons",
    "resources",
    "rescue_teams",
    "ingested_packets",
    "data_mules",
]

OPERATIONAL_MONGO_COLLECTIONS = [
    "incidents",
    "devices",
    "missing_persons",
    "resources",
    "rescue_teams",
    "packets",
    "test_collection",
]

def purge_database():
    print("=" * 70)
    print("RakshaNet Database Operational Data Purge")
    print("=" * 70)

    # Safety check: Verify backup exists
    if not BACKUP_FILE.exists() or BACKUP_FILE.stat().st_size < 10000:
        raise RuntimeError(f"ABORT: Backup file {BACKUP_FILE} missing or too small! Cannot proceed.")
    print(f"[SAFEGUARD] Verified backup file: {BACKUP_FILE} ({BACKUP_FILE.stat().st_size:,} bytes)")

    # 1. Purge SQLite Tables
    print(f"\n[1/3] Purging Local SQLite: {SQLITE_PATH}...")
    conn = sqlite3.connect(SQLITE_PATH)
    cur = conn.cursor()

    for table in OPERATIONAL_SQLITE_TABLES:
        cur.execute(f"SELECT COUNT(*) FROM {table}")
        count_before = cur.fetchone()[0]
        cur.execute(f"DELETE FROM {table}")
        print(f"  - Deleted {count_before} rows from table '{table}'")

    # Clear extraneous user metadata, retain credentials and auth fields
    cur.execute("SELECT COUNT(*) FROM users")
    user_count = cur.fetchone()[0]
    cur.execute("UPDATE users SET phone = NULL, location = NULL, last_active = NULL")
    print(f"  - Retained {user_count} user accounts (id, email, password_hash, role, agency) in 'users'")

    conn.commit()
    cur.execute("VACUUM")
    conn.close()
    print("  [OK] SQLite operational tables cleared and database vacuumed.")

    # 2. Purge MongoDB Atlas Collections
    print(f"\n[2/3] Purging MongoDB Atlas ({MONGODB_DB_NAME})...")
    if MONGODB_URI:
        try:
            client = pymongo.MongoClient(
                MONGODB_URI,
                tlsCAFile=certifi.where(),
                serverSelectionTimeoutMS=8000
            )
            client.admin.command("ping")
            db = client[MONGODB_DB_NAME]

            for coll in OPERATIONAL_MONGO_COLLECTIONS:
                if coll in db.list_collection_names():
                    res = db[coll].delete_many({})
                    print(f"  - Deleted {res.deleted_count} documents from collection '{coll}'")
                else:
                    print(f"  - Collection '{coll}' does not exist (already empty)")

            # Retain user credentials in MongoDB
            if "users" in db.list_collection_names():
                mongo_users_count = db.users.count_documents({})
                db.users.update_many({}, {"$unset": {"phone": "", "location": "", "last_active": "", "sightings": ""}})
                print(f"  - Retained {mongo_users_count} user accounts in MongoDB 'users'")

            print("  [OK] MongoDB Atlas operational collections purged.")
        except Exception as e:
            print(f"  [ERROR] MongoDB Atlas purge failed: {e}")
            raise
    else:
        print("  - Skipped MongoDB (No URI provided)")

    # 3. Post-Purge Verification
    print("\n[3/3] Post-Purge Verification...")
    conn = sqlite3.connect(SQLITE_PATH)
    cur = conn.cursor()
    print("SQLite Table Status:")
    for t in OPERATIONAL_SQLITE_TABLES:
        cur.execute(f"SELECT COUNT(*) FROM {t}")
        cnt = cur.fetchone()[0]
        assert cnt == 0, f"Table {t} should have 0 rows, found {cnt}!"
        print(f"  • {t}: {cnt} rows")

    cur.execute("SELECT COUNT(*), COUNT(id), COUNT(password_hash), COUNT(email) FROM users")
    u_row = cur.fetchone()
    print(f"  • users: {u_row[0]} accounts (IDs: {u_row[1]}, Passwords: {u_row[2]}, Emails: {u_row[3]})")
    assert u_row[0] > 0, "Users table should have user accounts!"
    assert u_row[0] == u_row[2], "All users must have password hashes!"
    conn.close()

    if MONGODB_URI:
        client = pymongo.MongoClient(MONGODB_URI, tlsCAFile=certifi.where())
        db = client[MONGODB_DB_NAME]
        print("\nMongoDB Atlas Collection Status:")
        for c in OPERATIONAL_MONGO_COLLECTIONS:
            doc_cnt = db[c].count_documents({})
            assert doc_cnt == 0, f"Collection {c} should have 0 docs, found {doc_cnt}!"
            print(f"  • {c}: {doc_cnt} docs")
        m_users_cnt = db.users.count_documents({})
        print(f"  • users: {m_users_cnt} user accounts")
        assert m_users_cnt > 0, "Users collection should have documents!"

    print("\n" + "=" * 70)
    print("SUCCESS: All operational data deleted. User accounts (id & pass) retained.")
    print(f"Backup verified at: {BACKUP_FILE}")
    print("=" * 70)

if __name__ == "__main__":
    purge_database()
