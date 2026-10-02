# RakshaNet Mobile (SignalRescue AI) — Phase 1

> **Android-First React Native + TypeScript + Native Kotlin Offline Mesh Application**

---

## 📱 Phase 1 Scope & Architecture

Phase 1 deliberately restricts its operational scope to:
**Permissions → User Setup → Offline Network → Offline Chat → Local Persistence**.

High-level features like cloud SOS triage, search zones, and government dashboards are deferred to later phases so the core RF delay-tolerant mesh remains rock solid.

```text
mobile/
├── App.tsx                                 # Application entrypoint & providers
├── index.js                                # React Native root registration
├── package.json                            # Dependencies & build scripts
├── tsconfig.json                           # TypeScript configuration
├── src/
│   ├── app/
│   │   └── navigation/                     # Multi-page navigation flows
│   │       ├── RootNavigator.tsx           # Stack orchestrator (Onboarding vs MainTabs)
│   │       └── MainTabNavigator.tsx        # Bottom tab bar (Home, Chat, Network, Settings)
│   ├── theme/                              # "Hi-vis beacon" design system
│   │   ├── tokens.ts                       # Design tokens from design.md
│   │   └── index.ts                        # useTheme hook (Light, Dark, Low-power OLED)
│   ├── types/                              # Strict TypeScript data models
│   │   ├── profile.ts                      # UserProfile, DeviceIdentity
│   │   ├── device.ts                       # NearbyDevice, ConnectionType, ProximityBand
│   │   ├── chat.ts                         # Message, Conversation, NetworkPacket, RelayHop
│   │   └── network.ts                      # NetworkState, RadioMode, MeshState
│   ├── database/                           # Offline-First SQLite Local Source of Truth
│   │   ├── schema.ts                       # Relational DDL (7 tables & performance indexes)
│   │   ├── sqlite.ts                       # Database manager & storage abstraction
│   │   └── repositories/                   # Data access repositories
│   │       ├── profileRepository.ts        # Profile & hardware-anonymized identity
│   │       ├── deviceRepository.ts         # Discovered peers & proximity indexing
│   │       └── chatRepository.ts           # Save-before-send messages & relay logs
│   ├── services/                           # Business logic & hardware coordination
│   │   ├── permissions/
│   │   │   └── permissionService.ts        # Progressive Android BLE runtime permissions
│   │   ├── identity/
│   │   │   └── identityService.ts          # Anonymous device ID & Ed25519 keys
│   │   ├── bluetooth/
│   │   │   └── bluetoothService.ts         # TypeScript bridge to native Kotlin radio
│   │   ├── mesh/
│   │   │   └── meshService.ts              # TTL decrement, Bloom deduplication, DTN outbox
│   │   └── chat/
│   │       └── chatService.ts              # Save-before-send transactional chat pipeline
│   ├── store/                              # Reactive Zustand stores for UI state
│   │   ├── profileStore.ts                 # Profile & identity state
│   │   ├── networkStore.ts                 # Real-time peer counts & radio states
│   │   ├── chatStore.ts                    # Active conversations & outbox queue
│   │   └── settingsStore.ts                # OLED low-power mode & radio battery governance
│   ├── components/                         # Modular, accessible UI components
│   │   ├── StatusStrip.tsx                 # Persistent Mesh/Net/GPS/Battery indicators
│   │   ├── PrimaryButton.tsx               # Hi-vis beacon yellow action button (56dp)
│   │   ├── ChatBubble.tsx                  # Bubble with save & relay hop indicators
│   │   ├── DeviceCard.tsx                  # Nearby peer card with proximity bands
│   │   └── Card.tsx                        # Accessible surface card container
│   └── screens/                            # Modular page-wise screens
│       ├── onboarding/
│       │   ├── SplashScreen.tsx            # Zero-network bootstrap & profile detection
│       │   ├── WelcomeScreen.tsx           # Mission intro & zero-internet premise
│       │   ├── PermissionsScreen.tsx       # Progressive BLE permission explanation
│       │   └── ProfileSetupScreen.tsx      # Minimal emergency profile (15s setup)
│       ├── home/
│       │   └── HomeScreen.tsx              # SOS beacon button, status strip, outbox counts
│       ├── chat/
│       │   ├── ChatListScreen.tsx          # Community Mesh & direct chat directory
│       │   └── ChatScreen.tsx              # Active conversation with quick shortcuts
│       ├── network/
│       │   └── NetworkScreen.tsx           # Peer discovery topology & battery governance
│       └── settings/
│           └── SettingsScreen.tsx          # OLED black mode (#000000) & security keys
└── android/
    └── app/src/main/
        ├── AndroidManifest.xml             # Progressive BLE permissions (API 26–34)
        └── java/org/rakshanet/nativemodules/
            ├── BluetoothModule.kt          # React Native native module bridge
            ├── MeshManager.kt              # Low-level BLE advertising & scanning
            └── RakshaNetPackage.kt         # Package registry for native modules
```

---

## 🛠️ Key Implementation Guarantees

1. **Save-Before-Send Persistence:**
   - Every message is written to SQLite with `status = 'SAVED'` before any radio transmission is attempted.
   - If the battery dies or process is killed mid-transfer, messages are permanently retained and restored upon restart.

2. **Deduplication & Loop Suppression:**
   - Messages are identified by deterministic UUIDs (`MSG-XXXX-XXXX`).
   - Packets already present in SQLite are dropped immediately to prevent RF packet storms.

3. **Time-To-Live (TTL) Decay:**
   - Outgoing packets start with `TTL = 5`. Each hop decrements TTL by 1.
   - When `TTL <= 1`, the receiving peer archives the message locally but does not relay further.

4. **Progressive Minimum Permissions:**
   - Zero permissions requested on splash or welcome screens.
   - On Android 12+, only requests `BLUETOOTH_SCAN`, `BLUETOOTH_ADVERTISE`, and `BLUETOOTH_CONNECT`.

5. **Battery Governance:**
   - Supports **Normal**, **Low-Power** (5% duty cycle), and **Critical OLED** (True Black `#000000` with 1.1% duty cycle).
