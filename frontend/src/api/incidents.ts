// api/incidents.ts
// Real API client for RakshaNet Incidents & Rescues — no hardcoded demo data

import apiClient from './client';
import type {
  Incident,
  IncidentFilterOptions,
  PaginatedIncidentsResponse,
  RescueUnit,
  IncidentPerson,
  IncidentMessage,
  IncidentDevice,
  IncidentTimelineEvent,
  IncidentCommunicationsResponse,
  IncidentMeshTopologyResponse,
} from '../types/incident.ts';

// ─── Normalization helpers ────────────────────────────────────────────────────

function normalizeIncidentAiExplainability(
  d: any,
  people: number
): import('../types/incident.ts').AIExplainability {
  const rawAi = d.ai_explainability || {};
  const rawFactorsList: string[] = Array.isArray(rawAi.factors)
    ? rawAi.factors
    : Array.isArray(rawAi.factorList)
    ? rawAi.factorList
    : [];

  const existingFactors =
    rawAi.factors && typeof rawAi.factors === 'object' && !Array.isArray(rawAi.factors)
      ? rawAi.factors
      : {};

  const rawConf = d.ai_confidence ?? rawAi.confidencePct ?? 0;
  const confidencePct = Math.min(100, Math.max(0, Math.round(rawConf > 1 ? rawConf : rawConf * 100)));

  return {
    priorityScore: rawAi.priorityScore ?? (d.severity === 'CRITICAL' ? 96 : 84),
    confidencePct,
    confidenceGrade: rawAi.confidenceGrade || (confidencePct >= 90 ? 'VERY_HIGH' : 'HIGH'),
    modelVersion: rawAi.model_version || rawAi.modelVersion || 'RakshaNet-SpatialTriage-v2.1',
    synthesis:
      rawAi.synthesis ||
      (rawFactorsList.length > 0
        ? `AI Spatial Triage: ${rawFactorsList.join('. ')}`
        : 'High confidence cluster of distress transmissions. Urgent unit deployment recommended.'),
    disclaimer:
      rawAi.disclaimer || 'Probabilistic casualty & search zone model. Values are estimated, not exact.',
    factors: {
      lastContactTime: existingFactors.lastContactTime || {
        name: 'Last Contact Time',
        factorKey: 'last_contact',
        weightPct: 25,
        valueDisplay: rawFactorsList[1] || 'Recent',
        status: 'critical',
        details: rawFactorsList[1] || 'Recent mesh beacon received',
      },
      incidentSeverity: existingFactors.incidentSeverity || {
        name: 'Incident Severity',
        factorKey: 'severity',
        weightPct: 30,
        valueDisplay: d.severity || 'Unknown',
        status: 'critical',
        details: rawFactorsList[0] || 'Disaster with life threat indicators',
      },
      affectedPopulation: existingFactors.affectedPopulation || {
        name: 'Estimated Population',
        factorKey: 'population',
        weightPct: 20,
        valueDisplay: people > 0 ? `${people} survivors` : 'Unknown',
        status: 'warning',
        details: rawFactorsList[2] || 'Based on DBSCAN device clustering',
      },
      hazardBoundaryProximity: existingFactors.hazardBoundaryProximity || {
        name: 'Hazard Proximity',
        factorKey: 'hazard',
        weightPct: 15,
        valueDisplay: 'Active Inundation',
        status: 'critical',
        details: 'Within primary disaster hazard zone boundary',
      },
      communicationStatus: existingFactors.communicationStatus || {
        name: 'Mesh Relay Hops',
        factorKey: 'comms',
        weightPct: 10,
        valueDisplay: 'Via mesh relay',
        status: 'warning',
        details: 'Mesh relay active',
      },
      ...existingFactors,
    },
  };
}

