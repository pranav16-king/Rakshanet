# SignalRescue AI (RakshaNet) — Phase 1 Implementation Plan

## 1. Phase 1 Objective

Build a working mobile application focused strictly on:
**Permissions → User Setup → Offline Network → Offline Chat → Local Persistence**.

Do not add SOS cloud intelligence, government CAD/CAP dashboards, AI probabilistic search zones, or rescue fleet optimization yet.

### Deliverables:
* Install and start with progressive, minimal Android permissions.
* Create a local-first anonymous emergency profile.
* Zero-internet operational baseline.
* Discover nearby SignalRescue peer handsets over Bluetooth Low Energy (BLE).
* Establish peer-to-peer and multi-hop delay-tolerant mesh communication.
* Send and receive chat messages locally.
* Relay messages through nearby intermediate carrier devices ("data mules").
* Store **all profile, device, conversation, and relay telemetry locally in SQLite**.
* Transparent delivery status: Saved &rarr; Sent Nearby &rarr; Relayed (N hops) &rarr; Delivered.
* Automatic recovery of pending message queues upon app restart.
* Adaptive battery governance (Normal, Low-Power, Emergency).

```text
┌────────────────────────────────────────────────────────────────────────┐
│                      SIGNALRESCUE MOBILE (PHASE 1)                     │
│                                                                        │
│                      React Native + TypeScript                         │
│                                                                        │
│   ┌───────────────────────────┐      ┌─────────────────────────────┐   │
│   │          Screens          │      │         Navigation          │   │
│   │ Onboarding / Home / Chat  │      │ React Navigation Native     │   │
│   └─────────────┬─────────────┘      └──────────────┬──────────────┘   │
│                 │                                   │                  │
│   ┌─────────────▼───────────────────────────────────▼──────────────┐   │
│   │                     Application Services                       │   │
│   │      ChatService / MeshService / IdentityService               │   │
│   └─────────────────────────────┬──────────────────────────────────┘   │
│                                 │                                      │
│                 ┌───────────────▼──────────────┐                       │
│                 │      Zustand UI Stores       │                       │
│                 │  Transient Reactive State    │                       │
│                 └───────────────┬──────────────┘                       │
│                                 │                                      │
│                 ┌───────────────▼──────────────┐                       │
│                 │       SQLite Database        │                       │
│                 │  Local-First Source of Truth │                       │
│                 └───────────────┬──────────────┘                       │
│                                 │                                      │
│                 ┌───────────────▼──────────────┐                       │
│                 │ Native Android Bridge (JNI)  │                       │
│                 └───────────────┬──────────────┘                       │
│                                 │                                      │
│   ┌─────────────────────────────▼──────────────────────────────────┐   │
│   │                    Native Android Modules (Kotlin)             │   │
│   │                                                                │   │
│   │   • BluetoothModule.kt (GATT Client/Server & Advertisements)   │   │
│   │   • MeshManager.kt (Battery-aware Duty Cycling & Handshake)    │   │
│   │   • WifiDirectModule.kt (P2P SoftAP escalation stub)           │   │
│   └────────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Technology Stack

### Mobile Frontend
- **Framework:** React Native 0.74+
- **Language:** TypeScript 5.x (Strict mode)
- **Navigation:** React Navigation v6 (`@react-navigation/native`, `@react-navigation/bottom-tabs`, `@react-navigation/native-stack`)
- **State Management:** Zustand 4.5+ (UI/transient reactive state only)
- **Design Tokens:** SignalRescue "Hi-Vis Beacon" Design System (`tokens.ts`)
- **Icons:** Lucide Icons via `lucide-react-native`
- **Animation & Gestures:** React Native Reanimated 3.x, React Native Gesture Handler

### Local Database
- **Engine:** SQLite (via `react-native-quick-sqlite` or direct SQLite driver)
- **Architecture:** Offline-first Repository Pattern
- **Core Principle:**
  > **SQLite is the sole durable source of truth.**  
  > State is never stored only in React memory. If the process is killed at any instant, zero messages or identity data are lost.

### Native Android Layer
- **Language:** Kotlin 1.9+
- **Target SDK:** Android 14 (API 34)
- **Minimum SDK:** Android 8.0 (API 26 - BLE 5.0 support)
- **Radio Protocols:** BLE Advertising (L2CAP / GATT Server), BLE Scanning (Filtered UUIDs), Wi-Fi Direct (P2P Wi-Fi)

---

## 3. Native Android Layer Architecture

The React Native JavaScript thread must never perform blocking RF operations.

```text
React Native UI
      │
      ▼
