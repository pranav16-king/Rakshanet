import { apiClient } from './client';
import type {
  Device,
  DeviceSummaryMetrics,
  NetworkTopologyNode,
  ConnectionLog,
  DeviceType,
  DeviceStatus,
} from '../types/devices';

const SUMMARY_METRICS: DeviceSummaryMetrics = {
  totalDevices: 326,
  onlineCount: 248,
  onlinePercent: 76,
  relayCount: 68,
  relayPercent: 21,
  offlineCount: 10,
  offlinePercent: 3,
};

const INITIAL_DEVICES: Device[] = [
  {
    id: 'SR-8F42',
    userName: 'Amit Kumar',
    type: 'Phone',
    location: 'Uttarakhand',
    battery: 85,
    status: 'Online',
    meshHops: 1,
    signalStrengthDbm: -58,
    lastPing: '20s ago',
    hardwareModel: 'Pixel 7a (BLE 5.3 + Wi-Fi Direct)',
    relayActive: false,
  },
  {
    id: 'SR-9A1C',
    userName: 'Priya Sharma',
    type: 'Phone',
    location: 'Uttarakhand',
    battery: 42,
    status: 'Relay',
    meshHops: 2,
    signalStrengthDbm: -74,
    lastPing: '45s ago',
    hardwareModel: 'Samsung Galaxy S22 (LoRa Hat + BLE)',
    relayActive: true,
  },
  {
    id: 'SR-3D7B',
    userName: 'Rahul Mehta',
    type: 'Phone',
    location: 'Himachal',
    battery: 76,
    status: 'Online',
    meshHops: 1,
    signalStrengthDbm: -62,
    lastPing: '1m ago',
    hardwareModel: 'OnePlus Nord CE (BLE 5.2)',
    relayActive: false,
  },
  {
    id: 'SR-6E2F',
    userName: 'Sneha Patel',
    type: 'Phone',
    location: 'Delhi',
    battery: 23,
    status: 'Offline',
    meshHops: 3,
    signalStrengthDbm: -98,
    lastPing: '14m ago',
    hardwareModel: 'Redmi Note 12 (BLE 5.0)',
    relayActive: false,
  },
  {
    id: 'SR-7G9H',
    userName: 'Vikram Singh',
    type: 'Tablet',
    location: 'Uttarakhand',
    battery: 89,
    status: 'Online',
    meshHops: 1,
    signalStrengthDbm: -51,
    lastPing: '15s ago',
    hardwareModel: 'Galaxy Tab Active 4 Pro (Dual Band Mesh)',
    relayActive: true,
  },
  {
    id: 'SR-4K2M',
    userName: 'Volunteer Team Alpha',
    type: 'Tablet',
    location: 'Uttarakhand',
    battery: 64,
    status: 'Relay',
    meshHops: 2,
    signalStrengthDbm: -69,
    lastPing: '30s ago',
    hardwareModel: 'iPad 10th Gen (Wi-Fi Direct Peer)',
    relayActive: true,
  },
  {
    id: 'SR-5L8P',
    userName: 'Ananya Gupta',
    type: 'Phone',
    location: 'Delhi',
    battery: 91,
    status: 'Online',
    meshHops: 1,
    signalStrengthDbm: -54,
    lastPing: '1m ago',
    hardwareModel: 'Pixel 8 (BLE 5.3 + Ultra Wideband)',
    relayActive: false,
  },
  {
    id: 'SR-1B9Q',
    userName: 'Dr. Farooq Sheikh',
    type: 'Phone',
    location: 'Himachal',
    battery: 15,
    status: 'Offline',
    meshHops: 4,
    signalStrengthDbm: -105,
    lastPing: '22m ago',
    hardwareModel: 'Motorola Edge 40 (LoRa Module)',
    relayActive: false,
  },
];

const TOPOLOGY_NODES: NetworkTopologyNode[] = [
  {
    id: 'GATEWAY-01',
    label: 'Command Gateway Base',
    type: 'gateway',
    status: 'Online',
    battery: 100,
    x: 480,
    y: 190,
    signalDbm: -40,
    hops: 0,
    connections: ['SR-8F42', 'SR-7G9H', 'SR-3D7B', 'SR-5L8P'],
  },
  {
    id: 'SR-8F42',
    label: 'Amit Kumar (SR-8F42)',
    type: 'client',
    status: 'Online',
    battery: 85,
    x: 280,
    y: 130,
    signalDbm: -58,
    hops: 1,
    connections: ['SR-9A1C', 'GATEWAY-01'],
  },
  {
    id: 'SR-9A1C',
    label: 'Priya Sharma [RELAY]',
    type: 'relay',
    status: 'Relay',
    battery: 42,
    x: 140,
    y: 220,
    signalDbm: -74,
    hops: 2,
    connections: ['SR-8F42'],
  },
  {
    id: 'SR-7G9H',
    label: 'Vikram Singh [RELAY]',
    type: 'relay',
    status: 'Online',
    battery: 89,
    x: 660,
    y: 120,
    signalDbm: -51,
    hops: 1,
    connections: ['GATEWAY-01', 'SR-4K2M'],
  },
  {
    id: 'SR-4K2M',
    label: 'Volunteer Team [RELAY]',
    type: 'relay',
    status: 'Relay',
    battery: 64,
    x: 810,
    y: 220,
    signalDbm: -69,
    hops: 2,
    connections: ['SR-7G9H'],
  },
  {
    id: 'SR-3D7B',
    label: 'Rahul Mehta (SR-3D7B)',
    type: 'client',
    status: 'Online',
    battery: 76,
    x: 350,
    y: 310,
    signalDbm: -62,
    hops: 1,
    connections: ['GATEWAY-01'],
  },
  {
    id: 'SR-5L8P',
    label: 'Ananya Gupta (SR-5L8P)',
    type: 'client',
    status: 'Online',
    battery: 91,
    x: 610,
    y: 310,
    signalDbm: -54,
    hops: 1,
    connections: ['GATEWAY-01', 'SR-6E2F'],
  },
  {
    id: 'SR-6E2F',
    label: 'Sneha Patel (SR-6E2F)',
    type: 'client',
    status: 'Offline',
    battery: 23,
    x: 740,
    y: 380,
    signalDbm: -98,
    hops: 3,
    connections: ['SR-5L8P'],
  },
];

