export type DeviceType = 'Phone' | 'Tablet' | 'Relay Beacon' | 'Satellite Uplink';

export type DeviceStatus = 'Online' | 'Relay' | 'Offline';

export type DeviceTab = 'list' | 'topology' | 'logs';

export interface Device {
  id: string; // e.g. 'DEV-SAT-08'
  userName: string;
  type: DeviceType;
  location: string;
  battery: number; // 0-100 percentage
  status: DeviceStatus;
  meshHops: number;
  signalStrengthDbm: number; // e.g. -68 dBm
  lastPing: string;
  hardwareModel?: string;
  relayActive?: boolean;
  lat?: number;
  lng?: number;
  packetsForwarded?: number;
  ownerName?: string;
  lastSeenTimestamp?: number;
}

export interface DeviceSummaryMetrics {
  totalDevices: number;
  onlineCount: number;
  onlinePercent: number;
  relayCount: number;
  relayPercent: number;
  offlineCount: number;
  offlinePercent: number;
}

export interface NetworkTopologyNode {
  id: string;
  label: string;
  type: 'gateway' | 'relay' | 'client';
  status: DeviceStatus;
  battery: number;
  x: number;
  y: number;
  signalDbm: number;
  hops: number;
  connections: string[];
  hardwareType?: DeviceType;
  packetsForwarded?: number;
}

export interface ConnectionLog {
  id: string;
  timestamp: string;
  deviceId: string;
  userName: string;
  event: string;
  protocol: 'BLE Mesh' | 'LoRa P2P' | 'Wi-Fi Direct';
  hopCount: number;
  rssiDbm: number;
  status: 'Delivered' | 'Relayed' | 'Queued' | 'Dropped';
  packetType?: string;
}
