// api/incidents.ts
// Complete API client and mock repository for RakshaNet Incidents & Rescues

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


// Master Incident Ticket INC-2025-001 exactly matching media_1791015140209.jpg
export const INC_PRIMARY: Incident = {
  id: 'INC-2025-001',
  incident_id: 'INC-2025-001',
  title: 'Flood in River Area',
  type: 'Flood',
  severity: 'CRITICAL',
  status: 'Active',
  affectedPeople: 142,
  devicesCount: 28,
  location: 'Uttarakhand, India',
  coordinates: {
    lat: 30.1458,
    lng: 78.2982,
  },
  affectedAreaKm2: 12.0,
  clusterRadiusMeters: 1950,
  polygonCoords: [
    [30.155, 78.285],
    [30.162, 78.305],
    [30.148, 78.322],
    [30.132, 78.312],
    [30.138, 78.289],
  ],
  reportedBy: 'Multiple users',
  firstReported: '12 min ago',
  firstReportedTimestamp: Date.now() - 12 * 60 * 1000,
  lastUpdate: '2 min ago',
  lastUpdateTimestamp: Date.now() - 2 * 60 * 1000,
  assignedTeam: null,
  assignedUnitId: null,
  description:
    'Heavy flooding reported in the river area. Multiple users have reported houses submerged and people stranded on rooftops. Communication networks are down.',
  subReportsCount: 28,
  resourcesNeeded: [
    {
      id: 'res-1',
      title: 'Rescue Boats',
      quantityDisplay: '3 units',
      priority: 'Critical',
      iconType: 'boat',
      allocatedCount: 0,
      statusText: 'Required urgently for rooftop extractions',
    },
    {
      id: 'res-2',
      title: 'Medical Teams',
      quantityDisplay: '2 units',
      priority: 'High',
      iconType: 'medical',
      allocatedCount: 0,
      statusText: 'Trauma kits & hypothermia care ready',
    },
    {
      id: 'res-3',
      title: 'Food & Water',
      quantityDisplay: 'High priority',
      priority: 'High',
      iconType: 'food',
      allocatedCount: 0,
      statusText: 'Rations for 150+ survivors across 48h',
    },
    {
      id: 'res-4',
      title: 'Temporary Shelter',
      quantityDisplay: '2 units',
      priority: 'Required',
      iconType: 'shelter',
      allocatedCount: 0,
      statusText: 'Community hall high-ground coordination',
    },
  ],
  aiExplainability: {
    priorityScore: 96,
    confidencePct: 94,
    confidenceGrade: 'VERY_HIGH',
    modelVersion: 'RakshaNet Bayesian Spatial v2.4 (DBSCAN + Poisson Mules)',
    synthesis:
      'High confidence cluster of 28 distress transmissions. Spatiotemporal velocity indicates flash water level increase. Urgent boat deployment recommended.',
    disclaimer: 'Probabilistic casualty & search zone model. Values are estimated, not exact.',
    factors: {
      lastContactTime: {
        name: 'Last Contact Time',
        factorKey: 'last_contact',
        weightPct: 25,
        valueDisplay: '2 min ago (Active distress stream)',
        status: 'critical',
        details: 'Distress packets received via 4-hop BLE mesh relay. Zero cellular ping detected.',
      },
      incidentSeverity: {
        name: 'Incident Severity',
        factorKey: 'severity',
        weightPct: 30,
        valueDisplay: 'CRITICAL (Flash flood water rise)',
        status: 'critical',
        details: 'Structural submergence confirmed with 9 individuals trapped on rooftops.',
      },
      affectedPopulation: {
        name: 'Affected Population Estimate',
        factorKey: 'population',
        weightPct: 20,
        valueDisplay: '142 people (~5.07 per active device)',
        status: 'critical',
        details: 'Derived from Indian Census rural household density and active signal count (28 handsets).',
      },
      hazardBoundaryProximity: {
        name: 'Hazard Boundary Proximity',
        factorKey: 'hazard_proximity',
        weightPct: 15,
        valueDisplay: '0.2 km from river embankment breach',
        status: 'warning',
        details: 'Centroid is 180m inside the predicted 1-hour hydrological inundation contour.',
      },
      communicationStatus: {
        name: 'Communication Status',
        factorKey: 'comm_status',
        weightPct: 10,
        valueDisplay: 'DEGRADED (Mesh relay operational)',
        status: 'warning',
        details: '3 cellular towers blacked out; surviving telemetry relayed via pedestrian data mules.',
      },
    },
  },
};

