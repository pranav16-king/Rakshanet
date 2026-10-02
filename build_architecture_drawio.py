"""
RakshaNet (SignalRescue AI) — Complete Software Architecture & Wireframe Generator
Generates comprehensive multi-tab draw.io XML specification file: p:\\RakshaNet\\architecture.drawio
Strictly implements dynamic data flow, reactive state contracts, DTN protocols, 14 phone frames,
and desktop browser wireframe for the Command Center.
"""

import xml.etree.ElementTree as ET
import os

def create_drawio_file():
    return ET.Element('mxfile', {
        'host': 'Electron',
        'modified': '2026-10-02T14:05:00.000Z',
        'agent': 'RakshaNet Architecture & Wireframe Specialist',
        'version': '24.7.17',
        'type': 'device'
    })

def add_diagram(mxfile, diag_id, name, width, height, bg="#0B1220"):
    diag = ET.SubElement(mxfile, 'diagram', {'id': diag_id, 'name': name})
    model = ET.SubElement(diag, 'mxGraphModel', {
        'dx': '2400', 'dy': '1600', 'grid': '1', 'gridSize': '10',
        'guides': '1', 'tooltips': '1', 'connect': '1', 'arrows': '1',
        'fold': '1', 'page': '1', 'pageScale': '1',
        'pageWidth': str(width), 'pageHeight': str(height),
        'background': bg, 'math': '0', 'shadow': '0'
    })
    root = ET.SubElement(model, 'root')
    ET.SubElement(root, 'mxCell', {'id': '0'})
    ET.SubElement(root, 'mxCell', {'id': '1', 'parent': '0'})
    return root

def cell(root, cid, val, style, x, y, w, h, parent="1"):
    c = ET.SubElement(root, 'mxCell', {
        'id': cid, 'value': val, 'style': style, 'vertex': '1', 'parent': parent
    })
    ET.SubElement(c, 'mxGeometry', {
        'x': str(x), 'y': str(y), 'width': str(w), 'height': str(h), 'as': 'geometry'
    })
    return c

def edge(root, eid, val, style, src, tgt, parent="1", points=None):
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

# -------------------------------------------------------------
# DYNAMIC PHONE FRAME WIREFRAME GENERATOR
# -------------------------------------------------------------
def draw_phone_frame(root, pfx, x, y, title, screen_num, subtitle="", is_oled=False):
    """Draws a high-fidelity smartphone bezel with notch, status bar, and home pill."""
    bg_color = "#000000" if is_oled else "#0B1220"
    border_color = "#D92D20" if "2b" in screen_num else ("#FFD21F" if screen_num in ["3", "1"] else "#3A4C70")

    # Outer Hardware Chassis
    cell(root, f"{pfx}_chassis", "",
         f"rounded=1;arcSize=10;whiteSpace=wrap;html=1;fillColor=#0F172A;strokeColor={border_color};strokeWidth=3;shadow=1;",
         x, y, 290, 580)
    
    # Side hardware buttons
    cell(root, f"{pfx}_pwr", "", "rounded=1;fillColor=#475569;strokeColor=none;", x + 290, y + 100, 3, 40)
    cell(root, f"{pfx}_vol_up", "", "rounded=1;fillColor=#475569;strokeColor=none;", x - 3, y + 80, 3, 35)
    cell(root, f"{pfx}_vol_dn", "", "rounded=1;fillColor=#475569;strokeColor=none;", x - 3, y + 125, 3, 35)

    # Inner Screen Surface
    cell(root, f"{pfx}_screen", "",
         f"rounded=1;arcSize=8;whiteSpace=wrap;html=1;fillColor={bg_color};strokeColor=#1E293B;strokeWidth=1;",
         x + 8, y + 8, 274, 564)

    # Dynamic Island / Notch
    cell(root, f"{pfx}_notch", "",
         "rounded=1;arcSize=50;whiteSpace=wrap;html=1;fillColor=#000000;strokeColor=#334155;strokeWidth=1;",
         x + 95, y + 14, 100, 18)
    cell(root, f"{pfx}_cam", "", "ellipse;fillColor=#1E293B;strokeColor=#0F172A;strokeWidth=1;", x + 168, y + 18, 10, 10)
    cell(root, f"{pfx}_speaker", "", "rounded=1;fillColor=#334155;strokeColor=none;", x + 115, y + 21, 35, 4)

    # Dynamic Status Bar
    cell(root, f"{pfx}_stat",
         "09:41  •  Stream: ((•)) BLE MESH  •  🔋 state.batteryPct",
         "text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontSize=8;fontColor=#94A3B8;fontStyle=1;",
         x + 10, y + 34, 270, 16)

    # Screen Header / AppBar
    header_color = "#FFD21F" if "2b" in screen_num or screen_num == "3" else "#3CC6D0"
    cell(root, f"{pfx}_appbar",
         f"<b>Screen {screen_num}: {title}</b>" + (f"<br/><span style='font-size:8px;color:#9FADC2;'>{subtitle}</span>" if subtitle else ""),
         f"rounded=1;fillColor=#162036;strokeColor={header_color};strokeWidth=1;fontColor=#EEF2F8;fontSize=10;align=center;verticalAlign=middle;",
         x + 14, y + 52, 262, 34)

    # Bottom Home Gesture Indicator Pill
    cell(root, f"{pfx}_pill", "", "rounded=1;arcSize=50;fillColor=#64748B;strokeColor=none;", x + 105, y + 562, 80, 4)

