import { apiClient } from './client';
import type { LiveDevice, MapIncidentNode, RescueTeam, DeviceStats } from '../types/map';

const numeric = (v: unknown): v is number => typeof v === 'number' && Number.isFinite(v);
function relativeTime(value: unknown): string {
  if (!numeric(value) && typeof value !== 'string') return 'Not reported';
  const ms = typeof value === 'string' ? Date.parse(value) : value;
  if (!Number.isFinite(ms)) return 'Not reported';
  const seconds = Math.max(0, Math.floor((Date.now() - ms) / 1000));
  if (seconds < 60) return `${seconds}s ago`;
  if (seconds < 3600) return `${Math.floor(seconds / 60)} min ago`;
  if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
  return `${Math.floor(seconds / 86400)}d ago`;
}

export async function fetchLiveDevices(): Promise<LiveDevice[]> {
  try {
    const { data } = await apiClient.get<any[]>('/api/v1/devices');
    return (Array.isArray(data) ? data : []).flatMap((raw): LiveDevice[] => {
      if (!raw?.device_id || !numeric(raw.lat) || !numeric(raw.lng) || !numeric(raw.battery_pct) || !numeric(raw.hops_away) || !numeric(raw.last_seen)) return [];
      const rawStatus = String(raw.status ?? '').toLowerCase();
      const status = rawStatus === 'online' ? 'Online' : rawStatus === 'relay' ? 'Relay' : 'Offline';
      return [{ id: String(raw.device_id), name: String(raw.name ?? raw.owner_name ?? raw.device_id), location: `${raw.lat.toFixed(4)}°, ${raw.lng.toFixed(4)}°`, relativeTime: relativeTime(raw.last_seen), status, battery: raw.battery_pct, lat: raw.lat, lng: raw.lng, type: String(raw.device_type ?? 'Unknown'), hops: raw.hops_away, lastPing: raw.last_seen }];
    });
  } catch { return []; }
}

export async function fetchMapIncidents(): Promise<MapIncidentNode[]> {
  try {
    const { data } = await apiClient.get<any[]>('/api/v1/incidents', { params: { source: 'db' } });
    return (Array.isArray(data) ? data : []).flatMap((raw): MapIncidentNode[] => {
      const id = raw?.incident_id ?? raw?.id;
      const lat = raw?.centroid_lat ?? raw?.lat;
      const lng = raw?.centroid_lng ?? raw?.lng;
      if (!id || !numeric(lat) || !numeric(lng)) return [];
      const category = String(raw.disaster_type ?? raw.category ?? '').toLowerCase();
      const type = category.includes('landslide') || category.includes('mud') ? 'landslide' : category.includes('flood') || category.includes('water') ? 'flood' : 'sos';
      const rawSeverity = String(raw.urgency ?? raw.severity ?? 'UNKNOWN').toUpperCase();
      const severity = (['CRITICAL', 'HIGH', 'MEDIUM', 'LOW', 'UNKNOWN'].includes(rawSeverity) ? rawSeverity : 'UNKNOWN') as MapIncidentNode['severity'];
      const people = numeric(raw.people_count) ? raw.people_count : undefined;
      const devices = numeric(raw.total_devices) ? raw.total_devices : numeric(raw.devices_count) ? raw.devices_count : undefined;
      return [{ id: String(id), title: String(raw.title ?? id), type, badgeLabel: category || 'Unspecified', countLabel: people !== undefined ? `${people} people` : devices !== undefined ? `${devices} devices` : 'Count not reported', lat, lng, severity, userCount: people, deviceCount: devices, radiusMeters: numeric(raw.radius_meters) ? raw.radius_meters : undefined, polygonCoords: Array.isArray(raw.polygon_coords) ? raw.polygon_coords : undefined, description: typeof raw.description === 'string' ? raw.description : undefined, reportedAgo: relativeTime(raw.updated_at ?? raw.created_at ?? raw.last_beacon_time) }];
    });
  } catch { return []; }
}
export async function fetchDeviceStats(): Promise<DeviceStats> { try { const { data } = await apiClient.get<any>('/api/v1/devices/stats'); return { total: numeric(data?.total) ? data.total : 0, online: numeric(data?.online) ? data.online : 0, relay: numeric(data?.relay) ? data.relay : 0, offline: numeric(data?.offline) ? data.offline : 0 }; } catch { return { total: 0, online: 0, relay: 0, offline: 0 }; } }
export async function fetchRescueTeams(): Promise<RescueTeam[]> {
  try { const { data } = await apiClient.get<any[]>('/api/v1/rescue-teams'); return (Array.isArray(data) ? data : []).flatMap((raw): RescueTeam[] => raw?.team_id && numeric(raw.location_lat ?? raw.lat) && numeric(raw.location_lng ?? raw.lng) && numeric(raw.members_count ?? raw.membersCount) ? [{ id: String(raw.team_id), name: String(raw.name ?? raw.team_id), teamType: String(raw.team_type ?? raw.teamType ?? 'Unknown'), leader: typeof raw.leader === 'string' ? raw.leader : undefined, contact: typeof raw.contact === 'string' ? raw.contact : undefined, membersCount: raw.members_count ?? raw.membersCount, status: String(raw.status ?? 'Unknown'), lat: raw.location_lat ?? raw.lat, lng: raw.location_lng ?? raw.lng, assignedIncidentId: raw.assigned_incident_id ?? null, capabilities: Array.isArray(raw.capabilities) ? raw.capabilities : [] }] : []); } catch { return []; }
}
