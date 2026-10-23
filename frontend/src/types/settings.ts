export type ThemeMode = 'dark' | 'light' | 'oled';

export interface MeshNetworkSettings {
  mesh_relay_enabled?: boolean;
  max_hops?: number;
  dtn_storage_limit_mb?: number;
  satellite_fallback?: boolean;
}

export interface AiClusteringSettings {
  auto_clustering_enabled?: boolean;
  eps_meters?: number;
  min_samples?: number;
  confidence_threshold?: number;
}

export interface AnomaliesSettings {
  black_hole_detection?: boolean;
  critical_drop_pct?: number;
  warning_drop_pct?: number;
}

export interface EmergencyBroadcastSettings {
  cap_auto_broadcast?: boolean;
  sachet_ndma_integration?: boolean;
}

export interface DataRetentionSettings {
  telemetry_retention_days?: number;
  sync_to_cloud?: boolean;
  anonymize_civilians?: boolean;
}

export interface NotificationSettings {
  criticalSosAudio?: boolean;
  visualBeaconPulse?: boolean;
  blackHoleSound?: boolean;
  pushRelayHandoff?: boolean;
}

export interface AccessControlSettings {
  requireMfaForCommanders?: boolean;
  sessionTimeoutHours?: number;
  permitAnonymousSos?: boolean;
}

export interface SystemSettings {
  allowNewUserRegistration: boolean;
  enableOfflineMeshNetwork: boolean;
  storeMessagesLocally?: boolean;
  saveMessagesLocally?: boolean;
  autoSyncWhenOnline: boolean;
  enableOfflineAiGuidance?: boolean;
  useLocalKnowledgeBase?: boolean;
  dataRetentionDays?: number;
  allowAnonymousUsage?: boolean;
  theme?: ThemeMode;
  apiBaseUrl?: string;
  wsBaseUrl?: string;
  wsEndpoint?: string;

  // Real backend nested configurations
  mesh_network?: MeshNetworkSettings;
  ai_clustering?: AiClusteringSettings;
  anomalies?: AnomaliesSettings;
  emergency_broadcast?: EmergencyBroadcastSettings;
  data_retention?: DataRetentionSettings;
  notifications?: NotificationSettings;
  access_control?: AccessControlSettings;
}

export interface HealthCheckResponse {
  status: string;
  timestamp: number;
  gateway: string;
  mongo_atlas?: string;
}

export interface TelemetryStatsResponse {
  unique_packets_stored: number;
  sos_beacons_count: number;
  active_mules: number;
  connected_dashboard_clients: number;
}

export interface AiAssistantSettings {
  enableOfflineAiGuidance: boolean;
  useLocalKnowledgeBase: boolean;
  confidenceThresholdPct: number;
}

export interface DataPrivacySettings {
  dataRetentionDays: number;
  allowAnonymousUsage: boolean;
  exportCapAlertsEnabled: boolean;
}

export interface AppSettings {
  theme: ThemeMode;
  system: SystemSettings;
  ai: AiAssistantSettings;
  privacy: DataPrivacySettings;
}
