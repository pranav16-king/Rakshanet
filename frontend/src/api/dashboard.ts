import { apiClient } from './client';
import type { DashboardOverviewResponse, IncidentCategoryDistribution } from '../types/dashboard';

export const EMPTY_DASHBOARD_DATA: DashboardOverviewResponse = {
  timeRange: '24h',
  lastUpdated: Date.now(),
  kpis: {
    totalActiveUsers: { count: 0, deltaYesterdayPct: 0 },
    activeIncidents: { count: 0, criticalCount: 0 },
    connectedDevices: { count: 0, deltaYesterdayPct: 0 },
    messagesRelayed: { count: 0, deltaYesterdayPct: 0 },
  },
  incidentDistribution: { total: 0, categories: [] },
  recentIncidents: [],
};

export async function fetchDashboardOverview(
  timeRange: string = '24h',
  forceEmpty: boolean = false
): Promise<DashboardOverviewResponse> {
  if (forceEmpty) return EMPTY_DASHBOARD_DATA;

  try {
    const response = await apiClient.get<any>('/api/v1/dashboard/overview', {
      params: { timeRange },
    });
    const d = response.data;
    if (d) {
      const dist = d.incident_distribution || {};
      const catList: IncidentCategoryDistribution[] = [
        { name: 'Flood',      count: dist.Flood      ?? 0, color: '#0E8A94' },
        { name: 'Earthquake', count: dist.Earthquake ?? 0, color: '#E11D48' },
        { name: 'Landslide',  count: dist.Landslide  ?? 0, color: '#D97706' },
        { name: 'Cyclone',    count: dist.Cyclone    ?? 0, color: '#8B5CF6' },
        { name: 'Fire',       count: dist.Fire       ?? 0, color: '#EF4444' },
        { name: 'Others',     count: dist.Others     ?? 0, color: '#64748B' },
      ];
      const totalDist = catList.reduce((acc, c) => acc + c.count, 0);

      const recentList = Array.isArray(d.recent_incidents) && d.recent_incidents.length > 0
        ? d.recent_incidents.map((inc: any, i: number) => ({
            id: inc.incident_id || inc.id || `INC-${i}`,
            title: inc.title || 'Disaster Incident',
            category: inc.disaster_type || 'Flood',
            location: inc.affected_area || (inc.lat ? `${inc.lat.toFixed(4)}° N, ${inc.lng.toFixed(4)}° E` : ''),
            relativeTime: `${(i + 1) * 7} min ago`,
            timestamp: inc.created_at || Date.now() - (i + 1) * 7 * 60 * 1000,
            severity: inc.severity || 'HIGH',
            affectedCount: inc.people_count ?? inc.casualty_estimate ?? 0,
            coordinates: [inc.lat ?? 0, inc.lng ?? 0],
          }))
        : [];

      return {
        timeRange,
        lastUpdated: Date.now(),
        kpis: {
          totalActiveUsers: {
            count: d.total_active_users ?? 0,
            deltaYesterdayPct: d.users_delta_pct ?? 0,
          },
          activeIncidents: {
            count: d.active_incidents ?? 0,
            criticalCount: d.critical_incidents ?? 0,
          },
          connectedDevices: {
            count: d.connected_devices ?? 0,
            deltaYesterdayPct: d.devices_delta_pct ?? 0,
          },
          messagesRelayed: {
            count: d.messages_relayed ?? 0,
            deltaYesterdayPct: d.messages_delta_pct ?? 0,
          },
        },
        incidentDistribution: { total: totalDist, categories: catList },
        recentIncidents: recentList,
      };
    }
  } catch {
    // Backend unreachable — return empty; UI will show empty states
  }

  return { ...EMPTY_DASHBOARD_DATA, timeRange, lastUpdated: Date.now() };
}
