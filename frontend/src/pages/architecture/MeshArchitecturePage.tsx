import React, { useState, useEffect, useRef, useMemo } from 'react';
import { Link } from 'react-router-dom';
import {
  Radio,
  Wifi,
  Smartphone,
  Tablet,
  Server,
  ShieldCheck,
  Lock,
  Unlock,
  Play,
  Pause,
  RotateCcw,
  SkipForward,
  MapPin,
  Users,
  CloudUpload,
  Share2,
  Zap,
  AlertTriangle,
  ArrowRight,
  Layers,
  Activity,
  CheckCircle2,
  Copy,
  Check,
  Eye,
  FileText,
  Network,
  RefreshCw,
  Sliders,
  Cpu,
  Database,
  Key,
  Compass,
  Binary,
  Workflow,
  Sparkles,
  ChevronRight,
  SlidersHorizontal,
  Flame,
  Volume2,
  HelpCircle,
  Clock,
  Send,
  Droplets,
  Building,
  Navigation,
} from 'lucide-react';
import { Card } from '../../components/common/Card';
import { Badge } from '../../components/common/Badge';

// =============================================================================
// TYPES & DATA STRUCTURES
// =============================================================================

export type ScenarioType = 'SOS' | 'GROUP_MSG' | 'PHOTO_CHUNK' | 'SIGHTING';

export type PacketTypeColor = '#FF365D' | '#38BDF8' | '#00F5A0' | '#FFB020' | '#A855F7' | '#06B6D4';

export interface SimulatedPacket {
  packetId: string;
  scenarioType: ScenarioType;
  sourceNodeId: string;
  destinationNodeId: string;
  currentNodeId: string;
  hopCount: number;
  ttl: number;
  payloadSizeBytes: number;
  priority: 'CRITICAL' | 'HIGH' | 'NORMAL' | 'LOW';
  createdAt: number;
  deliveryStatus: 'CREATING' | 'IN_TRANSIT' | 'STORED_IN_MULE' | 'GATEWAY_UPLINK' | 'DELIVERED_SERVER' | 'FAILED_DROPPED';
  encryptionStatus: 'X25519_AES256_GCM_SIGNED';
  retryCount: number;
  payloadPreview: string;
  photoChunkIndex?: number;
  totalPhotoChunks?: number;
}

export interface NetworkNodeDef {
  id: string;
  name: string;
  role: 'ORIGIN' | 'RELAY' | 'MULE' | 'REPEATER' | 'GATEWAY' | 'COMMAND_CENTER';
  roleLabel: string;
  x: number;
  y: number;
  batteryPct: number;
  signalDbm: number;
  queueSize: number;
  status: 'ONLINE' | 'RELAYING' | 'OFFLINE';
  iconType: 'phone' | 'phone_relay' | 'mule' | 'repeater' | 'tablet' | 'satellite' | 'cloud' | 'base';
  deviceModel: string;
  sector: string;
}

export interface NetworkEdgeDef {
  id: string;
  fromNode: string;
  toNode: string;
  linkType: 'BLE_53' | 'WIFI_DIRECT' | 'LORA_P2P' | 'SATELLITE_WAN';
  isAvailable: boolean;
  latencyMs: number;
  bandwidthKbps: number;
  rssiDbm: number;
  curvature: number; // for SVG curved bezier control
}

export interface DiagnosticLog {
  id: string;
  timestamp: string;
  eventType:
    | 'SOS_CREATED'
    | 'PAYLOAD_ENCRYPTED'
    | 'ROUTE_SELECTED'
    | 'PACKET_FORWARDED'
    | 'HOP_ACKNOWLEDGED'
    | 'RELAY_UNAVAILABLE'
    | 'PACKET_QUEUED'
    | 'GATEWAY_CONNECTED'
    | 'UPLOAD_STARTED'
    | 'SERVER_ACKNOWLEDGED'
    | 'INCIDENT_SYNCED';
  sourceNode: string;
  targetNode: string;
  message: string;
  details: string;
  severity: 'INFO' | 'WARN' | 'SUCCESS' | 'CRITICAL';
}

export interface QueuedItem {
  id: string;
  category: 'SOS' | 'GROUP' | 'PHOTO' | 'LOCATION' | 'MISSING' | 'WATER';
  priority: 'CRITICAL' | 'HIGH' | 'NORMAL';
  title: string;
  sizeBytes: number;
  status: 'QUEUED' | 'TRANSMITTING' | 'SYNCED' | 'EXPIRED';
  retryCount: number;
  timestamp: string;
  chunksReceived?: number;
  totalChunks?: number;
}

// =============================================================================
// MAIN CINEMATIC VISUALIZER COMPONENT
// =============================================================================