const SEED_INCIDENTS: Incident[] = [
  INC_PRIMARY,
  {
    id: 'INC-2025-002',
    incident_id: 'INC-2025-002',
    title: 'Landslide on NH-7 Highway Pass',
    type: 'Landslide',
    severity: 'HIGH',
    status: 'Active',
    affectedPeople: 45,
    devicesCount: 9,
    location: 'Himachal Pradesh, India',
    coordinates: { lat: 31.1048, lng: 77.1734 },
    affectedAreaKm2: 4.5,
    clusterRadiusMeters: 850,
    polygonCoords: [
      [31.11, 77.168],
      [31.115, 77.178],
      [31.102, 77.182],
      [31.098, 77.17],
    ],
    reportedBy: 'Bus Driver & 8 passengers',
    firstReported: '26 min ago',
    firstReportedTimestamp: Date.now() - 26 * 60 * 1000,
    lastUpdate: '5 min ago',
    lastUpdateTimestamp: Date.now() - 5 * 60 * 1000,
    assignedTeam: 'SDRF High-Clearance 4WD 02',
    assignedUnitId: 'SDRF-4WD-02',
    description:
      'Major debris avalanche blocking both lanes of NH-7. Three vehicles trapped under loose rocks. Ground shifting continues.',
    subReportsCount: 9,
    resourcesNeeded: [
      {
        id: 'res-2-1',
        title: 'Heavy Earth Movers',
        quantityDisplay: '2 JCBs',
        priority: 'High',
        iconType: 'personnel',
        allocatedCount: 1,
      },
      {
        id: 'res-2-2',
        title: 'Trauma Paramedics',
        quantityDisplay: '1 team',
        priority: 'High',
        iconType: 'medical',
        allocatedCount: 1,
      },
    ],
    aiExplainability: {
      priorityScore: 82,
      confidencePct: 89,
      confidenceGrade: 'HIGH',
      modelVersion: 'RakshaNet Bayesian Spatial v2.4',
      synthesis: 'Confirmed transport artery severed. Ground instability factor remains elevated.',
      disclaimer: 'Probabilistic casualty & search zone model. Values are estimated, not exact.',
      factors: {
        lastContactTime: {
          name: 'Last Contact Time',
          factorKey: 'last_contact',
          weightPct: 20,
          valueDisplay: '5 min ago',
          status: 'warning',
          details: 'Telemetry hopping via solar road beacon.',
        },
        incidentSeverity: {
          name: 'Incident Severity',
          factorKey: 'severity',
          weightPct: 35,
          valueDisplay: 'HIGH (Road blockage & rockfall)',
          status: 'critical',
          details: 'Physical barrier restricting medical transit.',
        },
        affectedPopulation: {
          name: 'Affected Population Estimate',
          factorKey: 'population',
          weightPct: 20,
          valueDisplay: '45 people (2 buses + 3 cars)',
          status: 'warning',
          details: 'Vehicle manifest correlation.',
        },
        hazardBoundaryProximity: {
          name: 'Hazard Boundary Proximity',
          factorKey: 'hazard_proximity',
          weightPct: 15,
          valueDisplay: 'Immediate slope face',
          status: 'warning',
          details: 'Rockfall perimeter active.',
        },
        communicationStatus: {
          name: 'Communication Status',
          factorKey: 'comm_status',
          weightPct: 10,
          valueDisplay: 'INTERMITTENT',
          status: 'warning',
          details: 'Mountain shadow creates sporadic relay intervals.',
        },
      },
    },
  },
  {
    id: 'INC-2025-003',
    incident_id: 'INC-2025-003',
    title: 'Building Collapse in Sector 9',
    type: 'Building Collapse',
    severity: 'HIGH',
    status: 'Investigating',
    affectedPeople: 68,
    devicesCount: 14,
    location: 'Delhi NCR, India',
    coordinates: { lat: 28.6139, lng: 77.209 },
    affectedAreaKm2: 1.8,
    clusterRadiusMeters: 320,
    reportedBy: 'Local residents & ward councillor',
    firstReported: '1 hour ago',
    firstReportedTimestamp: Date.now() - 60 * 60 * 1000,
    lastUpdate: '8 min ago',
    lastUpdateTimestamp: Date.now() - 8 * 60 * 1000,
    assignedTeam: null,
    assignedUnitId: null,
    description:
      '4-story residential complex partial collapse after basement excavation failure. Multiple residents trapped on upper floors and rubble pockets.',
    subReportsCount: 14,
    resourcesNeeded: [
      {
        id: 'res-3-1',
        title: 'K9 Search & Rescue',
        quantityDisplay: '2 dogs',
        priority: 'Critical',
        iconType: 'personnel',
      },
      {
        id: 'res-3-2',
        title: 'Hydraulic Cutters',
        quantityDisplay: '4 units',
        priority: 'High',
        iconType: 'personnel',
      },
    ],
    aiExplainability: {
      priorityScore: 78,
      confidencePct: 86,
      confidenceGrade: 'HIGH',
      modelVersion: 'RakshaNet Bayesian Spatial v2.4',
      synthesis: 'Acoustic and BLE ping density points to concentrated rubble survivors.',
      disclaimer: 'Probabilistic casualty & search zone model. Values are estimated, not exact.',
      factors: {
        lastContactTime: {
          name: 'Last Contact Time',
          factorKey: 'last_contact',
          weightPct: 25,
          valueDisplay: '8 min ago',
          status: 'warning',
          details: 'Survivors transmitting short beacon bursts.',
        },
        incidentSeverity: {
          name: 'Incident Severity',
          factorKey: 'severity',
          weightPct: 35,
          valueDisplay: 'HIGH (Structural collapse)',
          status: 'critical',
          details: 'Entrapment under concrete slabs.',
        },
        affectedPopulation: {
          name: 'Affected Population Estimate',
          factorKey: 'population',
          weightPct: 20,
          valueDisplay: '68 residents',
          status: 'warning',
          details: 'Building registry matching.',
        },
        hazardBoundaryProximity: {
          name: 'Hazard Boundary Proximity',
          factorKey: 'hazard_proximity',
          weightPct: 10,
          valueDisplay: 'Urban perimeter',
          status: 'normal',
          details: 'Surrounding structures evacuated.',
        },
        communicationStatus: {
          name: 'Communication Status',
          factorKey: 'comm_status',
          weightPct: 10,
          valueDisplay: 'CELLULAR AVAILABLE',
          status: 'normal',
          details: 'Cell towers operational.',
        },
      },
    },
  },
  {
    id: 'INC-2025-004',
    incident_id: 'INC-2025-004',
    title: 'Cyclone Alert - Coastal Fishing Village',
    type: 'Cyclone',
    severity: 'MEDIUM',
    status: 'Active',
    affectedPeople: 310,
    devicesCount: 52,
    location: 'Odisha Coast, India',
    coordinates: { lat: 19.8135, lng: 85.8312 },
    affectedAreaKm2: 24.0,
    clusterRadiusMeters: 3800,
    reportedBy: 'Village Panchayats & Marine Police',
    firstReported: '2 hours ago',
    firstReportedTimestamp: Date.now() - 120 * 60 * 1000,
    lastUpdate: '15 min ago',
    lastUpdateTimestamp: Date.now() - 15 * 60 * 1000,
    assignedTeam: 'Civil Defense Evacuation Fleet',
    assignedUnitId: null,
    description:
      'Gale force winds reaching 110 km/h with 2.5m storm surge warning. Fishermen settlements along shore need preemptive relocation.',
    subReportsCount: 52,
    resourcesNeeded: [
      {
        id: 'res-4-1',
        title: 'Evacuation Buses',
        quantityDisplay: '12 units',
        priority: 'High',
        iconType: 'shelter',
      },
    ],
    aiExplainability: {
      priorityScore: 68,
      confidencePct: 91,
      confidenceGrade: 'HIGH',
      modelVersion: 'RakshaNet Bayesian Spatial v2.4',
      synthesis: 'Storm surge trajectory indicates high vulnerability for thatch dwellings.',
      disclaimer: 'Probabilistic casualty & search zone model. Values are estimated, not exact.',
      factors: {
        lastContactTime: {
          name: 'Last Contact Time',
          factorKey: 'last_contact',
          weightPct: 20,
          valueDisplay: '15 min ago',
          status: 'normal',
          details: 'Continuous satellite relay broadcast.',
        },
        incidentSeverity: {
          name: 'Incident Severity',
          factorKey: 'severity',
          weightPct: 25,
          valueDisplay: 'MEDIUM (Preemptive evacuation)',
          status: 'normal',
          details: 'No confirmed structural breaches yet.',
        },
        affectedPopulation: {
          name: 'Affected Population Estimate',
          factorKey: 'population',
          weightPct: 25,
          valueDisplay: '310 villagers',
          status: 'warning',
          details: 'Coastal ward register.',
        },
        hazardBoundaryProximity: {
          name: 'Hazard Boundary Proximity',
          factorKey: 'hazard_proximity',
          weightPct: 20,
          valueDisplay: 'Direct coastal line',
          status: 'critical',
          details: 'Inside tidal surge envelope.',
        },
        communicationStatus: {
          name: 'Communication Status',
          factorKey: 'comm_status',
          weightPct: 10,
          valueDisplay: 'ONLINE',
          status: 'normal',
          details: 'Disaster satellite backhaul active.',
        },
      },
    },
  },
];

