// src/api/communicationGaps.ts
import apiClient from './client';
import type { BlackHoleAnomaly } from '../types';

export const communicationGapsApi = {
  getAnomalies: async (): Promise<BlackHoleAnomaly[]> => {
    try {
      const response = await apiClient.get<BlackHoleAnomaly[]>('/api/v1/anomalies/black-holes');
      return response.data ?? [];
    } catch (err) {
      console.warn('Backend black-hole query unavailable:', err);
      return [];
    }
  },

  triggerScan: async (): Promise<{
    status: string;
    anomaly_count: number;
    critical_count: number;
    warning_count: number;
    anomalies: BlackHoleAnomaly[];
  }> => {
    const response = await apiClient.post('/api/v1/anomalies/black-holes/scan');
    return response.data;
  },
};
