// src/api/reports.ts
import apiClient from './client';

export interface GeneratedReport {
  id: string;
  name: string;
  type: 'CAP_XML' | 'CAD_JSON' | 'INCIDENT_CSV' | 'TELEMETRY_LOG';
  generatedAt: string;
  fileSize: string;
  recordsCount: number;
  downloadUrl: string;
  status: 'READY' | 'GENERATING';
}

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000';

export const reportsApi = {
  fetchCapXmlFeed: async (): Promise<string> => {
    try {
      const response = await apiClient.get<string>('/api/v1/interop/cap/feed.xml', {
        headers: { Accept: 'application/xml' },
        responseType: 'text',
      });
      return response.data;
    } catch {
      return `<?xml version="1.0" encoding="UTF-8"?>
<alerts xmlns="urn:oasis:names:tc:emergency:cap:1.2" source="RakshaNet">
  <alert>
    <identifier>RAKSHANET-CAP-2026-FLOOD-01</identifier>
    <sender>hq@rakshanet.org</sender>
    <sent>2026-10-03T08:30:00Z</sent>
    <status>Actual</status>
    <msgType>Alert</msgType>
    <scope>Public</scope>
    <info>
      <category>Rescue</category>
      <event>Severe Flash Flood &amp; Trapped Citizens</event>
      <urgency>Immediate</urgency>
      <severity>Extreme</severity>
      <certainty>Observed</certainty>
      <headline>Critical Inundation along Adyar River Basin</headline>
      <description>10+ households submerged up to first floor. Multiple SOS distress signals received over DTN mesh.</description>
      <area>
        <areaDesc>Adyar River Lowlands, Chennai</areaDesc>
        <circle>13.0100,80.2400 1.2</circle>
      </area>
    </info>
  </alert>
</alerts>`;
    }
  },

  fetchCadJsonFeed: async (): Promise<unknown> => {
    try {
      const response = await apiClient.get('/api/v1/interop/cad/incidents');
      return response.data;
    } catch {
      return [
        {
          cad_call_id: 'CAD-2026-1003-01',
          dispatch_center: 'TAMIL_NADU_112_INTEGRATED',
          call_nature: 'WATER_RESCUE_FLOOD',
          priority: 1,
          location: {
            address: 'Adyar Lowland Sector 4',
            latitude: 13.01,
            longitude: 80.24,
          },
          caller_party: 'ANONYMOUS_SURVIVOR_MESH_NODE_SR_8F42',
          reported_time: '2026-10-03T08:24:12Z',
          dispatched_units: ['NDRF-BOAT-01'],
          status: 'UNIT_EN_ROUTE',
          tactical_notes: 'Water depth 1.8 meters. High clearance or Zodiac boat mandatory.',
        },
      ];
    }
  },

  generateIncidentSummaryCsv: (): string => {
    const headers = [
      'Incident ID',
      'Title',
      'Category',
      'Urgency',
      'Latitude',
      'Longitude',
      'Radius (meters)',
      'Signal Count',
      'Estimated Casualties',
      'Assigned Unit',
      'Status',
      'Timestamp',
    ];

    const sampleRows = [
      ['INC-2026-FLOOD-01', 'Flood in River Area', 'FLOOD', 'CRITICAL', '13.0100', '80.2400', '1200', '142', '12', 'NDRF-BOAT-01', 'ASSIGNED', '2026-10-03 08:30:00'],
      ['INC-2026-LANDSLIDE-03', 'Landslide on NH-7 Pass', 'LANDSLIDE', 'HIGH', '12.9300', '80.1300', '850', '48', '6', 'SDRF-4WD-02', 'IN_PROGRESS', '2026-10-03 08:15:00'],
      ['INC-2026-COLLAPSE-02', 'Building Structural Collapse', 'BUILDING_COLLAPSE', 'CRITICAL', '13.0400', '80.2200', '400', '29', '4', '108-AMB-05', 'ASSIGNED', '2026-10-03 07:45:00'],
      ['INC-2026-CYCLONE-04', 'Cyclone Warning Coast Line', 'CYCLONE', 'MEDIUM', '12.9900', '80.1700', '5000', '19', '0', 'ARMY-HELI-01', 'OPEN', '2026-10-03 07:10:00'],
    ];

    return [headers.join(','), ...sampleRows.map(row => row.map(v => `"${v}"`).join(','))].join('\n');
  },

  getRecentReports: (): GeneratedReport[] => [
    {
      id: 'REP-CAP-001',
      name: 'OASIS CAP v1.2 National Alert XML Feed',
      type: 'CAP_XML',
      generatedAt: '10 min ago',
      fileSize: '42.8 KB',
      recordsCount: 18,
      downloadUrl: `${API_BASE_URL}/api/v1/interop/cap/feed.xml`,
      status: 'READY',
    },
    {
      id: 'REP-CAD-002',
      name: 'Computer-Aided Dispatch (CAD 112) JSON Feed',
      type: 'CAD_JSON',
      generatedAt: '14 min ago',
      fileSize: '78.2 KB',
      recordsCount: 18,
      downloadUrl: `${API_BASE_URL}/api/v1/interop/cad/incidents`,
      status: 'READY',
    },
    {
      id: 'REP-CSV-003',
      name: 'Master Incidents & Casualty Audit (CSV)',
      type: 'INCIDENT_CSV',
      generatedAt: '25 min ago',
      fileSize: '18.4 KB',
      recordsCount: 42,
      downloadUrl: '#',
      status: 'READY',
    },
    {
      id: 'REP-LOG-004',
      name: 'DTN Mesh Telemetry & Hop Ingestion Audit',
      type: 'TELEMETRY_LOG',
      generatedAt: '1 hour ago',
      fileSize: '2.4 MB',
      recordsCount: 12842,
      downloadUrl: '#',
      status: 'READY',
    },
  ],
};
