# RakshaNet (SignalRescue AI) — System Architecture Specification

> **Document Version:** 1.0.0  
> **Status:** Phase 1 Implementation Active  
> **Target Platforms:** Flutter/Dart (Android & iOS Mobile Client) • FastAPI (Incident Gateway) • React/Vite (Command Center Dashboard)  
> **Associated Architecture Artifacts:**  
> - Visual Wireframe Architecture: [`architecture.drawio`](file:///p:/RakshaNet/architecture.drawio)  
> - System Topology & Data Flow Mermaid Diagram: [`architecture.mmd`](file:///p:/RakshaNet/architecture.mmd)  
> - Source Design Tokens: [`design.md`](file:///p:/RakshaNet/design.md) & [`AppTokens`](file:///p:/RakshaNet/mobile/lib/theme/app_tokens.dart)

---

## 1. Executive Summary & Design Philosophy

Disasters such as floods, earthquakes, cyclonic storms, and landslides routinely trigger total collapse of terrestrial communication infrastructure: cell towers lose power, fiber backhauls sever, and power grids fail.

**RakshaNet (SignalRescue AI)** is an extreme-environment, offline-first emergency coordination network designed to operate when **zero internet, zero cellular signal, and zero grid power** exist. It establishes an ad-hoc, peer-to-peer, multi-hop **Delay-Tolerant Mesh Network (DTN)** over Bluetooth Low Energy (BLE) and Wi-Fi Direct, turning ordinary smartphones carried by survivors, community volunteers, and emergency first responders into resilient store-and-forward routing nodes.

### Core Architectural Principles
1. **Zero-Infrastructure Operability:** The core user journey—sending an SOS distress beacon, chatting with nearby survivors, accessing survival guides, reporting missing persons, and locating emergency shelters—operates completely offline without ever pinging a remote server.
2. **Save-Before-Send Transactional Durability:** Messages, reports, and distress beacons are committed to local SQLite flash memory before radio transceivers are triggered. No message is lost if battery dies immediately after dispatch.
3. **Decentralized Epidemic Multi-Hop Routing:** Inspired by proven offline mesh implementations (*Kabootar*, *MeshChat*, and *Beacon*), packets hop node-to-node across pedestrian movement and opportunistic encounters using Time-To-Live (TTL) decay and cryptographic deduplication.
4. **Hi-Vis Beacon UI & OLED Power Conservation:** Built on strict safety gear aesthetics (`#FFC400` Signal Yellow, `#D92D20` SOS Red, `#0E8A94` Beacon Teal) with a dedicated `#000000` True OLED Black mode that cuts display battery consumption by up to 62% in survival scenarios.
5. **Mandatory Profile Setup Gate:** Guaranteed responder identification through anonymous pseudo-identifiers (`SR-XXXX-XXXX`) captured at first launch before any navigation to home is unlocked.

---

## 2. Multi-Tier End-to-End System Topology

The end-to-end network is structured into 4 interoperable tiers, bridging ground survivors directly with national emergency coordination bodies:

```
┌────────────────────────────────────────────────────────────────────────┐
│             TIER 1: DISCONNECTED MOBILE MESH NODES (SURVIVORS)         │
│  Flutter / Dart Mobile App  •  Local SQLite  •  BLE GATT Client/Server │
└────────────────────────────────────┬───────────────────────────────────┘
                                     │ (Opportunistic BLE Broadcast ~80m)
                                     ▼
┌────────────────────────────────────────────────────────────────────────┐
│             TIER 2: MULTI-HOP DELAY-TOLERANT MESH TOPOLOGY             │
│  Phone A (TTL 5, Hops 0) ──> Phone B (TTL 4, Hops 1) ──> Phone C (TTL 3)│
└────────────────────────────────────┬───────────────────────────────────┘
                                     │ (Border Node / Highway Vehicle Sync)
                                     ▼
┌────────────────────────────────────────────────────────────────────────┐
│            TIER 3: FIELD RESCUE GATEWAY & TACTICAL CONVOY              │
│  Tactical High-Gain BLE Sink  •  DTN Buffer  •  Satellite/4G Uplink    │
└────────────────────────────────────┬───────────────────────────────────┘
                                     │ (Secure WSS / HTTPS Sync)
                                     ▼
┌────────────────────────────────────────────────────────────────────────┐
│          TIER 4: COMMAND CENTER CLOUD & NATIONAL DISASTER APIS         │
│  FastAPI Gateway  •  PostgreSQL / PostGIS  •  React Leaflet Dashboard  │
│  NDMA / SDMA National Disaster Management Ingestion (CAP XML Protocol) │
└────────────────────────────────────────────────────────────────────────┘
```

### Detailed Tier Breakdown

#### Tier 1: Disconnected Mobile Mesh Nodes
- Runs on consumer Android/iOS smartphones using **Flutter 3.47+** and **Dart 3.13+**.
- Dual BLE role: Operates simultaneously as a **GATT Server (Peripheral Advertiser)** and **GATT Client (Central Scanner)** with duty-cycled advertising (200ms active / 800ms sleep) to conserve battery.
- Local non-volatile persistence via SQLite (`sqflite`).

#### Tier 2: Multi-Hop Delay-Tolerant Mesh (DTN)
- Autonomous peer discovery without central coordination or pre-established pairings.
- Packets are encapsulated into bounded binary envelopes. As people walk through affected neighborhoods or evacuation zones, messages physically move with them (Store-Carry-and-Forward).
- Automatic loop suppression via Bloom filters and SQLite message hashes prevents infinite message loops.

#### Tier 3: Field Edge Rescue Gateway
- Mobile command vehicles, NDRF (National Disaster Response Force) boats, and drone payloads equipped with high-gain BLE receivers.
- Caches incoming survivor distress envelopes in local edge queues.
- As soon as a satellite link (Starlink, Inmarsat) or cellular boundary is crossed, automatically flushes pending packets upstream.

#### Tier 4: Command Center & National Agencies
- **FastAPI backend** providing ingestion pipelines (`/api/mesh/sync`), real-time WebSocket broadcasting (`/ws/mesh`), and geo-spatial query endpoints.
- **React + Leaflet Command Dashboard** featuring real-time incident cluster heatmaps, automated drone corridor planning, survivor triage status, and NDRF team dispatch.
- **NDMA / SDMA Ingestion Gateway:** Generates Common Alerting Protocol (CAP XML v1.2) feeds compatible with government relief command centers.

---

## 3. Flutter Mobile Application Architecture

The mobile application is built using a clean, decoupled architecture:

```
mobile/lib/
├── theme/
│   ├── app_tokens.dart           # Brand colors, typography, touch targets, radii
│   └── app_theme.dart            # Dark (Navy), Light (Hi-Vis), Low-Power (OLED #000000)
├── models/
│   ├── user_profile.dart         # Identity, blood group, emergency contacts
│   ├── nearby_device.dart        # BLE peers, RSSI, proximity bands, hop distance
│   ├── chat_message.dart         # Messages, envelopes, delivery states, GPS coords
│   ├── emergency_report.dart     # Incidents: Medical, Trapped, Fire, Flood, etc.
│   ├── shelter_resource.dart     # Relief camps, occupancy, food/water supply tags
│   └── missing_person.dart       # Missing victim registry, physical markers, photos
├── database/
│   ├── app_database.dart         # SQLite schema initialization & database lifecycle
│   └── repositories/
│       ├── profile_repository.dart
│       ├── chat_repository.dart
│       ├── device_repository.dart
│       └── report_repository.dart
├── services/
│   ├── mesh_engine.dart          # Envelope encoding, deduplication, TTL decay
│   ├── chat_service.dart         # Save-Before-Send dispatcher
│   ├── location_service.dart     # GPS & last known dead-reckoning cache
│   └── ai_assistant_service.dart # Tiny offline disaster Q&A & triage heuristic
├── providers/
│   ├── profile_provider.dart     # Registration gating & profile management
│   ├── theme_provider.dart       # Real-time switching between Navy, Light, OLED
│   ├── mesh_provider.dart        # Live peer count, radio scanning, telemetry
│   └── chat_provider.dart        # Active conversations & outbox sync queue
├── screens/
│   ├── onboarding/
│   │   ├── splash_screen.dart           # Screen 1: Animated beacon & gate router
│   │   ├── onboarding_screen.dart       # Screen 2: Value proposition cards
│   │   └── profile_setup_screen.dart   # Screen 2b: Mandatory First-Launch Profile Gate
│   ├── home/
│   │   ├── home_screen.dart             # Screen 3: 4 status cards, 3s hold SOS button
│   │   └── emergency_report_screen.dart # Screen 4: Categorized distress reporting
│   ├── chat/
│   │   ├── chat_screen.dart             # Screen 5: Community chat & location sharing
│   │   └── my_messages_screen.dart      # Screen 10: Pending outbox & sync tracker
│   ├── tools/
│   │   ├── live_map_screen.dart         # Screen 6: Offline vector mesh canvas
│   │   ├── ai_assistant_screen.dart     # Screen 7: Offline survival assistant
│   │   ├── missing_person_screen.dart   # Screen 8: Missing person form & photos
│   │   ├── shelters_screen.dart         # Screen 9: Shelter status & supply levels
│   │   └── safety_tools_screen.dart     # Screen 11: 2x3 quick emergency tools grid
│   ├── settings/
│   │   └── settings_screen.dart         # Screen 12: Offline mode & OLED dark switch
│   ├── profile/
│   │   └── profile_screen.dart          # Screen 13: Mesh ID & Community Impact KPIs
│   └── main_shell.dart                  # Bottom Navigation Shell (Chat, Map, SOS, Tools, AI)
└── main.dart                            # MultiProvider entrypoint & initial route guard
```

---

## 4. Complete 13-Screen Wireframe Specification

Every screen in the application is engineered according to the visual design specified in [`architecture.drawio`](file:///p:/RakshaNet/architecture.drawio) and verified against the user-provided design mockups:

| # | Screen Name | Key Wireframe Elements | Core Functional Behaviors |
|---|---|---|---|
| **1** | **Splash Screen** | Large glowing beacon icon, "SignalRescue AI" brand header, subtext "Stay Connected. Save Lives. Anytime. Anywhere." | Checks `ProfileProvider.isRegistered`. If false, forces redirection to Screen 2b (Profile Gate). If true, proceeds directly to `MainShell`. |
| **2** | **Onboarding Screen** | Hero mesh graphic, 4 feature value cards ("Works without internet", "Connects nearby devices", "AI guidance on your device", "Auto sends to government"), "Get Started" and "Skip" actions. | Introduces core mesh philosophy to first-time survivors. "Get Started" navigates to Profile Gate. |
| **2b** | **Profile Setup Gate (Mandatory)** | Full Name / Nickname input, Blood Group dropdown (`A+`, `B+`, `O+`, `AB+`, etc.), Emergency Contact phone, Language selector, Privacy guarantee disclaimer. | **Strict Gate:** App cannot be bypassed until submitted. Writes to SQLite, marks `isRegistered = true`, assigns anonymous ID (`SR-XXXX-XXXX`). |
| **3** | **Home / SOS Main** | 4 status indicator cards (Mesh: 12 devices, Internet: Offline, GPS: Offline, Battery: 68%), **Central 176dp Circular SOS Beacon**, Persistent offline warning banner, Bottom Tab Bar. | **Hold-to-Activate:** Holding SOS button for 3.0s triggers haptic feedback, generates high-priority distress envelope, and opens Screen 4. |
| **4** | **Emergency Report** | Header with close 'X', 6 multi-threat categories: Medical, Trapped, Fire, Flood, Missing Person, Other; 56dp "((•)) Send SOS" button. | Packages coordinates, blood group, and emergency description into a prioritized binary envelope with `TTL = 5`. |
| **5** | **Offline Mesh Chat** | Channel tabs: Nearby, Group, Rescue, Saved; Chat bubbles with multi-hop delivery ticks (Single grey = Saved, Double teal = Sent Nearby, Arrow = Relayed, Double green = Delivered); Location card; Quick prompt pills. | Uses **Save-Before-Send** architecture. Messages typed offline are committed locally and broadcasted to all peers within BLE range. |
| **6** | **Live Mesh Map** | Custom vector canvas rendering simulated topographical disaster zone, pulsing red SOS pins, teal connected peers, dashed mesh link lines, cluster bubble ("5 devices in this area"), bottom sliding drawer ("2 people need help"). | Visualizes local ad-hoc network topology and nearby critical incidents without requiring Google Maps / internet tile fetching. |
| **7** | **Offline AI Assistant** | Conversational chat stream, step-by-step triage guidance cards (water purification, wound dressing, flood survival), suggestion chips ("Food storage", "First aid", "Nearby shelters"). | Runs 100% locally on-device. Uses a deterministic offline rule & triage knowledge base requiring zero cloud connectivity. |
| **8** | **Report Missing Person** | Person details (Name, Age, Clothing/Description), Last seen location pin, Last seen timestamp picker, 3 photo attachment previews, 56dp "Submit Report" button. | Propagates missing child/person bulletins across all hops so search teams and relief camps can cross-reference found individuals. |
| **9** | **Shelters & Resources** | Filter tabs ("Nearby", "All"), Camp cards: Village School (1.2 km, 120/200), Community Center (2.6 km, 190/200), capacity bars, supply badges (Food, Water, Medical, Solar Power). | Displays real-time occupancy and resource inventory broadcasted by relief coordinators. |
| **10** | **My Messages (Outbox)** | Tabs: Pending (3), Sent (8), Received (14); Outbox list showing pending SOS distress, location updates, and missing reports; Bottom Uplink status sync card. | Inspects local SQLite outbox queue. Automatically triggers bulk forward as soon as an uplink-connected node is detected. |
| **11** | **Safety Tools** | 2x3 Grid of survival tools: First Aid Guide, Emergency Tips, Offline Maps, "I Am Safe" Quick Check-in, Emergency Numbers, Disaster Alerts. | Immediate access to critical survival workflows without needing to read complex guides. |
| **12** | **Settings** | Toggles with active green tracks: Offline Mode, Location Sharing, Auto Govt Sync, **Low Power Theme (True OLED #000000)**; Navigation rows: Language, Privacy & Encryption, About. | Enables power-saving configurations and displays security certifications. |
| **13** | **Profile & Community Impact** | User profile card with avatar, Name ("Amit Sharma"), Mesh ID ("SR-284739"), 2x2 Impact KPI Grid (12 Helped, 8 Relayed, 3 Forwarded, 1 Found), navigation actions. | Gamifies and motivates disaster volunteers by showing transparent metrics on how many lives their phone helped bridge. |

---

## 5. Delay-Tolerant Networking (DTN) Protocol Specification

Inspired by Kabootar and MeshChat, RakshaNet utilizes a lightweight, self-contained binary envelope protocol designed for low-bandwidth BLE advertisements (MTU ~512 bytes):

### 5.1 Binary Envelope Structure

| Field | Size | Description |
|---|---|---|
| `message_id` | 16 bytes | UUID v4 uniquely identifying the message globally |
| `sender_id` | 8 bytes | Pseudonymous Device ID (e.g., `SR-284739`) |
| `timestamp` | 8 bytes | Monotonic unix epoch milliseconds of creation |
| `packet_type` | 1 byte | `0x01` (SOS), `0x02` (Chat), `0x03` (Missing), `0x04` (Shelter), `0x05` (ACK) |
| `ttl` | 1 byte | Time-To-Live hop limit (Initial value: `5`, decremented at each relay) |
| `hop_count` | 1 byte | Number of physical hops traversed (Initial value: `0`) |
| `is_location_shared` | 1 byte | Boolean flag (`0x00` = false, `0x01` = true) |
| `latitude` | 8 bytes | IEEE 754 64-bit float |
| `longitude` | 8 bytes | IEEE 754 64-bit float |
| `payload_length` | 2 bytes | Byte length of compressed payload body |
| `payload` | Var (≤ 450B) | UTF-8 JSON / CBOR encoded payload content |
| `checksum` | 4 bytes | CRC32 / HMAC frame validation for corruption detection |

### 5.2 Save-Before-Send Transactional Guarantee
To prevent data loss in unpredictable disaster scenarios (e.g. device destruction, sudden battery drain), every message dispatch strictly adheres to this transactional sequence:

```
[User Action: Tap Send / Hold SOS]
              │
              ▼
  ┌───────────────────────┐
  │ 1. SQLite Transaction │ ──> Status: 'SAVED' (Persisted to Flash)
  └───────────────────────┘
              │
              ▼
  ┌───────────────────────┐
  │ 2. Radio BLE Broadcast│ ──> Status: 'SENT_NEARBY' (Emitted Over Air)
  └───────────────────────┘
              │
              ▼
  ┌───────────────────────┐
  │ 3. Peer Ingestion     │ ──> Ingested by Peer Nodes (Dedup Check)
  └───────────────────────┘
              │
              ▼
  ┌───────────────────────┐
  │ 4. Multi-Hop Forward  │ ──> Status: 'RELAYED' (TTL Decremented)
  └───────────────────────┘
              │
              ▼
  ┌───────────────────────┐
  │ 5. Gateway Encounter  │ ──> Status: 'DELIVERED' (NDMA Cloud Confirmed)
  └───────────────────────┘
```

### 5.3 Deduplication & Loop Suppression
1. **Bloom Filter In-Memory:** Every node maintains a 10,000-bit rotating Bloom filter tracking seen `message_id`s for $O(1)$ fast rejection of re-broadcasted packets.
2. **SQLite Secondary Index:** If Bloom filter reports positive, the database table `messages` is queried by `message_id`. If found, the incoming packet is dropped silently without re-transmission.
3. **TTL Expiration Guard:** Each relay node decrements `ttl = ttl - 1`. If `ttl <= 1`, the message is saved locally in SQLite for the user to read, but is strictly halted from further transmission over the radio. This limits total blast radius and eliminates network broadcast storms.

---

## 6. Power & Energy Optimization (OLED #000000 True Black)

Power conservation is life-critical during disaster power outages:
- **True OLED Black Theme:** Most modern smartphones feature AMOLED screens. By replacing standard dark grey (`#121212`) with pure black (`#000000`), individual display subpixels turn off completely. This yields a **55% to 62% decrease in display battery draw**.
- **Adaptive Duty Cycling:**
  - *Standard Mode:* BLE scanning runs 5 seconds every 30 seconds.
  - *Low Power Mode (Battery < 20%):* BLE scanning runs 2 seconds every 60 seconds.
  - *SOS Emergency Mode:* BLE advertising runs continuously at maximum radio transmit power (+8 dBm).

---

## 7. Security, Privacy & Government Integration

1. **Pseudonymous Device Identifiers:** Users are identified exclusively through their anonymous token `SR-XXXX-XXXX`. No phone numbers, IMEIs, or personal names are broadcast unencrypted across the mesh.
2. **Payload Protection:** Emergency SOS packets include cleartext coordinates to allow immediate local neighbor assistance, while personal medical notes and contact details are encrypted using the public key of the National Disaster Management Authority (NDMA).
3. **NDMA / SDMA CAP Ingestion:** When gateway vehicles connect to cellular/satellite backhauls, packets are automatically transformed into **OASIS Common Alerting Protocol (CAP v1.2)** format, allowing native ingestion by national disaster dashboards across India and global relief agencies.

---

## 8. Verification & Architectural Compliance Matrix

| Requirement | Implementation Artifact | Verification Test |
|---|---|---|
| 13-Screen Hi-Vis UI Suite | `mobile/lib/screens/` | `widget_test.dart` / Visual Wireframes in `architecture.drawio` |
| Mandatory Profile Setup Gate | `profile_setup_screen.dart` | `phase1_verification_test.dart` (Test 1) |
| Save-Before-Send Guarantee | `chat_service.dart` + SQLite | `phase1_verification_test.dart` (Test 2) |
| 4-Phone 3-Hop Relay Simulation | `mesh_engine.dart` | `phase1_verification_test.dart` (Test 3) |
| Deduplication & Anti-Replay | `mesh_engine.dart` | `phase1_verification_test.dart` (Test 4) |
| TTL Expiration Guard (`TTL <= 1`) | `mesh_engine.dart` | `phase1_verification_test.dart` (Test 5) |
| OLED True Black Theme (`#000000`) | `app_tokens.dart` & `app_theme.dart` | `phase1_verification_test.dart` (Test 6) |
| Status Telemetry & Offline Warning | `home_screen.dart` | `phase1_verification_test.dart` (Test 7) |

---

## 9. Comparative Open-Source Architecture Analysis

RakshaNet's architecture synthesizes best-of-breed design patterns from key open-source offline mesh chat repositories on GitHub:

### 9.1 Kabootar (github.com/royalpinto007/Kabootar)
- **Architectural Contribution:** The foundational 5-layer decoupling pattern:
  $$\text{Flutter UI} \longrightarrow \text{ChatService} \longrightarrow \text{MeshEngine} \longrightarrow \text{SQLite} \longrightarrow \text{Bluetooth/Wi-Fi Transport}$$
- **Framework-Independent Dart Engine:** The core mesh routing logic (`MeshEngine`) is isolated from Flutter UI dependencies, allowing pure Dart unit testing without headless device runners.
- **Envelope Protocol:** UUID message identification, decremented TTL, hop counting, and multi-hop delivery receipts (Saved $\rightarrow$ Sent Nearby $\rightarrow$ Relayed $\rightarrow$ Delivered ACK).

### 9.2 MeshChat (github.com/koneb71/meshchat)
- **Architectural Contribution:** BLE Mesh peripheral/central state machine and Android foreground service lifecycle.
- **Deduplication Engine:** In-memory message hash caches combined with secondary SQLite lookups to eliminate packet storms during dense survivor clustering.
- **Diagnostics:** Proximity band estimation (Immediate $\le 2\text{m}$, Near $\le 10\text{m}$, Far $> 10\text{m}$) based on RSSI measurements.

### 9.3 BitChat & bitchat-flutter (github.com/rahulsahu2/Bitchat & github.com/avillagran/bitchat-flutter)
- **Architectural Contribution:** 3-role node topology: every phone dynamically acts as **Client**, **Router**, and **Relay**.
- **Cryptographic Envelopes:** Ed25519 anonymous device keypairs generating `SR-XXXX-XXXX` tokens.

### 9.4 Beacon (github.com/dash-pr/beacon)
- **Architectural Contribution:** Integrating offline BLE mesh communication with multi-hazard emergency management: SOS distress beacon, offline AI guidance, and shelter resource allocation.
- **Distinction from Beacon:** While Beacon requires a heavyweight 1B parameter model (Gemma 3 1B) exceeding 1.2 GB download sizes, RakshaNet utilizes an ultra-lightweight, deterministic, offline rule-based heuristic triage engine requiring zero megabytes of external weights, running smoothly on low-end budget smartphones.

### 9.5 Architectural Synthesis Matrix

| Capability | Kabootar | MeshChat | Beacon | RakshaNet (SignalRescue AI) |
|---|---|---|---|---|
| **Clean Layered Architecture** | Yes (UI $\rightarrow$ Engine $\rightarrow$ DB) | Partial | Monolithic | **Full 5-Layer Decoupled Stack** |
| **Save-Before-Send Guarantee** | Yes (SQLite) | Partial | No | **Strict SQLite Transaction First** |
| **Epidemic DTN Routing** | Yes | Yes | BLE Nearby | **Epidemic Store-and-Forward + TTL** |
| **Mandatory Profile Setup Gate** | No | No | No | **Strict Anonymous ID Onboarding Gate** |
| **OLED True Black (`#000000`)** | No | No | No | **Built-in Power-Saving AMOLED Theme** |
| **Multi-Hazard Emergency Triage** | No (Chat only) | No (Chat only) | Yes | **6 Emergency Types + Priority Scoring** |
| **Command Center Cloud Sync** | No | No | No | **FastAPI + Leaflet + NDMA CAP Gateway** |
