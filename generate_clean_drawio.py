import xml.etree.ElementTree as ET

def create_drawio():
    mxfile = ET.Element('mxfile', {
        'host': 'app.diagrams.net',
        'modified': '2026-10-02T13:40:00.000Z',
        'agent': 'Antigravity Clean Wireframe Architect',
        'version': '24.7.17',
        'type': 'device'
    })
    return mxfile

def add_diagram(mxfile, diag_id, name, width=2000, height=1300, bg="#0B1220"):
    diag = ET.SubElement(mxfile, 'diagram', {'id': diag_id, 'name': name})
    model = ET.SubElement(diag, 'mxGraphModel', {
        'dx': '1600', 'dy': '1000', 'grid': '1', 'gridSize': '10',
        'guides': '1', 'tooltips': '1', 'connect': '1', 'arrows': '1',
        'fold': '1', 'page': '1', 'pageScale': '1',
        'pageWidth': str(width), 'pageHeight': str(height),
        'background': bg, 'math': '0', 'shadow': '0'
    })
    root = ET.SubElement(model, 'root')
    ET.SubElement(root, 'mxCell', {'id': '0'})
    ET.SubElement(root, 'mxCell', {'id': '1', 'parent': '0'})
    return root

def node(root, nid, val, style, x, y, w, h, parent="1"):
    if "html=1;" not in style:
        style = "html=1;" + style
    if "whiteSpace=wrap;" not in style:
        style = "whiteSpace=wrap;" + style
    if "overflow=hidden;" not in style:
        style = "overflow=hidden;" + style
    c = ET.SubElement(root, 'mxCell', {
        'id': nid, 'value': val, 'style': style, 'vertex': '1', 'parent': parent
    })
    ET.SubElement(c, 'mxGeometry', {
        'x': str(x), 'y': str(y), 'width': str(w), 'height': str(h), 'as': 'geometry'
    })
    return c

def edge(root, eid, val, style, src, tgt, parent="1", points=None):
    if "html=1;" not in style:
        style = "html=1;" + style
    if "whiteSpace=wrap;" not in style:
        style = "whiteSpace=wrap;" + style
    e = ET.SubElement(root, 'mxCell', {
        'id': eid, 'value': val, 'style': style, 'edge': '1', 'parent': parent,
        'source': src, 'target': tgt
    })
    geo = ET.SubElement(e, 'mxGeometry', {'relative': '1', 'as': 'geometry'})
    if points:
        pts = ET.SubElement(geo, 'Array', {'as': 'points'})
        for px, py in points:
            ET.SubElement(pts, 'mxPoint', {'x': str(px), 'y': str(py)})
    return e

