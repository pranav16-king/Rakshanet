// src/api/analytics.ts
import apiClient from './client';

export interface LiveAnalyticsData {
  totalMessages: number;
  totalMessagesDelta: string;
  uniqueUsers: number;
  uniqueUsersDelta: string;
  incidentsHandled: number;
  incidentsHandledDelta: string;
  peopleHelped: number;
  peopleHelpedDelta: string;
  totalSosRelayed: number;
  resolutionRatePct: number;
  avgResponseMinutes: number;
  networkEfficiencyPct: number;
  days: Array<{
    date: string;
    total: number;
    sos: number;
    reports: number;
    team: number;
  }>;
  incidentDistribution: Record<string, number>;
  deviceStats: {
    total: number;
    online: number;
    relay: number;
    offline: number;
  };
}

const EMPTY_ANALYTICS: LiveAnalyticsData = {
  totalMessages: 0,
  totalMessagesDelta: '',
  uniqueUsers: 0,
  uniqueUsersDelta: '',
  incidentsHandled: 0,
  incidentsHandledDelta: '',
  peopleHelped: 0,
  peopleHelpedDelta: '',
  totalSosRelayed: 0,
  resolutionRatePct: 0,
  avgResponseMinutes: 0,
  networkEfficiencyPct: 0,
  days: [],
  incidentDistribution: {},
  deviceStats: { total: 0, online: 0, relay: 0, offline: 0 },
};

export const analyticsApi = {
  getSummary: async (timeRange: string = '7d'): Promise<LiveAnalyticsData> => {
    try {
      const [trendsRes, overviewRes, deviceStatsRes] = await Promise.allSettled([
        apiClient.get('/api/v1/analytics/trends', { params: { range: timeRange } }),
        apiClient.get('/api/v1/dashboard/overview', { params: { timeRange } }),
        apiClient.get('/api/v1/devices/stats'),
      ]);

      const trendsData = trendsRes.status === 'fulfilled' ? trendsRes.value.data : {};
      const overviewData = overviewRes.status === 'fulfilled' ? overviewRes.value.data : {};
      const devStatsData = deviceStatsRes.status === 'fulfilled' ? deviceStatsRes.value.data : {};

      const days = Array.isArray(trendsData.days) && trendsData.days.length > 0
        ? trendsData.days
        : Array.isArray(trendsData.trends) && trendsData.trends.length > 0
        ? trendsData.trends
        : [];

      // Calculate total casualties across incidents from overview
      let peopleCount = 0;
      if (Array.isArray(overviewData.recent_incidents)) {
        peopleCount = overviewData.recent_incidents.reduce(
          (sum: number, inc: any) => sum + (Number(inc.people_count) || Number(inc.casualty_estimate) || 0),
          0
        );
      }

      const totalMsgs = trendsData.total_messages ?? days.reduce((acc: number, d: any) => acc + (d.total || 0), 0);
      const activeUsers = overviewData.active_users ?? 0;
      const activeIncidents = overviewData.active_incidents ?? (overviewData.recent_incidents?.length || 0);
      const resolutionRate = trendsData.resolution_rate_pct ?? 0;

      return {
        totalMessages: totalMsgs,
        totalMessagesDelta: trendsData.messages_delta ?? '',
        uniqueUsers: activeUsers,
        uniqueUsersDelta: trendsData.users_delta ?? '',
        incidentsHandled: activeIncidents,
        incidentsHandledDelta: resolutionRate > 0 ? `${resolutionRate}% triage efficiency` : '',
        peopleHelped: peopleCount,
        peopleHelpedDelta: 'Poisson casualty model',
        totalSosRelayed: trendsData.total_sos_relayed ?? 0,
        resolutionRatePct: resolutionRate,
        avgResponseMinutes: trendsData.avg_response_minutes ?? 0,
        networkEfficiencyPct: trendsData.network_efficiency_pct ?? 0,
        days,
        incidentDistribution: overviewData.incident_distribution || {},
        deviceStats: {
          total: devStatsData.total ?? 0,
          online: devStatsData.online ?? 0,
          relay: devStatsData.relay ?? 0,
          offline: devStatsData.offline ?? 0,
        },
      };
    } catch (err) {
      console.error('Failed to load analytics data:', err);
      return EMPTY_ANALYTICS;
    }
  },
};
