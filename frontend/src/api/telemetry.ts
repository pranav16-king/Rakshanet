import apiClient from './client';
import type { Packet } from '../types';

export interface TelemetryStatsResponse {
  total_packets_received: number;
  unique_packets_stored: number;
  duplicates_dropped: number;
  active_mules: number;
  sos_beacons_count: number;
  active_incidents: number;
  connected_dashboard_clients?: number;
}

export const telemetryApi = {
  getPackets: async (limit: number = 100, packetType?: string): Promise<{ count: number; packets: Packet[] }> => {
    const response = await apiClient.get('/api/v1/telemetry/packets', {
      params: { limit, packet_type: packetType },
    });
    return response.data;
  },

  getStats: async (): Promise<TelemetryStatsResponse> => {
    const response = await apiClient.get<TelemetryStatsResponse>('/api/v1/telemetry/stats');
    return response.data;
  },
};
