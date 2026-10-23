import React, { useMemo, useState } from 'react';
import {
  MapContainer,
  TileLayer,
  Marker,
  Polygon,
  Polyline,
  Tooltip,
  Popup,
  useMap,
} from 'react-leaflet';
import L from 'leaflet';
import {
  Plus,
  Minus,
  Crosshair,
  Navigation,
  Compass,
  AlertTriangle,
  ShieldAlert,
  ArrowRight,
  X,
  ChevronDown,
} from 'lucide-react';
import type { MapIncidentNode, LiveDevice, MapLayersState, RescueTeam } from '../../types/map';
import {
  isValidCoordinate,
  buildNavigationVector,
  type NavigationVector,
  type SosBeaconTarget,
} from '../../utils/geoNavigation';

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
  const [isHudMinimized, setIsHudMinimized] = useState(false);

  // Dynamically compute center coordinates from active incidents or devices
  const computedCenter = useMemo((): [number, number] | null => {
    if (center && isValidCoordinate(center[0], center[1])) return center;

    // Prioritize active SOS beacon coordinates if present
    const activeSos = incidents.find(
      (inc) =>
        (inc.type === 'sos' ||
          inc.severity === 'CRITICAL' ||
          inc.badgeLabel.toLowerCase().includes('sos') ||
          inc.title.toLowerCase().includes('sos')) &&
        isValidCoordinate(inc.lat, inc.lng)
    );
    if (activeSos && isValidCoordinate(activeSos.lat, activeSos.lng)) {
      return [activeSos.lat, activeSos.lng];
    }

    const points: [number, number][] = [];
    incidents.forEach((inc) => {
      if (isValidCoordinate(inc.lat, inc.lng)) {
        points.push([inc.lat, inc.lng]);
      }
    });
    devices.forEach((dev) => {
      if (isValidCoordinate(dev.lat, dev.lng)) {
        points.push([dev.lat, dev.lng]);
      }
    });
    rescueTeams.forEach((team) => {
      if (isValidCoordinate(team.lat, team.lng)) {
        points.push([team.lat, team.lng]);
      }
    });

    if (points.length === 0) return null;

    const avgLat = points.reduce((sum, p) => sum + p[0], 0) / points.length;
    const avgLng = points.reduce((sum, p) => sum + p[1], 0) / points.length;
    return [avgLat, avgLng];
  }, [center, incidents, devices, rescueTeams]);

  // Mesh lines: radio connectivity
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

  // 1. Extract all active SOS Beacon targets with validated coordinates
  const sosTargets = useMemo((): SosBeaconTarget[] => {
    const list: SosBeaconTarget[] = [];

    // Check Incidents
    incidents.forEach((inc) => {
      const isSos =
        inc.type === 'sos' ||
        inc.severity === 'CRITICAL' ||
        inc.badgeLabel.toLowerCase().includes('sos') ||
        inc.title.toLowerCase().includes('sos');

      if (isSos && isValidCoordinate(inc.lat, inc.lng)) {
        list.push({
          id: inc.id,
          name: inc.title || `SOS Node ${inc.id}`,
          title: inc.title,
          lat: inc.lat,
          lng: inc.lng,
          type: 'sos_incident',
          severity: inc.severity,
        });
      }
    });

    // Check Devices with SOS tags
    devices.forEach((dev) => {
      const isSos =
        dev.type.toLowerCase().includes('sos') ||
        dev.name.toLowerCase().includes('sos');

      if (isSos && isValidCoordinate(dev.lat, dev.lng)) {
        list.push({
          id: dev.id,
          name: dev.name || `SOS Beacon ${dev.id}`,
          lat: dev.lat,
          lng: dev.lng,
          type: 'sos_device',
          hops: dev.hops,
        });
      }
    });

    return list;
  }, [incidents, devices]);

  // 2. Identify focus target (either explicit user selection or primary SOS beacon)
  const activeFocusTarget = useMemo((): SosBeaconTarget | null => {
    if (selectedIncident && isValidCoordinate(selectedIncident.lat, selectedIncident.lng)) {
      return {
        id: selectedIncident.id,
        name: selectedIncident.title || `Incident ${selectedIncident.id}`,
        title: selectedIncident.title,
        lat: selectedIncident.lat,
        lng: selectedIncident.lng,
        type: 'selected_incident',
        severity: selectedIncident.severity,
      };
    }

    if (selectedDevice && isValidCoordinate(selectedDevice.lat, selectedDevice.lng)) {
      return {
        id: selectedDevice.id,
        name: selectedDevice.name || `Device ${selectedDevice.id}`,
        lat: selectedDevice.lat,
        lng: selectedDevice.lng,
        type: 'selected_device',
        hops: selectedDevice.hops,
      };
    }

    if (sosTargets.length > 0) {
      return sosTargets[0];
    }

    return null;
  }, [selectedIncident, selectedDevice, sosTargets]);

  // 3. Dynamic navigation vector connecting nearest rescue team or gateway unit to active focus target
  const activeNavigationVector = useMemo((): NavigationVector | null => {
    if (!activeFocusTarget) return null;
    return buildNavigationVector(activeFocusTarget, rescueTeams, devices);
  }, [activeFocusTarget, rescueTeams, devices]);

  // 4. Direction vectors for all active SOS beacons
  const allSosVectors = useMemo((): NavigationVector[] => {
    return sosTargets
      .map((target) => buildNavigationVector(target, rescueTeams, devices))
      .filter((v): v is NavigationVector => v !== null);
  }, [sosTargets, rescueTeams, devices]);

  // Pulsing red beacon marker on the SOS origin coordinates
  const getSosBeaconIcon = (label: string, isSelected: boolean) => {
    const selectedClass = isSelected ? 'scale-125 ring-4 ring-[#FFC400]' : '';
    const safeLabel = escapeHtml(label.length > 22 ? label.slice(0, 20) + '...' : label);

    return L.divIcon({
      html: `
        <div class="relative flex items-center justify-center cursor-pointer ${selectedClass}">
          <!-- High-visibility animated concentric ping and radar circles -->
          <div class="absolute w-24 h-24 rounded-full bg-red-600/30 animate-beacon-radar pointer-events-none"></div>
          <div class="absolute w-16 h-16 rounded-full bg-red-600/40 animate-ping pointer-events-none"></div>
          <div class="absolute w-10 h-10 rounded-full bg-red-500/50 animate-pulse pointer-events-none"></div>

          <!-- Pulsing Red Beacon Core -->
          <div class="relative w-5 h-5 rounded-full bg-[#DC2626] border-2 border-white shadow-[0_0_16px_rgba(220,38,38,1)] flex items-center justify-center">
            <span class="w-2 h-2 rounded-full bg-white animate-pulse"></span>
          </div>

          <!-- Hi-Vis Beacon Origin Flag Tag -->
          <div class="absolute top-6 left-1/2 -translate-x-1/2 px-2.5 py-0.5 rounded-full bg-[#DC2626] text-white text-[10px] font-black uppercase tracking-wider shadow-xl border border-white/60 whitespace-nowrap flex items-center gap-1">
            <span class="w-1.5 h-1.5 rounded-full bg-yellow-300 animate-ping"></span>
            <span>SOS: ${safeLabel}</span>
          </div>
        </div>
      `,
      className: 'custom-sos-beacon-marker',
      iconSize: [120, 52],
      iconAnchor: [60, 26],
    });
  };

  // Directional arrow icon showing compass bearing & distance along the response vector
  const getDirectionArrowIcon = (bearingDegrees: number, compassBearing: string, distanceFormatted: string) => {
    return L.divIcon({
      html: `
        <div class="flex items-center justify-center pointer-events-auto cursor-pointer -translate-x-1/2 -translate-y-1/2">
          <div class="px-2.5 py-1 rounded-full bg-[#0B1220]/95 border-2 border-[#FF365D] text-white text-[11px] font-bold shadow-2xl flex items-center gap-1.5 backdrop-blur-md">
            <svg class="w-3.5 h-3.5 text-[#FFD21F] transform transition-transform shrink-0" style="transform: rotate(${bearingDegrees}deg)" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 2L4 20l8-4 8 4z" />
            </svg>
            <span class="text-[#FFD21F] font-mono">${escapeHtml(distanceFormatted)}</span>
            <span class="text-[10px] text-slate-300 font-mono">${escapeHtml(compassBearing)}</span>
          </div>
        </div>
      `,
      className: 'custom-direction-arrow',
      iconSize: [110, 30],
      iconAnchor: [55, 15],
    });
  };

  // Standard incident icon generator
  const getIncidentIcon = (inc: MapIncidentNode, isSelected: boolean) => {
    const isCritical = inc.severity === 'CRITICAL' || inc.type === 'sos';
    const badgeLabel = escapeHtml(inc.badgeLabel || 'ALERT');
    const countLabel = escapeHtml(inc.countLabel || inc.severity);
    const selectedClass = isSelected ? 'scale-110 ring-4 ring-[#FFC400]' : '';

    if (isCritical) {
      return getSosBeaconIcon(inc.title || badgeLabel, isSelected);
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

  if (!computedCenter) {
    return (
      <div className="flex h-full min-h-[320px] items-center justify-center rounded-xl border border-dashed border-slate-300 bg-slate-50 p-6 text-center text-sm text-slate-600 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-300">
        No consented GPS coordinates have reached the gateway yet. Devices without a shared location remain visible in the device list.
      </div>
    );
  }

  // Check if selected entity has coordinates pending
  const isSelectionCoordsPending =
    (selectedIncident && !isValidCoordinate(selectedIncident.lat, selectedIncident.lng)) ||
    (selectedDevice && !isValidCoordinate(selectedDevice.lat, selectedDevice.lng));

  return (
    <div className="relative w-full h-full overflow-hidden">
      {/* Dynamic Navigation HUD Overlay */}
      {activeNavigationVector && !isHudMinimized && (
        <div className="absolute top-4 right-4 z-[400] max-w-sm sm:max-w-md w-full bg-[#0B1220]/95 backdrop-blur-md border-2 border-red-500/80 rounded-2xl p-3.5 shadow-2xl text-white animate-in fade-in slide-in-from-right-4 duration-300 ring-4 ring-red-500/10">
          <div className="flex items-center justify-between pb-2 mb-2 border-b border-red-900/50">
            <div className="flex items-center gap-2">
              <span className="relative flex h-2.5 w-2.5">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-red-400 opacity-75" />
                <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-red-600" />
              </span>
              <span className="text-[11px] font-black tracking-wider text-red-400 uppercase font-mono flex items-center gap-1">
                <ShieldAlert className="w-3.5 h-3.5 text-red-500" />
                ACTIVE RESPONSE VECTOR
              </span>
            </div>
            <div className="flex items-center gap-1.5">
              <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-amber-500/20 text-amber-300 border border-amber-500/30">
                BEARING {activeNavigationVector.bearingDegrees}° {activeNavigationVector.compassBearing}
              </span>
              <button
                onClick={() => setIsHudMinimized(true)}
                aria-label="Minimize HUD"
                className="text-slate-400 hover:text-white p-1 rounded hover:bg-slate-800 cursor-pointer"
              >
                <X className="w-3.5 h-3.5" />
              </button>
            </div>
          </div>

          <div className="space-y-1.5">
            <div className="text-xs font-bold text-slate-100 flex items-center gap-1.5 flex-wrap">
              <span className="text-emerald-400 font-mono">
                {activeNavigationVector.responder.name}
              </span>
              <ArrowRight className="w-3.5 h-3.5 text-amber-400 shrink-0" />
              <span className="text-red-400 font-mono">
                Survivor ({activeNavigationVector.target.name})
              </span>
            </div>

            <div className="flex items-center justify-between text-xs pt-1 border-t border-slate-800">
              <div className="flex items-center gap-1 text-amber-300 font-mono font-bold">
                <Navigation className="w-3.5 h-3.5 text-amber-400" />
                <span>{activeNavigationVector.distanceFormatted}</span>
              </div>
              <div className="flex items-center gap-1 text-cyan-300 font-mono text-[11px]">
                <Compass className="w-3.5 h-3.5 text-cyan-400" />
                <span>Bearing {activeNavigationVector.bearingDegrees}° {activeNavigationVector.compassBearing}</span>
              </div>
              <div className="text-[11px] font-mono text-emerald-400">
                ETA: ~{activeNavigationVector.etaMinutes} min
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Minimized HUD Pill */}
      {activeNavigationVector && isHudMinimized && (
        <button
          onClick={() => setIsHudMinimized(false)}
          className="absolute top-4 right-4 z-[400] flex items-center gap-2 px-3 py-1.5 rounded-full bg-[#0B1220]/95 backdrop-blur-md border border-red-500 text-white text-xs font-bold shadow-xl hover:bg-[#162036] transition-all cursor-pointer"
        >
          <span className="w-2 h-2 rounded-full bg-red-500 animate-ping" />
          <span>Vector HUD: {activeNavigationVector.distanceFormatted} ({activeNavigationVector.compassBearing})</span>
          <ChevronDown className="w-3 h-3 text-slate-400" />
        </button>
      )}

      {/* Pending Coordinates Warning Banner */}
      {isSelectionCoordsPending && (
        <div className="absolute top-4 right-4 z-[400] max-w-sm bg-[#0B1220]/90 backdrop-blur-md border border-amber-500/60 rounded-xl p-3 shadow-xl text-amber-200 text-xs flex items-center gap-2 animate-in fade-in duration-200">
          <AlertTriangle className="w-4 h-4 text-amber-400 shrink-0" />
          <div>
            <strong>GPS Coordinates Pending:</strong> Selected node is acquiring satellite fix via mesh hops.
          </div>
        </div>
      )}

      <MapContainer
        center={computedCenter}
        zoom={zoom}
        zoomControl={false}
        className="w-full h-full z-0"
        style={{ height: '100%', width: '100%', background: '#0B1220' }}
      >
        {/* OpenStreetMap Tile Layer */}
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

        {/* Dynamic Glowing Neon Response Polylines for Active SOS & Selected Nodes */}
        {allSosVectors.map((vector) => {
          const isPrimary = activeNavigationVector?.target.id === vector.target.id;
          return (
            <React.Fragment key={`sos-vector-${vector.target.id}`}>
              {/* Outer Neon Glow Polyline */}
              <Polyline
                positions={[
                  [vector.responder.lat, vector.responder.lng],
                  [vector.target.lat, vector.target.lng],
                ]}
                pathOptions={{
                  color: isPrimary ? '#FF365D' : '#FF7043',
                  weight: isPrimary ? 8 : 5,
                  opacity: isPrimary ? 0.4 : 0.25,
                  lineCap: 'round',
                  className: 'leaflet-sos-neon-glow',
                }}
              />

              {/* Core Dynamic Animated Dashed Polyline */}
              <Polyline
                positions={[
                  [vector.responder.lat, vector.responder.lng],
                  [vector.target.lat, vector.target.lng],
                ]}
                pathOptions={{
                  color: isPrimary ? '#FFD21F' : '#FFA726',
                  weight: isPrimary ? 3.5 : 2.5,
                  dashArray: '10, 14',
                  opacity: 0.95,
                  className: 'leaflet-sos-neon-path',
                }}
              >
                <Popup>
                  <div className="p-2 font-sans text-xs min-w-[200px]">
                    <div className="font-bold text-red-600 uppercase text-[10px] flex items-center gap-1">
                      <span>🚨 Rapid Response Direction Path</span>
                    </div>
                    <div className="font-bold text-slate-900 dark:text-white my-1 text-xs">
                      {vector.hudText}
                    </div>
                    <div className="text-[11px] text-slate-600 dark:text-slate-300">
                      Estimated Response Time: <strong>~{vector.etaMinutes} min</strong> (Tactical speed)
                    </div>
                  </div>
                </Popup>
              </Polyline>

              {/* Directional Arrow / Compass Midpoint Marker */}
              <Marker
                position={vector.midpoint}
                icon={getDirectionArrowIcon(
                  vector.bearingDegrees,
                  vector.compassBearing,
                  vector.distanceFormatted
                )}
              >
                <Tooltip direction="top" offset={[0, -14]} opacity={0.95}>
                  <div className="font-sans text-xs font-semibold">
                    <span>{vector.hudText}</span>
                  </div>
                </Tooltip>
              </Marker>
            </React.Fragment>
          );
        })}

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
            if (!isValidCoordinate(inc.lat, inc.lng)) return null;
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
            if (!isValidCoordinate(team.lat, team.lng)) return null;
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
            if (!isValidCoordinate(device.lat, device.lng)) return null;
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
