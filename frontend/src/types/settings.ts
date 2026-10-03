export type ThemeMode = 'dark' | 'light' | 'oled';

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
}

export interface HealthCheckResponse {
  status: string;
  timestamp: number;
  gateway: string;
  mongo_atlas?: string;
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
