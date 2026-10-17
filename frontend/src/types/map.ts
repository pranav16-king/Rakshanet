import type { IncidentSeverity } from './dashboard';

export type DeviceStatus = 'Online' | 'Relay' | 'Offline';

export interface LiveDevice {
  id: string;
  name: string;
  location: string;
  relativeTime: string;
  status: DeviceStatus;
  battery: number;
  lat: number;
  lng: number;
  type: string;
  hops: number;
  lastPing: number;
}

export type MapNodeType = 'sos' | 'landslide' | 'flood' | 'rescue_team';

export interface MapIncidentNode {
  id: string;
  title: string;
  type: MapNodeType;
  badgeLabel: string;
  countLabel: string;
  lat: number;
  lng: number;
  severity: IncidentSeverity;
  userCount?: number;
  deviceCount?: number;
  radiusMeters?: number;
  polygonCoords?: [number, number][];
  description?: string;
  reportedAgo?: string;
}

export interface RescueTeam {
  id: string;
  name: string;
  teamType: string;
  leader?: string;
  contact?: string;
  membersCount: number;
  status: string;
  lat: number;
  lng: number;
  assignedIncidentId?: string | null;
  capabilities?: string[];
}

export interface DeviceStats {
  total: number;
  online: number;
  relay: number;
  offline: number;
}

export interface MapLayersState {
  users: boolean;
  nearbyDevices: boolean;
  incidents: boolean;
  rescueTeams: boolean;
  meshConnections: boolean;
  hazardZones: boolean;
}

export interface MapFilterState {
  searchQuery: string;
  incidentType: string;
  deviceType: string;
  status: string;
}
