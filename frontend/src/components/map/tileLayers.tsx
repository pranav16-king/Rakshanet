/**
 * RakshaNet / SignalRescue AI — Leaflet Tile Layer Configurations & Offline Fallbacks
 * Source: design.md and media_1791015140209.jpg
 */

import { useEffect } from 'react';
import { useMap, TileLayer } from 'react-leaflet';
import { OfflineGridLayer } from './OfflineGridLayer';

export type MapTileTheme = 'dark' | 'light' | 'stadiaDark' | 'satellite' | 'offline';

export interface TileLayerConfig {
  url: string;
  attribution: string;
  subdomains?: string[];
  maxZoom: number;
  minZoom?: number;
}

export const TILE_CONFIGS: Record<Exclude<MapTileTheme, 'offline'>, TileLayerConfig> = {
  // Dark Theme: Free Humanitarian OSM (High visibility emergency roads)
  dark: {
    url: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
    attribution:
      '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors, Humanitarian OpenStreetMap Team',
    subdomains: ['a', 'b', 'c'],
    maxZoom: 19,
    minZoom: 1,
  },

  // Light Theme: OpenStreetMap Standard (100% Free, zero API key)
  light: {
    url: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution:
      '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
    subdomains: ['a', 'b', 'c'],
    maxZoom: 19,
    minZoom: 1,
  },

  // Stadia Dark alternative
  stadiaDark: {
    url: 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png',
    attribution:
      '&copy; <a href="https://stadiamaps.com/">Stadia Maps</a> &copy; <a href="https://openmaptiles.org/">OpenMapTiles</a>',
    maxZoom: 20,
    minZoom: 1,
  },

  // Satellite Imagery for terrain disaster inspection
  satellite: {
    url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    attribution: 'Tiles &copy; Esri &mdash; Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community',
    maxZoom: 19,
    minZoom: 1,
  },
};

/**
 * Returns configuration object for requested tile theme
 */
export function getTileLayerConfig(theme: Exclude<MapTileTheme, 'offline'> = 'dark'): TileLayerConfig {
  return TILE_CONFIGS[theme] || TILE_CONFIGS.dark;
}

/**
 * React Component that renders the appropriate TileLayer or OfflineGridLayer
 * depending on connectivity state and selected theme
 */
export interface RakshaTileLayerProps {
  theme?: MapTileTheme;
  isOffline?: boolean;
}

export function RakshaTileLayer({ theme = 'dark', isOffline = false }: RakshaTileLayerProps) {
  const map = useMap();

  useEffect(() => {
    // If offline mode is enabled or theme is 'offline', attach custom procedural Canvas Grid
    if (isOffline || theme === 'offline') {
      const offlineGrid = new OfflineGridLayer({
        theme: theme === 'light' ? 'light' : 'dark',
        showCoordinates: true,
      });

      offlineGrid.addTo(map);

      return () => {
        map.removeLayer(offlineGrid);
      };
    }
  }, [map, isOffline, theme]);

  if (isOffline || theme === 'offline') {
    return null;
  }

  const selectedTheme = (theme === 'light' ? 'light' : theme === 'satellite' ? 'satellite' : 'dark') as Exclude<MapTileTheme, 'offline'>;
  const config = getTileLayerConfig(selectedTheme);

  return (
    <TileLayer
      url={config.url}
      attribution={config.attribution}
      subdomains={config.subdomains}
      maxZoom={config.maxZoom}
      minZoom={config.minZoom}
    />
  );
}