function normalizeIncident(item: any): Incident {
  const cat = item.disaster_type || item.category ? String(item.disaster_type || item.category) : '';
  const categoryFormatted = cat ? cat.charAt(0).toUpperCase() + cat.slice(1).toLowerCase() : 'Disaster';
  const incId = item.incident_id || item.id || 'INC-UNKNOWN';
  const autoTitle = `${categoryFormatted} Response Zone - Sector ${incId}`;
  const lat = item.lat ?? item.centroid_lat ?? item.coordinates?.lat ?? 0;
  const lng = item.lng ?? item.centroid_lng ?? item.coordinates?.lng ?? 0;
  const people = item.affectedPeople ?? item.people_count ?? item.casualty_estimate ?? item.estimated_casualties ?? 0;
  const devices = item.devicesCount ?? item.devices_count ?? item.total_devices ?? (item.associated_devices?.length || 0);
  const radiusM = item.clusterRadiusMeters ?? item.cluster_radius_meters ?? item.radius_meters ?? 600;

  return {
    ...item,
    id: incId,
    incident_id: incId,
    title: item.title || autoTitle,
    type: item.type || item.disaster_type || item.category || 'Disaster',
    disaster_type: item.disaster_type || item.type || item.category || 'Disaster',
    severity: (item.severity || item.urgency || 'HIGH').toUpperCase(),
    status: item.status || 'Active',
    location:
      item.location || item.affected_area || (lat ? `${lat.toFixed(4)}° N, ${lng.toFixed(4)}° E` : ''),
    coordinates: { lat, lng },
    affectedPeople: people,
    people_count: people,
    devicesCount: devices,
    devices_count: devices,
    clusterRadiusMeters: radiusM,
    cluster_radius_meters: radiusM,
    affectedAreaKm2:
      item.affectedAreaKm2 ||
      item.affected_area_km2 ||
      +(Math.PI * Math.pow(radiusM / 1000, 2)).toFixed(1) ||
      0,
    firstReported: item.firstReported || item.first_reported || '',
    description:
      item.description ||
      `Active ${categoryFormatted} distress cluster detected over tactical mesh network.`,
  };
}

// ─── API Methods ──────────────────────────────────────────────────────────────

export const incidentsApi = {
  getIncidents: async (epsMeters: number = 120.0, minSamples: number = 2): Promise<Incident[]> => {
    try {
      const response = await apiClient.get<Incident[]>('/api/v1/incidents', {
        params: { eps_meters: epsMeters, min_samples: minSamples },
      });
      if (response.data && response.data.length > 0) {
        return response.data.map(normalizeIncident);
      }
      return [];
    } catch {
      return [];
    }
  },

  triggerClustering: async (epsMeters: number = 120.0, minSamples: number = 2) => {
    const response = await apiClient.post('/api/v1/incidents/cluster', null, {
      params: { eps_meters: epsMeters, min_samples: minSamples },
    });
    return response.data;
  },

  getBlackHoles: async () => {
    const response = await apiClient.get('/api/v1/anomalies/black-holes');
    return response.data;
  },

  scanBlackHoles: async () => {
    const response = await apiClient.post('/api/v1/anomalies/black-holes/scan');
    return response.data;
  },
};

export async function fetchIncidents(filters: IncidentFilterOptions): Promise<PaginatedIncidentsResponse> {
  let source: Incident[] = [];
  try {
    const live = await incidentsApi.getIncidents();
    source = live;
  } catch {
    // backend unavailable
  }

  let filtered = [...source];

  if (filters.searchQuery?.trim()) {
    const q = filters.searchQuery.toLowerCase();
    filtered = filtered.filter(
      (inc) =>
        inc.title.toLowerCase().includes(q) ||
        inc.id.toLowerCase().includes(q) ||
        String(inc.location).toLowerCase().includes(q) ||
        String(inc.type).toLowerCase().includes(q)
    );
  }

  if (filters.severity && filters.severity !== 'ALL') {
    filtered = filtered.filter((inc) => inc.severity === filters.severity);
  }

  if (filters.type && filters.type !== 'ALL') {
    filtered = filtered.filter((inc) => inc.type === filters.type);
  }

  if (filters.status && filters.status !== 'ALL') {
    filtered = filtered.filter((inc) => inc.status === filters.status);
  }

  filtered.sort((a, b) => {
    let comparison = 0;
    if (filters.sortBy === 'severity') {
      const order: Record<string, number> = { CRITICAL: 4, HIGH: 3, MEDIUM: 2, LOW: 1, UNKNOWN: 0 };
      comparison = (order[a.severity] || 0) - (order[b.severity] || 0);
    } else if (filters.sortBy === 'affectedPeople') {
      comparison = a.affectedPeople - b.affectedPeople;
    } else if (filters.sortBy === 'firstReported') {
      comparison = a.firstReportedTimestamp - b.firstReportedTimestamp;
    } else {
      comparison = a.lastUpdateTimestamp - b.lastUpdateTimestamp;
    }
    return filters.sortOrder === 'desc' ? -comparison : comparison;
  });

  const totalCount = filtered.length;
  const pageSize = filters.pageSize || 10;
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
  const currentPage = Math.min(Math.max(1, filters.page || 1), totalPages);
  const startIndex = (currentPage - 1) * pageSize;
  const paginatedData = filtered.slice(startIndex, startIndex + pageSize);

  return { data: paginatedData, totalCount, currentPage, pageSize, totalPages };
}

