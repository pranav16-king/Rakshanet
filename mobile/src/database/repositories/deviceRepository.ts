import { dbManager } from '../sqlite';
import { NearbyDevice } from '@/types/device';

export class DeviceRepository {
  public async getAllNearby(): Promise<NearbyDevice[]> {
    const table = dbManager.getMockTable('nearby_devices');
    // Sort by most recently seen
    return [...table].sort((a, b) => b.lastSeen - a.lastSeen);
  }

  public async upsertDevice(device: NearbyDevice): Promise<void> {
    const table = dbManager.getMockTable('nearby_devices');
    const existingIndex = table.findIndex((d: NearbyDevice) => d.deviceId === device.deviceId);
    if (existingIndex >= 0) {
      table[existingIndex] = {
        ...table[existingIndex],
        ...device,
        lastSeen: Date.now(),
      };
    } else {
      table.push(device);
    }
    dbManager.setMockTable('nearby_devices', table);
  }

  public async getConnectedCount(): Promise<number> {
    const table = dbManager.getMockTable('nearby_devices');
    const cutoff = Date.now() - 30000; // active within 30s
    return table.filter((d: NearbyDevice) => d.isConnected && d.lastSeen > cutoff).length;
  }
}

export const deviceRepository = new DeviceRepository();