export const MeshArchitecturePage: React.FC = () => {
  // Scenario & Simulation State
  const [scenario, setScenario] = useState<ScenarioType>('SOS');
  const [isPlaying, setIsPlaying] = useState<boolean>(false);
  const [simSpeed, setSimSpeed] = useState<number>(1);
  const [currentStepIndex, setCurrentStepIndex] = useState<number>(0);

  // Failure & Network Controls
  const [repeaterOffline, setRepeaterOffline] = useState<boolean>(false);
  const [gatewayOnline, setGatewayOnline] = useState<boolean>(true);
  const [showTrails, setShowTrails] = useState<boolean>(true);
  const [showLabels, setShowLabels] = useState<boolean>(true);
  const [activeTab, setActiveTab] = useState<'visualizer' | 'infographics' | 'queue' | 'diagnostics'>('visualizer');

  // Selected Interactive Elements
  const [selectedNodeId, setSelectedNodeId] = useState<string | null>('node1');
  const [selectedLogId, setSelectedLogId] = useState<string | null>(null);

  // 8 ARCHITECTURAL NETWORK NODES (Curved Topo Layout)
  const nodes: NetworkNodeDef[] = useMemo(() => [
    {
      id: 'node1',
      name: 'Survivor Phone',
      role: 'ORIGIN',
      roleLabel: 'Distress Beacon (0 Hops)',
      x: 100,
      y: 260,
      batteryPct: 74,
      signalDbm: -68,
      queueSize: 1,
      status: 'ONLINE',
      iconType: 'phone',
      deviceModel: 'Pixel 7a (BLE 5.3 + GNSS)',
      sector: 'Sector 4B Submerged Riverbank',
    },
    {
      id: 'node2',
      name: 'Nearby Citizen Relay',
      role: 'RELAY',
      roleLabel: 'Mesh Peer Relay (1 Hop)',
      x: 230,
      y: 150,
      batteryPct: 88,
      signalDbm: -56,
      queueSize: 2,
      status: 'ONLINE',
      iconType: 'phone_relay',
      deviceModel: 'Samsung Galaxy A54 (BLE Mesh)',
      sector: 'Sector 4B Residential Block 2',
    },
    {
      id: 'node3',
      name: 'Data Mule Phone B',
      role: 'MULE',
      roleLabel: 'Store & Forward Mule',
      x: 380,
      y: 280,
      batteryPct: 82,
      signalDbm: -52,
      queueSize: 4,
      status: 'ONLINE',
      iconType: 'mule',
      deviceModel: 'OnePlus Nord 3 (Mule Carrier)',
      sector: 'Volunteer Evacuation Corridor',
    },
    {
      id: 'node4',
      name: 'Solar Ridge Repeater',
      role: 'REPEATER',
      roleLabel: 'Autonomous LoRa Bridge',
      x: 520,
      y: 110,
      batteryPct: repeaterOffline ? 0 : 100,
      signalDbm: repeaterOffline ? -120 : -42,
      queueSize: 0,
      status: repeaterOffline ? 'OFFLINE' : 'ONLINE',
      iconType: 'repeater',
      deviceModel: 'Autonomous Solar LoRa Beacon v3',
      sector: 'Guindy High Elevation Ridge',
    },
    {
      id: 'node5',
      name: 'Rescue Squad Tablet',
      role: 'GATEWAY',
      roleLabel: 'Field Mobile Gateway',
      x: 670,
      y: 230,
      batteryPct: 95,
      signalDbm: -48,
      queueSize: 6,
      status: 'ONLINE',
      iconType: 'tablet',
      deviceModel: 'Panasonic Toughbook NDRF Squad 4',
      sector: 'Forward Relief Staging Base',
    },
    {
      id: 'node6',
      name: 'Connected Mobile Phone',
      role: 'GATEWAY',
      roleLabel: 'Temporary 4G/5G Gateway',
      x: 770,
      y: 350,
      batteryPct: 68,
      signalDbm: -54,
      queueSize: 3,
      status: gatewayOnline ? 'ONLINE' : 'OFFLINE',
      iconType: 'satellite',
      deviceModel: 'Iridium GO! Satellite Gateway',
      sector: 'Disaster Perimeter Fringe',
    },
    {
      id: 'node7',
      name: 'RakshaNet Cloud API',
      role: 'COMMAND_CENTER',
      roleLabel: 'FastAPI Ingestion Endpoint',
      x: 880,
      y: 140,
      batteryPct: 100,
      signalDbm: -35,
      queueSize: 18,
      status: 'ONLINE',
      iconType: 'cloud',
      deviceModel: 'FastAPI REST + WebSocket Stream :8000',
      sector: 'SA-East AWS Cloud Core',
    },
    {
      id: 'node8',
      name: 'Command Center Base',
      role: 'COMMAND_CENTER',
      roleLabel: 'Disaster Operations Console',
      x: 990,
      y: 260,
      batteryPct: 100,
      signalDbm: -30,
      queueSize: 0,
      status: 'ONLINE',
      iconType: 'base',
      deviceModel: 'Incident Commander Operations Terminal',
      sector: 'National Disaster Management HQ',
    },
  ], [repeaterOffline, gatewayOnline]);

  // NETWORK EDGES (Curved routing links)
  const edges: NetworkEdgeDef[] = useMemo(() => [
    { id: 'e1_2', fromNode: 'node1', toNode: 'node2', linkType: 'BLE_53', isAvailable: true, latencyMs: 22, bandwidthKbps: 120, rssiDbm: -58, curvature: -25 },
    { id: 'e1_3', fromNode: 'node1', toNode: 'node3', linkType: 'BLE_53', isAvailable: true, latencyMs: 38, bandwidthKbps: 90, rssiDbm: -68, curvature: 20 },
    { id: 'e2_4', fromNode: 'node2', toNode: 'node4', linkType: 'LORA_P2P', isAvailable: !repeaterOffline, latencyMs: 85, bandwidthKbps: 22, rssiDbm: -52, curvature: -35 },
    { id: 'e3_4', fromNode: 'node3', toNode: 'node4', linkType: 'LORA_P2P', isAvailable: !repeaterOffline, latencyMs: 92, bandwidthKbps: 22, rssiDbm: -56, curvature: -15 },
    { id: 'e3_5', fromNode: 'node3', toNode: 'node5', linkType: 'WIFI_DIRECT', isAvailable: true, latencyMs: 14, bandwidthKbps: 24000, rssiDbm: -48, curvature: 35 },
    { id: 'e4_5', fromNode: 'node4', toNode: 'node5', linkType: 'WIFI_DIRECT', isAvailable: !repeaterOffline, latencyMs: 18, bandwidthKbps: 18000, rssiDbm: -50, curvature: -20 },
    { id: 'e5_6', fromNode: 'node5', toNode: 'node6', linkType: 'BLE_53', isAvailable: gatewayOnline, latencyMs: 30, bandwidthKbps: 150, rssiDbm: -62, curvature: 25 },
    { id: 'e5_7', fromNode: 'node5', toNode: 'node7', linkType: 'SATELLITE_WAN', isAvailable: true, latencyMs: 320, bandwidthKbps: 1200, rssiDbm: -40, curvature: -30 },
    { id: 'e6_7', fromNode: 'node6', toNode: 'node7', linkType: 'SATELLITE_WAN', isAvailable: gatewayOnline, latencyMs: 65, bandwidthKbps: 45000, rssiDbm: -44, curvature: -10 },
    { id: 'e7_8', fromNode: 'node7', toNode: 'node8', linkType: 'SATELLITE_WAN', isAvailable: true, latencyMs: 8, bandwidthKbps: 100000, rssiDbm: -32, curvature: 15 },
  ], [repeaterOffline, gatewayOnline]);

  // ACTIVE SIMULATED PACKET
  const activePacket: SimulatedPacket = useMemo(() => {
    switch (scenario) {
      case 'SOS':
        return {
          packetId: 'PKT-SOS-98A1',
          scenarioType: 'SOS',
          sourceNodeId: 'node1',
          destinationNodeId: 'node8',
          currentNodeId: currentStepIndex === 0 ? 'node1' : currentStepIndex === 1 ? 'node3' : currentStepIndex === 2 ? (repeaterOffline ? 'node5' : 'node4') : currentStepIndex === 3 ? 'node5' : currentStepIndex === 4 ? 'node7' : 'node8',
          hopCount: currentStepIndex,
          ttl: Math.max(0, 5 - currentStepIndex),
          payloadSizeBytes: 142,
          priority: 'CRITICAL',
          createdAt: Date.now() - 45000,
          deliveryStatus: currentStepIndex === 5 ? 'DELIVERED_SERVER' : currentStepIndex >= 3 ? 'GATEWAY_UPLINK' : 'IN_TRANSIT',
          encryptionStatus: 'X25519_AES256_GCM_SIGNED',
          retryCount: 0,
          payloadPreview: 'SOS: Water 1.8m in Ward 14. 2 Elderly Trapped. GPS: 13.0425° N, 80.2285° E',
        };
      case 'GROUP_MSG':
        return {
          packetId: 'PKT-GRP-77C2',
          scenarioType: 'GROUP_MSG',
          sourceNodeId: 'node1',
          destinationNodeId: 'node8',
          currentNodeId: currentStepIndex === 0 ? 'node1' : 'node2',
          hopCount: currentStepIndex,
          ttl: Math.max(0, 5 - currentStepIndex),
          payloadSizeBytes: 210,
          priority: 'HIGH',
          createdAt: Date.now() - 32000,
          deliveryStatus: currentStepIndex >= 3 ? 'DELIVERED_SERVER' : 'IN_TRANSIT',
          encryptionStatus: 'X25519_AES256_GCM_SIGNED',
          retryCount: 0,
          payloadPreview: 'Group (#ward-14): Relief food packets distributed at Community School.',
        };
      case 'PHOTO_CHUNK':
        return {
          packetId: 'PKT-IMG-4029',
          scenarioType: 'PHOTO_CHUNK',
          sourceNodeId: 'node1',
          destinationNodeId: 'node8',
          currentNodeId: currentStepIndex >= 3 ? 'node7' : 'node3',
          hopCount: currentStepIndex,
          ttl: Math.max(0, 5 - currentStepIndex),
          payloadSizeBytes: 16384,
          priority: 'NORMAL',
          createdAt: Date.now() - 60000,
          deliveryStatus: currentStepIndex >= 4 ? 'DELIVERED_SERVER' : 'STORED_IN_MULE',
          encryptionStatus: 'X25519_AES256_GCM_SIGNED',
          retryCount: 1,
          payloadPreview: 'Attachment: flooded_canal_breach.jpg (Chunk 3/4 • SHA-256 Verified)',
          photoChunkIndex: 3,
          totalPhotoChunks: 4,
        };
      case 'SIGHTING':
        return {
          packetId: 'PKT-MP-8831',
          scenarioType: 'SIGHTING',
          sourceNodeId: 'node1',
          destinationNodeId: 'node8',
          currentNodeId: currentStepIndex >= 4 ? 'node8' : 'node5',
          hopCount: currentStepIndex,
          ttl: Math.max(0, 5 - currentStepIndex),
          payloadSizeBytes: 340,
          priority: 'HIGH',
          createdAt: Date.now() - 18000,
          deliveryStatus: currentStepIndex === 5 ? 'DELIVERED_SERVER' : 'GATEWAY_UPLINK',
          encryptionStatus: 'X25519_AES256_GCM_SIGNED',
          retryCount: 0,
          payloadPreview: 'Missing Sighting: Rameshwar Sen seen safe at Community Camp Block B.',
        };
    }
  }, [scenario, currentStepIndex, repeaterOffline]);

  // DIAGNOSTIC LOGS
  const diagnosticLogs: DiagnosticLog[] = useMemo(() => [
    {
      id: 'log-01',
      timestamp: '16:20:02.104',
      eventType: 'SOS_CREATED',
      sourceNode: 'node1 (Survivor)',
      targetNode: 'node1',
      message: 'Triple-tap power hardware SOS trigger actuated. Acquired GNSS GPS fix: 13.0425° N, 80.2285° E (±4.2m).',
      details: 'Payload generated: 142 bytes. Urgency: CRITICAL. Casualties: 2.',
      severity: 'CRITICAL',
    },
    {
      id: 'log-02',
      timestamp: '16:20:02.189',
      eventType: 'PAYLOAD_ENCRYPTED',
      sourceNode: 'node1 (Survivor)',
      targetNode: 'node1',
      message: 'X25519 ECDH shared secret derived with Command Base. Signed with Ed25519 private key.',
      details: 'AES-GCM-256 encryption complete. 128-bit MAC auth tag appended. Wire format sealed.',
      severity: 'SUCCESS',
    },
    {
      id: 'log-03',
      timestamp: '16:20:02.412',
      eventType: 'ROUTE_SELECTED',
      sourceNode: 'node1 (Survivor)',
      targetNode: 'node3 (Data Mule)',
      message: 'AODV-Mesh protocol evaluates candidate peers: Node 2 (RSSI -56) and Node 3 (RSSI -52). Direct mule route chosen.',
      details: 'Protocol: BLE 5.3 ADV_EXT. Channel: 37/38/39 hopping.',
      severity: 'INFO',
    },
    {
      id: 'log-04',
      timestamp: '16:20:03.018',
      eventType: 'PACKET_FORWARDED',
      sourceNode: 'node1 (Survivor)',
      targetNode: 'node3 (Data Mule)',
      message: 'Packet PKT-SOS-98A1 transmitted across 28m flood gap to Data Mule Phone B.',
      details: 'Byte count: 142 B. Hop count incremented to 1. TTL decremented to 4.',
      severity: 'INFO',
    },
    {
      id: 'log-05',
      timestamp: '16:20:03.112',
      eventType: 'HOP_ACKNOWLEDGED',
      sourceNode: 'node3 (Data Mule)',
      targetNode: 'node1 (Survivor)',
      message: 'Bloom filter bitset updated with hash(PKT-SOS-98A1). Persisted into SQLite table encrypted_mesh_packets.',
      details: 'Zero-knowledge relay: Mule inspects RoutingHeader only; cannot decrypt payload.',
      severity: 'SUCCESS',
    },
    {
      id: 'log-06',
      timestamp: '16:20:04.280',
      eventType: repeaterOffline ? 'RELAY_UNAVAILABLE' : 'PACKET_FORWARDED',
      sourceNode: 'node3 (Data Mule)',
      targetNode: repeaterOffline ? 'node5 (Rescue Squad)' : 'node4 (Solar Repeater)',
      message: repeaterOffline
        ? 'Repeater Beacon 4 failed! AODV-Mesh dynamically bypasses to Rescue Squad Tablet 5 via Wi-Fi Direct.'
        : 'Transmitted over LoRa 868MHz P2P bridge to elevated Solar Ridge Repeater 4.',
      details: repeaterOffline ? 'Alternate path selected. Self-healing mesh activated.' : 'Carrier: 868.1 MHz SF7 BW125. RSSI: -52 dBm.',
      severity: repeaterOffline ? 'WARN' : 'INFO',
    },
    {
      id: 'log-07',
      timestamp: '16:20:05.419',
      eventType: 'GATEWAY_CONNECTED',
      sourceNode: 'node5 (Rescue Squad)',
      targetNode: 'node7 (Cloud API)',
      message: 'Rescue Squad Vehicle reaches cellular fringe / satellite dish. NetworkStateService detects isInternetGateway = true!',
      details: 'Batch ingestion queue triggered: 4 buffered packets scheduled for HTTPS upload.',
      severity: 'SUCCESS',
    },
    {
      id: 'log-08',
      timestamp: '16:20:06.115',
      eventType: 'SERVER_ACKNOWLEDGED',
      sourceNode: 'node7 (Cloud API)',
      targetNode: 'node8 (Command Base)',
      message: 'FastAPI gateway ingests POST /api/v1/packets. Deduplication verified in MongoDB & SQLite.',
      details: 'DBSCAN spatial clustering groups distress signals (eps=120m). Incident INC-FLD-2026-001 created.',
      severity: 'SUCCESS',
    },
    {
      id: 'log-09',
      timestamp: '16:20:06.340',
      eventType: 'INCIDENT_SYNCED',
      sourceNode: 'node8 (Command Base)',
      targetNode: 'node8 (Command Base)',
      message: 'Command Center operations console receives live incident alert via /ws/mesh. Zodiac rescue boat dispatched.',
      details: 'Full end-to-end telemetry verified in 4.23 seconds.',
      severity: 'CRITICAL',
    },
  ], [repeaterOffline]);

  // STORE-AND-FORWARD QUEUE MOCK DATA
  const queuedItems: QueuedItem[] = [
    { id: 'Q-SOS-01', category: 'SOS', priority: 'CRITICAL', title: 'Ward 14 Flood SOS - 2 Elderly Trapped', sizeBytes: 142, status: 'SYNCED', retryCount: 0, timestamp: '16:20:02' },
    { id: 'Q-GRP-02', category: 'GROUP', priority: 'HIGH', title: 'Relief Camp Food Distribution Alert', sizeBytes: 210, status: 'TRANSMITTING', retryCount: 1, timestamp: '16:19:40' },
    { id: 'Q-IMG-03', category: 'PHOTO', priority: 'NORMAL', title: 'flooded_canal_breach.jpg (Chunk 3/4)', sizeBytes: 16384, status: 'QUEUED', retryCount: 2, timestamp: '16:18:12', chunksReceived: 3, totalChunks: 4 },
    { id: 'Q-LOC-04', category: 'LOCATION', priority: 'NORMAL', title: 'Survivor GPS Track Log #492', sizeBytes: 88, status: 'SYNCED', retryCount: 0, timestamp: '16:17:50' },
    { id: 'Q-MP-05', category: 'MISSING', priority: 'HIGH', title: 'Sighting: Rameshwar Sen at Camp B', sizeBytes: 340, status: 'QUEUED', retryCount: 0, timestamp: '16:16:30' },
    { id: 'Q-WAT-06', category: 'WATER', priority: 'NORMAL', title: 'Water TDS & Contamination Test 420ppm', sizeBytes: 120, status: 'QUEUED', retryCount: 1, timestamp: '16:15:10' },
  ];

  // Simulation Step Advancement
  useEffect(() => {
    let interval: any;
    if (isPlaying) {
      interval = setInterval(() => {
        setCurrentStepIndex((prev) => {
          if (prev >= 5) {
            setIsPlaying(false);
            return prev;
          }
          return prev + 1;
        });
      }, 3000 / simSpeed);
    }
    return () => clearInterval(interval);
  }, [isPlaying, simSpeed]);

  const selectedNode = nodes.find((n) => n.id === selectedNodeId) || nodes[0];

  return (
    <div className="space-y-5 max-w-[1400px] mx-auto pb-12 text-[#F8FAFC]">
      {/* Top Header & Breadcrumb */}
      <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4 bg-[#070D19] border border-[#1E293B] p-4 rounded-2xl shadow-xl">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-cyan-500/10 text-[#38BDF8] border border-cyan-500/30 text-xs font-mono font-bold tracking-wider uppercase">
              <Activity size={12} className="text-[#38BDF8] animate-pulse" />
              <span>RakshaNet Mesh Core // Operational Console</span>
            </span>
            <span className="text-xs text-slate-500">•</span>
            <span className="text-xs font-mono text-[#00F5A0] font-bold">LIVE TELEMETRY STREAM ACTIVE</span>
          </div>
          <h1
            className="text-2xl sm:text-3xl font-black text-white tracking-tight"
            style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
          >
            Tactical Offline Mesh Network Visualizer &amp; Hop Engine
          </h1>
        </div>

        {/* Global Controls & Return */}
        <div className="flex flex-wrap items-center gap-2">
          <Link
            to="/app/dashboard"
            className="px-3.5 py-2 rounded-xl bg-[#0D1729] text-[#94A3B8] hover:text-white border border-[#263650] text-xs font-bold transition-all shadow-xs"
          >
            ← Command Dashboard
          </Link>
          <Link
            to="/app/map"
            className="px-3.5 py-2 rounded-xl bg-[#FFB020] text-[#050816] text-xs font-black hover:brightness-105 transition-all shadow-md"
          >
            Live Disaster Map
          </Link>
        </div>
      </div>

      {/* TOP INTERACTIVE CONTROL BAR (Preserving & Upgrading all existing controls) */}
      <div className="bg-[#0D1729] border border-[#263650] rounded-2xl p-4 shadow-xl flex flex-wrap items-center justify-between gap-4">
        {/* Scenario Packet Selector */}
        <div className="flex flex-wrap items-center gap-2">
          <span className="text-xs font-bold text-[#94A3B8] uppercase tracking-wider mr-1">
            Scenario Packet:
          </span>
          {[
            { id: 'SOS', label: '🚨 Emergency SOS Beacon', color: '#FF365D' },
            { id: 'GROUP_MSG', label: '👥 E2EE Group Alert', color: '#38BDF8' },
            { id: 'PHOTO_CHUNK', label: '📸 16KB Photo Chunk', color: '#FFB020' },
            { id: 'SIGHTING', label: '🔍 Missing Sighting', color: '#A855F7' },
          ].map((sc) => (
            <button
              key={sc.id}
              onClick={() => {
                setScenario(sc.id as ScenarioType);
                setCurrentStepIndex(0);
                setIsPlaying(false);
              }}
              className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                scenario === sc.id
                  ? 'bg-white text-slate-950 font-black shadow-md ring-2 ring-amber-400'
                  : 'bg-[#070D19] text-[#94A3B8] border border-[#263650] hover:text-white hover:border-slate-500'
              }`}
            >
              {sc.label}
            </button>
          ))}
        </div>

        {/* Engine Controls: Play, Step, Reset, Speed, Failure */}
        <div className="flex flex-wrap items-center gap-2">
          <button
            onClick={() => setIsPlaying(!isPlaying)}
            className="px-4 py-1.5 rounded-xl bg-[#FFB020] text-[#050816] text-xs font-black hover:brightness-105 transition-all flex items-center gap-1.5 shadow-md cursor-pointer"
          >
            {isPlaying ? <Pause size={14} /> : <Play size={14} />}
            <span>{isPlaying ? 'Pause' : 'Play Flow'}</span>
          </button>

          <button
            onClick={() => {
              setIsPlaying(false);
              setCurrentStepIndex((prev) => (prev < 5 ? prev + 1 : 0));
            }}
            className="p-2 rounded-xl bg-[#070D19] text-white border border-[#263650] hover:bg-[#1E293B] transition-colors cursor-pointer"
            title="Step next hop"
          >
            <SkipForward size={14} />
          </button>

          <button
            onClick={() => {
              setIsPlaying(false);
              setCurrentStepIndex(0);
            }}
            className="p-2 rounded-xl bg-[#070D19] text-white border border-[#263650] hover:bg-[#1E293B] transition-colors cursor-pointer"
            title="Reset simulation"
          >
            <RotateCcw size={14} />
          </button>

          {/* Speed Selector */}
          <button
            onClick={() => setSimSpeed((s) => (s === 1 ? 2 : s === 2 ? 4 : s === 4 ? 0.5 : 1))}
            className="px-2.5 py-1.5 rounded-xl bg-[#070D19] text-[#38BDF8] border border-[#263650] text-xs font-mono font-bold hover:bg-[#1E293B] cursor-pointer"
          >
            {simSpeed}x Speed
          </button>

          {/* Simulate Repeater Failure */}
          <button
            onClick={() => setRepeaterOffline((prev) => !prev)}
            className={`px-3 py-1.5 rounded-xl text-xs font-bold border transition-all cursor-pointer ${
              repeaterOffline
                ? 'bg-rose-500/20 text-[#FF365D] border-rose-500/50 shadow-xs'
                : 'bg-[#070D19] text-[#94A3B8] border-[#263650] hover:text-white'
            }`}
          >
            {repeaterOffline ? 'Repeater: FAULT (Bypassing)' : 'Simulate Repeater Failure'}
          </button>

          {/* Toggle Gateway Availability */}
          <button
            onClick={() => setGatewayOnline((prev) => !prev)}
            className={`px-3 py-1.5 rounded-xl text-xs font-bold border transition-all cursor-pointer ${
              gatewayOnline
                ? 'bg-emerald-500/15 text-[#00F5A0] border-emerald-500/40 shadow-xs'
                : 'bg-rose-500/15 text-rose-400 border-rose-500/40'
            }`}
          >
            {gatewayOnline ? 'Gateway: CONNECTED' : 'Gateway: DISCONNECTED'}
          </button>
        </div>
      </div>

      {/* MODULE NAVIGATION TABS */}
      <div className="flex items-center gap-2 border-b border-[#263650] pb-2 overflow-x-auto scrollbar-tactical">
        {[
          { id: 'visualizer', label: '🌐 Interactive 8-Node Mesh Topology', icon: Network },
          { id: 'infographics', label: '📊 Architectural Reference Panels (7, 8 & 9)', icon: Layers },
          { id: 'queue', label: `💾 Store-and-Forward Queues (${queuedItems.length})`, icon: Database },
          { id: 'diagnostics', label: `📡 Diagnostics & Timeline (${diagnosticLogs.length})`, icon: Binary },
        ].map((tab) => {
          const active = activeTab === tab.id;
          const Icon = tab.icon;
          return (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id as any)}
              className={`inline-flex items-center gap-2 px-4 py-2.5 rounded-xl text-xs font-bold transition-all whitespace-nowrap cursor-pointer ${
                active
                  ? 'bg-[#38BDF8] text-[#050816] shadow-md font-black'
                  : 'bg-[#0D1729] border border-[#263650] text-[#94A3B8] hover:text-white hover:bg-[#1E293B]'
              }`}
            >
              <Icon size={14} />
              <span>{tab.label}</span>
            </button>
          );
        })}
      </div>

      {/* =========================================================================
          MODULE 1: CINEMATIC 8-NODE TOPOLOGY SVG CANVAS
          ========================================================================= */}
      {activeTab === 'visualizer' && (
        <div className="space-y-4">
          <div className="relative rounded-3xl bg-[#070D19] border border-[#1E293B] p-6 shadow-2xl overflow-hidden min-h-[580px] flex flex-col justify-between">
            {/* Ambient Radial Glow & Grid Background */}
            <div
              className="absolute inset-0 opacity-20 pointer-events-none"
              style={{
                backgroundImage:
                  'radial-gradient(circle at 1px 1px, #38BDF8 1px, transparent 0)',
                backgroundSize: '36px 36px',
              }}
            />
            <div className="absolute top-1/4 left-1/3 w-96 h-96 bg-cyan-500/5 rounded-full blur-3xl pointer-events-none" />
            <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-emerald-500/5 rounded-full blur-3xl pointer-events-none" />

            {/* Top Canvas Telemetry HUD */}
            <div className="relative z-20 flex flex-wrap items-center justify-between gap-3 pb-3 border-b border-[#1E293B] text-xs">
              <div className="flex items-center gap-3">
                <span className="flex items-center gap-1.5 font-mono font-bold text-white uppercase tracking-wider">
                  <span className="w-2.5 h-2.5 rounded-full bg-[#00F5A0] animate-ping" />
                  <span>Dynamic Mesh Engine: Stage {currentStepIndex + 1} of 6</span>
                </span>
                <span className="text-slate-600">|</span>
                <span className="font-mono text-[11px] text-[#94A3B8]">
                  Active Route: <strong className="text-white">Node 1 → Node {currentStepIndex === 1 ? '2/3' : currentStepIndex === 2 ? (repeaterOffline ? '5' : '4') : currentStepIndex === 3 ? '5' : currentStepIndex === 4 ? '7' : '8'}</strong>
                </span>
              </div>

              <div className="flex items-center gap-3 font-mono text-[11px]">
                <span className="text-[#94A3B8]">
                  Hops Traversed: <strong className="text-white">{activePacket.hopCount}</strong>
                </span>
                <span className="text-[#94A3B8]">
                  TTL Remaining: <strong className="text-[#FFB020]">{activePacket.ttl}</strong>
                </span>
                <span className="text-[#38BDF8]">
                  Payload: <strong className="text-white">{activePacket.payloadSizeBytes} B</strong>
                </span>
                <span className="px-2 py-0.5 rounded bg-emerald-950/60 text-[#00F5A0] border border-emerald-500/30 font-bold">
                  {activePacket.encryptionStatus}
                </span>
              </div>
            </div>

            {/* SVG RENDERING FOR CURVED CONNECTIONS & ANIMATED PACKET BEAMS */}
            <div className="relative w-full h-[400px] my-2 z-10">
              <svg className="w-full h-full pointer-events-none" viewBox="0 0 1100 400">
                <defs>
                  {/* Glowing gradients */}
                  <linearGradient id="edgeBle" x1="0%" y1="0%" x2="100%" y2="0%">
                    <stop offset="0%" stopColor="#38BDF8" />
                    <stop offset="100%" stopColor="#00F5A0" />
                  </linearGradient>
                  <linearGradient id="edgeLora" x1="0%" y1="0%" x2="100%" y2="0%">
                    <stop offset="0%" stopColor="#06B6D4" />
                    <stop offset="100%" stopColor="#FFB020" />
                  </linearGradient>
                  <linearGradient id="edgeWifi" x1="0%" y1="0%" x2="100%" y2="0%">
                    <stop offset="0%" stopColor="#FFB020" />
                    <stop offset="100%" stopColor="#00F5A0" />
                  </linearGradient>

                  <filter id="cinematicGlow">
                    <feGaussianBlur stdDeviation="4" result="coloredBlur" />
                    <feMerge>
                      <feMergeNode in="coloredBlur" />
                      <feMergeNode in="SourceGraphic" />
                    </feMerge>
                  </filter>
                </defs>

                {/* Draw Curved Interconnection Edges */}
                {edges.map((edge) => {
                  const from = nodes.find((n) => n.id === edge.fromNode);
                  const to = nodes.find((n) => n.id === edge.toNode);
                  if (!from || !to) return null;

                  // Compute quadratic curved control point
                  const midX = (from.x + to.x) / 2;
                  const midY = (from.y + to.y) / 2 + edge.curvature;
                  const d = `M ${from.x} ${from.y} Q ${midX} ${midY} ${to.x} ${to.y}`;

                  const isEdgeActive =
                    (edge.fromNode === activePacket.currentNodeId) ||
                    (currentStepIndex >= 1 && edge.id === 'e1_3') ||
                    (currentStepIndex >= 2 && edge.id === 'e3_4' && !repeaterOffline) ||
                    (currentStepIndex >= 2 && edge.id === 'e3_5' && repeaterOffline) ||
                    (currentStepIndex >= 3 && edge.id === 'e4_5' && !repeaterOffline) ||
                    (currentStepIndex >= 4 && edge.id === 'e5_7') ||
                    (currentStepIndex >= 5 && edge.id === 'e7_8');

                  return (
                    <g key={edge.id}>
                      <path
                        d={d}
                        fill="none"
                        stroke={edge.isAvailable ? (isEdgeActive ? '#38BDF8' : '#1E293B') : '#3A1512'}
                        strokeWidth={isEdgeActive ? 3 : 1.5}
                        strokeDasharray={edge.isAvailable ? (isEdgeActive ? 'none' : '4 4') : '2 4'}
                        strokeOpacity={edge.isAvailable ? (isEdgeActive ? 0.9 : 0.4) : 0.2}
                        filter={isEdgeActive ? 'url(#cinematicGlow)' : undefined}
                      />
                    </g>
                  );
                })}

                {/* Animated Packet Beam moving along active hop */}
                <g
                  transform={`translate(${
                    currentStepIndex === 0 ? 100 :
                    currentStepIndex === 1 ? 380 :
                    currentStepIndex === 2 ? (repeaterOffline ? 670 : 520) :
                    currentStepIndex === 3 ? 670 :
                    currentStepIndex === 4 ? 880 : 990
                  }, ${
                    currentStepIndex === 0 ? 260 :
                    currentStepIndex === 1 ? 280 :
                    currentStepIndex === 2 ? (repeaterOffline ? 230 : 110) :
                    currentStepIndex === 3 ? 230 :
                    currentStepIndex === 4 ? 140 : 260
                  })`}
                  style={{ transition: 'transform 0.8s cubic-bezier(0.4, 0, 0.2, 1)' }}
                >
                  <circle r="14" fill="#FFB020" opacity="0.3" className="animate-ping" />
                  <circle r="8" fill={scenario === 'SOS' ? '#FF365D' : scenario === 'GROUP_MSG' ? '#38BDF8' : '#FFB020'} filter="url(#cinematicGlow)" />
                  <circle r="4" fill="#FFFFFF" />
                  <text y="24" textAnchor="middle" fontSize="10" fontFamily="monospace" fontWeight="bold" fill="#F8FAFC">
                    {activePacket.packetId}
                  </text>
                </g>
              </svg>

              {/* 8 INTERACTIVE NETWORK NODES WITH GLASS-LIKE BADGES */}
              {nodes.map((node) => {
                const isSelected = selectedNodeId === node.id;
                const isPacketHere = activePacket.currentNodeId === node.id;

                return (
                  <div
                    key={node.id}
                    onClick={() => setSelectedNodeId(node.id)}
                    style={{
                      left: `${(node.x / 1100) * 100}%`,
                      top: `${(node.y / 400) * 100}%`,
                    }}
                    className={`absolute -translate-x-1/2 -translate-y-1/2 cursor-pointer z-20 transition-all duration-300 hover:scale-110 ${
                      isSelected ? 'scale-110' : ''
                    }`}
                  >
                    <div
                      className={`relative p-3 rounded-2xl border-2 flex flex-col items-center min-w-[110px] text-center backdrop-blur-md shadow-2xl transition-all ${
                        isPacketHere
                          ? 'border-[#38BDF8] bg-[#0D1729]/95 ring-4 ring-cyan-500/20'
                          : isSelected
                          ? 'border-[#FFB020] bg-[#0D1729]/95'
                          : node.status === 'OFFLINE'
                          ? 'border-rose-950 bg-slate-950/60 opacity-50'
                          : 'border-[#263650] bg-[#070D19]/90'
                      }`}
                    >
                      {/* Node Icon Avatar */}
                      <div
                        className={`w-10 h-10 rounded-xl flex items-center justify-center font-bold mb-1 shadow-inner ${
                          node.id === 'node1'
                            ? 'bg-rose-500/20 text-[#FF365D]'
                            : node.id === 'node3'
                            ? 'bg-amber-500/20 text-[#FFB020]'
                            : node.id === 'node4'
                            ? 'bg-cyan-500/20 text-[#38BDF8]'
                            : node.id === 'node5'
                            ? 'bg-teal-500/20 text-[#00F5A0]'
                            : node.id === 'node7' || node.id === 'node8'
                            ? 'bg-emerald-500/20 text-[#00F5A0]'
                            : 'bg-blue-500/20 text-blue-400'
                        }`}
                      >
                        {node.iconType === 'phone' ? (
                          <Smartphone size={20} />
                        ) : node.iconType === 'phone_relay' ? (
                          <Smartphone size={20} />
                        ) : node.iconType === 'mule' ? (
                          <Share2 size={20} />
                        ) : node.iconType === 'repeater' ? (
                          <Radio size={20} />
                        ) : node.iconType === 'tablet' ? (
                          <Tablet size={20} />
                        ) : node.iconType === 'satellite' ? (
                          <Radio size={20} />
                        ) : node.iconType === 'cloud' ? (
                          <Server size={20} />
                        ) : (
                          <Building size={20} />
                        )}
                      </div>

                      {/* Device Title & Role */}
                      <span className="font-bold text-xs text-white leading-tight truncate max-w-[105px]">
                        {node.name}
                      </span>
                      <span className="font-mono text-[9px] text-[#38BDF8] font-semibold mt-0.5">
                        {node.roleLabel}
                      </span>

                      {/* Battery & Signal Pill */}
                      {showLabels && (
                        <div className="flex items-center gap-1.5 text-[9px] font-mono text-[#94A3B8] mt-1 pt-1 border-t border-[#1E293B] w-full justify-center">
                          <span>🔋{node.batteryPct}%</span>
                          <span>•</span>
                          <span>{node.signalDbm}dBm</span>
                        </div>
                      )}

                      {/* Moving Packet Pulse Indicator */}
                      {isPacketHere && (
                        <span className="absolute -top-1.5 -right-1.5 w-4 h-4 rounded-full bg-[#FFB020] animate-ping" />
                      )}
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Bottom Active Step Narrative Banner */}
            <div className="relative z-20 p-4 rounded-2xl bg-[#0D1729] border border-[#263650] flex flex-col md:flex-row md:items-center justify-between gap-4 shadow-xl">
              <div className="space-y-1">
                <div className="flex items-center gap-2">
                  <span className="px-2 py-0.5 rounded bg-[#FFB020] text-[#050816] font-black text-xs">
                    STAGE {currentStepIndex + 1}
                  </span>
                  <h3 className="text-sm font-bold text-white tracking-wide">
                    {currentStepIndex === 0
                      ? 'Local Emergency Trigger & Device E2EE Envelope Creation'
                      : currentStepIndex === 1
                      ? 'Store-and-Forward Transmission to Mobile Data Mule'
                      : currentStepIndex === 2
                      ? repeaterOffline
                        ? 'Dynamic Self-Healing: Bypassing Failed Repeater directly to Rescue Vehicle'
                        : 'Elevated Solar Ridge Repeater bridges Mountain Valley'
                      : currentStepIndex === 3
                      ? 'Rescue Squad Vehicle Gateway Discovered via Satellite Link'
                      : currentStepIndex === 4
                      ? 'Cloud Ingestion via POST /api/v1/packets & DBSCAN Spatial Triage'
                      : 'Command Center Base Live Dispatch & Real-Time Incident Sync'}
                  </h3>
                </div>
                <p className="text-xs text-[#94A3B8]">
                  {activePacket.payloadPreview}
                </p>
              </div>

              {/* Cryptographic State Capsule */}
              <div className="text-xs bg-[#070D19] p-3 rounded-xl border border-[#1E293B] max-w-md">
                <span className="text-[#38BDF8] font-bold block mb-0.5">Cryptographic Rule:</span>
                <span className="text-slate-300">
                  {currentStepIndex <= 2
                    ? 'Zero-Knowledge Relays: Nodes 2 and 3 inspect only RoutingHeader (TTL/Hops). EncryptedPayload remains sealed with AES-GCM-256.'
                    : currentStepIndex >= 4
                    ? 'Command Center Base verifies Ed25519 digital signature and decrypts survivor GPS fix for emergency dispatch.'
                    : 'Gateway buffers packets into SQLite outbox and flushes via idempotent HTTPS batch payload.'}
                </span>
              </div>
            </div>
          </div>

          {/* SELECTED NODE TELEMETRY INSPECTOR (Slide-Out Details Card) */}
          {selectedNode && (
            <div className="p-4 rounded-2xl bg-[#0D1729] border border-[#263650] shadow-lg flex flex-col md:flex-row md:items-center justify-between gap-4 text-xs">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-cyan-500/10 border border-cyan-500/30 text-[#38BDF8] flex items-center justify-center font-bold">
                  <Cpu size={20} />
                </div>
                <div>
                  <div className="flex items-center gap-2">
                    <span className="font-bold text-sm text-white">{selectedNode.name}</span>
                    <span className="px-2 py-0.2 rounded-full font-mono text-[10px] bg-[#070D19] text-[#38BDF8] border border-[#263650]">
                      {selectedNode.id}
                    </span>
                  </div>
                  <span className="text-[#94A3B8]">{selectedNode.deviceModel} • {selectedNode.sector}</span>
                </div>
              </div>

              <div className="flex flex-wrap items-center gap-4 font-mono text-xs">
                <div>
                  <span className="text-slate-500 block text-[10px]">BATTERY</span>
                  <strong className={selectedNode.batteryPct > 50 ? 'text-[#00F5A0]' : 'text-rose-400'}>
                    {selectedNode.batteryPct}%
                  </strong>
                </div>
                <div>
                  <span className="text-slate-500 block text-[10px]">SIGNAL RSSI</span>
                  <strong className="text-white">{selectedNode.signalDbm} dBm</strong>
                </div>
                <div>
                  <span className="text-slate-500 block text-[10px]">OUTBOX QUEUE</span>
                  <strong className="text-[#FFB020]">{selectedNode.queueSize} items</strong>
                </div>
                <div>
                  <span className="text-slate-500 block text-[10px]">STATUS</span>
                  <strong className={selectedNode.status === 'ONLINE' ? 'text-[#00F5A0]' : 'text-rose-400'}>
                    ● {selectedNode.status}
                  </strong>
                </div>
              </div>
            </div>
          )}
        </div>
      )}

      {/* =========================================================================
          MODULE 2: ARCHITECTURAL REFERENCE PANELS (7, 8 & 9 FROM USER SPEC)
          ========================================================================= */}
      {activeTab === 'infographics' && (
        <div className="space-y-6 animate-in fade-in duration-200">
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">

            {/* PANEL 7: LOCATION ESTIMATION (NO GPS NEEDED) */}
            <div className="p-5 rounded-3xl bg-[#0D1729] border border-[#263650] shadow-xl flex flex-col justify-between space-y-4">
              <div>
                <div className="flex items-center gap-2 mb-2">
                  <span className="w-6 h-6 rounded-lg bg-amber-500/20 text-[#FFB020] font-black text-xs flex items-center justify-center">
                    7
                  </span>
                  <h3 className="text-sm font-bold text-white">Location Estimation (No GPS Needed)</h3>
                </div>
                <p className="text-xs text-[#94A3B8] leading-relaxed">
                  If a user doesn't have a GPS lock (indoors or subterranean), RakshaNet estimates location using nearby phones (Bluetooth ranging + known GPS anchor nodes).
                </p>
              </div>

              {/* Multilateration Visual Schematic */}
              <div className="relative h-64 bg-[#070D19] border border-[#1E293B] rounded-2xl overflow-hidden p-3 flex items-center justify-center">
                {/* Distance range rings */}
                <div className="absolute w-44 h-44 rounded-full border border-dashed border-rose-500/40 animate-ping" />
                <div className="absolute w-32 h-32 rounded-full border border-rose-500/30" />

                {/* Center: Estimated Node */}
                <div className="absolute z-10 flex flex-col items-center">
                  <div className="w-9 h-9 rounded-xl bg-rose-500/20 border-2 border-[#FF365D] text-[#FF365D] flex items-center justify-center font-bold shadow-lg">
                    📱
                  </div>
                  <span className="text-[10px] font-bold text-[#FF365D] mt-1">Estimated Location</span>
                  <span className="text-[9px] font-mono text-slate-400">(&plusmn; 20–50 meters)</span>
                </div>

                {/* Surrounding GPS Anchors */}
                <div className="absolute top-4 left-6 flex flex-col items-center">
                  <div className="w-7 h-7 rounded-lg bg-emerald-500/20 border border-[#00F5A0] text-[#00F5A0] flex items-center justify-center text-xs">
                    📱
                  </div>
                  <span className="text-[9px] text-[#00F5A0] font-mono font-bold mt-0.5">42 m</span>
                </div>

                <div className="absolute top-4 right-6 flex flex-col items-center">
                  <div className="w-7 h-7 rounded-lg bg-blue-500/20 border border-[#38BDF8] text-[#38BDF8] flex items-center justify-center text-xs">
                    📱
                  </div>
                  <span className="text-[9px] text-[#38BDF8] font-mono font-bold mt-0.5">58 m</span>
                </div>

                <div className="absolute bottom-4 left-6 flex flex-col items-center">
                  <div className="w-7 h-7 rounded-lg bg-blue-500/20 border border-[#38BDF8] text-[#38BDF8] flex items-center justify-center text-xs">
                    📱
                  </div>
                  <span className="text-[9px] text-[#38BDF8] font-mono font-bold mt-0.5">66 m</span>
                </div>

                <div className="absolute bottom-4 right-6 flex flex-col items-center">
                  <div className="w-7 h-7 rounded-lg bg-emerald-500/20 border border-[#00F5A0] text-[#00F5A0] flex items-center justify-center text-xs">
                    📱
                  </div>
                  <span className="text-[9px] text-[#00F5A0] font-mono font-bold mt-0.5">50 m</span>
                </div>
              </div>

              {/* Legend & Calibration Caveats */}
              <div className="space-y-1.5 text-[11px] pt-1 border-t border-[#1E293B]">
                <div className="flex items-center justify-between text-slate-400">
                  <span className="flex items-center gap-1.5">
                    <span className="w-2 h-2 rounded-full bg-[#00F5A0]" /> Phone with GPS Lock
                  </span>
                  <span className="flex items-center gap-1.5">
                    <span className="w-2 h-2 rounded-full bg-[#38BDF8]" /> Phone without GPS
                  </span>
                </div>
                <p className="text-[10px] text-slate-500 leading-tight">
                  * Note: BLE RSSI is noisy. Ranging estimates apply log-distance path loss calibration with rolling median filters.
                </p>
              </div>
            </div>

            {/* PANEL 8: WHEN NETWORK IS AVAILABLE (AUTO-SYNC PIPELINE) */}
            <div className="p-5 rounded-3xl bg-[#0D1729] border border-[#263650] shadow-xl flex flex-col justify-between space-y-4">
              <div>
                <div className="flex items-center gap-2 mb-2">
                  <span className="w-6 h-6 rounded-lg bg-amber-500/20 text-[#FFB020] font-black text-xs flex items-center justify-center">
                    8
                  </span>
                  <h3 className="text-sm font-bold text-white">When Network is Available</h3>
                </div>
                <p className="text-xs text-[#94A3B8] leading-relaxed">
                  Any single phone or rescue vehicle that reaches mobile data, satellite WAN, or base Wi-Fi uploads all collected mesh telemetry to the Command Center.
                </p>
              </div>

              {/* Sync Pipeline Flow */}
              <div className="p-4 bg-[#070D19] border border-[#1E293B] rounded-2xl space-y-3">
                <div className="flex items-center justify-between text-xs">
                  <div className="flex flex-col items-center">
                    <span className="w-8 h-8 rounded-lg bg-cyan-500/20 border border-cyan-400 text-[#38BDF8] flex items-center justify-center font-bold">
                      🕸️
                    </span>
                    <span className="text-[10px] font-bold text-white mt-1">Mesh Cluster</span>
                    <span className="text-[9px] text-slate-500">Offline P2P</span>
                  </div>

                  <ArrowRight size={14} className="text-[#FFB020] animate-pulse" />

                  <div className="flex flex-col items-center">
                    <span className="w-8 h-8 rounded-lg bg-emerald-500/20 border border-[#00F5A0] text-[#00F5A0] flex items-center justify-center font-bold">
                      📶
                    </span>
                    <span className="text-[10px] font-bold text-white mt-1">Gateway Phone</span>
                    <span className="text-[9px] text-[#00F5A0]">4G / 5G / Wi-Fi</span>
                  </div>

                  <ArrowRight size={14} className="text-[#00F5A0] animate-pulse" />

                  <div className="flex flex-col items-center">
                    <span className="w-8 h-8 rounded-lg bg-purple-500/20 border border-purple-400 text-purple-400 flex items-center justify-center font-bold">
                      ☁️
                    </span>
                    <span className="text-[10px] font-bold text-white mt-1">Cloud Server</span>
                    <span className="text-[9px] text-purple-300">FastAPI API</span>
                  </div>
                </div>

                <div className="pt-2 border-t border-[#1E293B] grid grid-cols-2 gap-2 text-[10px] text-slate-300">
                  <div>• SOS Distress Alerts</div>
                  <div>• Water Test Results</div>
                  <div>• Mesh Chat Messages</div>
                  <div>• Photos &amp; Video Chunks</div>
                  <div>• GPS Location Logs</div>
                  <div>• Missing Person Sightings</div>
                </div>
              </div>

              {/* Pipeline Status Checklist */}
              <div className="text-xs space-y-1">
                <div className="flex items-center justify-between text-slate-400">
                  <span>Pipeline State:</span>
                  <span className="font-bold text-[#00F5A0]">AUTHENTICATED &amp; UPLOADING</span>
                </div>
                <div className="flex items-center justify-between text-slate-400">
                  <span>Batch Throughput:</span>
                  <span className="font-mono text-white">4 packets (16.8 KB)</span>
                </div>
              </div>
            </div>

            {/* PANEL 9: COMMAND CENTER DASHBOARD */}
            <div className="p-5 rounded-3xl bg-[#0D1729] border border-[#263650] shadow-xl flex flex-col justify-between space-y-4">
              <div>
                <div className="flex items-center gap-2 mb-2">
                  <span className="w-6 h-6 rounded-lg bg-amber-500/20 text-[#FFB020] font-black text-xs flex items-center justify-center">
                    9
                  </span>
                  <h3 className="text-sm font-bold text-white">Command Center Dashboard</h3>
                </div>
                <p className="text-xs text-[#94A3B8] leading-relaxed">
                  Government &amp; Rescue teams see all real-time data, citizen locations, SOS distress alerts, and resource allocation telemetry.
                </p>
              </div>

              {/* Live Metric Counters Preview matching Reference */}
              <div className="grid grid-cols-2 gap-2 text-xs">
                <div className="p-3 rounded-xl bg-[#070D19] border border-[#1E293B]">
                  <span className="text-[10px] text-slate-400 uppercase font-semibold">Active Users</span>
                  <span className="text-xl font-black text-white block mt-0.5" style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}>
                    1,253
                  </span>
                </div>

                <div className="p-3 rounded-xl bg-[#070D19] border border-rose-500/30">
                  <span className="text-[10px] text-rose-400 uppercase font-semibold">SOS Alerts</span>
                  <span className="text-xl font-black text-[#FF365D] block mt-0.5" style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}>
                    37
                  </span>
                </div>

                <div className="p-3 rounded-xl bg-[#070D19] border border-emerald-500/30">
                  <span className="text-[10px] text-emerald-400 uppercase font-semibold">People Located</span>
                  <span className="text-xl font-black text-[#00F5A0] block mt-0.5" style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}>
                    892
                  </span>
                </div>

                <div className="p-3 rounded-xl bg-[#070D19] border border-amber-500/30">
                  <span className="text-[10px] text-amber-400 uppercase font-semibold">Pending Sync</span>
                  <span className="text-xl font-black text-[#FFB020] block mt-0.5" style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}>
                    214
                  </span>
                </div>
              </div>

              {/* Sub-Tabs Selector matching reference UI */}
              <div className="flex items-center justify-between gap-1 p-1 rounded-xl bg-[#070D19] border border-[#1E293B] text-[10px] font-bold text-center">
                <span className="flex-1 py-1 px-2 rounded-lg bg-[#38BDF8] text-[#050816]">Live Map</span>
                <span className="flex-1 py-1 px-2 text-[#94A3B8]">People</span>
                <span className="flex-1 py-1 px-2 text-[#94A3B8]">Alerts</span>
                <span className="flex-1 py-1 px-2 text-[#94A3B8]">Resources</span>
              </div>
            </div>

          </div>
        </div>
      )}

      {/* =========================================================================
          MODULE 3: STORE-AND-FORWARD QUEUES & PHOTO CHUNKING
          ========================================================================= */}
      {activeTab === 'queue' && (
        <div className="space-y-4 animate-in fade-in duration-200">
          <Card className="p-6 bg-[#0D1729] border border-[#263650]">
            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 mb-4">
              <div>
                <h3 className="text-base font-bold text-white flex items-center gap-2">
                  <Database size={18} className="text-[#38BDF8]" />
                  <span>SQLite Store-and-Forward Outbox Queues</span>
                </h3>
                <p className="text-xs text-[#94A3B8]">
                  Messages persist across device reboots and are forwarded opportunistically when eligible radio links open.
                </p>
              </div>

              <span className="px-3 py-1 rounded-full text-xs font-mono font-bold bg-[#070D19] text-[#00F5A0] border border-emerald-500/30">
                Outbox Capacity: 42.8 MB / 500 MB
              </span>
            </div>

            {/* Queue Table */}
            <div className="overflow-x-auto rounded-xl border border-[#1E293B]">
              <table className="w-full text-left text-xs text-slate-300">
                <thead className="bg-[#070D19] text-[#94A3B8] font-semibold border-b border-[#1E293B] uppercase text-[10px]">
                  <tr>
                    <th className="p-3">Item ID</th>
                    <th className="p-3">Category</th>
                    <th className="p-3">Title / Payload Summary</th>
                    <th className="p-3">Size</th>
                    <th className="p-3">Status</th>
                    <th className="p-3">Retries</th>
                    <th className="p-3 text-right">Queued At</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#1E293B]">
                  {queuedItems.map((item) => (
                    <tr key={item.id} className="hover:bg-[#162036]/50 transition-colors">
                      <td className="p-3 font-mono font-bold text-[#FFB020]">{item.id}</td>
                      <td className="p-3">
                        <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                          item.category === 'SOS' ? 'bg-rose-500/20 text-[#FF365D]' :
                          item.category === 'PHOTO' ? 'bg-amber-500/20 text-[#FFB020]' :
                          item.category === 'GROUP' ? 'bg-blue-500/20 text-[#38BDF8]' :
                          'bg-emerald-500/20 text-[#00F5A0]'
                        }`}>
                          {item.category}
                        </span>
                      </td>
                      <td className="p-3 font-medium text-white">
                        {item.title}
                        {item.totalChunks && (
                          <div className="w-40 h-1.5 rounded-full bg-slate-800 mt-1 overflow-hidden">
                            <div className="h-full bg-amber-400" style={{ width: `${((item.chunksReceived || 0) / item.totalChunks) * 100}%` }} />
                          </div>
                        )}
                      </td>
                      <td className="p-3 font-mono">{item.sizeBytes} B</td>
                      <td className="p-3">
                        <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold ${
                          item.status === 'SYNCED' ? 'bg-emerald-500/20 text-[#00F5A0]' :
                          item.status === 'TRANSMITTING' ? 'bg-amber-500/20 text-[#FFB020]' :
                          'bg-slate-800 text-slate-400'
                        }`}>
                          ● {item.status}
                        </span>
                      </td>
                      <td className="p-3 font-mono text-center">{item.retryCount}</td>
                      <td className="p-3 text-right font-mono text-slate-500">{item.timestamp}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </Card>
        </div>
      )}

      {/* =========================================================================
          MODULE 4: DIAGNOSTIC LOGS & PROTOCOL EVENTS TIMELINE
          ========================================================================= */}
      {activeTab === 'diagnostics' && (
        <div className="space-y-4 animate-in fade-in duration-200">
          <Card className="p-6 bg-[#0D1729] border border-[#263650] space-y-4">
            <div className="flex items-center justify-between pb-2 border-b border-[#1E293B]">
              <div>
                <h3 className="text-base font-bold text-white flex items-center gap-2">
                  <Binary size={18} className="text-[#38BDF8]" />
                  <span>Real-Time Diagnostic Hop Engine Stream</span>
                </h3>
                <p className="text-xs text-[#94A3B8]">
                  Timestamped cryptographic, routing, and physical radio events generated by the simulation.
                </p>
              </div>

              <span className="text-xs font-mono text-slate-400">
                Log Buffer: {diagnosticLogs.length} events
              </span>
            </div>

            <div className="space-y-2.5 max-h-[480px] overflow-y-auto pr-1 scrollbar-tactical">
              {diagnosticLogs.map((log) => (
                <div
                  key={log.id}
                  onClick={() => setSelectedLogId(log.id)}
                  className={`p-3.5 rounded-xl border text-xs transition-all cursor-pointer ${
                    selectedLogId === log.id
                      ? 'border-[#38BDF8] bg-[#162036]'
                      : 'border-[#1E293B] bg-[#070D19] hover:border-slate-600'
                  }`}
                >
                  <div className="flex items-center justify-between mb-1">
                    <div className="flex items-center gap-2">
                      <span className="font-mono text-slate-500 text-[11px]">{log.timestamp}</span>
                      <span className={`px-2 py-0.2 rounded font-mono font-bold text-[10px] ${
                        log.severity === 'CRITICAL' ? 'bg-rose-500/20 text-[#FF365D] border border-rose-500/40' :
                        log.severity === 'SUCCESS' ? 'bg-emerald-500/20 text-[#00F5A0] border border-emerald-500/40' :
                        log.severity === 'WARN' ? 'bg-amber-500/20 text-[#FFB020] border border-amber-500/40' :
                        'bg-blue-500/20 text-[#38BDF8]'
                      }`}>
                        {log.eventType}
                      </span>
                    </div>

                    <span className="font-mono text-[10px] text-slate-400">
                      {log.sourceNode} → {log.targetNode}
                    </span>
                  </div>

                  <p className="text-slate-200 font-medium">{log.message}</p>
                  <p className="text-[11px] text-slate-400 mt-0.5 font-mono">{log.details}</p>
                </div>
              ))}
            </div>
          </Card>
        </div>
      )}

    </div>
  );
};

export default MeshArchitecturePage;
