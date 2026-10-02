import { NativeModules, NativeEventEmitter, Platform } from 'react-native';
import { NearbyDevice } from '@/types/device';
import { NetworkPacket } from '@/types/chat';

const { RakshaNetBluetooth } = NativeModules;

export type DeviceDiscoveredCallback = (device: NearbyDevice) => void;
export type PacketReceivedCallback = (packet: NetworkPacket) => void;

export class BluetoothService {
  private eventEmitter: NativeEventEmitter | null = null;
  private isScanning = false;
  private isAdvertising = false;

  private onDeviceDiscoveredCallbacks: DeviceDiscoveredCallback[] = [];
  private onPacketReceivedCallbacks: PacketReceivedCallback[] = [];

  constructor() {
    if (RakshaNetBluetooth) {
      this.eventEmitter = new NativeEventEmitter(RakshaNetBluetooth);
      this.eventEmitter.addListener('onDeviceDiscovered', (device: NearbyDevice) => {
        this.onDeviceDiscoveredCallbacks.forEach((cb) => cb(device));
      });
      this.eventEmitter.addListener('onPacketReceived', (packet: NetworkPacket) => {
        this.onPacketReceivedCallbacks.forEach((cb) => cb(packet));
      });
    }
  }

  public async startMesh(deviceId: string, displayName: string): Promise<void> {
    if (RakshaNetBluetooth) {
      await RakshaNetBluetooth.startMesh(deviceId, displayName);
      this.isScanning = true;
      this.isAdvertising = true;
    } else {
      console.log('[BluetoothService] Simulating mesh radio on non-native platform');
      this.isScanning = true;
      this.isAdvertising = true;
      this.simulateNearbyEnvironment();
    }
  }

  public async stopMesh(): Promise<void> {
    if (RakshaNetBluetooth) {
      await RakshaNetBluetooth.stopMesh();
    }
    this.isScanning = false;
    this.isAdvertising = false;
  }

  public async sendPacket(packet: NetworkPacket): Promise<boolean> {
    if (RakshaNetBluetooth) {
      return await RakshaNetBluetooth.broadcastPacket(JSON.stringify(packet));
    } else {
      console.log('[BluetoothService] Transmitting packet over simulated radio:', packet.msg_id);
      return true;
    }
  }

  public subscribeDeviceDiscovered(cb: DeviceDiscoveredCallback): () => void {
    this.onDeviceDiscoveredCallbacks.push(cb);
    return () => {
      this.onDeviceDiscoveredCallbacks = this.onDeviceDiscoveredCallbacks.filter((c) => c !== cb);
    };
  }

  public subscribePacketReceived(cb: PacketReceivedCallback): () => void {
    this.onPacketReceivedCallbacks.push(cb);
    return () => {
      this.onPacketReceivedCallbacks = this.onPacketReceivedCallbacks.filter((c) => c !== cb);
    };
  }

  private simulateNearbyEnvironment() {
    // Development simulator: discovers simulated peers
    setTimeout(() => {
      const mockPeers: NearbyDevice[] = [
        {
          id: 'dev_1',
          deviceId: 'SR-7B14-99D2',
          displayName: 'Rahul (Field Responder)',
          connectionType: 'BLE',
          signalStrength: -58,
          proximityBand: 'NEAR',
          lastSeen: Date.now(),
          firstSeen: Date.now() - 120000,
          isConnected: true,
          hopCount: 1,
          batteryLevel: 68,
        },
        {
          id: 'dev_2',
          deviceId: 'SR-4F91-10AA',
          displayName: 'Ananya',
          connectionType: 'BLE',
          signalStrength: -78,
          proximityBand: 'FAR',
          lastSeen: Date.now() - 5000,
          firstSeen: Date.now() - 300000,
          isConnected: true,
          hopCount: 2,
          batteryLevel: 42,
        },
      ];

      mockPeers.forEach((p) => {
        this.onDeviceDiscoveredCallbacks.forEach((cb) => cb(p));
      });
    }, 1500);
  }
}

export const bluetoothService = new BluetoothService();
