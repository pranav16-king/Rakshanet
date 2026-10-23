import { apiClient } from './client';
import type { ResourceItem } from '../types';

export function normalizeResourceItem(raw: any): ResourceItem {
  const id = String(raw.resource_id || raw.id || 'RES-01');
  const name = String(raw.name || 'Emergency Relief Asset');
  const rawCat = String(raw.category || raw.type || '').toUpperCase();

  let category = 'EQUIPMENT';
  let type: ResourceItem['type'] = 'EQUIPMENT';
  let unit = 'Units';
  let urgency: ResourceItem['urgency'] = 'MEDIUM';
  let specifications: string[] = [];
  let description = '';
  let depotOfficer = 'State Emergency Logistics Operations';
  let contactNumber = '';

  if (rawCat.includes('BOAT')) {
    category = 'BOATS';
    type = 'RESCUE_BOAT';
    unit = 'Boats';
    urgency = 'CRITICAL';
    specifications = [
      'Capacity: 8-10 Persons',
      'Engine: 40HP Marine Outboard',
      'Waterproof VHF Radio (Channel 16)',
      'Heavy-duty Hull',
    ];
    description = 'Inflatable tactical boats for swift water extraction and urban flood rescue.';
  } else if (rawCat.includes('4WD') || rawCat.includes('TRUCK') || rawCat.includes('VEHICLE')) {
    category = '4WDS';
    type = 'HIGH_CLEARANCE_4WD';
    unit = 'Trucks';
    urgency = 'HIGH';
    specifications = [
      'High Ground Clearance',
      'Heavy-duty Winch',
      'Emergency Floodlight & Radio Repeater',
    ];
    description = 'High-mobility 4x4 trucks for high-water crossings, mud slides, and debris fields.';
  } else if (rawCat.includes('AMBULANCE')) {
    category = 'AMBULANCES';
    type = 'AMBULANCE';
    unit = 'Ambulances';
    urgency = 'CRITICAL';
    specifications = [
      'Advanced Life Support (ALS)',
      'Transport Ventilator & Defibrillator',
      'Oxygen Cylinders',
    ];
    description = 'Emergency trauma transport with life-support apparatus and paramedic crew.';
  } else if (rawCat.includes('MED')) {
    category = 'MEDICAL';
    type = 'MEDICAL_KIT';
    unit = 'Kits';
    urgency = 'CRITICAL';
    specifications = [
      'Hemostatic Gauze & QuikClot',
      'Application Tourniquets',
      'Burn & Blast Dressings',
      'IV Resuscitation Sets',
    ];
    description = 'Emergency hemorrhage and mass-casualty triage kits for field surgical first-aid.';
  } else if (rawCat.includes('SHELTER') || rawCat.includes('SHLT')) {
    category = 'SHELTERS';
    type = 'TEMPORARY_SHELTER';
    unit = 'Camps';
    urgency = 'HIGH';
    specifications = [
      'Capacity: 100-150 Beds per Camp',
      'Solar Microgrid Generator',
      'Water Filtration',
      'Sanitation Cubicles',
    ];
    description = 'Safe-haven community disaster relief shelters with backup power and meals.';
  } else if (rawCat.includes('WATER') || rawCat.includes('FOOD') || rawCat.includes('RATION')) {
    category = 'FOOD_WATER';
    type = 'FOOD_WATER_RATIONS';
    unit = name.toLowerCase().includes('water') ? 'Packs' : 'Rations';
    urgency = 'HIGH';
    specifications = [
      'Purified Sealed Water Packs',
      'High-Energy Rations',
      'Shelf Life: 24 Months Hermetically Sealed',
    ];
    description = 'Non-perishable rations and sealed drinking water for isolated communities.';
  }

  const total = Number(raw.total_quantity ?? raw.totalCapacity ?? raw.quantity ?? 0);
  const allocated = Number(raw.deployed_quantity ?? raw.allocated ?? 0);
  const available = Number(raw.available_quantity ?? raw.available ?? Math.max(0, total - allocated));

  let status: ResourceItem['status'] = raw.status || 'READY';
  if (available === 0 && total > 0) {
    status = 'DEPLETED';
  } else if (available <= total * 0.25 && total > 0) {
    status = 'LOW';
  } else {
    status = 'READY';
  }

  return {
    id,
    resource_id: id,
    name,
    category,
    type,
    quantity: total,
    totalCapacity: total,
    allocated,
    available,
    unit: raw.unit || unit,
    location: raw.location || 'Central Disaster Logistics Depot',
    status,
    urgency,
    lastUpdated: 'Live',
    description: raw.description || description,
    depotOfficer: raw.depot_officer || raw.depotOfficer || depotOfficer,
    contactNumber: raw.contact_number || raw.contactNumber || contactNumber,
    specifications: raw.specifications || specifications,
    maintenanceStatus: raw.maintenance_status || 'OPERATIONAL',
  };
}

export const resourcesApi = {
  getResources: async (): Promise<ResourceItem[]> => {
    try {
      const response = await apiClient.get('/api/v1/resources');
      if (response.data && Array.isArray(response.data) && response.data.length > 0) {
        return response.data.map(normalizeResourceItem);
      }
      return [];
    } catch (err) {
      console.warn('Failed to fetch from /api/v1/resources:', err);
      return [];
    }
  },

  getResourceById: async (id: string): Promise<ResourceItem | undefined> => {
    const all = await resourcesApi.getResources();
    return all.find((r) => r.id === id || r.resource_id === id);
  },

  updateResourceAllocation: async (
    resourceId: string,
    allocatedCount: number
  ): Promise<{ success: boolean; resource: ResourceItem }> => {
    const response = await apiClient.patch(`/api/v1/resources/${resourceId}`, {
      allocated: allocatedCount,
    });
    if (response.data && response.data.resource) {
      return {
        success: true,
        resource: normalizeResourceItem(response.data.resource),
      };
    }
    throw new Error('Resource allocation update failed — no resource returned from backend.');
  },
};