def build_tab1_er_architecture(mxfile):
    """Tab 1: Software Architecture & Database ER Diagram (Clean, Spacious, Wireframe Style)"""
    root = add_diagram(mxfile, "tab1_er_arch", "01 - Software Architecture & ER Diagram", 2200, 1400)

    # Title Banner
    node(root, "t1_title",
         "<b>RAKSHANET (SIGNALRESCUE AI) — SOFTWARE ARCHITECTURE & DATABASE ER DIAGRAM</b><br/>"
         "<span style='font-size:12px;color:#9FADC2;'>Clean Layered Component Stack • Entity-Relationship Model • Reactive Providers • Zero Demo Data</span>",
         "rounded=1;fillColor=#162036;strokeColor=#FFD21F;strokeWidth=2;fontColor=#FFD21F;fontSize=18;align=center;verticalAlign=middle;",
         50, 30, 2100, 65)

    # ==================== LAYER 1: UI PRESENTATION LAYER ====================
    node(root, "grp_ui", "<b>LAYER 1: PRESENTATION &amp; SCREENS (FLUTTER)</b>",
         "rounded=1;fillColor=#0E1627;strokeColor=#3A4C70;strokeWidth=1;fontColor=#FFD21F;fontSize=13;align=left;spacingLeft=15;verticalAlign=top;spacingTop=10;",
         50, 120, 2100, 130)

    screens = [
        ("ui_splash", "1. Splash &amp; Gate", "Check isRegistered"),
        ("ui_onboard", "2. Onboarding", "4 Value Cards"),
        ("ui_gate", "2b. Profile Gate*", "Name, Blood, Phone"),
        ("ui_home", "3. SOS Home", "Circular 3s Hold"),
        ("ui_report", "4. Emergency Report", "6 Threat Badges"),
        ("ui_chat", "5. Offline Chat", "Channels &amp; Ticks"),
        ("ui_map", "6. Live Map", "Vector Mesh Radar"),
        ("ui_ai", "7. AI Assistant", "Offline Q&amp;A"),
        ("ui_missing", "8. Missing Person", "Photos &amp; Traits"),
        ("ui_shelter", "9. Shelters", "Capacity &amp; Food"),
        ("ui_outbox", "10. My Messages", "Pending Outbox"),
        ("ui_tools", "11. Safety Tools", "2x3 Grid"),
        ("ui_settings", "12. Settings", "OLED #000000"),
        ("ui_profile", "13. Profile &amp; KPIs", "Impact Metrics"),
    ]
    sw = 135
    for idx, (sid, sname, ssub) in enumerate(screens):
        node(root, sid,
             f"<b>{sname}</b><br/><span style='font-size:9px;color:#9FADC2;'>{ssub}</span>",
             "rounded=1;fillColor=#162036;strokeColor=#FFD21F;fontColor=#EEF2F8;fontSize=10;align=center;",
             70 + idx * 148, 160, sw, 65)

    # ==================== LAYER 2: STATE MANAGEMENT PROVIDERS ====================
    node(root, "grp_state", "<b>LAYER 2: STATE MANAGEMENT &amp; REACTIVE CONTROLLERS (PROVIDER / CHANGENOTIFIER)</b>",
         "rounded=1;fillColor=#0E1627;strokeColor=#3A4C70;strokeWidth=1;fontColor=#3CC6D0;fontSize=13;align=left;spacingLeft=15;verticalAlign=top;spacingTop=10;",
         50, 275, 2100, 135)

    providers = [
        ("p_prof", "ProfileProvider", "Registration Gate<br/>Anonymous ID `SR-XXXX`"),
        ("p_theme", "ThemeProvider", "Navy (#0B1220)<br/>True OLED (#000000)"),
        ("p_mesh", "MeshProvider", "BLE Peer Discovery<br/>Live Signal Telemetry"),
        ("p_chat", "ChatProvider", "Conversations &amp; Outbox<br/>Real-time Status Ticks"),
        ("p_emer", "EmergencyProvider", "Active SOS Beacons<br/>Incident Dispatch"),
        ("p_tele", "TelemetryProvider", "Battery Monitoring<br/>GPS Availability"),
    ]
    for idx, (pid, pname, psub) in enumerate(providers):
        node(root, pid,
             f"<b style='font-size:12px;color:#3CC6D0;'>{pname}</b><br/><span style='font-size:10px;color:#EEF2F8;'>{psub}</span>",
             "rounded=1;fillColor=#162036;strokeColor=#3CC6D0;strokeWidth=2;fontColor=#EEF2F8;align=center;",
             70 + idx * 345, 315, 325, 75)

    # Connections UI -> Providers
    edge(root, "e_ui_prof", "reads/writes", "strokeColor=#3CC6D0;strokeWidth=1.5;dashed=1;", "ui_gate", "p_prof")
    edge(root, "e_ui_home", "consumes", "strokeColor=#3CC6D0;strokeWidth=1.5;dashed=1;", "ui_home", "p_mesh")
    edge(root, "e_ui_chat", "streams", "strokeColor=#3CC6D0;strokeWidth=1.5;dashed=1;", "ui_chat", "p_chat")

    # ==================== LAYER 3: DOMAIN SERVICES & DTN ENGINE ====================
    node(root, "grp_services", "<b>LAYER 3: DOMAIN SERVICES &amp; DTN PROTOCOL ENGINE (KABOOTAR / MESHCHAT PATTERN)</b>",
         "rounded=1;fillColor=#0E1627;strokeColor=#3A4C70;strokeWidth=1;fontColor=#FF5A4E;fontSize=13;align=left;spacingLeft=15;verticalAlign=top;spacingTop=10;",
         50, 435, 2100, 150)

    services = [
        ("s_chatsvc", "ChatService", "Save-Before-Send Guarantee<br/>Persists to SQLite before radio emit"),
        ("s_mesh", "MeshEngine", "Epidemic Store-and-Forward<br/>Bloom Filter Deduplication<br/>TTL Hop Decay &amp; Loop Guard"),
        ("s_ai", "AIAssistantService", "Deterministic Offline Triage<br/>Rules Knowledge Base (Water, First Aid)"),
        ("s_loc", "LocationService", "Device GPS &amp; Dead-Reckoning<br/>No hardcoded coordinates"),
        ("s_tele", "TelemetryService", "Battery-Aware Radio Duty Cycle<br/>Power Savings Manager"),
    ]
    for idx, (sid, sname, ssub) in enumerate(services):
        node(root, sid,
             f"<b style='font-size:13px;color:#FF5A4E;'>{sname}</b><br/><span style='font-size:10px;color:#EEF2F8;'>{ssub}</span>",
             "rounded=1;fillColor=#162036;strokeColor=#FF5A4E;strokeWidth=2;fontColor=#EEF2F8;align=center;",
             70 + idx * 415, 475, 395, 85)

    # Connections Provider -> Services
    edge(root, "e_p_chat_svc", "delegates", "strokeColor=#FF5A4E;strokeWidth=1.5;", "p_chat", "s_chatsvc")
    edge(root, "e_chat_mesh", "enqueues", "strokeColor=#FF5A4E;strokeWidth=1.5;", "s_chatsvc", "s_mesh")

    # ==================== LAYER 4: DATABASE ER DIAGRAM (SQLITE - app_database.db) ====================
    node(root, "grp_db", "<b>LAYER 4: DATABASE ENTITY-RELATIONSHIP (ER) MODEL (SQLITE - app_database.db)</b>",
         "rounded=1;fillColor=#0E1627;strokeColor=#3A4C70;strokeWidth=1;fontColor=#4CD08A;fontSize=13;align=left;spacingLeft=15;verticalAlign=top;spacingTop=10;",
         50, 610, 2100, 480)

    # ER Entities (clean tabular cards with PK, FK, Types)
    # 1. user_profile
    node(root, "er_user",
         "<b style='font-size:13px;color:#4CD08A;'>user_profile</b><hr/>"
         "<div style='text-align:left;font-size:11px;font-family:monospace;'>"
         "<b>PK</b> id : TEXT<br/>"
         "&nbsp;&nbsp;&nbsp;name : TEXT<br/>"
         "&nbsp;&nbsp;&nbsp;device_id : TEXT (SR-XXXX)<br/>"
         "&nbsp;&nbsp;&nbsp;blood_group : TEXT<br/>"
         "&nbsp;&nbsp;&nbsp;emergency_contact : TEXT<br/>"
         "&nbsp;&nbsp;&nbsp;language : TEXT<br/>"
         "&nbsp;&nbsp;&nbsp;is_registered : INTEGER<br/>"
         "&nbsp;&nbsp;&nbsp;people_helped : INTEGER<br/>"
         "&nbsp;&nbsp;&nbsp;messages_relayed : INTEGER<br/>"
         "&nbsp;&nbsp;&nbsp;created_at : INTEGER"
         "</div>",
         "rounded=1;fillColor=#162036;strokeColor=#4CD08A;strokeWidth=2;fontColor=#EEF2F8;align=center;verticalAlign=top;spacingTop=8;",
         70, 660, 310, 230)

    # 2. messages & outbox
    node(root, "er_msg",
         "<b style='font-size:13px;color:#4CD08A;'>messages</b><hr/>"
         "<div style='text-align:left;font-size:11px;font-family:monospace;'>"
         "<b>PK</b> message_id : TEXT (UUID)<br/>"
         "<b>FK</b> conversation_id : TEXT<br/>"
         "<b>FK</b> sender_id : TEXT<br/>"
         "&nbsp;&nbsp;&nbsp;sender_name : TEXT<br/>"
         "&nbsp;&nbsp;&nbsp;content : TEXT<br/>"
         "&nbsp;&nbsp;&nbsp;timestamp : INTEGER<br/>"
         "&nbsp;&nbsp;&nbsp;status : TEXT (SAVED/RELAYED)<br/>"
         "&nbsp;&nbsp;&nbsp;hop_count : INTEGER<br/>"
         "&nbsp;&nbsp;&nbsp;ttl : INTEGER (default 5)<br/>"
         "&nbsp;&nbsp;&nbsp;latitude : REAL<br/>"
         "&nbsp;&nbsp;&nbsp;longitude : REAL"
         "</div>",
         "rounded=1;fillColor=#162036;strokeColor=#4CD08A;strokeWidth=2;fontColor=#EEF2F8;align=center;verticalAlign=top;spacingTop=8;",
         420, 660, 330, 230)

    # 3. nearby_devices
    node(root, "er_dev",
         "<b style='font-size:13px;color:#4CD08A;'>nearby_devices</b><hr/>"
         "<div style='text-align:left;font-size:11px;font-family:monospace;'>"
         "<b>PK</b> device_id : TEXT<br/>"
         "&nbsp;&nbsp;&nbsp;display_name : TEXT<br/>"
         "&nbsp;&nbsp;&nbsp;connection_type : TEXT<br/>"
         "&nbsp;&nbsp;&nbsp;rssi : INTEGER<br/>"
         "&nbsp;&nbsp;&nbsp;proximity_band : TEXT<br/>"
         "&nbsp;&nbsp;&nbsp;is_connected : INTEGER<br/>"
         "&nbsp;&nbsp;&nbsp;hop_count : INTEGER<br/>"
         "&nbsp;&nbsp;&nbsp;battery_level : INTEGER<br/>"
         "&nbsp;&nbsp;&nbsp;last_seen : INTEGER"
         "</div>",
         "rounded=1;fillColor=#162036;strokeColor=#4CD08A;strokeWidth=2;fontColor=#EEF2F8;align=center;verticalAlign=top;spacingTop=8;",
         790, 660, 300, 230)

    # 4. emergency_reports
    node(root, "er_rep",
         "<b style='font-size:13px;color:#FF5A4E;'>emergency_reports</b><hr/>"
         "<div style='text-align:left;font-size:11px;font-family:monospace;'>"
         "<b>PK</b> id : TEXT (UUID)<br/>"
         "&nbsp;&nbsp;&nbsp;type : TEXT (Medical/Trapped...)<br/>"
         "&nbsp;&nbsp;&nbsp;people_affected : INTEGER<br/>"
         "&nbsp;&nbsp;&nbsp;description : TEXT<br/>"
         "&nbsp;&nbsp;&nbsp;status : TEXT (QUEUED/SYNCED)<br/>"
         "&nbsp;&nbsp;&nbsp;timestamp : INTEGER<br/>"
         "&nbsp;&nbsp;&nbsp;latitude : REAL<br/>"
         "&nbsp;&nbsp;&nbsp;longitude : REAL<br/>"
         "&nbsp;&nbsp;&nbsp;severity : TEXT (P1-CRITICAL)"
         "</div>",
         "rounded=1;fillColor=#162036;strokeColor=#FF5A4E;strokeWidth=2;fontColor=#EEF2F8;align=center;verticalAlign=top;spacingTop=8;",
         1130, 660, 300, 230)

    # 5. shelters
    node(root, "er_shel",
         "<b style='font-size:13px;color:#3CC6D0;'>shelters</b><hr/>"
         "<div style='text-align:left;font-size:11px;font-family:monospace;'>"
         "<b>PK</b> id : TEXT<br/>"
         "&nbsp;&nbsp;&nbsp;name : TEXT<br/>"
         "&nbsp;&nbsp;&nbsp;distance_meters : REAL<br/>"
         "&nbsp;&nbsp;&nbsp;capacity : INTEGER<br/>"
         "&nbsp;&nbsp;&nbsp;occupancy : INTEGER<br/>"
         "&nbsp;&nbsp;&nbsp;has_food : INTEGER<br/>"
         "&nbsp;&nbsp;&nbsp;has_water : INTEGER<br/>"
         "&nbsp;&nbsp;&nbsp;has_medical : INTEGER<br/>"
         "&nbsp;&nbsp;&nbsp;is_open : INTEGER"
         "</div>",
         "rounded=1;fillColor=#162036;strokeColor=#3CC6D0;strokeWidth=2;fontColor=#EEF2F8;align=center;verticalAlign=top;spacingTop=8;",
         1470, 660, 300, 230)

    # 6. missing_persons
    node(root, "er_miss",
         "<b style='font-size:13px;color:#FFD21F;'>missing_persons</b><hr/>"
         "<div style='text-align:left;font-size:11px;font-family:monospace;'>"
         "<b>PK</b> id : TEXT<br/>"
         "&nbsp;&nbsp;&nbsp;name : TEXT<br/>"
         "&nbsp;&nbsp;&nbsp;age : INTEGER<br/>"
         "&nbsp;&nbsp;&nbsp;description : TEXT<br/>"
         "&nbsp;&nbsp;&nbsp;last_seen_location : TEXT<br/>"
         "&nbsp;&nbsp;&nbsp;last_seen_time : TEXT<br/>"
         "&nbsp;&nbsp;&nbsp;photo_path : TEXT<br/>"
         "&nbsp;&nbsp;&nbsp;status : TEXT (SEARCHING/FOUND)"
         "</div>",
         "rounded=1;fillColor=#162036;strokeColor=#FFD21F;strokeWidth=2;fontColor=#EEF2F8;align=center;verticalAlign=top;spacingTop=8;",
         1810, 660, 300, 230)

    # ER Relational Lines (1:N, N:M)
    edge(root, "er_rel_user_msg", "1:N (Author)", "strokeColor=#4CD08A;strokeWidth=2;", "er_user", "er_msg")
    edge(root, "er_rel_dev_msg", "1:N (Relayed via)", "strokeColor=#3CC6D0;strokeWidth=2;", "er_dev", "er_msg")
    edge(root, "er_rel_user_rep", "1:N (Filed by)", "strokeColor=#FF5A4E;strokeWidth=2;", "er_user", "er_rep")

    # DAOs / Repositories Bar
    node(root, "daos_box",
         "<b>DATABASE REPOSITORIES:</b> "
         "&nbsp;&nbsp;• ProfileRepository "
         "&nbsp;&nbsp;• ChatRepository "
         "&nbsp;&nbsp;• DeviceRepository "
         "&nbsp;&nbsp;• ReportRepository "
         "&nbsp;&nbsp;• ShelterRepository "
         "&nbsp;&nbsp;• MissingPersonRepository",
         "rounded=1;fillColor=#162036;strokeColor=#4CD08A;fontColor=#EEF2F8;fontSize=11;align=center;",
         70, 930, 2040, 40)

    # Connections Service -> DB
    edge(root, "e_svc_db", "commits (Save-Before-Send)", "strokeColor=#4CD08A;strokeWidth=2;", "s_chatsvc", "er_msg")
    edge(root, "e_mesh_db", "dedup query & audit", "strokeColor=#4CD08A;strokeWidth=2;", "s_mesh", "daos_box")

    # ==================== LAYER 5: HARDWARE & TRANSCEIVERS ====================
    node(root, "grp_hw", "<b>LAYER 5: HARDWARE ABSTRACTION LAYER (HAL) &amp; RADIO TRANSCEIVERS</b>",
         "rounded=1;fillColor=#0E1627;strokeColor=#3A4C70;strokeWidth=1;fontColor=#FFA033;fontSize=13;align=left;spacingLeft=15;verticalAlign=top;spacingTop=10;",
         50, 1110, 2100, 130)

    hw_items = [
        ("hw_ble_adv", "BLE GATT Server", "Advertising Mode (200ms)<br/>Service UUID: 0xFD6F / Raksha"),
        ("hw_ble_scan", "BLE GATT Client", "Continuous Central Scanner<br/>RSSI &amp; Proximity Banding"),
        ("hw_wifi", "Wi-Fi Direct / Nearby", "High-Bandwidth P2P Transport<br/>Large Payload &amp; Media Chunks"),
        ("hw_oled", "OLED Display Controller", "AMOLED Subpixel Shutdown<br/>True #000000 (62% Battery Saved)"),
        ("hw_gps", "Location Sensor API", "Real Device GPS / Dead-Reckoning<br/>Permission-Aware Graceful Fallback"),
    ]
    for idx, (hid, hname, hsub) in enumerate(hw_items):
        node(root, hid,
             f"<b style='font-size:12px;color:#FFA033;'>{hname}</b><br/><span style='font-size:10px;color:#EEF2F8;'>{hsub}</span>",
             "rounded=1;fillColor=#162036;strokeColor=#FFA033;strokeWidth=2;fontColor=#EEF2F8;align=center;",
             70 + idx * 415, 1150, 395, 75)

    edge(root, "e_mesh_hw", "radio emit/listen", "strokeColor=#FFA033;strokeWidth=2;", "s_mesh", "hw_ble_adv")

