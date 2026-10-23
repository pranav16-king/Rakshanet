import { apiClient } from './client';
import type { ConnectionLog, Device, DeviceStatus, DeviceSummaryMetrics, DeviceType, NetworkTopologyNode } from '../types/devices';

const EMPTY_METRICS: DeviceSummaryMetrics = { totalDevices: 0, onlineCount: 0, onlinePercent: 0, relayCount: 0, relayPercent: 0, offlineCount: 0, offlinePercent: 0 };
const isNumber = (value: unknown): value is number => typeof value === 'number' && Number.isFinite(value);

function formatTimeAgo(timestamp?: unknown): string {
  if (!isNumber(timestamp) && typeof timestamp !== 'string') return 'Not reported';
  const time = typeof timestamp === 'string' ? Date.parse(timestamp) : timestamp;
  if (!Number.isFinite(time)) return 'Not reported';
  const diff = Math.max(0, Math.floor((Date.now() - time) / 1000));
  if (diff < 60) return 'Just now';
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
  return `${Math.floor(diff / 86400)}d ago`;
}

function deviceType(value: unknown): DeviceType {
  const raw = String(value ?? '').toLowerCase();
  if (raw.includes('tablet')) return 'Tablet';
  if (raw.includes('satellite') || raw.includes('uplink') || raw.includes('gateway')) return 'Satellite Uplink';
  if (raw.includes('beacon') || raw.includes('repeater') || raw.includes('relay')) return 'Relay Beacon';
  if (raw.includes('phone')) return 'Phone';
  return 'Unknown';
}
function deviceStatus(value: unknown): DeviceStatus {
  const raw = String(value ?? '').toLowerCase();
  if (raw === 'online') return 'Online';
  if (raw === 'relay') return 'Relay';
  if (raw === 'offline') return 'Offline';
  return 'Reported';
}
function coordinateLabel(lat: unknown, lng: unknown): string {
  return isNumber(lat) && isNumber(lng) ? `${lat.toFixed(4)}°, ${lng.toFixed(4)}°` : 'Location unavailable';
}

export const devicesApi = {
  async getSummaryMetrics(): Promise<DeviceSummaryMetrics> {
    try {
      const { data } = await apiClient.get<any>('/api/v1/devices/stats');
      if (!data || !isNumber(data.total)) return EMPTY_METRICS;
      const total = data.total;
      const online = isNumber(data.online) ? data.online : 0;
      const relay = isNumber(data.relay) ? data.relay : 0;
      const offline = isNumber(data.offline) ? data.offline : 0;
      return { totalDevices: total, onlineCount: online, relayCount: relay, offlineCount: offline, onlinePercent: total ? Math.round((online / total) * 100) : 0, relayPercent: total ? Math.round((relay / total) * 100) : 0, offlinePercent: total ? Math.round((offline / total) * 100) : 0 };
    } catch { return EMPTY_METRICS; }
  },
  async getDevices(typeFilter = 'All', statusFilter = 'All', searchQuery = ''): Promise<Device[]> {
    try {
      const { data } = await apiClient.get<any[]>('/api/v1/devices');
      const mapped = (Array.isArray(data) ? data : []).flatMap((raw): Device[] => {
        if (!raw?.device_id && !raw?.id) return [];
        const id = String(raw.device_id ?? raw.id);
        const lat = isNumber(raw.lat) ? raw.lat : undefined;
        const lng = isNumber(raw.lng) ? raw.lng : undefined;
        return [{ id, userName: String(raw.owner_name ?? raw.name ?? id), ownerName: typeof raw.owner_name === 'string' ? raw.owner_name : undefined, type: deviceType(raw.device_type ?? raw.type), location: coordinateLabel(lat, lng), battery: isNumber(raw.battery_pct) ? raw.battery_pct : undefined, status: deviceStatus(raw.status), meshHops: isNumber(raw.hops_away) ? raw.hops_away : undefined, signalStrengthDbm: isNumber(raw.signal_dbm) ? raw.signal_dbm : undefined, lastPing: formatTimeAgo(raw.last_seen), lastSeenTimestamp: isNumber(raw.last_seen) ? raw.last_seen : undefined, hardwareModel: typeof raw.hardware_model === 'string' ? raw.hardware_model : undefined, relayActive: raw.relay_active === true, lat, lng, packetsForwarded: isNumber(raw.packets_forwarded) ? raw.packets_forwarded : undefined }];
      });
      const query = searchQuery.trim().toLowerCase();
      return mapped.filter((device) => (typeFilter === 'All' || device.type === typeFilter) && (statusFilter === 'All' || device.status === statusFilter) && (!query || [device.id, device.userName, device.ownerName, device.location].filter(Boolean).some((value) => value!.toLowerCase().includes(query))));
    } catch { return []; }
  },
  // The gateway does not expose verified neighbour edges. Do not infer topology from hop counts or locations.
  async getTopology(): Promise<NetworkTopologyNode[]> { return []; },
  async getConnectionLogs(): Promise<ConnectionLog[]> {
    try {
      const { data } = await apiClient.get<any>('/api/v1/telemetry/packets', { params: { limit: 40 } });
      const packets = Array.isArray(data) ? data : data?.packets;
      return (Array.isArray(packets) ? packets : []).flatMap((packet): ConnectionLog[] => {
        const id = packet?.msg_id;
        const senderId = packet?.sender_id ?? packet?.mule_device_id;
        if (!id || !senderId) return [];
        return [{ id: String(id), timestamp: formatTimeAgo(packet.timestamp ?? packet.created_at), deviceId: String(senderId), userName: String(packet.sender_name ?? senderId), event: String(packet.packet_type ?? 'UNKNOWN'), protocol: typeof packet.protocol === 'string' ? packet.protocol : 'Not reported', hopCount: isNumber(packet.hops) ? packet.hops : undefined, rssiDbm: isNumber(packet.rssi_dbm) ? packet.rssi_dbm : undefined, status: 'Ingested', packetType: typeof packet.packet_type === 'string' ? packet.packet_type : undefined }];
      });
    } catch { return []; }
  },
  async pingDevice(_deviceId: string): Promise<{ success: false; latencyMs: null; message: string }> {
    return { success: false, latencyMs: null, message: 'The gateway has no verified mesh ping endpoint for this device.' };
  },
};
export default devicesApi;
