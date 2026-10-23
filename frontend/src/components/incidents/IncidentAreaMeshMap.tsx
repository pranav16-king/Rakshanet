import React, { useEffect, useRef, useState, useMemo } from 'react';
import L from 'leaflet';
import {
  Layers,
  Maximize2,
  Navigation,
  Radio,
  ShieldAlert,
  Users,
  Compass,
  Battery,
  Clock,
  MapPin,
  CheckCircle2,
  Anchor,
  Truck,
  Activity,
} from 'lucide-react';
import type { Incident, IncidentMeshTopologyResponse, IncidentBeaconPoint, IncidentMeshRelayNode, IncidentRescueUnitLocation } from '../../types/incident.ts';
import { useTheme } from '../../theme/ThemeContext.tsx';

interface IncidentAreaMeshMapProps {
  incident: Incident;
  topology?: IncidentMeshTopologyResponse | null;
  height?: string;
  onSelectNode?: (type: 'BEACON' | 'RELAY' | 'UNIT', id: string) => void;
}

export const IncidentAreaMeshMap: React.FC<IncidentAreaMeshMapProps> = ({
  incident,
  topology,
  height = '480px',
  onSelectNode,
}) => {
  const mapContainerRef = useRef<HTMLDivElement | null>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const { isDark } = useTheme();

  const [mapStyle, setMapStyle] = useState<'satellite' | 'street' | 'dark'>(() =>
    isDark ? 'satellite' : 'satellite'
  );

  // Layer Visibility Toggles
  const [showBeacons, setShowBeacons] = useState(true);
  const [showRelays, setShowRelays] = useState(true);
  const [showRescueUnits, setShowRescueUnits] = useState(true);
  const [showGeofence, setShowGeofence] = useState(true);

  // Selected item modal/drawer inside map
  const [selectedItem, setSelectedItem] = useState<{
    type: 'BEACON' | 'RELAY' | 'UNIT' | 'CENTROID';
    data: any;
  } | null>(null);

  const tileUrls = {
    satellite:
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    dark: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
    street: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
  };

  const tileAttributions = {
    satellite: 'Tiles &copy; Esri &mdash; Source: Esri, i-cubed, USDA, USGS',
    dark: '&copy; OpenStreetMap contributors, Humanitarian Style',
    street: '&copy; OpenStreetMap contributors',
  };

  const lat = incident.coordinates?.lat ?? topology?.centroid?.lat;
  const lng = incident.coordinates?.lng ?? topology?.centroid?.lng;
  const radius = incident.clusterRadiusMeters ?? topology?.radius_meters;

  const beacons = useMemo(() => topology?.sos_beacons || [], [topology]);


  const relays = useMemo(() => topology?.mesh_relays || [], [topology]);

  const rescueUnits = useMemo(() => topology?.rescue_units || [], [topology]);



  // Initialize and redraw map
  useEffect(() => {
    if (!mapContainerRef.current || !Number.isFinite(lat) || !Number.isFinite(lng)) return;

    if (mapInstanceRef.current) {
      mapInstanceRef.current.remove();
      mapInstanceRef.current = null;
    }

    const map = L.map(mapContainerRef.current, {
      center: [lat, lng],
      zoom: 15,
      zoomControl: false,
    });
    mapInstanceRef.current = map;

    L.control.zoom({ position: 'topleft' }).addTo(map);

    L.tileLayer(tileUrls[mapStyle], {
      attribution: tileAttributions[mapStyle],
      maxZoom: 19,
    }).addTo(map);

    // 1. Geofence polygon / circle
    if (showGeofence) {
      if (incident.polygonCoords && incident.polygonCoords.length > 0) {
        L.polygon(incident.polygonCoords, {
          color: '#D92D20',
          weight: 2,
          dashArray: '4, 6',
          fillColor: '#D92D20',
          fillOpacity: 0.22,
        }).addTo(map);
      } else if (typeof radius === 'number') {
        L.circle([lat, lng], {
          radius: radius,
          color: '#D92D20',
          weight: 2,
          dashArray: '5, 5',
          fillColor: '#D92D20',
          fillOpacity: 0.2,
        }).addTo(map);
      }
    }

    // 2. Incident Centroid Marker
    const centroidIcon = L.divIcon({
      className: 'custom-centroid-marker',
      html: `
        <div style="position: relative; width: 36px; height: 36px; display: flex; align-items: center; justify-content: center;">
          <div style="position: absolute; width: 36px; height: 36px; border-radius: 50%; background: rgba(217, 45, 32, 0.4); animation: ping 2s cubic-bezier(0, 0, 0.2, 1) infinite;"></div>
          <div style="width: 22px; height: 22px; border-radius: 50%; background: #D92D20; border: 2.5px solid white; box-shadow: 0 2px 8px rgba(0,0,0,0.4); display: flex; align-items: center; justify-content: center; color: white; font-weight: bold; font-size: 11px;">!</div>
        </div>
      `,
      iconSize: [36, 36],
      iconAnchor: [18, 18],
    });

    const centroidMarker = L.marker([lat, lng], { icon: centroidIcon }).addTo(map);
    centroidMarker.on('click', () => {
      setSelectedItem({
        type: 'CENTROID',
        data: {
          title: incident.title,
          lat,
          lng,
          radius,
          severity: incident.severity,
          affectedPeople: incident.affectedPeople,
        },
      });
    });

    // 3. SOS Beacons
    if (showBeacons) {
      beacons.forEach((b: IncidentBeaconPoint) => {
        const isCritical = b.status.includes('CRITICAL') || b.status.includes('TRAPPED');
        const iconColor = isCritical ? '#EF4444' : '#F59E0B';

        const beaconIcon = L.divIcon({
          className: 'custom-sos-beacon',
          html: `
            <div style="position: relative; width: 32px; height: 32px; display: flex; align-items: center; justify-content: center; cursor: pointer;">
              <div style="position: absolute; width: 30px; height: 30px; border-radius: 50%; background: ${iconColor}; opacity: 0.35; animation: pulse 1.8s ease-in-out infinite;"></div>
              <div style="width: 20px; height: 20px; border-radius: 50%; background: ${iconColor}; border: 2px solid white; display: flex; align-items: center; justify-content: center; color: white; font-size: 9px; font-weight: 900; box-shadow: 0 2px 6px rgba(0,0,0,0.5);">
                ${b.casualties}
              </div>
            </div>
          `,
          iconSize: [32, 32],
          iconAnchor: [16, 16],
        });

        const marker = L.marker([b.lat, b.lng], { icon: beaconIcon }).addTo(map);
        marker.on('click', () => {
          setSelectedItem({ type: 'BEACON', data: b });
          if (onSelectNode) onSelectNode('BEACON', b.beacon_id);
        });
      });
    }

    // 4. Mesh Relay Nodes
    if (showRelays) {
      relays.forEach((r: IncidentMeshRelayNode) => {
        const relayIcon = L.divIcon({
          className: 'custom-mesh-relay',
          html: `
            <div style="position: relative; width: 28px; height: 28px; display: flex; align-items: center; justify-content: center; cursor: pointer;">
              <div style="width: 18px; height: 18px; border-radius: 6px; background: #06B6D4; border: 2px solid white; transform: rotate(45deg); box-shadow: 0 2px 6px rgba(0,0,0,0.4);"></div>
              <div style="position: absolute; color: white; font-size: 10px; font-weight: bold; pointer-events: none;">R</div>
            </div>
          `,
          iconSize: [28, 28],
          iconAnchor: [14, 14],
        });

        const marker = L.marker([r.lat, r.lng], { icon: relayIcon }).addTo(map);
        marker.on('click', () => {
          setSelectedItem({ type: 'RELAY', data: r });
          if (onSelectNode) onSelectNode('RELAY', r.relay_id);
        });
      });
    }

    // 5. Rescue Units
    if (showRescueUnits) {
      rescueUnits.forEach((u: IncidentRescueUnitLocation) => {
        const isBoat = u.type === 'BOAT';
        const unitColor = '#10B981';

        const unitIcon = L.divIcon({
          className: 'custom-rescue-unit',
          html: `
            <div style="position: relative; width: 30px; height: 30px; display: flex; align-items: center; justify-content: center; cursor: pointer;">
              <div style="width: 22px; height: 22px; border-radius: 50%; background: ${unitColor}; border: 2px solid white; display: flex; align-items: center; justify-content: center; color: white; box-shadow: 0 2px 8px rgba(0,0,0,0.5); font-size: 11px;">
                ${isBoat ? '⛵' : '🚑'}
              </div>
            </div>
          `,
          iconSize: [30, 30],
          iconAnchor: [15, 15],
        });

        const marker = L.marker([u.lat, u.lng], { icon: unitIcon }).addTo(map);
        marker.on('click', () => {
          setSelectedItem({ type: 'UNIT', data: u });
          if (onSelectNode) onSelectNode('UNIT', u.unit_id);
        });
      });
    }

    return () => {
      if (mapInstanceRef.current) {
        mapInstanceRef.current.remove();
        mapInstanceRef.current = null;
      }
    };
  }, [
    lat,
    lng,
    radius,
    incident,
    beacons,
    relays,
    rescueUnits,
    showBeacons,
    showRelays,
    showRescueUnits,
    showGeofence,
    mapStyle,
    onSelectNode,
  ]);

  if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
    return <div className="flex items-center justify-center rounded-xl border border-dashed border-slate-300 p-6 text-center text-sm text-slate-600 dark:border-slate-700 dark:text-slate-300" style={{ height }}>No consented incident coordinates are available for this map.</div>;
  }

  const recenterMap = () => {
    if (mapInstanceRef.current) {
      mapInstanceRef.current.setView([lat, lng], 15);
    }
  };

  return (
    <div
      className="relative rounded-2xl overflow-hidden border border-[#E2E8F0] dark:border-[#1E293B] shadow-sm flex flex-col"
      style={{ height }}
    >
      {/* Map Control Bar Overlay */}
      <div className="absolute top-3 right-3 z-[400] flex flex-wrap items-center gap-1.5 bg-white/90 dark:bg-[#111A2E]/90 backdrop-blur-md p-1.5 rounded-xl border border-[#E2E8F0] dark:border-[#1E293B] shadow-lg">
        {/* Layer Toggles */}
        <button
          onClick={() => setShowBeacons(!showBeacons)}
          className={`px-2 py-1 text-[11px] font-bold rounded-lg transition-colors flex items-center gap-1 ${
            showBeacons
              ? 'bg-red-500/15 text-red-600 dark:text-red-400 border border-red-500/30'
              : 'opacity-50 text-[#64748B]'
          }`}
          title="Toggle SOS Distress Pins"
        >
          <span className="w-2 h-2 rounded-full bg-red-500" />
          <span>SOS ({beacons.length})</span>
        </button>

        <button
          onClick={() => setShowRelays(!showRelays)}
          className={`px-2 py-1 text-[11px] font-bold rounded-lg transition-colors flex items-center gap-1 ${
            showRelays
              ? 'bg-cyan-500/15 text-cyan-600 dark:text-cyan-400 border border-cyan-500/30'
              : 'opacity-50 text-[#64748B]'
          }`}
          title="Toggle Mesh Relays"
        >
          <span className="w-2 h-2 rounded-full bg-cyan-500" />
          <span>Relays ({relays.length})</span>
        </button>

        <button
          onClick={() => setShowRescueUnits(!showRescueUnits)}
          className={`px-2 py-1 text-[11px] font-bold rounded-lg transition-colors flex items-center gap-1 ${
            showRescueUnits
              ? 'bg-emerald-500/15 text-emerald-600 dark:text-emerald-400 border border-emerald-500/30'
              : 'opacity-50 text-[#64748B]'
          }`}
          title="Toggle Rescue Units"
        >
          <span className="w-2 h-2 rounded-full bg-emerald-500" />
          <span>Units ({rescueUnits.length})</span>
        </button>

        <button
          onClick={() => setShowGeofence(!showGeofence)}
          className={`px-2 py-1 text-[11px] font-bold rounded-lg transition-colors ${
            showGeofence
              ? 'bg-[#FFD21F]/20 text-amber-700 dark:text-amber-300 border border-amber-500/30'
              : 'opacity-50 text-[#64748B]'
          }`}
          title="Toggle Cluster Radius Geofence"
        >
          <span>Geofence</span>
        </button>

        <div className="h-4 w-[1px] bg-gray-300 dark:bg-gray-700 mx-0.5" />

        {/* Style Selector */}
        <select
          value={mapStyle}
          onChange={(e) => setMapStyle(e.target.value as any)}
          className="text-[11px] font-semibold bg-transparent border-0 outline-none cursor-pointer text-[#334155] dark:text-[#CBD5E1]"
        >
          <option value="satellite">Satellite</option>
          <option value="street">Humanitarian</option>
          <option value="dark">Tactical</option>
        </select>

        <button
          onClick={recenterMap}
          className="p-1 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 text-[#64748B]"
          title="Recenter Map"
        >
          <Navigation className="w-3.5 h-3.5" />
        </button>
      </div>

      {/* Main Map DOM */}
      <div ref={mapContainerRef} className="w-full h-full z-0" />

      {/* Selected Node Drawer Popup */}
      {selectedItem && (
        <div className="absolute bottom-3 left-3 right-3 sm:right-auto sm:w-80 z-[400] bg-white/95 dark:bg-[#111A2E]/95 backdrop-blur-md p-4 rounded-xl border border-[#E2E8F0] dark:border-[#1E293B] shadow-2xl animate-in fade-in slide-in-from-bottom-2">
          <div className="flex items-start justify-between">
            <div className="flex items-center gap-2">
              {selectedItem.type === 'BEACON' && (
                <div className="p-1.5 rounded-lg bg-red-500/20 text-red-600 dark:text-red-400">
                  <ShieldAlert className="w-4 h-4" />
                </div>
              )}
              {selectedItem.type === 'RELAY' && (
                <div className="p-1.5 rounded-lg bg-cyan-500/20 text-cyan-600 dark:text-cyan-400">
                  <Radio className="w-4 h-4" />
                </div>
              )}
              {selectedItem.type === 'UNIT' && (
                <div className="p-1.5 rounded-lg bg-emerald-500/20 text-emerald-600 dark:text-emerald-400">
                  <CheckCircle2 className="w-4 h-4" />
                </div>
              )}
              {selectedItem.type === 'CENTROID' && (
                <div className="p-1.5 rounded-lg bg-amber-500/20 text-amber-600 dark:text-amber-400">
                  <MapPin className="w-4 h-4" />
                </div>
              )}
              <div>
                <h4 className="text-xs font-bold text-[#0F172A] dark:text-[#F8FAFC]">
                  {selectedItem.data.name || selectedItem.data.title || selectedItem.data.relay_id}
                </h4>
                <span className="text-[10px] text-[#64748B] dark:text-[#94A3B8] font-mono">
                  {selectedItem.data.device_id || selectedItem.data.unit_id || selectedItem.type}
                </span>
              </div>
            </div>
            <button
              onClick={() => setSelectedItem(null)}
              className="text-[#94A3B8] hover:text-[#0F172A] dark:hover:text-[#F8FAFC] text-sm"
            >
              ✕
            </button>
          </div>

          <div className="mt-3 space-y-1.5 text-[11px] text-[#475569] dark:text-[#CBD5E1]">
            {selectedItem.type === 'BEACON' && (
              <>
                <div className="flex justify-between">
                  <span>Casualties at pin:</span>
                  <strong className="text-red-500 font-bold">{selectedItem.data.casualties} souls</strong>
                </div>
                <div className="flex justify-between">
                  <span>Battery Status:</span>
                  <span className="font-mono">{selectedItem.data.battery}% remaining</span>
                </div>
                <div className="flex justify-between">
                  <span>Status:</span>
                  <span className="font-semibold text-amber-600">{selectedItem.data.status}</span>
                </div>
                <div className="flex justify-between">
                  <span>Coordinates:</span>
                  <span className="font-mono text-[10px]">{selectedItem.data.lat.toFixed(4)}, {selectedItem.data.lng.toFixed(4)}</span>
                </div>
              </>
            )}

            {selectedItem.type === 'RELAY' && (
              <>
                <div className="flex justify-between">
                  <span>Relay Hops to Gateway:</span>
                  <strong className="text-cyan-500">{selectedItem.data.hops_to_gateway} hop</strong>
                </div>
                <div className="flex justify-between">
                  <span>Packets Forwarded:</span>
                  <span className="font-mono">{selectedItem.data.packets_forwarded}</span>
                </div>
                <div className="flex justify-between">
                  <span>Battery Health:</span>
                  <span className="font-mono text-emerald-500">{selectedItem.data.battery}%</span>
                </div>
              </>
            )}

            {selectedItem.type === 'UNIT' && (
              <>
                <div className="flex justify-between">
                  <span>Deployment Status:</span>
                  <strong className="text-emerald-500">{selectedItem.data.status}</strong>
                </div>
                {selectedItem.data.eta_minutes && (
                  <div className="flex justify-between">
                    <span>Extraction ETA:</span>
                    <strong className="text-amber-500">~{selectedItem.data.eta_minutes} mins</strong>
                  </div>
                )}
              </>
            )}

            {selectedItem.type === 'CENTROID' && (
              <>
                <div className="flex justify-between">
                  <span>Cluster Radius:</span>
                  <span>{selectedItem.data.radius} meters</span>
                </div>
                <div className="flex justify-between">
                  <span>Affected Population:</span>
                  <strong className="text-red-500">{selectedItem.data.affectedPeople} estimated</strong>
                </div>
              </>
            )}
          </div>
        </div>
      )}
    </div>
  );
};
