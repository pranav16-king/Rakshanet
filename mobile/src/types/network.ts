export type MeshState = 'CONNECTED' | 'SEARCHING' | 'OFF' | 'ERROR';

export type RadioMode = 'NORMAL' | 'LOW_POWER' | 'EMERGENCY';

export interface NetworkState {
  internetOnline: boolean;
  meshState: MeshState;
  bluetoothEnabled: boolean;
  wifiEnabled: boolean;
  gpsFix: 'GOOD' | 'LAST_KNOWN' | 'OFF';
  batteryLevel: number; // 0 to 100
  isCharging: boolean;
  activeRadioMode: RadioMode;
  connectedPeerCount: number;
  relayedHopCount: number;
  pendingQueueCount: number;
}