def populate_screen_dynamic(root, pfx, x, y, screen_num):
    """Populates dynamic software architecture bindings and state flows inside phone frames."""
    # Screen 1: Splash
    if screen_num == "1":
        cell(root, f"{pfx}_beacon", "🚨\nSignalRescue AI",
             "ellipse;whiteSpace=wrap;html=1;fillColor=#162036;strokeColor=#FFD21F;strokeWidth=3;fontColor=#FFD21F;fontStyle=1;fontSize=14;align=center;",
             x + 65, y + 145, 160, 160)
        cell(root, f"{pfx}_tag", "Stay Connected. Save Lives.\nAnytime. Anywhere.",
             "text;html=1;align=center;fontColor=#EEF2F8;fontSize=12;fontStyle=1;",
             x + 25, y + 325, 240, 40)
        cell(root, f"{pfx}_gate", "FutureBuilder(ProfileRepository.getProfile())\nChecking SQLite `user_profile` table...",
             "rounded=1;fillColor=#162036;strokeColor=#3CC6D0;fontColor=#3CC6D0;fontSize=9;align=center;",
             x + 30, y + 400, 230, 45)
        cell(root, f"{pfx}_flow", "isRegistered ? Navigator('/home')\n: Navigator('/profile_gate')",
             "rounded=1;fillColor=#0E1627;strokeColor=#FFD21F;fontColor=#FFD21F;fontSize=9;align=center;",
             x + 30, y + 460, 230, 40)
        cell(root, f"{pfx}_ver", "Build: Flutter 3.47 / Dart 3.13 (Offline Stack)",
             "text;html=1;align=center;fontColor=#9FADC2;fontSize=8;",
             x + 25, y + 520, 240, 18)

    # Screen 2: Onboarding
    elif screen_num == "2":
        cell(root, f"{pfx}_hero", "Decentralized Offline Mesh\nZero Infrastructure Required",
             "text;html=1;align=center;fontColor=#EEF2F8;fontStyle=1;fontSize=13;",
             x + 20, y + 92, 250, 36)
        cards = [
            ("⚡ Local Radio Transceivers", "BLE GATT Client/Server duty-cycle loop"),
            ("📡 Multi-Hop Epidemic Routing", "Store-Carry-and-Forward packet hopping"),
            ("🤖 Deterministic Triage Engine", "On-device rule-based disaster heuristic"),
            ("🏛️ Automatic Gateway Synchronization", "Spools to NDMA CAP XML when uplink in range")
        ]
        for idx, (title, sub) in enumerate(cards):
            cell(root, f"{pfx}_c{idx}", f"<b>{title}</b><br/><span style='font-size:8px;color:#9FADC2;'>{sub}</span>",
                 "rounded=1;fillColor=#162036;strokeColor=#26344F;fontColor=#EEF2F8;fontSize=9;align=left;spacingLeft=8;",
                 x + 25, y + 135 + idx * 58, 240, 50)
        cell(root, f"{pfx}_btn", "OnboardingController.complete() ➔",
             "rounded=1;fillColor=#FFD21F;strokeColor=none;fontColor=#1A1400;fontStyle=1;fontSize=11;align=center;",
             x + 25, y + 440, 240, 42)
        cell(root, f"{pfx}_skip", "Skip to Profile Gate",
             "text;html=1;align=center;fontColor=#9FADC2;fontSize=10;",
             x + 25, y + 490, 240, 20)

    # Screen 2b: Mandatory Profile Setup Gate
    elif screen_num == "2b":
        cell(root, f"{pfx}_alert", "⚠️ MANDATORY FIRST-LAUNCH GATE\nProfileProvider.isRegistered == false",
             "rounded=1;fillColor=#3A1010;strokeColor=#D92D20;fontColor=#FFFFFF;fontSize=9;align=center;fontStyle=1;",
             x + 20, y + 92, 250, 36)
        inputs = [
            ("user_input: full_name", "TextEditingController(name)"),
            ("user_input: blood_group", "DropdownSelector<BloodGroup>()"),
            ("user_input: emergency_phone", "TextEditingController(contact)"),
            ("user_input: preferred_lang", "SegmentedButton<Language>()")
        ]
        for idx, (lbl, val) in enumerate(inputs):
            cell(root, f"{pfx}_in{idx}", f"<span style='font-size:8px;color:#9FADC2;'>{lbl}:</span><br/><b>{val}</b>",
                 "rounded=1;fillColor=#162036;strokeColor=#26344F;fontColor=#EEF2F8;fontSize=9;align=left;spacingLeft=8;",
                 x + 25, y + 135 + idx * 52, 240, 44)
        cell(root, f"{pfx}_disc", "SQLite Transaction:\nINSERT INTO user_profile VALUES (uuid, name, blood, ...)\nGenerates anonymous mesh ID: `SR-XXXX-XXXX`",
             "rounded=1;fillColor=#162036;strokeColor=#FFD21F;fontColor=#FFD21F;fontSize=8;align=left;spacingLeft=6;",
             x + 25, y + 355, 240, 45)
        cell(root, f"{pfx}_submit", "ProfileProvider.saveProfile(data)",
             "rounded=1;fillColor=#FFD21F;strokeColor=none;fontColor=#1A1400;fontStyle=1;fontSize=11;align=center;",
             x + 25, y + 440, 240, 45)

    # Screen 3: Home / SOS Main (Hold 3s)
    elif screen_num == "3":
        stats = [
            ("MeshProvider.peers", "${peers.length} active", "#3CC6D0"),
            ("Net: Offline", "Outbox Spooled", "#FF5A4E"),
            ("LocationService", "Live GPS Fix", "#9FADC2"),
            ("TelemetryService", "state.batteryPct", "#FFD21F")
        ]
        for idx, (lbl, sub, col) in enumerate(stats):
            row = idx // 2
            col_idx = idx % 2
            cell(root, f"{pfx}_st{idx}", f"<b>{lbl}</b><br/><span style='font-size:8px;color:#EEF2F8;'>{sub}</span>",
                 f"rounded=1;fillColor=#162036;strokeColor={col};fontColor={col};fontSize=9;align=center;",
                 x + 25 + col_idx * 125, y + 92 + row * 44, 115, 38)
        
        # Central SOS Circular Button (176dp)
        cell(root, f"{pfx}_sos_ring", "",
             "ellipse;fillColor=#3A1010;strokeColor=#FF5A4E;strokeWidth=3;",
             x + 55, y + 190, 180, 180)
        cell(root, f"{pfx}_sos_btn", "<b>SOS</b><br/><span style='font-size:8px;'>GestureDetector.onLongPress(3s)<br/>EmergencyProvider.dispatch()</span>",
             "ellipse;fillColor=#D92D20;strokeColor=#FFFFFF;strokeWidth=2;fontColor=#FFFFFF;fontSize=24;fontStyle=1;align=center;",
             x + 70, y + 205, 150, 150)
        
        cell(root, f"{pfx}_warn", "⚠️ Save-Before-Send: Writes to SQLite before radio attempt",
             "rounded=1;fillColor=#162036;strokeColor=#FFD21F;fontColor=#FFD21F;fontSize=8;align=center;",
             x + 25, y + 410, 240, 24)
        cell(root, f"{pfx}_nav", "MainShell: [ChatTab | MapTab | SosTab | ToolsTab | AiTab]",
             "rounded=0;fillColor=#162036;strokeColor=#26344F;fontColor=#EEF2F8;fontSize=8;align=center;",
             x + 10, y + 510, 270, 36)

    # Screen 4: Emergency Report
    elif screen_num == "4":
        cell(root, f"{pfx}_head", "Dynamic Selector: `EmergencyType.values`",
             "text;html=1;fontColor=#9FADC2;fontSize=9;align=left;",
             x + 25, y + 90, 240, 18)
        cats = [
            ("🩸 EmergencyType.medical", "#D92D20"),
            ("🧱 EmergencyType.trapped", "#FFA033"),
            ("🔥 EmergencyType.fire", "#FF5A4E"),
            ("🌊 EmergencyType.flood", "#3CC6D0"),
            ("👤 EmergencyType.missingPerson", "#FFD21F"),
            ("❓ EmergencyType.other", "#9FADC2")
        ]
        for idx, (cname, ccol) in enumerate(cats):
            cell(root, f"{pfx}_cat{idx}", cname,
                 f"rounded=1;fillColor=#162036;strokeColor={ccol};fontColor=#EEF2F8;fontSize=9;align=left;spacingLeft=8;",
                 x + 25, y + 112 + idx * 34, 240, 28)
        cell(root, f"{pfx}_note", "TextFormField(description, maxLines: 3)",
             "rounded=1;fillColor=#0E1627;strokeColor=#26344F;fontColor=#9FADC2;fontSize=8;align=left;spacingLeft=6;",
             x + 25, y + 325, 240, 38)
        cell(root, f"{pfx}_loc", "📍 LocationService.stream: (lat, lon, accuracy)",
             "rounded=1;fillColor=#162036;strokeColor=#FFD21F;fontColor=#FFD21F;fontSize=8;align=center;",
             x + 25, y + 375, 240, 24)
        cell(root, f"{pfx}_send", "ChatService.saveBeforeSend(report)",
             "rounded=1;fillColor=#D92D20;strokeColor=none;fontColor=#FFFFFF;fontStyle=1;fontSize=11;align=center;",
             x + 25, y + 420, 240, 45)
        cell(root, f"{pfx}_bot", "SQLite status='SAVED' ➔ BLE Envelope Broadcast",
             "text;html=1;fontColor=#9FADC2;fontSize=8;align=center;",
             x + 25, y + 475, 240, 20)

    # Screen 5: Offline Mesh Chat
    elif screen_num == "5":
        cell(root, f"{pfx}_tabs", "TabBar: Nearby(Stream) | Group | Rescue | Saved",
             "rounded=0;fillColor=#111A2C;strokeColor=#26344F;fontColor=#FFD21F;fontSize=9;align=center;",
             x + 20, y + 90, 250, 22)
        cell(root, f"{pfx}_b1", "StreamBuilder<List<ChatMessage>>:\npeer_msg: payload.content\n<span style='font-size:7px;color:#3CC6D0;'>state = MessageStatus.SENT_NEARBY</span>",
             "rounded=1;fillColor=#162036;strokeColor=#3CC6D0;fontColor=#EEF2F8;fontSize=8;align=left;spacingLeft=6;",
             x + 25, y + 120, 190, 48)
        cell(root, f"{pfx}_b2", "my_msg: payload.content\n<span style='font-size:7px;color:#4CD08A;'>state = MessageStatus.DELIVERED (hops: 2)</span>",
             "rounded=1;fillColor=#0E8A94;strokeColor=none;fontColor=#FFFFFF;fontSize=8;align=right;spacingRight=6;",
             x + 75, y + 180, 190, 42)
        cell(root, f"{pfx}_loccard", "LocationAttachmentCard:\nGeoPoint(msg.lat, msg.lon, dist: calcDistance())",
             "rounded=1;fillColor=#162036;strokeColor=#FFD21F;fontColor=#FFD21F;fontSize=8;align=center;",
             x + 25, y + 235, 240, 36)
        cell(root, f"{pfx}_quick", "QuickPromptChips.generate()",
             "text;html=1;fontColor=#9FADC2;fontSize=8;align=center;",
             x + 20, y + 415, 250, 18)
        cell(root, f"{pfx}_in", "TextEditingController  •  onSend: ChatService.dispatch()",
             "rounded=1;fillColor=#162036;strokeColor=#26344F;fontColor=#9FADC2;fontSize=8;align=left;spacingLeft=8;",
             x + 25, y + 440, 240, 36)
        cell(root, f"{pfx}_nav", "MainShell Navigation Shell",
             "rounded=0;fillColor=#162036;strokeColor=#26344F;fontColor=#EEF2F8;fontSize=8;align=center;",
             x + 10, y + 510, 270, 36)

    # Screen 6: Live Mesh Map
    elif screen_num == "6":
        cell(root, f"{pfx}_map", "",
             "rounded=1;fillColor=#0E1627;strokeColor=#26344F;strokeWidth=1;",
             x + 25, y + 90, 240, 260)
        cell(root, f"{pfx}_m_sos", "CustomPaint:\nSOS Pin",
             "ellipse;fillColor=#D92D20;strokeColor=#FF5A4E;strokeWidth=2;fontColor=#FFFFFF;fontSize=8;align=center;",
             x + 55, y + 125, 50, 50)
        cell(root, f"{pfx}_m_peer1", "CustomPaint:\nPeer Node",
             "ellipse;fillColor=#162036;strokeColor=#FFD21F;strokeWidth=1;fontColor=#FFD21F;fontSize=7;align=center;",
             x + 160, y + 145, 40, 40)
        cell(root, f"{pfx}_m_peer2", "CustomPaint:\nGateway",
             "ellipse;fillColor=#162036;strokeColor=#4CD08A;strokeWidth=1;fontColor=#4CD08A;fontSize=7;align=center;",
             x + 195, y + 245, 40, 40)
        edge(root, f"{pfx}_hop1", "", "dashed=1;strokeColor=#3CC6D0;strokeWidth=2;", f"{pfx}_m_sos", f"{pfx}_m_peer1")
        edge(root, f"{pfx}_hop2", "", "dashed=1;strokeColor=#3CC6D0;strokeWidth=2;", f"{pfx}_m_peer1", f"{pfx}_m_peer2")
        cell(root, f"{pfx}_clus", "clusterPainter(peersInProximity)",
             "rounded=1;fillColor=#162036;strokeColor=#3CC6D0;fontColor=#3CC6D0;fontSize=8;align=center;",
             x + 65, y + 310, 160, 22)
        cell(root, f"{pfx}_sheet", "DraggableScrollableSheet:\nActive Reports Stream (SQLite SELECT active reports)",
             "rounded=1;fillColor=#162036;strokeColor=#D92D20;fontColor=#EEF2F8;fontSize=8;align=left;spacingLeft=6;",
             x + 25, y + 365, 240, 48)
        cell(root, f"{pfx}_filters", "FilterChips: StreamFilter.byCategory()",
             "text;html=1;fontColor=#9FADC2;fontSize=8;align=center;",
             x + 20, y + 425, 250, 18)
        cell(root, f"{pfx}_nav", "MainShell Navigation Shell",
             "rounded=0;fillColor=#162036;strokeColor=#26344F;fontColor=#EEF2F8;fontSize=8;align=center;",
             x + 10, y + 510, 270, 36)

    # Screen 7: Offline AI Assistant
    elif screen_num == "7":
        cell(root, f"{pfx}_badge", "🤖 AIAssistantService.evaluateIntent(prompt)",
             "rounded=1;fillColor=#162036;strokeColor=#3CC6D0;fontColor=#3CC6D0;fontSize=8;align=center;",
             x + 25, y + 90, 240, 22)
        cell(root, f"{pfx}_uq", "Query: prompt_input.text",
             "rounded=1;fillColor=#162036;strokeColor=#3CC6D0;fontColor=#EEF2F8;fontSize=8;align=left;spacingLeft=6;",
             x + 35, y + 120, 220, 30)
        cell(root, f"{pfx}_ai_ans", "OfflineRuleKB.match(intent):\n1. Pattern: WaterContaminationRule\n2. Actions: ClothFilter -> Boil -> SODIS\n3. Deterministic Safety Constraints\n⚠️ Zero Cloud Dependency Verified",
             "rounded=1;fillColor=#0E1627;strokeColor=#FFD21F;fontColor=#EEF2F8;fontSize=8;align=left;spacingLeft=6;",
             x + 25, y + 160, 240, 90)
        cell(root, f"{pfx}_pills", "HeuristicSuggestions: RuleIndex.topSuggestions()",
             "text;html=1;fontColor=#9FADC2;fontSize=8;align=center;",
             x + 20, y + 415, 250, 18)
        cell(root, f"{pfx}_in", "TextEditingController • onSubmitted: evaluate()",
             "rounded=1;fillColor=#162036;strokeColor=#26344F;fontColor=#9FADC2;fontSize=8;align=left;spacingLeft=8;",
             x + 25, y + 440, 240, 36)
        cell(root, f"{pfx}_nav", "MainShell Navigation Shell",
             "rounded=0;fillColor=#162036;strokeColor=#26344F;fontColor=#EEF2F8;fontSize=8;align=center;",
             x + 10, y + 510, 270, 36)

    # Screen 8: Report Missing Person
    elif screen_num == "8":
        fields = [
            ("TextFormField(name)", "bind: missingPerson.fullName"),
            ("Row(Age, Gender)", "bind: age, genderDropdown"),
            ("TextFormField(clothing)", "bind: clothingDescription"),
            ("LocationPicker()", "bind: lastSeenLocation, timestamp")
        ]
        for idx, (lbl, val) in enumerate(fields):
            cell(root, f"{pfx}_f{idx}", f"<span style='font-size:8px;color:#9FADC2;'>{lbl}:</span><br/><b>{val}</b>",
                 "rounded=1;fillColor=#162036;strokeColor=#26344F;fontColor=#EEF2F8;fontSize=8;align=left;spacingLeft=6;",
                 x + 25, y + 90 + idx * 44, 240, 36)
        cell(root, f"{pfx}_photos", "PhotoAttachmentWidget:\nList<Uint8List> thumbnailBytes (Compressed for BLE)",
             "rounded=1;fillColor=#162036;strokeColor=#3CC6D0;fontColor=#3CC6D0;fontSize=8;align=center;",
             x + 25, y + 280, 240, 48)
        cell(root, f"{pfx}_disc", "SQLite: INSERT INTO missing_persons ...\nMeshEngine: broadcastEnvelope(PacketType.MISSING)",
             "text;html=1;fontColor=#9FADC2;fontSize=8;align=center;",
             x + 20, y + 360, 250, 24)
        cell(root, f"{pfx}_btn", "ReportRepository.createMissingPerson()",
             "rounded=1;fillColor=#FFD21F;strokeColor=none;fontColor=#1A1400;fontStyle=1;fontSize=10;align=center;",
             x + 25, y + 420, 240, 42)

    # Screen 9: Shelters & Resources
    elif screen_num == "9":
        cell(root, f"{pfx}_tabs", "StreamBuilder(ShelterRepository.watchShelters())",
             "rounded=0;fillColor=#111A2C;strokeColor=#26344F;fontColor=#FFD21F;fontSize=8;align=center;",
             x + 20, y + 90, 250, 22)
        shelters = [
            ("shelter.name", "${shelter.occupancy}/${shelter.capacity} (60%)", "Dynamic Supplies: food, water, meds", "#4CD08A"),
            ("shelter.name", "Capacity Warning: (95% full)", "Dynamic Supplies: solar power, food", "#FFA033"),
            ("shelter.name", "Status: Medical Triage Active", "Dynamic Supplies: triage beds, doctors", "#D92D20")
        ]
        for idx, (sname, stat, tags, col) in enumerate(shelters):
            cell(root, f"{pfx}_sh{idx}", f"<b>{sname}</b><br/><span style='color:{col};font-size:8px;'>{stat}</span><br/><span style='color:#9FADC2;font-size:7px;'>{tags}</span>",
                 f"rounded=1;fillColor=#162036;strokeColor={col};fontColor=#EEF2F8;fontSize=8;align=left;spacingLeft=6;",
                 x + 25, y + 120 + idx * 74, 240, 64)
        cell(root, f"{pfx}_nav", "MainShell Navigation Shell",
             "rounded=0;fillColor=#162036;strokeColor=#26344F;fontColor=#EEF2F8;fontSize=8;align=center;",
             x + 10, y + 510, 270, 36)

    # Screen 10: My Messages (Outbox)
    elif screen_num == "10":
        cell(root, f"{pfx}_tabs", "SQLite Outbox Queue: SELECT * FROM messages WHERE ...",
             "rounded=0;fillColor=#111A2C;strokeColor=#26344F;fontColor=#FFD21F;fontSize=8;align=center;",
             x + 20, y + 90, 250, 22)
        msgs = [
            ("OutboxItem: PacketType.SOS", "status='SAVED' • retryCount=4 • Priority=P1", "#FF5A4E"),
            ("OutboxItem: PacketType.LOCATION", "status='QUEUED' • waiting for peer encounter", "#FFA033"),
            ("OutboxItem: PacketType.MISSING", "status='SENT_NEARBY' • TTL=4 • Hops=1", "#3CC6D0")
        ]
        for idx, (mtitle, msub, col) in enumerate(msgs):
            cell(root, f"{pfx}_m{idx}", f"<b>{mtitle}</b><br/><span style='font-size:7px;color:#9FADC2;'>{msub}</span>",
                 f"rounded=1;fillColor=#162036;strokeColor={col};fontColor=#EEF2F8;fontSize=8;align=left;spacingLeft=6;",
                 x + 25, y + 120 + idx * 56, 240, 48)
        cell(root, f"{pfx}_sync", "MeshEngine.onGatewayDiscovered():\nTrigger batch outbox flush to uplink gateway",
             "rounded=1;fillColor=#0E1627;strokeColor=#4CD08A;fontColor=#4CD08A;fontSize=8;align=center;",
             x + 25, y + 360, 240, 40)
        cell(root, f"{pfx}_nav", "MainShell Navigation Shell",
             "rounded=0;fillColor=#162036;strokeColor=#26344F;fontColor=#EEF2F8;fontSize=8;align=center;",
             x + 10, y + 510, 270, 36)

    # Screen 11: Safety Tools
    elif screen_num == "11":
        tools = [
            ("🩹 FirstAidNavigator", "Static Offline KB", "#D92D20"),
            ("💡 SurvivalRules", "Intent Classifier", "#FFD21F"),
            ("🗺️ CachedTiles", "MBTiles Store", "#3CC6D0"),
            ("✅ IAmSafeDispatch", "One-Tap Beacon", "#4CD08A"),
            ("📞 AgencyDirectory", "Emergency Contacts", "#FF5A4E"),
            ("🔔 SirenAlertStream", "Local Siren Alerts", "#FFA033")
        ]
        for idx, (tname, tsub, col) in enumerate(tools):
            row = idx // 2
            col_idx = idx % 2
            cell(root, f"{pfx}_tl{idx}", f"<b>{tname}</b><br/><span style='font-size:7px;color:#9FADC2;'>{tsub}</span>",
                 f"rounded=1;fillColor=#162036;strokeColor={col};fontColor=#EEF2F8;fontSize=8;align=center;",
                 x + 25 + col_idx * 125, y + 105 + row * 65, 115, 54)
        cell(root, f"{pfx}_nav", "MainShell Navigation Shell",
             "rounded=0;fillColor=#162036;strokeColor=#26344F;fontColor=#EEF2F8;fontSize=8;align=center;",
             x + 10, y + 510, 270, 36)

    # Screen 12: Settings (True OLED Black)
    elif screen_num == "12":
        toggles = [
            ("MeshEngine.radioActive", "Switch(value: state.meshEnabled)"),
            ("LocationService.tracking", "Switch(value: state.gpsEnabled)"),
            ("CloudSync.autoUpload", "Switch(value: state.autoSync)"),
            ("ThemeProvider.oledBlack", "Switch(value: state.isOledTrueBlack)")
        ]
        for idx, (tname, tval) in enumerate(toggles):
            cell(root, f"{pfx}_set{idx}", f"<b>{tname}</b><br/><span style='font-size:7px;color:#9FADC2;'>{tval}</span>",
                 "rounded=1;fillColor=#162036;strokeColor=#26344F;fontColor=#EEF2F8;fontSize=8;align=left;spacingLeft=6;",
                 x + 25, y + 92 + idx * 42, 240, 34)
        cell(root, f"{pfx}_oled_note", "Hardware Controller: AMOLED Subpixel Shutdown\nRGB #000000 turns off physical OLED pixels (62% power savings)",
             "rounded=1;fillColor=#000000;strokeColor=#FFD21F;fontColor=#FFD21F;fontSize=8;align=left;spacingLeft=6;",
             x + 25, y + 270, 240, 42)
        navs = ["LocaleController.setLocale()", "CryptoManager.exportPublicKey()", "AppInfo.versionCheck()"]
        for idx, ntxt in enumerate(navs):
            cell(root, f"{pfx}_nv{idx}", ntxt,
                 "rounded=1;fillColor=#162036;strokeColor=#26344F;fontColor=#9FADC2;fontSize=8;align=left;spacingLeft=6;",
                 x + 25, y + 325 + idx * 36, 240, 28)
        cell(root, f"{pfx}_nav", "MainShell Navigation Shell",
             "rounded=0;fillColor=#162036;strokeColor=#26344F;fontColor=#EEF2F8;fontSize=8;align=center;",
             x + 10, y + 510, 270, 36)

    # Screen 13: Profile & Community Impact KPIs
    elif screen_num == "13":
        cell(root, f"{pfx}_user", "Consumer<ProfileProvider>:\nprofile.pseudonym (ID: `SR-XXXX-XXXX`)\nBloodGroup: profile.bloodGroup",
             "rounded=1;fillColor=#162036;strokeColor=#3CC6D0;fontColor=#EEF2F8;fontSize=9;align=center;",
             x + 25, y + 92, 240, 48)
        cell(root, f"{pfx}_badge", "Local Impact Aggregator:\nActive Relay Node • DTN Store-and-Forward Worker",
             "rounded=1;fillColor=#162036;strokeColor=#FFD21F;fontColor=#FFD21F;fontSize=8;align=center;",
             x + 25, y + 150, 240, 32)
        kpis = [
            ("SELECT COUNT(*)", "People Helped", "#4CD08A"),
            ("SELECT COUNT(*)", "Packets Relayed", "#3CC6D0"),
            ("SELECT COUNT(*)", "SOS Forwarded", "#FF5A4E"),
            ("SELECT COUNT(*)", "Missing Matches", "#FFD21F")
        ]
        for idx, (num, lbl, col) in enumerate(kpis):
            row = idx // 2
            col_idx = idx % 2
            cell(root, f"{pfx}_kp{idx}", f"<b style='font-size:10px;color:{col};'>{num}</b><br/><span style='font-size:7px;color:#EEF2F8;'>{lbl}</span>",
                 f"rounded=1;fillColor=#162036;strokeColor={col};fontColor=#EEF2F8;align=center;",
                 x + 25 + col_idx * 125, y + 195 + row * 60, 115, 50)
        cell(root, f"{pfx}_edit", "Navigator.pushNamed('/edit_profile')",
             "rounded=1;fillColor=#162036;strokeColor=#3CC6D0;fontColor=#3CC6D0;fontSize=9;align=center;",
             x + 25, y + 360, 240, 38)
        cell(root, f"{pfx}_nav", "MainShell Navigation Shell",
             "rounded=0;fillColor=#162036;strokeColor=#26344F;fontColor=#EEF2F8;fontSize=8;align=center;",
             x + 10, y + 510, 270, 36)

