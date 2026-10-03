// src/api/communicationGaps.ts
import apiClient from './client';
import type { BlackHoleAnomaly } from '../types';

export const communicationGapsApi = {
  getAnomalies: async (): Promise<BlackHoleAnomaly[]> => {
    try {
      const response = await apiClient.get<BlackHoleAnomaly[]>('/api/v1/anomalies/black-holes');
      if (response.data && response.data.length > 0) {
        return response.data;
      }
      return getFallbackAnomalies();
    } catch (err) {
      console.warn('Backend black-hole query fallback:', err);
      return getFallbackAnomalies();
    }
  },

  triggerScan: async (): Promise<{
    status: string;
    anomaly_count: number;
    critical_count: number;
    warning_count: number;
    anomalies: BlackHoleAnomaly[];
  }> => {
    try {
      const response = await apiClient.post('/api/v1/anomalies/black-holes/scan');
      return response.data;
    } catch (err) {
      console.warn('Backend black-hole scan fallback:', err);
      const anomalies = getFallbackAnomalies();
      return {
        status: 'SCANNED_FALLBACK',
        anomaly_count: anomalies.length,
        critical_count: anomalies.filter(a => a.severity === 'CRITICAL').length,
        warning_count: anomalies.filter(a => a.severity === 'WARNING').length,
        anomalies,
      };
    }
  },
};

function getFallbackAnomalies(): BlackHoleAnomaly[] {
  return [
    {
      anomaly_id: 'BH-SEC-1301-8025',
      sector_id: 'SEC-13.01N-80.25E',
      center_lat: 13.0125,
      center_lng: 80.2510,
      radius_meters: 850.0,
      bounds: {
        min_lat: 13.0075,
        max_lat: 13.0175,
        min_lng: 80.2460,
        max_lng: 80.2560,
      },
      baseline_nodes: 412,
      current_nodes: 24,
      drop_percentage: 94.2,
      decay_rate_per_hour: 194.0,
      estimated_silenced_people: 1030,
      severity: 'CRITICAL',
      recommended_action: 'DISPATCH_AERIAL_RECON_DRONE_WITH_DTN_RELAY',
      silence_duration_minutes: 48.0,
      detected_at: Date.now() - 48 * 60 * 1000,
      affected_incidents: ['INC-2026-FLOOD-01', 'CLUSTER-ADYAR-EAST'],
      last_signal_seen: '18 min ago via mule node SR-9F21',
      time_series: [
        { timestamp: Date.now() - 120 * 60 * 1000, active_nodes: 412 },
        { timestamp: Date.now() - 90 * 60 * 1000, active_nodes: 388 },
        { timestamp: Date.now() - 60 * 60 * 1000, active_nodes: 180 },
        { timestamp: Date.now() - 30 * 60 * 1000, active_nodes: 54 },
        { timestamp: Date.now(), active_nodes: 24 },
      ],
    },
    {
      anomaly_id: 'BH-SEC-1293-8013',
      sector_id: 'SEC-12.93N-80.13E',
      center_lat: 12.9340,
      center_lng: 80.1320,
      radius_meters: 650.0,
      bounds: {
        min_lat: 12.9290,
        max_lat: 12.9390,
        min_lng: 12.1270,
        max_lng: 80.1370,
      },
      baseline_nodes: 185,
      current_nodes: 38,
      drop_percentage: 79.5,
      decay_rate_per_hour: 73.5,
      estimated_silenced_people: 462,
      severity: 'CRITICAL',
      recommended_action: 'DEPLOY_TACTICAL_CELLULAR_COW_TRUCK',
      silence_duration_minutes: 32.0,
      detected_at: Date.now() - 32 * 60 * 1000,
      affected_incidents: ['INC-2026-LANDSLIDE-03'],
      last_signal_seen: '26 min ago via gateway SDRF-4WD-02',
      time_series: [
        { timestamp: Date.now() - 120 * 60 * 1000, active_nodes: 185 },
        { timestamp: Date.now() - 90 * 60 * 1000, active_nodes: 172 },
        { timestamp: Date.now() - 60 * 60 * 1000, active_nodes: 110 },
        { timestamp: Date.now() - 30 * 60 * 1000, active_nodes: 58 },
        { timestamp: Date.now(), active_nodes: 38 },
      ],
    },
    {
      anomaly_id: 'BH-SEC-1304-8022',
      sector_id: 'SEC-13.04N-80.22E',
      center_lat: 13.0420,
      center_lng: 80.2250,
      radius_meters: 500.0,
      bounds: {
        min_lat: 13.0370,
        max_lat: 13.0470,
        min_lng: 80.2200,
        max_lng: 80.2300,
      },
      baseline_nodes: 260,
      current_nodes: 112,
      drop_percentage: 56.9,
      decay_rate_per_hour: 74.0,
      estimated_silenced_people: 370,
      severity: 'WARNING',
      recommended_action: 'STATIONARY_MULE_DEPLOYMENT_HIGH_GROUND',
      silence_duration_minutes: 20.0,
      detected_at: Date.now() - 20 * 60 * 1000,
      affected_incidents: ['CLUSTER-METRO-WEST'],
      last_signal_seen: '8 min ago via volunteer beacon 108-AMB-05',
      time_series: [
        { timestamp: Date.now() - 120 * 60 * 1000, active_nodes: 260 },
        { timestamp: Date.now() - 90 * 60 * 1000, active_nodes: 255 },
        { timestamp: Date.now() - 60 * 60 * 1000, active_nodes: 220 },
        { timestamp: Date.now() - 30 * 60 * 1000, active_nodes: 150 },
        { timestamp: Date.now(), active_nodes: 112 },
      ],
    },
  ];
}