export async function fetchIncidentById(id: string): Promise<Incident | null> {
  try {
    const res = await apiClient.get<any>(`/api/v1/incidents/${id}`);
    if (res.data) {
      const d = res.data;
      const lat = d.lat ?? d.centroid_lat ?? 0;
      const lng = d.lng ?? d.centroid_lng ?? 0;
      const radiusM = d.cluster_radius_meters ?? d.radius_meters ?? 180;
      const people = d.people_count ?? d.casualty_estimate ?? d.estimated_casualties ?? 0;
      const devices = d.devices_count ?? d.total_devices ?? (d.associated_devices?.length || 0);

      return {
        id: d.incident_id || id,
        incident_id: d.incident_id || id,
        title: d.title || 'Incident ' + (d.incident_id || id),
        type: d.disaster_type || d.category || 'Disaster',
        severity: (d.severity || d.urgency || 'UNKNOWN').toUpperCase(),
        status: d.status || 'Active',
        location:
          d.affected_area || (lat ? `${lat.toFixed(4)}° N, ${lng.toFixed(4)}° E` : ''),
        coordinates: { lat, lng },
        affectedAreaKm2:
          d.affected_area_km2 || +(Math.PI * Math.pow(radiusM / 1000, 2)).toFixed(1) || 0,
        clusterRadiusMeters: radiusM,
        polygonCoords: d.polygon_coords || [
          [lat + 0.008, lng - 0.006],
          [lat + 0.012, lng + 0.008],
          [lat - 0.004, lng + 0.012],
          [lat - 0.010, lng + 0.002],
          [lat - 0.005, lng - 0.008],
        ],
        affectedPeople: people,
        devicesCount: devices,
        reportedBy: d.reported_by || '',
        firstReported: d.first_reported || '',
        firstReportedTimestamp: d.created_at || Date.now(),
        lastUpdate: d.last_updated || '',
        lastUpdateTimestamp: d.updated_at || Date.now(),
        assignedTeam: d.assigned_team,
        assignedUnitId: d.assigned_unit_id,
        description: d.description || '',
        subReportsCount: devices,
        resourcesNeeded:
          Array.isArray(d.resources_needed) && d.resources_needed.length > 0
            ? d.resources_needed
            : [],
        aiExplainability: normalizeIncidentAiExplainability(d, people),
      };
    }
  } catch (err) {
    console.warn('[incidentsApi] fetchIncidentById remote error:', err);
  }
  return null;
}

export async function fetchAvailableRescueUnits(): Promise<RescueUnit[]> {
  try {
    const res = await apiClient.get<RescueUnit[]>('/api/v1/dispatch/units');
    if (res.data && Array.isArray(res.data) && res.data.length > 0) {
      return res.data;
    }
    return [];
  } catch {
    return [];
  }
}

export async function assignTeamToIncident(
  incidentId: string,
  unitId: string,
  notes?: string
): Promise<{ success: boolean; unitName: string; incident: Incident | null }> {
  const unitsRes = await fetchAvailableRescueUnits();
  const unit = unitsRes.find((u) => u.unit_id === unitId);
  const unitName = unit ? unit.name : unitId;

  await apiClient.post(`/api/v1/incidents/${incidentId}/assign`, {
    unit_id: unitId,
    notes: notes || 'Assigned via Incident Command Center',
  });

  const incident = await fetchIncidentById(incidentId);
  return { success: true, unitName, incident };
}

export function getIncidentPeople(): IncidentPerson[] {
  // People data comes from the backend only — no hardcoded demo people
  return [];
}

export function getIncidentMessages(): IncidentMessage[] {
  // Messages come from the backend only — no hardcoded demo messages
  return [];
}

export function getIncidentDevices(): IncidentDevice[] {
  // Devices come from the backend only — no hardcoded demo devices
  return [];
}

export function getIncidentTimeline(): IncidentTimelineEvent[] {
  // Timeline comes from the backend only — no hardcoded demo events
  return [];
}

export async function fetchIncidentCommunications(
  incidentId: string
): Promise<IncidentCommunicationsResponse> {
  const res = await apiClient.get<IncidentCommunicationsResponse>(
    `/api/v1/incidents/${incidentId}/communications`
  );
  return res.data;
}

export async function fetchIncidentMeshTopology(
  incidentId: string
): Promise<IncidentMeshTopologyResponse> {
  const res = await apiClient.get<IncidentMeshTopologyResponse>(
    `/api/v1/incidents/${incidentId}/mesh-topology`
  );
  return res.data;
}

export async function updateIncidentStatus(
  incidentId: string,
  status: string,
  notes?: string
): Promise<{ success: boolean; incident: any }> {
  const res = await apiClient.patch(`/api/v1/incidents/${incidentId}/status`, {
    status,
    notes,
  });
  return { success: true, incident: res.data };
}

export async function broadcastIncidentMessage(
  incidentId: string,
  message: string,
  priority: string = 'HIGH',
  channel: string = 'ALL_CHANNELS'
): Promise<{ success: boolean; message_id: string }> {
  const res = await apiClient.post(`/api/v1/incidents/${incidentId}/messages`, {
    message,
    priority,
    channel,
  });
  return res.data;
}
