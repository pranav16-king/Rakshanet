// src/api/settings.ts
import apiClient from './client';
import type { SystemSettings, HealthCheckResponse, TelemetryStatsResponse } from '../types';

const SETTINGS_STORAGE_KEY = 'rakshanet_system_settings';

export const settingsApi = {
  getSettings: async (): Promise<SystemSettings> => {
    try {
      const response = await apiClient.get<SystemSettings>('/api/v1/settings');
      if (response.data && typeof response.data === 'object') {
        const backendData = response.data;
        const merged: SystemSettings = {
          ...getDefaultSettings(),
          ...backendData,
          // Normalize legacy / alias keys
          enableOfflineMeshNetwork:
            backendData.enableOfflineMeshNetwork ??
            backendData.mesh_network?.mesh_relay_enabled ??
            true,
          autoSyncWhenOnline:
            backendData.autoSyncWhenOnline ??
            backendData.data_retention?.sync_to_cloud ??
            true,
          enableOfflineAiGuidance:
            backendData.enableOfflineAiGuidance ??
            backendData.ai_clustering?.auto_clustering_enabled ??
            true,
          dataRetentionDays:
            backendData.dataRetentionDays ??
            backendData.data_retention?.telemetry_retention_days ??
            30,
          allowAnonymousUsage:
            backendData.allowAnonymousUsage ??
            backendData.data_retention?.anonymize_civilians ??
            true,
        };
        try {
          localStorage.setItem(SETTINGS_STORAGE_KEY, JSON.stringify(merged));
        } catch {
          // ignore storage error
        }
        return merged;
      }
    } catch (err) {
      console.warn('[settingsApi] Backend settings endpoint unavailable, using cached/defaults:', err);
    }

    try {
      const stored = localStorage.getItem(SETTINGS_STORAGE_KEY);
      if (stored) {
        return { ...getDefaultSettings(), ...JSON.parse(stored) };
      }
    } catch {
      // Ignore parse error
    }
    return getDefaultSettings();
  },

  saveSettings: async (settings: SystemSettings): Promise<SystemSettings> => {
    try {
      localStorage.setItem(SETTINGS_STORAGE_KEY, JSON.stringify(settings));
    } catch {
      // ignore
    }

    // Persist real data to FastAPI backend endpoint
    try {
      const response = await apiClient.post<SystemSettings>('/api/v1/settings', settings);
      if (response.data) {
        return { ...settings, ...response.data };
      }
    } catch (err) {
      console.warn('[settingsApi] Error saving settings to backend:', err);
    }
    return settings;
  },

  checkBackendHealth: async (): Promise<{
    apiHealthy: boolean;
    apiLatencyMs: number;
    wsHealthy: boolean;
    details: HealthCheckResponse | null;
  }> => {
    const start = performance.now();
    try {
      const response = await apiClient.get<HealthCheckResponse>('/api/v1/health');
      const latency = Math.round(performance.now() - start);
      return {
        apiHealthy: response.data?.status === 'HEALTHY' || response.status === 200,
        apiLatencyMs: latency,
        wsHealthy: true,
        details: response.data,
      };
    } catch {
      return {
        apiHealthy: false,
        apiLatencyMs: -1,
        wsHealthy: false,
        details: null,
      };
    }
  },

  getTelemetryStats: async (): Promise<TelemetryStatsResponse | null> => {
    try {
      const response = await apiClient.get<TelemetryStatsResponse>('/api/v1/telemetry/stats');
      return response.data;
    } catch {
      return null;
    }
  },

  getRegisteredUsers: async (): Promise<any[]> => {
    try {
      const response = await apiClient.get('/api/v1/users');
      if (Array.isArray(response.data?.users)) {
        return response.data.users;
      }
      if (Array.isArray(response.data)) {
        return response.data;
      }
      return [];
    } catch (err) {
      console.warn('[settingsApi] Failed to load registered users:', err);
      return [];
    }
  },
};

export function getDefaultSettings(): SystemSettings {
  return {
    allowNewUserRegistration: true,
    enableOfflineMeshNetwork: true,
    saveMessagesLocally: true,
    storeMessagesLocally: true,
    autoSyncWhenOnline: true,
    enableOfflineAiGuidance: true,
    useLocalKnowledgeBase: true,
    dataRetentionDays: 30,
    allowAnonymousUsage: true,
    theme: 'dark',
    apiBaseUrl: import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000',
    wsEndpoint: 'ws://localhost:8000/ws/mesh',
    mesh_network: {
      mesh_relay_enabled: true,
      max_hops: 7,
      dtn_storage_limit_mb: 500,
      satellite_fallback: true,
    },
    ai_clustering: {
      auto_clustering_enabled: true,
      eps_meters: 130.0,
      min_samples: 2,
      confidence_threshold: 0.88,
    },
    anomalies: {
      black_hole_detection: true,
      critical_drop_pct: 75.0,
      warning_drop_pct: 45.0,
    },
    emergency_broadcast: {
      cap_auto_broadcast: true,
      sachet_ndma_integration: true,
    },
    data_retention: {
      telemetry_retention_days: 30,
      sync_to_cloud: true,
      anonymize_civilians: true,
    },
    notifications: {
      criticalSosAudio: true,
      visualBeaconPulse: true,
      blackHoleSound: true,
      pushRelayHandoff: false,
    },
    access_control: {
      requireMfaForCommanders: false,
      sessionTimeoutHours: 24,
      permitAnonymousSos: true,
    },
  };
}