def build_tab2_dtn_protocol(mxfile):
    """Tab 2: DTN Mesh Protocol & 4-Phone Relay Flowchart"""
    root = add_diagram(mxfile, "tab2_dtn", "02 - DTN Mesh Protocol & Relay Sequence", 2000, 1200)

    node(root, "t2_title",
         "<b>DELAY-TOLERANT NETWORKING (DTN) PROTOCOL &amp; 4-PHONE 3-HOP SIMULATION</b><br/>"
         "<span style='font-size:12px;color:#9FADC2;'>Kabootar / MeshChat Pattern • Save-Before-Send • Bloom Filter Deduplication • TTL Decay Guard</span>",
         "rounded=1;fillColor=#162036;strokeColor=#FFD21F;strokeWidth=2;fontColor=#FFD21F;fontSize=18;align=center;verticalAlign=middle;",
         50, 30, 1900, 65)

    # 4 Phones Flowchart
    phones = [
        ("ph_a", "PHONE A (Origin / Victim)", "Trapped survivor (No Internet)<br/><b>Creates SOS: MSG-001</b><br/>Commits to SQLite: status='SAVED'<br/><span style='color:#FFD21F;'>TTL: 5 | Hop Count: 0</span>", "#FF5A4E", 80),
        ("ph_b", "PHONE B (Pedestrian Relay)", "Pedestrian moves physically<br/><b>Bloom Filter Dedup: Pass</b><br/>Store-and-forward into SQLite<br/><span style='color:#FFD21F;'>TTL: 4 | Hop Count: 1</span>", "#3CC6D0", 550),
        ("ph_c", "PHONE C (Shelter Node)", "Relief camp volunteer device<br/><b>Renders SOS in Chat Screen</b><br/>Relays to outbound emergency vehicles<br/><span style='color:#FFD21F;'>TTL: 3 | Hop Count: 2</span>", "#3CC6D0", 1020),
        ("ph_d", "PHONE D (Gateway Convoy)", "Encounter with Rescue Convoy<br/><b>Edge Uplink Synchronized</b><br/>Status: DELIVERED to Command Center<br/><span style='color:#4CD08A;'>TTL: 2 | Hop Count: 3</span>", "#4CD08A", 1490),
    ]

    for pid, pname, pdesc, pcol, px in phones:
        node(root, pid,
             f"<b style='font-size:14px;color:{pcol};'>{pname}</b><hr/>"
             f"<span style='font-size:11px;color:#EEF2F8;'>{pdesc}</span>",
             f"rounded=1;fillColor=#162036;strokeColor={pcol};strokeWidth=2;align=center;verticalAlign=top;spacingTop=10;",
             px, 140, 390, 140)

    edge(root, "hop1", "BLE Broadcast (~80m)\nHop 1", "strokeColor=#3CC6D0;strokeWidth=3;fontColor=#3CC6D0;fontSize=11;", "ph_a", "ph_b")
    edge(root, "hop2", "Physical Transit & BLE\nHop 2", "strokeColor=#3CC6D0;strokeWidth=3;fontColor=#3CC6D0;fontSize=11;", "ph_b", "ph_c")
    edge(root, "hop3", "Multi-Hop Transport\nHop 3", "strokeColor=#4CD08A;strokeWidth=3;fontColor=#4CD08A;fontSize=11;", "ph_c", "ph_d")

    # Binary Envelope Wireframe
    node(root, "env_title", "<b>DTN BINARY ENVELOPE SPECIFICATION (&lt; 512 BYTES BLE MTU)</b>",
         "rounded=1;fillColor=#0E1627;strokeColor=#3A4C70;fontColor=#FFD21F;fontSize=13;align=left;spacingLeft=15;verticalAlign=top;spacingTop=10;",
         80, 340, 1800, 180)

    env_fields = [
        ("UUID", "16 Bytes", "Message ID"),
        ("Sender ID", "8 Bytes", "Pseudonym `SR-XXXX`"),
        ("Timestamp", "8 Bytes", "Origin Monotonic ms"),
        ("Type", "1 Byte", "0x01: SOS / 0x02: Chat"),
        ("TTL", "1 Byte", "Starts at 5, Decr -1"),
        ("Hop Count", "1 Byte", "Starts at 0, Incr +1"),
        ("Location Flag", "1 Byte", "0: None / 1: Present"),
        ("Lat / Lon", "16 Bytes", "IEEE 754 Float64"),
        ("Payload", "&le; 450 Bytes", "UTF-8 / CBOR Data"),
        ("CRC32", "4 Bytes", "Frame Checksum"),
    ]
    ew = 160
    for idx, (fname, fsize, fdesc) in enumerate(env_fields):
        node(root, f"ef_{idx}",
             f"<b style='font-size:11px;color:#FFD21F;'>{fname}</b><br/>"
             f"<span style='font-size:9px;color:#4CD08A;'>{fsize}</span><br/>"
             f"<span style='font-size:8px;color:#EEF2F8;'>{fdesc}</span>",
             "rounded=1;fillColor=#162036;strokeColor=#FFD21F;align=center;",
             105 + idx * 175, 390, ew, 90)

    # Decision Flowchart: Save-Before-Send & Deduplication
    node(root, "flow_box", "<b>SAVE-BEFORE-SEND &amp; LOOP SUPPRESSION DECISION ENGINE</b>",
         "rounded=1;fillColor=#0E1627;strokeColor=#3A4C70;fontColor=#3CC6D0;fontSize=13;align=left;spacingLeft=15;verticalAlign=top;spacingTop=10;",
         80, 560, 1800, 560)

    node(root, "st_send", "<b>User Dispatches SOS / Message</b>",
         "rounded=1;fillColor=#162036;strokeColor=#FFD21F;fontColor=#FFD21F;fontSize=12;align=center;",
         120, 630, 260, 60)

    node(root, "st_sql_save", "<b>1. SQLite Write Barrier</b><br/>status = 'SAVED'<br/>Committed to disk before radio",
         "rounded=1;fillColor=#162036;strokeColor=#4CD08A;fontColor=#4CD08A;fontSize=11;align=center;",
         440, 630, 260, 60)

    node(root, "st_ble_emit", "<b>2. Radio Transmission</b><br/>BLE GATT Advertising<br/>status = 'SENT_NEARBY'",
         "rounded=1;fillColor=#162036;strokeColor=#3CC6D0;fontColor=#3CC6D0;fontSize=11;align=center;",
         760, 630, 260, 60)

    node(root, "st_peer_recv", "<b>3. Peer Node Receives Packet</b><br/>Extracts UUID from envelope",
         "rounded=1;fillColor=#162036;strokeColor=#EEF2F8;fontColor=#EEF2F8;fontSize=11;align=center;",
         1080, 630, 260, 60)

    node(root, "d_bloom", "<b>Bloom Filter &amp; SQLite Check:</b><br/>Has this UUID been seen?",
         "rhombus;fillColor=#162036;strokeColor=#FFD21F;fontColor=#FFD21F;fontSize=11;align=center;",
         1400, 610, 240, 100)

    node(root, "st_drop", "<b>DROP DUPLICATE SILENTLY</b><br/>Halts retransmission storm",
         "rounded=1;fillColor=#162036;strokeColor=#FF5A4E;fontColor=#FF5A4E;fontSize=11;align=center;",
         1700, 630, 220, 60)

    node(root, "d_ttl", "<b>TTL Guard Check:</b><br/>Is TTL &gt; 1?",
         "rhombus;fillColor=#162036;strokeColor=#3CC6D0;fontColor=#3CC6D0;fontSize=11;align=center;",
         1400, 770, 240, 100)

    node(root, "st_ttl_halt", "<b>STORE LOCALLY, HALT RELAY</b><br/>status = 'STORED_TTL_EXPIRED'",
         "rounded=1;fillColor=#162036;strokeColor=#FFA033;fontColor=#FFA033;fontSize=11;align=center;",
         1700, 790, 220, 60)

    node(root, "st_fwd", "<b>FORWARD OVER MESH:</b><br/>• Decrement TTL = TTL - 1<br/>• Increment Hop = Hop + 1<br/>• status = 'RELAYED'",
         "rounded=1;fillColor=#162036;strokeColor=#4CD08A;fontColor=#4CD08A;fontSize=11;align=center;",
         1400, 940, 240, 80)

    edge(root, "f1", "", "strokeColor=#FFD21F;strokeWidth=2;", "st_send", "st_sql_save")
    edge(root, "f2", "", "strokeColor=#4CD08A;strokeWidth=2;", "st_sql_save", "st_ble_emit")
    edge(root, "f3", "", "strokeColor=#3CC6D0;strokeWidth=2;", "st_ble_emit", "st_peer_recv")
    edge(root, "f4", "", "strokeColor=#EEF2F8;strokeWidth=2;", "st_peer_recv", "d_bloom")
    edge(root, "f_dup_yes", "YES (Duplicate)", "strokeColor=#FF5A4E;strokeWidth=2;fontColor=#FF5A4E;", "d_bloom", "st_drop")
    edge(root, "f_dup_no", "NO (New Message)", "strokeColor=#4CD08A;strokeWidth=2;fontColor=#4CD08A;", "d_bloom", "d_ttl")
    edge(root, "f_ttl_no", "NO (TTL <= 1)", "strokeColor=#FFA033;strokeWidth=2;fontColor=#FFA033;", "d_ttl", "st_ttl_halt")
    edge(root, "f_ttl_yes", "YES (TTL > 1)", "strokeColor=#4CD08A;strokeWidth=2;fontColor=#4CD08A;", "d_ttl", "st_fwd")