export const RESCUE_FLEET_AVAILABLE: RescueUnit[] = [
  {
    unit_id: 'NDRF-BOAT-01',
    name: 'NDRF Zodiac Inflatable Boat 01',
    unit_type: 'BOAT',
    agency: 'NDRF',
    lat: 30.141,
    lng: 78.291,
    capacity: 10,
    status: 'AVAILABLE',
    speed_kmh: 25.0,
    eta_minutes: 8,
    distance_km: 2.1,
    capabilities: ['WATER_RESCUE', 'EVACUATION', 'FLOOD_NAV'],
    contact_frequency: 'VHF CH-16 (156.800 MHz)',
  },
  {
    unit_id: 'SDRF-4WD-02',
    name: 'SDRF High-Clearance Rescue Truck 02',
    unit_type: 'HIGH_CLEARANCE_4WD',
    agency: 'SDRF',
    lat: 30.132,
    lng: 78.281,
    capacity: 6,
    status: 'AVAILABLE',
    speed_kmh: 45.0,
    eta_minutes: 14,
    distance_km: 4.8,
    capabilities: ['STRUCTURAL_SEARCH', 'EVACUATION', 'DEBRIS_CLEAR'],
    contact_frequency: 'UHF CH-04 (446.050 MHz)',
  },
  {
    unit_id: '108-AMB-05',
    name: 'Emergency Trauma Paramedic Ambulance 05',
    unit_type: 'AMBULANCE',
    agency: '108_EMS',
    lat: 30.155,
    lng: 78.31,
    capacity: 2,
    status: 'AVAILABLE',
    speed_kmh: 50.0,
    eta_minutes: 11,
    distance_km: 3.5,
    capabilities: ['PARAMEDIC', 'ADVANCED_LIFE_SUPPORT', 'TRIAGE'],
    contact_frequency: '108 DISPATCH NET',
  },
  {
    unit_id: 'ARMY-HELI-01',
    name: 'Indian Army ALH Dhruv Air Recon 01',
    unit_type: 'HELICOPTER',
    agency: 'ARMY',
    lat: 30.18,
    lng: 78.35,
    capacity: 12,
    status: 'AVAILABLE',
    speed_kmh: 160.0,
    eta_minutes: 6,
    distance_km: 9.4,
    capabilities: ['WATER_RESCUE', 'STRUCTURAL_SEARCH', 'AERIAL_RECON', 'WINCH_EXTRACTION'],
    contact_frequency: 'MIL AIR OPS (123.450 MHz)',
  },
];

