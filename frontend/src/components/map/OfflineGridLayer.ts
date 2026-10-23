/**
 * RakshaNet — Offline Fallback Vector Canvas Grid Layer
 * Renders tactical GIS coordinates and disconnected grid lines when operating
 * with zero cellular/satellite connectivity in disaster zones.
 * Adheres to design.md Section 1. Principles (Work offline, bundled).
 */

import L from 'leaflet';
import { mapLayerTokens } from '../../theme/tokens';

export interface OfflineGridLayerOptions extends L.GridLayerOptions {
  theme?: 'dark' | 'light';
  showCoordinates?: boolean;
  gridSubdivisions?: number;
}

/**
 * Procedural Canvas Grid Layer for offline mapping
 */
export class OfflineGridLayer extends L.GridLayer {
  private gridTheme: 'dark' | 'light';
  private showCoords: boolean;
  private subdivisions: number;

  constructor(options: OfflineGridLayerOptions = {}) {
    super({
      tileSize: 256,
      minZoom: 0,
      maxZoom: 22,
      ...options,
    });
    this.gridTheme = options.theme || 'dark';
    this.showCoords = options.showCoordinates !== false;
    this.subdivisions = options.gridSubdivisions || 4;
  }

  createTile(coords: L.Coords, done: L.DoneCallback): HTMLElement {
    const tile = document.createElement('canvas');
    const size = this.getTileSize();
    tile.width = size.x;
    tile.height = size.y;
    tile.className = 'sr-offline-grid-tile';

    const ctx = tile.getContext('2d');
    if (!ctx) {
      done(undefined, tile);
      return tile;
    }

    const isLight = this.gridTheme === 'light';
    const bgColor = isLight ? '#FFFCEB' : mapLayerTokens.offlineGrid.bg; // #0B1220
    const majorLineColor = isLight ? '#E6DCA8' : mapLayerTokens.offlineGrid.lineMajor; // #26344F
    const minorLineColor = isLight ? '#F6F0D4' : mapLayerTokens.offlineGrid.lineMinor; // #162036
    const textColor = isLight ? '#8A5A00' : mapLayerTokens.offlineGrid.coordsText; // #9FADC2
    const crosshairColor = isLight ? '#C9BB6E' : mapLayerTokens.offlineGrid.crosshair; // #3A4C70

    // 1. Fill tile background
    ctx.fillStyle = bgColor;
    ctx.fillRect(0, 0, size.x, size.y);

    // 2. Draw minor subdivisions
    ctx.strokeStyle = minorLineColor;
    ctx.lineWidth = 1;
    ctx.setLineDash([2, 4]);

    const step = size.x / this.subdivisions;
    for (let i = 1; i < this.subdivisions; i++) {
      const pos = Math.round(i * step);
      // Vertical line
      ctx.beginPath();
      ctx.moveTo(pos, 0);
      ctx.lineTo(pos, size.y);
      ctx.stroke();

      // Horizontal line
      ctx.beginPath();
      ctx.moveTo(0, pos);
      ctx.lineTo(size.x, pos);
      ctx.stroke();
    }

    // 3. Draw major tile border (tactical grid cell)
    ctx.setLineDash([]);
    ctx.strokeStyle = majorLineColor;
    ctx.lineWidth = 1.5;
    ctx.strokeRect(0, 0, size.x, size.y);

    // 4. Tactical corner crosshairs
    const crossSize = 6;
    ctx.strokeStyle = crosshairColor;
    ctx.lineWidth = 1.5;

    // Center crosshair
    const cx = size.x / 2;
    const cy = size.y / 2;
    ctx.beginPath();
    ctx.moveTo(cx - crossSize, cy);
    ctx.lineTo(cx + crossSize, cy);
    ctx.moveTo(cx, cy - crossSize);
    ctx.lineTo(cx, cy + crossSize);
    ctx.stroke();

    // 5. Draw Geographic Lat/Lng or Grid coordinates if map is available
    if (this.showCoords && this._map) {
      try {
        const nwPoint = coords.scaleBy(size);
        const nwLatLng = this._map.unproject(nwPoint, coords.z);
        
        ctx.font = '500 10px "JetBrains Mono", monospace';
        ctx.fillStyle = textColor;

        // Top-left coordinate stamp
        const latStr = `${nwLatLng.lat.toFixed(4)}°`;
        const lngStr = `${nwLatLng.lng.toFixed(4)}°`;
        ctx.fillText(`${latStr}, ${lngStr}`, 6, 14);

        // Bottom-right tactical cell ID
        ctx.fillStyle = isLight ? '#9AA1AB' : '#5F6E86';
        ctx.font = '700 9px "JetBrains Mono", monospace';
        const cellTag = `Z${coords.z}·${coords.x},${coords.y}`;
        const textWidth = ctx.measureText(cellTag).width;
        ctx.fillText(cellTag, size.x - textWidth - 6, size.y - 6);
      } catch {
        // Fallback tile coords
        ctx.font = '500 10px "JetBrains Mono", monospace';
        ctx.fillStyle = textColor;
        ctx.fillText(`Z${coords.z} [${coords.x}, ${coords.y}]`, 6, 14);
      }
    }

    // Inform Leaflet that tile is ready
    setTimeout(() => done(undefined, tile), 0);
    return tile;
  }
}

/**
 * Factory helper
 */
export function createOfflineGridLayer(options?: OfflineGridLayerOptions): OfflineGridLayer {
  return new OfflineGridLayer(options);
}