const CONNECTION_LOGS: ConnectionLog[] = [
  {
    id: 'log-101',
    timestamp: '14:24:12',
    deviceId: 'SR-8F42',
    userName: 'Amit Kumar',
    event: 'Mesh Ping Acknowledged via Direct BLE Hop',
    protocol: 'BLE Mesh',
    hopCount: 1,
    rssiDbm: -58,
    status: 'Delivered',
  },
  {
    id: 'log-102',
    timestamp: '14:23:48',
    deviceId: 'SR-9A1C',
    userName: 'Priya Sharma',
    event: 'Packet Relayed forward for downstream node SR-8F42',
    protocol: 'LoRa P2P',
    hopCount: 2,
    rssiDbm: -74,
    status: 'Relayed',
  },
  {
    id: 'log-103',
    timestamp: '14:22:15',
    deviceId: 'SR-7G9H',
    userName: 'Vikram Singh',
    event: 'High-throughput Wi-Fi Direct mesh cluster sync',
    protocol: 'Wi-Fi Direct',
    hopCount: 1,
    rssiDbm: -51,
    status: 'Delivered',
  },
  {
    id: 'log-104',
    timestamp: '14:21:05',
    deviceId: 'SR-4K2M',
    userName: 'Volunteer Team Alpha',
    event: 'Sub-mesh heartbeat broadcast received',
    protocol: 'BLE Mesh',
    hopCount: 2,
    rssiDbm: -69,
    status: 'Relayed',
  },
  {
    id: 'log-105',
    timestamp: '14:18:22',
    deviceId: 'SR-6E2F',
    userName: 'Sneha Patel',
    event: 'Connection timeout after 3 retransmission attempts',
    protocol: 'BLE Mesh',
    hopCount: 3,
    rssiDbm: -98,
    status: 'Dropped',
  },
  {
    id: 'log-106',
    timestamp: '14:15:09',
    deviceId: 'SR-1B9Q',
    userName: 'Dr. Farooq Sheikh',
    event: 'Radio link silent - device powered down or shadowed',
    protocol: 'LoRa P2P',
    hopCount: 4,
    rssiDbm: -105,
    status: 'Dropped',
  },
];

let localDevices = [...INITIAL_DEVICES];

export const devicesApi = {
  getSummaryMetrics: async (): Promise<DeviceSummaryMetrics> => {
    try {
      const response = await apiClient.get<DeviceSummaryMetrics>('/devices/summary');
      return response.data;
    } catch {
      return SUMMARY_METRICS;
    }
  },

  getDevices: async (
    typeFilter: string = 'All',
    statusFilter: string = 'All',
    searchQuery: string = ''
  ): Promise<Device[]> => {
    try {
      const response = await apiClient.get<Device[]>('/devices', {
        params: { type: typeFilter, status: statusFilter, q: searchQuery },
      });
      return response.data;
    } catch {
      let filtered = [...localDevices];

      if (typeFilter && typeFilter !== 'All') {
        filtered = filtered.filter((d) => d.type.toLowerCase() === typeFilter.toLowerCase());
      }

      if (statusFilter && statusFilter !== 'All') {
        filtered = filtered.filter((d) => d.status.toLowerCase() === statusFilter.toLowerCase());
      }

      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase();
        filtered = filtered.filter(
          (d) =>
            d.id.toLowerCase().includes(q) ||
            d.userName.toLowerCase().includes(q) ||
            d.location.toLowerCase().includes(q)
        );
      }

      return filtered;
    }
  },

  getTopology: async (): Promise<NetworkTopologyNode[]> => {
    try {
      const response = await apiClient.get<NetworkTopologyNode[]>('/devices/topology');
      return response.data;
    } catch {
      return TOPOLOGY_NODES;
    }
  },

  getConnectionLogs: async (): Promise<ConnectionLog[]> => {
    try {
      const response = await apiClient.get<ConnectionLog[]>('/devices/logs');
      return response.data;
    } catch {
      return CONNECTION_LOGS;
    }
  },

  pingDevice: async (deviceId: string): Promise<{ success: boolean; latencyMs: number }> => {
    try {
      const response = await apiClient.post<{ success: boolean; latencyMs: number }>(
        `/devices/${deviceId}/ping`
      );
      return response.data;
    } catch {
      return {
        success: true,
        latencyMs: Math.floor(Math.random() * 45) + 15,
      };
    }
  },
};

export default devicesApi;
