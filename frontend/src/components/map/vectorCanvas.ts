/**
 * RakshaNet — Custom GIS Vector Canvas & Polygon Styles
 * Source: design.md Section 2.6 and media_1791015140209.jpg
 */

import type L from 'leaflet';
import { mapLayerTokens } from '../../theme/tokens';

export type MapTheme = 'dark' | 'light';

/**
 * 1. FloodZonePolygon Path Options
 * Cyan/blue border, 30% fill opacity
 */
export function getFloodZonePolygonOptions(theme: MapTheme = 'dark'): L.PathOptions {
  const isLight = theme === 'light';
  return {
    color: isLight ? mapLayerTokens.floodExtent.stroke : mapLayerTokens.floodExtent.strokeDark,
    weight: 2.5,
    opacity: 0.95,
    fillColor: isLight ? mapLayerTokens.floodExtent.stroke : mapLayerTokens.floodExtent.strokeDark,
    fillOpacity: mapLayerTokens.floodExtent.fillOpacity, // 0.30 (30%)
    className: 'sr-flood-zone-polygon',
  };
}

/**
 * 2. CommunicationGapPolygon Path Options
 * Hatched purple polygon pattern (#7A4DD8 / #A98BFF @ 25% fill) indicating cut-off / silence zones
 */
export function getCommGapPolygonOptions(theme: MapTheme = 'dark'): L.PathOptions {
  const isLight = theme === 'light';
  const color = isLight ? mapLayerTokens.communicationGap.stroke : mapLayerTokens.communicationGap.strokeDark;
  
  return {
    color,
    weight: 2,
    opacity: 0.85,
    fillColor: color,
    fillOpacity: mapLayerTokens.communicationGap.fillOpacity, // 0.25 (25%)
    dashArray: '4, 4',
    className: 'sr-comm-gap-polygon comm-gap-hatched',
  };
}

/**
 * 3. SearchZonePolygon Path Options
 * Dashed yellow boundary (#FFC400 @ 28% fill, 2px dashed edge) for isochrone search areas
 */
export function getSearchZonePolygonOptions(theme: MapTheme = 'dark'): L.PathOptions {
  const isLight = theme === 'light';
  const borderColor = isLight ? mapLayerTokens.searchZone.border : mapLayerTokens.searchZone.borderDark;
  const fillColor = isLight ? mapLayerTokens.searchZone.fill : mapLayerTokens.searchZone.fillDark;

  return {
    color: borderColor,
    weight: mapLayerTokens.searchZone.borderWidth, // 2px
    opacity: 1,
    fillColor: fillColor,
    fillOpacity: 0.28, // 28% fill as specified in design.md Section 2.6
    dashArray: mapLayerTokens.searchZone.dashArray, // '6, 6'
    className: 'sr-search-zone-polygon search-zone-dashed',
  };
}

/**
 * 4. Mesh Connection Polyline Options
 * Connecting nearby peers across mesh networks
 */
export function getMeshPolylineOptions(
  status: 'active' | 'relay' | 'weak' | 'broken' = 'active',
  theme: MapTheme = 'dark'
): L.PolylineOptions {
  const isLight = theme === 'light';

  let color: string;
  let dashArray: string | undefined;
  let opacity = 0.85;

  switch (status) {
    case 'active':
      color = isLight ? mapLayerTokens.meshConnection.activeLight : mapLayerTokens.meshConnection.activeDark;
      break;
    case 'relay':
      color = isLight ? mapLayerTokens.meshConnection.relayLight : mapLayerTokens.meshConnection.relayDark;
      dashArray = '3, 4';
      break;
    case 'weak':
      color = isLight ? mapLayerTokens.meshConnection.weakLight : mapLayerTokens.meshConnection.weakDark;
      dashArray = '4, 6';
      opacity = 0.6;
      break;
    case 'broken':
      color = mapLayerTokens.meshConnection.broken;
      dashArray = '5, 5';
      opacity = 0.7;
      break;
  }

  return {
    color,
    weight: 2,
    opacity,
    dashArray,
    lineCap: 'round',
    lineJoin: 'round',
  };
}

