export interface SeverityDistribution {
  critical: number;
  high: number;
  medium: number;
  low: number;
  total: number;
}

export interface IncidentTypeDistribution {
  flood: number;
  earthquake: number;
  landslide: number;
  cyclone: number;
  fire: number;
  others: number;
  total: number;
}

export interface NetworkHealthMetrics {
  totalPacketsReceived: number;
  uniquePacketsStored: number;
  duplicatesDropped: number;
  activeDataMules: number;
  sosBeaconsCount: number;
  activeIncidents: number;
  connectedDashboardClients: number;
}

export interface TimeSeriesDataPoint {
  timestamp?: string;
  label?: string;
  date?: string;
  textCount?: number;
  sosCount?: number;
  reportsCount?: number;
  sos?: number;
  reports?: number;
  total: number;
}

export type MessageTrendPoint = {
  date: string;
  total: number;
  sos: number;
  reports: number;
  [key: string]: any;
};

export interface AnalyticsSummary {
  totalMessages?: number;
  totalMessagesDelta?: string;
  uniqueUsers?: number;
  uniqueUsersDelta?: string;
  incidentsHandled?: number;
  incidentsHandledDelta?: string | number;
  peopleHelped?: number;
  peopleHelpedDelta?: string | number;
  totalActiveUsers?: number;
  userGrowthPct?: number;
  activeIncidentsCount?: number;
  criticalIncidentsCount?: number;
  connectedDevicesCount?: number;
  deviceGrowthPct?: number;
  messagesRelayedCount?: number;
  relayGrowthPct?: number;
  severityDistribution?: SeverityDistribution;
  incidentTypeDistribution?: IncidentTypeDistribution;
  networkMetrics?: NetworkHealthMetrics;
  messagesOverTime?: TimeSeriesDataPoint[];
  trends?: any;
}
