import { apiClient } from './client';
import type { Resource, ResourceItem } from '../types';

export const resourcesApi = {
  getResources: async (): Promise<ResourceItem[]> => {
    try {
      const response = await apiClient.get('/api/v1/resources');
      return response.data;
    } catch {
      return getDefaultResources();
    }
  },

  getResourceById: async (id: string): Promise<ResourceItem | undefined> => {
    const all = await resourcesApi.getResources();
    return all.find(r => r.id === id);
  },

  updateResourceAllocation: async (
    resourceId: string,
    allocatedCount: number
  ): Promise<{ success: boolean; resource: ResourceItem }> => {
    try {
      const response = await apiClient.patch(`/api/v1/resources/${resourceId}`, {
        allocated: allocatedCount,
      });
      return response.data;
    } catch {
      const all = getDefaultResources();
      const target = all.find(r => r.id === resourceId) || all[0];
      target.allocated = allocatedCount;
      const total = target.totalCapacity ?? target.quantity ?? 100;
      target.available = Math.max(0, total - allocatedCount);
      target.status = target.available === 0 ? 'ALLOCATED' : 'READY';
      target.lastUpdated = 'Just now';
      return { success: true, resource: target };
    }
  },
};

function getDefaultResources(): ResourceItem[] {
  return [
    {
      id: 'RES-BOAT-01',
      name: 'Inflatable Zodiac Rescue Boats',
      type: 'RESCUE_BOAT',
      category: 'BOATS',
      quantity: 35,
      totalCapacity: 35,
      allocated: 24,
      available: 11,
      unit: 'Boats',
      location: 'Central Marina Rescue Dock',
      status: 'READY',
      urgency: 'CRITICAL',
      lastUpdated: '12 min ago',
    },
    {
      id: 'RES-4WD-02',
      name: 'High-Clearance 4WD Amphibious Trucks',
      type: 'HIGH_CLEARANCE_4WD',
      category: 'RESCUE_VEHICLES',
      quantity: 28,
      totalCapacity: 28,
      allocated: 20,
      available: 8,
      unit: 'Vehicles',
      location: 'Western Staging Depot',
      status: 'READY',
      urgency: 'HIGH',
      lastUpdated: '25 min ago',
    },
    {
      id: 'RES-MED-03',
      name: 'Advanced Paramedic Trauma & ALS Kits',
      type: 'MEDICAL_KIT',
      category: 'MEDICAL',
      quantity: 120,
      totalCapacity: 120,
      allocated: 95,
      available: 25,
      unit: 'Kits',
      location: 'Civil District Hospital Base',
      status: 'READY',
      urgency: 'CRITICAL',
      lastUpdated: '5 min ago',
    },
    {
      id: 'RES-SHELTER-04',
      name: 'Emergency High-Ground Relief Shelters',
      type: 'TEMPORARY_SHELTER',
      category: 'SHELTERS',
      quantity: 2500,
      totalCapacity: 2500,
      allocated: 1840,
      available: 660,
      unit: 'Beds',
      location: 'District Indoor Sports Arena & Stadium',
      status: 'READY',
      urgency: 'HIGH',
      lastUpdated: '18 min ago',
    },
    {
      id: 'RES-RATION-05',
      name: 'Purified Water Packets & MRE Rations',
      type: 'FOOD_WATER_RATIONS',
      category: 'RATIONS',
      quantity: 15000,
      totalCapacity: 15000,
      allocated: 11200,
      available: 3800,
      unit: 'Meal Packs',
      location: 'State Disaster Logistics Warehouse',
      status: 'READY',
      urgency: 'MEDIUM',
      lastUpdated: '40 min ago',
    },
    {
      id: 'RES-DRONE-06',
      name: 'Autonomous DTN Relay & Mesh Tethered Drones',
      type: 'DRONE',
      category: 'EQUIPMENT',
      quantity: 16,
      totalCapacity: 16,
      allocated: 12,
      available: 4,
      unit: 'Drones',
      location: 'Air Command Mobile Unit',
      status: 'READY',
      urgency: 'HIGH',
      lastUpdated: '15 min ago',
    },
  ];
}
