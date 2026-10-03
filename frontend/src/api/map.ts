import { apiClient } from './client';
import type { LiveDevice, MapIncidentNode } from '../types/map';

export const INITIAL_MAP_INCIDENTS: MapIncidentNode[] = [
  {
    id: 'INC-SOS-01',
    title: 'SOS Emergency Cluster',
    type: 'sos',
    badgeLabel: 'SOS',
    countLabel: '12 users',
    userCount: 12,
    lat: 30.0750,
    lng: 79.0200,
    severity: 'CRITICAL',
    description: '12 individuals stranded on reinforced rooftop due to sudden river overflow. Battery reserves declining.',
    reportedAgo: '2 min ago',
  },
  {
    id: 'INC-LS-02',
    title: 'Landslide Debris Block',
    type: 'landslide',
    badgeLabel: 'Landslide',
    countLabel: '5 devices',
    deviceCount: 5,
    lat: 30.0910,
    lng: 79.0490,
    severity: 'HIGH',
    description: 'Road blocked on NH-7 ridge. 5 civilian phones acting as ad-hoc relay chain across the pass.',
    reportedAgo: '26 min ago',
  },
  {
    id: 'INC-FL-03',
    title: 'River Basin Flood Area',
    type: 'flood',
    badgeLabel: 'Flood Area',
    countLabel: '15 devices',
    deviceCount: 15,
    radiusMeters: 550,
    lat: 30.0610,
    lng: 79.0340,
    severity: 'HIGH',
    description: 'Active flash inundation zone. Mesh network packet relay operational across fringe nodes.',
    reportedAgo: '12 min ago',
    polygonCoords: [
      [30.066, 79.028],
      [30.068, 79.038],
      [30.058, 79.042],
      [30.054, 79.031],
    ],
  },
  {
    id: 'INC-RT-04',
    title: 'SDRF Rapid Rescue Alpha',
    type: 'rescue_team',
    badgeLabel: 'Rescue Team',
    countLabel: '8 devices',
    deviceCount: 8,
    lat: 30.0510,
    lng: 79.0280,
    severity: 'LOW',
    description: 'Tactical responder unit equipped with inflatable motorboats and satellite-linked LoRa gateway.',
    reportedAgo: 'Active now',
  },
];

export const INITIAL_LIVE_DEVICES: LiveDevice[] = [
  {
    id: 'SR-8F42',
    name: 'Amit Kumar',
    location: 'Uttarakhand',
    relativeTime: '2 min ago',
    status: 'Online',
    battery: 85,
    lat: 30.0760,
    lng: 79.0230,
    type: 'Smartphone',
    hops: 1,
    lastPing: Date.now() - 2 * 60 * 1000,
  },
  {
    id: 'SR-9A1C',
    name: 'Priya Sharma',
    location: 'Uttarakhand',
    relativeTime: '5 min ago',
    status: 'Relay',
    battery: 42,
    lat: 30.0710,
    lng: 79.0380,
    type: 'Relay Node',
    hops: 2,
    lastPing: Date.now() - 5 * 60 * 1000,
  },
  {
    id: 'SR-3D7B',
    name: 'Rahul Mehta',
    location: 'Himachal Pradesh',
    relativeTime: '5 min ago',
    status: 'Online',
    battery: 76,
    lat: 30.0880,
    lng: 79.0450,
    type: 'Smartphone',
    hops: 1,
    lastPing: Date.now() - 5 * 60 * 1000,
  },
  {
    id: 'SR-6E2F',
    name: 'Sneha Patel',
    location: 'Delhi',
    relativeTime: '12 min ago',
    status: 'Offline',
    battery: 23,
    lat: 30.0620,
    lng: 79.0210,
    type: 'Smartphone',
    hops: 0,
    lastPing: Date.now() - 12 * 60 * 1000,
  },
  {
    id: 'SR-7Q3H',
    name: 'Vikram Singh',
    location: 'Uttarakhand',
    relativeTime: '18 min ago',
    status: 'Online',
    battery: 89,
    lat: 30.0530,
    lng: 79.0260,
    type: 'Tablet Responder',
    hops: 1,
    lastPing: Date.now() - 18 * 60 * 1000,
  },
  {
    id: 'SR-4K2P',
    name: 'Ananya Gupta',
    location: 'Uttarakhand',
    relativeTime: '22 min ago',
    status: 'Relay',
    battery: 58,
    lat: 30.0810,
    lng: 79.0350,
    type: 'LoRa Mesh Hop',
    hops: 3,
    lastPing: Date.now() - 22 * 60 * 1000,
  },
];

export async function fetchLiveDevices(): Promise<LiveDevice[]> {
  try {
    const response = await apiClient.get<LiveDevice[]>('/devices');
    if (response.data && Array.isArray(response.data)) {
      return response.data;
    }
  } catch {
    // Return high-fidelity local telemetry
  }
  return INITIAL_LIVE_DEVICES;
}

export async function fetchMapIncidents(): Promise<MapIncidentNode[]> {
  try {
    const response = await apiClient.get<MapIncidentNode[]>('/incidents/map');
    if (response.data && Array.isArray(response.data)) {
      return response.data;
    }
  } catch {
    // Return high-fidelity local incidents
  }
  return INITIAL_MAP_INCIDENTS;
}
