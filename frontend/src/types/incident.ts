// types/incident.ts
// Comprehensive Incident & Response types for RakshaNet Command Center

export type IncidentSeverity = 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW' | 'UNKNOWN' | string;
export type SeverityLevel = 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW' | 'UNKNOWN';

export type IncidentStatus =
  | 'ACTIVE'
  | 'ASSIGNED'
  | 'IN_PROGRESS'
  | 'CONTAINED'
  | 'RESOLVED'
  | 'Active'
  | 'Investigating'
  | 'Dispatched'
  | 'Resolved'
  | string;

export type IncidentType =
  | 'FLOOD'
  | 'LANDSLIDE'
  | 'EARTHQUAKE'
  | 'CYCLONE'
  | 'FIRE'
  | 'BUILDING_COLLAPSE'
  | 'MEDICAL_EMERGENCY'
  | 'OTHER'
  | 'Flood'
  | 'Landslide'
  | 'Cyclone'
  | 'Flash Flood'
  | 'Building Collapse'
  | 'Earthquake'
  | string;

export type DisasterType =
  | 'Flood'
  | 'Landslide'
  | 'Earthquake'
  | 'Building Collapse'
  | 'Cyclone'
  | 'Fire'
  | 'Medical Emergency'
  | 'Flash Flood'
  | 'Other';

export interface IncidentLocationDetails {
  lat?: number;
  lng?: number;
  address?: string;
  region?: string;
  radiusMeters?: number;
  [key: string]: any;
}

export type IncidentLocation = string | IncidentLocationDetails;

export interface AIFactor {
  name: string;
  factorKey: string;
  weightPct: number;
  valueDisplay: string;
  status: 'critical' | 'warning' | 'normal' | 'info';
  details: string;
}

export interface AIExplainability {
  priorityScore: number;
  confidencePct: number;
  confidenceGrade: 'VERY_HIGH' | 'HIGH' | 'MODERATE' | 'LOW' | string;
  modelVersion: string;
  factors: {
    lastContactTime: AIFactor;
    incidentSeverity: AIFactor;
    affectedPopulation: AIFactor;
    hazardBoundaryProximity: AIFactor;
    communicationStatus: AIFactor;
    [key: string]: AIFactor;
  };
  synthesis: string;
  disclaimer: string;
}

export interface ResourceNeed {
  id: string;
  title: string;
  quantityDisplay: string;
  priority: 'Critical' | 'High' | 'Medium' | 'Required';
  iconType: 'boat' | 'medical' | 'food' | 'shelter' | 'helicopter' | 'personnel';
  allocatedCount?: number;
  statusText?: string;
}

export interface Incident {
  id: string;
  incident_id?: string;
  title: string;
  type: IncidentType | DisasterType;
  severity: SeverityLevel | string;
  status: IncidentStatus;
  location: IncidentLocation;
  coordinates: {
    lat: number;
    lng: number;
  };
  affectedAreaKm2: number;
  clusterRadiusMeters: number;
  polygonCoords?: [number, number][];
  affectedPeople: number;
  devicesCount: number;
  reportedBy: string;
  firstReported: string;
  firstReportedTimestamp: number;
  lastUpdate: string;
  lastUpdateTimestamp: number;
  assignedTeam?: string | null;
  assignedUnitId?: string | null;
  description: string;
  resourcesNeeded: ResourceNeed[];
  aiExplainability: AIExplainability;
  subReportsCount: number;
  [key: string]: any;
}

export interface IncidentFilterOptions {
  searchQuery: string;
  severity: 'ALL' | SeverityLevel;
  type: 'ALL' | DisasterType;
  status: 'ALL' | IncidentStatus;
  sortBy: 'severity' | 'lastUpdate' | 'affectedPeople' | 'firstReported';
  sortOrder: 'asc' | 'desc';
  page: number;
  pageSize: number;
  [key: string]: any;
}

export interface PaginatedIncidentsResponse {
  data: Incident[];
  totalCount: number;
  currentPage: number;
  pageSize: number;
  totalPages: number;
}

export interface RescueUnit {
  unit_id: string;
  name: string;
  unit_type: 'BOAT' | 'HIGH_CLEARANCE_4WD' | 'AMBULANCE' | 'HELICOPTER' | 'K9_SEARCH' | 'DRONE_RECON' | string;
  agency?: 'NDRF' | 'SDRF' | 'ARMY' | '108_EMS' | 'CIVIL_DEFENSE' | string;
  lat: number;
  lng: number;
  capacity: number;
  status: 'AVAILABLE' | 'DISPATCHED' | 'ON_SCENE' | 'MAINTENANCE' | string;
  speed_kmh: number;
  eta_minutes?: number;
  distance_km?: number;
  capabilities: string[];
  contact_frequency?: string;
  base_location?: string;
  fuel_percent?: number;
  crew_count?: number;
  [key: string]: any;
}

export interface IncidentPerson {
  id: string;
  name: string;
  role: 'Civic Survivor' | 'Elderly' | 'Infant' | 'Injured' | 'Responder' | string;
  status: 'Critical Triage' | 'Trapped' | 'Safe Haven' | 'Evacuated' | 'Unknown' | string;
  familyMembersCount: number;
  lastContact: string;
  devicePseudonym: string;
  medicalNotes?: string;
  location: string;
}

export interface IncidentMessage {
  id: string;
  senderName: string;
  senderPseudonym: string;
  hops: number;
  timestamp: string;
  text: string;
  type: 'SOS' | 'REPORT' | 'MEDICAL' | 'RELAY' | 'SYSTEM' | string;
  severity: SeverityLevel | string;
  delivered: boolean;
}

