# Graph Report - RakshaNet  (2026-10-02)

## Corpus Check
- 69 files · ~285,188 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 2 file(s) not represented in the graph (top: (none) 1, .xml 1)

## Summary
- 631 nodes · 913 edges · 57 communities (36 shown, 21 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 5 edges (avg confidence: 0.91)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `86b1df5e`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- SignalRescue AI (RakshaNet) — Complete Feature Set
- RakshaNet — Offline Disaster Communication and AI Rescue System
- SignalRescue AI — design.md
- What You Must Do When Invoked
- useTheme
- chat.ts
- graphify reference: extra exports and benchmark
- Frontend Design
- SignalRescue Design System & UI Guidelines
- mobile/package.json
- ▶️ Running the Project
- networkStore.ts
- graphify reference: query, path, explain
- RakshaNet (SignalRescue AI)
- RakshaNet (SignalRescue AI): Verified Competitor and Uniqueness Report
- graphify reference: add a URL and watch a folder
- graphify reference: commit hook and native CLAUDE.md integration
- graphify reference: incremental update and cluster-only
- graphify reference: GitHub clone and cross-repo merge
- graphify reference: transcribe video and audio
- rules/graphify.md
- extraction-spec.md
- workflows/graphify.md
- BluetoothModule
- MeshManager
- SignalRescue AI (RakshaNet) — Phase 1 Implementation Plan
- dependencies
- compilerOptions
- profileStore.ts
- metro.config.js
- RakshaNet Mobile (SignalRescue AI) — Phase 1
- ✨ Features
- package.json
- 🚀 Installation & Reproduction
- 🗺️ Roadmap
- 🎯 Problem Statement
- 🗄️ Database Models (Specified Architecture)
- 🛠️ Tech Stack
- 🏆 Competitor Analysis & Market Moat
- ⚙️ Requirements
- server.js
- App.tsx
- scripts
- sqlite.ts
- devDependencies

## God Nodes (most connected - your core abstractions)
1. `SignalRescue AI (RakshaNet) — Complete Feature Set` - 36 edges
2. `useTheme()` - 34 edges
3. `RakshaNet (SignalRescue AI)` - 22 edges
4. `RakshaNet — Offline Disaster Communication and AI Rescue System` - 21 edges
5. `react-native` - 20 edges
6. `MeshManager` - 18 edges
7. `react` - 18 edges
8. `SignalRescue AI — design.md` - 18 edges
9. `compilerOptions` - 15 edges
10. `StatusStrip()` - 14 edges

## Surprising Connections (you probably didn't know these)
- `9. Core Components` --references--> `Card()`  [INFERRED]
  design.md → mobile/src/components/Card.tsx
- `9. Core Components` --references--> `ChatBubble()`  [INFERRED]
  design.md → mobile/src/components/ChatBubble.tsx
- `9. Core Components` --references--> `StatusStrip()`  [INFERRED]
  design.md → mobile/src/components/StatusStrip.tsx
- `BluetoothModule` --calls--> `MeshManager`  [INFERRED]
  mobile/android/app/src/main/java/org/rakshanet/nativemodules/BluetoothModule.kt → mobile/android/app/src/main/java/org/rakshanet/nativemodules/MeshManager.kt
- `App()` --calls--> `useTheme()`  [EXTRACTED]
  mobile/App.tsx → mobile/src/theme/index.ts

## Import Cycles
- None detected.

## Communities (57 total, 21 thin omitted)

### Community 0 - "SignalRescue AI (RakshaNet) — Complete Feature Set"
Cohesion: 0.05
Nodes (43): 10. 📦 Store-and-Forward Delay-Tolerant Networking, 11. 🔐 Message Deduplication & Hash Verification, 12. ⏳ Message Time-To-Live (TTL) & Hop Limits, 13. 📴 Lightweight On-Device AI Assistant (SLM), 14. 🧠 Automated AI Emergency Classification, 15. 📊 Spatial Incident Clustering (DBSCAN), 16. 📡 Communication-Gap & Black Hole Anomaly Detection, 17. 👤 Last-Known Presence Timeline (+35 more)

### Community 1 - "RakshaNet — Offline Disaster Communication and AI Rescue System"
Cohesion: 0.07
Nodes (27): 10. Government & Rescue Agency Dispatch Integration, 11. SignalRescue AI Command Centre, 12. AI Emergency Clustering, 13. Communication-Gap Detection, 14. Missing-Person Search Intelligence, 15. Rescue Resource Optimization, 16. Economic & Operational Benefits, 17. End-to-End System Workflow (+19 more)

### Community 2 - "SignalRescue AI — design.md"
Cohesion: 0.04
Nodes (46): 10. Content and Voice, 11. Accessibility, 12. Battery and Low-Connectivity Design, 13. Design Tokens (TypeScript), 14. Representation Guidelines (data to visuals), 15. Light vs Dark Quick Preview, 16. Design Skill (for AI agents and contributors), 17. Suggested File Structure (+38 more)

### Community 3 - "What You Must Do When Invoked"
Cohesion: 0.07
Nodes (26): For /graphify add and --watch, For /graphify query, For the commit hook and native CLAUDE.md integration, For --update and --cluster-only, /graphify, Honesty Rules, Interpreter guard for subcommands, Part A - Structural extraction for code files (+18 more)

### Community 4 - "useTheme"
Cohesion: 0.07
Nodes (62): 9. Core Components, MainTabNavigator(), Tab, Stack, Card(), Props, styles, ChatBubble() (+54 more)

### Community 5 - "chat.ts"
Cohesion: 0.09
Nodes (16): Props, chatRepository, bluetoothService, DeviceDiscoveredCallback, PacketReceivedCallback, chatService, meshService, ChatStoreState (+8 more)

### Community 6 - "graphify reference: extra exports and benchmark"
Cohesion: 0.22
Nodes (8): graphify reference: extra exports and benchmark, Step 6b - Wiki (only if --wiki flag), Step 7 - Neo4j export (only if --neo4j or --neo4j-push flag), Step 7a - FalkorDB export (only if --falkordb or --falkordb-push flag), Step 7b - SVG export (only if --svg flag), Step 7c - GraphML export (only if --graphml flag), Step 7d - MCP server (only if --mcp flag), Step 8 - Token reduction benchmark (only if total_words > 5000)

### Community 7 - "Frontend Design"
Cohesion: 0.29
Nodes (6): Design principles, Frontend Design, Ground your designs in the subject matter, More on writing in design, Process: plan, review against the brief, build, critique, Restraint and self-critique

### Community 8 - "SignalRescue Design System & UI Guidelines"
Cohesion: 0.29
Nodes (6): Always, Component recipe (React Native example), Never, Screen checklist, SignalRescue Design System & UI Guidelines, When to apply

### Community 9 - "mobile/package.json"
Cohesion: 0.11
Nodes (17): name, private, version, @babel/core, @babel/preset-env, @babel/runtime, lucide-react-native, react-native-gesture-handler (+9 more)

### Community 10 - "▶️ Running the Project"
Cohesion: 0.50
Nodes (4): 1. Launch the Interactive Mobile Client & Mesh Simulator (Edge Browser), 2. Inspect the Interactive Knowledge Graph, 3. Query the Codebase Knowledge Graph via CLI, ▶️ Running the Project

### Community 11 - "networkStore.ts"
Cohesion: 0.20
Nodes (9): Props, styles, deviceRepository, NetworkStoreState, ConnectionType, NearbyDevice, ProximityBand, MeshState (+1 more)

### Community 12 - "graphify reference: query, path, explain"
Cohesion: 0.33
Nodes (5): For /graphify explain, For /graphify path, graphify reference: query, path, explain, Step 0 — Constrained query expansion (REQUIRED before traversal), Step 1 — Traversal

### Community 13 - "RakshaNet (SignalRescue AI)"
Cohesion: 0.15
Nodes (13): 🙏 Acknowledgements, 🤖 AI / ML Architecture, 🔗 Documentation Links, 🔐 Environment Variables, 📄 License, 📌 Overview, 📋 Project Status, 📂 Project Structure (+5 more)

### Community 14 - "RakshaNet (SignalRescue AI): Verified Competitor and Uniqueness Report"
Cohesion: 0.05
Nodes (32): 1. Executive Bottom Line, 2. Verified Corrections & Reality Check, 3. Competitor Profiles (Verified), 4. Definitive Feature Matrix & Differentiation, 5. Where Competitors Beat You Today, 6. Why RakshaNet is Different, 7. What to Do Before the Pitch, A. Already Exists (Do NOT Claim as Unique) (+24 more)

### Community 15 - "graphify reference: add a URL and watch a folder"
Cohesion: 0.50
Nodes (3): For /graphify add, For --watch, graphify reference: add a URL and watch a folder

### Community 16 - "graphify reference: commit hook and native CLAUDE.md integration"
Cohesion: 0.50
Nodes (3): For git commit hook, For native CLAUDE.md integration, graphify reference: commit hook and native CLAUDE.md integration

### Community 17 - "graphify reference: incremental update and cluster-only"
Cohesion: 0.50
Nodes (3): For --cluster-only, For --update (incremental re-extraction), graphify reference: incremental update and cluster-only

### Community 25 - "SignalRescue AI (RakshaNet) — Phase 1 Implementation Plan"
Cohesion: 0.11
Nodes (18): 10. Adaptive Battery Governance, 11. Multi-Device Verification Matrix (4 Phones), 1. Phase 1 Objective, 2. Technology Stack, 3. Native Android Layer Architecture, 4. Application Startup & Progressive Permissions, 5. Required Permissions (Android-First), 6. Local Anonymous Identity (+10 more)

### Community 26 - "dependencies"
Cohesion: 0.15
Nodes (13): dependencies, lucide-react-native, react, react-native, react-native-gesture-handler, react-native-reanimated, react-native-safe-area-context, react-native-screens (+5 more)

### Community 27 - "compilerOptions"
Cohesion: 0.12
Nodes (16): compilerOptions, allowJs, allowSyntheticDefaultImports, baseUrl, esModuleInterop, isolatedModules, jsx, lib (+8 more)

### Community 28 - "profileStore.ts"
Cohesion: 0.35
Nodes (5): profileRepository, identityService, ProfileState, DeviceIdentity, UserProfile

### Community 30 - "RakshaNet Mobile (SignalRescue AI) — Phase 1"
Cohesion: 0.50
Nodes (3): 🛠️ Key Implementation Guarantees, 📱 Phase 1 Scope & Architecture, RakshaNet Mobile (SignalRescue AI) — Phase 1

### Community 32 - "✨ Features"
Cohesion: 0.20
Nodes (10): 1. Core Offline Communications & Mesh Protocol, 2. Delay-Tolerant Networking & Protocol Security, 3. Localization & Geospatial Mapping, 4. On-Device Edge & Cloud AI Intelligence, 5. Rescue Coordination & Command Center, 6. Civilian Modes & Community Resilience, 7. Implementation & Architecture in this Repository, 📱 Civilian Mobile Application Interface Suite (+2 more)

### Community 33 - "package.json"
Cohesion: 0.17
Nodes (11): author, description, keywords, license, main, name, scripts, dev (+3 more)

### Community 34 - "🚀 Installation & Reproduction"
Cohesion: 0.50
Nodes (4): 1. Clone the Repository, 2. Set Up a Virtual Environment (Recommended), 3. Install Document & Chart Dependencies, 🚀 Installation & Reproduction

### Community 35 - "🗺️ Roadmap"
Cohesion: 0.50
Nodes (4): Completed `[x]`, In Progress `[~]`, Planned `[ ]`, 🗺️ Roadmap

### Community 36 - "🎯 Problem Statement"
Cohesion: 0.50
Nodes (4): Ground-Truth Evidence: Nepal–Tibet Glacier-Collapse Floods (26 August 2026), 🎯 Problem Statement, The Indian Context, The Real-World Crisis

### Community 37 - "🗄️ Database Models (Specified Architecture)"
Cohesion: 0.67
Nodes (3): 1. On-Device SQLite Local Outbox (`design.md`), 2. Cloud PostGIS Incident Schema (`docs/features.md`), 🗄️ Database Models (Specified Architecture)

### Community 38 - "🛠️ Tech Stack"
Cohesion: 0.67
Nodes (3): Actual Technologies Implemented & Verified in Repository, Specified Architecture for Implementation, 🛠️ Tech Stack

### Community 39 - "🏆 Competitor Analysis & Market Moat"
Cohesion: 0.67
Nodes (3): 🏆 Competitor Analysis & Market Moat, Head-to-Head: RakshaNet vs. Crisis Connect, Reality Check: What is NOT Unique vs. The Real Moat

### Community 52 - "server.js"
Cohesion: 0.17
Nodes (7): { exec }, fs, http, MIME_TYPES, MOBILE_DIR, path, server

### Community 53 - "App.tsx"
Cohesion: 0.31
Nodes (6): App(), displayName, name, RootNavigator(), react-native-safe-area-context, @react-navigation/native

### Community 54 - "scripts"
Cohesion: 0.25
Nodes (8): scripts, android, dev, ios, lint, preview, start, test

### Community 55 - "sqlite.ts"
Cohesion: 0.29
Nodes (3): CREATE_TABLES_SQL, DatabaseManager, dbManager

### Community 56 - "devDependencies"
Cohesion: 0.29
Nodes (7): devDependencies, @babel/core, @babel/preset-env, @babel/runtime, @types/react, @types/react-native, typescript

## Knowledge Gaps
- **345 isolated node(s):** `displayName`, `{ getDefaultConfig, mergeConfig }`, `config`, `name`, `version` (+340 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 407 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **21 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `SignalRescue AI — design.md` connect `SignalRescue AI — design.md` to `useTheme`, `RakshaNet (SignalRescue AI): Verified Competitor and Uniqueness Report`?**
  _High betweenness centrality (0.269) - this node is a cross-community bridge._
- **Why does `9. Core Components` connect `useTheme` to `SignalRescue AI — design.md`?**
  _High betweenness centrality (0.229) - this node is a cross-community bridge._
- **What connects `displayName`, `{ getDefaultConfig, mergeConfig }`, `config` to the rest of the system?**
  _345 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `SignalRescue AI (RakshaNet) — Complete Feature Set` be split into smaller, more focused modules?**
  _Cohesion score 0.046511627906976744 - nodes in this community are weakly interconnected._
- **Should `RakshaNet — Offline Disaster Communication and AI Rescue System` be split into smaller, more focused modules?**
  _Cohesion score 0.07407407407407407 - nodes in this community are weakly interconnected._
- **Should `SignalRescue AI — design.md` be split into smaller, more focused modules?**
  _Cohesion score 0.043478260869565216 - nodes in this community are weakly interconnected._
- **Should `What You Must Do When Invoked` be split into smaller, more focused modules?**
  _Cohesion score 0.07407407407407407 - nodes in this community are weakly interconnected._