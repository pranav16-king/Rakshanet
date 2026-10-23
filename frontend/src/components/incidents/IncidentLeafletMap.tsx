import React, { useEffect, useRef, useState } from 'react';
import L from 'leaflet';
import { Layers, Maximize2, Navigation, AlertTriangle } from 'lucide-react';
import type { Incident } from '../../types/incident.ts';
import { useTheme } from '../../theme/ThemeContext.tsx';

interface IncidentLeafletMapProps {
  incident: Incident;
  height?: string;
}

export const IncidentLeafletMap: React.FC<IncidentLeafletMapProps> = ({
  incident,
  height = '380px',
}) => {
  const mapContainerRef = useRef<HTMLDivElement | null>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const { isDark } = useTheme();
  const coordinates = incident.coordinates;
  const hasCoordinates =
    typeof coordinates?.lat === 'number' && Number.isFinite(coordinates.lat) &&
    typeof coordinates?.lng === 'number' && Number.isFinite(coordinates.lng);
  const radiusMeters =
    typeof incident.clusterRadiusMeters === 'number' && Number.isFinite(incident.clusterRadiusMeters)
      ? incident.clusterRadiusMeters
      : undefined;
  const [mapStyle, setMapStyle] = useState<'satellite' | 'street' | 'dark'>(() =>
    isDark ? 'satellite' : 'satellite'
  );

  const tileUrls = {
    satellite: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    dark: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
    street: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
  };

  const tileAttributions = {
    satellite: 'Tiles &copy; Esri &mdash; Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community',
    dark: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors, Tiles style by Humanitarian OpenStreetMap Team',
    street: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
  };

  // Re-initialize map
  useEffect(() => {
    if (!mapContainerRef.current || !hasCoordinates) return;

    // Clean up previous instance
    if (mapInstanceRef.current) {
      mapInstanceRef.current.remove();
      mapInstanceRef.current = null;
    }

    const { lat, lng } = coordinates;
    const map = L.map(mapContainerRef.current, {
      center: [lat, lng],
      zoom: 13,
      zoomControl: false,
    });

    // Add zoom control top left
    L.control.zoom({ position: 'topleft' }).addTo(map);

    // Add Tile Layer
    const currentLayer = L.tileLayer(tileUrls[mapStyle], {
      attribution: tileAttributions[mapStyle],
      maxZoom: 19,
    }).addTo(map);

    // Affected Area Polygon
    if (incident.polygonCoords && incident.polygonCoords.length > 0) {
      const polygon = L.polygon(incident.polygonCoords, {
        color: '#D92D20',
        weight: 2,
        dashArray: '4, 6',
        fillColor: '#D92D20',
        fillOpacity: 0.28,
      }).addTo(map);

      polygon.bindPopup(`
        <div style="font-family: sans-serif; padding: 4px;">
          <strong style="color: #D92D20; font-size: 13px;">${incident.title}</strong>
          <div style="font-size: 11px; margin-top: 4px; color: #555;">Affected Area: ~${incident.affectedAreaKm2} km²</div>
          <div style="font-size: 11px; color: #555;">Casualties: ~${incident.affectedPeople} survivors</div>
        </div>
      `);
    } else if (radiusMeters !== undefined) {
      // Centroid Circle & Radius
      const circle = L.circle([lat, lng], {
        radius: radiusMeters,
        color: '#D92D20',
        weight: 2,
        dashArray: '4, 6',
        fillColor: '#D92D20',
        fillOpacity: 0.25,
      }).addTo(map);

      circle.bindPopup(`
        <div style="font-family: sans-serif; padding: 4px;">
          <strong style="color: #D92D20;">${incident.title}</strong>
          <div style="font-size: 11px; margin-top: 4px;">Radius: ${incident.clusterRadiusMeters}m</div>
        </div>
      `);
    }

    // Centroid Beacon Marker
    const centroidIcon = L.divIcon({
      className: 'custom-centroid-marker',
      html: `
        <div style="position: relative; width: 32px; height: 32px; display: flex; align-items: center; justify-content: center;">
          <div style="position: absolute; width: 32px; height: 32px; border-radius: 50%; background: rgba(217, 45, 32, 0.4); animation: ping 1.5s cubic-bezier(0, 0, 0.2, 1) infinite;"></div>
          <div style="width: 16px; height: 16px; border-radius: 50%; background: #D92D20; border: 2px solid #FFFFFF; box-shadow: 0 2px 6px rgba(0,0,0,0.4);"></div>
        </div>
      `,
      iconSize: [32, 32],
      iconAnchor: [16, 16],
    });

    const centroidMarker = L.marker([lat, lng], { icon: centroidIcon }).addTo(map);
    centroidMarker.bindTooltip(`Centroid: ${incident.id}`, {
      permanent: false,
      direction: 'top',
    });

    mapInstanceRef.current = map;

    return () => {
      currentLayer.remove();
      map.remove();
      mapInstanceRef.current = null;
    };
  }, [coordinates, hasCoordinates, incident.id, incident.polygonCoords, incident.title, mapStyle, radiusMeters]);

  const recenterMap = () => {
    if (mapInstanceRef.current && hasCoordinates) {
      mapInstanceRef.current.setView([coordinates.lat, coordinates.lng], 13);
    }
  };

  const cycleMapLayer = () => {
    setMapStyle((prev) => (prev === 'satellite' ? 'dark' : prev === 'dark' ? 'street' : 'satellite'));
  };

  if (!hasCoordinates) {
    return (
      <div className="flex h-full min-h-[220px] flex-col items-center justify-center gap-2 rounded-xl border border-[#E2E8F0] bg-[#F8FAFC] p-6 text-center text-[#64748B] dark:border-[#26344F] dark:bg-[#111A2E] dark:text-[#94A3B8]" style={{ height }}>
        <AlertTriangle size={24} className="text-amber-500" />
        <strong className="text-sm">Map unavailable</strong>
        <span className="text-xs">This incident has no reported coordinates.</span>
      </div>
    );
  }

  return (
    <div
      className="relative w-full rounded-xl overflow-hidden border shadow-sm transition-colors"
      style={{ height }}
    >
      {/* Map DOM Element */}
      <div ref={mapContainerRef} className="w-full h-full z-10" />

      {/* Floating Tactical Overlay Controls */}
      <div className="absolute top-3 right-3 z-20 flex items-center gap-2">
        <button
          type="button"
          onClick={cycleMapLayer}
          title={`Switch layer (Current: ${mapStyle.toUpperCase()})`}
          className="px-2.5 py-1.5 rounded-lg bg-[#0B1220]/85 hover:bg-[#0B1220] text-white text-xs font-semibold backdrop-blur border border-white/20 flex items-center gap-1.5 transition-all shadow-md"
        >
          <Layers size={13} className="text-[#FFC400]" />
          <span className="capitalize">{mapStyle}</span>
        </button>

        <button
          type="button"
          onClick={recenterMap}
          title="Recenter on Incident Centroid"
          className="p-1.5 rounded-lg bg-[#0B1220]/85 hover:bg-[#0B1220] text-white backdrop-blur border border-white/20 transition-all shadow-md"
        >
          <Navigation size={15} className="text-[#FFC400]" />
        </button>

        <button
          type="button"
          onClick={() => {
            if (mapContainerRef.current) {
              if (!document.fullscreenElement) {
                mapContainerRef.current.requestFullscreen?.();
              } else {
                document.exitFullscreen?.();
              }
            }
          }}
          title="Toggle Fullscreen"
          className="p-1.5 rounded-lg bg-[#0B1220]/85 hover:bg-[#0B1220] text-white backdrop-blur border border-white/20 transition-all shadow-md"
        >
          <Maximize2 size={15} />
        </button>
      </div>

      {/* Bottom Map Info Strip */}
      <div className="absolute bottom-2 left-3 z-20 pointer-events-none">
        <div className="bg-[#0B1220]/85 backdrop-blur px-3 py-1 rounded-md text-[11px] font-mono text-white/90 border border-white/10 flex items-center gap-2">
          <span className="inline-block w-2 h-2 rounded-full bg-[#D92D20] animate-pulse"></span>
          <span>
            CENTROID: {incident.coordinates.lat.toFixed(4)}°N, {incident.coordinates.lng.toFixed(4)}°E
          </span>
          <span className="text-[#FFC400]">| ~{incident.affectedAreaKm2} km²</span>
        </div>
      </div>
    </div>
  );
};
