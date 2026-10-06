import React, { useMemo } from 'react';
import {
  MapContainer,
  TileLayer,
  Marker,
  Polygon,
  Polyline,
  useMap,
} from 'react-leaflet';
import L from 'leaflet';
import { Plus, Minus, Crosshair } from 'lucide-react';
import { MapIncidentNode, LiveDevice, MapLayersState } from '../../types/map';

export interface MapCanvasProps {
  incidents: MapIncidentNode[];
  devices: LiveDevice[];
  layers: MapLayersState;
  selectedIncident: MapIncidentNode | null;
  selectedDevice: LiveDevice | null;
  onSelectIncident: (node: MapIncidentNode) => void;
  onSelectDevice: (device: LiveDevice) => void;
  center?: [number, number];
  zoom?: number;
}

// Controller component to expose programmatic map control (Recenter, Zoom)
const MapControls: React.FC<{ defaultCenter: [number, number]; defaultZoom: number }> = ({
  defaultCenter,
  defaultZoom,
}) => {
  const map = useMap();

  return (
    <div className="leaflet-top leaflet-left !top-20 !left-4 z-[400] flex flex-col gap-2">
      <div className="flex flex-col bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] rounded-xl shadow-md overflow-hidden">
        <button
          type="button"
          onClick={() => map.zoomIn()}
          aria-label="Zoom in"
          className="p-2 text-[#16202D] dark:text-[#EEF2F8] hover:bg-[#FFFCEB] dark:hover:bg-[#1C2844] transition-colors border-b border-[#E6DCA8] dark:border-[#26344F] cursor-pointer"
        >
          <Plus className="w-4 h-4" />
        </button>
        <button
          type="button"
          onClick={() => map.zoomOut()}
          aria-label="Zoom out"
          className="p-2 text-[#16202D] dark:text-[#EEF2F8] hover:bg-[#FFFCEB] dark:hover:bg-[#1C2844] transition-colors cursor-pointer"
        >
          <Minus className="w-4 h-4" />
        </button>
      </div>

      <button
        type="button"
        onClick={() => map.flyTo(defaultCenter, defaultZoom, { duration: 1.2 })}
        aria-label="Recenter map"
        className="p-2 bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] rounded-xl shadow-md text-[#16202D] dark:text-[#EEF2F8] hover:bg-[#FFFCEB] dark:hover:bg-[#1C2844] transition-colors cursor-pointer"
        title="Recenter to active disaster sector"
      >
        <Crosshair className="w-4 h-4 text-[#FFC400]" />
      </button>
    </div>
  );
};