let incidentsStore = [...SEED_INCIDENTS];

export const incidentsApi = {
  getIncidents: async (epsMeters: number = 120.0, minSamples: number = 2): Promise<Incident[]> => {
    try {
      const response = await apiClient.get<Incident[]>('/api/v1/incidents', {
        params: { eps_meters: epsMeters, min_samples: minSamples },
      });
      if (response.data && response.data.length > 0) {
        return response.data.map((item: any) => {
          const cat = item.disaster_type || item.category ? String(item.disaster_type || item.category) : '';
          const categoryFormatted = cat ? cat.charAt(0).toUpperCase() + cat.slice(1).toLowerCase() : 'Disaster';
          const incId = item.incident_id || item.id || 'INC-UNKNOWN';
          const autoTitle = `${categoryFormatted} Response Zone - Sector ${incId}`;
          const lat = item.lat ?? item.centroid_lat ?? item.coordinates?.lat ?? 30.1458;
          const lng = item.lng ?? item.centroid_lng ?? item.coordinates?.lng ?? 78.2982;
          const people = item.affectedPeople ?? item.people_count ?? item.casualty_estimate ?? item.estimated_casualties ?? 142;
          const devices = item.devicesCount ?? item.devices_count ?? item.total_devices ?? (item.associated_devices?.length || 28);
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
            location: item.location || item.affected_area || `${lat.toFixed(4)}° N, ${lng.toFixed(4)}° E`,
            coordinates: { lat, lng },
            affectedPeople: people,
            people_count: people,
            devicesCount: devices,
            devices_count: devices,
            clusterRadiusMeters: radiusM,
            cluster_radius_meters: radiusM,
            affectedAreaKm2: item.affectedAreaKm2 || item.affected_area_km2 || +(Math.PI * Math.pow(radiusM / 1000, 2)).toFixed(1) || 12.0,
            firstReported: item.firstReported || item.first_reported || '12 min ago',
            description: item.description || `Active ${categoryFormatted} distress cluster detected over tactical mesh network. Immediate multi-unit dispatch protocol enabled.`,
          };
        });
      }
    } catch {
      // fallback
    }
    return incidentsStore;
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
  let filtered = [...incidentsStore];

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

  return {
    data: paginatedData,
    totalCount,
    currentPage,
    pageSize,
    totalPages,
  };
}