def build_tab3_clean_wireframes(mxfile):
    """Tab 3: Core Mobile Wireframes (Spacious, Clean, Legible)"""
    root = add_diagram(mxfile, "tab3_wireframes", "03 - Mobile App Wireframes", 2000, 1100)

    node(root, "t3_title",
         "<b>RAKSHANET MOBILE CLIENT — CORE EMERGENCY WIREFRAMES</b><br/>"
         "<span style='font-size:12px;color:#9FADC2;'>High-Visibility Beacon Design System • 48dp Touch Targets • True OLED Black (#000000) • Zero Hardcoded Data</span>",
         "rounded=1;fillColor=#162036;strokeColor=#FFD21F;strokeWidth=2;fontColor=#FFD21F;fontSize=18;align=center;verticalAlign=middle;",
         50, 30, 1900, 65)

    # Draw 5 spacious, readable phone cards (Width: 320, Height: 680)
    cards = [
        ("c_gate", "SCREEN 2b: PROFILE GATE", "#FFD21F", 70),
        ("c_home", "SCREEN 3: HOME / SOS BEACON", "#FF5A4E", 450),
        ("c_report", "SCREEN 4: EMERGENCY REPORT", "#FF5A4E", 830),
        ("c_chat", "SCREEN 5: OFFLINE MESH CHAT", "#3CC6D0", 1210),
        ("c_map", "SCREEN 6: LIVE MESH MAP", "#4CD08A", 1590),
    ]

    pw, ph = 340, 880
    for cid, ctitle, ccol, cx in cards:
        # Phone chassis
        node(root, f"{cid}_box", "",
             f"rounded=1;arcSize=10;fillColor=#0B1220;strokeColor={ccol};strokeWidth=2.5;",
             cx, 130, pw, ph)

        # Phone Header bar
        node(root, f"{cid}_hdr", f"<b style='color:#EEF2F8;font-size:12px;'>{ctitle}</b>",
             f"rounded=0;fillColor=#162036;strokeColor={ccol};fontColor=#EEF2F8;fontSize=11;align=center;",
             cx, 130, pw, 38)

    # 1. Profile Gate Content
    node(root, "wg_note", "⚠️ Required Setup: Profile saved locally in SQLite before accessing network.",
         "rounded=1;fillColor=#162036;strokeColor=#FFD21F;fontColor=#FFD21F;fontSize=10;align=center;",
         85, 185, 310, 45)
    node(root, "wg_f1", "Full Name / Handle *<br/><span style='color:#9FADC2;font-size:9px;'>Validated non-empty string</span>",
         "rounded=1;fillColor=#162036;strokeColor=#3A4C70;fontColor=#EEF2F8;fontSize=11;align=left;spacingLeft=10;",
         85, 245, 310, 48)
    node(root, "wg_f2", "Blood Group (Dropdown)<br/><span style='color:#FFD21F;font-size:9px;'>A+, B+, O+, AB+, Unknown</span>",
         "rounded=1;fillColor=#162036;strokeColor=#3A4C70;fontColor=#EEF2F8;fontSize=11;align=left;spacingLeft=10;",
         85, 310, 310, 48)
    node(root, "wg_f3", "Emergency Contact Phone<br/><span style='color:#9FADC2;font-size:9px;'>+91 XXXXX XXXXX</span>",
         "rounded=1;fillColor=#162036;strokeColor=#3A4C70;fontColor=#EEF2F8;fontSize=11;align=left;spacingLeft=10;",
         85, 375, 310, 48)
    node(root, "wg_f4", "Preferred Language<br/><span style='color:#9FADC2;font-size:9px;'>English, Hindi, Marathi...</span>",
         "rounded=1;fillColor=#162036;strokeColor=#3A4C70;fontColor=#EEF2F8;fontSize=11;align=left;spacingLeft=10;",
         85, 440, 310, 48)
    node(root, "wg_btn", "<b>SAVE PROFILE &amp; ENTER APP</b><br/><span style='font-size:9px;color:#1A1400;'>Writes to SQLite • Generates ID `SR-XXXX`</span>",
         "rounded=1;fillColor=#FFD21F;strokeColor=none;fontColor=#1A1400;fontSize=12;align=center;",
         85, 870, 310, 56)

    # 2. Home SOS Content
    node(root, "wh_s1", "📡 Mesh Peers<br/><b style='color:#3CC6D0;font-size:13px;'>Dynamic Count</b>",
         "rounded=1;fillColor=#162036;strokeColor=#3CC6D0;fontColor=#EEF2F8;fontSize=10;align=center;",
         465, 185, 150, 55)
    node(root, "wh_s2", "🌐 Internet<br/><b style='color:#FF5A4E;font-size:13px;'>Offline</b>",
         "rounded=1;fillColor=#162036;strokeColor=#FF5A4E;fontColor=#EEF2F8;fontSize=10;align=center;",
         625, 185, 150, 55)
    node(root, "wh_s3", "📍 GPS Status<br/><b style='color:#9FADC2;font-size:13px;'>Sensor Active</b>",
         "rounded=1;fillColor=#162036;strokeColor=#3A4C70;fontColor=#EEF2F8;fontSize=10;align=center;",
         465, 250, 150, 55)
    node(root, "wh_s4", "🔋 Battery<br/><b style='color:#FFD21F;font-size:13px;'>Live %</b>",
         "rounded=1;fillColor=#162036;strokeColor=#FFD21F;fontColor=#EEF2F8;fontSize=10;align=center;",
         625, 250, 150, 55)

    # Circular SOS 176dp Button
    node(root, "wh_sos",
         "<b style='font-size:28px;color:#FFFFFF;'>SOS</b><br/>"
         "<span style='font-size:11px;color:#FFFFFF;'>Hold for 3 Seconds<br/>Radial Progress Ring</span>",
         "ellipse;fillColor=#D92D20;strokeColor=#FF5A4E;strokeWidth=6;align=center;verticalAlign=middle;",
         525, 370, 190, 190)

    node(root, "wh_warn", "⚠️ OFFLINE MODE ACTIVE<br/>Messages queued in SQLite and relayed to nearby peers.",
         "rounded=1;fillColor=#162036;strokeColor=#FFD21F;fontColor=#FFD21F;fontSize=10;align=center;",
         465, 620, 310, 48)
    node(root, "wh_nav", "💬 Chat &nbsp;|&nbsp; 🗺️ Map &nbsp;|&nbsp; 🚨 SOS &nbsp;|&nbsp; 📡 Nearby &nbsp;|&nbsp; 🤖 AI",
         "rounded=0;fillColor=#162036;strokeColor=#3A4C70;fontColor=#EEF2F8;fontSize=11;align=center;",
         450, 955, 340, 55)

    # 3. Emergency Report Content
    threats = [
        ("Medical", "Injury, respiratory, bleeding", "#D92D20"),
        ("Trapped", "Debris, collapsed structure", "#E07B00"),
        ("Fire", "Smoke, flammable hazard", "#D92D20"),
        ("Flood", "Water level rising rapidly", "#0E8A94"),
        ("Missing Person", "Lost child or family member", "#FFA033"),
        ("Other", "Custom situation notes", "#FFC400"),
    ]
    for idx, (tname, tdesc, tcol) in enumerate(threats):
        node(root, f"wt_{idx}",
             f"<b style='color:{tcol};font-size:12px;'>{tname}</b><br/>"
             f"<span style='color:#EEF2F8;font-size:10px;'>{tdesc}</span>",
             f"rounded=1;fillColor=#162036;strokeColor={tcol};strokeWidth=1.5;align=left;spacingLeft=10;",
             845, 185 + idx * 62, 310, 52)

    node(root, "wt_btn", "<b>((•)) SEND SOS DISTRESS BEACON</b><br/><span style='font-size:9px;color:#FFFFFF;'>Persists to SQLite &amp; Emits to Mesh Nodes</span>",
         "rounded=1;fillColor=#D92D20;strokeColor=none;fontColor=#FFFFFF;fontSize=12;align=center;",
         845, 870, 310, 56)

    # 4. Offline Mesh Chat Content
    node(root, "wc_tabs", "Nearby &nbsp;|&nbsp; Group &nbsp;|&nbsp; Rescue &nbsp;|&nbsp; Saved",
         "rounded=0;fillColor=#111A2C;strokeColor=#3A4C70;fontColor=#FFD21F;fontSize=11;align=center;",
         1210, 170, 340, 32)
    node(root, "wc_b1", "Survivor Node: Water needed near camp.<br/><span style='font-size:8px;color:#3CC6D0;'>✓✓ Sent Nearby (BLE) • 10:14 AM</span>",
         "rounded=1;fillColor=#162036;strokeColor=#3CC6D0;fontColor=#EEF2F8;fontSize=10;align=left;spacingLeft=8;",
         1225, 220, 240, 50)
    node(root, "wc_b2", "You: Medical team on the way.<br/><span style='font-size:8px;color:#4CD08A;'>✓✓ Relayed 2 Hops • 10:16 AM</span>",
         "rounded=1;fillColor=#0E8A94;strokeColor=none;fontColor=#FFFFFF;fontSize=10;align=left;spacingLeft=8;",
         1285, 285, 240, 50)
    node(root, "wc_loc", "📍 <b>Shared Location:</b> Village School<br/><span style='font-size:9px;color:#FFD21F;'>Lat: Real Fix, Lon: Real Fix (~1.2 km)</span>",
         "rounded=1;fillColor=#162036;strokeColor=#FFD21F;fontColor=#EEF2F8;fontSize=10;align=center;",
         1225, 350, 310, 48)
    node(root, "wc_empty", "Empty State: If no peers are broadcasting, displays dynamic status waiting for peer packets.",
         "rounded=1;fillColor=#162036;strokeColor=#3A4C70;fontColor=#9FADC2;fontSize=9;align=center;",
         1225, 415, 310, 45)
    node(root, "wc_in", "Type offline message... &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 🎙️ ➡️",
         "rounded=1;fillColor=#162036;strokeColor=#3A4C70;fontColor=#9FADC2;fontSize=11;align=left;spacingLeft=10;",
         1225, 870, 310, 48)

    # 5. Live Mesh Map Content
    node(root, "wm_canvas", "<b>OFFLINE TOPOGRAPHICAL VECTOR CANVAS</b><br/>"
                           "• Pulsing Red Rings: Active SOS Incidents<br/>"
                           "• Teal Nodes: Connected Mesh Peers<br/>"
                           "• Dashed Lines: Multi-hop Relay Links",
         "rounded=1;fillColor=#0E1627;strokeColor=#3A4C70;fontColor=#3CC6D0;fontSize=10;align=center;",
         1605, 185, 310, 300)
    node(root, "wm_node1", "🔴 SOS", "ellipse;fillColor=#D92D20;strokeColor=#FF5A4E;fontColor=#FFFFFF;fontSize=9;align=center;", 1640, 240, 55, 55)
    node(root, "wm_node2", "🟡 Peer", "ellipse;fillColor=#162036;strokeColor=#FFD21F;fontColor=#FFD21F;fontSize=9;align=center;", 1820, 340, 50, 50)
    edge(root, "wm_link", "", "dashed=1;strokeColor=#3CC6D0;strokeWidth=2;", "wm_node1", "wm_node2")

    node(root, "wm_drawer", "<b>BOTTOM INCIDENT DRAWER:</b><br/>Dynamic Incidents query from SQLite `emergency_reports` table.",
         "rounded=1;fillColor=#162036;strokeColor=#FF5A4E;fontColor=#EEF2F8;fontSize=10;align=center;",
         1605, 510, 310, 70)

