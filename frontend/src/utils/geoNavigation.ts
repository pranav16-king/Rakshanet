import type { MapIncidentNode, LiveDevice, RescueTeam } from '../types/map';

export interface ResponderUnit {
  id: string;
  name: string;
  type: 'rescue_team' | 'gateway_unit' | 'mesh_relay';
  lat: number;
  lng: number;
  status?: string;
  membersCount?: number;
}

export interface SosBeaconTarget {
  id: string;
  name: string;
  title?: string;
  lat: number;
  lng: number;
  type: 'sos_incident' | 'sos_device' | 'selected_incident' | 'selected_device';
  severity?: string;
  hops?: number;
}

export interface NavigationVector {
  target: SosBeaconTarget;
  responder: ResponderUnit;
  distanceMeters: number;
  distanceFormatted: string;
  bearingDegrees: number;
  compassBearing: string;
  etaMinutes: number;
  hudText: string;
  midpoint: [number, number];
}

export function isValidCoordinate(lat?: number | null, lng?: number | null): lat is number {
  return (
    typeof lat === 'number' &&
    typeof lng === 'number' &&
    Number.isFinite(lat) &&
    Number.isFinite(lng) &&
    lat >= -90 &&
    lat <= 90 &&
    lng >= -180 &&
    lng <= 180 &&
    (Math.abs(lat) > 0.0001 || Math.abs(lng) > 0.0001)
  );
}

export function calculateDistanceMeters(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  if (!isValidCoordinate(lat1, lon1) || !isValidCoordinate(lat2, lon2)) return 0;

  const R = 6371e3; // Earth's mean radius in meters
  const phi1 = (lat1 * Math.PI) / 180;
  const phi2 = (lat2 * Math.PI) / 180;
  const deltaPhi = ((lat2 - lat1) * Math.PI) / 180;
  const deltaLambda = ((lon2 - lon1) * Math.PI) / 180;

  const a =
    Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
    Math.cos(phi1) * Math.cos(phi2) * Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c;
}

export function calculateBearing(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): { degrees: number; compass: string } {
  if (!isValidCoordinate(lat1, lon1) || !isValidCoordinate(lat2, lon2)) {
    return { degrees: 0, compass: 'N' };
  }

  const phi1 = (lat1 * Math.PI) / 180;
  const phi2 = (lat2 * Math.PI) / 180;
  const deltaLambda = ((lon2 - lon1) * Math.PI) / 180;

  const y = Math.sin(deltaLambda) * Math.cos(phi2);
  const x =
    Math.cos(phi1) * Math.sin(phi2) -
    Math.sin(phi1) * Math.cos(phi2) * Math.cos(deltaLambda);
  const theta = Math.atan2(y, x);
  const degrees = Math.round(((theta * 180) / Math.PI + 360) % 360);

  const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
  const index = Math.round(degrees / 45) % 8;
  const compass = directions[index];

  return { degrees, compass };
}

export function formatDistance(meters: number): string {
  if (!Number.isFinite(meters) || meters <= 0) return '0 m';
  if (meters < 1000) {
    return `${Math.round(meters)} m`;
  }
  return `${(meters / 1000).toFixed(2)} km`;
}

export function findNearestRescueOrGateway(
  targetLat: number,
  targetLng: number,
  rescueTeams: RescueTeam[] = [],
  devices: LiveDevice[] = []
): { responder: ResponderUnit; distanceMeters: number } | null {
  if (!isValidCoordinate(targetLat, targetLng)) return null;

  let nearest: ResponderUnit | null = null;
  let minDistance = Infinity;

  // 1. Check Rescue Teams
  for (const team of rescueTeams) {
    if (!isValidCoordinate(team.lat, team.lng)) continue;
    const dist = calculateDistanceMeters(team.lat, team.lng, targetLat, targetLng);
    if (dist < minDistance) {
      minDistance = dist;
      nearest = {
        id: team.id,
        name: team.name || `Rescue Team ${team.id}`,
        type: 'rescue_team',
        lat: team.lat,
        lng: team.lng,
        status: team.status,
        membersCount: team.membersCount,
      };
    }
  }

  // 2. Check Gateway Units and Online Relay Devices
  for (const dev of devices) {
    if (!isValidCoordinate(dev.lat, dev.lng)) continue;
    const isGateway =
      dev.type.toLowerCase().includes('gateway') ||
      dev.name.toLowerCase().includes('gateway') ||
      dev.name.toLowerCase().includes('gw');
    const isRelay = dev.status === 'Relay' || dev.status === 'Online';

    if (isGateway || isRelay) {
      const dist = calculateDistanceMeters(dev.lat, dev.lng, targetLat, targetLng);
      // Give rescue teams priority, but if gateway is much closer or no rescue teams exist:
      if (dist < minDistance) {
        minDistance = dist;
        nearest = {
          id: dev.id,
          name: dev.name || `Gateway Unit ${dev.id}`,
          type: isGateway ? 'gateway_unit' : 'mesh_relay',
          lat: dev.lat,
          lng: dev.lng,
          status: dev.status,
        };
      }
    }
  }

  if (!nearest || !Number.isFinite(minDistance)) return null;
  return { responder: nearest, distanceMeters: minDistance };
}

export function buildNavigationVector(
  target: SosBeaconTarget,
  rescueTeams: RescueTeam[] = [],
  devices: LiveDevice[] = []
): NavigationVector | null {
  if (!isValidCoordinate(target.lat, target.lng)) return null;

  const result = findNearestRescueOrGateway(target.lat, target.lng, rescueTeams, devices);
  if (!result) return null;

  const { responder, distanceMeters } = result;
  const bearing = calculateBearing(responder.lat, responder.lng, target.lat, target.lng);
  const distanceFormatted = formatDistance(distanceMeters);

  // Foot/light tactical terrain estimate: ~80 meters per minute (4.8 km/h)
  const etaMinutes = Math.max(1, Math.round(distanceMeters / 80));

  const hudText = `Response Unit ${responder.name} -> Survivor (${target.name}) • ${distanceFormatted} • Compass Bearing ${bearing.degrees}° ${bearing.compass}`;

  return {
    target,
    responder,
    distanceMeters,
    distanceFormatted,
    bearingDegrees: bearing.degrees,
    compassBearing: bearing.compass,
    etaMinutes,
    hudText,
    midpoint: [(responder.lat + target.lat) / 2, (responder.lng + target.lng) / 2],
  };
}
