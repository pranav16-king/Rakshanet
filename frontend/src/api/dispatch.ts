import apiClient from './client';
import type { Team } from '../types';

export const dispatchApi = {
  getRescueUnits: async (): Promise<Team[]> => {
    const response = await apiClient.get<Team[]>('/api/v1/dispatch/units');
    return response.data;
  },

  optimizeDispatch: async () => {
    const response = await apiClient.post('/api/v1/dispatch/optimize');
    return response.data;
  },
};
