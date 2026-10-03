export type ResourceType = 
  | 'RESCUE_BOAT' 
  | 'MEDICAL_KIT' 
  | 'FOOD_WATER_RATIONS' 
  | 'TEMPORARY_SHELTER' 
  | 'SATELLITE_PHONE' 
  | 'GENERATOR' 
  | 'DRONE'
  | string;

export type ResourceStatus = 'AVAILABLE' | 'DEPLETED' | 'LOW' | 'ALLOCATED' | 'READY' | string;

export interface Resource {
  id: string;
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
}

export type ResourceItem = Resource;
