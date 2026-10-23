"""
Export all RakshaNet database tables and collections (SQLite + MongoDB Atlas)
to a comprehensive Excel workbook (.xlsx).
"""

import os
import sqlite3
import json
from pathlib import Path
import pandas as pd
import certifi
import pymongo
from dotenv import load_dotenv

# Load backend environment
load_dotenv(Path(__file__).parent / ".env")

SQLITE_PATH = Path(__file__).parent / os.getenv("LOCAL_SQLITE_PATH", "data/gateway_telemetry.db")
MONGODB_URI = os.getenv("MONGODB_URI")
MONGODB_DB_NAME = os.getenv("MONGODB_DB_NAME", "rakshanet_command_center")

OUTPUT_EXCEL_ROOT = Path(__file__).parent.parent / "rakshanet_database_backup.xlsx"
OUTPUT_EXCEL_DATA = Path(__file__).parent / "data" / "rakshanet_database_backup.xlsx"

def export_all_data():
    print("=" * 70)
    print("RakshaNet - Full Database Export to Excel")
    print("=" * 70)

    # 1. Connect to SQLite
    print(f"Connecting to SQLite: {SQLITE_PATH}...")
    conn = sqlite3.connect(SQLITE_PATH)
    cur = conn.cursor()
    cur.execute("SELECT name FROM sqlite_master WHERE type='table'")
    sqlite_tables = [t[0] for t in cur.fetchall()]
    print(f"Found SQLite tables: {sqlite_tables}")

    sqlite_data = {}
    for table in sqlite_tables:
        df = pd.read_sql_query(f"SELECT * FROM {table}", conn)
        sqlite_data[table] = df
        print(f"  - Table '{table}': {len(df)} rows")

    # 2. Connect to MongoDB Atlas
    mongo_data = {}
    if MONGODB_URI:
        try:
            print(f"\nConnecting to MongoDB Atlas ({MONGODB_DB_NAME})...")
            client = pymongo.MongoClient(
                MONGODB_URI,
                tlsCAFile=certifi.where(),
                serverSelectionTimeoutMS=5000
            )
            client.admin.command("ping")
            db = client[MONGODB_DB_NAME]
            collections = db.list_collection_names()
            print(f"Connected! Found MongoDB collections: {collections}")

            for coll_name in collections:
                docs = list(db[coll_name].find())
                # Clean MongoDB _id to string for clean serialization
                for doc in docs:
                    if "_id" in doc:
                        doc["_id"] = str(doc["_id"])
                    # Convert dict/list fields to JSON string for readable excel cells
                    for k, v in doc.items():
                        if isinstance(v, (dict, list)):
                            doc[k] = json.dumps(v, ensure_ascii=False)
                mongo_data[coll_name] = pd.DataFrame(docs)
                print(f"  - Collection '{coll_name}': {len(docs)} documents")
        except Exception as e:
            print(f"Warning: Could not connect to MongoDB Atlas: {e}")

    # 3. Consolidate and Merge Data into Clean Sheets
    print("\nConsolidating datasets into Excel sheets...")
    excel_sheets = {}

    # Sheet: Users
    users_df = sqlite_data.get("users", pd.DataFrame())
    if "users" in mongo_data and not mongo_data["users"].empty:
        # Combine or fallback
        m_users = mongo_data["users"]
        if not users_df.empty:
            # Union by id/email
            combined = pd.concat([users_df, m_users]).drop_duplicates(subset=["email"]).reset_index(drop=True)
            excel_sheets["Users"] = combined
        else:
            excel_sheets["Users"] = m_users
    else:
        excel_sheets["Users"] = users_df

    # Sheet: Incidents
    incidents_df = sqlite_data.get("incidents", pd.DataFrame())
    if "incidents" in mongo_data and not mongo_data["incidents"].empty:
        m_incidents = mongo_data["incidents"]
        id_col = "incident_id" if "incident_id" in incidents_df.columns else "id"
        m_id_col = "incident_id" if "incident_id" in m_incidents.columns else "id"
        combined = pd.concat([incidents_df, m_incidents]).drop_duplicates(subset=[id_col]).reset_index(drop=True)
        excel_sheets["Incidents"] = combined
    else:
        excel_sheets["Incidents"] = incidents_df

    # Sheet: Devices
    devices_df = sqlite_data.get("devices", pd.DataFrame())
    if "devices" in mongo_data and not mongo_data["devices"].empty:
        m_devices = mongo_data["devices"]
        combined = pd.concat([devices_df, m_devices]).drop_duplicates(subset=["device_id"]).reset_index(drop=True)
        excel_sheets["Devices"] = combined
    else:
        excel_sheets["Devices"] = devices_df

    # Sheet: Missing Persons
    mp_df = sqlite_data.get("missing_persons", pd.DataFrame())
    if "missing_persons" in mongo_data and not mongo_data["missing_persons"].empty:
        m_mp = mongo_data["missing_persons"]
        combined = pd.concat([mp_df, m_mp]).drop_duplicates(subset=["id"]).reset_index(drop=True)
        excel_sheets["Missing_Persons"] = combined
    else:
        excel_sheets["Missing_Persons"] = mp_df

    # Sheet: Rescue Teams
    teams_df = sqlite_data.get("rescue_teams", pd.DataFrame())
    if "rescue_teams" in mongo_data and not mongo_data["rescue_teams"].empty:
        m_teams = mongo_data["rescue_teams"]
        combined = pd.concat([teams_df, m_teams]).drop_duplicates(subset=["team_id"]).reset_index(drop=True)
        excel_sheets["Rescue_Teams"] = combined
    else:
        excel_sheets["Rescue_Teams"] = teams_df

    # Sheet: Resources
    res_df = sqlite_data.get("resources", pd.DataFrame())
    if "resources" in mongo_data and not mongo_data["resources"].empty:
        m_res = mongo_data["resources"]
        combined = pd.concat([res_df, m_res]).drop_duplicates(subset=["resource_id"]).reset_index(drop=True)
        excel_sheets["Resources"] = combined
    else:
        excel_sheets["Resources"] = res_df

    # Sheet: Ingested Packets / Telemetry
    packets_df = sqlite_data.get("ingested_packets", pd.DataFrame())
    if "packets" in mongo_data and not mongo_data["packets"].empty:
        excel_sheets["Packets"] = mongo_data["packets"]
    elif not packets_df.empty:
        excel_sheets["Packets"] = packets_df
    else:
        excel_sheets["Packets"] = pd.DataFrame()

    # Sheet: Data Mules
    if "data_mules" in sqlite_data:
        excel_sheets["Data_Mules"] = sqlite_data["data_mules"]

    # Sheet: Settings
    if "settings" in sqlite_data:
        excel_sheets["Settings"] = sqlite_data["settings"]
    elif "settings" in mongo_data:
        excel_sheets["Settings"] = mongo_data["settings"]

    # 4. Save to Excel Files
    OUTPUT_EXCEL_ROOT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_EXCEL_DATA.parent.mkdir(parents=True, exist_ok=True)

    for target_path in [OUTPUT_EXCEL_ROOT, OUTPUT_EXCEL_DATA]:
        with pd.ExcelWriter(target_path, engine="openpyxl") as writer:
            for sheet_name, df in excel_sheets.items():
                # Clean sheet name (max 31 chars in Excel)
                clean_name = sheet_name[:31]
                df.to_excel(writer, sheet_name=clean_name, index=False)
        print(f"Exported Excel file successfully: {target_path} ({os.path.getsize(target_path):,} bytes)")

    print("\nSummary of Exported Sheets:")
    for s_name, s_df in excel_sheets.items():
        print(f"  • {s_name}: {len(s_df)} rows, {len(s_df.columns)} columns")
    print("=" * 70)

if __name__ == "__main__":
    export_all_data()
