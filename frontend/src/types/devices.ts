export type DeviceType = 'Phone' | 'Tablet' | 'Relay Beacon' | 'Satellite Uplink' | 'Unknown';
export type DeviceStatus = 'Online' | 'Relay' | 'Offline' | 'Reported';
export type DeviceTab = 'list' | 'topology' | 'logs';

export interface Device { id: string; userName: string; type: DeviceType; location: string; battery?: number; status: DeviceStatus; meshHops?: number; signalStrengthDbm?: number; lastPing: string; hardwareModel?: string; relayActive?: boolean; lat?: number; lng?: number; packetsForwarded?: number; ownerName?: string; lastSeenTimestamp?: number; }
export interface DeviceSummaryMetrics { totalDevices: number; onlineCount: number; onlinePercent: number; relayCount: number; relayPercent: number; offlineCount: number; offlinePercent: number; }
export interface NetworkTopologyNode { id: string; label: string; type: 'gateway' | 'relay' | 'client'; status: DeviceStatus; battery?: number; x: number; y: number; signalDbm?: number; hops?: number; connections: string[]; hardwareType?: DeviceType; packetsForwarded?: number; }
export interface ConnectionLog { id: string; timestamp: string; deviceId: string; userName: string; event: string; protocol: string; hopCount?: number; rssiDbm?: number; status: 'Ingested'; packetType?: string; }