# -------------------------------------------------------------
# BROWSER FRAME HELPER
# -------------------------------------------------------------
def draw_browser(root, pfx, x, y, w, h, title, url):
    """Draws a desktop browser wireframe window."""
    cell(root, f"{pfx}_win", "",
         "rounded=1;arcSize=4;whiteSpace=wrap;html=1;fillColor=#0B1220;strokeColor=#3A4C70;strokeWidth=2;shadow=1;",
         x, y, w, h)
    cell(root, f"{pfx}_tb", "",
         "rounded=1;arcSize=2;fillColor=#162036;strokeColor=#26344F;strokeWidth=1;",
         x, y, w, 40)
    cell(root, f"{pfx}_dot1", "", "ellipse;fillColor=#FF5F56;strokeColor=none;", x + 14, y + 14, 12, 12)
    cell(root, f"{pfx}_dot2", "", "ellipse;fillColor=#FFBD2E;strokeColor=none;", x + 32, y + 14, 12, 12)
    cell(root, f"{pfx}_dot3", "", "ellipse;fillColor=#27C93F;strokeColor=none;", x + 50, y + 14, 12, 12)
    cell(root, f"{pfx}_tab1", f"🛡️ {title}",
         "rounded=1;fillColor=#0E1627;strokeColor=#3CC6D0;strokeWidth=1;fontColor=#EEF2F8;fontSize=10;fontStyle=1;align=center;",
         x + 80, y + 8, 260, 32)
    cell(root, f"{pfx}_tab2", "🗺️ Tactical GIS Map",
         "rounded=1;fillColor=#162036;strokeColor=#26344F;strokeWidth=1;fontColor=#9FADC2;fontSize=10;align=center;",
         x + 350, y + 8, 170, 32)
    cell(root, f"{pfx}_tab3", "📡 Edge Uplink Spooler",
         "rounded=1;fillColor=#162036;strokeColor=#26344F;strokeWidth=1;fontColor=#9FADC2;fontSize=10;align=center;",
         x + 530, y + 8, 170, 32)
    cell(root, f"{pfx}_ab", "",
         "fillColor=#111A2C;strokeColor=#26344F;strokeWidth=1;",
         x, y + 40, w, 44)
    cell(root, f"{pfx}_nav", "◀   ▶   🔄",
         "text;html=1;strokeColor=none;fillColor=none;fontColor=#9FADC2;fontSize=12;align=center;",
         x + 10, y + 50, 70, 24)
    cell(root, f"{pfx}_url",
         f"🔒 {url}    (Connected to 14 Edge Gateways • Starlink Online)",
         "rounded=1;fillColor=#0E1627;strokeColor=#3CC6D0;strokeWidth=1;fontColor=#EEF2F8;fontSize=10;align=left;spacingLeft=10;",
         x + 90, y + 48, w - 210, 28)
    cell(root, f"{pfx}_usr", "👤 NDRF Cmd",
         "rounded=1;fillColor=#162036;strokeColor=#FFD21F;fontColor=#FFD21F;fontSize=9;fontStyle=1;align=center;",
         x + w - 105, y + 48, 90, 28)

