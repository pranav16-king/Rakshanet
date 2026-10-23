/**
 * RakshaNet — Master Map Container & Viewport
 * Source: design.md Section 8 and media_1791015140209.jpg
 */

import React, { useEffect, useRef } from 'react';
import { MapContainer } from 'react-leaflet';
import type { Map as LeafletMap, LatLngExpression } from 'leaflet';
import { RakshaTileLayer, type MapTileTheme } from './tileLayers';
import { injectMapSvgPatterns } from './vectorCanvas';
import './map.css';

export interface RakshaMapViewProps {
  center?: LatLngExpression;
  zoom?: number;
  minZoom?: number;
  maxZoom?: number;
  theme?: MapTileTheme;
  isOffline?: boolean;
  className?: string;
  style?: React.CSSProperties;
  children?: React.ReactNode;
  onMapReady?: (map: LeafletMap) => void;
}

/**
 * Tactical command center map view with support for online tiles (dark/light)
 * and offline procedural grid vector canvas.
 */
export function RakshaMapView({
  center = [30.1455, 78.4984], // Default: Uttarakhand / Himalayan disaster-prone zone
  zoom = 13,
  minZoom = 3,
  maxZoom = 20,
  theme = 'dark',
  isOffline = false,
  className = '',
  style,
  children,
  onMapReady,
}: RakshaMapViewProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<LeafletMap | null>(null);

  useEffect(() => {
    // Inject custom SVG patterns (such as hatched pattern for communication gaps)
    injectMapSvgPatterns();
  }, []);

  const isLight = theme === 'light';

  return (
    <div
      ref={containerRef}
      className={`raksha-map-container ${isLight ? 'theme-light' : 'theme-dark'} ${className}`}
      style={style}
    >
      {/* Offline Grid Watermark indicator when in disconnected mode */}
      {(isOffline || theme === 'offline') && (
        <div className="sr-offline-watermark" role="status">
          <span style={{ display: 'inline-block', width: 8, height: 8, borderRadius: '50%', backgroundColor: '#FFC400' }} />
          <span>OFFLINE MESH GRID · DISCONNECTED MODE</span>
        </div>
      )}

      <MapContainer
        center={center}
        zoom={zoom}
        minZoom={minZoom}
        maxZoom={maxZoom}
        zoomControl={true}
        scrollWheelZoom={true}
        style={{ width: '100%', height: '100%' }}
        ref={(instance) => {
          if (instance) {
            mapRef.current = instance;
            if (onMapReady) {
              onMapReady(instance);
            }
          }
        }}
      >
        <RakshaTileLayer theme={theme} isOffline={isOffline} />
        {children}
      </MapContainer>
    </div>
  );
}
