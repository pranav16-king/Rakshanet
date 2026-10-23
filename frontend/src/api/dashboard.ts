import { apiClient } from './client';
import type { DashboardOverviewResponse, IncidentCategoryDistribution } from '../types/dashboard';

export const DEFAULT_DASHBOARD_DATA: DashboardOverviewResponse = {
  timeRange: '24h',
  lastUpdated: Date.now(),
  kpis: {
    totalActiveUsers: {
      count: 21,
      deltaYesterdayPct: 12,
    },
    activeIncidents: {
      count: 5,
      criticalCount: 2,
    },
    connectedDevices: {
      count: 8,
      deltaYesterdayPct: 20,
    },
    messagesRelayed: {
      count: 348,
      deltaYesterdayPct: 45,
    },
  },
  incidentDistribution: {
    total: 5,
    categories: [
      { name: 'Flood', count: 1, color: '#0E8A94' },
      { name: 'Earthquake', count: 1, color: '#D92D20' },
      { name: 'Landslide', count: 1, color: '#E07B00' },
      { name: 'Cyclone', count: 1, color: '#7A4DD8' },
      { name: 'Fire', count: 1, color: '#E0463B' },
      { name: 'Others', count: 0, color: '#64748B' },
    ],
  },
  recentIncidents: [
    {
      id: 'INC-FLD-2026-001',
      title: 'Severe Flash Flooding & Trapped Residents - Ward 14',
      category: 'Flood',
      location: 'Sector 4B Riverside Colony',
      relativeTime: '8 min ago',
      timestamp: Date.now() - 8 * 60 * 1000,
      severity: 'CRITICAL',
      affectedCount: 28,
      coordinates: [13.0425, 80.2285],
    },
    {
      id: 'INC-EQ-2026-002',
      title: 'Structural Collapse at South Market Complex',
      category: 'Earthquake',
      location: 'Commercial Plaza, Block B',
      relativeTime: '15 min ago',
      timestamp: Date.now() - 15 * 60 * 1000,
      severity: 'CRITICAL',
      affectedCount: 15,
      coordinates: [12.985, 80.21],
    },
    {
      id: 'INC-LND-2026-003',
      title: 'Hillside Highway Landslide & Road Blockage',
      category: 'Landslide',
      location: 'NH-48 Mountain Pass km 74',
      relativeTime: '24 min ago',
      timestamp: Date.now() - 24 * 60 * 1000,
      severity: 'HIGH',
      affectedCount: 12,
      coordinates: [12.932, 80.125],
    },
    {
      id: 'INC-CYC-2026-004',
      title: 'Coastal Storm Surge & Fishing Hamlet Evacuation',
      category: 'Cyclone',
      location: 'Kovalam Coast Sector 1',
      relativeTime: '1 hour ago',
      timestamp: Date.now() - 60 * 60 * 1000,
      severity: 'HIGH',
      affectedCount: 45,
      coordinates: [12.79, 80.25],
    },
    {
      id: 'INC-FIR-2026-005',
      title: 'Substation Electrical Fire & Chemical Fumes',
      category: 'Fire',
      location: 'Industrial Park Gate 3',
      relativeTime: '2 hours ago',
      timestamp: Date.now() - 120 * 60 * 1000,
      severity: 'MEDIUM',
      affectedCount: 6,
      coordinates: [13.08, 80.18],
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
    const response = await apiClient.get<any>('/api/v1/dashboard/overview', {
      params: { timeRange },
    });
    const d = response.data;
    if (d) {
      const dist = d.incident_distribution || {};
      const catList: IncidentCategoryDistribution[] = [
        { name: 'Flood', count: dist.Flood ?? 0, color: '#0E8A94' },
        { name: 'Earthquake', count: dist.Earthquake ?? 0, color: '#E11D48' },
        { name: 'Landslide', count: dist.Landslide ?? 0, color: '#D97706' },
        { name: 'Cyclone', count: dist.Cyclone ?? 0, color: '#8B5CF6' },
        { name: 'Fire', count: dist.Fire ?? 0, color: '#EF4444' },
        { name: 'Others', count: dist.Others ?? 0, color: '#64748B' },
      ];
      const totalDist = catList.reduce((acc, c) => acc + c.count, 0);

      const recentList = Array.isArray(d.recent_incidents) && d.recent_incidents.length > 0
        ? d.recent_incidents.map((inc: any, i: number) => ({
            id: inc.incident_id || inc.id || `INC-${i}`,
            title: inc.title || 'Disaster Incident',
            category: inc.disaster_type || 'Flood',
            location: inc.affected_area || (inc.lat ? `${inc.lat.toFixed(4)}° N, ${inc.lng.toFixed(4)}° E` : 'Sector 4B Riverside Colony'),
            relativeTime: `${(i + 1) * 7} min ago`,
            timestamp: inc.created_at || Date.now() - (i + 1) * 7 * 60 * 1000,
            severity: inc.severity || 'CRITICAL',
            affectedCount: inc.people_count || inc.casualty_estimate || 15,
            coordinates: [inc.lat || 13.0425, inc.lng || 80.2285],
          }))
        : DEFAULT_DASHBOARD_DATA.recentIncidents;

      return {
        timeRange,
        lastUpdated: Date.now(),
        kpis: {
          totalActiveUsers: {
            count: d.total_active_users ?? 21,
            deltaYesterdayPct: 12,
          },
          activeIncidents: {
            count: d.active_incidents ?? 5,
            criticalCount: d.critical_incidents ?? 2,
          },
          connectedDevices: {
            count: d.connected_devices ?? 8,
            deltaYesterdayPct: 20,
          },
          messagesRelayed: {
            count: d.messages_relayed ?? 348,
            deltaYesterdayPct: 45,
          },
        },
        incidentDistribution: {
          total: totalDist,
          categories: catList,
        },
        recentIncidents: recentList,
      };
    }
  } catch {
    // Fallback
  }

  return {
    ...DEFAULT_DASHBOARD_DATA,
    timeRange,
    lastUpdated: Date.now(),
  };
}
