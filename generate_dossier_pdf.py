import os
import sys
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Image as RLImage,
    Table, TableStyle, PageBreak, KeepTogether, HRFlowable
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.pdfgen import canvas
from pypdf import PdfReader

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super(NumberedCanvas, self).__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super(NumberedCanvas, self).showPage()
        super(NumberedCanvas, self).save()

    def draw_page_decorations(self, total_pages):
        self.saveState()
        w, h = A4
        margin = 36

        # Running Header (pages 2+)
        if self._pageNumber > 1:
            self.setFont("Helvetica-Bold", 8.5)
            self.setFillColor(colors.HexColor("#0B1220"))
            self.drawString(margin, h - 24, "RAKSHANET (SIGNALRESCUE AI)")
            self.setFont("Helvetica", 8)
            self.setFillColor(colors.HexColor("#475569"))
            self.drawString(margin + 160, h - 24, "|   Offline Disaster Mesh & AI Rescue Intelligence Dossier")
            
            self.setFont("Helvetica-Bold", 8)
            self.setFillColor(colors.HexColor("#0E8A94"))
            self.drawRightString(w - margin, h - 24, "TECHNICAL WHITE PAPER")
            
            self.setStrokeColor(colors.HexColor("#CBD5E1"))
            self.setLineWidth(0.6)
            self.line(margin, h - 28, w - margin, h - 28)

        # Running Footer (all pages)
        self.setStrokeColor(colors.HexColor("#CBD5E1"))
        self.setLineWidth(0.6)
        self.line(margin, 26, w - margin, 26)

        self.setFont("Helvetica", 8)
        self.setFillColor(colors.HexColor("#64748B"))
        self.drawString(margin, 16, "RakshaNet Technical Dossier  |  Empirical Case Study, Full 34-Feature Spec & Competitive Audit")
        
        page_str = f"Page {self._pageNumber} of {total_pages}"
        self.setFont("Helvetica-Bold", 8)
        self.setFillColor(colors.HexColor("#0B1220"))
        self.drawRightString(w - margin, 16, page_str)

        self.restoreState()