export interface IncidentDevice {
  deviceId: string;
  ownerName: string;
  deviceType: 'Phone' | 'Relay Node' | 'Solar Repeater' | string;
  batteryPct: number;
  hops: number;
  lastSeen: string;
  status: 'Online' | 'Relay' | 'Silent' | 'Low Power' | string;
  rssi: number;
}

export interface IncidentTimelineEvent {
  id: string;
  timestamp: string;
  title: string;
  description: string;
  category: 'DISTRESS' | 'AI_TRIAGE' | 'DISPATCH' | 'OPERATIONAL' | 'RELAY' | string;
  actor: string;
  severity?: SeverityLevel;
}

export interface BlackHoleAnomaly {
  anomaly_id: string;
  sector_id: string;
  center_lat: number;
  center_lng: number;
  radius_meters: number;
  bounds: {
    min_lat: number;
    max_lat: number;
    min_lng: number;
    max_lng: number;
  };
  baseline_nodes: number;
  current_nodes: number;
  drop_percentage: number;
  decay_rate_per_hour: number;
  estimated_silenced_people: number;
  severity: 'CRITICAL' | 'WARNING' | 'NORMAL' | string;
  recommended_action: string;
  silence_duration_minutes: number;
  detected_at: number;
  affected_incidents: string[];
  last_signal_seen: string;
  time_series: { timestamp: number; active_nodes: number }[];
}

export interface UnitAssignment {
  unit_id: string;
  unit_name: string;
  unit_type: string;
  incident_id: string;
  incident_category: string;
  incident_urgency: string;
  incident_lat: number;
  incident_lng: number;
  transit_distance_km: number;
  eta_minutes: number;
  casualties_addressed: number;
  match_reason: string;
}

export interface DispatchPlan {
  plan_id: string;
  generated_at: number;
  total_units_evaluated: number;
  total_incidents_evaluated: number;
  assigned_count: number;
  unassigned_incident_ids: string[];
  total_casualties_addressed: number;
  cumulative_transit_distance_km: number;
  solver_status: string;
  assignments: UnitAssignment[];
}

export interface IncidentSosAlert {
  id: string;
  incident_id: string;
  type: 'SOS';
  priority: 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW';
  sender_id: string;
  sender_name: string;
  imei?: string | null;
  payload: string;
  timestamp: number;
  timestamp_display: string;
  lat: number;
  lng: number;
  battery_pct: number;
  siren_active: boolean;
  casualties: number;
  hops: number;
  relay_path: { node: string; rssi: string; hop: number; battery: string }[];
}

export interface MeshRelayHopNode {
  hop_number: number;
  device_id: string;
  role: string;
  signal_dbm: number;
  delay_ms: number;
  battery: number;
}

export interface RelayTopologyRoute {
  route_id: string;
  origin_device: string;
  target_incident: string;
  total_hops: number;
  estimated_latency_ms: number;
  status: 'DELIVERED' | 'IN_TRANSIT' | 'DROPPED';
  hops: MeshRelayHopNode[];
}

export interface IncidentFieldSitrep {
  id: string;
  type: 'SITREP';
  reporter: string;
  category: string;
  location: string;
  lat: number;
  lng: number;
  notes: string;
  timestamp: number;
  timestamp_display: string;
  actionable: string;
}

export interface IncidentTeamComm {
  id: string;
  sender: string;
  recipient: string;
  type: string;
  message: string;
  timestamp: number;
  timestamp_display: string;
  status: string;
}

export interface IncidentVoiceTranscription {
  id: string;
  speaker: string;
  duration_seconds: number;
  transcription: string;
  nlp_extracted_entities: string[];
  urgency_score: number;
  timestamp: number;
}

export interface IncidentCategorizedCommunication {
  id: string;
  category: 'SOS' | 'SITREP' | 'RESCUE_COMMS' | 'VOICE_TRANSCRIPTION' | string;
  title: string;
  content: string;
  sender: string;
  sender_name?: string;
  sender_id: string;
  imei?: string | null;
  timestamp: number;
  timestamp_display: string;
  priority: 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW' | string;
  hops: number;
  lat?: number;
  lng?: number;
  meta?: Record<string, any>;
}

export interface IncidentCommunicationsResponse {
  incident_id: string;
  title: string;
  summary: {
    total: number;
    sos_count: number;
    sitreps_count: number;
    team_comms_count: number;
    voice_count: number;
    active_devices: number;
  };
  sos_alerts: IncidentSosAlert[];
  relay_topology: RelayTopologyRoute[];
  field_sitreps: IncidentFieldSitrep[];
  team_comms: IncidentTeamComm[];
  voice_transcriptions: IncidentVoiceTranscription[];
  all_communications: IncidentCategorizedCommunication[];
}

export interface IncidentBeaconPoint {
  beacon_id: string;
  device_id: string;
  name: string;
  lat: number;
  lng: number;
  status: string;
  casualties: number;
  battery: number;
  last_ping_seconds_ago: number;
}

export interface IncidentMeshRelayNode {
  relay_id: string;
  name: string;
  lat: number;
  lng: number;
  hops_to_gateway: number;
  status: string;
  battery: number;
  packets_forwarded: number;
}

export interface IncidentRescueUnitLocation {
  unit_id: string;
  name: string;
  type: string;
  lat: number;
  lng: number;
  status: string;
  eta_minutes?: number | null;
}

export interface IncidentMeshTopologyResponse {
  incident_id: string;
  title: string;
  centroid: { lat: number; lng: number };
  radius_meters: number;
  affected_area: string;
  sos_beacons: IncidentBeaconPoint[];
  mesh_relays: IncidentMeshRelayNode[];
  rescue_units: IncidentRescueUnitLocation[];
}

