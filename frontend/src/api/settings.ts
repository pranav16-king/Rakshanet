// src/api/settings.ts
import apiClient from './client';
import type { SystemSettings, HealthCheckResponse } from '../types';

const SETTINGS_STORAGE_KEY = 'rakshanet_system_settings';

export const settingsApi = {
  getSettings: (): SystemSettings => {
    try {
      const stored = localStorage.getItem(SETTINGS_STORAGE_KEY);
      if (stored) {
        return JSON.parse(stored);
      }
    } catch {
      // Ignore parse error
    }
    return getDefaultSettings();
  },

  saveSettings: async (settings: SystemSettings): Promise<SystemSettings> => {
    try {
      localStorage.setItem(SETTINGS_STORAGE_KEY, JSON.stringify(settings));
      await apiClient.post('/api/v1/settings', settings).catch(() => {});
    } catch {
      // LocalStorage updated
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
};

function getDefaultSettings(): SystemSettings {
  return {
    allowNewUserRegistration: true,
    enableOfflineMeshNetwork: true,
    saveMessagesLocally: true,
    autoSyncWhenOnline: true,
    enableOfflineAiGuidance: true,
    useLocalKnowledgeBase: true,
    dataRetentionDays: 90,
    allowAnonymousUsage: true,
    theme: 'dark',
    apiBaseUrl: import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000',
    wsEndpoint: 'ws://localhost:8000/ws/mesh',
  };
}
