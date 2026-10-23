// src/api/rescueOps.ts
import apiClient from './client';
import type { RescueUnit, DispatchPlan } from '../types';

export const rescueOpsApi = {
  getFleet: async (): Promise<RescueUnit[]> => {
    try {
      const response = await apiClient.get<RescueUnit[]>('/api/v1/dispatch/units');
      return response.data ?? [];
    } catch (err) {
      console.warn('Fleet data unavailable:', err);
      return [];
    }
  },

  optimizeDispatch: async (customUnits?: RescueUnit[]): Promise<DispatchPlan> => {
    const response = await apiClient.post<DispatchPlan>(
      '/api/v1/dispatch/optimize',
      customUnits || null
    );
    return response.data;
  },
};