function normalizeIncidentAiExplainability(d: any, people: number): import('../types/incident.ts').AIExplainability {
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

  const rawConf = d.ai_confidence ?? rawAi.confidencePct ?? 0.94;
  const confidencePct = Math.min(100, Math.max(10, Math.round(rawConf > 1 ? rawConf : rawConf * 100)));

  return {
    priorityScore: rawAi.priorityScore ?? (d.severity === 'CRITICAL' ? 96 : 84),
    confidencePct,
    confidenceGrade: rawAi.confidenceGrade || (confidencePct >= 90 ? 'VERY_HIGH' : 'HIGH'),
    modelVersion: rawAi.model_version || rawAi.modelVersion || 'RakshaNet-SpatialTriage-v2.1',
    synthesis:
      rawAi.synthesis ||
      (rawFactorsList.length > 0
        ? `AI Spatial Triage: ${rawFactorsList.join('. ')}`
        : 'High confidence cluster of distress transmissions. Spatiotemporal velocity indicates flash disaster event. Urgent unit deployment recommended.'),
    disclaimer: rawAi.disclaimer || 'Probabilistic casualty & search zone model. Values are estimated, not exact.',
    factors: {
      lastContactTime: existingFactors.lastContactTime || {
        name: 'Last Contact Time',
        factorKey: 'last_contact',
        weightPct: 25,
        valueDisplay: '2 min ago',
        status: 'critical',
        details: rawFactorsList[1] || 'Recent mesh beacon received via volunteer mule',
      },
      incidentSeverity: existingFactors.incidentSeverity || {
        name: 'Incident Severity',
        factorKey: 'severity',
        weightPct: 30,
        valueDisplay: d.severity || 'Critical',
        status: 'critical',
        details: rawFactorsList[0] || 'Flash disaster with life threat indicators',
      },
      affectedPopulation: existingFactors.affectedPopulation || {
        name: 'Estimated Population',
        factorKey: 'population',
        weightPct: 20,
        valueDisplay: `${people} survivors`,
        status: 'warning',
        details: rawFactorsList[2] || 'Based on DBSCAN device clustering and Poisson multiplier',
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
        valueDisplay: '3 hops away',
        status: 'warning',
        details: 'Cellular network dead, mesh relay active',
      },
      ...existingFactors,
    },
  };
}