# -------------------------------------------------------------
# DIAGRAM 1: COMPLETE MASTER ARCHITECTURE & WIREFRAME MAP
# -------------------------------------------------------------
def build_diagram_1(mxfile):
    root = add_diagram(mxfile, "master", "01 - Master Architecture & Wireframe Map", 5400, 3600)

    # Master Banner
    cell(root, "m_hdr", "", "rounded=1;fillColor=#162036;strokeColor=#FFD21F;strokeWidth=2;", 40, 30, 5320, 90)
    cell(root, "m_hdr_t",
         "<b>RAKSHANET (SIGNALRESCUE AI) — COMPLETE SOFTWARE ARCHITECTURE & WIREFRAME SPECIFICATION</b><br/>"
         "<span style='font-size:14px;color:#EEF2F8;'>Decentralized Offline BLE Mesh • DTN Store-Carry-Forward • Dynamic Reactive State Providers • SQLite Save-Before-Send • 14 Mobile Phone Frames • Command Center Web Dashboard</span>",
         "text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontSize=22;fontColor=#FFD21F;",
         60, 35, 5280, 80)

    # SECTION 1: 6-LAYER MOBILE SOFTWARE ARCHITECTURE WIREFRAME
    cell(root, "s1_box", "", "rounded=1;fillColor=#111A2C;strokeColor=#26344F;strokeWidth=2;", 40, 150, 1600, 1920)
    cell(root, "s1_title", "<b>1. SIX-LAYER MOBILE SOFTWARE ARCHITECTURE WIREFRAME (FLUTTER / DART 3)</b>",
         "text;html=1;strokeColor=none;fillColor=none;fontSize=18;fontColor=#FFD21F;", 60, 165, 800, 30)

    # LAYER 1: Presentation & UI
    cell(root, "l1_box", "", "rounded=1;fillColor=#162036;strokeColor=#FFD21F;strokeWidth=2;", 60, 210, 1560, 260)
    cell(root, "l1_lbl", "<b>LAYER 1: PRESENTATION & UI LAYER (Widget Tree & GoRouter State Machine)</b>",
         "text;html=1;strokeColor=none;fillColor=none;fontSize=14;fontColor=#FFD21F;", 80, 220, 700, 25)
    
    screen_names = [
        ("1. Splash", "u1", "#162036", "#FFD21F"),
        ("2. Onboard", "u2", "#162036", "#FFD21F"),
        ("2b. Profile Gate*", "u2b", "#D92D20", "#FFFFFF"),
        ("3. Home SOS", "u3", "#162036", "#FFD21F"),
        ("4. Emergency", "u4", "#162036", "#FFD21F"),
        ("5. Chat", "u5", "#162036", "#FFD21F"),
        ("6. Map", "u6", "#162036", "#FFD21F"),
        ("7. AI Assist", "u7", "#162036", "#FFD21F"),
        ("8. Missing", "u8", "#162036", "#FFD21F"),
        ("9. Shelters", "u9", "#162036", "#FFD21F"),
        ("10. Outbox", "u10", "#162036", "#FFD21F"),
        ("11. Tools", "u11", "#162036", "#FFD21F"),
        ("12. Settings", "u12", "#162036", "#FFD21F"),
        ("13. Profile", "u13", "#162036", "#FFD21F"),
    ]
    for idx, (sname, sid, bg, st) in enumerate(screen_names[:7]):
        cell(root, sid, sname, f"rounded=1;fillColor={bg};strokeColor={st};fontColor=#EEF2F8;fontSize=10;align=center;",
             80 + idx * 215, 255, 205, 35)
    for idx, (sname, sid, bg, st) in enumerate(screen_names[7:]):
        cell(root, sid, sname, f"rounded=1;fillColor={bg};strokeColor={st};fontColor=#EEF2F8;fontSize=10;align=center;",
             80 + idx * 215, 300, 205, 35)
    
    cell(root, "l1_sub", "<b>Navigator 2.0 / GoRouter State Machine:</b> Initial Route Guard (`ProfileProvider.isRegistered ? '/home' : '/profile_gate'`) • Modal Bottom Sheets • Strict Gate Lock<br/><b>Theme Tokens Engine:</b> Hi-Vis Safety Yellow (#FFD21F) • SOS Red (#D92D20) • Beacon Teal (#0E8A94) • Night Navy (#0B1220) • True OLED Black (#000000) • Min 48dp Targets • 56dp Primary Buttons",
         "rounded=1;fillColor=#0E1627;strokeColor=#3CC6D0;fontColor=#EEF2F8;fontSize=10;align=left;spacingLeft=10;",
         80, 350, 1520, 105)

    # LAYER 2: State Management
    cell(root, "l2_box", "", "rounded=1;fillColor=#162036;strokeColor=#3CC6D0;strokeWidth=2;", 60, 490, 1560, 180)
    cell(root, "l2_lbl", "<b>LAYER 2: STATE MANAGEMENT LAYER (ChangeNotifier Providers & Reactive State Contracts)</b>",
         "text;html=1;strokeColor=none;fillColor=none;fontSize=14;fontColor=#3CC6D0;", 80, 500, 750, 25)
    providers = [
        ("ProfileProvider", "Registration Gate & Anonymous Pseudonym (SR-XXXX-XXXX)\nLocal state cache & validation barrier"),
        ("MeshProvider", "BLE Peer Registry (12 active peers)\nRSSI Proximity Bands (Immediate/Near/Far) & Scanning loop"),
        ("ChatProvider", "Active Conversation Streams & Unread Badges\nMulti-Hop Delivery State Machine (Saved/Sent/Relayed/Delivered)"),
        ("ThemeProvider", "Real-Time Theme Switching\nDark Navy / Hi-Vis Light / True OLED Black (#000000)"),
        ("EmergencyProvider", "Distress Triggering & Threat Categorization\nHigh-priority binary envelope assembly & dispatch queue"),
        ("TelemetryProvider", "Battery % Drain Tracker & Dead-Reckoning GPS Fix\nAdaptive Radio Duty-Cycling Policy")
    ]
    for idx, (pname, pdesc) in enumerate(providers):
        col = idx % 3
        row = idx // 3
        cell(root, f"prv_{idx}", f"<b>{pname}</b><br/><span style='font-size:8px;color:#9FADC2;'>{pdesc}</span>",
             "rounded=1;fillColor=#0E1627;strokeColor=#3CC6D0;fontColor=#EEF2F8;fontSize=9;align=left;spacingLeft=8;",
             80 + col * 510, 530 + row * 65, 495, 58)

    # LAYER 3: Application & Domain Layer
    cell(root, "l3_box", "", "rounded=1;fillColor=#162036;strokeColor=#4CD08A;strokeWidth=2;", 60, 690, 1560, 180)
    cell(root, "l3_lbl", "<b>LAYER 3: APPLICATION & DOMAIN SERVICES LAYER (Offline Intelligence & Transaction Dispatcher)</b>",
         "text;html=1;strokeColor=none;fillColor=none;fontSize=14;fontColor=#4CD08A;", 80, 700, 800, 25)
    services = [
        ("ChatService (Save-Before-Send)", "Executes SQLite write transaction BEFORE triggering radio broadcast. Guarantees zero message loss during battery drain or crash. Listens for ACK receipts."),
        ("AIAssistantService (Offline Rules)", "Deterministic rule-based disaster triage heuristic. Pattern matches user prompts against bundled offline knowledge base (water purification, wounds, flood survival). Zero cloud dependency."),
        ("LocationService (GPS & Dead-Reckon)", "Streams hardware GPS coordinates. Computes dead-reckoning cache and Euclidean distances to nearby reported incident pins without map tiles."),
        ("TelemetryService (Power Monitor)", "Monitors battery level. Dynamically switches BLE scanning duty cycles (e.g. 2s scan every 60s when battery < 20%) to prolong survivor node life.")
    ]
    for idx, (sname, sdesc) in enumerate(services):
        cell(root, f"srv_{idx}", f"<b>{sname}</b><br/><span style='font-size:8px;color:#EEF2F8;'>{sdesc}</span>",
             "rounded=1;fillColor=#0E1627;strokeColor=#4CD08A;fontColor=#EEF2F8;fontSize=9;align=left;spacingLeft=8;",
             80 + idx * 380, 730, 365, 125)

    # LAYER 4: DTN Mesh Protocol Engine
    cell(root, "l4_box", "", "rounded=1;fillColor=#162036;strokeColor=#FF5A4E;strokeWidth=2;", 60, 890, 1560, 260)
    cell(root, "l4_lbl", "<b>LAYER 4: DTN MESH PROTOCOL ENGINE (Kabootar & MeshChat Pattern: Store-and-Forward Routing)</b>",
         "text;html=1;strokeColor=none;fillColor=none;fontSize=14;fontColor=#FF5A4E;", 80, 900, 850, 25)
    dtn_engines = [
        ("Binary Envelope Builder", "Encapsulates messages into bounded byte envelopes (<512B MTU): UUID (16B), Sender ID (8B), Timestamp (8B), Type (1B), TTL (1B), Hops (1B), GPS (16B), Checksum (4B)."),
        ("Bloom Filter Deduplication", "10,000-bit rotating in-memory Bloom filter for O(1) loop suppression. Backed by SQLite secondary index. Drops seen packet hashes silently, preventing storms."),
        ("Outbox Store-and-Forward Queue", "Persistent outgoing spool table in SQLite. Implements priority sorting: P1 (SOS) > P2 (Missing) > P3 (Chat). Exponential backoff retry with random jitter."),
        ("Epidemic Carry-and-Forward Router", "Opportunistic gossip protocol. Relays packets whenever an uncontacted peer enters BLE radio range (~80m). Physical pedestrian motion bridges network partitions."),
        ("TTL Decrement Guard (Blast Limiter)", "Decrements TTL by 1 at each hop (TTL - 1). If TTL <= 1, envelope is retained in local SQLite for user reading, but strictly HALTED from re-broadcasting over radio."),
        ("Multi-Hop ACK Tracker", "Reverse path receipt tracking. When a packet reaches an Edge Gateway or destination, an ACK envelope (Type 0x05) flows back, upgrading SQLite status to 'DELIVERED'.")
    ]
    for idx, (ename, edesc) in enumerate(dtn_engines):
        col = idx % 3
        row = idx // 3
        cell(root, f"dtn_{idx}", f"<b>{ename}</b><br/><span style='font-size:8px;color:#EEF2F8;'>{edesc}</span>",
             "rounded=1;fillColor=#0E1627;strokeColor=#FF5A4E;fontColor=#EEF2F8;fontSize=9;align=left;spacingLeft=8;",
             80 + col * 510, 930 + row * 105, 495, 95)

    # LAYER 5: Local Persistence Engine (SQLite)
    cell(root, "l5_box", "", "rounded=1;fillColor=#162036;strokeColor=#FFA033;strokeWidth=2;", 60, 1170, 1560, 260)
    cell(root, "l5_lbl", "<b>LAYER 5: LOCAL PERSISTENCE ENGINE (SQLite Database - app_database.db & Repositories)</b>",
         "text;html=1;strokeColor=none;fillColor=none;fontSize=14;fontColor=#FFA033;", 80, 1180, 850, 25)
    tables = [
        ("user_profile", "id TEXT PRIMARY KEY\nfull_name TEXT\nblood_group TEXT\ncontact_phone TEXT\nlanguage TEXT\ncreated_at INTEGER"),
        ("messages & outbox", "message_id TEXT PRIMARY KEY\nconversation_id TEXT\nsender_id TEXT\ncontent TEXT\nstatus TEXT (SAVED/DELIVERED)\nttl INT, hops INT, ts INT"),
        ("nearby_devices", "device_id TEXT PRIMARY KEY\ndisplay_name TEXT\nrssi INTEGER\nsignal_band TEXT\nlast_seen INTEGER\nrelay_capable INT"),
        ("emergency_reports", "report_id TEXT PRIMARY KEY\ntype TEXT (medical, trapped)\nlatitude REAL, longitude REAL\ndescription TEXT\nstatus TEXT, created_at INT"),
        ("shelters & resources", "id TEXT PRIMARY KEY\nname TEXT, address TEXT\nlatitude REAL, longitude REAL\ncapacity INT, occupancy INT\nsupplies_json TEXT, open INT"),
        ("missing_persons", "id TEXT PRIMARY KEY\nfull_name TEXT, age INT\ngender TEXT, clothing TEXT\nlast_seen_loc TEXT, ts INT\nphotos_blob_json TEXT")
    ]
    for idx, (tname, tcols) in enumerate(tables):
        col = idx % 6
        cell(root, f"tbl_{idx}", f"<b>{tname}</b><br/><span style='font-size:7px;color:#9FADC2;'>{tcols.replace(chr(10), '<br/>')}</span>",
             "shape=cylinder;whiteSpace=wrap;html=1;boundedLbl=1;backgroundOutline=1;size=10;fillColor=#0E1627;strokeColor=#FFA033;fontColor=#EEF2F8;fontSize=8;align=left;spacingLeft=6;",
             80 + col * 255, 1210, 245, 115)
    cell(root, "l5_daos", "<b>Data Access Objects (Repositories):</b> `ProfileRepository` • `ChatRepository` • `DeviceRepository` • `ReportRepository` • `ShelterRepository`<br/><b>Save-Before-Send Write Barrier:</b> `db.transaction((txn) => txn.insert('messages', envelope.toMap()))` must commit to NAND flash before BLE radio transmits.",
         "rounded=1;fillColor=#0E1627;strokeColor=#FFA033;fontColor=#EEF2F8;fontSize=9;align=left;spacingLeft=10;",
         80, 1340, 1520, 75)

    # LAYER 6: Hardware Abstraction & OS Platform Layer
    cell(root, "l6_box", "", "rounded=1;fillColor=#162036;strokeColor=#9FADC2;strokeWidth=2;", 60, 1450, 1560, 180)
    cell(root, "l6_lbl", "<b>LAYER 6: HARDWARE ABSTRACTION & OS PLATFORM LAYER (Zero Internet Transceivers & Display Power HAL)</b>",
         "text;html=1;strokeColor=none;fillColor=none;fontSize=14;fontColor=#9FADC2;", 80, 1460, 900, 25)
    hal_items = [
        ("BLE GATT Server (Peripheral)", "Broadcasts service UUID 0xFD6F / RakshaNet. Duty-cycled advertising (200ms active / 800ms sleep). Encapsulates envelopes in manufacturer data."),
        ("BLE GATT Client (Central)", "Continuous background scanning for peer advertisements. Computes RSSI proximity bands (Immediate < -50dBm, Near < -70dBm, Far < -85dBm)."),
        ("Wi-Fi Direct / Nearby Service", "High-throughput peer-to-peer fallback. Triggered opportunistically for syncing missing-person photo attachments and large relief inventories."),
        ("AMOLED Subpixel Black Controller", "Hardware display power optimization: renders True #000000 black, shutting down physical OLED subpixels. Cuts display battery draw by 62% in emergency mode.")
    ]
    for idx, (hname, hdesc) in enumerate(hal_items):
        cell(root, f"hal_{idx}", f"<b>{hname}</b><br/><span style='font-size:8px;color:#EEF2F8;'>{hdesc}</span>",
             "rounded=1;fillColor=#0E1627;strokeColor=#9FADC2;fontColor=#EEF2F8;fontSize=9;align=left;spacingLeft=8;",
             80 + idx * 380, 1490, 365, 125)

    edge(root, "e_l1_l2", "UI events / State subscriptions", "strokeColor=#FFD21F;strokeWidth=2;", "l1_box", "l2_box")
    edge(root, "e_l2_l3", "Provider delegates to Domain Services", "strokeColor=#3CC6D0;strokeWidth=2;", "l2_box", "l3_box")
    edge(root, "e_l3_l4", "Envelope Builder & Relay Enqueue", "strokeColor=#4CD08A;strokeWidth=2;", "l3_box", "l4_box")
    edge(root, "e_l4_l5", "Save-Before-Send Flash Commit", "strokeColor=#FF5A4E;strokeWidth=2;", "l4_box", "l5_box")
    edge(root, "e_l5_l6", "Hardware Radio Transmission", "strokeColor=#FFA033;strokeWidth=2;", "l5_box", "l6_box")

    # SECTION 2: EDGE GATEWAY & TACTICAL CONVOY SOFTWARE ARCHITECTURE
    cell(root, "s2_box", "", "rounded=1;fillColor=#111A2C;strokeColor=#26344F;strokeWidth=2;", 1660, 150, 1720, 840)
    cell(root, "s2_title", "<b>2. FIELD RESCUE EDGE GATEWAY & TACTICAL CONVOY SOFTWARE ARCHITECTURE</b>",
         "text;html=1;strokeColor=none;fillColor=none;fontSize=18;fontColor=#FFA033;", 1680, 165, 900, 30)
    
    gw_modules = [
        ("Headless Linux Rescue Daemon", "`rakshanet-gateway.service`\nC++ / Python / Go headless engine running on tactical Raspberry Pi / vehicle computers.\nCoordinates ingestion, deduplication, and hybrid backhaul uplink spooling.", "#FFA033"),
        ("Tactical High-Gain BLE Sink", "Omnidirectional antenna array (+12 dBi gain).\nSimultaneously scans and ingests survivor envelopes from passing pedestrian nodes within 150m.\nIssues multi-hop ACK packets back to the ground mesh.", "#FFA033"),
        ("DTN Edge Spool Buffer (Embedded RocksDB)", "Embedded persistent store for hundreds of thousands of envelopes.\nPrioritizes P1 (SOS) over P4 (Chat).\nTracks hop latencies, spatial vectors, and survivor cluster densities.", "#FFA033"),
        ("Hybrid Backhaul Uplink Spooler", "Multi-WAN failover logic:\n1. Starlink / Satellite Transceiver (Primary remote link)\n2. 4G/5G Tactical Private LTE (Auto-switching)\n3. VHF / LoRa Long-Distance Radio (Ultra-low bandwidth fallback)", "#FFA033"),
        ("Bidirectional Federal Sync Controller", "Secure HTTPS / WSS uplink to FastAPI Command Hub.\nFlushes survivor outbox envelopes to Cloud.\nIngests NDMA CAP XML alerts from Cloud and injects them downward into ground BLE mesh.", "#FFA033")
    ]
    for idx, (gname, gdesc, gcol) in enumerate(gw_modules):
        col = idx % 3
        row = idx // 3
        cell(root, f"gw_{idx}", f"<b>{gname}</b><br/><span style='font-size:8px;color:#EEF2F8;'>{gdesc.replace(chr(10), '<br/>')}</span>",
             f"rounded=1;fillColor=#162036;strokeColor={gcol};fontColor=#EEF2F8;fontSize=9;align=left;spacingLeft=8;",
             1680 + col * 565, 210 + row * 130, 550, 120)

    edge(root, "e_gw_sink", "BLE Air Packets", "strokeColor=#FFD21F;strokeWidth=2;", "gw_1", "gw_0")
    edge(root, "e_gw_buf", "Spool Envelopes", "strokeColor=#FFA033;strokeWidth=2;", "gw_0", "gw_2")
    edge(root, "e_gw_up", "Multi-WAN Route", "strokeColor=#4CD08A;strokeWidth=2;", "gw_2", "gw_3")
    edge(root, "e_gw_sync", "Bidirectional Bridge", "strokeColor=#3CC6D0;strokeWidth=2;", "gw_3", "gw_4")

    # SECTION 3: COMMAND CENTER CLOUD SOFTWARE ARCHITECTURE
    cell(root, "s3_box", "", "rounded=1;fillColor=#111A2C;strokeColor=#26344F;strokeWidth=2;", 1660, 520, 1720, 470)
    cell(root, "s3_title", "<b>3. COMMAND CENTER CLOUD & NATIONAL DISASTER MANAGEMENT ARCHITECTURE</b>",
         "text;html=1;strokeColor=none;fillColor=none;fontSize=18;fontColor=#4CD08A;", 1680, 535, 900, 30)

    cloud_modules = [
        ("FastAPI Microservices Hub", "REST Ingestion (`/api/v1/mesh/sync`)\nWebSocket Broadcast Hub (`/ws/live-incidents`)\nJWT Auth, Rate Limiter, and Signature Verifier", "#4CD08A"),
        ("Explainable AI Triage Engine", "Multi-Factor Triage Scoring:\n`Score = w1*Crush + w2*WaterRise + w3*Battery`\nOutputs severity (P1-P4), confidence score (e.g. 96%), and human-readable explanation accordion.", "#FF5A4E"),
        ("PostgreSQL 15 + PostGIS Spatial Engine", "Spatial Incident Heatmaps & Voronoi Partitions\nMulti-Hop Graph Dijkstra Shortest Path Tracer\nRelief Camp Resource Registry & GeoJSON Stream", "#4CD08A"),
        ("Redis Pub/Sub & Celery Spool", "High-throughput asynchronous envelope broker.\nDispatches real-time incident notifications to connected dashboard clients and field drones.", "#D92D20"),
        ("NDMA / SDMA CAP XML Gateway", "OASIS Common Alerting Protocol (CAP v1.2) XML Bridge.\nBidirectional interoperability with national Indian disaster management agencies and federal relief forces.", "#FFD21F")
    ]
    for idx, (cname, cdesc, ccol) in enumerate(cloud_modules):
        cell(root, f"cld_{idx}", f"<b>{cname}</b><br/><span style='font-size:8px;color:#EEF2F8;'>{cdesc.replace(chr(10), '<br/>')}</span>",
             f"rounded=1;fillColor=#162036;strokeColor={ccol};fontColor=#EEF2F8;fontSize=9;align=left;spacingLeft=8;",
             1680 + idx * 340, 580, 325, 140)

    edge(root, "e_gw_cloud", "WSS / HTTPS Ingestion", "strokeColor=#4CD08A;strokeWidth=3;", "gw_4", "cld_0")

    # SECTION 4: DESKTOP BROWSER FRAME WIREFRAME (COMMAND CENTER DASHBOARD)
    cell(root, "s4_box", "", "rounded=1;fillColor=#111A2C;strokeColor=#26344F;strokeWidth=2;", 1660, 1020, 1720, 1050)
    cell(root, "s4_title", "<b>4. COMMAND CENTER DESKTOP BROWSER WIREFRAME (REACT / VITE / LEAFLET GIS)</b>",
         "text;html=1;strokeColor=none;fillColor=none;fontSize=18;fontColor=#3CC6D0;", 1680, 1035, 900, 30)

    draw_browser(root, "brw", 1680, 1080, 1680, 960, "RakshaNet NDMA Command Center Hub", "https://command.rakshanet.gov.in/triage")

    cell(root, "w_stat",
         "🚨 Active P1 SOS Beacons: 4   •   👥 Persons in Distress: 18   •   🚙 Field Convoy Units: 6   •   🏕️ Open Shelters: 12 (64% Capacity)   •   📡 14 Edge Gateways Connected   •   🏛️ NDMA CAP Live",
         "rounded=1;fillColor=#162036;strokeColor=#3CC6D0;fontColor=#EEF2F8;fontSize=9;align=center;",
         1695, 1175, 1650, 32)

    cell(root, "w_map_box", "", "rounded=1;fillColor=#0E1627;strokeColor=#26344F;strokeWidth=1;", 1695, 1215, 650, 770)
    cell(root, "w_map_lbl", "<b>Leaflet Tactical GIS Map Canvas (`L.geoJSON()`)</b><br/><span style='font-size:8px;color:#9FADC2;'>Layers: [Contour Topo] [Flood Extent] [BLE Mesh Hops] [Drone Corridors]</span>",
         "text;html=1;fontColor=#FFD21F;fontSize=10;align=left;", 1705, 1225, 450, 25)
    
    cell(root, "w_m_sos1", "🔴 P1: Amit (Trapped)\nLat: 19.076, Lon: 72.877",
         "ellipse;fillColor=#D92D20;strokeColor=#FF5A4E;strokeWidth=2;fontColor=#FFFFFF;fontSize=8;align=center;",
         1730, 1280, 140, 70)
    cell(root, "w_m_p1", "🟡 Peer Node B\n(Hop 1 Relay)",
         "ellipse;fillColor=#162036;strokeColor=#FFD21F;strokeWidth=1;fontColor=#FFD21F;fontSize=7;align=center;",
         1920, 1310, 100, 50)
    cell(root, "w_m_p2", "🟡 Peer Node C\n(Hop 2 Relay)",
         "ellipse;fillColor=#162036;strokeColor=#FFD21F;strokeWidth=1;fontColor=#FFD21F;fontSize=7;align=center;",
         2070, 1370, 100, 50)
    cell(root, "w_m_gw", "🚙 NDRF Convoy 01\n(BLE Sink Gateway)",
         "ellipse;fillColor=#162036;strokeColor=#4CD08A;strokeWidth=2;fontColor=#4CD08A;fontSize=8;align=center;",
         2200, 1450, 130, 60)
    edge(root, "w_hop_1", "BLE Hop 1 (~80m)", "dashed=1;strokeColor=#3CC6D0;strokeWidth=2;fontSize=8;fontColor=#3CC6D0;", "w_m_sos1", "w_m_p1")
    edge(root, "w_hop_2", "BLE Hop 2", "dashed=1;strokeColor=#3CC6D0;strokeWidth=2;fontSize=8;fontColor=#3CC6D0;", "w_m_p1", "w_m_p2")
    edge(root, "w_hop_3", "Uplink Ingestion", "dashed=1;strokeColor=#4CD08A;strokeWidth=2;fontSize=8;fontColor=#4CD08A;", "w_m_p2", "w_m_gw")
    
    cell(root, "w_m_sos2", "🔴 P2: Primary School (120 Stranded)\nLat: 19.082, Lon: 72.891",
         "ellipse;fillColor=#D92D20;strokeColor=#FF5A4E;strokeWidth=2;fontColor=#FFFFFF;fontSize=8;align=center;",
         1750, 1470, 160, 70)
    cell(root, "w_m_drone", "✈️ Drone Alpha Corridor\nThermal Search Active",
         "rounded=1;fillColor=#162036;strokeColor=#3CC6D0;fontColor=#3CC6D0;fontSize=8;align=center;",
         1850, 1590, 150, 40)
    cell(root, "w_m_clus", "📍 8 Peer Devices Active in 300m Sector",
         "rounded=1;fillColor=#162036;strokeColor=#FFD21F;fontColor=#FFD21F;fontSize=8;align=center;",
         2050, 1590, 180, 40)

    cell(root, "w_triage_box", "", "rounded=1;fillColor=#0E1627;strokeColor=#26344F;strokeWidth=1;", 2355, 1215, 570, 770)
    cell(root, "w_triage_lbl", "<b>Explainable AI Live Incident Triage Stream (`WebSocket /ws/live`)</b>",
         "text;html=1;fontColor=#FF5A4E;fontSize=10;align=left;", 2365, 1225, 450, 25)
    
    cell(root, "w_card_p1",
         "<b>🚨 P1 CRITICAL Distress (AI Score: 98/100)</b><br/>"
         "<b>Victim:</b> Amit Sharma (ID: SR-284739)  •  <b>Blood:</b> O+  •  <b>Contact:</b> +91 98765 43210<br/>"
         "<b>Path:</b> 3 BLE hops via Pedestrian Relay  •  <b>Battery:</b> 12%  •  <b>GPS Acc:</b> ±6m<br/>"
         "<hr/>"
         "<b>🤖 Explainable AI Reasoning (Confidence: 96.4%):</b><br/>"
         "• Severe crush injury / trapped under concrete beam (Weight: 0.45)<br/>"
         "• Rapidly rising floodwaters detected (0.35m/hr) (Weight: 0.35)<br/>"
         "• Critical device battery drain (< 15%) (Weight: 0.20)<br/>"
         "<b>Recommended Action:</b> Immediate NDRF Boat / Heavy Extrication Dispatch",
         "rounded=1;fillColor=#162036;strokeColor=#D92D20;strokeWidth=2;fontColor=#EEF2F8;fontSize=9;align=left;spacingLeft=8;",
         2365, 1255, 550, 165)
    cell(root, "w_btn_disp", "🚨 Dispatch NDRF Team 3", "rounded=1;fillColor=#D92D20;fontColor=#FFFFFF;fontStyle=1;fontSize=9;align=center;", 2375, 1428, 170, 28)
    cell(root, "w_btn_ack", "📡 Send Mesh ACK Packet", "rounded=1;fillColor=#0E8A94;fontColor=#FFFFFF;fontStyle=1;fontSize=9;align=center;", 2555, 1428, 170, 28)
    cell(root, "w_btn_sat", "🛰️ Satellite SMS Relay", "rounded=1;fillColor=#162036;strokeColor=#FFD21F;fontColor=#FFD21F;fontSize=9;align=center;", 2735, 1428, 160, 28)

    cell(root, "w_card_p2",
         "<b>🟠 P2 SEVERE Cluster (AI Score: 84/100)</b><br/>"
         "<b>Location:</b> Primary Senior High School Relief Point (Lat: 19.082, Lon: 72.891)<br/>"
         "<b>Casualties:</b> 120 Stranded Individuals  •  Clean Water Depleted<br/>"
         "<hr/>"
         "<b>🤖 Explainable AI Reasoning:</b> Population cut off by bridge structural collapse.<br/>"
         "<b>Recommended Action:</b> Route supply boat with water purification kits.",
         "rounded=1;fillColor=#162036;strokeColor=#FFA033;strokeWidth=1;fontColor=#EEF2F8;fontSize=9;align=left;spacingLeft=8;",
         2365, 1470, 550, 120)

    cell(root, "w_card_p3",
         "<b>🟡 P3 MODERATE Bulletin (AI Score: 62/100)</b><br/>"
         "<b>Subject:</b> Missing Child: Rohan Kumar (12y)  •  Last Seen: River Bridge<br/>"
         "<b>Cross-Reference:</b> AI face recognition matched child photo at Shelter #2 (92% match).",
         "rounded=1;fillColor=#162036;strokeColor=#FFD21F;strokeWidth=1;fontColor=#EEF2F8;fontSize=9;align=left;spacingLeft=8;",
         2365, 1605, 550, 95)

    cell(root, "w_ops_box", "", "rounded=1;fillColor=#0E1627;strokeColor=#26344F;strokeWidth=1;", 2935, 1215, 410, 770)
    cell(root, "w_ops_lbl", "<b>Tactical Operations & NDMA Gateway Matrix</b>",
         "text;html=1;fontColor=#4CD08A;fontSize=10;align=left;", 2945, 1225, 380, 25)
    
    cell(root, "w_ops_units",
         "<b>Field Units Live Telemetry:</b><br/>"
         "• NDRF Unit 1: Deployed (Zone Alpha)<br/>"
         "• NDRF Unit 2: En Route (Zone Beta)<br/>"
         "• Boat Team 3: Evacuating School<br/>"
         "• Drone Alpha: Scanning Corridor 4<br/>"
         "• Drone Beta: Standby (Battery 95%)",
         "rounded=1;fillColor=#162036;strokeColor=#4CD08A;fontColor=#EEF2F8;fontSize=8;align=left;spacingLeft=6;",
         2945, 1255, 390, 95)

    cell(root, "w_ops_shelters",
         "<b>Relief Shelters Capacity Status:</b><br/>"
         "• Village Senior School: 120/200 (60%) 🟢<br/>"
         "• Community Center: 190/200 (95%) 🟠 FULL<br/>"
         "• Primary Health Center: 45/50 (90%) 🔴 TRIAGE",
         "rounded=1;fillColor=#162036;strokeColor=#FFA033;fontColor=#EEF2F8;fontSize=8;align=left;spacingLeft=6;",
         2945, 1360, 390, 85)

    cell(root, "w_ops_cap",
         "<b>NDMA CAP XML v1.2 Protocol Feed:</b><br/>"
         "`[12:48:15] INGEST: CAP Alert #NDMA-MH-04`<br/>"
         "`[12:49:02] BROADCAST: 3 SOS to Federal Grid`<br/>"
         "`[12:50:33] ACK SYNC: 14 Packets confirmed`<br/>"
         "<b>Backhaul:</b> Starlink Dish (48 Mbps, Latency: 38ms)",
         "rounded=1;fillColor=#162036;strokeColor=#FFD21F;fontColor=#EEF2F8;fontSize=8;align=left;spacingLeft=6;",
         2945, 1455, 390, 95)

    # SECTION 5: DTN MESH PROTOCOL & 4-PHONE 3-HOP SIMULATION
    cell(root, "s5_box", "", "rounded=1;fillColor=#111A2C;strokeColor=#26344F;strokeWidth=2;", 40, 2090, 3340, 950)
    cell(root, "s5_title", "<b>5. DELAY-TOLERANT MESH PROTOCOL ENGINE & 4-PHONE 3-HOP STORE-AND-FORWARD TOPOLOGY SIMULATION</b>",
         "text;html=1;strokeColor=none;fillColor=none;fontSize=18;fontColor=#FF5A4E;", 60, 2105, 1200, 30)

    sim_phones = [
        ("PHONE A (Victim Trapped)", "Creates SOS Beacon `MSG-001`\nSave-Before-Send: Committed to SQLite\nTTL = 5 | Hop Count = 0\nBroadcasts BLE GATT Advertisement (~80m)", "#D92D20", 80),
        ("PHONE B (Pedestrian Relay)", "Receives MSG-001 via BLE Scanner\nDedup Check: Hash not seen in Bloom filter\nStored into local SQLite\nDecrements TTL = 4 | Increments Hops = 1\nPhysical movement carries packet across sector", "#3CC6D0", 680),
        ("PHONE C (Shelter Volunteer)", "Encounter sync with Phone B\nReceives MSG-001 • Ingested into SQLite\nDecrements TTL = 3 | Increments Hops = 2\nDisplays SOS in Community Chat\nRelays to outbound rescue vehicle", "#3CC6D0", 1280),
        ("PHONE D (Border Gateway Node)", "Receives MSG-001 from volunteer vehicle\nTTL = 2 | Hop Count = 3\nEnters radio range of NDRF Rescue Convoy Gateway\nTriggers high-speed batch sync\nReceives Reverse ACK Packet", "#4CD08A", 1880)
    ]
    for idx, (pname, pdesc, pcol, px) in enumerate(sim_phones):
        cell(root, f"sim_ph_{idx}", f"<b>{pname}</b><br/><hr/><span style='font-size:9px;color:#EEF2F8;'>{pdesc.replace(chr(10), '<br/>')}</span>",
             f"rounded=1;fillColor=#162036;strokeColor={pcol};strokeWidth=2;fontColor=#EEF2F8;fontSize=11;align=left;spacingLeft=8;",
             px, 2150, 480, 200)

    edge(root, "e_hop_ab", "BLE Hop 1 (~80m)\nRange: Radio Encounter", "strokeColor=#3CC6D0;strokeWidth=2;fontSize=9;fontColor=#3CC6D0;", "sim_ph_0", "sim_ph_1")
    edge(root, "e_hop_bc", "BLE Hop 2\nStore-Carry-Forward", "strokeColor=#3CC6D0;strokeWidth=2;fontSize=9;fontColor=#3CC6D0;", "sim_ph_1", "sim_ph_2")
    edge(root, "e_hop_cd", "BLE Hop 3\nBorder Encounter", "strokeColor=#3CC6D0;strokeWidth=2;fontSize=9;fontColor=#3CC6D0;", "sim_ph_2", "sim_ph_3")
    edge(root, "e_hop_dg", "Uplink to Tactical Gateway Convoy", "strokeColor=#4CD08A;strokeWidth=3;fontSize=10;fontColor=#4CD08A;", "sim_ph_3", "gw_1")

    # Binary Envelope Layout Box
    cell(root, "env_box", "", "rounded=1;fillColor=#0E1627;strokeColor=#FFD21F;strokeWidth=1;", 80, 2380, 1600, 280)
    cell(root, "env_title", "<b>DTN Binary Envelope Specification (Wire Format & MTU Packing < 512 Bytes)</b>",
         "text;html=1;fontColor=#FFD21F;fontSize=12;align=left;", 100, 2390, 600, 25)
    env_fields = [
        ("UUID (16 Bytes)", "Globally Unique Envelope ID v4"),
        ("Sender ID (8 Bytes)", "Pseudonymous Token (e.g. `SR-284739`)"),
        ("Timestamp (8 Bytes)", "Monotonic Origin Unix ms"),
        ("Packet Type (1 Byte)", "0x01: SOS | 0x02: Chat | 0x03: Missing"),
        ("TTL (1 Byte)", "Default=5, Decremented at each hop"),
        ("Hop Count (1 Byte)", "Default=0, Incremented at each hop"),
        ("Latitude (8 Bytes)", "IEEE 754 64-bit Float GPS Fix"),
        ("Longitude (8 Bytes)", "IEEE 754 64-bit Float GPS Fix"),
        ("Payload Len (2 Bytes)", "Compressed Body Byte Count"),
        ("Payload (Var <= 450B)", "Compressed JSON / CBOR Message Data"),
        ("Checksum (4 Bytes)", "CRC32 Frame Integrity Check")
    ]
    for idx, (fname, fdesc) in enumerate(env_fields):
        col = idx % 4
        row = idx // 4
        cell(root, f"efld_{idx}", f"<b>{fname}</b><br/><span style='font-size:7px;color:#9FADC2;'>{fdesc}</span>",
             "rounded=1;fillColor=#162036;strokeColor=#26344F;fontColor=#EEF2F8;fontSize=8;align=left;spacingLeft=6;",
             100 + col * 390, 2420 + row * 65, 375, 55)

    # Save-Before-Send Flowchart Box
    cell(root, "sbs_box", "", "rounded=1;fillColor=#0E1627;strokeColor=#4CD08A;strokeWidth=1;", 1700, 2380, 1600, 280)
    cell(root, "sbs_title", "<b>Save-Before-Send Transaction State Pipeline & Bloom Filter Loop Guard</b>",
         "text;html=1;fontColor=#4CD08A;fontSize=12;align=left;", 1720, 2390, 600, 25)
    sbs_steps = [
        ("1. User Tap SOS", "UI triggers dispatch action", "#FFD21F"),
        ("2. SQLite INSERT", "status='SAVED' to flash memory", "#4CD08A"),
        ("3. BLE Broadcast", "Packet emitted over air", "#3CC6D0"),
        ("4. Peer Dedup Check", "Bloom Filter seen? Drop! Else save.", "#FF5A4E"),
        ("5. TTL Guard", "TTL > 1 ? Forward : Halt radio", "#FFA033"),
        ("6. Cloud Delivery", "Gateway upload -> status='DELIVERED'", "#4CD08A")
    ]
    for idx, (stitle, ssub, scol) in enumerate(sbs_steps):
        cell(root, f"sbs_{idx}", f"<b>{stitle}</b><br/><span style='font-size:8px;color:#EEF2F8;'>{ssub}</span>",
             f"rounded=1;fillColor=#162036;strokeColor={scol};fontColor=#EEF2F8;fontSize=9;align=center;",
             1720 + idx * 260, 2435, 240, 65)
        if idx > 0:
            edge(root, f"e_sbs_{idx}", "", "strokeColor=#3CC6D0;strokeWidth=2;", f"sbs_{idx-1}", f"sbs_{idx}")

    cell(root, "sbs_expl",
         "<b>Zero Data Loss Guarantee:</b> If a device runs out of battery or reboots immediately after pressing Send SOS, the envelope is safely stored in local SQLite flash memory. As soon as the device reboots or another node comes in range, the opportunistic mesh outbox resumes relaying without data loss.",
         "rounded=1;fillColor=#162036;strokeColor=#26344F;fontColor=#EEF2F8;fontSize=9;align=left;spacingLeft=8;",
         1720, 2520, 1540, 45)

    # SECTION 6: MOBILE PHONE FRAME GALLERY (14 SCREENS)
    cell(root, "s6_box", "", "rounded=1;fillColor=#111A2C;strokeColor=#26344F;strokeWidth=2;", 3400, 150, 1960, 2890)
    cell(root, "s6_title", "<b>6. MOBILE PHONE FRAME WIREFRAME GALLERY (14 SCREENS IN REALISTIC BEZELS)</b>",
         "text;html=1;strokeColor=none;fillColor=none;fontSize=18;fontColor=#FFD21F;", 3420, 165, 900, 30)

    all_screens = [
        ("1", "Splash Screen", "Animated Beacon & Gate Router"),
        ("2", "Onboarding Guide", "Decentralized Mesh Principles"),
        ("2b", "Profile Gate*", "Mandatory Identity Setup"),
        ("3", "Home SOS Main", "3s Hold Beacon & Telemetry"),
        ("4", "Emergency Report", "Categorized Distress Dispatch"),
        ("5", "Offline Mesh Chat", "P2P Community Stream"),
        ("6", "Live Mesh Map", "Vector Topological Canvas"),
        ("7", "AI Survival Assist", "Offline On-Device Rules"),
        ("8", "Report Missing", "Bulletin Form & Photos"),
        ("9", "Relief Shelters", "Real-Time Resource Gauges"),
        ("10", "My Outbox Queue", "Store-and-Forward Spool"),
        ("11", "Safety Tools", "2x3 Emergency Utilities"),
        ("12", "Settings (OLED)", "AMOLED Subpixel Black #000000"),
        ("13", "Responder Profile", "2x2 Community Impact KPIs")
    ]
    for idx, (snum, stitle, ssub) in enumerate(all_screens):
        col = idx // 7
        row = idx % 7
        px = 3440 + col * 950
        py = 210 + row * 380
        draw_phone_frame(root, f"m_ph_{snum}", px, py, stitle, snum, ssub, is_oled=(snum == "12"))
        populate_screen_dynamic(root, f"m_ph_{snum}", px, py, snum)