TypeScript Service Layer (chatService / meshService)
      │
      ▼
Native Module Bridge (RakshaNetPackage)
      │
      ▼
Kotlin Native Modules
 ┌────┴─────────────────────────────┐
 ▼                                  ▼
BluetoothModule.kt             MeshManager.kt
• BLE Advertising              • Periodic duty-cycling
• BLE Scanning                 • Battery-aware power tiers
• GATT Client/Server           • Bloom filter deduplication
• Connection Handshakes        • Packet fragment reassembly
```

---

## 4. Application Startup & Progressive Permissions

The app must **never mass-request permissions upon initial launch**. Instead, it uses a progressive, transparent onboarding flow.

```text
Splash Screen (Zero permissions requested)
     ↓
Welcome & Mission Statement
     ↓
Permission Explanation Screen (Plain-language rationale)
     ↓
Native Android Permission Dialog (Nearby Devices)
     ↓
Emergency Profile Setup (Minimal: Name + Language)
     ↓
Local Device Identity Generation (Ed25519 Keypair + Anonymous ID)
     ↓
SQLite Schema Initialization
     ↓
Main App Home
```

---

## 5. Required Permissions (Android-First)

Only request what is strictly required for Phase 1 mesh operation:

| Permission | Android Level | Purpose | User Explanation |
|---|---|---|---|
| `BLUETOOTH_SCAN` | Android 12+ (API 31+) | Discover nearby peer devices | "Used to detect nearby survivors without cellular networks." |
| `BLUETOOTH_ADVERTISE` | Android 12+ (API 31+) | Broadcast mesh presence | "Allows nearby phones to discover your phone for relaying." |
| `BLUETOOTH_CONNECT` | Android 12+ (API 31+) | Establish GATT data channels | "Used to send and receive offline messages." |
| `ACCESS_FINE_LOCATION` | Android 8–11 | BLE discovery hardware requirement | "Required by Android 8–11 to scan for Bluetooth beacons." |
| `POST_NOTIFICATIONS` | Android 13+ | Urgent message alerts | *Only requested when message notifications are active.* |

---

## 6. Local Anonymous Identity

To protect user safety during humanitarian crises, raw hardware identifiers (**IMEI, MAC address, IMSI, Serial Number**) are **strictly prohibited** from transmission.

```text
Local Identity Generation:
  device_id: SR-8F42-A91C (Deterministic short hash)
  public_key: Ed25519 (Raw 32 bytes hex)
  private_key: Android Keystore / Encrypted SQLite reference