/**
 * Inject SVG Hatch Pattern into Leaflet's SVG pane
 * Ensures that polygons with class 'comm-gap-hatched' render the purple diagonal hatched stripes
 */
export function injectMapSvgPatterns(container?: HTMLElement | null): void {
  if (typeof document === 'undefined') return;

  const patternId = 'raksha-comm-gap-pattern';
  if (document.getElementById(patternId)) return;

  const targetContainer = container || document.querySelector('.leaflet-pane.leaflet-overlay-pane svg');

  const svgDefs = document.createElementNS('http://www.w3.org/2000/svg', 'defs');
  svgDefs.innerHTML = `
    <!-- Hatched purple pattern for communication cut-off zones -->
    <pattern id="${patternId}" width="12" height="12" patternTransform="rotate(45 0 0)" patternUnits="userSpaceOnUse">
      <line x1="0" y1="0" x2="0" y2="12" stroke="#A98BFF" stroke-width="2.5" opacity="0.65" />
      <rect width="12" height="12" fill="#7A4DD8" fill-opacity="0.20" />
    </pattern>
    <pattern id="raksha-comm-gap-pattern-light" width="12" height="12" patternTransform="rotate(45 0 0)" patternUnits="userSpaceOnUse">
      <line x1="0" y1="0" x2="0" y2="12" stroke="#7A4DD8" stroke-width="2.5" opacity="0.65" />
      <rect width="12" height="12" fill="#7A4DD8" fill-opacity="0.15" />
    </pattern>
  `;

  if (targetContainer) {
    targetContainer.prepend(svgDefs);
  } else {
    // Append to document body or head as hidden svg
    const hiddenSvg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    hiddenSvg.id = 'raksha-map-svg-patterns';
    hiddenSvg.style.position = 'absolute';
    hiddenSvg.style.width = '0';
    hiddenSvg.style.height = '0';
    hiddenSvg.style.overflow = 'hidden';
    hiddenSvg.appendChild(svgDefs);
    document.body.appendChild(hiddenSvg);
  }
}

/**
 * Helper to compute the geographic centroid of a polygon [lat, lng] array
 */
export function getPolygonCentroid(positions: [number, number][] | [number, number][][]): [number, number] {
  const points: [number, number][] = Array.isArray(positions[0]) && Array.isArray((positions[0] as unknown[])[0])
    ? (positions[0] as unknown as [number, number][])
    : (positions as [number, number][]);

  if (!points || points.length === 0) return [0, 0];

  let sumLat = 0;
  let sumLng = 0;
  for (const pt of points) {
    sumLat += pt[0];
    sumLng += pt[1];
  }

  return [sumLat / points.length, sumLng / points.length];
}

/**
 * Helper: generates isochrone search polygon coordinates around a center point
 */
export function generateIsochronePoints(
  center: [number, number],
  radiusMeters: number,
  pointsCount: number = 32
): [number, number][] {
  const [lat, lng] = center;
  const earthRadius = 6378137; // meters
  const coords: [number, number][] = [];

  for (let i = 0; i < pointsCount; i++) {
    const angle = (i * 360) / pointsCount;
    const rad = (angle * Math.PI) / 180;
    
    // Add slight non-uniform variation to reflect real-world terrain/isochrone search front
    const jitter = 1 + Math.sin(rad * 3) * 0.08 + Math.cos(rad * 5) * 0.05;
    const r = radiusMeters * jitter;

    const dLat = (r * Math.cos(rad)) / earthRadius;
    const dLng = (r * Math.sin(rad)) / (earthRadius * Math.cos((lat * Math.PI) / 180));

    coords.push([lat + (dLat * 180) / Math.PI, lng + (dLng * 180) / Math.PI]);
  }

  return coords;
}