# -------------------------------------------------------------
# DIAGRAM 2: 6-LAYER MOBILE SOFTWARE ARCHITECTURE DEEP DIVE
# -------------------------------------------------------------
def build_diagram_2(mxfile):
    root = add_diagram(mxfile, "layers", "02 - 6-Layer Mobile Software Architecture", 3400, 2600)

    # Banner
    cell(root, "d2_hdr", "", "rounded=1;fillColor=#162036;strokeColor=#FFD21F;strokeWidth=2;", 40, 30, 3320, 90)
    cell(root, "d2_hdr_t",
         "<b>FLUTTER MOBILE CLIENT — SIX-LAYER SOFTWARE ARCHITECTURE SPECIFICATION</b><br/>"
         "<span style='font-size:14px;color:#EEF2F8;'>Kabootar & MeshChat Design Pattern • Dynamic Reactive State Contracts • Save-Before-Send Transaction Barrier • Local Persistence Engine</span>",
         "text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontSize=22;fontColor=#FFD21F;",
         60, 35, 3280, 80)

    # 4 DYNAMIC DATA FLOW LANES AT THE TOP
    cell(root, "d2_flow_box", "", "rounded=1;fillColor=#111A2C;strokeColor=#26344F;strokeWidth=2;", 40, 150, 3320, 160)
    cell(root, "d2_flow_title", "<b>CRITICAL DYNAMIC DATA FLOW PATTERNS (NO HARDCODED DATA):</b>",
         "text;html=1;strokeColor=none;fillColor=none;fontSize=14;fontColor=#FFD21F;", 60, 160, 800, 25)
    
    flow_lanes = [
        ("Flow 1: User Input ➔ SQLite Persistence",
         "`TextEditingController` / `Dropdown` ➔ `ProfileProvider.saveProfile()` ➔ `ProfileRepository.insertProfile()` ➔ SQLite `user_profile` table (Flash Commit) ➔ `notifyListeners()`"),
        ("Flow 2: Real-time Telemetry & BLE Discovery ➔ Dynamic UI",
         "`BLE GATT Scanner` / `BatteryManager` ➔ `Stream<NearbyDevice>` ➔ `MeshProvider` & `TelemetryProvider` ➔ `Consumer<MeshProvider>` ListView / CustomPainter Map"),
        ("Flow 3: Real-time Outbox Queue ➔ Opportunistic BLE Dispatch",
         "User sends message ➔ `ChatService.saveBeforeSend()` (status='SAVED') ➔ `MeshEngine.outboxQueue` ➔ Peer in radio range (~80m) ➔ `BLE GATT Advertiser` broadcast"),
        ("Flow 4: Dynamic Shelters & Missing Records ➔ P2P Gossip Sync",
         "SQLite parameterized query `SELECT * FROM shelters WHERE is_open=1` ➔ Dynamic Distance Ordering ➔ Gossip Ingestion on BLE encounter ➔ UI Stream updates")
    ]
    for idx, (fname, fdesc) in enumerate(flow_lanes):
        cell(root, f"d2_fl_{idx}", f"<b>{fname}</b><br/><span style='font-size:9px;color:#EEF2F8;'>{fdesc}</span>",
             "rounded=1;fillColor=#162036;strokeColor=#3CC6D0;strokeWidth=1;fontColor=#EEF2F8;fontSize=10;align=left;spacingLeft=8;",
             60 + idx * 820, 190, 800, 105)

    # 6 LAYERS
    layer_configs = [
        ("LAYER 1: PRESENTATION & UI LAYER (Widget Tree & GoRouter State Machine)", "#FFD21F", 340, 310,
         "<b>Flutter Widget Tree:</b> `MainShell` (Bottom Navigation Shell: ChatTab, MapTab, SosTab, ToolsTab, AiTab)<br/>"
         "<b>14 Hi-Vis Screens:</b> SplashScreen, OnboardingScreen, ProfileSetupScreen, HomeScreen, EmergencyReportScreen, ChatScreen, LiveMapScreen, AIAssistantScreen, MissingPersonScreen, SheltersScreen, MyMessagesScreen, SafetyToolsScreen, SettingsScreen, ProfileScreen<br/>"
         "<b>Core Reusable Components:</b> `BeaconSosButton` (176dp Circular 3s Hold), `StatusCard` (Mesh, Net, GPS, Bat), `ChatBubble` (Delivery Ticks), `PrimaryButton` (56dp CTA), `StatusStrip`<br/>"
         "<b>Navigator 2.0 / GoRouter State Machine:</b> Initial Route Guard (`ProfileProvider.isRegistered ? '/home' : '/profile_setup'`) • Modal Bottom Sheets • Strict Back-Button Lock on Profile Gate<br/>"
         "<b>Design System Tokens:</b> Safety Yellow (#FFD21F), SOS Red (#D92D20), Beacon Teal (#0E8A94), True OLED Black (#000000), Min 48dp Targets, 56dp Primary Buttons"),

        ("LAYER 2: STATE MANAGEMENT LAYER (ChangeNotifier Providers & Reactive State Contracts)", "#3CC6D0", 680, 280,
         "<b>ChangeNotifier Providers (Reactive Contracts):</b><br/>"
         "• `ProfileProvider`: Identity lifecycle, registration gate, pseudonym UUID (`SR-XXXX-XXXX`), blood group, emergency contact<br/>"
         "• `MeshProvider`: Peer registry (12 active peers), RSSI bands (Immediate/Near/Far), duty-cycle scanner loop<br/>"
         "• `ChatProvider`: Active conversation streams, outbox sync queue, multi-hop delivery states (Saved, Sent Nearby, Relayed, Delivered)<br/>"
         "• `ThemeProvider`: Real-time switching between High-Contrast Yellow, Dark Navy, and True OLED Black (#000000)<br/>"
         "• `EmergencyProvider` / `EmergencyReportProvider`: SOS triggering, threat categorization, high-priority envelope dispatch<br/>"
         "• `TelemetryProvider` / `DeviceStatusProvider`: Battery % drain tracker, GPS dead-reckoning cache, radio duty-cycle coordinator"),

        ("LAYER 3: APPLICATION & DOMAIN SERVICES LAYER (Offline Intelligence & Transaction Dispatcher)", "#4CD08A", 990, 280,
         "<b>Domain Protocol Services:</b><br/>"
         "• `ChatService`: Save-Before-Send transactional pipeline, ACK tracking, outbox dispatch<br/>"
         "• `AIAssistantService`: Offline rule-based disaster triage heuristic, disaster Q&A knowledge base (water, fire, wounds)<br/>"
         "• `LocationService`: Hardware GPS listener, dead-reckoning estimator, accuracy bounding<br/>"
         "• `TelemetryService`: Battery drain monitor, adaptive radio duty-cycle policy"),

        ("LAYER 4: DTN MESH PROTOCOL ENGINE (Kabootar & MeshChat Pattern: Store-and-Forward Routing)", "#FF5A4E", 1300, 310,
         "<b>DTN Engine Subsystems:</b><br/>"
         "• `Binary Envelope Builder`: UUID (16B), Sender ID (8B), Timestamp (8B), Type (1B), TTL (1B), Hops (1B), Coords (16B), Payload (<450B), CRC32 Checksum<br/>"
         "• `Bloom Filter Deduplication`: 10,000-bit rotating bitset, O(1) loop suppression, SQLite secondary hash verification<br/>"
         "• `Outbox Store-and-Forward Queue`: Non-volatile SQLite buffer, priority sorting (P1 SOS > P2 Missing > P3 Chat), exponential retry backoff<br/>"
         "• `Epidemic Carry-and-Forward Router`: Opportunistic gossip protocol, carry-and-forward relay across pedestrian motion<br/>"
         "• `TTL Decrement Guard`: Decrement TTL by 1; if TTL <= 1 halt retransmission, eliminate broadcast storms<br/>"
         "• `Multi-Hop ACK Tracker`: Reverse path receipt confirmation updating local SQLite message status"),

        ("LAYER 5: LOCAL PERSISTENCE ENGINE (SQLite Database - app_database.db & Repositories)", "#FFA033", 1640, 310,
         "<b>SQLite Database (`app_database.db`):</b><br/>"
         "• Tables: `user_profile`, `messages`, `nearby_devices`, `emergency_reports`, `shelters`, `missing_persons`<br/>"
         "• Repositories (DAOs): `ProfileRepository`, `ChatRepository`, `DeviceRepository`, `ReportRepository`, `ShelterRepository`<br/>"
         "• <b>Save-Before-Send Write Barrier:</b> `db.transaction((txn) => txn.insert('messages', envelope.toMap()))` must commit to NAND flash before BLE radio transmits.<br/>"
         "• Reactive Database Triggers: Emits update streams to ChangeNotifier providers upon table mutations"),

        ("LAYER 6: HARDWARE ABSTRACTION & OS PLATFORM LAYER (Zero Internet Transceivers & Display Power HAL)", "#9FADC2", 1980, 280,
         "<b>Hardware Transceivers & Power HAL:</b><br/>"
         "• `BLE GATT Server (Peripheral)`: Duty-cycled advertising (200ms active / 800ms sleep), Service UUID 0xFD6F<br/>"
         "• `BLE GATT Client (Central)`: Background scanning, RSSI proximity band estimator (Immediate/Near/Far)<br/>"
         "• `Wi-Fi Direct / Nearby Service`: High-throughput fallback for image attachments and relief inventories<br/>"
         "• `AMOLED Subpixel Black Controller`: True #000000 shutdown, 62% battery power reduction")
    ]

    for idx, (lname, lcol, ly, lh, ldesc) in enumerate(layer_configs):
        cell(root, f"d2_l_{idx}", f"<b>{lname}</b><br/><hr/><span style='font-size:11px;color:#EEF2F8;'>{ldesc}</span>",
             f"rounded=1;fillColor=#162036;strokeColor={lcol};strokeWidth=2;fontColor=#EEF2F8;fontSize=14;align=left;spacingLeft=12;",
             60, ly, 3280, lh)

    # Inter-layer arrows
    edge(root, "d2_arr_1", "UI Events / State Listeners", "strokeColor=#FFD21F;strokeWidth=3;", "d2_l_0", "d2_l_1")
    edge(root, "d2_arr_2", "Service Invocations", "strokeColor=#3CC6D0;strokeWidth=3;", "d2_l_1", "d2_l_2")
    edge(root, "d2_arr_3", "DTN Envelope Dispatch", "strokeColor=#4CD08A;strokeWidth=3;", "d2_l_2", "d2_l_3")
    edge(root, "d2_arr_4", "Save-Before-Send Flash Commit", "strokeColor=#FF5A4E;strokeWidth=3;", "d2_l_3", "d2_l_4")
    edge(root, "d2_arr_5", "Radio Air Transmission", "strokeColor=#FFA033;strokeWidth=3;", "d2_l_4", "d2_l_5")