export async function fetchIncidentById(id: string): Promise<Incident | null> {
  try {
    const res = await apiClient.get<any>(`/api/v1/incidents/${id}`);
    if (res.data) {
      const d = res.data;
      const lat = d.lat ?? d.centroid_lat ?? 30.1458;
      const lng = d.lng ?? d.centroid_lng ?? 78.2982;
      const radiusM = d.cluster_radius_meters ?? d.radius_meters ?? 180;
      const people = d.people_count ?? d.casualty_estimate ?? d.estimated_casualties ?? 142;
      const devices = d.devices_count ?? d.total_devices ?? (d.associated_devices?.length || 28);

      return {
        id: d.incident_id || id,
        incident_id: d.incident_id || id,
        title: d.title || 'Incident ' + (d.incident_id || id),
        type: d.disaster_type || d.category || 'Flood',
        severity: (d.severity || d.urgency || 'CRITICAL').toUpperCase(),
        status: d.status || 'Active',
        location: d.affected_area || (lat ? `${lat.toFixed(4)}° N, ${lng.toFixed(4)}° E` : 'Uttarakhand, India'),
        coordinates: { lat, lng },
        affectedAreaKm2: d.affected_area_km2 || +(Math.PI * Math.pow(radiusM / 1000, 2)).toFixed(1) || 12.0,
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
        reportedBy: d.reported_by || 'Multiple users (Mesh Nodes)',
        firstReported: d.first_reported || '12 min ago',
        firstReportedTimestamp: d.created_at || (Date.now() - 12 * 60 * 1000),
        lastUpdate: d.last_updated || '2 min ago',
        lastUpdateTimestamp: d.updated_at || (Date.now() - 2 * 60 * 1000),
        assignedTeam: d.assigned_team,
        assignedUnitId: d.assigned_unit_id,
        description: d.description || 'Heavy flooding reported in the river area. Multiple users have reported houses submerged and people stranded on rooftops. Communication networks are down. Distress packets relaying through volunteer handsets with 3 hops to nearest satellite node.',
        subReportsCount: devices,
        resourcesNeeded: Array.isArray(d.resources_needed) && d.resources_needed.length > 0 && typeof d.resources_needed[0] === 'object'
          ? d.resources_needed
          : [
              {
                id: 'res-1',
                title: 'Rescue Boats',
                quantityDisplay: '3 units',
                priority: 'Critical',
                iconType: 'boat',
                allocatedCount: 0,
                statusText: 'Required urgently for rooftop extractions',
              },
              {
                id: 'res-2',
                title: 'Medical Teams',
                quantityDisplay: '2 units',
                priority: 'High',
                iconType: 'medical',
                allocatedCount: 0,
                statusText: 'Trauma kits & hypothermia care ready',
              },
              {
                id: 'res-3',
                title: 'Food & Water',
                quantityDisplay: 'High priority',
                priority: 'High',
                iconType: 'food',
                allocatedCount: 0,
                statusText: 'Rations for 150+ survivors across 48h',
              },
              {
                id: 'res-4',
                title: 'Temp Shelter',
                quantityDisplay: 'Required',
                priority: 'Required',
                iconType: 'shelter',
                allocatedCount: 0,
                statusText: 'Community hall high-ground coordination',
              },
            ],
        aiExplainability: normalizeIncidentAiExplainability(d, people),
      };
    }
  } catch (err) {
    console.warn('[incidentsApi] fetchIncidentById remote error, falling back to local store', err);
  }
  const found = incidentsStore.find((i) => i.id === id || i.incident_id === id);
  return found || incidentsStore[0];
}

export async function fetchAvailableRescueUnits(): Promise<RescueUnit[]> {
  try {
    const res = await apiClient.get<RescueUnit[]>('/api/v1/dispatch/units');
    if (res.data && Array.isArray(res.data) && res.data.length > 0) {
      return res.data;
    }
  } catch {
    // fallback
  }
  return RESCUE_FLEET_AVAILABLE;
}

