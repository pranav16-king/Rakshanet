import { apiClient } from './client';
import type { LiveDevice, MapIncidentNode, RescueTeam, DeviceStats } from '../types/map';

function formatRelativeTime(timestamp?: number | string): string {
  if (!timestamp) return 'Active now';
  const timeMs = typeof timestamp === 'string' ? new Date(timestamp).getTime() : timestamp;
  if (isNaN(timeMs)) return 'Active now';
  const diffSec = Math.max(0, Math.floor((Date.now() - timeMs) / 1000));
  if (diffSec < 60) return `${diffSec}s ago`;
  const diffMin = Math.floor(diffSec / 60);
  if (diffMin < 60) return `${diffMin} min ago`;
  const diffHr = Math.floor(diffMin / 60);
  if (diffHr < 24) return `${diffHr}h ago`;
  return `${Math.floor(diffHr / 24)}d ago`;
}

export async function fetchLiveDevices(): Promise<LiveDevice[]> {
  try {
    const response = await apiClient.get<any[]>('/api/v1/devices');
    const rawList = Array.isArray(response.data) ? response.data : [];

    return rawList.map((raw: any): LiveDevice => {
      const id = String(raw.device_id || raw.id || 'DEV-NODE');
      const name = String(raw.name || raw.owner_name || id);

      const rawStatus = String(raw.status || 'Offline').toLowerCase();
      let status: LiveDevice['status'] = 'Offline';
      if (rawStatus === 'online') status = 'Online';
      else if (rawStatus === 'relay') status = 'Relay';

      const lat = Number(raw.lat ?? 0);
      const lng = Number(raw.lng ?? 0);
      const battery = Number(raw.battery_pct ?? raw.battery ?? 100);
      const hops = Number(raw.hops_away ?? raw.hops ?? 0);
      const lastPing = Number(raw.last_seen ?? raw.lastPing ?? Date.now());

      let location = raw.location;
      if (!location) {
        if (lat !== 0 && lng !== 0) {
          location = `${lat.toFixed(3)}°N, ${lng.toFixed(3)}°E`;
        } else {
          location = 'Sector Grid';
        }
      }

      return {
        id,
        name,
        location,
        relativeTime: formatRelativeTime(lastPing),
        status,
        battery,
        lat,
        lng,
        type: String(raw.device_type || raw.type || 'Smartphone'),
        hops,
        lastPing,
      };
    });
  } catch (err) {
    console.warn('Failed to fetch live devices from /api/v1/devices:', err);
    return [];
  }
}