export const MapCanvas: React.FC<MapCanvasProps> = ({
  incidents,
  devices,
  layers,
  selectedIncident,
  selectedDevice,
  onSelectIncident,
  onSelectDevice,
  center = [30.071, 79.034],
  zoom = 13,
}) => {
  // Custom Icon generators
  const createDivIcon = (html: string, className: string = '', iconSize: [number, number] = [120, 40]) => {
    return L.divIcon({
      html,
      className,
      iconSize,
      iconAnchor: [iconSize[0] / 2, iconSize[1] / 2],
    });
  };

  const icons = useMemo(() => {
    return {
      sos: createDivIcon(
        `
        <div class="relative flex items-center justify-center cursor-pointer">
          <div class="absolute w-12 h-12 rounded-full bg-red-600/35 animate-ping"></div>
          <div class="absolute w-16 h-16 rounded-full bg-red-500/20 animate-pulse"></div>
          <div class="relative px-3 py-1 rounded-full bg-[#D92D20] text-white text-xs font-bold shadow-xl border-2 border-white/40 flex items-center gap-1.5 whitespace-nowrap">
            <span class="w-2 h-2 rounded-full bg-white animate-pulse"></span>
            <span>SOS</span>
            <span class="opacity-90 font-mono text-[11px]">12 users</span>
          </div>
        </div>
        `,
        'custom-sos-marker',
        [130, 44]
      ),
      landslide: createDivIcon(
        `
        <div class="px-3 py-1 rounded-full bg-[#B45309] text-white text-xs font-bold shadow-xl border-2 border-amber-300/40 flex items-center gap-1.5 whitespace-nowrap cursor-pointer hover:scale-105 transition-transform">
          <span>Landslide</span>
          <span class="opacity-90 font-mono text-[11px]">5 devices</span>
        </div>
        `,
        'custom-landslide-marker',
        [140, 36]
      ),
      flood: createDivIcon(
        `
        <div class="px-3 py-1 rounded-full bg-[#0E8A94] text-white text-xs font-bold shadow-xl border-2 border-cyan-300/40 flex items-center gap-1.5 whitespace-nowrap cursor-pointer hover:scale-105 transition-transform">
          <span>Flood Area</span>
          <span class="opacity-90 font-mono text-[11px]">15 devices</span>
        </div>
        `,
        'custom-flood-marker',
        [144, 36]
      ),
      rescueTeam: createDivIcon(
        `
        <div class="px-3 py-1 rounded-full bg-[#1E8E4E] text-white text-xs font-bold shadow-xl border-2 border-emerald-300/40 flex items-center gap-1.5 whitespace-nowrap cursor-pointer hover:scale-105 transition-transform">
          <span>Rescue Team</span>
          <span class="opacity-90 font-mono text-[11px]">8 devices</span>
        </div>
        `,
        'custom-rescue-marker',
        [150, 36]
      ),
      deviceOnline: createDivIcon(
        `
        <div class="flex items-center gap-1 cursor-pointer">
          <div class="w-3 h-3 rounded-full bg-[#4CD08A] ring-4 ring-[#4CD08A]/30"></div>
        </div>
        `,
        'custom-device-online',
        [16, 16]
      ),
      deviceRelay: createDivIcon(
        `
        <div class="flex items-center gap-1 cursor-pointer">
          <div class="w-3 h-3 rounded-full bg-[#3CC6D0] ring-4 ring-[#3CC6D0]/30 animate-pulse"></div>
        </div>
        `,
        'custom-device-relay',
        [16, 16]
      ),
      deviceOffline: createDivIcon(
        `
        <div class="flex items-center gap-1 cursor-pointer">
          <div class="w-3 h-3 rounded-full bg-[#9FADC2] ring-2 ring-gray-600/40"></div>
        </div>
        `,
        'custom-device-offline',
        [16, 16]
      ),
    };
  }, []);

  // Mesh connections line segments connecting active devices
  const meshLines: [number, number][][] = useMemo(() => {
    return [
      [[30.076, 79.023], [30.071, 79.038]],
      [[30.071, 79.038], [30.088, 79.045]],
      [[30.076, 79.023], [30.075, 79.020]],
      [[30.071, 79.038], [30.051, 79.028]],
      [[30.051, 79.028], [30.053, 79.026]],
    ];
  }, []);

  return (
    <div className="relative w-full h-full overflow-hidden">
      <MapContainer
        center={center}
        zoom={zoom}
        zoomControl={false}
        className="w-full h-full z-0"
        style={{ height: '100%', width: '100%', background: '#0B1220' }}
      >
        {/* Free OpenStreetMap tile layer (No API key required) */}
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          subdomains="abc"
          maxZoom={19}
        />

        {/* Custom Zoom & Recenter Controls */}
        <MapControls defaultCenter={center} defaultZoom={zoom} />

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
                opacity: 0.8,
              }}
            />
          ))}

        {/* Hazard Zones: Flood Area Polygon */}
        {layers.hazardZones &&
          incidents
            .filter((inc) => inc.type === 'flood' && inc.polygonCoords)
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

        {/* Incidents Layer */}
        {layers.incidents &&
          incidents.map((inc) => {
            let icon = icons.sos;
            if (inc.type === 'landslide') icon = icons.landslide;
            if (inc.type === 'flood') icon = icons.flood;
            if (inc.type === 'rescue_team') icon = icons.rescueTeam;

            return (
              <Marker
                key={inc.id}
                position={[inc.lat, inc.lng]}
                icon={icon}
                eventHandlers={{
                  click: () => onSelectIncident(inc),
                }}
              />
            );
          })}

        {/* Live Devices Layer */}
        {layers.nearbyDevices &&
          devices.map((device) => {
            let icon = icons.deviceOnline;
            if (device.status === 'Relay') icon = icons.deviceRelay;
            if (device.status === 'Offline') icon = icons.deviceOffline;

            return (
              <Marker
                key={device.id}
                position={[device.lat, device.lng]}
                icon={icon}
                eventHandlers={{
                  click: () => onSelectDevice(device),
                }}
              />
            );
          })}
      </MapContainer>
    </div>
  );
};