# -------------------------------------------------------------
# DIAGRAM 3: 14 MOBILE PHONE FRAME WIREFRAMES
# -------------------------------------------------------------
def build_diagram_3(mxfile):
    root = add_diagram(mxfile, "screens", "03 - 14 Mobile Phone Frame Wireframes", 4600, 1600)

    # Banner
    cell(root, "d3_hdr", "", "rounded=1;fillColor=#162036;strokeColor=#FFD21F;strokeWidth=2;", 40, 30, 4520, 90)
    cell(root, "d3_hdr_t",
         "<b>COMPLETE 14-SCREEN MOBILE APPLICATION WIREFRAME SUITE (FLUTTER / DART 3)</b><br/>"
         "<span style='font-size:14px;color:#EEF2F8;'>Realistic Smartphone Bezels • Dynamic Reactive State Contracts • OLED True Black #000000 Mode • High-Vis Beacon Design System</span>",
         "text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontSize=22;fontColor=#FFD21F;",
         60, 35, 4480, 80)

    all_screens = [
        ("1", "Splash Screen", "Animated Beacon & Gate Router"),
        ("2", "Onboarding Guide", "Decentralized Mesh Principles"),
        ("2b", "Profile Gate*", "Mandatory Identity Setup"),
        ("3", "Home SOS Main", "3s Hold Beacon & Telemetry"),
        ("4", "Emergency Report", "Categorized Distress Dispatch"),
        ("5", "Offline Mesh Chat", "P2P Community Stream"),
        ("6", "Live Mesh Map", "Vector Topological Canvas"),
        ("7", "AI Survival Assist", "Offline On-Device Rules"),
        ("8", "Report Missing", "Bulletin Form & Photos"),
        ("9", "Relief Shelters", "Real-Time Resource Gauges"),
        ("10", "My Outbox Queue", "Store-and-Forward Spool"),
        ("11", "Safety Tools", "2x3 Emergency Utilities"),
        ("12", "Settings (OLED)", "AMOLED Subpixel Black #000000"),
        ("13", "Responder Profile", "2x2 Community Impact KPIs")
    ]

    # Row 1: Screens 1 to 6 (7 phones, including 2b)
    for idx, (snum, stitle, ssub) in enumerate(all_screens[:7]):
        px = 60 + idx * 645
        py = 160
        draw_phone_frame(root, f"d3_ph_{snum}", px, py, stitle, snum, ssub, is_oled=(snum == "12"))
        populate_screen_dynamic(root, f"d3_ph_{snum}", px, py, snum)

    # Row 2: Screens 7 to 13 (7 phones)
    for idx, (snum, stitle, ssub) in enumerate(all_screens[7:]):
        px = 60 + idx * 645
        py = 820
        draw_phone_frame(root, f"d3_ph_{snum}", px, py, stitle, snum, ssub, is_oled=(snum == "12"))
        populate_screen_dynamic(root, f"d3_ph_{snum}", px, py, snum)

