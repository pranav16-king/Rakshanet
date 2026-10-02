import { create } from 'zustand';
import { NearbyDevice } from '@/types/device';
import { NetworkState } from '@/types/network';
import { deviceRepository } from '@/database/repositories/deviceRepository';

interface NetworkStoreState extends NetworkState {
  nearbyDevices: NearbyDevice[];
  loadNearbyDevices: () => Promise<void>;
  addOrUpdateDevice: (device: NearbyDevice) => void;
  setMeshState: (state: NetworkState['meshState']) => void;
  setInternetOnline: (online: boolean) => void;
  setGpsFix: (fix: NetworkState['gpsFix']) => void;
  setBatteryLevel: (level: number) => void;
}

export const useNetworkStore = create<NetworkStoreState>((set) => ({
  internetOnline: false,
  meshState: 'SEARCHING',
  bluetoothEnabled: true,
  wifiEnabled: true,
  gpsFix: 'GOOD',
  batteryLevel: 82,
  isCharging: false,
  activeRadioMode: 'NORMAL',
  connectedPeerCount: 0,
  relayedHopCount: 0,
  pendingQueueCount: 0,
  nearbyDevices: [],

  loadNearbyDevices: async () => {
    const devices = await deviceRepository.getAllNearby();
    const connectedCount = await deviceRepository.getConnectedCount();
    set({
      nearbyDevices: devices,
      connectedPeerCount: connectedCount,
      meshState: devices.length > 0 ? 'CONNECTED' : 'SEARCHING',
    });
  },

  addOrUpdateDevice: (device: NearbyDevice) => {
    set((state) => {
      const existing = state.nearbyDevices.findIndex((d) => d.deviceId === device.deviceId);
      let updated: NearbyDevice[];
      if (existing >= 0) {
        updated = [...state.nearbyDevices];
        updated[existing] = device;
      } else {
        updated = [device, ...state.nearbyDevices];
      }
      return {
        nearbyDevices: updated,
        connectedPeerCount: updated.filter((d) => d.isConnected).length,
        meshState: 'CONNECTED',
      };
    });
  },

  setMeshState: (meshState) => set({ meshState }),
  setInternetOnline: (internetOnline) => set({ internetOnline }),
  setGpsFix: (gpsFix) => set({ gpsFix }),
  setBatteryLevel: (batteryLevel) => set({ batteryLevel }),
}));
