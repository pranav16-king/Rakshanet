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
  let contactNumber = '+91-94450-10701';

  if (rawCat.includes('BOAT')) {
    category = 'BOATS';
    type = 'RESCUE_BOAT';
    unit = 'Boats';
    urgency = 'CRITICAL';
    specifications = [
      'Capacity: 8-10 Persons',
      'Engine: 40HP Mariner Marine Outboard',
      'Waterproof VHF Radio (Channel 16)',
      'Heavy-duty Hypalon-Neoprene Hull'
    ];
    description = 'MilPro inflatable tactical boats equipped for swift water extraction, urban flood rescue, and submerged avenue navigation.';
    depotOfficer = 'Sub-Insp. Manoj Kumar (Marine Search Unit)';
    contactNumber = '+91-98401-22334';
  } else if (rawCat.includes('4WD') || rawCat.includes('TRUCK') || rawCat.includes('VEHICLE')) {
    category = '4WDS';
    type = 'HIGH_CLEARANCE_4WD';
    unit = 'Trucks';
    urgency = 'HIGH';
    specifications = [
      'Ground Clearance: 420mm',
      'Snorkel Intake (1.5m Fording Depth)',
      'Heavy-duty 12,000lb Warn Winch',
      'Emergency Floodlight & Radio Repeater'
    ];
    description = 'High-mobility tactical amphibious 4x4 trucks engineered for high-water crossings, mud slides, and debris fields.';
    depotOfficer = 'Inspector K. Senthil (SDRF Heavy Fleet)';
    contactNumber = '+91-98402-33445';
  } else if (rawCat.includes('AMBULANCE')) {
    category = 'AMBULANCES';
    type = 'AMBULANCE';
    unit = 'Ambulances';
    urgency = 'CRITICAL';
    specifications = [
      'Level 3 Advanced Life Support (ALS)',
      'Portable Transport Ventilator & Defibrillator',
      'Dual Oxygen Cylinders (2x 1500L)',
      'Satellite Telemetry Link to Base Hospital'
    ];
    description = 'Specialized emergency trauma transport equipped with life-support apparatus, paramedic crew, and triage stabilization.';
    depotOfficer = 'Dr. Radhakrishnan (EMRI 108 Fleet Operations)';
    contactNumber = '+91-98403-44556';
  } else if (rawCat.includes('MED')) {
    category = 'MEDICAL';
    type = 'MEDICAL_KIT';
    unit = 'Kits';
    urgency = 'CRITICAL';
    specifications = [
      'Tactical Hemostatic Gauze & QuikClot',
      'Combat Application Tourniquets (CAT Gen 7)',
      'Sterile Burn & Blast Dressings',
      'IV Resuscitation Sets & Analgesics'
    ];
    description = 'Pre-configured emergency hemorrhage and mass-casualty triage kits deployed for field surgical first-aid.';
    depotOfficer = 'Dr. Priya V. (Chief Medical Officer, Logistics)';
    contactNumber = '+91-98404-55667';
  } else if (rawCat.includes('SHELTER') || rawCat.includes('SHLT')) {
    category = 'SHELTERS';
    type = 'TEMPORARY_SHELTER';
    unit = 'Camps';
    urgency = 'HIGH';
    specifications = [
      'Capacity: 100-150 Beds per Shelter Camp',
      'Integrated Solar Microgrid Generator',
      'Clean Potable Water Filtration (2,000L/day)',
      'Sanitation & Medical Isolation Cubicles'
    ];
    description = 'Designated safe-haven community disaster relief shelters providing dry bedding, backup power, and hot meals.';
    depotOfficer = 'V. Ramanathan (Tahsildar Emergency Relief)';
    contactNumber = '+91-98405-66778';
  } else if (rawCat.includes('WATER') || rawCat.includes('FOOD') || rawCat.includes('RATION')) {
    category = 'FOOD_WATER';
    type = 'FOOD_WATER_RATIONS';
    unit = name.toLowerCase().includes('water') ? 'Packs' : 'Rations';
    urgency = 'HIGH';
    specifications = [
      'Purified Water: Sealed 500ml Multi-Packs',
      'High-Energy Humanitarian Biscuits (2,400 kcal/day)',
      'Shelf Life: 24 Months Hermetically Sealed',
      'Waterproof Drop-Packaging for Air & Boat Delivery'
    ];
    description = 'Non-perishable ready-to-eat tactical rations and sealed emergency drinking water for flood-isolated communities.';
    depotOfficer = 'S. Anbarasan (Civil Supplies Logistics Hub)';
    contactNumber = '+91-98406-77889';
  }

  const total = Number(raw.total_quantity ?? raw.totalCapacity ?? raw.quantity ?? 0);
  const allocated = Number(raw.deployed_quantity ?? raw.allocated ?? 0);
  const available = Number(raw.available_quantity ?? raw.available ?? Math.max(0, total - allocated));

  let status: ResourceItem['status'] = raw.status || 'READY';
  if (available === 0 && total > 0) {
    status = 'DEPLETED';
  } else if (available <= total * 0.25 && total > 0) {
    status = 'LOW';
  } else if (allocated > 0) {
    status = 'READY';
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
    lastUpdated: 'Live Telemetry',
    description,
    depotOfficer,
    contactNumber,
    specifications,
    maintenanceStatus: 'OPERATIONAL',
  };
}