def build_pdf():
    pdf_path = r"P:\RakshaNet\RakshaNet_Comprehensive_System_Dossier.pdf"
    os.makedirs(os.path.dirname(pdf_path), exist_ok=True)

    doc = SimpleDocTemplate(
        pdf_path,
        pagesize=A4,
        leftMargin=36,
        rightMargin=36,
        topMargin=36,
        bottomMargin=36
    )

    page_w = A4[0] - 72  # 523.28 pt usable width
    styles = getSampleStyleSheet()

    # Brand Colors
    c_navy = colors.HexColor("#0B1220")
    c_yellow = colors.HexColor("#FFC400")
    c_red = colors.HexColor("#D92D20")
    c_teal = colors.HexColor("#0E8A94")
    c_slate = colors.HexColor("#475569")
    c_bg_light = colors.HexColor("#F8FAFC")
    c_border = colors.HexColor("#CBD5E1")
    c_text = colors.HexColor("#0F172A")
    c_white = colors.HexColor("#FFFFFF")

    # Highly Readable Typography Styles
    title_style = ParagraphStyle(
        'DocTitle',
        fontName='Helvetica-Bold',
        fontSize=20,
        leading=24,
        textColor=c_navy,
        spaceAfter=4
    )
    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        fontName='Helvetica',
        fontSize=10.5,
        leading=14.5,
        textColor=c_teal,
        spaceAfter=8
    )
    h1_style = ParagraphStyle(
        'ChapterHeading',
        fontName='Helvetica-Bold',
        fontSize=13.5,
        leading=16.5,
        textColor=c_navy,
        spaceBefore=12,
        spaceAfter=6,
        keepWithNext=True
    )
    h2_style = ParagraphStyle(
        'SubHeading',
        fontName='Helvetica-Bold',
        fontSize=10.5,
        leading=13.5,
        textColor=c_teal,
        spaceBefore=9,
        spaceAfter=4,
        keepWithNext=True
    )
    h3_style = ParagraphStyle(
        'SubSubHeading',
        fontName='Helvetica-Bold',
        fontSize=9.5,
        leading=12.5,
        textColor=c_navy,
        spaceBefore=7,
        spaceAfter=3,
        keepWithNext=True
    )
    body_style = ParagraphStyle(
        'Body_Readable',
        fontName='Helvetica',
        fontSize=9.2,
        leading=13.2,
        textColor=c_text,
        spaceAfter=5
    )
    body_bold = ParagraphStyle(
        'BodyBold_Readable',
        fontName='Helvetica-Bold',
        fontSize=9.2,
        leading=13.2,
        textColor=c_text,
        spaceAfter=5
    )
    bullet_style = ParagraphStyle(
        'Bullet_Readable',
        fontName='Helvetica',
        fontSize=9.0,
        leading=12.8,
        textColor=c_text,
        leftIndent=14,
        spaceAfter=4
    )
    callout_style = ParagraphStyle(
        'Callout_Readable',
        fontName='Helvetica-Oblique',
        fontSize=9.0,
        leading=13.0,
        textColor=c_navy
    )
    th_style = ParagraphStyle(
        'TableHeader_Readable',
        fontName='Helvetica-Bold',
        fontSize=8.2,
        leading=10.5,
        textColor=c_white,
        alignment=0
    )
    td_style = ParagraphStyle(
        'TableCell_Readable',
        fontName='Helvetica',
        fontSize=8.0,
        leading=10.5,
        textColor=c_text
    )
    td_bold = ParagraphStyle(
        'TableCellBold_Readable',
        fontName='Helvetica-Bold',
        fontSize=8.0,
        leading=10.5,
        textColor=c_text
    )

    story = []

    # =============================================================
    # COVER / TITLE HEADER BLOCK
    # =============================================================
    header_data = [
        [
            Paragraph("<b>RAKSHANET (SIGNALRESCUE AI)</b>", title_style),
            Paragraph("<b>DOCUMENT TYPE:</b> TECHNICAL WHITE PAPER<br/><b>EDITION:</b> OCTOBER 2026 / V2.0", ParagraphStyle('Badge', fontName='Helvetica-Bold', fontSize=8, leading=10, textColor=c_teal, alignment=2))
        ],
        [
            Paragraph("<b>Offline Disaster Communication, Delay-Tolerant Mesh & AI Rescue Intelligence Platform</b>", subtitle_style),
            Paragraph("Smart India Hackathon 2026", ParagraphStyle('SubBadge', fontName='Helvetica', fontSize=8, leading=10, textColor=c_slate, alignment=2))
        ]
    ]
    header_table = Table(header_data, colWidths=[360, 163.28])
    header_table.setStyle(TableStyle([
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('BOTTOMPADDING', (0,0), (-1,-1), 0),
        ('TOPPADDING', (0,0), (-1,-1), 0),
    ]))
    story.append(header_table)
    story.append(HRFlowable(width="100%", thickness=1.5, color=c_navy, spaceBefore=4, spaceAfter=7))

    # EXECUTIVE VISION CALLOUT BOX
    exec_text = "<b>The Core Mission:</b> When catastrophic floods, glacier collapses, and landslides destroy cellular towers and power grids, survivors cannot signal, and emergency rescue agencies act blind. <b>RakshaNet turns ordinary smartphones into an autonomous store-and-forward mesh</b>, capturing offline distress signals and converting them into <b>prioritized incidents, probabilistic search zones, and optimized dispatch plans</b> the moment any single handset encounters backhaul connectivity.<br/><br/><i>\"In the next disaster, every silent phone must still leave a trail.\"</i>"
    callout_box = Table([[Paragraph(exec_text, callout_style)]], colWidths=[page_w])
    callout_box.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#FEF9C3")),
        ('BOX', (0,0), (-1,-1), 1.2, c_yellow),
        ('TOPPADDING', (0,0), (-1,-1), 7),
        ('BOTTOMPADDING', (0,0), (-1,-1), 7),
        ('LEFTPADDING', (0,0), (-1,-1), 11),
        ('RIGHTPADDING', (0,0), (-1,-1), 11),
    ]))
    story.append(callout_box)
    story.append(Spacer(1, 7))

    # TABLE OF CONTENTS SUMMARY BOX
    toc_data = [
        [Paragraph("<b>Dossier Table of Contents & Navigation:</b>", ParagraphStyle('TOCHead', fontName='Helvetica-Bold', fontSize=8.5, leading=11, textColor=c_navy))],
        [Paragraph("<b>Chapter 1:</b> Problem Statement, Empirical Evidence (Nepal Floods) & Indian Context  |  <b>Chapter 2:</b> RakshaNet Solution & System Architecture<br/>"
                   "<b>Chapter 3:</b> Full 34-Feature Specification Across 7 Pillars  |  <b>Chapter 4:</b> Verified Competitor Landscape Audit & Corrections<br/>"
                   "<b>Chapter 5:</b> Head-to-Head Deep Dive: RakshaNet vs. Crisis Connect  |  <b>Chapter 6:</b> Quantitative Impact Model & Winning Pitch Strategy", ParagraphStyle('TOCBody', fontName='Helvetica', fontSize=8.0, leading=11, textColor=c_slate))]
    ]
    t_toc = Table(toc_data, colWidths=[page_w])
    t_toc.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#F1F5F9")),
        ('BOX', (0,0), (-1,-1), 0.8, c_border),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ('LEFTPADDING', (0,0), (-1,-1), 9),
        ('RIGHTPADDING', (0,0), (-1,-1), 9),
    ]))
    story.append(t_toc)
    story.append(Spacer(1, 9))

    # =============================================================
    # CHAPTER 1: PROBLEM STATEMENT, EMPIRICAL EVIDENCE & REAL DATA
    # =============================================================
    story.append(Paragraph("Chapter 1: Problem Statement, Empirical Evidence & Real-World Reality", h1_style))
    story.append(Paragraph(
        "When flash floods, glacial lake outburst floods (GLOF), landslides, cyclones, and earthquakes strike, physical infrastructure collapses first. Base transceiver stations (BTS) lose grid power, backhaul fiber-optic lines snap under mudslides, and bridges wash away. In that exact instant, <b>the people who most desperately need rescue are stripped of any ability to call, message, or transmit GPS coordinates</b>.",
        body_style
    ))
    story.append(Paragraph(
        "Consequently, emergency rescue agencies—such as the National Disaster Response Force (NDRF), State Disaster Response Forces (SDRF), and defense teams—are forced to operate blind. They do not know who is alive, where victims are clustered, how many people are in each pocket, or which cut-off valleys must be reached first. Existing government alert platforms (e.g., NDMA SACHET) are strictly one-way and cease functioning when cell towers die. Consumer mesh messengers deliver raw text across short hops but provide zero decision support or command intelligence. <b>Neither system converts scattered offline signals into prioritized rescue dispatch plans.</b>",
        body_style
    ))

    # 1.1 The Latest Incident: Nepal-Tibet Flood Case
    story.append(Paragraph("1.1 Ground-Truth Evidence: The Nepal–Tibet Glacier Collapse (26 August 2026)", h2_style))
    story.append(Paragraph(
        "The catastrophic glacier-collapse flash flood on <b>26 August 2026</b> represents the most recent, rigorously documented proof of systemic communication blackouts paralyzing disaster response operations. The figures below compile verified field reports from the Nepal National Disaster Risk Reduction and Management Authority (NDRRMA), Reuters, and The Kathmandu Post:",
        body_style
    ))

    # Embed Figure 1: Nepal Metrics
    fig1_path = r"P:\RakshaNet\docs\assets\figures\fig1_nepal_disaster_metrics.png"
    if os.path.exists(fig1_path):
        story.append(RLImage(fig1_path, width=page_w, height=185))
        story.append(Spacer(1, 6))

    # Comprehensive Nepal Evidence Table
    nepal_table_data = [
        [Paragraph("Disaster Dimension", th_style), Paragraph("Official Documented Figures", th_style), Paragraph("Communication & Operational Breakdown", th_style)],
        [Paragraph("<b>Dead & Missing Combined</b>", td_bold),
         Paragraph("<b>Over 7,000 casualties</b><br/>• 1,386 dead in Nepal + 43 in Tibet (1,429)<br/>• 5,130 missing in Nepal + 519 in Tibet (5,649)", td_style),
         Paragraph("Responders had zero last-known coordinates; search teams blindly combed hundreds of square kilometers.", td_style)],
        [Paragraph("<b>Injured & Affected Population</b>", td_bold),
         Paragraph("• <b>6,827 injured</b> survivors<br/>• <b>~1.6 million people affected</b> (NDRRMA)<br/>• 8,317 residential houses destroyed", td_style),
         Paragraph("Critically injured victims in collapsed basements could not signal medical urgency or bleeding status.", td_style)],
        [Paragraph("<b>Telecom Infrastructure Wipeout</b>", td_bold),
         Paragraph("• <b>198 mobile towers offline</b><br/>• 120 Nepal Telecom towers destroyed<br/>• 78 Ncell towers destroyed", td_style),
         Paragraph("<b>Core cellular restoration required 9 full days</b> (until 4 Sept), leaving vast mountainous corridors completely blacked out.", td_style)],
        [Paragraph("<b>Catastrophic Warning Deficit</b>", td_bold),
         Paragraph("• Surge crossed border in <b>7 minutes</b><br/>• Official state alert sent in <b>38 minutes</b>", td_style),
         Paragraph("<b>Negative 31-minute warning window</b>; upstream monitoring sensors were swept away before alarms could fire.", td_style)],
        [Paragraph("<b>Isolated Ghost Settlements</b>", td_bold),
         Paragraph("• <b>Village of Tiru reached on 9 September</b><br/>• <b>15 days after disaster struck</b>", td_style),
         Paragraph("Helicopters flew blind; zero presence heartbeats existed to alert commanders that villagers survived cut-off.", td_style)],
        [Paragraph("<b>Forensics & Family Separation</b>", td_bold),
         Paragraph("• Only <b>4% of ~900 bodies identified</b> by 1 Sept<br/>• <b>540 children separated</b> from parents", td_style),
         Paragraph("Lacking cold storage, unidentified bodies were buried in mass graves; families searched physical bulletin boards.", td_style)],
        [Paragraph("<b>Pilgrim & Foreigner Blackouts</b>", td_bold),
         Paragraph("• <b>587 foreign nationals missing</b> (39 nations)<br/>• 288 Indians missing in Nepal, 49 in Tibet", td_style),
         Paragraph("Pilgrim parties (including 77 Isha Foundation pilgrims) went days without proof-of-life status to anxious families.", td_style)],
        [Paragraph("<b>Financial & Rescue Operations</b>", td_bold),
         Paragraph("• US$2.64B damage; US$4.73B reconstruction<br/>• 21,465 security deployed; 1,348 air sorties", td_style),
         Paragraph("Significant aerial sorties were wasted searching empty riverbanks due to zero digital triage intelligence.", td_style)]
    ]
    t_nepal = Table(nepal_table_data, colWidths=[125, 175, 223.28])
    t_nepal.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), c_navy),
        ('GRID', (0,0), (-1,-1), 0.5, c_border),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [c_white, c_bg_light]),
    ]))
    story.append(t_nepal)
    story.append(Spacer(1, 8))

    # 1.2 Indian Operational Reality & 5 Failures
    story.append(Paragraph("1.2 The Indian Operational Reality & The Five Systemic Failures", h2_style))
    story.append(Paragraph(
        "This is not a foreign anomaly; it is an annual, systemic crisis across India:",
        body_style
    ))
    in_bullets = [
        "<b>Monsoon 2025 Human Toll:</b> Floods and landslides killed ~1,500 people across India, with Himachal Pradesh suffering ~400 fatalities alone.",
        "<b>September 2026 Monsoon Inundations:</b> Flash floods killed 56 people in a 60-hour rain burst; >70,000 citizens were evacuated in Odisha.",
        "<b>July 2026 Himalayan Surges:</b> Cloudbursts and flash floods across Kashmir and Nagaland claimed at least 25 lives.",
        "<b>Historical Human Cost (Parliamentary CWC Data):</b> Central Water Commission records show <b>107,487 flood deaths between 1953 and 2017</b>—averaging ~1,650 fatalities every single year.",
        "<b>Routine Telecommunication Severance:</b> The 2025 Dharali flash flood in Uttarakhand severed telecom and fiber trunks to Gangotri Dham, demonstrating that Indian pilgrimage corridors operate in perpetual communication peril."
    ]
    for b in in_bullets:
        story.append(Paragraph(b, bullet_style))
    story.append(Spacer(1, 5))

    story.append(Paragraph("<b>The Five Structural Failures Proved by Disaster Evidence:</b>", h3_style))
    five_failures = [
        "<b>1. Survivors Cannot Signal:</b> Cellular base stations, power grids, and fiber lines fail exactly when danger peaks.",
        "<b>2. Responders Operate Blind:</b> Coordinators lack headcounts, exact locations, medical urgency, or last-known vectors.",
        "<b>3. Missing-Person Lists Are Unreliable:</b> Unreachable living citizens are listed as missing/dead; unidentified bodies end in mass graves.",
        "<b>4. Search Assets Are Misdirected:</b> Silent cut-off settlements are reached 15 days late; expensive helicopter sorties overlap blindly.",
        "<b>5. Emergency Alerting Is Strictly One-Way:</b> Authorities blast sirens/SMS warnings, but have zero channel to receive feedback or cries for help."
    ]
    for f in five_failures:
        story.append(Paragraph(f, bullet_style))
    story.append(Spacer(1, 10))

    # =============================================================
    # CHAPTER 2: RAKSHANET SYSTEM CONCEPT & ARCHITECTURE
    # =============================================================
    story.append(Paragraph("Chapter 2: The RakshaNet Solution & Technical Architecture", h1_style))
    story.append(Paragraph(
        "RakshaNet (SignalRescue AI) is an <b>offline-first disaster communication, localization, and rescue-intelligence platform</b>. Instead of waiting for cellular restoration or deploying specialized satellite hardware, RakshaNet converts everyday consumer smartphones into an autonomous, temporary local ad-hoc communication network (mesh).",
        body_style
    ))

    story.append(Paragraph("2.1 Pre-Disaster Onboarding & Autonomous Mesh Protocol", h2_style))
    story.append(Paragraph(
        "Users install RakshaNet prior to emergencies during civil preparedness campaigns. The handset caches compressed vector map tiles, geocoded shelters, hospitals, and medical triage runbooks. When cellular towers collapse, the app activates its dual-radio transport:",
        body_style
    ))
    mesh_points = [
        "<b>Bluetooth Low Energy (BLE 5.x):</b> Background advertising and scanning discovers neighboring handsets within 15–50m. Broadcasts micro-packets containing cryptographically signed SOS beacons and presence heartbeats without pairing codes.",
        "<b>Wi-Fi Peer-to-Peer (Wi-Fi Direct / Local SoftAP):</b> Escalates automatically for high-bandwidth local transfers (chat logs, vector maps, casualty records) without requiring wireless routers or internet.",
        "<b>Store-and-Forward Delay-Tolerant Networking (DTN):</b> Packets travel hop-by-hop across physical space (Person A &rarr; Person B &rarr; Person C &rarr; Person D). Handsets act as mobile data mules across kilometers, carrying payloads until any node reaches internet backhaul."
    ]
    for m in mesh_points:
        story.append(Paragraph(m, bullet_style))
    story.append(Spacer(1, 6))

    story.append(Paragraph("2.2 Hardware Location Hierarchy & On-Device Edge AI", h2_style))
    story.append(Paragraph(
        "RakshaNet enforces absolute honesty in spatial reporting, categorizing fixes into three distinct verifiable states:<br/>"
        "• <b>LIVE_GPS:</b> Direct autonomous hardware GNSS receiver lock (satellites transmit one-way timing signals; zero mobile internet required).<br/>"
        "• <b>LAST_KNOWN:</b> Clearly displayed with timestamp delta and drift uncertainty (e.g. <i>'Fix from 24 mins ago, &plusmn;150m'</i>).<br/>"
        "• <b>ESTIMATED_ZONE:</b> When GPS is blocked by rubble or tunnels, multi-anchor RSSI RF proximity trilateration calculates a bounded search circle.<br/>"
        "Simultaneously, a <b>quantized on-device Small Language Model (SLM)</b> parses unstructured, panicked survivor messages (<i>'Water entering 2nd floor, father cannot walk'</i>) into structured emergency records (<b>Flood | 2+ People | Mobility Limited | Urgency: Critical</b>) completely offline.",
        body_style
    ))
    story.append(Spacer(1, 6))

    # Embed Figure 2: Comm Gap
    fig2_path = r"P:\RakshaNet\docs\assets\figures\fig2_communication_gap_anomaly.png"
    if os.path.exists(fig2_path):
        story.append(RLImage(fig2_path, width=page_w, height=175))
        story.append(Spacer(1, 6))

    story.append(Paragraph("2.3 Opportunistic Cloud Ingestion & Spatial Command Operations", h2_style))
    story.append(Paragraph(
        "When any participating phone reaches cellular fringe coverage, an emergency Wi-Fi hotspot, or a satellite terminal, it batch-uploads its buffered outbox with cryptographic deduplication. The cloud backend processes multi-node signals through a three-stage spatial intelligence engine:<br/>"
        "1. <b>DBSCAN Incident Clustering:</b> Aggregates dozens of redundant pings from the same apartment block into one unified incident.<br/>"
        "2. <b>Communication-Gap Detection:</b> Flags sudden heartbeat decay curves (500 &rarr; 430 &rarr; 150 &rarr; 20 nodes) as black holes, alerting commanders to silent villages like Tiru in hours rather than 15 days.<br/>"
        "3. <b>Resource Dispatch Optimization:</b> Linear optimization solver matches rescue fleets (boats, 4WDs, air ambulances) against triage priorities.",
        body_style
    ))
    story.append(Spacer(1, 10))

    # =============================================================
    # CHAPTER 3: COMPLETE 34-FEATURE ARCHITECTURAL SPECIFICATION
    # =============================================================
    story.append(Paragraph("Chapter 3: Complete 34-Feature System Specification", h1_style))
    story.append(Paragraph(
        "RakshaNet's comprehensive capability set spans seven functional pillars, providing end-to-end resilience from civilian handsets to government command centers:",
        body_style
    ))

    # Module 1
    story.append(Paragraph("Pillar I: Core Offline Communication & Mesh Protocol", h2_style))
    p1_feats = [
        "<b>01. One-Tap SOS:</b> Prominent, tactile 1.5s press-and-hold button (with accessible double-tap confirmation). Packages device ID, GPS coordinates, situation type, casualty count, and battery level. Persisted to local SQLite flash memory <i>before</i> over-the-air transmission.",
        "<b>02. Completely Offline Emergency Mode:</b> All essential functions—SOS, chat, location cache, maps, AI triage, and message buffers—remain fully operational without cellular service, ISPs, or cloud servers.",
        "<b>03. Bluetooth (BLE) Device Discovery & Signaling:</b> Autonomous background scanning and advertising using BLE micro-beacons. Broadcasts compact, cryptographically signed distress payloads across 15–50m ranges with minimal battery consumption.",
        "<b>04. Wi-Fi Peer-to-Peer (Wi-Fi Direct) Transport:</b> Dynamically escalates to Wi-Fi P2P / Local SoftAP for high-bandwidth local transfers (chat histories, vector map chunks, batch telemetry) without requiring access points.",
        "<b>05. Multi-Hop Mesh Relay:</b> Packets hop from handset to handset across physical terrain (A &rarr; B &rarr; C &rarr; D). Survivors do not need direct internet; information propagates through moving civilian data mules.",
        "<b>06. Zero-Infrastructure Offline Chat:</b> Local neighborhood conversational channels operating over direct RF. Includes pre-configured one-tap triage replies (<i>'I am safe'</i>, <i>'Need drinking water'</i>, <i>'Trapped under rubble'</i>)."
    ]
    for pf in p1_feats:
        story.append(Paragraph(pf, bullet_style))
    story.append(Spacer(1, 4))

    # Module 2
    story.append(Paragraph("Pillar II: Delay-Tolerant Networking & Protocol Security", h2_style))
    p2_feats = [
        "<b>10. Store-and-Forward DTN System:</b> Transactional outbox persists distress packets across disconnects. Packets remain buffered on intermediate handsets until cryptographic upstream delivery is verified.",
        "<b>11. Message Deduplication & Hash Verification:</b> Every packet is assigned an immutable hash (e.g. <code>SOS-72819-A3F9</code>). Handsets drop duplicate broadcasts instantly, eliminating broadcast storms and RF spectrum congestion.",
        "<b>12. Message TTL & Hop Limits:</b> Configurable hop counters (e.g. <code>TTL = 10 hops</code>) and 72-hour time decay prevent obsolete packets from looping endlessly through the mesh.",
        "<b>27. Adaptive Battery-Aware Mesh Governance:</b> Three operating tiers modulate power draw: Normal (&gt;50%), Emergency (20%–50%), and Critical Battery (&lt;20%, radio duty-cycling, pure OLED dark theme).",
        "<b>28. Cryptographic Security, Privacy & Integrity:</b> Ephemeral Ed25519 signing pairs and AES-256-GCM encryption. Intermediate relay nodes carry encrypted blobs; sensitive civilian medical notes are decryptable only by verified rescue agencies."
    ]
    for pf in p2_feats:
        story.append(Paragraph(pf, bullet_style))
    story.append(Spacer(1, 4))

    # Module 3
    story.append(Paragraph("Pillar III: Offline Localization & Geospatial Mapping", h2_style))
    p3_feats = [
        "<b>07. Offline GPS / Location:</b> Direct autonomous hardware GNSS fixes independent of mobile cellular triangulation. Stores latitude, longitude, altitude, accuracy radius, and hardware timestamp.",
        "<b>08. Bundled Offline Vector Maps:</b> High-compression local MapLibre vector tiles containing road networks, elevation contours, bridges, hospitals, shelters, and designated relief distribution points.",
        "<b>09. GPS-Independent Proximity Estimation:</b> When GPS is blocked by rubble, multi-anchor RSSI RF trilateration calculates relative proximity against neighboring devices with valid fixes, generating an Estimated Emergency Zone (e.g. 100–200m, 67% confidence).",
        "<b>17. Last-Known Presence Timeline:</b> Immutable historical breadcrumb vector trail per device (10:20 Location X &rarr; 10:35 Location Y &rarr; 10:47 Location Z &rarr; Lost Contact), providing responders with bearing vectors.",
        "<b>18. Missing-Person Probabilistic Search Zones:</b> Evaluates last known coordinates, elapsed time delta, terrain slope, and flood current velocities to generate dynamic isochrone probability envelopes for rescue teams."
    ]
    for pf in p3_feats:
        story.append(Paragraph(pf, bullet_style))
    story.append(Spacer(1, 4))

    # Module 4
    story.append(Paragraph("Pillar IV: On-Device Edge & Cloud AI Intelligence", h2_style))
    p4_feats = [
        "<b>13. Lightweight On-Device AI Assistant (SLM):</b> Quantized edge Small Language Model executing locally on device CPU/NPU without cloud connectivity. Provides offline first-aid runbooks and multi-lingual emergency translation.",
        "<b>14. Automated AI Emergency Classification:</b> Translates panicking, unstructured messages into standardized taxonomy (Flood Inundation, Structural Collapse, Medical Trauma) and urgency tiers (Critical, High, Medium, Low).",
        "<b>15. Spatial Incident Clustering (DBSCAN):</b> Spatial clustering engine in the cloud merges 30 separate distress pings from the same apartment building into one master operational incident, estimating total impacted devices.",
        "<b>16. Communication-Gap & Black Hole Anomaly Detection:</b> Analyzes temporal telemetry decay across grid sectors (500 &rarr; 430 &rarr; 150 &rarr; 20 active nodes), automatically dispatching reconnaissance drones to silent sectors.",
        "<b>19. Affected Population & Device Estimation:</b> Statistical inference models distinguish between devices and people (<code>Devices &ne; People</code>), aggregating declared family members in SOS beacons with ambient RF probes.",
        "<b>21. Critical Infrastructure Vulnerability Monitoring:</b> Real-time risk modeling tracking bridges, culverts, electrical substations, and cellular base stations, identifying single-points-of-failure.",
        "<b>22. Cascading Disaster Dependency Analysis:</b> Models multi-stage domino failure chains (Heavy Rain &rarr; Dam Release &rarr; Bridge Washout &rarr; Arterial Severed &rarr; Ambulance Access Blocked)."
    ]
    for pf in p4_feats:
        story.append(Paragraph(pf, bullet_style))
    story.append(Spacer(1, 4))

    # Module 5
    story.append(Paragraph("Pillar V: Rescue Coordination & Agency Command Operations", h2_style))
    p5_feats = [
        "<b>20. Real-Time Disaster Risk & Hazard Overlays:</b> Command dashboard integrates live emergency pins with dynamic GIS layers: flood inundation polygons, road blockages, bridge outages, and hospital intake statuses.",
        "<b>23. Algorithmic Rescue Resource Optimization:</b> Linear dispatch solver evaluates casualty counts, terrain blockages, and vehicle compatibility, generating actionable proposals (Incident A &rarr; Inflatable Boat 02; Incident B &rarr; 4WD Ambulance 01).",
        "<b>24. Unified Government & Agency Command Dashboard:</b> High-performance React Web interface with dark-mode hi-vis styling, color-coded incident priority hierarchy, and real-time WebSocket feeds.",
        "<b>25. Automated Government Dispatch & CAD Ingestion:</b> Automatically compiles emergency signals into Common Alerting Protocol (CAP) and standard Computer Aided Dispatch (CAD) incident tickets for NDRF/SDRF systems.",
        "<b>26. End-to-End Emergency Status Journey Tracking:</b> Transparent 6-stage feedback loop for survivors: Created &rarr; Saved Locally &rarr; Relayed by Peer &rarr; Multi-Hop Transport &rarr; Gateway Upload &rarr; Agency Dispatched."
    ]
    for pf in p5_feats:
        story.append(Paragraph(pf, bullet_style))
    story.append(Spacer(1, 4))

    # Module 6 & 7
    story.append(Paragraph("Pillar VI & VII: Civilian Modes, Hardening & Technical Architecture", h2_style))
    p6_feats = [
        "<b>29. Family & Group Emergency Network:</b> Pre-disaster pairing enables handsets to passively recognize family device IDs in the mesh, displaying distance vectors and status without cell service.",
        "<b>30. One-Tap Safety Check-In ('I AM SAFE'):</b> Non-injured survivors broadcast a green safe beacon, automatically deprecating prior pending SOS tickets and preventing wasted rescue searches.",
        "<b>31. Dynamic Shelter Capacity Intelligence:</b> Offline-accessible shelter registry displaying physical locations and facilities; remaining bed capacities synchronize bidirectionally upon reconnection.",
        "<b>32. Authoritative Emergency Mesh Broadcast:</b> Reverse-direction capability allowing disaster authorities to inject official evacuation directives across all mesh hops, reaching zero-net zones.",
        "<b>33. Technical Architecture & Pipeline:</b> React Native + Native Kotlin Radio Bridges + SQLite + FastAPI Async Gateway + PostGIS Geospatial DB + React Command Center.",
        "<b>34. Core Uniqueness Moat:</b> The complete closed loop connecting offline mesh &rarr; delay-tolerant relay &rarr; edge AI &rarr; cloud clustering &rarr; black hole detection &rarr; search zones &rarr; dispatch solver."
    ]
    for pf in p6_feats:
        story.append(Paragraph(pf, bullet_style))
    story.append(Spacer(1, 10))

    # =============================================================
    # CHAPTER 4: VERIFIED COMPETITOR LANDSCAPE & AUDIT
    # =============================================================
    story.append(Paragraph("Chapter 4: Verified Competitor Landscape & Market Reality Check", h1_style))
    story.append(Paragraph(
        "A rigorous audit of public GitHub repositories, commit logs, and active app store listings across the disaster communication space reveals critical truths regarding what competitors have already shipped and where RakshaNet's defensible moat exists:",
        body_style
    ))

    # Embed Figure 3: Competitor Comparison
    fig3_path = r"P:\RakshaNet\docs\assets\figures\fig3_competitor_comparison_matrix.png"
    if os.path.exists(fig3_path):
        story.append(RLImage(fig3_path, width=page_w, height=180))
        story.append(Spacer(1, 6))

    story.append(Paragraph("4.1 Reality Check & Source Verification (The 6 Corrected Claims)", h2_style))
    story.append(Paragraph(
        "Direct code audits correct several widespread misconceptions in disaster tech pitches:",
        body_style
    ))
    corrections_data = [
        [Paragraph("Common Myth / False Claim", th_style), Paragraph("Ground Truth Verified from Source Code", th_style)],
        [Paragraph("<i>'Sahayata Setu has no offline maps'</i>", td_bold), Paragraph("<b>False:</b> Sahayata Setu includes offline MapLibre maps bundled with OpenStreetMap vector tiles.", td_style)],
        [Paragraph("<i>'Tremour has offline maps'</i>", td_bold), Paragraph("<b>False:</b> Tremour lists no offline maps; its dashboard only binds to a local LAN.", td_style)],
        [Paragraph("<i>'Tremour has offline AI as a core strength'</i>", td_bold), Paragraph("<b>False:</b> Tremour's triage is a basic regex/keyword rule list. Gemma is a stub; its README explicitly notes <i>'Keyword rules, not a real LLM'</i>.", td_style)],
        [Paragraph("<i>'Crisis Connect has missing-person search tools'</i>", td_bold), Paragraph("<b>Unverified:</b> No spatial search zones exist; it only supports manual rescuer sighting feeds.", td_style)],
        [Paragraph("<i>'Crisis Connect Wi-Fi Direct is shipped'</i>", td_bold), Paragraph("<b>Accurate:</b> Wi-Fi Direct remains on their public development roadmap; BLE is primary.", td_style)],
        [Paragraph("<i>'Digital Twin & Device Intelligence are separate features'</i>", td_bold), Paragraph("<b>Terminology Bloat:</b> These are branding synonyms for the spatial data pipeline. Drop them to maintain technical credibility.", td_style)]
    ]
    t_corr = Table(corrections_data, colWidths=[180, 343.28])
    t_corr.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), c_navy),
        ('GRID', (0,0), (-1,-1), 0.5, c_border),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [c_white, c_bg_light]),
    ]))
    story.append(t_corr)
    story.append(Spacer(1, 6))

    story.append(Paragraph("4.2 Three-Tier Capability Matrix: Table-Stakes vs. The Real Moat", h2_style))
    story.append(Paragraph(
        "To establish credibility with senior evaluators, RakshaNet categorizes capabilities with complete transparency:",
        body_style
    ))

    tiers_data = [
        [Paragraph("Classification Tier", th_style), Paragraph("Included Capabilities & Market Status", th_style), Paragraph("Strategic Pitch Guidance", th_style)],
        [Paragraph("<b>Tier A: Already Shipped by Competitors</b>", td_bold),
         Paragraph("One-Tap SOS, Offline Mode, BLE Discovery, Wi-Fi P2P (Tremour/Sahayata), Multi-Hop Relay, Store-and-Forward DTN, Deduplication & TTL, Offline Chat, Offline Vector Maps, On-Device AI Triage (Crisis Connect real LLM, Tremour regex), Battery Governance, Cryptographic Signing/Encryption (Crisis Connect Signal/AES-GCM, Sahayata X25519/AES), Authority Broadcast to Mesh (Tremour mock CAP, Crisis Connect Bridge), Basic Web Dashboard.", td_style),
         Paragraph("<b>DO NOT CLAIM AS UNIQUE.</b> Competitors already ship these. Claiming them as inventions will cause judges to disqualify the pitch.", td_style)],
        [Paragraph("<b>Tier B: Partially Present in Market</b>", td_bold),
         Paragraph("Position Classification (raw coords vs. RakshaNet's LIVE/LAST/ESTIMATED states); Presence History (raw sightings vs. RakshaNet's hop breadcrumb vector); Family Circles (pairing vs. ambient mesh detection); Safety Check-In (text status vs. SOS deprecation beacon); Status Tracking (checkmarks vs. 6-stage CAD pipeline); Hazard GIS (feed widget vs. dynamic flood contour overlay); Agency Alerting (inbound CAP vs. outbound CAP/CAD tickets); Shelter Info (static lists vs. bidirectional capacity sync).", td_style),
         Paragraph("<b>CLAIM ONLY YOUR SPECIFIC TWIST.</b> Frame these as refined operational enhancements over basic consumer implementations.", td_style)],
        [Paragraph("<b>Tier C: True Candidate Differentiators (The Moat)</b>", td_bold),
         Paragraph("<b>1. DBSCAN Spatial Incident Clustering:</b> Merges 30 redundant phone pings into 1 master operational ticket.<br/>"
                   "<b>2. Communication-Gap ('Black Hole') Detection:</b> Flags sudden heartbeat decay curves alerting to cut-off hamlets.<br/>"
                   "<b>3. Probabilistic Search Zones:</b> Isochrone search envelopes generated from drift, slope, and flood currents.<br/>"
                   "<b>4. RSSI Proximity Trilateration:</b> Estimates survivor zones when GPS is zero.<br/>"
                   "<b>5. Devices &ne; People Population Inference:</b> Statistical modeling of impacted headcounts.<br/>"
                   "<b>6. Critical Infrastructure SPoF Monitoring:</b> Real-time bridge and power risk modeling.<br/>"
                   "<b>7. Cascading Disaster Dependency AI:</b> Graph modeling of domino failures.<br/>"
                   "<b>8. Algorithmic Resource Optimization:</b> Linear dispatch solver for boat and medical fleets.<br/>"
                   "<b>9. Closed-Loop Continuum:</b> Mesh &rarr; DTN &rarr; Cloud AI &rarr; Command Center &rarr; Dispatch.", td_style),
         Paragraph("<b>100% UNCONTESTED TERRITORY.</b> Absent from every product and repository audited. Focus 80% of presentation time on these nine capabilities.", td_style)]
    ]
    t_tiers = Table(tiers_data, colWidths=[120, 240, 163.28])
    t_tiers.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), c_navy),
        ('GRID', (0,0), (-1,-1), 0.5, c_border),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('TOPPADDING', (0,0), (-1,-1), 3.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3.5),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [c_white, c_bg_light]),
    ]))
    story.append(t_tiers)
    story.append(Spacer(1, 10))

    # =============================================================
    # CHAPTER 5: HEAD-TO-HEAD DEEP DIVE: RAKSHANET VS CRISIS CONNECT
    # =============================================================
    story.append(Paragraph("Chapter 5: One-on-One Head-to-Head: RakshaNet vs. Crisis Connect", h1_style))
    story.append(Paragraph(
        "<b>Crisis Connect</b> is the undisputed production benchmark in disaster mesh applications (~300,000 lines of code, 611 automated tests, live on Google Play and Apple App Store). A detailed, feature-by-feature evaluation illustrates the fundamental division of scope:",
        body_style
    ))

    h2h_data = [
        [Paragraph("Feature / Capability", th_style), Paragraph("RakshaNet", th_style), Paragraph("Crisis Connect", th_style), Paragraph("Across All Competitors?", th_style), Paragraph("Operational & Architectural Impact", th_style)],
        
        [Paragraph("<b>Offline BLE Mesh Relay</b>", td_bold), Paragraph("Yes (BLE 5.x)", td_style), Paragraph("Yes (GATT)", td_style), Paragraph("All Apps", td_style), Paragraph("Table-stakes baseline for offline packet hop transport.", td_style)],
        [Paragraph("<b>Wi-Fi Direct P2P Transport</b>", td_bold), Paragraph("Yes (Auto)", td_style), Paragraph("Roadmap", td_style), Paragraph("Tremour / Sahayata", td_style), Paragraph("RakshaNet escalates to Wi-Fi Direct for high-throughput data.", td_style)],
        [Paragraph("<b>End-to-End Encryption</b>", td_bold), Paragraph("Design Spec", td_style), Paragraph("<b>Shipped (Signal/AES)</b>", td_style), Paragraph("Crisis / Sahayata", td_style), Paragraph("Crisis Connect leads in cryptographic maturity today.", td_style)],
        [Paragraph("<b>Offline Voice & Media</b>", td_bold), Paragraph("Text / Telemetry", td_style), Paragraph("<b>Shipped (Voice/Files)</b>", td_style), Paragraph("Crisis Connect Only", td_style), Paragraph("RakshaNet deliberately avoids media to preserve critical mesh airtime.", td_style)],
        [Paragraph("<b>On-Device AI Assistant</b>", td_bold), Paragraph("SLM Triage Engine", td_style), Paragraph("<b>Shipped (LiteRT-LM)</b>", td_style), Paragraph("Crisis Connect Only", td_style), Paragraph("Crisis Connect runs a real local LLM; RakshaNet focuses on fast triage.", td_style)],
        [Paragraph("<b>DBSCAN Incident Clustering</b>", td_bold), Paragraph("<b>Yes (Proprietary)</b>", td_style), Paragraph("None (Raw Inbox)", td_style), Paragraph("<b>None</b>", td_style), Paragraph("<b>RakshaNet Exclusive:</b> Merges 30 redundant pings into 1 ticket.", td_style)],
        [Paragraph("<b>Comm-Gap / Black Hole AI</b>", td_bold), Paragraph("<b>Yes (Decay Analysis)</b>", td_style), Paragraph("None", td_style), Paragraph("<b>None</b>", td_style), Paragraph("<b>RakshaNet Exclusive:</b> Flags silent villages (Tiru) within hours.", td_style)],
        [Paragraph("<b>Probabilistic Search Zones</b>", td_bold), Paragraph("<b>Yes (Isochrone Core)</b>", td_style), Paragraph("None (Raw Sightings)", td_style), Paragraph("<b>None</b>", td_style), Paragraph("<b>RakshaNet Exclusive:</b> Generates bounded search circles for rescuers.", td_style)],
        [Paragraph("<b>RSSI Proximity Trilateration</b>", td_bold), Paragraph("<b>Yes (Trilateration)</b>", td_style), Paragraph("None", td_style), Paragraph("<b>None</b>", td_style), Paragraph("<b>RakshaNet Exclusive:</b> Binds survivor zones when GPS is zero.", td_style)],
        [Paragraph("<b>Cascading Failure Risk AI</b>", td_bold), Paragraph("<b>Yes (Graph Engine)</b>", td_style), Paragraph("None", td_style), Paragraph("<b>None</b>", td_style), Paragraph("<b>RakshaNet Exclusive:</b> Models secondary bridge and road collapses.", td_style)],
        [Paragraph("<b>Resource Dispatch Optimizer</b>", td_bold), Paragraph("<b>Yes (Linear Solver)</b>", td_style), Paragraph("None", td_style), Paragraph("<b>None</b>", td_style), Paragraph("<b>RakshaNet Exclusive:</b> Proposes boat, 4WD, and medical allocations.", td_style)],
        [Paragraph("<b>Outbound CAP / CAD Export</b>", td_bold), Paragraph("<b>Yes (Gov Spec)</b>", td_style), Paragraph("None", td_style), Paragraph("<b>None</b>", td_style), Paragraph("<b>RakshaNet Exclusive:</b> Directly feeds official Indian disaster portals.", td_style)],
        [Paragraph("<b>Verified Responder ID</b>", td_bold), Paragraph("Roadmap", td_style), Paragraph("<b>Shipped (X.509)</b>", td_style), Paragraph("Crisis Connect Only", td_style), Paragraph("Crisis Connect leads in preventing rescuer spoofing; RakshaNet will adopt.", td_style)]
    ]
    t_h2h = Table(h2h_data, colWidths=[105, 75, 75, 60, 208.28])
    t_h2h.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), c_navy),
        ('GRID', (0,0), (-1,-1), 0.5, c_border),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING', (0,0), (-1,-1), 2.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2.5),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [c_white, c_bg_light]),
    ]))
    story.append(t_h2h)
    story.append(Spacer(1, 6))

    story.append(Paragraph("5.1 Where Competitors Beat You Today (Honest Weakness Analysis)", h2_style))
    story.append(Paragraph(
        "Acknowledging where competitors lead builds unassailable engineering credibility:<br/>"
        "• <b>Cryptographic Maturity:</b> Crisis Connect and Sahayata Setu have shipped live end-to-end encryption (Signal Protocol / AES-GCM). RakshaNet's is currently a specification.<br/>"
        "• <b>Production Platform Scope:</b> Crisis Connect runs cross-platform on Android and iOS with 611 unit tests. RakshaNet is currently an Android-first prototype.<br/>"
        "• <b>Rich Media Support:</b> Crisis Connect supports offline voice calls and images; RakshaNet intentionally restricts payloads to text and telemetry to conserve mesh airtime.<br/>"
        "• <b>Verified Responder Trust:</b> Crisis Connect issues cryptographically signed responder role certificates, mitigating fake-SOS spoofing.",
        body_style
    ))
    story.append(Spacer(1, 6))

    story.append(Paragraph("5.2 The Fundamental Strategic Differentiation", h2_style))
    story.append(Paragraph(
        "<b>Crisis Connect answers:</b> <i>'How do trapped civilians chat with responders when cellular towers fall?'</i> (A survivor-to-responder messenger routing conversations into an agency inbox).<br/><br/>"
        "<b>RakshaNet answers:</b> <i>'How do disaster commanders decide where to deploy limited boats and helicopters first when all networks fall?'</i> (An operational spatial intelligence engine clustering thousands of fragmented pings, identifying who went dark, and optimizing resource dispatches).",
        body_bold
    ))
    story.append(Spacer(1, 10))

    # =============================================================
    # CHAPTER 6: QUANTITATIVE IMPACT MODEL & PRE-PITCH STRATEGY
    # =============================================================
    story.append(Paragraph("Chapter 6: Quantitative Impact Model & Winning Pitch Strategy", h1_style))
    story.append(Paragraph(
        "Responsible disaster analytics avoids unverified 'lives saved' claims. Instead, utility in delay-tolerant mesh networks scales directly with <b>community pre-installation and device density</b>. Applying this mathematical model against the verified baseline of the Nepal 2026 disaster yields tangible, adoption-dependent projections:",
        body_style
    ))

    # Embed Figure 4: Impact model
    fig4_path = r"P:\RakshaNet\docs\assets\figures\fig4_adoption_impact_model.png"
    if os.path.exists(fig4_path):
        story.append(RLImage(fig4_path, width=page_w, height=170))
        story.append(Spacer(1, 6))

    # Impact table
    impact_data = [
        [Paragraph("Projected Operational Impact Metric", th_style), Paragraph("Mathematical Basis", th_style), Paragraph("5% Adoption", th_style), Paragraph("15% Adoption", th_style), Paragraph("30% Adoption", th_style)],
        [Paragraph("<b>Casualties with Last-Known Fix & Time</b>", td_bold),
         Paragraph("6,516 (Nepal dead + missing) &times; Adoption Rate", td_style),
         Paragraph("<b>~326</b>", td_style), Paragraph("<b>~977</b>", td_style), Paragraph("<b>~1,955</b>", td_style)],
        [Paragraph("<b>Injured Civilians Triggering Mesh SOS</b>", td_bold),
         Paragraph("6,827 (Injured survivors) &times; Adoption Rate", td_style),
         Paragraph("<b>~341</b>", td_style), Paragraph("<b>~1,024</b>", td_style), Paragraph("<b>~2,048</b>", td_style)],
        [Paragraph("<b>Missing Entries Cleared by 'I AM SAFE'</b>", td_bold),
         Paragraph("Assumes 10–20% of 5,130 missing were alive but unreachable &times; Adoption", td_style),
         Paragraph("<b>26 – 51</b>", td_style), Paragraph("<b>77 – 154</b>", td_style), Paragraph("<b>154 – 308</b>", td_style)],
        [Paragraph("<b>Wasted Helicopter Sorties Eliminated</b>", td_bold),
         Paragraph("Assumes 10–20% reduction in duplicate/blind runs of 1,348 sorties", td_style),
         Paragraph("<b>135 – 270</b>", td_style), Paragraph("<b>135 – 270</b>", td_style), Paragraph("<b>135 – 270</b>", td_style)]
    ]
    t_imp = Table(impact_data, colWidths=[140, 150, 70, 75, 88.28])
    t_imp.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), c_navy),
        ('GRID', (0,0), (-1,-1), 0.5, c_border),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [c_white, c_bg_light]),
    ]))
    story.append(t_imp)
    story.append(Spacer(1, 6))

    story.append(Paragraph("6.1 Qualitative Impact Transformations & Honest Limits", h2_style))
    qual_points = [
        "<b>Autonomous Silent-Village Discovery:</b> Instead of requiring 15 days for helicopters to discover Tiru, RakshaNet flags a severe communication blackout within hours.",
        "<b>Rapid Post-Mortem Identification:</b> Cryptographically signed presence trails match recovered bodies against missing-person registries, mitigating mass unidentified burials.",
        "<b>Passive Group Verification:</b> Pre-paired pilgrim parties (such as the 77 stranded Isha Foundation pilgrims) confirm member safety locally during total cellular collapse.",
        "<b>Honest Post-Impact Reality:</b> RakshaNet coordinates post-disaster search and triage; it does not claim to prevent structural destruction from high-velocity flash floods.",
        "<b>RF Terrain Attenuation:</b> BLE spans 15–50m. In deep Himalayan ravines, node density is low until aerial data mules (helicopters or drones) bridge isolated sectors."
    ]
    for qp in qual_points:
        story.append(Paragraph(qp, bullet_style))
    story.append(Spacer(1, 6))

    story.append(Paragraph("6.2 High-Impact Presentation Slide Numbers & Pitch Strategy", h2_style))
    story.append(Paragraph(
        "<b>Key Slide Numbers:</b> 1,429 dead & 5,649 missing in one event (Nepal 2026)  |  1.6 million affected  |  38-min warning delay vs 7-min surge  |  15 days to reach village Tiru  |  1,500 annual monsoon deaths across India.<br/><br/>"
        "<b>Pitch Anchor Line:</b> <i>\"In the next disaster, every silent phone should still leave a trail.\"</i><br/><br/>"
        "<b>Defensible Claims:</b> <i>'Mesh apps route messages. RakshaNet turns decentralized, chaotic signals into prioritized incidents, search envelopes, and optimized boat dispatch plans.'</i> &bull; <i>'We detect who has abruptly gone silent, not just who is talking.'</i><br/><br/>"
        "<b>Claims to Avoid:</b> <i>'First offline SOS app'</i> (False), <i>'First mesh app'</i> (False), <i>'Unique offline AI'</i> (False: Crisis Connect has real LLM).",
        body_style
    ))
    story.append(Spacer(1, 8))

    # PRE-PITCH CHECKLIST
    pre_pitch_box = [
        [Paragraph("<b>Pre-Pitch 5-Point Execution Action Plan:</b>", ParagraphStyle('PlanHead', fontName='Helvetica-Bold', fontSize=8.5, leading=11, textColor=c_navy))],
        [Paragraph(
            "<b>1. Demo 3 Moat Features Live:</b> Build interactive web prototypes demonstrating DBSCAN clustering of 50 pings, a visual comm-gap black hole alert, and an expanding search zone.<br/>"
            "<b>2. Build a 150-Node Mesh Simulator (<code>simulate_mesh.py</code>):</b> Feed simulated device hops into the dashboard. Evaluators trust measured telemetry over theoretical claims.<br/>"
            "<b>3. Include a Transparent Competitor Slide:</b> Explicitly name Crisis Connect, acknowledging their production maturity while establishing your intelligence layer.<br/>"
            "<b>4. Focus Presentation on the Core 8 Features:</b> Pitch Tactile SOS, Store-and-Forward Mesh, Edge Triage, Opportunistic Sync, DBSCAN Clustering, Comm-Gap AI, Search Zones, and Dispatch Optimization.<br/>"
            "<b>5. Master the Inevitable Question:</b> <i>'Crisis Connect already has rescue ops. How are you different?'</i> &rarr; <b>'They route individual conversations to an inbox. RakshaNet analyzes the macroscopic disaster picture and tells commanders where to deploy limited boats first.'</b>",
            ParagraphStyle('PlanBody', fontName='Helvetica', fontSize=8.0, leading=11.5, textColor=c_slate)
        )]
    ]
    t_plan = Table(pre_pitch_box, colWidths=[page_w])
    t_plan.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#EFF6FF")),
        ('BOX', (0,0), (-1,-1), 1, c_teal),
        ('TOPPADDING', (0,0), (-1,-1), 6),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('LEFTPADDING', (0,0), (-1,-1), 10),
        ('RIGHTPADDING', (0,0), (-1,-1), 10),
    ]))
    story.append(t_plan)

    # Build PDF
    doc.build(story, canvasmaker=NumberedCanvas)
    print("Successfully built rebuilt PDF dossier at:", pdf_path)

if __name__ == "__main__":
    build_pdf()