export async function assignTeamToIncident(
  incidentId: string,
  unitId: string,
  notes?: string
): Promise<{ success: boolean; unitName: string; incident: Incident }> {
  const unit = RESCUE_FLEET_AVAILABLE.find((u) => u.unit_id === unitId);
  const unitName = unit ? unit.name : unitId;

  try {
    await apiClient.post(`/api/v1/incidents/${incidentId}/assign`, {
      unit_id: unitId,
      notes: notes || 'Assigned via Incident Command Center',
    });
  } catch {
    // fallback
  }

  const target = incidentsStore.find((i) => i.id === incidentId || i.incident_id === incidentId);
  if (target) {
    target.assignedTeam = unitName;
    target.assignedUnitId = unitId;
    target.status = 'Dispatched';
    target.lastUpdate = 'Just now';
    target.lastUpdateTimestamp = Date.now();
  }

  return {
    success: true,
    unitName,
    incident: target || INC_PRIMARY,
  };
}

export function getIncidentPeople(count: number = 142): IncidentPerson[] {
  const people: IncidentPerson[] = [
    {
      id: 'P-101',
      name: 'Amit Kumar',
      role: 'Civic Survivor',
      status: 'Trapped',
      familyMembersCount: 5,
      lastContact: '2 min ago',
      devicePseudonym: 'SR-8F42',
      medicalNotes: 'Elderly diabetic parent with family on roof',
      location: 'Sector 3 Riverside Colony, House #14',
    },
    {
      id: 'P-102',
      name: 'Priya Sharma',
      role: 'Civic Survivor',
      status: 'Critical Triage',
      familyMembersCount: 3,
      lastContact: '5 min ago',
      devicePseudonym: 'SR-9A1C',
      medicalNotes: 'Minor leg injury from debris, infant child present',
      location: 'Primary School Upper Floor',
    },
    {
      id: 'P-103',
      name: 'Rahul Mehta',
      role: 'Civic Survivor',
      status: 'Trapped',
      familyMembersCount: 4,
      lastContact: '11 min ago',
      devicePseudonym: 'SR-3D7B',
      medicalNotes: 'Drinking water exhausted',
      location: 'Ganga Vihar Block B',
    },
    {
      id: 'P-104',
      name: 'Sneha Patel',
      role: 'Civic Survivor',
      status: 'Safe Haven',
      familyMembersCount: 2,
      lastContact: '15 min ago',
      devicePseudonym: 'SR-6E2F',
      medicalNotes: 'Safe on temple terrace',
      location: 'Shiv Mandir High Ridge',
    },
    {
      id: 'P-105',
      name: 'Vikram Singh',
      role: 'Responder',
      status: 'Safe Haven',
      familyMembersCount: 1,
      lastContact: '18 min ago',
      devicePseudonym: 'SR-7G3H',
      medicalNotes: 'Civil defense volunteer coordinating rooftop beacon',
      location: 'Water Tank Tower Overlook',
    },
  ];

  for (let i = 6; i <= Math.min(25, count); i++) {
    people.push({
      id: `P-${100 + i}`,
      name: `Resident Cluster Member #${i}`,
      role: i % 4 === 0 ? 'Elderly' : i % 5 === 0 ? 'Infant' : 'Civic Survivor',
      status: i % 3 === 0 ? 'Critical Triage' : 'Trapped',
      familyMembersCount: 2 + (i % 4),
      lastContact: `${(i * 2) % 30 + 1} min ago`,
      devicePseudonym: `SR-${(i * 99).toString(16).toUpperCase().padStart(4, '0')}`,
      location: `Submerged Lane ${(i % 6) + 1}`,
    });
  }

  return people;
}

export function getIncidentMessages(): IncidentMessage[] {
  return [
    {
      id: 'MSG-01',
      senderName: 'Amit Kumar',
      senderPseudonym: 'SR-8F42',
      hops: 1,
      timestamp: '2 min ago',
      text: 'Flood in river area, water level rising fast. 5 people trapped on our roof.',
      type: 'SOS',
      severity: 'CRITICAL',
      delivered: true,
    },
    {
      id: 'MSG-02',
      senderName: 'Priya Sharma',
      senderPseudonym: 'SR-9A1C',
      hops: 2,
      timestamp: '5 min ago',
      text: 'We are safe at school building second floor. Need rescue boat for elderly neighbors.',
      type: 'SOS',
      severity: 'CRITICAL',
      delivered: true,
    },
    {
      id: 'MSG-03',
      senderName: 'Rahul Mehta',
      senderPseudonym: 'SR-3D7B',
      hops: 3,
      timestamp: '10 min ago',
      text: 'Road breached near river culvert. Alternative boat approach recommended from eastern bend.',
      type: 'REPORT',
      severity: 'HIGH',
      delivered: true,
    },
    {
      id: 'MSG-04',
      senderName: 'Sneha Patel',
      senderPseudonym: 'SR-6E2F',
      hops: 2,
      timestamp: '15 min ago',
      text: 'Medical help required for hypothermic child. One person injured.',
      type: 'MEDICAL',
      severity: 'HIGH',
      delivered: true,
    },
    {
      id: 'MSG-05',
      senderName: 'Volunteer Team',
      senderPseudonym: 'SR-7G3H',
      hops: 1,
      timestamp: '16 min ago',
      text: 'NDRF advance reconnaissance unit reaching the perimeter in 10 minutes.',
      type: 'SYSTEM',
      severity: 'MEDIUM',
      delivered: true,
    },
  ];
}

