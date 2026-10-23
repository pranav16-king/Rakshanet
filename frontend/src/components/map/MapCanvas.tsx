import React, { useMemo } from 'react';
import {
  MapContainer,
  TileLayer,
  Marker,
  Polygon,
  Polyline,
  Tooltip,
  useMap,
} from 'react-leaflet';
import L from 'leaflet';
import { Plus, Minus, Crosshair } from 'lucide-react';
import type { MapIncidentNode, LiveDevice, MapLayersState, RescueTeam } from '../../types/map';

export interface MapCanvasProps {
  incidents: MapIncidentNode[];
  devices: LiveDevice[];
  rescueTeams?: RescueTeam[];
  layers: MapLayersState;
  selectedIncident: MapIncidentNode | null;
  selectedDevice: LiveDevice | null;
  selectedRescueTeam?: RescueTeam | null;
  onSelectIncident: (node: MapIncidentNode) => void;
  onSelectDevice: (device: LiveDevice) => void;
  onSelectRescueTeam?: (team: RescueTeam) => void;
  center?: [number, number];
  zoom?: number;
}

function escapeHtml(str: string): string {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

// Controller component to expose programmatic map control (Recenter, Zoom)
const MapControls: React.FC<{ defaultCenter: [number, number]; defaultZoom: number }> = ({
  defaultCenter,
  defaultZoom,
}) => {
  const map = useMap();

  return (
    <div className="leaflet-top leaflet-left !top-20 !left-4 z-[400] flex flex-col gap-2">
      <div className="flex flex-col bg-white dark:bg-[#162036] border border-[#E2E8F0] dark:border-[#26344F] rounded-xl shadow-md overflow-hidden">
        <button
          type="button"
          onClick={() => map.zoomIn()}
          aria-label="Zoom in"
          className="p-2 text-[#0F172A] dark:text-[#EEF2F8] hover:bg-[#F8FAFC] dark:hover:bg-[#1C2844] transition-colors border-b border-[#E2E8F0] dark:border-[#26344F] cursor-pointer"
        >
          <Plus className="w-4 h-4" />
        </button>
        <button
          type="button"
          onClick={() => map.zoomOut()}
          aria-label="Zoom out"
          className="p-2 text-[#0F172A] dark:text-[#EEF2F8] hover:bg-[#F8FAFC] dark:hover:bg-[#1C2844] transition-colors cursor-pointer"
        >
          <Minus className="w-4 h-4" />
        </button>
      </div>

      <button
        type="button"
        onClick={() => map.flyTo(defaultCenter, defaultZoom, { duration: 1.2 })}
        aria-label="Recenter map"
        className="p-2 bg-white dark:bg-[#162036] border border-[#E2E8F0] dark:border-[#26344F] rounded-xl shadow-md text-[#0F172A] dark:text-[#EEF2F8] hover:bg-[#F8FAFC] dark:hover:bg-[#1C2844] transition-colors cursor-pointer"
        title="Recenter to active disaster sector"
      >
        <Crosshair className="w-4 h-4 text-[#FFC400]" />
      </button>
    </div>
  );
};

const MapCenteringSync: React.FC<{ center: [number, number] }> = ({ center }) => {
  const map = useMap();
  const prevCenterRef = React.useRef(center);

  React.useEffect(() => {
    if (
      Math.abs(prevCenterRef.current[0] - center[0]) > 0.001 ||
      Math.abs(prevCenterRef.current[1] - center[1]) > 0.001
    ) {
      prevCenterRef.current = center;
      map.panTo(center, { animate: true });
    }
  }, [center, map]);

  return null;
};

export const MapCanvas: React.FC<MapCanvasProps> = ({
  incidents,
  devices,
  rescueTeams = [],
  layers,
  selectedIncident,
  selectedDevice,
  selectedRescueTeam,
  onSelectIncident,
  onSelectDevice,
  onSelectRescueTeam,
  center,
  zoom = 13,
}) => {
  // Dynamically compute center coordinates from active incidents or devices
  const computedCenter = useMemo((): [number, number] | null => {
    if (center) return center;

    const points: [number, number][] = [];
    incidents.forEach((inc) => {
      if (inc.lat && inc.lng && Math.abs(inc.lat) > 0.001) {
        points.push([inc.lat, inc.lng]);
      }
    });
    devices.forEach((dev) => {
      if (dev.lat && dev.lng && Math.abs(dev.lat) > 0.001) {
        points.push([dev.lat, dev.lng]);
      }
    });
    rescueTeams.forEach((team) => {
      if (team.lat && team.lng && Math.abs(team.lat) > 0.001) {
        points.push([team.lat, team.lng]);
      }
    });

    if (points.length === 0) return null;

    const avgLat = points.reduce((sum, p) => sum + p[0], 0) / points.length;
    const avgLng = points.reduce((sum, p) => sum + p[1], 0) / points.length;
    return [avgLat, avgLng];
  }, [center, incidents, devices, rescueTeams]);

  // The gateway does not publish radio-neighbour edges. Do not infer links from hop counts or proximity.
  const meshLines: [number, number][][] = useMemo(() => [], []);

  // Device dot icons
  const deviceIcons = useMemo(() => {
    return {
      online: L.divIcon({
        html: `
          <div class="flex items-center justify-center cursor-pointer">
            <div class="w-3.5 h-3.5 rounded-full bg-[#4CD08A] ring-4 ring-[#4CD08A]/30 shadow-md"></div>
          </div>
        `,
        className: 'custom-device-online',
        iconSize: [16, 16],
        iconAnchor: [8, 8],
      }),
      relay: L.divIcon({
        html: `
          <div class="flex items-center justify-center cursor-pointer">
            <div class="w-3.5 h-3.5 rounded-full bg-[#3CC6D0] ring-4 ring-[#3CC6D0]/35 animate-pulse shadow-md"></div>
          </div>
        `,
        className: 'custom-device-relay',
        iconSize: [16, 16],
        iconAnchor: [8, 8],
      }),
      offline: L.divIcon({
        html: `
          <div class="flex items-center justify-center cursor-pointer opacity-70">
            <div class="w-3 h-3 rounded-full bg-[#9FADC2] ring-2 ring-gray-600/40"></div>
          </div>
        `,
        className: 'custom-device-offline',
        iconSize: [14, 14],
        iconAnchor: [7, 7],
      }),
    };
  }, []);

  if (!computedCenter) {
    return <div className="flex h-full min-h-[320px] items-center justify-center rounded-xl border border-dashed border-slate-300 bg-slate-50 p-6 text-center text-sm text-slate-600 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-300">No consented GPS coordinates have reached the gateway yet. Devices without a shared location remain visible in the device list.</div>;
  }

  // Incident icon generator with real dynamic labels and urgency pulsing
  const getIncidentIcon = (inc: MapIncidentNode, isSelected: boolean) => {
    const isCritical = inc.severity === 'CRITICAL' || inc.type === 'sos';
    const badgeLabel = escapeHtml(inc.badgeLabel || 'ALERT');
    const countLabel = escapeHtml(inc.countLabel || inc.severity);
    const selectedClass = isSelected ? 'scale-110 ring-4 ring-[#FFC400]' : '';

    if (isCritical) {
      return L.divIcon({
        html: `
          <div class="relative flex items-center justify-center cursor-pointer ${selectedClass}">
            <div class="absolute w-12 h-12 rounded-full bg-red-600/35 animate-ping pointer-events-none"></div>
            <div class="absolute w-16 h-16 rounded-full bg-red-500/20 animate-pulse pointer-events-none"></div>
            <div class="relative px-3 py-1 rounded-full bg-[#D92D20] text-white text-xs font-bold shadow-xl border-2 border-white/40 flex items-center gap-1.5 whitespace-nowrap transition-transform">
              <span class="w-2 h-2 rounded-full bg-white animate-pulse"></span>
              <span>${badgeLabel}</span>
              <span class="opacity-90 font-mono text-[11px]">${countLabel}</span>
            </div>
          </div>
        `,
        className: 'custom-sos-marker',
        iconSize: [130, 44],
        iconAnchor: [65, 22],
      });
    }

    if (inc.type === 'landslide') {
      return L.divIcon({
        html: `
          <div class="px-3 py-1 rounded-full bg-[#B45309] text-white text-xs font-bold shadow-xl border-2 border-amber-300/40 flex items-center gap-1.5 whitespace-nowrap cursor-pointer hover:scale-105 transition-transform ${selectedClass}">
            <span>${badgeLabel}</span>
            <span class="opacity-90 font-mono text-[11px]">${countLabel}</span>
          </div>
        `,
        className: 'custom-landslide-marker',
        iconSize: [140, 36],
        iconAnchor: [70, 18],
      });
    }

    if (inc.type === 'flood') {
      return L.divIcon({
        html: `
          <div class="px-3 py-1 rounded-full bg-[#0E8A94] text-white text-xs font-bold shadow-xl border-2 border-cyan-300/40 flex items-center gap-1.5 whitespace-nowrap cursor-pointer hover:scale-105 transition-transform ${selectedClass}">
            <span>${badgeLabel}</span>
            <span class="opacity-90 font-mono text-[11px]">${countLabel}</span>
          </div>
        `,
        className: 'custom-flood-marker',
        iconSize: [144, 36],
        iconAnchor: [72, 18],
      });
    }

    // Default rescue team / other marker
    return L.divIcon({
      html: `
        <div class="px-3 py-1 rounded-full bg-[#1E8E4E] text-white text-xs font-bold shadow-xl border-2 border-emerald-300/40 flex items-center gap-1.5 whitespace-nowrap cursor-pointer hover:scale-105 transition-transform ${selectedClass}">
          <span>${badgeLabel}</span>
          <span class="opacity-90 font-mono text-[11px]">${countLabel}</span>
        </div>
      `,
      className: 'custom-rescue-marker',
      iconSize: [150, 36],
      iconAnchor: [75, 18],
    });
  };

  // Rescue team icon generator
  const getRescueTeamIcon = (team: RescueTeam, isSelected: boolean) => {
    const selectedClass = isSelected ? 'scale-110 ring-4 ring-[#FFC400]' : '';
    const safeName = escapeHtml(team.name.length > 20 ? team.name.slice(0, 18) + '...' : team.name);

    return L.divIcon({
      html: `
        <div class="px-2.5 py-1 rounded-full bg-[#1E8E4E] text-white text-xs font-bold shadow-xl border-2 border-emerald-300/60 flex items-center gap-1.5 whitespace-nowrap cursor-pointer hover:scale-105 transition-transform ${selectedClass}">
          <span class="w-2 h-2 rounded-full bg-white animate-pulse"></span>
          <span>${safeName}</span>
          <span class="opacity-90 font-mono text-[10px]">${team.membersCount}P</span>
        </div>
      `,
      className: 'custom-team-marker',
      iconSize: [160, 36],
      iconAnchor: [80, 18],
    });
  };

  return (
    <div className="relative w-full h-full overflow-hidden">
      <MapContainer
        center={computedCenter}
        zoom={zoom}
        zoomControl={false}
        className="w-full h-full z-0"
        style={{ height: '100%', width: '100%', background: '#0B1220' }}
      >
        {/* OpenStreetMap tile layer (100% Free, Humanitarian / Carto standard) */}
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          subdomains="abc"
          maxZoom={19}
        />

        {/* Sync Center on data changes */}
        <MapCenteringSync center={computedCenter} />

        {/* Custom Zoom & Recenter Controls */}
        <MapControls defaultCenter={computedCenter} defaultZoom={zoom} />

        {/* Mesh Connections Layer */}
        {layers.meshConnections &&
          meshLines.map((coords, i) => (
            <Polyline
              key={`mesh-${i}`}
              positions={coords}
              pathOptions={{
                color: '#3CC6D0',
                weight: 2,
                dashArray: '6, 8',
                opacity: 0.85,
              }}
            />
          ))}

        {/* Hazard Zones: Flood Area Polygon */}
        {layers.hazardZones &&
          incidents
            .filter((inc) => inc.type === 'flood' && inc.polygonCoords && inc.polygonCoords.length > 0)
            .map((inc) => (
              <Polygon
                key={`poly-${inc.id}`}
                positions={inc.polygonCoords as [number, number][]}
                pathOptions={{
                  fillColor: '#0E8A94',
                  fillOpacity: 0.28,
                  color: '#3CC6D0',
                  weight: 2,
                  dashArray: '4, 4',
                }}
                eventHandlers={{
                  click: () => onSelectIncident(inc),
                }}
              />
            ))}

        {/* Real Incidents Layer */}
        {layers.incidents &&
          incidents.map((inc) => {
            const isSelected = selectedIncident?.id === inc.id;
            return (
              <Marker
                key={`inc-${inc.id}`}
                position={[inc.lat, inc.lng]}
                icon={getIncidentIcon(inc, isSelected)}
                eventHandlers={{
                  click: () => onSelectIncident(inc),
                }}
              >
                <Tooltip direction="top" offset={[0, -20]} opacity={0.95}>
                  <div className="font-sans text-xs">
                    <strong>{inc.title}</strong>
                    <div className="text-[10px] text-gray-600 dark:text-gray-300">
                      {inc.countLabel} · {inc.severity}
                    </div>
                  </div>
                </Tooltip>
              </Marker>
            );
          })}

        {/* Real Rescue Teams Layer */}
        {layers.rescueTeams &&
          rescueTeams.map((team) => {
            if (!Number.isFinite(team.lat) || !Number.isFinite(team.lng)) return null;
            const isSelected = selectedRescueTeam?.id === team.id;
            return (
              <Marker
                key={`team-${team.id}`}
                position={[team.lat, team.lng]}
                icon={getRescueTeamIcon(team, isSelected)}
                eventHandlers={{
                  click: () => {
                    if (onSelectRescueTeam) {
                      onSelectRescueTeam(team);
                    } else {
                      // Map to node format for inspector drawer fallback
                      onSelectIncident({
                        id: team.id,
                        title: team.name,
                        type: 'rescue_team',
                        badgeLabel: 'Rescue Unit',
                        countLabel: `${team.membersCount} Responders`,
                        lat: team.lat,
                        lng: team.lng,
                        severity: 'LOW',
                        description: `Operational Status: ${team.status} · Leader: ${team.leader || 'Unassigned'} · Capabilities: ${team.capabilities?.join(', ') || 'General rescue'}`,
                        reportedAgo: 'Active unit',
                      });
                    }
                  },
                }}
              >
                <Tooltip direction="top" offset={[0, -18]} opacity={0.95}>
                  <div className="font-sans text-xs">
                    <strong>{team.name}</strong>
                    <div className="text-[10px] text-gray-600 dark:text-gray-300">
                      {team.teamType} · {team.status}
                    </div>
                  </div>
                </Tooltip>
              </Marker>
            );
          })}

        {/* Real Live Devices Layer */}
        {layers.nearbyDevices &&
          devices.map((device) => {
            if (device.lat === undefined || device.lng === undefined) return null;
            let icon = deviceIcons.online;
            if (device.status === 'Relay') icon = deviceIcons.relay;
            if (device.status === 'Offline') icon = deviceIcons.offline;

            return (
              <Marker
                key={`dev-${device.id}`}
                position={[device.lat, device.lng]}
                icon={icon}
                eventHandlers={{
                  click: () => onSelectDevice(device),
                }}
              >
                <Tooltip direction="top" offset={[0, -10]} opacity={0.95}>
                  <div className="font-sans text-xs">
                    <span className="font-bold">{device.name}</span>
                    <span className="font-mono text-[10px] text-gray-500 ml-1">({device.id})</span>
                    <div className="text-[10px] text-gray-600 dark:text-gray-300">
                      {device.status} · {device.battery}% battery · {device.hops} hops
                    </div>
                  </div>
                </Tooltip>
              </Marker>
            );
          })}
      </MapContainer>
    </div>
  );
};

export default MapCanvas;
