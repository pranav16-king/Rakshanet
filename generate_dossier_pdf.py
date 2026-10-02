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
            self.setFont("Helvetica-Bold", 8)
            self.setFillColor(colors.HexColor("#0B1220"))
            self.drawString(margin, h - 24, "RAKSHANET (SIGNALRESCUE AI)")
            self.setFont("Helvetica", 8)
            self.setFillColor(colors.HexColor("#475569"))
            self.drawString(margin + 155, h - 24, "|   Offline Disaster Mesh & Rescue Intelligence System")
            
            self.setFont("Helvetica-Bold", 8)
            self.setFillColor(colors.HexColor("#0E8A94"))
            self.drawRightString(w - margin, h - 24, "TECHNICAL DOSSIER & COMPETITOR REPORT")
            
            self.setStrokeColor(colors.HexColor("#CBD5E1"))
            self.setLineWidth(0.6)
            self.line(margin, h - 28, w - margin, h - 28)

        # Running Footer (all pages)
        self.setStrokeColor(colors.HexColor("#E2E8F0"))
        self.setLineWidth(0.6)
        self.line(margin, 26, w - margin, 26)

        self.setFont("Helvetica", 7.5)
        self.setFillColor(colors.HexColor("#64748B"))
        self.drawString(margin, 16, "RakshaNet Comprehensive System Dossier  |  Offline DTN Mesh  |  DBSCAN Spatial AI  |  Rescue Ops")
        
        page_str = f"Page {self._pageNumber} of {total_pages}"
        self.setFont("Helvetica-Bold", 7.5)
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

    # Typography styles
    title_style = ParagraphStyle(
        'DocTitle',
        fontName='Helvetica-Bold',
        fontSize=18,
        leading=22,
        textColor=c_navy,
        spaceAfter=4
    )
    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        fontName='Helvetica',
        fontSize=10,
        leading=14,
        textColor=c_teal,
        spaceAfter=12
    )
    h1_style = ParagraphStyle(
        'Heading1_Custom',
        fontName='Helvetica-Bold',
        fontSize=13,
        leading=16,
        textColor=c_navy,
        spaceBefore=12,
        spaceAfter=6,
        keepWithNext=True
    )
    h2_style = ParagraphStyle(
        'Heading2_Custom',
        fontName='Helvetica-Bold',
        fontSize=10.5,
        leading=13.5,
        textColor=c_teal,
        spaceBefore=8,
        spaceAfter=4,
        keepWithNext=True
    )
    body_style = ParagraphStyle(
        'Body_Custom',
        fontName='Helvetica',
        fontSize=8.5,
        leading=11.5,
        textColor=c_text,
        spaceAfter=5
    )
    body_bold = ParagraphStyle(
        'BodyBold_Custom',
        fontName='Helvetica-Bold',
        fontSize=8.5,
        leading=11.5,
        textColor=c_text,
        spaceAfter=5
    )
    bullet_style = ParagraphStyle(
        'Bullet_Custom',
        fontName='Helvetica',
        fontSize=8.2,
        leading=11,
        textColor=c_text,
        leftIndent=12,
        spaceAfter=3
    )
    callout_style = ParagraphStyle(
        'Callout_Custom',
        fontName='Helvetica-Oblique',
        fontSize=8.5,
        leading=12,
        textColor=c_navy
    )
    th_style = ParagraphStyle(
        'TableHeader',
        fontName='Helvetica-Bold',
        fontSize=7.8,
        leading=9.5,
        textColor=c_white,
        alignment=0
    )
    td_style = ParagraphStyle(
        'TableCell',
        fontName='Helvetica',
        fontSize=7.5,
        leading=9.5,
        textColor=c_text
    )
    td_bold = ParagraphStyle(
        'TableCellBold',
        fontName='Helvetica-Bold',
        fontSize=7.5,
        leading=9.5,
        textColor=c_text
    )

    story = []

    # -------------------------------------------------------------
    # COVER / HEADER BANNER
    # -------------------------------------------------------------
    banner_data = [
        [
            Paragraph("<b>RAKSHANET (SIGNALRESCUE AI)</b>", title_style),
            Paragraph("<b>STATUS:</b> PRODUCTION DOSSIER<br/><b>EDITION:</b> OCTOBER 2026", ParagraphStyle('Badge', fontName='Helvetica-Bold', fontSize=8, leading=10, textColor=c_teal, alignment=2))
        ],
        [
            Paragraph("Offline Disaster Communication, Delay-Tolerant Mesh & AI Rescue Intelligence Platform", subtitle_style),
            Paragraph("Smart India Hackathon 2026", ParagraphStyle('SubBadge', fontName='Helvetica', fontSize=8, leading=10, textColor=c_slate, alignment=2))
        ]
    ]
    banner_table = Table(banner_data, colWidths=[370, 153.28])
    banner_table.setStyle(TableStyle([
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('BOTTOMPADDING', (0,0), (-1,-1), 0),
        ('TOPPADDING', (0,0), (-1,-1), 0),
    ]))
    story.append(banner_table)
    story.append(HRFlowable(width="100%", thickness=1.5, color=c_navy, spaceBefore=4, spaceAfter=8))

    # EXECUTIVE CALLOUT BOX
    pitch_text = "<b>The Central Mission:</b> When catastrophic floods and glacier collapses destroy all telecommunication towers and power grids, survivors cannot signal, and emergency rescue agencies act blind. <b>RakshaNet turns ordinary smartphones into an autonomous store-and-forward mesh</b>, capturing offline distress signals and converting them into <b>prioritized incidents, probabilistic search zones, and optimized dispatch plans</b> the moment any single handset encounters backhaul connectivity."
    callout_box = Table([[Paragraph(pitch_text, callout_style)]], colWidths=[page_w])
    callout_box.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#FEF9C3")),
        ('BOX', (0,0), (-1,-1), 1, c_yellow),
        ('TOPPADDING', (0,0), (-1,-1), 6),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('LEFTPADDING', (0,0), (-1,-1), 10),
        ('RIGHTPADDING', (0,0), (-1,-1), 10),
    ]))
    story.append(callout_box)
    story.append(Spacer(1, 8))

    # -------------------------------------------------------------
    # SECTION 1: THE REAL PROBLEM & EMPIRICAL DISASTER CASE
    # -------------------------------------------------------------
    story.append(Paragraph("1. The Real Problem & Empirical Disaster Evidence", h1_style))
    story.append(Paragraph(
        "Modern disaster response faces a recurring catastrophic failure mode: <b>telecommunication infrastructure fails exactly when human survival depends upon it most</b>. When cellular base stations lose power, backhaul fiber-optic lines are severed by landslides, and bridges wash away, victims are rendered entirely silent. Responders deploy without knowing who is alive, where survivors are clustered, or which isolated settlements require immediate airlifts.",
        body_style
    ))

    # Ground-truth incident: Nepal-Tibet Flood Case
    story.append(Paragraph("<b>The Ground-Truth Evidence: Nepal–Tibet Glacier-Collapse Floods (26 August 2026)</b>", h2_style))
    story.append(Paragraph(
        "The trans-Himalayan glacial outburst flood on 26 August 2026 provides undeniable empirical proof of systemic communication collapse paralyzing disaster coordination (verified figures sourced from official NDRRMA, Reuters, and Kathmandu Post compilations):",
        body_style
    ))

    # Embed Figure 1
    fig1_path = r"P:\RakshaNet\docs\assets\figures\fig1_nepal_disaster_metrics.png"
    if os.path.exists(fig1_path):
        story.append(RLImage(fig1_path, width=page_w, height=195))
        story.append(Spacer(1, 6))

    # Detailed statistics table
    nepal_stats = [
        [Paragraph("Disaster Impact Metric", th_style), Paragraph("Official Documented Scale", th_style), Paragraph("Systemic Operational Breakdown", th_style)],
        [Paragraph("Combined Dead & Missing", td_bold), Paragraph("<b>Over 7,000 casualties</b> (1,429 dead + 5,649 missing)", td_style), Paragraph("Absence of last-known coordinates forced blind multi-valley searches.", td_style)],
        [Paragraph("Injured & Affected Population", td_bold), Paragraph("<b>6,827 injured</b>; <b>~1.6 million civilians</b> impacted", td_style), Paragraph("Medical triage was impossible; survivors had zero outbound SOS channel.", td_style)],
        [Paragraph("Cellular Infrastructure Destruction", td_bold), Paragraph("<b>198 mobile towers offline</b> (120 Nepal Telecom, 78 Ncell)", td_style), Paragraph("<b>Core restoration required 9 days</b>, leaving vast regions in complete radio silence.", td_style)],
        [Paragraph("Critical Early Warning Latency", td_bold), Paragraph("Surge reached border in <b>7 mins</b>; alert sent in <b>38 mins</b>", td_style), Paragraph("Negative 31-minute warning deficit; sensors were swept away before alerting.", td_style)],
        [Paragraph("Cut-Off Isolated Settlements", td_bold), Paragraph("Village of <b>Tiru reached on 9 September (15 days late)</b>", td_style), Paragraph("Helicopters had zero presence telemetry indicating trapped villagers remained alive.", td_style)],
        [Paragraph("Forensic & Family Identification", td_bold), Paragraph("Only <b>4% of ~900 recovered bodies</b> identified by 1 Sept", td_style), Paragraph("Unidentified victims buried in mass graves; 540 separated children searched manually.", td_style)],
        [Paragraph("Pilgrim & Foreigner Blackout", td_bold), Paragraph("<b>587 foreign nationals missing</b> (288 Indians in Nepal)", td_style), Paragraph("Parties (including 77 Isha Foundation pilgrims) spent days without proof-of-life status.", td_style)]
    ]
    t_nepal = Table(nepal_stats, colWidths=[140, 160, 223.28])
    t_nepal.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), c_navy),
        ('GRID', (0,0), (-1,-1), 0.5, c_border),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [c_white, c_bg_light]),
    ]))
    story.append(t_nepal)
    story.append(Spacer(1, 6))

    # Indian Operational Context
    story.append(Paragraph("<b>The Indian Operational Reality:</b> Floods and landslides in the 2025 monsoon claimed ~1,500 lives across India (~400 in Himachal Pradesh alone). Parliamentary Central Water Commission data reveals <b>107,487 flood deaths between 1953 and 2017</b> (~1,650 annually). In July–September 2026, floods evacuated >70,000 citizens in Odisha and severed fiber trunks to Gangotri Dham in Uttarakhand. Telecommunication failure is a routine, annual Indian crisis.", body_style))
    story.append(Spacer(1, 8))

    # -------------------------------------------------------------
    # SECTION 2: RAKSHANET SOLUTION & SYSTEM ARCHITECTURE
    # -------------------------------------------------------------
    story.append(Paragraph("2. Our Idea & Technical Solution: RakshaNet", h1_style))
    story.append(Paragraph(
        "RakshaNet (SignalRescue AI) is an <b>offline-first disaster communication, localization, and rescue-intelligence system</b>. Instead of relying on expensive specialized satellite phones, RakshaNet converts consumer smartphones into an ad-hoc local communication mesh:",
        body_style
    ))

    sol_bullets = [
        "<b>1. Zero-Infrastructure P2P Mesh:</b> Combines Bluetooth Low Energy (BLE) micro-beacons for background peer discovery with Wi-Fi Direct for high-bandwidth local data transfers.",
        "<b>2. Multi-Hop Store-and-Forward DTN:</b> Messages jump opportunistically from phone to phone (A &rarr; B &rarr; C &rarr; D). Devices act as data mules across kilometers without simultaneous network paths.",
        "<b>3. Transparent Location Hierarchy:</b> Categorizes fixes into strict verifiable states: <code>LIVE_GPS</code>, <code>LAST_KNOWN</code> (with time delta and drift uncertainty), and <code>ESTIMATED_ZONE</code> (multi-anchor RSSI).",
        "<b>4. Lightweight On-Device AI:</b> Quantized edge SLM extracts structured triage taxonomy (Disaster Type, Casualty Headcount, Vulnerability, Urgency) without internet connectivity.",
        "<b>5. Opportunistic Cloud Ingestion:</b> When any node touches cellular, satellite, or emergency Wi-Fi backhaul, it batch-uploads its buffered outbox with cryptographic deduplication.",
        "<b>6. Macroscopic AI Command Center:</b> Evaluates raw multi-node telemetry to generate spatial incident clusters, communication-gap anomalies, and automated rescue boat dispatch proposals."
    ]
    for b in sol_bullets:
        story.append(Paragraph(b, bullet_style))
    story.append(Spacer(1, 6))

    # Embed Figure 2: Communication Gap
    fig2_path = r"P:\RakshaNet\docs\assets\figures\fig2_communication_gap_anomaly.png"
    if os.path.exists(fig2_path):
        story.append(RLImage(fig2_path, width=page_w, height=170))
        story.append(Spacer(1, 6))

    story.append(Paragraph("<b>The Closed-Loop Formula:</b> <i>Offline P2P Mesh &rarr; Delay-Tolerant Relay &rarr; Edge AI Triage &rarr; Opportunistic Gateway &rarr; Spatial Clustering &rarr; Comm-Gap Black Hole Detection &rarr; Search Isochrones &rarr; Optimized Resource Dispatch.</i>", body_bold))
    story.append(Spacer(1, 8))

    # -------------------------------------------------------------
    # SECTION 3: COMPLETE FEATURE SET (34 FEATURES)
    # -------------------------------------------------------------
    story.append(PageBreak())
    story.append(Paragraph("3. Complete Feature Architecture (34 Features Across 7 Pillars)", h1_style))
    story.append(Paragraph(
        "RakshaNet's comprehensive feature set spans the complete disaster lifecycle, from pre-crisis preparation on individual handsets to macro-level agency command:",
        body_style
    ))

    feat_matrix = [
        [Paragraph("Pillar", th_style), Paragraph("#", th_style), Paragraph("Feature Name", th_style), Paragraph("Core Architectural Capability & Impact", th_style)],
        
        # Pillar 1
        [Paragraph("<b>I. Core Mesh & P2P</b>", td_bold), Paragraph("01<br/>02<br/>03<br/>04<br/>05<br/>06", td_style),
         Paragraph("One-Tap SOS<br/>Offline Emergency Mode<br/>Bluetooth BLE Discovery<br/>Wi-Fi Direct Transport<br/>Multi-Hop Relay<br/>Offline P2P Chat", td_bold),
         Paragraph("1.5s hold-to-send tactile SOS; instant local SQLite persistence.<br/>Functions with zero cellular, ISP, or tower connectivity.<br/>Background BLE advertising/scanning with micro-packet payloads.<br/>High-throughput data transfers negotiated without routers.<br/>Opportunistic delay-tolerant packet travel across phone chains.<br/>Direct civilian-to-civilian neighborhood messaging & quick replies.", td_style)],
        
        # Pillar 2
        [Paragraph("<b>II. Protocol & Resilience</b>", td_bold), Paragraph("10<br/>11<br/>12<br/>27<br/>28", td_style),
         Paragraph("Store-and-Forward DTN<br/>Message Deduplication<br/>Message TTL Limits<br/>Battery-Aware Mesh<br/>Cryptographic Security", td_bold),
         Paragraph("Transactional persistence buffers distress packets until upload confirmed.<br/>Deterministic hashing drops duplicate broadcasts, preventing RF storms.<br/>Configurable hop counts (e.g. 10 hops) prevent stale packet loops.<br/>Three tiers (Normal, Emergency, Critical &lt;20%) throttle radio draw.<br/>Ed25519 asymmetric signatures and AES-GCM encrypted payloads.", td_style)],

        # Pillar 3
        [Paragraph("<b>III. Location & Mapping</b>", td_bold), Paragraph("07<br/>08<br/>09<br/>17<br/>18", td_style),
         Paragraph("Offline GPS Cache<br/>Bundled Offline Maps<br/>Proximity Localization<br/>Last-Known Presence<br/>Probabilistic Search Zone", td_bold),
         Paragraph("Autonomous GNSS receiver locks independent of mobile network.<br/>Local vector tiles of roads, shelters, clinics, and relief depots.<br/>RSSI multi-anchor trilateration estimates zone when GPS blocked.<br/>Hop-by-hop breadcrumb vector timeline per device for search teams.<br/>Dynamic isochrone search envelope calculated from drift and current.", td_style)],

        # Pillar 4
        [Paragraph("<b>IV. Edge & Cloud AI</b>", td_bold), Paragraph("13<br/>14<br/>15<br/>16<br/>19<br/>21<br/>22", td_style),
         Paragraph("On-Device SLM AI<br/>Emergency Classification<br/>Incident Clustering<br/>Comm-Gap Detection<br/>Population Estimation<br/>Infrastructure Vulnerability<br/>Cascading Disaster AI", td_bold),
         Paragraph("Quantized edge model parses unstructured panicking text offline.<br/>Categorizes dispatches (Flood, Trapped, Medical) & urgency tier.<br/>DBSCAN clusters 30 redundant phone pings into 1 unified incident.<br/>Identifies severe telemetry decay (500&rarr;20 nodes) indicating blackout.<br/>Infers civilian headcounts using Devices &ne; People statistical models.<br/>Monitors single-point-of-failure bridges, culverts, and substations.<br/>Models domino dependencies (Rain &rarr; Bridge Cut &rarr; Hospital Blocked).", td_style)],

        # Pillar 5
        [Paragraph("<b>V. Command & Dispatch</b>", td_bold), Paragraph("20<br/>23<br/>24<br/>25<br/>26", td_style),
         Paragraph("Disaster Risk Overlays<br/>Resource Optimization<br/>Government Dashboard<br/>Automated CAD Ingestion<br/>Status Tracking Journey", td_bold),
         Paragraph("Real-time GIS integration with live flood boundaries & road washouts.<br/>Linear solver proposes boat, 4WD, and medical team allocations.<br/>React Web command center with dark-mode hi-vis incident hierarchy.<br/>Exports Common Alerting Protocol (CAP) & CAD incident tickets.<br/>6-stage survivor state machine confirming message progress to dispatch.", td_style)],

        # Pillar 6
        [Paragraph("<b>VI. Civilian Modes</b>", td_bold), Paragraph("29<br/>30<br/>31<br/>32", td_style),
         Paragraph("Family Emergency Network<br/>Safety Check-In<br/>Shelter Intelligence<br/>Emergency Mesh Broadcast", td_bold),
         Paragraph("Pre-formed circles recognize family device IDs in the local mesh.<br/>'I AM SAFE' one-tap beacon supersedes earlier pending SOS packets.<br/>Offline shelter capacities synchronized bidirectionally upon reconnection.<br/>Official agency evacuation directives propagate reverse-hop through mesh.", td_style)],

        # Pillar 7
        [Paragraph("<b>VII. Architecture & Moat</b>", td_bold), Paragraph("33<br/>34", td_style),
         Paragraph("Technology Pipeline<br/>Closed-Loop Moat", td_bold),
         Paragraph("React Native + Kotlin Radio Bridges + SQLite + FastAPI + PostGIS.<br/>Unbroken continuum from zero-net phone to agency command decisions.", td_style)]
    ]
    t_feat = Table(feat_matrix, colWidths=[95, 30, 135, 263.28])
    t_feat.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), c_navy),
        ('GRID', (0,0), (-1,-1), 0.5, c_border),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [c_white, c_bg_light]),
    ]))
    story.append(t_feat)
    story.append(Spacer(1, 8))

    # -------------------------------------------------------------
    # SECTION 4: MACRO COMPETITOR ANALYSIS
    # -------------------------------------------------------------
    story.append(PageBreak())
    story.append(Paragraph("4. Verified Competitor Landscape & Reality Check", h1_style))
    story.append(Paragraph(
        "A rigorous audit of production repositories, commits, and store listings across the offline disaster ecosystem establishes what competitors have already shipped and where RakshaNet's defensible moat exists:",
        body_style
    ))

    # Embed Figure 3: Competitor Comparison
    fig3_path = r"P:\RakshaNet\docs\assets\figures\fig3_competitor_comparison_matrix.png"
    if os.path.exists(fig3_path):
        story.append(RLImage(fig3_path, width=page_w, height=185))
        story.append(Spacer(1, 6))

    # Profiles table
    comp_profiles = [
        [Paragraph("Competitor Application", th_style), Paragraph("Deployment & Architecture", th_style), Paragraph("Verified Strengths", th_style), Paragraph("Critical Gaps & Limitations", th_style)],
        [Paragraph("<b>Crisis Connect</b><br/>(Primary Rival)", td_bold),
         Paragraph("Live Production on Google Play & App Store (~300k LOC, 611 tests). React Native / Native.", td_style),
         Paragraph("AES-256-GCM / Signal Protocol encryption; on-device LiteRT-LM assistant; offline voice calls & media; rescuer certificates.", td_style),
         Paragraph("<b>Zero spatial clustering</b>, zero comm-gap detection, zero search zones, no resource optimization, no CAD/CAP export.", td_style)],
        [Paragraph("<b>Tremour</b><br/>(Hackathon PoC)", td_bold),
         Paragraph("Open-source PoC (2 commits). Flutter + Google Nearby Connections.", td_style),
         Paragraph("Wi-Fi Direct & BLE; Ed25519 signing; priority queues; <b>mock CAP gateway injecting official alerts into mesh</b>.", td_style),
         Paragraph("No payload encryption; regex keyword triage (no real LLM); local LAN dashboard only; abandoned codebase.", td_style)],
        [Paragraph("<b>Sahayata Setu</b><br/>(Relief App)", td_bold),
         Paragraph("Flutter-based community relief application.", td_style),
         Paragraph("BLE & Wi-Fi mesh; Ed25519 + X25519 + AES-GCM encryption; offline MapLibre maps; missing-person photo boards.", td_style),
         Paragraph("<b>Zero cloud pipeline</b>; no command center dashboard; strictly peer-to-peer volunteer tool.", td_style)],
        [Paragraph("<b>General Messengers</b><br/>(Bridgefy, Briar)", td_bold),
         Paragraph("Commercial / FOSS Bluetooth chat apps.", td_style),
         Paragraph("Proven multi-hop BLE relay across large crowds (protests, festivals).", td_style),
         Paragraph("Generic chat only; <b>zero disaster schemas, zero triage, zero rescue agency integration</b>.", td_style)]
    ]
    t_comp = Table(comp_profiles, colWidths=[100, 125, 145, 153.28])
    t_comp.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), c_navy),
        ('GRID', (0,0), (-1,-1), 0.5, c_border),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [c_white, c_bg_light]),
    ]))
    story.append(t_comp)
    story.append(Spacer(1, 6))

    story.append(Paragraph("<b>The Reality Check for Pitching:</b>", h2_style))
    story.append(Paragraph("• <b>Do NOT claim as unique:</b> BLE mesh, One-Tap SOS, offline maps, store-and-forward, on-device AI, or encryption. Competitors have shipped all of these.", bullet_style))
    story.append(Paragraph("• <b>The True Uncontested Moat:</b> The <b>decision-support intelligence layer</b> built on top of the mesh. None of the audited apps possess incident clustering, communication black hole detection, probabilistic search zones, or dispatch solvers.", bullet_style))
    story.append(Spacer(1, 8))

    # -------------------------------------------------------------
    # SECTION 5: ONE-ON-ONE DEEP DIVE: RAKSHANET VS CRISIS CONNECT
    # -------------------------------------------------------------
    story.append(PageBreak())
    story.append(Paragraph("5. One-on-One Head-to-Head: RakshaNet vs. Crisis Connect", h1_style))
    story.append(Paragraph(
        "<b>Crisis Connect</b> is the undisputed benchmark in the disaster mesh category. A detailed, feature-by-feature matrix reveals the precise boundary between Crisis Connect's communication focus and RakshaNet's operational command focus:",
        body_style
    ))

    head_to_head = [
        [Paragraph("Feature / Capability", th_style), Paragraph("RakshaNet", th_style), Paragraph("Crisis Connect", th_style), Paragraph("All Competitors?", th_style), Paragraph("Architectural & Operational Impact", th_style)],
        
        # Core comms
        [Paragraph("Offline BLE Mesh Relay", td_bold), Paragraph("Yes (BLE 5.x)", td_style), Paragraph("Yes (GATT)", td_style), Paragraph("All Apps", td_style), Paragraph("Standard table-stakes baseline for offline disaster networking.", td_style)],
        [Paragraph("Wi-Fi Direct P2P Transport", td_bold), Paragraph("Yes (Auto)", td_style), Paragraph("Roadmap", td_style), Paragraph("Tremour Only", td_style), Paragraph("RakshaNet escalates to Wi-Fi P2P for bulk data; Crisis Connect uses BLE.", td_style)],
        [Paragraph("End-to-End Encryption", td_bold), Paragraph("Design (AES/Ed25519)", td_style), Paragraph("<b>Shipped (AES/Signal)</b>", td_style), Paragraph("Crisis/Sahayata", td_style), Paragraph("Crisis Connect leads in cryptographic maturity today.", td_style)],
        [Paragraph("Offline Voice / Photos", td_bold), Paragraph("Text/Telemetry Only", td_style), Paragraph("<b>Shipped (Voice/Files)</b>", td_style), Paragraph("Crisis Connect", td_style), Paragraph("RakshaNet deliberately avoids heavy media to conserve RF mesh airtime.", td_style)],
        
        # Intelligence
        [Paragraph("On-Device AI Assistant", td_bold), Paragraph("Lightweight SLM Triage", td_style), Paragraph("<b>LiteRT-LM (TFLite)</b>", td_style), Paragraph("Crisis Connect", td_style), Paragraph("Crisis Connect runs a real local LLM; RakshaNet prioritizes fast triage rules.", td_style)],
        [Paragraph("DBSCAN Incident Clustering", td_bold), Paragraph("<b>Yes (Proprietary)</b>", td_style), Paragraph("None (Raw Inbox)", td_style), Paragraph("<b>None</b>", td_style), Paragraph("<b>RakshaNet Exclusive:</b> Merges 30 redundant pings into 1 master incident.", td_style)],
        [Paragraph("Comm-Gap / Black Hole AI", td_bold), Paragraph("<b>Yes (Decay Analysis)</b>", td_style), Paragraph("None", td_style), Paragraph("<b>None</b>", td_style), Paragraph("<b>RakshaNet Exclusive:</b> Flags silent villages (like Tiru) within hours.", td_style)],
        [Paragraph("Probabilistic Search Zones", td_bold), Paragraph("<b>Yes (Isochrone Core)</b>", td_style), Paragraph("None (Sightings)", td_style), Paragraph("<b>None</b>", td_style), Paragraph("<b>RakshaNet Exclusive:</b> Generates bounded search envelopes for rescuers.", td_style)],
        [Paragraph("RSSI Proximity Localization", td_bold), Paragraph("<b>Yes (Trilateration)</b>", td_style), Paragraph("None", td_style), Paragraph("<b>None</b>", td_style), Paragraph("<b>RakshaNet Exclusive:</b> Binds survivor envelopes when GPS fix is zero.", td_style)],
        [Paragraph("Cascading Failure Risk AI", td_bold), Paragraph("<b>Yes (Graph Engine)</b>", td_style), Paragraph("None", td_style), Paragraph("<b>None</b>", td_style), Paragraph("<b>RakshaNet Exclusive:</b> Anticipates secondary bridge/power collapses.", td_style)],
        [Paragraph("Resource Dispatch Optimization", td_bold), Paragraph("<b>Yes (Linear Solver)</b>", td_style), Paragraph("None", td_style), Paragraph("<b>None</b>", td_style), Paragraph("<b>RakshaNet Exclusive:</b> Proposes boat, 4WD, and medical team assignments.", td_style)],
        [Paragraph("Outbound CAP / CAD Export", td_bold), Paragraph("<b>Yes (Gov Spec)</b>", td_style), Paragraph("None", td_style), Paragraph("<b>None</b>", td_style), Paragraph("<b>RakshaNet Exclusive:</b> Directly feeds official Indian disaster systems.", td_style)],
        [Paragraph("Verified Responder ID", td_bold), Paragraph("Roadmap", td_style), Paragraph("<b>Shipped (X.509)</b>", td_style), Paragraph("Crisis Connect", td_style), Paragraph("Crisis Connect leads in preventing responder spoofing; RakshaNet must match.", td_style)]
    ]
    t_h2h = Table(head_to_head, colWidths=[105, 75, 75, 60, 208.28])
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

    story.append(Paragraph(
        "<b>The Fundamental Strategic Contrast:</b><br/>"
        "• <b>Crisis Connect is a Survivor-to-Responder Messenger:</b> It routes encrypted chats and voice packets from a phone to an agency web inbox.<br/>"
        "• <b>RakshaNet is an Operational Disaster Intelligence Engine:</b> It assumes thousands of messy, fragmented signals will flood the system, clusters them into prioritized incidents, flags who went dark, and calculates where limited rescue boats should deploy first.",
        body_style
    ))
    story.append(Spacer(1, 8))

    # -------------------------------------------------------------
    # SECTION 6: SCENARIO IMPACT MODEL & GRAPHICAL PROJECTIONS
    # -------------------------------------------------------------
    story.append(Paragraph("6. Scenario Impact Model & Real-World Feasibility", h1_style))
    story.append(Paragraph(
        "Impact in delay-tolerant mesh systems scales directly with community pre-installation. Modeling RakshaNet against the documented Nepal 2026 baseline demonstrates tangible, adoption-dependent utility:",
        body_style
    ))

    # Embed Figure 4: Impact model
    fig4_path = r"P:\RakshaNet\docs\assets\figures\fig4_adoption_impact_model.png"
    if os.path.exists(fig4_path):
        story.append(RLImage(fig4_path, width=page_w, height=170))
        story.append(Spacer(1, 6))

    impact_table_data = [
        [Paragraph("Projected Operational Benefit", th_style), Paragraph("Calculation Basis", th_style), Paragraph("5% Adoption", th_style), Paragraph("15% Adoption", th_style), Paragraph("30% Adoption", th_style)],
        [Paragraph("Casualties with Last-Known Fix & Time", td_bold), Paragraph("6,516 (Dead + Missing) &times; Adoption", td_style), Paragraph("~326", td_style), Paragraph("~977", td_style), Paragraph("~1,955", td_style)],
        [Paragraph("Injured Civilians Triggering Mesh SOS", td_bold), Paragraph("6,827 (Injured) &times; Adoption", td_style), Paragraph("~341", td_style), Paragraph("~1,024", td_style), Paragraph("~2,048", td_style)],
        [Paragraph("Missing Entries Cleared by 'I AM SAFE'", td_bold), Paragraph("10–20% of 5,130 unreachable &times; Adoption", td_style), Paragraph("26 – 51", td_style), Paragraph("77 – 154", td_style), Paragraph("154 – 308", td_style)],
        [Paragraph("Wasted Helicopter Sorties Eliminated", td_bold), Paragraph("10–20% of 1,348 sorties via clustering", td_style), Paragraph("135 – 270", td_style), Paragraph("135 – 270", td_style), Paragraph("135 – 270", td_style)]
    ]
    t_impact = Table(impact_table_data, colWidths=[140, 140, 75, 75, 93.28])
    t_impact.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), c_navy),
        ('GRID', (0,0), (-1,-1), 0.5, c_border),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [c_white, c_bg_light]),
    ]))
    story.append(t_impact)
    story.append(Spacer(1, 6))

    # Real-world limitations
    story.append(Paragraph("<b>Honest Engineering Boundaries to State in Pitch:</b>", h2_style))
    story.append(Paragraph("1. <b>Post-Impact, Not Early Warning:</b> Flash outbursts strike in minutes. RakshaNet coordinates post-disaster search and triage; it does not claim to prevent structural destruction.", bullet_style))
    story.append(Paragraph("2. <b>RF Mountainous Attenuation:</b> Consumer BLE range is 15–50m. In sparse Himalayan ravines, node density is low until aerial data mules (helicopters/drones) or foot patrols bridge the gap.", bullet_style))
    story.append(Paragraph("3. <b>Community Pre-Installation Dependency:</b> Mesh efficacy requires prior civil defense installation before the annual monsoon.", bullet_style))
    story.append(Spacer(1, 8))

    # -------------------------------------------------------------
    # SECTION 7: PRE-PITCH STRATEGY & DEFENSIBLE POSITIONING
    # -------------------------------------------------------------
    story.append(PageBreak())
    story.append(Paragraph("7. Pre-Pitch Action Items & Winning Strategy", h1_style))
    story.append(Paragraph(
        "To win hackathons and convince agency evaluators, execute the following 5-point action strategy:",
        body_style
    ))

    action_points = [
        "<b>1. Demo the Three Core Moat Features Live:</b> Build interactive dashboard prototypes demonstrating (a) live DBSCAN clustering of 50 incoming pings, (b) visual decay alerting for a simulated communication black hole, and (c) an expanding probabilistic search circle from a stale pin.",
        "<b>2. Build a Virtual Mesh Simulator (150 Nodes):</b> Use a Python script (<code>simulate_mesh.py</code>) injecting realistic phone hops and dropouts. Judges trust measured simulation telemetry over theoretical claims.",
        "<b>3. Include a Transparent Competitor Slide:</b> Name <b>Crisis Connect</b> directly. Acknowledging their production maturity while illustrating your intelligence layer disarms technical critics.",
        "<b>4. Focus Presentation on the Core 8 Features:</b> Do not overwhelm evaluators with all 34 features. Present: <i>Tactile SOS, Store-and-Forward DTN, Edge Triage, Opportunistic Sync, DBSCAN Clustering, Comm-Gap Anomaly Detection, Probabilistic Search Zones, and Dispatch Optimization.</i>",
        "<b>5. Master the Inevitable Question:</b> When asked <i>'Crisis Connect already has a web dashboard, so why RakshaNet?'</i>, answer: <b>'Crisis Connect is an inbox for reading messages. RakshaNet is an operational spatial engine that analyzes the entire disaster picture and tells commanders where to send limited boats first.'</b>"
    ]
    for act in action_points:
        story.append(Paragraph(act, bullet_style))
    story.append(Spacer(1, 10))

    # FINAL SIGN-OFF BANNER
    sign_box = Table([[Paragraph(
        "<b>PITCH CLOSING STATEMENT:</b><br/>"
        "<i>\"In the next disaster, cell towers will fall again. But with RakshaNet, every silent phone will still leave a trail—and every rescue commander will know exactly where to go.\"</i>",
        ParagraphStyle('SignText', fontName='Helvetica-Bold', fontSize=9, leading=13, textColor=c_navy, alignment=1)
    )]], colWidths=[page_w])
    sign_box.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#EFF6FF")),
        ('BOX', (0,0), (-1,-1), 1, c_teal),
        ('TOPPADDING', (0,0), (-1,-1), 8),
        ('BOTTOMPADDING', (0,0), (-1,-1), 8),
        ('LEFTPADDING', (0,0), (-1,-1), 12),
        ('RIGHTPADDING', (0,0), (-1,-1), 12),
    ]))
    story.append(sign_box)

    # Build the document
    doc.build(story, canvasmaker=NumberedCanvas)
    print("Successfully built PDF dossier at:", pdf_path)

if __name__ == "__main__":
    build_pdf()
