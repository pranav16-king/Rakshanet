// src/components/communication-gaps/CommunicationGapsMap.tsx
import React, { useEffect, useRef } from 'react';
import type { BlackHoleAnomaly } from '../../types';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

interface CommunicationGapsMapProps {
  anomalies: BlackHoleAnomaly[];
  selectedAnomalyId?: string;
  onSelectAnomaly?: (anomaly: BlackHoleAnomaly) => void;
}

export const CommunicationGapsMap: React.FC<CommunicationGapsMapProps> = ({
  anomalies,
  selectedAnomalyId,
  onSelectAnomaly,
}) => {
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const layerGroupRef = useRef<L.LayerGroup | null>(null);

  useEffect(() => {
    if (!mapContainerRef.current) return;

    if (!mapInstanceRef.current) {
      // Initialize Leaflet Map centered around Chennai / Tamil Nadu coordinates (13.01N, 80.24E)
      const centerLat = anomalies[0]?.center_lat || 13.0125;
      const centerLng = anomalies[0]?.center_lng || 80.2450;

      const map = L.map(mapContainerRef.current, {
        center: [centerLat, centerLng],
        zoom: 13,
        zoomControl: true,
      });

      // Dark style tile layer
      L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
        attribution: '&copy; OpenStreetMap contributors &copy; CARTO',
        maxZoom: 19,
      }).addTo(map);

      layerGroupRef.current = L.layerGroup().addTo(map);
      mapInstanceRef.current = map;
    }

    const map = mapInstanceRef.current;
    const layers = layerGroupRef.current;
    if (!map || !layers) return;

    layers.clearLayers();

    // Render hatched purple circles & silence markers for each anomaly
    anomalies.forEach((anomaly) => {
      const isSelected = selectedAnomalyId === anomaly.anomaly_id;
      const isCritical = anomaly.severity === 'CRITICAL' || anomaly.drop_percentage >= 75;

      // Hatched purple styling as specified in design.md section 2.6
      const circleColor = isCritical ? '#A98BFF' : '#7A4DD8';
      const circleFill = isCritical ? '#7A4DD8' : '#6A3DC8';

      // 1. Hatched / semi-transparent polygon/circle
      const circle = L.circle([anomaly.center_lat, anomaly.center_lng], {
        radius: anomaly.radius_meters || 750,
        color: circleColor,
        dashArray: isSelected ? '6, 4' : '4, 4',
        weight: isSelected ? 3 : 2,
        fillColor: circleFill,
        fillOpacity: 0.28,
      });

      // 2. Custom pulsing silence icon marker
      const customIcon = L.divIcon({
        className: 'custom-blackhole-pin',
        html: `
          <div style="
            position: relative;
            display: flex;
            align-items: center;
            justify-content: center;
            width: 38px;
            height: 38px;
            cursor: pointer;
          ">
            <div style="
              position: absolute;
              width: 38px;
              height: 38px;
              border-radius: 50%;
              background: rgba(169, 139, 255, 0.3);
              border: 1px dashed #A98BFF;
              animation: ping 2s cubic-bezier(0, 0, 0.2, 1) infinite;
            "></div>
            <div style="
              position: relative;
              background: #7A4DD8;
              color: white;
              font-family: monospace;
              font-weight: bold;
              font-size: 11px;
              width: 26px;
              height: 26px;
              border-radius: 50%;
              display: flex;
              align-items: center;
              justify-content: center;
              border: 2px solid #FFF;
              box-shadow: 0 0 10px rgba(122, 77, 216, 0.8);
            ">
              ⚡
            </div>
          </div>
        `,
        iconSize: [38, 38],
        iconAnchor: [19, 19],
      });

      const marker = L.marker([anomaly.center_lat, anomaly.center_lng], {
        icon: customIcon,
      });

      marker.bindPopup(`
        <div style="font-family: sans-serif; color: #16202D; min-width: 190px;">
          <div style="font-weight: bold; font-family: monospace; color: #7A4DD8; font-size: 13px;">
            ${anomaly.sector_id}
          </div>
          <div style="font-size: 12px; margin-top: 4px; font-weight: 600; color: #D92D20;">
            ${anomaly.drop_percentage.toFixed(1)}% Telemetry Blackout
          </div>
          <div style="font-size: 11px; color: #566070; margin-top: 4px;">
            Baseline: ${anomaly.baseline_nodes} nodes ➔ Now: ${anomaly.current_nodes} nodes
          </div>
          <div style="font-size: 11px; color: #16202D; margin-top: 2px;">
            Estimated trapped: ~${anomaly.estimated_silenced_people} people
          </div>
          <div style="font-size: 11px; color: #566070; margin-top: 2px;">
            Silence duration: ${anomaly.silence_duration_minutes.toFixed(0)} min
          </div>
          <div style="margin-top: 6px; padding: 4px 6px; background: #F3EEFF; border: 1px solid #C4A7FF; border-radius: 4px; font-size: 10px; font-family: monospace;">
            ${anomaly.recommended_action}
          </div>
        </div>
      `);

      marker.on('click', () => {
        onSelectAnomaly?.(anomaly);
      });

      circle.addTo(layers);
      marker.addTo(layers);
    });

    // If an anomaly is selected, fly to it
    if (selectedAnomalyId) {
      const selected = anomalies.find((a) => a.anomaly_id === selectedAnomalyId);
      if (selected) {
        map.flyTo([selected.center_lat, selected.center_lng], 14, { duration: 1 });
      }
    }
  }, [anomalies, selectedAnomalyId, onSelectAnomaly]);

  return (
    <div className="relative w-full h-[520px] rounded-xl overflow-hidden border border-purple-500/30 shadow-lg">
      <div ref={mapContainerRef} className="w-full h-full z-0" />

      {/* Map Legend Overlay */}
      <div className="absolute top-3 right-3 z-[1000] p-3 rounded-lg bg-[#0E1627]/90 backdrop-blur border border-slate-700/80 text-xs space-y-1.5 shadow-md">
        <div className="font-semibold text-slate-200">GIS Communication Layers</div>
        <div className="flex items-center gap-2 text-slate-300">
          <span className="w-3 h-3 rounded-full bg-[#7A4DD8] border border-purple-300" />
          <span>Hatched Sector (Critical &gt;75% Drop)</span>
        </div>
        <div className="flex items-center gap-2 text-slate-300">
          <span className="w-3 h-3 rounded-full bg-[#E07B00] border border-amber-300" />
          <span>Warning Sector (&gt;45% Drop)</span>
        </div>
        <div className="text-[10px] text-purple-300 mt-1 font-mono">
          Decay window: 120 min spatiotemporal
        </div>
      </div>
    </div>
  );
};
