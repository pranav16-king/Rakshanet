export type ConnectionType = 'BLE' | 'WIFI_DIRECT';

export type ProximityBand = 'IMMEDIATE' | 'NEAR' | 'FAR';

export interface NearbyDevice {
  id: string;
  deviceId: string; // e.g. "SR-39B1-28FF"
  displayName: string;
  connectionType: ConnectionType;
  signalStrength: number; // RSSI dBm, e.g. -68
  proximityBand: ProximityBand;
  lastSeen: number; // Unix timestamp ms
  firstSeen: number;
  isConnected: boolean;
  hopCount: number; // 1 for direct RF peer, 2+ for relayed
  batteryLevel?: number;
}