export function getIncidentDevices(): IncidentDevice[] {
  return [
    {
      deviceId: 'SR-8F42',
      ownerName: 'Amit Kumar',
      deviceType: 'Phone',
      batteryPct: 65,
      hops: 1,
      lastSeen: '2 min ago',
      status: 'Online',
      rssi: -62,
    },
    {
      deviceId: 'SR-9A1C',
      ownerName: 'Priya Sharma',
      deviceType: 'Phone',
      batteryPct: 42,
      hops: 2,
      lastSeen: '5 min ago',
      status: 'Relay',
      rssi: -78,
    },
    {
      deviceId: 'SR-3D7B',
      ownerName: 'Rahul Mehta',
      deviceType: 'Phone',
      batteryPct: 76,
      hops: 3,
      lastSeen: '10 min ago',
      status: 'Online',
      rssi: -84,
    },
    {
      deviceId: 'SR-6E2F',
      ownerName: 'Sneha Patel',
      deviceType: 'Phone',
      batteryPct: 23,
      hops: 2,
      lastSeen: '15 min ago',
      status: 'Low Power',
      rssi: -88,
    },
    {
      deviceId: 'SR-7G3H',
      ownerName: 'Vikram Singh',
      deviceType: 'Solar Repeater',
      batteryPct: 98,
      hops: 1,
      lastSeen: '1 min ago',
      status: 'Relay',
      rssi: -51,
    },
  ];
}

export function getIncidentTimeline(): IncidentTimelineEvent[] {
  return [
    {
      id: 'TL-1',
      timestamp: '12 min ago',
      title: 'First Distress Telemetry Ingested',
      description: 'Incoming SOS beacon from handset SR-8F42 reporting rising water in river basin.',
      category: 'DISTRESS',
      actor: 'Amit Kumar (Civilian)',
      severity: 'CRITICAL',
    },
    {
      id: 'TL-2',
      timestamp: '10 min ago',
      title: 'DBSCAN Spatial Cluster Formed',
      description:
        'AI engine unified 8 distress pings within 120m into Master Incident ticket INC-2025-001. "Devices != People" model estimated 40+ casualties.',
      category: 'AI_TRIAGE',
      actor: 'RakshaNet Spatial Engine',
      severity: 'HIGH',
    },
    {
      id: 'TL-3',
      timestamp: '8 min ago',
      title: 'Severity Escalated to CRITICAL',
      description:
        'Submergence confirmed across 12 km² boundary; 28 handsets joined mesh cluster. Estimated casualties raised to 142.',
      category: 'AI_TRIAGE',
      actor: 'RakshaNet AI Core',
      severity: 'CRITICAL',
    },
    {
      id: 'TL-4',
      timestamp: '5 min ago',
      title: 'Resource Needs Formulated',
      description: 'Mixed-Integer dispatch model identified requirement for 3 inflatable boats and 2 medical units.',
      category: 'OPERATIONAL',
      actor: 'AI Dispatch Optimizer',
    },
    {
      id: 'TL-5',
      timestamp: '2 min ago',
      title: 'Heartbeat & Telemetry Refresh',
      description: 'Relay status re-verified over 4 hops. Embankment proximity remains at 0.2 km.',
      category: 'RELAY',
      actor: 'Solar Repeater Node SR-7G3H',
    },
  ];
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
  return {
    success: true,
    incident: res.data,
  };
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