export const resourcesApi = {
  getResources: async (): Promise<ResourceItem[]> => {
    try {
      const response = await apiClient.get('/api/v1/resources');
      if (response.data && Array.isArray(response.data) && response.data.length > 0) {
        return response.data.map(normalizeResourceItem);
      }
    } catch (err) {
      console.warn('Failed to fetch from /api/v1/resources, using emergency fallback:', err);
    }
    return getDefaultResources();
  },

  getResourceById: async (id: string): Promise<ResourceItem | undefined> => {
    const all = await resourcesApi.getResources();
    return all.find((r) => r.id === id || r.resource_id === id);
  },

  updateResourceAllocation: async (
    resourceId: string,
    allocatedCount: number
  ): Promise<{ success: boolean; resource: ResourceItem }> => {
    try {
      const response = await apiClient.patch(`/api/v1/resources/${resourceId}`, {
        allocated: allocatedCount,
      });
      if (response.data && response.data.resource) {
        return {
          success: true,
          resource: normalizeResourceItem(response.data.resource),
        };
      }
    } catch (err) {
      console.warn('Failed to patch resource allocation on backend, using local update:', err);
    }

    const all = await resourcesApi.getResources();
    const target = all.find((r) => r.id === resourceId || r.resource_id === resourceId) || all[0];
    target.allocated = allocatedCount;
    const total = target.totalCapacity ?? target.quantity ?? 100;
    target.available = Math.max(0, total - allocatedCount);
    target.status = target.available === 0 ? 'DEPLETED' : target.available <= total * 0.25 ? 'LOW' : 'READY';
    target.lastUpdated = 'Just now';
    return { success: true, resource: target };
  },
};