# -------------------------------------------------------------
# DIAGRAM 4: TACTICAL GATEWAY & COMMAND CENTER DESKTOP BROWSER
# -------------------------------------------------------------
def build_diagram_4(mxfile):
    root = add_diagram(mxfile, "gateway_desktop", "04 - Tactical Gateway & Command Center Dashboard", 3200, 2400)

    # Banner
    cell(root, "d4_hdr", "", "rounded=1;fillColor=#162036;strokeColor=#FFA033;strokeWidth=2;", 40, 30, 3120, 90)
    cell(root, "d4_hdr_t",
         "<b>TACTICAL RESCUE EDGE GATEWAY & COMMAND CENTER CLOUD DASHBOARD WIREFRAME</b><br/>"
         "<span style='font-size:14px;color:#EEF2F8;'>Headless Linux Daemon • Multi-WAN Hybrid Backhaul • React / Vite / Leaflet Web Dashboard • Explainable AI Triage Stream</span>",
         "text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontSize=22;fontColor=#FFA033;",
         60, 35, 3080, 80)

    # Top Half: Edge Gateway Convoy Architecture
    cell(root, "d4_gw_box", "", "rounded=1;fillColor=#111A2C;strokeColor=#26344F;strokeWidth=2;", 40, 150, 3120, 680)
    cell(root, "d4_gw_lbl", "<b>FIELD RESCUE EDGE GATEWAY & TACTICAL CONVOY SOFTWARE ARCHITECTURE</b>",
         "text;html=1;strokeColor=none;fillColor=none;fontSize=18;fontColor=#FFA033;", 60, 165, 900, 30)

    gw_nodes = [
        ("Tactical Convoy Vehicle", "NDRF / SDRF Rescue Truck equipped with omnidirectional high-gain BLE receiver (+12 dBi) and onboard Starlink satellite terminal."),
        ("Headless Linux Daemon", "`rakshanet-gateway.service`\nC++ / Python / Go runtime managing BLE packet ingestion, hardware watchdog, and uplink synchronization."),
        ("Tactical BLE Sink Buffer", "Ingests batch envelopes from passing pedestrian nodes within 150m. Issues multi-hop ACKs back into ground mesh."),
        ("RocksDB Persistent Spool", "Local high-throughput store. Prioritizes P1 (SOS) over P4 (Chat). Calculates hop delay & vector route metrics."),
        ("Hybrid Backhaul Failover", "Auto-switches between Starlink satellite dish, 4G/5G tactical private LTE, and VHF/LoRa long-range radio."),
        ("Bidirectional Sync Engine", "Pushes survivor envelopes to Cloud; ingests NDMA CAP XML alerts and injects them downward into ground mesh.")
    ]
    for idx, (gtitle, gdesc) in enumerate(gw_nodes):
        col = idx % 3
        row = idx // 3
        cell(root, f"d4_gwn_{idx}", f"<b>{gtitle}</b><br/><hr/><span style='font-size:9px;color:#EEF2F8;'>{gdesc.replace(chr(10), '<br/>')}</span>",
             "rounded=1;fillColor=#162036;strokeColor=#FFA033;strokeWidth=1;fontColor=#EEF2F8;fontSize=11;align=left;spacingLeft=8;",
             60 + col * 1025, 210 + row * 260, 990, 230)

    # Bottom Half: Full-Size Desktop Browser Command Center Wireframe
    cell(root, "d4_brw_box", "", "rounded=1;fillColor=#111A2C;strokeColor=#26344F;strokeWidth=2;", 40, 870, 3120, 1480)
    cell(root, "d4_brw_lbl", "<b>COMMAND CENTER CLOUD DESKTOP BROWSER WIREFRAME (REACT / VITE / LEAFLET GIS)</b>",
         "text;html=1;strokeColor=none;fillColor=none;fontSize=18;fontColor=#3CC6D0;", 60, 885, 900, 30)

    draw_browser(root, "d4_bwin", 60, 930, 3080, 1400, "RakshaNet NDMA Command Center Hub", "https://command.rakshanet.gov.in/triage")

    cell(root, "d4_bstat",
         "🚨 Active P1 SOS Beacons: 4   •   👥 Persons in Distress: 18   •   🚙 Field Convoy Units: 6   •   🏕️ Open Shelters: 12 (64% Capacity)   •   📡 14 Edge Gateways Connected   •   🏛️ NDMA CAP Live",
         "rounded=1;fillColor=#162036;strokeColor=#3CC6D0;fontColor=#EEF2F8;fontSize=11;align=center;",
         80, 1030, 3040, 40)

    # Column 1: Leaflet GIS Map Canvas (Left 40% width)
    cell(root, "d4_map_canvas", "", "rounded=1;fillColor=#0E1627;strokeColor=#26344F;strokeWidth=1;", 80, 1085, 1200, 1220)
    cell(root, "d4_map_title", "<b>Leaflet Tactical GIS Map Canvas (`L.geoJSON()`)</b>", "text;html=1;fontColor=#FFD21F;fontSize=12;", 95, 1095, 450, 25)
    
    cell(root, "d4_m_sos1", "🔴 P1: Amit (Trapped)\nLat: 19.076, Lon: 72.877",
         "ellipse;fillColor=#D92D20;strokeColor=#FF5A4E;strokeWidth=3;fontColor=#FFFFFF;fontSize=10;align=center;",
         150, 1160, 180, 90)
    cell(root, "d4_m_p1", "🟡 Peer Node B\n(Hop 1 Relay)",
         "ellipse;fillColor=#162036;strokeColor=#FFD21F;strokeWidth=2;fontColor=#FFD21F;fontSize=9;align=center;",
         420, 1200, 140, 70)
    cell(root, "d4_m_p2", "🟡 Peer Node C\n(Hop 2 Relay)",
         "ellipse;fillColor=#162036;strokeColor=#FFD21F;strokeWidth=2;fontColor=#FFD21F;fontSize=9;align=center;",
         680, 1290, 140, 70)
    cell(root, "d4_m_gw", "🚙 NDRF Convoy 01\n(BLE Sink Gateway)",
         "ellipse;fillColor=#162036;strokeColor=#4CD08A;strokeWidth=3;fontColor=#4CD08A;fontSize=10;align=center;",
         950, 1400, 180, 80)
    edge(root, "d4_m_hop1", "BLE Hop 1 (~80m)", "dashed=1;strokeColor=#3CC6D0;strokeWidth=3;fontColor=#3CC6D0;fontSize=10;", "d4_m_sos1", "d4_m_p1")
    edge(root, "d4_m_hop2", "BLE Hop 2", "dashed=1;strokeColor=#3CC6D0;strokeWidth=3;fontColor=#3CC6D0;fontSize=10;", "d4_m_p1", "d4_m_p2")
    edge(root, "d4_m_hop3", "Uplink Ingestion", "dashed=1;strokeColor=#4CD08A;strokeWidth=3;fontColor=#4CD08A;fontSize=10;", "d4_m_p2", "d4_m_gw")

    # Column 2: Explainable AI Live Incident Triage Stream (Middle 35% width)
    cell(root, "d4_triage_stream", "", "rounded=1;fillColor=#0E1627;strokeColor=#26344F;strokeWidth=1;", 1300, 1085, 1050, 1220)
    cell(root, "d4_triage_title", "<b>Explainable AI Live Incident Triage Stream (`WebSocket /ws/live`)</b>", "text;html=1;fontColor=#FF5A4E;fontSize=12;", 1315, 1095, 500, 25)

    cell(root, "d4_c_p1",
         "<b>🚨 P1 CRITICAL Distress (AI Score: 98/100)</b><br/>"
         "<b>Victim:</b> Amit Sharma (ID: SR-284739)  •  <b>Blood:</b> O+  •  <b>Contact:</b> +91 98765 43210<br/>"
         "<b>Path:</b> 3 BLE hops via Pedestrian Relay  •  <b>Battery:</b> 12%  •  <b>GPS Acc:</b> ±6m<br/>"
         "<hr/>"
         "<b>🤖 Explainable AI Reasoning (Confidence: 96.4%):</b><br/>"
         "• Severe crush injury / trapped under concrete beam (Weight: 0.45)<br/>"
         "• Rapidly rising floodwaters detected (0.35m/hr) (Weight: 0.35)<br/>"
         "• Critical device battery drain (< 15%) (Weight: 0.20)<br/>"
         "<b>Recommended Action:</b> Immediate NDRF Boat / Heavy Extrication Dispatch",
         "rounded=1;fillColor=#162036;strokeColor=#D92D20;strokeWidth=2;fontColor=#EEF2F8;fontSize=10;align=left;spacingLeft=10;",
         1315, 1140, 1020, 220)

    cell(root, "d4_b_act1", "🚨 Dispatch NDRF Team 3", "rounded=1;fillColor=#D92D20;fontColor=#FFFFFF;fontStyle=1;fontSize=11;align=center;", 1325, 1375, 280, 42)
    cell(root, "d4_b_act2", "📡 Send Mesh ACK Packet", "rounded=1;fillColor=#0E8A94;fontColor=#FFFFFF;fontStyle=1;fontSize=11;align=center;", 1625, 1375, 280, 42)
    cell(root, "d4_b_act3", "🛰️ Satellite SMS Relay", "rounded=1;fillColor=#162036;strokeColor=#FFD21F;fontColor=#FFD21F;fontSize=11;align=center;", 1925, 1375, 280, 42)

    # Column 3: Rescue Operations & Federal Matrix (Right 25% width)
    cell(root, "d4_ops_matrix", "", "rounded=1;fillColor=#0E1627;strokeColor=#26344F;strokeWidth=1;", 2370, 1085, 750, 1220)
    cell(root, "d4_ops_title", "<b>Rescue Operations & NDMA CAP Gateway Matrix</b>", "text;html=1;fontColor=#4CD08A;fontSize=12;", 2385, 1095, 450, 25)

    cell(root, "d4_o_units",
         "<b>Field Units Live Telemetry:</b><br/>"
         "• NDRF Unit 1: Deployed (Zone Alpha)<br/>"
         "• NDRF Unit 2: En Route (Zone Beta)<br/>"
         "• Boat Team 3: Evacuating School<br/>"
         "• Drone Alpha: Scanning Corridor 4<br/>"
         "• Drone Beta: Standby (Battery 95%)",
         "rounded=1;fillColor=#162036;strokeColor=#4CD08A;fontColor=#EEF2F8;fontSize=10;align=left;spacingLeft=8;",
         2385, 1140, 720, 150)

    cell(root, "d4_o_shelters",
         "<b>Relief Shelters Capacity Status:</b><br/>"
         "• Village Senior School: 120/200 (60%) 🟢<br/>"
         "• Community Center: 190/200 (95%) 🟠 FULL<br/>"
         "• Primary Health Center: 45/50 (90%) 🔴 TRIAGE",
         "rounded=1;fillColor=#162036;strokeColor=#FFA033;fontColor=#EEF2F8;fontSize=10;align=left;spacingLeft=8;",
         2385, 1310, 720, 130)

    cell(root, "d4_o_cap",
         "<b>NDMA CAP XML v1.2 Protocol Feed:</b><br/>"
         "`[12:48:15] INGEST: CAP Alert #NDMA-MH-04`<br/>"
         "`[12:49:02] BROADCAST: 3 SOS to Federal Grid`<br/>"
         "`[12:50:33] ACK SYNC: 14 Packets confirmed`<br/>"
         "<b>Backhaul:</b> Starlink Dish (48 Mbps, Latency: 38ms)",
         "rounded=1;fillColor=#162036;strokeColor=#FFD21F;fontColor=#EEF2F8;fontSize=10;align=left;spacingLeft=8;",
         2385, 1460, 720, 150)