export async function fetchMapIncidents(): Promise<MapIncidentNode[]> {
  try {
    const response = await apiClient.get<any[]>('/api/v1/incidents');
    const rawList = Array.isArray(response.data) ? response.data : [];

    return rawList.map((raw: any): MapIncidentNode => {
      const id = String(raw.incident_id || raw.id || `INC-${Math.random().toString(36).substring(2, 7).toUpperCase()}`);
      const rawCategory = (raw.disaster_type || raw.category || raw.primary_category || '').toLowerCase();

      let type: MapIncidentNode['type'] = 'sos';
      if (rawCategory.includes('landslide') || rawCategory.includes('mud')) {
        type = 'landslide';
      } else if (rawCategory.includes('flood') || rawCategory.includes('water') || rawCategory.includes('inundation')) {
        type = 'flood';
      } else if (rawCategory.includes('rescue') || rawCategory.includes('team') || rawCategory.includes('ops')) {
        type = 'rescue_team';
      } else {
        type = 'sos';
      }

      const rawSeverity = String(raw.urgency || raw.severity || 'CRITICAL').toUpperCase();
      const severity = (['CRITICAL', 'HIGH', 'MEDIUM', 'LOW', 'UNKNOWN'].includes(rawSeverity)
        ? rawSeverity
        : 'CRITICAL') as MapIncidentNode['severity'];

      const totalDevices = Number(
        raw.total_devices ?? raw.devices_count ?? (Array.isArray(raw.contributing_devices) ? raw.contributing_devices.length : 0)
      );
      const casualties = Number(raw.estimated_casualties ?? raw.casualty_estimate ?? raw.people_count ?? 0);

      let badgeLabel = 'SOS';
      if (type === 'landslide') badgeLabel = 'Landslide';
      else if (type === 'flood') badgeLabel = 'Flood Area';
      else if (type === 'rescue_team') badgeLabel = 'Rescue Team';

      let countLabel = '';
      if (totalDevices > 0) {
        countLabel = `${totalDevices} devices`;
      } else if (casualties > 0) {
        countLabel = `${casualties} users`;
      } else {
        countLabel = severity;
      }

      const lat = Number(raw.centroid_lat ?? raw.lat ?? 0);
      const lng = Number(raw.centroid_lng ?? raw.lng ?? 0);

      let polygonCoords: [number, number][] | undefined = undefined;
      if (Array.isArray(raw.polygon_coords) && raw.polygon_coords.length > 0) {
        polygonCoords = raw.polygon_coords;
      } else if (Array.isArray(raw.polygonCoords) && raw.polygonCoords.length > 0) {
        polygonCoords = raw.polygonCoords;
      } else if (type === 'flood' && lat !== 0 && lng !== 0) {
        const delta = 0.005;
        polygonCoords = [
          [lat + delta * 0.8, lng - delta * 0.9],
          [lat + delta * 1.1, lng + delta * 0.7],
          [lat - delta * 0.6, lng + delta * 1.2],
          [lat - delta * 0.9, lng - delta * 0.6],
        ];
      }

      const description =
        raw.description ||
        raw.affected_area ||
        (Array.isArray(raw.sample_messages) && raw.sample_messages.length > 0 ? raw.sample_messages[0] : undefined) ||
        (Array.isArray(raw.associated_messages) && raw.associated_messages.length > 0 ? raw.associated_messages[0] : undefined) ||
        `${badgeLabel} incident affecting ${casualties || totalDevices || 'unknown'} people/devices`;

      return {
        id,
        title: raw.title || `${badgeLabel} Alert (${countLabel})`,
        type,
        badgeLabel,
        countLabel,
        lat,
        lng,
        severity,
        userCount: casualties > 0 ? casualties : undefined,
        deviceCount: totalDevices > 0 ? totalDevices : undefined,
        radiusMeters: raw.radius_meters || raw.radiusMeters || 450,
        polygonCoords,
        description,
        reportedAgo: formatRelativeTime(raw.updated_at || raw.created_at || raw.last_beacon_time),
      };
    });
  } catch (err) {
    console.warn('Failed to fetch map incidents from /api/v1/incidents:', err);
    return [];
  }
}

export async function fetchDeviceStats(): Promise<DeviceStats> {
  try {
    const response = await apiClient.get<any>('/api/v1/devices/stats');
    if (response.data && typeof response.data === 'object') {
      return {
        total: Number(response.data.total ?? 0),
        online: Number(response.data.online ?? 0),
        relay: Number(response.data.relay ?? 0),
        offline: Number(response.data.offline ?? 0),
      };
    }
  } catch (err) {
    console.warn('Failed to fetch device stats from /api/v1/devices/stats:', err);
  }
  return { total: 0, online: 0, relay: 0, offline: 0 };
}

export async function fetchRescueTeams(): Promise<RescueTeam[]> {
  try {
    const response = await apiClient.get<any[]>('/api/v1/rescue-teams');
    const rawList = Array.isArray(response.data) ? response.data : [];

    return rawList.map((raw: any): RescueTeam => ({
      id: String(raw.team_id || raw.id || 'TEAM-01'),
      name: String(raw.name || 'Tactical Rescue Unit'),
      teamType: String(raw.team_type || raw.teamType || 'RESCUE_TEAM'),
      leader: raw.leader ? String(raw.leader) : undefined,
      contact: raw.contact ? String(raw.contact) : undefined,
      membersCount: Number(raw.members_count ?? raw.membersCount ?? 4),
      status: String(raw.status || 'AVAILABLE'),
      lat: Number(raw.location_lat ?? raw.lat ?? 0),
      lng: Number(raw.location_lng ?? raw.lng ?? 0),
      assignedIncidentId: raw.assigned_incident_id ?? null,
      capabilities: Array.isArray(raw.capabilities) ? raw.capabilities : [],
    }));
  } catch (err) {
    console.warn('Failed to fetch rescue teams from /api/v1/rescue-teams:', err);
    return [];
  }
}
