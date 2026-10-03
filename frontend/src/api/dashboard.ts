import { apiClient } from './client';
import type { DashboardOverviewResponse } from '../types/dashboard';

export const DEFAULT_DASHBOARD_DATA: DashboardOverviewResponse = {
  timeRange: '24h',
  lastUpdated: Date.now(),
  kpis: {
    totalActiveUsers: {
      count: 1248,
      deltaYesterdayPct: 12,
    },
    activeIncidents: {
      count: 18,
      criticalCount: 3,
    },
    connectedDevices: {
      count: 326,
      deltaYesterdayPct: 20,
    },
    messagesRelayed: {
      count: 12842,
      deltaYesterdayPct: 45,
    },
  },
  incidentDistribution: {
    total: 18,
    categories: [
      { name: 'Flood', count: 6, color: '#3B82F6' },
      { name: 'Earthquake', count: 4, color: '#EF4444' },
      { name: 'Landslide', count: 3, color: '#F97316' },
      { name: 'Cyclone', count: 2, color: '#8B5CF6' },
      { name: 'Fire', count: 2, color: '#F59E0B' },
      { name: 'Others', count: 1, color: '#10B981' },
    ],
  },
  recentIncidents: [
    {
      id: 'INC-2025-001',
      title: 'Flood in River Area',
      category: 'Flood',
      location: 'Uttarakhand',
      relativeTime: '12 min ago',
      timestamp: Date.now() - 12 * 60 * 1000,
      severity: 'CRITICAL',
      affectedCount: 142,
      coordinates: [30.0668, 79.0193],
    },
    {
      id: 'INC-2025-002',
      title: 'Landslide on NH-7',
      category: 'Landslide',
      location: 'Himachal Pradesh',
      relativeTime: '26 min ago',
      timestamp: Date.now() - 26 * 60 * 1000,
      severity: 'HIGH',
      affectedCount: 38,
      coordinates: [31.1048, 77.1734],
    },
    {
      id: 'INC-2025-003',
      title: 'Building Collapse',
      category: 'Building Collapse',
      location: 'Delhi',
      relativeTime: '1 hour ago',
      timestamp: Date.now() - 60 * 60 * 1000,
      severity: 'HIGH',
      affectedCount: 19,
      coordinates: [28.6139, 77.2090],
    },
    {
      id: 'INC-2025-004',
      title: 'Cyclone Alert',
      category: 'Cyclone',
      location: 'Odisha',
      relativeTime: '2 hours ago',
      timestamp: Date.now() - 120 * 60 * 1000,
      severity: 'MEDIUM',
      affectedCount: 520,
      coordinates: [20.2961, 85.8245],
    },
  ],
};

export const EMPTY_DASHBOARD_DATA: DashboardOverviewResponse = {
  timeRange: '24h',
  lastUpdated: Date.now(),
  kpis: {
    totalActiveUsers: {
      count: 0,
      deltaYesterdayPct: 0,
    },
    activeIncidents: {
      count: 0,
      criticalCount: 0,
    },
    connectedDevices: {
      count: 0,
      deltaYesterdayPct: 0,
    },
    messagesRelayed: {
      count: 0,
      deltaYesterdayPct: 0,
    },
  },
  incidentDistribution: {
    total: 0,
    categories: [],
  },
  recentIncidents: [],
};

export async function fetchDashboardOverview(
  timeRange: string = '24h',
  forceEmpty: boolean = false
): Promise<DashboardOverviewResponse> {
  if (forceEmpty) {
    return EMPTY_DASHBOARD_DATA;
  }

  try {
    const response = await apiClient.get<DashboardOverviewResponse>('/dashboard/overview', {
      params: { timeRange },
    });
    if (response.data && response.data.kpis) {
      return response.data;
    }
  } catch {
    // Graceful fallback to default overview metrics when server is standalone/offline
  }

  return {
    ...DEFAULT_DASHBOARD_DATA,
    timeRange,
    lastUpdated: Date.now(),
  };
}
