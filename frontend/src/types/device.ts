export type DeviceStatus = 'ONLINE' | 'OFFLINE' | 'RELAY' | 'SEARCHING';

export type DeviceType = 'PHONE' | 'TABLET' | 'MULE' | 'GATEWAY' | 'BEACON' | 'SATELLITE_UPLINK';

export interface Device {
  id: string; // e.g. 'SR-8F42'
  name: string;
  userName?: string;
  type: DeviceType;
  status: DeviceStatus;
  batteryPercentage: number;
  hops: number;
  location?: {
    lat: number;
    lng: number;
    region?: string;
  };
  lastSeen: string | number;
  meshConnected: boolean;
  role: 'EDGE_NODE' | 'DATA_MULE' | 'GATEWAY_BASE' | 'RELAY';
  packetsRelayedCount?: number;
}
