export type TeamStatus = 'AVAILABLE' | 'DEPLOYED' | 'EN_ROUTE' | 'STANDBY';

export type TeamType = 'BOAT' | 'HIGH_CLEARANCE_4WD' | 'AMBULANCE' | 'HELICOPTER' | 'FOOT_PATROL' | 'DRONE_RECON';

export type UnitStatus = TeamStatus | string;
export type UnitType = TeamType | string;

export interface TeamMember {
  id: string;
  name: string;
  role: string;
  phone?: string;
}

export interface Team {
  id: string; // e.g. 'NDRF-BOAT-01'
  name: string;
  type: TeamType;
  status: TeamStatus;
  capacity: number;
  speedKmh?: number;
  location: {
    lat: number;
    lng: number;
    address?: string;
  };
  capabilities: string[];
  members?: TeamMember[];
  assignedIncidentId?: string | null;
  currentEtaMinutes?: number;
}
