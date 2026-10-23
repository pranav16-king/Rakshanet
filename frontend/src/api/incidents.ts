import apiClient from './client';
import type { Incident, IncidentCommunicationsResponse, IncidentDevice, IncidentFilterOptions, IncidentMessage, IncidentMeshTopologyResponse, IncidentPerson, IncidentTimelineEvent, PaginatedIncidentsResponse, RescueUnit } from '../types/incident.ts';

const numberOrUndefined = (value: unknown): number | undefined => typeof value === 'number' && Number.isFinite(value) ? value : undefined;
const textOrUndefined = (value: unknown): string | undefined => typeof value === 'string' && value.trim() ? value : undefined;

/** Maps only fields that the gateway actually supplied. Missing telemetry remains unavailable. */
function normalizeIncident(raw: any): Incident {
  const lat = numberOrUndefined(raw?.lat ?? raw?.centroid_lat ?? raw?.coordinates?.lat);
  const lng = numberOrUndefined(raw?.lng ?? raw?.centroid_lng ?? raw?.coordinates?.lng);
  const coordinates = lat !== undefined && lng !== undefined ? { lat, lng } : undefined;
  const id = String(raw?.incident_id ?? raw?.id ?? '');
  const people = numberOrUndefined(raw?.affectedPeople ?? raw?.people_count ?? raw?.casualty_estimate ?? raw?.estimated_casualties);
  const devices = numberOrUndefined(raw?.devicesCount ?? raw?.devices_count ?? raw?.total_devices);

  return {
    ...raw,
    id,
    incident_id: id,
    title: textOrUndefined(raw?.title) ?? id,
    type: textOrUndefined(raw?.type ?? raw?.disaster_type ?? raw?.category) ?? 'UNSPECIFIED',
    disaster_type: textOrUndefined(raw?.disaster_type ?? raw?.type ?? raw?.category) ?? 'UNSPECIFIED',
    severity: String(raw?.severity ?? raw?.urgency ?? 'UNKNOWN').toUpperCase(),
    status: String(raw?.status ?? 'UNCLASSIFIED').toUpperCase(),
    location: textOrUndefined(raw?.location ?? raw?.affected_area) ?? (coordinates ? `${lat!.toFixed(4)}°, ${lng!.toFixed(4)}°` : 'Location unavailable'),
    coordinates,
    affectedAreaKm2: numberOrUndefined(raw?.affectedAreaKm2 ?? raw?.affected_area_km2),
    clusterRadiusMeters: numberOrUndefined(raw?.clusterRadiusMeters ?? raw?.cluster_radius_meters ?? raw?.radius_meters),
    polygonCoords: Array.isArray(raw?.polygonCoords ?? raw?.polygon_coords) ? raw.polygonCoords ?? raw.polygon_coords : undefined,
    affectedPeople: people,
    people_count: people,
    devicesCount: devices,
    devices_count: devices,
    reportedBy: textOrUndefined(raw?.reportedBy ?? raw?.reported_by),
    firstReported: textOrUndefined(raw?.firstReported ?? raw?.first_reported),
    firstReportedTimestamp: numberOrUndefined(raw?.firstReportedTimestamp ?? raw?.created_at),
    lastUpdate: textOrUndefined(raw?.lastUpdate ?? raw?.last_updated),
    lastUpdateTimestamp: numberOrUndefined(raw?.lastUpdateTimestamp ?? raw?.updated_at),
    assignedTeam: raw?.assigned_team ?? undefined,
    assignedUnitId: raw?.assignedUnitId ?? raw?.assigned_unit_id ?? undefined,
    description: textOrUndefined(raw?.description),
    resourcesNeeded: Array.isArray(raw?.resourcesNeeded ?? raw?.resources_needed) ? raw.resourcesNeeded ?? raw.resources_needed : [],
    aiExplainability: raw?.aiExplainability ?? raw?.ai_explainability,
    subReportsCount: numberOrUndefined(raw?.subReportsCount),
  } as Incident;
}

export const incidentsApi = {
  async getIncidents(epsMeters = 120.0, minSamples = 2): Promise<Incident[]> {
    try {
      const { data } = await apiClient.get<any[]>('/api/v1/incidents', { params: { source: 'db' } });
      return (Array.isArray(data) ? data : []).filter((item) => item?.incident_id || item?.id).map(normalizeIncident);
    } catch { return []; }
  },
  async triggerClustering(epsMeters = 120.0, minSamples = 2) {
    const { data } = await apiClient.post('/api/v1/incidents/cluster', null, { params: { eps_meters: epsMeters, min_samples: minSamples } });
    return data;
  },
  async getBlackHoles() { return (await apiClient.get('/api/v1/anomalies/black-holes')).data; },
  async scanBlackHoles() { return (await apiClient.post('/api/v1/anomalies/black-holes/scan')).data; },
};