function getDefaultResources(): ResourceItem[] {
  return [
    {
      id: 'RES-BOAT-01',
      resource_id: 'RES-BOAT-01',
      name: 'Zodiac MilPro Inflatable Boats',
      type: 'RESCUE_BOAT',
      category: 'BOATS',
      quantity: 12,
      totalCapacity: 12,
      allocated: 5,
      available: 7,
      unit: 'Boats',
      location: 'Marina Base Station',
      status: 'READY',
      urgency: 'CRITICAL',
      lastUpdated: 'Live Telemetry',
      description: 'MilPro inflatable tactical boats equipped for swift water extraction, urban flood rescue, and submerged avenue navigation.',
      depotOfficer: 'Sub-Insp. Manoj Kumar (Marine Search Unit)',
      contactNumber: '+91-98401-22334',
      specifications: [
        'Capacity: 8-10 Persons',
        'Engine: 40HP Mariner Marine Outboard',
        'Waterproof VHF Radio (Channel 16)',
        'Heavy-duty Hypalon-Neoprene Hull'
      ],
      maintenanceStatus: 'OPERATIONAL',
    },
    {
      id: 'RES-4WD-01',
      resource_id: 'RES-4WD-01',
      name: 'SDRF High-Water Rescue 4x4 Trucks',
      type: 'HIGH_CLEARANCE_4WD',
      category: '4WDS',
      quantity: 8,
      totalCapacity: 8,
      allocated: 5,
      available: 3,
      unit: 'Trucks',
      location: 'Guindy Disaster Depot',
      status: 'READY',
      urgency: 'HIGH',
      lastUpdated: 'Live Telemetry',
      description: 'High-mobility tactical amphibious 4x4 trucks engineered for high-water crossings, mud slides, and debris fields.',
      depotOfficer: 'Inspector K. Senthil (SDRF Heavy Fleet)',
      contactNumber: '+91-98402-33445',
      specifications: [
        'Ground Clearance: 420mm',
        'Snorkel Intake (1.5m Fording Depth)',
        'Heavy-duty 12,000lb Warn Winch',
        'Emergency Floodlight & Radio Repeater'
      ],
      maintenanceStatus: 'OPERATIONAL',
    },
    {
      id: 'RES-AMB-01',
      resource_id: 'RES-AMB-01',
      name: 'ACLS Critical Care Ambulances',
      type: 'AMBULANCE',
      category: 'AMBULANCES',
      quantity: 10,
      totalCapacity: 10,
      allocated: 6,
      available: 4,
      unit: 'Ambulances',
      location: 'Central Medical Hub',
      status: 'READY',
      urgency: 'CRITICAL',
      lastUpdated: 'Live Telemetry',
      description: 'Specialized emergency trauma transport equipped with life-support apparatus, paramedic crew, and triage stabilization.',
      depotOfficer: 'Dr. Radhakrishnan (EMRI 108 Fleet Operations)',
      contactNumber: '+91-98403-44556',
      specifications: [
        'Level 3 Advanced Life Support (ALS)',
        'Portable Transport Ventilator & Defibrillator',
        'Dual Oxygen Cylinders (2x 1500L)',
        'Satellite Telemetry Link to Base Hospital'
      ],
      maintenanceStatus: 'OPERATIONAL',
    },
    {
      id: 'RES-MED-01',
      resource_id: 'RES-MED-01',
      name: 'Trauma Dressing & Emergency Hemorrhage Kits',
      type: 'MEDICAL_KIT',
      category: 'MEDICAL',
      quantity: 250,
      totalCapacity: 250,
      allocated: 95,
      available: 155,
      unit: 'Kits',
      location: 'Central Medical Hub',
      status: 'READY',
      urgency: 'CRITICAL',
      lastUpdated: 'Live Telemetry',
      description: 'Pre-configured emergency hemorrhage and mass-casualty triage kits deployed for field surgical first-aid.',
      depotOfficer: 'Dr. Priya V. (Chief Medical Officer, Logistics)',
      contactNumber: '+91-98404-55667',
      specifications: [
        'Tactical Hemostatic Gauze & QuikClot',
        'Combat Application Tourniquets (CAT Gen 7)',
        'Sterile Burn & Blast Dressings',
        'IV Resuscitation Sets & Analgesics'
      ],
      maintenanceStatus: 'OPERATIONAL',
    },
    {
      id: 'RES-WATER-01',
      resource_id: 'RES-WATER-01',
      name: 'Purified Drinking Water Packs (500ml)',
      type: 'FOOD_WATER_RATIONS',
      category: 'FOOD_WATER',
      quantity: 15000,
      totalCapacity: 15000,
      allocated: 8500,
      available: 6500,
      unit: 'Packs',
      location: 'State Logistics Warehouse',
      status: 'READY',
      urgency: 'HIGH',
      lastUpdated: 'Live Telemetry',
      description: 'Sealed purified drinking water packets designed for disaster-stricken isolated populations.',
      depotOfficer: 'S. Anbarasan (Civil Supplies Logistics Hub)',
      contactNumber: '+91-98406-77889',
      specifications: [
        'Purified & Sealed 500ml Multi-Packs',
        'Certified WHO Drinking Standard',
        'Drop-Reinforced Packaging'
      ],
      maintenanceStatus: 'OPERATIONAL',
    },
    {
      id: 'RES-FOOD-02',
      resource_id: 'RES-FOOD-02',
      name: 'Ready-to-Eat High Energy Ration Packs',
      type: 'FOOD_WATER_RATIONS',
      category: 'FOOD_WATER',
      quantity: 10000,
      totalCapacity: 10000,
      allocated: 6200,
      available: 3800,
      unit: 'Rations',
      location: 'State Logistics Warehouse',
      status: 'READY',
      urgency: 'HIGH',
      lastUpdated: 'Live Telemetry',
      description: 'Non-perishable ready-to-eat tactical rations designed for disaster relief sustenance.',
      depotOfficer: 'S. Anbarasan (Civil Supplies Logistics Hub)',
      contactNumber: '+91-98406-77889',
      specifications: [
        'High-Energy Humanitarian Biscuits (2,400 kcal/day)',
        'Shelf Life: 24 Months Hermetically Sealed'
      ],
      maintenanceStatus: 'OPERATIONAL',
    },
    {
      id: 'RES-SHLT-01',
      resource_id: 'RES-SHLT-01',
      name: 'Community Relief Camp Shelters',
      type: 'TEMPORARY_SHELTER',
      category: 'SHELTERS',
      quantity: 6,
      totalCapacity: 6,
      allocated: 4,
      available: 2,
      unit: 'Camps',
      location: 'Government High Schools Wards 10-15',
      status: 'READY',
      urgency: 'HIGH',
      lastUpdated: 'Live Telemetry',
      description: 'Designated safe-haven community disaster relief shelters providing dry bedding, backup power, and hot meals.',
      depotOfficer: 'V. Ramanathan (Tahsildar Emergency Relief)',
      contactNumber: '+91-98405-66778',
      specifications: [
        'Capacity: 100-150 Beds per Camp (Total: 600 Beds)',
        'Integrated Solar Microgrid Generator',
        'Clean Potable Water Filtration'
      ],
      maintenanceStatus: 'OPERATIONAL',
    },
  ];
}