def build_tab4_command_center(mxfile):
    """Tab 4: Tactical Convoy Gateway & Command Center Dashboard (ER & UI Wireframe)"""
    root = add_diagram(mxfile, "tab4_command", "04 - Command Center & Gateway Architecture", 2000, 1200)

    node(root, "t4_title",
         "<b>FIELD EDGE GATEWAY &amp; COMMAND CENTER CLOUD ARCHITECTURE</b><br/>"
         "<span style='font-size:12px;color:#9FADC2;'>Tactical Convoy Daemon • FastAPI Microservices • Explainable AI Scorer • React Leaflet Hub • NDMA CAP Gateway</span>",
         "rounded=1;fillColor=#162036;strokeColor=#FFD21F;strokeWidth=2;fontColor=#FFD21F;fontSize=18;align=center;verticalAlign=middle;",
         50, 30, 1900, 65)

    # Top Half: Field Gateway Architecture Wireframe
    node(root, "gw_box", "<b>FIELD EDGE RESCUE GATEWAY (CONVOY / NDMA BOAT / DRONE RELAY)</b>",
         "rounded=1;fillColor=#0E1627;strokeColor=#3A4C70;fontColor=#FFA033;fontSize=13;align=left;spacingLeft=15;verticalAlign=top;spacingTop=10;",
         50, 120, 1900, 220)

    gw_nodes = [
        ("gw_ble", "Long-Range BLE Sink", "High-gain omni array<br/>Ingests survivor batch envelopes<br/>Emits multi-hop ACKs"),
        ("gw_spool", "DTN Persistent Spool", "RocksDB / SQLite queue<br/>Prioritizes P1 (SOS) over P4 (Chat)<br/>Zero data loss on loss of link"),
        ("gw_uplink", "Hybrid Backhaul Uplink", "Starlink Satellite Transceiver<br/>4G/5G Tactical Private Network<br/>Auto-failover router"),
        ("gw_sync", "Bidirectional Sync Controller", "Transforms envelopes to CAP XML<br/>Pushes federal alert bulletins to mesh"),
    ]
    for idx, (gid, gname, gsub) in enumerate(gw_nodes):
        node(root, gid,
             f"<b style='font-size:12px;color:#FFA033;'>{gname}</b><br/><span style='font-size:10px;color:#EEF2F8;'>{gsub}</span>",
             "rounded=1;fillColor=#162036;strokeColor=#FFA033;strokeWidth=2;align=center;",
             80 + idx * 460, 170, 420, 130)

    # Bottom Half: Desktop Browser Frame Wireframe (Command Center)
    node(root, "brw_frame", "",
         "rounded=1;arcSize=4;fillColor=#0B1220;strokeColor=#3CC6D0;strokeWidth=2;",
         50, 370, 1900, 780)

    # Browser Top Chrome
    node(root, "brw_top", "🔴 🟡 🟢 &nbsp;&nbsp;&nbsp;&nbsp; <b>https://command.rakshanet.gov.in/triage</b>",
         "rounded=0;fillColor=#162036;strokeColor=#3A4C70;fontColor=#EEF2F8;fontSize=12;align=left;spacingLeft=20;",
         50, 370, 1900, 42)

    # Status Bar
    node(root, "brw_status",
         "🚨 ACTIVE P1 SOS: 4 &nbsp;&nbsp;|&nbsp;&nbsp; "
         "👥 PERSONS IN DISTRESS: 18 &nbsp;&nbsp;|&nbsp;&nbsp; "
         "🚒 ACTIVE RESCUE TEAMS: 6 &nbsp;&nbsp;|&nbsp;&nbsp; "
         "⛺ SHELTERS OPEN: 12 &nbsp;&nbsp;|&nbsp;&nbsp; "
         "📡 MESH GATEWAYS: 14 &nbsp;&nbsp;|&nbsp;&nbsp; "
         "🏛️ NDMA CAP SYNC: CONNECTED",
         "rounded=0;fillColor=#111A2C;strokeColor=#3A4C70;fontColor=#FFD21F;fontSize=11;align=center;",
         50, 412, 1900, 35)

    # 3-Column Dashboard Layout
    # Col 1: Leaflet Tactical Map (40%)
    node(root, "dash_map",
         "<b>LEAFLET TACTICAL GIS MAP CANVAS</b><br/><br/>"
         "• Real-time GeoJSON Overlays<br/>"
         "• Red Pulsing Rings: SOS Distress Clusters<br/>"
         "• Teal Vehicle Markers: Convoy Rescue Units<br/>"
         "• Dashed Cyan Lines: Multi-hop BLE Relay Trajectories<br/>"
         "• Yellow Shaded Polygon: Flood Inundation Zone",
         "rounded=1;fillColor=#0E1627;strokeColor=#3CC6D0;fontColor=#3CC6D0;fontSize=12;align=center;",
         70, 465, 740, 660)

    # Col 2: Explainable AI Triage Queue (35%)
    node(root, "dash_triage",
         "<b>EXPLAINABLE AI LIVE INCIDENT TRIAGE STREAM</b><hr/>"
         "<div style='text-align:left;font-size:11px;'>"
         "<b style='color:#FF5A4E;'>[P1 CRITICAL] Trapped Under Building Debris</b><br/>"
         "Victim ID: `SR-284739` • Sector 4 Bridge (~1.3 km)<br/>"
         "<b>AI Factors:</b> Crush Hazard (0.45) + Battery 18% (0.35) + Water (0.20)<br/>"
         "<b>Confidence Score:</b> 96.4%<br/>"
         "<b style='color:#4CD08A;'>[ASSIGN TEAM 1 ➡️]</b><br/><br/>"
         "<b style='color:#FFA033;'>[P2 URGENT] Flood Water Entering Shelter Ground Floor</b><br/>"
         "Shelter: Primary Village School (120 Persons)<br/>"
         "<b>AI Factors:</b> Water Ingress Rate + Elderly Population<br/>"
         "<b>Confidence Score:</b> 91.2%<br/>"
         "<b style='color:#4CD08A;'>[DISPATCH RESCUE BOAT ➡️]</b>"
         "</div>",
         "rounded=1;fillColor=#162036;strokeColor=#FF5A4E;fontColor=#EEF2F8;fontSize=11;align=center;verticalAlign=top;spacingTop=12;",
         830, 465, 590, 660)

    # Col 3: Resource Matrix & NDMA CAP Broadcast (25%)
    node(root, "dash_res",
         "<b>RESCUE OPERATIONS &amp; NDMA CAP GATEWAY</b><hr/>"
         "<div style='text-align:left;font-size:11px;'>"
         "<b>FIELD UNITS STATUS:</b><br/>"
         "• Team 1 (Alpha): En route to Sector 4 (ETA 8m)<br/>"
         "• Team 2 (Bravo): Evacuating School Shelter<br/>"
         "• Team 3 (Charlie): Standby at HQ<br/><br/>"
         "<b>SHELTER CAPACITY:</b><br/>"
         "• Village School: 120 / 200 (Food: OK, Med: Need)<br/>"
         "• Community Center: 190 / 200 (Full)<br/><br/>"
         "<b>NDMA CAP XML BROADCAST:</b><br/>"
         "<span style='color:#4CD08A;'>Status: Active Alert Ingestion</span><br/>"
         "Last Federal Sync: 10:44:12 IST"
         "</div>",
         "rounded=1;fillColor=#162036;strokeColor=#4CD08A;fontColor=#EEF2F8;fontSize=11;align=center;verticalAlign=top;spacingTop=12;",
         1440, 465, 480, 660)

def main():
    mxfile = create_drawio()
    build_tab1_er_architecture(mxfile)
    build_tab2_dtn_protocol(mxfile)
    build_tab3_clean_wireframes(mxfile)
    build_tab4_command_center(mxfile)

    tree = ET.ElementTree(mxfile)
    ET.indent(tree, space="  ")
    out_path = r"p:\RakshaNet\architecture.drawio"
    tree.write(out_path, encoding="utf-8", xml_declaration=True)
    print(f"Successfully generated clean ER diagram & wireframe architecture to: {out_path}")

if __name__ == "__main__":
    main()
