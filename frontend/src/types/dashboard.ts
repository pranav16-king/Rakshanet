export type IncidentSeverity = 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW' | 'UNKNOWN';

export type IncidentCategory =
  | 'Flood'
  | 'Earthquake'
  | 'Landslide'
  | 'Cyclone'
  | 'Fire'
  | 'Building Collapse'
  | 'Others';

export interface IncidentSummary {
  id: string;
  title: string;
  category: IncidentCategory;
  location: string;
  relativeTime: string;
  timestamp: number;
  severity: IncidentSeverity;
  affectedCount?: number;
  coordinates?: [number, number];
}

export interface IncidentCategoryDistribution {
  name: IncidentCategory;
  count: number;
  color: string;
}

export interface DashboardKpis {
  totalActiveUsers: {
    count: number;
    deltaYesterdayPct: number;
  };
  activeIncidents: {
    count: number;
    criticalCount: number;
  };
  connectedDevices: {
    count: number;
    deltaYesterdayPct: number;
  };
  messagesRelayed: {
    count: number;
    deltaYesterdayPct: number;
  };
}

export interface DashboardOverviewResponse {
  timeRange: string;
  lastUpdated: number;
  kpis: DashboardKpis;
  incidentDistribution: {
    total: number;
    categories: IncidentCategoryDistribution[];
  };
  recentIncidents: IncidentSummary[];
}