```

---

## 7. SQLite Database Schema

```sql
-- 1. Civilian User Profile
CREATE TABLE IF NOT EXISTS user_profile (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    preferred_language TEXT DEFAULT 'en',
    age INTEGER,
    blood_group TEXT,
    emergency_contact TEXT,
    medical_notes TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

-- 2. Local Device Identity
CREATE TABLE IF NOT EXISTS device_identity (
    id TEXT PRIMARY KEY,
    device_id TEXT UNIQUE NOT NULL,
    public_key TEXT NOT NULL,
    private_key_ref TEXT NOT NULL,
    created_at INTEGER NOT NULL
);

-- 3. Discovered Nearby Devices
CREATE TABLE IF NOT EXISTS nearby_devices (
    id TEXT PRIMARY KEY,
    device_id TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL,
    connection_type TEXT NOT NULL, -- 'BLE', 'WIFI_DIRECT'
    signal_strength INTEGER NOT NULL, -- RSSI in dBm
    proximity_band TEXT NOT NULL, -- 'IMMEDIATE', 'NEAR', 'FAR'
    last_seen INTEGER NOT NULL,
    first_seen INTEGER NOT NULL,
    is_connected INTEGER DEFAULT 0,
    hop_count INTEGER DEFAULT 1,
    battery_level INTEGER
);

-- 4. Conversations
CREATE TABLE IF NOT EXISTS conversations (
    id TEXT PRIMARY KEY,
    conversation_id TEXT UNIQUE NOT NULL,
    type TEXT NOT NULL, -- 'DIRECT', 'GROUP', 'BROADCAST'
    title TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

-- 5. Conversation Participants
CREATE TABLE IF NOT EXISTS conversation_participants (
    id TEXT PRIMARY KEY,
    conversation_id TEXT NOT NULL,
    device_id TEXT NOT NULL,
    display_name TEXT NOT NULL,
    joined_at INTEGER NOT NULL,
    last_seen INTEGER NOT NULL,
    FOREIGN KEY(conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
);

-- 6. Offline Messages (Local Source of Truth)
CREATE TABLE IF NOT EXISTS messages (
    id TEXT PRIMARY KEY,
    message_id TEXT UNIQUE NOT NULL,
    conversation_id TEXT NOT NULL,
    sender_device_id TEXT NOT NULL,
    sender_name TEXT NOT NULL,
    message_type TEXT NOT NULL, -- 'TEXT', 'STATUS', 'RELAY_ACK'
    content TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    expires_at INTEGER NOT NULL,
    status TEXT NOT NULL, -- 'SAVED', 'QUEUED', 'SENDING', 'SENT_NEARBY', 'RELAYED', 'DELIVERED', 'FAILED', 'EXPIRED'
    hop_count INTEGER DEFAULT 0,
    ttl INTEGER DEFAULT 5,
    FOREIGN KEY(conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
);

-- 7. Message Relay Audit Trail
CREATE TABLE IF NOT EXISTS message_relays (
    id TEXT PRIMARY KEY,
    message_id TEXT NOT NULL,
    from_device_id TEXT NOT NULL,
    to_device_id TEXT NOT NULL,
    hop_number INTEGER NOT NULL,
    received_at INTEGER NOT NULL,
    forwarded_at INTEGER,
    status TEXT NOT NULL, -- 'RECEIVED', 'FORWARDED', 'DROPPED'
    FOREIGN KEY(message_id) REFERENCES messages(id) ON DELETE CASCADE
);
```

---

## 8. Offline-First Chat Pipeline

### Critical Axiom: Save Before Transmit
Under extreme disaster conditions, a phone may run out of battery or disconnect at any millisecond. Therefore:
```text
User presses Send
       │
       ▼
1. Generate UUID & timestamp
       │
       ▼
2. Write record to SQLite with status = 'SAVED'
       │
       ▼
3. Render instantly in React Native UI (Grey tick: "Saved on this phone")
       │
       ▼
4. Enqueue into Outbox Queue (status = 'QUEUED')
       │
       ▼
5. Background Mesh Worker detects nearby peers
       │
       ▼
6. Transmit compact binary/JSON packet via BLE GATT
       │
       ▼
7. Intermediate peer returns ACK -> Update status = 'SENT_NEARBY' / 'RELAYED'
       │
       ▼
8. UI updates ticks (Blue double check: "Relayed by 2 devices")
```

---

## 9. Compact Network Packet Protocol

```json
{
  "ver": 1,
  "msg_id": "MSG-7A2B-9C01",
  "conv_id": "CONV-COMMUNITY",
  "sender_id": "SR-8F42-A91C",
  "sender_name": "Priya",
  "ts": 1790912345,
  "ttl": 5,
  "hops": 0,
  "type": "TEXT",
  "payload": "Water is available at the municipal school."
}
```

### Forwarding Rules:
1. **Deduplication:** Check if `msg_id` exists in SQLite. If yes, **DROP**.
2. **TTL Decrement:** Decrement `ttl` by 1. If `ttl <= 0`, store locally but **DO NOT FORWARD**.
3. **Hop Count:** Increment `hops` by 1.
4. **Relay Audit:** Insert entry in `message_relays`.

---

## 10. Adaptive Battery Governance

| Battery Level | Profile | BLE Scan Duty Cycle | Advertisement Interval | UI Mode |
|---|---|---|---|---|
| **> 50%** | **Normal** | 5s scan every 25s (20%) | 250ms | Full light/dark theme |
| **20% – 50%** | **Low-Power** | 3s scan every 60s (5%) | 1000ms | Dark mode recommended |
| **< 20%** | **Critical** | 2s scan every 180s (1.1%) | 3000ms | Pure OLED black (`#000000`), animations disabled |

---

## 11. Multi-Device Verification Matrix (4 Phones)

| Test Case | Scenario | Expected Outcome |
|---|---|---|
| **TC-01** | Phone A &rarr; Phone B (Direct) | Direct BLE message delivery within 4 seconds. |
| **TC-02** | Phone A &rarr; Phone B &rarr; Phone C (2 Hops) | Phone B transparently relays; Phone C receives message with `hops = 2`. |
| **TC-03** | Phone A &rarr; B &rarr; C &rarr; Phone D (3 Hops) | Multi-hop mesh relay across 4 handsets with zero internet or server connection. |
| **TC-04** | Process Kill & Recovery | Terminate app process. Upon reboot, all messages and queued outbox items restore from SQLite. |
| **TC-05** | Loop Suppression | Phone C relays back towards Phone A; Phone A drops duplicate packet deterministically. |
| **TC-06** | Zero TTL Enforcement | Send message with `ttl = 1`; Phone B receives message and halts downstream forwarding. |