export async function fetchIncidents(filters: IncidentFilterOptions): Promise<PaginatedIncidentsResponse> {
  const source = await incidentsApi.getIncidents();
  const query = filters.searchQuery?.trim().toLowerCase();
  const filtered = source.filter((incident) => {
    const location = typeof incident.location === 'string' ? incident.location : incident.location?.address ?? '';
    return (!query || [incident.id, incident.title, String(incident.type), location].some((value) => value.toLowerCase().includes(query))) &&
      (!filters.severity || filters.severity === 'ALL' || incident.severity === filters.severity) &&
      (!filters.type || filters.type === 'ALL' || incident.type === filters.type) &&
      (!filters.status || filters.status === 'ALL' || incident.status === filters.status);
  });
  const order: Record<string, number> = { CRITICAL: 4, HIGH: 3, MEDIUM: 2, LOW: 1, UNKNOWN: 0 };
  filtered.sort((a, b) => {
    const left = filters.sortBy === 'severity' ? order[a.severity] ?? 0 : filters.sortBy === 'affectedPeople' ? a.affectedPeople ?? -1 : filters.sortBy === 'firstReported' ? a.firstReportedTimestamp ?? -1 : a.lastUpdateTimestamp ?? -1;
    const right = filters.sortBy === 'severity' ? order[b.severity] ?? 0 : filters.sortBy === 'affectedPeople' ? b.affectedPeople ?? -1 : filters.sortBy === 'firstReported' ? b.firstReportedTimestamp ?? -1 : b.lastUpdateTimestamp ?? -1;
    return filters.sortOrder === 'desc' ? right - left : left - right;
  });
  const pageSize = filters.pageSize || 10;
  const totalPages = Math.max(1, Math.ceil(filtered.length / pageSize));
  const currentPage = Math.min(Math.max(1, filters.page || 1), totalPages);
  return { data: filtered.slice((currentPage - 1) * pageSize, currentPage * pageSize), totalCount: filtered.length, currentPage, pageSize, totalPages };
}

export async function fetchIncidentById(id: string): Promise<Incident | null> {
  if (!id) return null;
  try { const { data } = await apiClient.get<any>(`/api/v1/incidents/${id}`); return data ? normalizeIncident(data) : null; } catch { return null; }
}
export async function fetchAvailableRescueUnits(): Promise<RescueUnit[]> { try { const { data } = await apiClient.get<RescueUnit[]>('/api/v1/dispatch/units'); return Array.isArray(data) ? data : []; } catch { return []; } }
export async function assignTeamToIncident(incidentId: string, unitId: string, notes?: string): Promise<{ success: boolean; unitName: string; incident: Incident | null }> { const unit = (await fetchAvailableRescueUnits()).find((item) => item.unit_id === unitId); await apiClient.post(`/api/v1/incidents/${incidentId}/assign`, { unit_id: unitId, notes }); return { success: true, unitName: unit?.name ?? unitId, incident: await fetchIncidentById(incidentId) }; }
export function getIncidentPeople(): IncidentPerson[] { return []; }
export function getIncidentMessages(): IncidentMessage[] { return []; }
export function getIncidentDevices(): IncidentDevice[] { return []; }
export function getIncidentTimeline(): IncidentTimelineEvent[] { return []; }
export async function fetchIncidentCommunications(incidentId: string): Promise<IncidentCommunicationsResponse> { return (await apiClient.get<IncidentCommunicationsResponse>(`/api/v1/incidents/${incidentId}/communications`)).data; }
export async function fetchIncidentMeshTopology(incidentId: string): Promise<IncidentMeshTopologyResponse> { return (await apiClient.get<IncidentMeshTopologyResponse>(`/api/v1/incidents/${incidentId}/mesh-topology`)).data; }
export async function updateIncidentStatus(incidentId: string, status: string, notes?: string): Promise<{ success: boolean; incident: any }> { return { success: true, incident: (await apiClient.patch(`/api/v1/incidents/${incidentId}/status`, { status, notes })).data }; }
export async function broadcastIncidentMessage(incidentId: string, message: string, priority = 'HIGH', channel = 'ALL_CHANNELS'): Promise<{ success: boolean; message_id: string }> { return (await apiClient.post(`/api/v1/incidents/${incidentId}/messages`, { message, priority, channel })).data; }
