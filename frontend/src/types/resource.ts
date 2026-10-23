export type ResourceType = 
  | 'RESCUE_BOAT' 
  | 'HIGH_CLEARANCE_4WD'
  | 'AMBULANCE'
  | 'MEDICAL_KIT' 
  | 'FOOD_WATER_RATIONS' 
  | 'TEMPORARY_SHELTER' 
  | 'SATELLITE_PHONE' 
  | 'GENERATOR' 
  | 'DRONE'
  | 'EQUIPMENT'
  | string;

export type ResourceStatus = 'AVAILABLE' | 'DEPLETED' | 'LOW' | 'ALLOCATED' | 'READY' | 'DEPLOYED' | string;

export interface Resource {
  id: string;
  resource_id?: string;
  name: string;
  type: ResourceType;
  category?: string;
  quantity: number;
  available: number;
  totalCapacity?: number;
  allocated?: number;
  unit: string;
  urgency?: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL' | string;
  location: any; // supports string or object { lat, lng, facilityName }
  status: ResourceStatus;
  allocatedToIncidentId?: string | null;
  lastRestocked?: string;
  lastUpdated?: string;
  description?: string;
  depotOfficer?: string;
  contactNumber?: string;
  specifications?: string[];
  assignedIncidents?: string[];
  maintenanceStatus?: 'OPERATIONAL' | 'STANDBY' | 'MAINTENANCE';
}

export type ResourceItem = Resource;