# -------------------------------------------------------------
# DIAGRAM 5: KABOOTAR & MESHCHAT DTN PROTOCOL & SQLITE ENGINE
# -------------------------------------------------------------
def build_diagram_5(mxfile):
    root = add_diagram(mxfile, "dtn_persistence", "05 - DTN Protocol & SQLite Engine", 3400, 2200)

    # Banner
    cell(root, "d5_hdr", "", "rounded=1;fillColor=#162036;strokeColor=#FF5A4E;strokeWidth=2;", 40, 30, 3320, 90)
    cell(root, "d5_hdr_t",
         "<b>KABOOTAR & MESHCHAT DTN PROTOCOL, 4-PHONE 3-HOP SIMULATION & SQLITE PERSISTENCE</b><br/>"
         "<span style='font-size:14px;color:#EEF2F8;'>Save-Before-Send Transactional Durability • Bloom Filter Loop Suppression • Binary Envelope Wire Format</span>",
         "text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontSize=22;fontColor=#FF5A4E;",
         60, 35, 3280, 80)

    # Section 1: 5-Layer Stack Wireframe
    cell(root, "d5_s1_box", "", "rounded=1;fillColor=#111A2C;strokeColor=#26344F;strokeWidth=2;", 40, 150, 1050, 1980)
    cell(root, "d5_s1_lbl", "<b>THE 5-LAYER STACK ARCHITECTURE WIREFRAME</b>",
         "text;html=1;strokeColor=none;fillColor=none;fontSize=16;fontColor=#FFD21F;", 60, 165, 800, 25)
    
    stack_layers = [
        ("Flutter UI (13 Screens)", "#FFD21F", "User interaction, hi-vis components, emergency triggers"),
        ("ChatService / Domain Services", "#3CC6D0", "Save-Before-Send coordinator, ACK handler, offline AI rules"),
        ("MeshEngine (DTN Routing)", "#4CD08A", "Envelope builder, Bloom filter dedup, epidemic carry-and-forward"),
        ("SQLite Local Persistence", "#FFA033", "app_database.db, flash commit barrier, outbox queue"),
        ("BLE / Wi-Fi Transport HAL", "#9FADC2", "BLE GATT server/client, duty-cycle scheduler, AMOLED black")
    ]
    for idx, (sname, scol, sdesc) in enumerate(stack_layers):
        cell(root, f"d5_stk_{idx}", f"<b>{sname}</b><br/><span style='font-size:10px;color:#EEF2F8;'>{sdesc}</span>",
             f"rounded=1;fillColor=#162036;strokeColor={scol};strokeWidth=2;fontColor=#EEF2F8;fontSize=13;align=center;",
             60, 220 + idx * 240, 1010, 130)
        if idx > 0:
            edge(root, f"d5_stk_arr_{idx}", "Downward Call / Upward Event", "strokeColor=#3CC6D0;strokeWidth=3;", f"d5_stk_{idx-1}", f"d5_stk_{idx}")

    # Section 2: DTN Binary Envelope Wireframe
    cell(root, "d5_s2_box", "", "rounded=1;fillColor=#111A2C;strokeColor=#26344F;strokeWidth=2;", 1120, 150, 2240, 600)
    cell(root, "d5_s2_lbl", "<b>DTN BINARY ENVELOPE SPECIFICATION (WIRE FORMAT < 512 BYTES MTU)</b>",
         "text;html=1;strokeColor=none;fillColor=none;fontSize=16;fontColor=#3CC6D0;", 1140, 165, 800, 25)

    env_specs = [
        ("Envelope UUID (16 Bytes)", "UUID v4 uniquely identifying message across all nodes globally"),
        ("Sender ID (8 Bytes)", "Pseudonymous token (e.g. `SR-284739`) generated from SHA256 of pubkey"),
        ("Monotonic Timestamp (8 Bytes)", "Monotonic unix milliseconds of creation clock"),
        ("Packet Type (1 Byte)", "0x01: SOS | 0x02: Chat | 0x03: Missing | 0x04: Shelter | 0x05: ACK"),
        ("Time-To-Live TTL (1 Byte)", "Default=5. Decremented by 1 at each hop. If TTL<=1 halt radio."),
        ("Hop Count (1 Byte)", "Default=0. Incremented by 1 at each physical relay hop."),
        ("Location Flag (1 Byte)", "0x00: No GPS | 0x01: Active GPS fix attached"),
        ("Latitude & Longitude (16 Bytes)", "Two IEEE 754 64-bit floats representing geographic coordinates"),
        ("Payload Length (2 Bytes)", "Unsigned 16-bit integer representing compressed body byte size"),
        ("Payload Body (Var <= 450 Bytes)", "Compressed JSON / CBOR encoded emergency message data"),
        ("CRC32 / HMAC Checksum (4 Bytes)", "Integrity frame verification against radio corruption")
    ]
    for idx, (ename, edesc) in enumerate(env_specs):
        col = idx % 3
        row = idx // 3
        cell(root, f"d5_env_{idx}", f"<b>{ename}</b><br/><span style='font-size:9px;color:#9FADC2;'>{edesc}</span>",
             "rounded=1;fillColor=#162036;strokeColor=#26344F;fontColor=#EEF2F8;fontSize=10;align=left;spacingLeft=8;",
             1140 + col * 735, 210 + row * 95, 715, 80)

    # Section 3: 4-Phone 3-Hop Simulation
    cell(root, "d5_s3_box", "", "rounded=1;fillColor=#111A2C;strokeColor=#26344F;strokeWidth=2;", 1120, 770, 2240, 680)
    cell(root, "d5_s3_lbl", "<b>4-PHONE 3-HOP STORE-AND-FORWARD TOPOLOGY SIMULATION (EPIDEMIC ROUTING)</b>",
         "text;html=1;strokeColor=none;fillColor=none;fontSize=16;fontColor=#4CD08A;", 1140, 785, 900, 25)

    sim_cards = [
        ("PHONE A (Victim Node)", "#D92D20", "• Generates SOS `MSG-001`<br/>• Save-Before-Send into SQLite<br/>• <b>TTL = 5 | Hop Count = 0</b><br/>• Broadcasts BLE advertisement"),
        ("PHONE B (Pedestrian Relay)", "#3CC6D0", "• Ingests MSG-001 via BLE<br/>• Bloom filter dedup check: Not Seen<br/>• Saved into local SQLite<br/>• <b>TTL = 4 | Hop Count = 1</b><br/>• Physical walking carries packet"),
        ("PHONE C (Volunteer Node)", "#3CC6D0", "• Encounter sync with Phone B<br/>• Receives MSG-001 into SQLite<br/>• <b>TTL = 3 | Hop Count = 2</b><br/>• Displays SOS in Community Chat<br/>• Relays to outbound vehicle"),
        ("PHONE D (Gateway Contact)", "#4CD08A", "• Receives MSG-001 from vehicle<br/>• <b>TTL = 2 | Hop Count = 3</b><br/>• Enters range of NDRF Convoy<br/>• Batch flushes outbox to Gateway<br/>• Receives Reverse ACK")
    ]
    for idx, (sname, scol, sdesc) in enumerate(sim_cards):
        cell(root, f"d5_sim_{idx}", f"<b>{sname}</b><br/><hr/><span style='font-size:10px;color:#EEF2F8;'>{sdesc}</span>",
             f"rounded=1;fillColor=#162036;strokeColor={scol};strokeWidth=2;fontColor=#EEF2F8;fontSize=12;align=left;spacingLeft=10;",
             1140 + idx * 550, 830, 520, 250)

    edge(root, "d5_sim_ab", "BLE Hop 1 (~80m)", "strokeColor=#3CC6D0;strokeWidth=3;fontSize=10;fontColor=#3CC6D0;", "d5_sim_0", "d5_sim_1")
    edge(root, "d5_sim_bc", "BLE Hop 2 (Store-Carry)", "strokeColor=#3CC6D0;strokeWidth=3;fontSize=10;fontColor=#3CC6D0;", "d5_sim_1", "d5_sim_2")
    edge(root, "d5_sim_cd", "BLE Hop 3 (Vehicle Sync)", "strokeColor=#3CC6D0;strokeWidth=3;fontSize=10;fontColor=#3CC6D0;", "d5_sim_2", "d5_sim_3")

    # Section 4: SQLite Database Schema & E-R Model
    cell(root, "d5_s4_box", "", "rounded=1;fillColor=#111A2C;strokeColor=#26344F;strokeWidth=2;", 1120, 1470, 2240, 660)
    cell(root, "d5_s4_lbl", "<b>LOCAL SQLITE DATABASE ARCHITECTURE (`app_database.db`) & RELATIONAL SCHEMA</b>",
         "text;html=1;strokeColor=none;fillColor=none;fontSize=16;fontColor=#FFA033;", 1140, 1485, 900, 25)

    sqlite_dbs = [
        ("user_profile", "id TEXT PRIMARY KEY\nfull_name TEXT\nblood_group TEXT\ncontact_phone TEXT\nlanguage TEXT\ncreated_at INTEGER"),
        ("messages", "message_id TEXT PRIMARY KEY\nconversation_id TEXT\nsender_id TEXT\ncontent TEXT\nstatus TEXT\nttl INT, hops INT, ts INT"),
        ("nearby_devices", "device_id TEXT PRIMARY KEY\ndisplay_name TEXT\nrssi INTEGER\nsignal_band TEXT\nlast_seen INTEGER\nrelay_capable INT"),
        ("emergency_reports", "report_id TEXT PRIMARY KEY\ntype TEXT\nlatitude REAL, longitude REAL\ndescription TEXT\nstatus TEXT, created_at INT"),
        ("shelters", "id TEXT PRIMARY KEY\nname TEXT, address TEXT\nlatitude REAL, longitude REAL\ncapacity INT, occupancy INT\nsupplies_json TEXT, open INT"),
        ("missing_persons", "id TEXT PRIMARY KEY\nfull_name TEXT, age INT\ngender TEXT, clothing TEXT\nlast_seen_loc TEXT, ts INT\nphotos_blob_json TEXT")
    ]
    for idx, (tname, tcols) in enumerate(sqlite_dbs):
        col = idx % 3
        row = idx // 3
        cell(root, f"d5_db_{idx}", f"<b>{tname}</b><br/><hr/><span style='font-size:9px;color:#9FADC2;'>{tcols.replace(chr(10), '<br/>')}</span>",
             "shape=cylinder;whiteSpace=wrap;html=1;boundedLbl=1;backgroundOutline=1;size=12;fillColor=#162036;strokeColor=#FFA033;fontColor=#EEF2F8;fontSize=11;align=left;spacingLeft=8;",
             1140 + col * 735, 1530 + row * 260, 715, 220)

# -------------------------------------------------------------
# MAIN COMPILATION & EXECUTION ROUTINE
# -------------------------------------------------------------
def main():
    print("Building RakshaNet architecture.drawio...")
    mxfile = create_drawio_file()

    print("Generating Diagram 1: Master Architecture & Wireframe Map...")
    build_diagram_1(mxfile)

    print("Generating Diagram 2: 6-Layer Mobile Software Architecture...")
    build_diagram_2(mxfile)

    print("Generating Diagram 3: 14 Mobile Phone Frame Wireframes...")
    build_diagram_3(mxfile)

    print("Generating Diagram 4: Tactical Gateway & Desktop Command Center...")
    build_diagram_4(mxfile)

    print("Generating Diagram 5: Kabootar & MeshChat DTN Protocol & SQLite Engine...")
    build_diagram_5(mxfile)

    out_path = r"p:\RakshaNet\architecture.drawio"
    tree = ET.ElementTree(mxfile)
    
    # Write to string with xml declaration and UTF-8
    xml_str = ET.tostring(mxfile, encoding="utf-8", xml_declaration=True).decode("utf-8")
    
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(xml_str)
    
    print(f"Successfully generated {out_path} ({len(xml_str)} bytes)")
    
    # Verify XML well-formedness
    try:
        ET.parse(out_path)
        print("Verification SUCCESS: XML is 100% well-formed and valid!")
    except Exception as e:
        print(f"Verification ERROR: {e}")
        raise e

if __name__ == "__main__":
    main()
