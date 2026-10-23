/**
 * RakshaNet — Custom SVG & HTML Marker Generators
 * Generates Leaflet L.DivIcon instances adhering to design.md Section 2.6 and media_1791015140209.jpg
 */

import L from 'leaflet';
import {
  getUnitTypeIconSvg,
  getWaterFloodIconSvg,
  getLandslideIconSvg,
  getRadioOffIconSvg,
  getSearchRadarIconSvg,
  type RescueUnitType,
} from './svgIcons';

export interface SOSMarkerOptions {
  count?: number;
  label?: string;
  theme?: 'dark' | 'light';
  pulsing?: boolean;
  className?: string;
}

export interface WaterLabelMarkerOptions {
  label?: string;
  deviceCount?: number;
  theme?: 'dark' | 'light';
  className?: string;
}

export interface LandslideMarkerOptions {
  label?: string;
  deviceCount?: number;
  severity?: 'critical' | 'warning';
  theme?: 'dark' | 'light';
  className?: string;
}

export interface RescueTeamMarkerOptions {
  unitType?: RescueUnitType;
  unitName?: string;
  deviceCount?: number;
  theme?: 'dark' | 'light';
  className?: string;
}

export interface DeviceClusterMarkerOptions {
  count: number;
  theme?: 'dark' | 'light';
  className?: string;
}

export interface SearchZoneLabelOptions {
  label?: string;
  confidence?: number;
  radiusKm?: number;
  theme?: 'dark' | 'light';
  className?: string;
}

export interface CommGapLabelOptions {
  label?: string;
  sublabel?: string;
  theme?: 'dark' | 'light';
  className?: string;
}

export interface DeviceNodeMarkerOptions {
  status?: 'online' | 'relay' | 'offline';
  deviceId?: string;
  theme?: 'dark' | 'light';
}

/**
 * 1. SOSMarker Icon Generator
 * Red filled circular pin (#D92D20 / #FF5A4E) with concentric pulsing ripple animation
 * and user casualty count pill (e.g. "SOS 12 users").
 */
export function createSOSMarkerIcon(options: SOSMarkerOptions = {}): L.DivIcon {
  const {
    count = 12,
    label = 'users',
    theme = 'dark',
    pulsing = true,
    className = '',
  } = options;

  const countText = count > 0 ? `${count} ${label}` : 'CRITICAL';

  const html = `
    <div class="sr-sos-marker-wrapper ${theme === 'light' ? 'theme-light' : ''} ${className}">
      ${pulsing ? `
        <div class="sr-sos-ripple-layer">
          <div class="sr-sos-ripple ring-1"></div>
          <div class="sr-sos-ripple ring-2"></div>
          <div class="sr-sos-ripple ring-3"></div>
        </div>
      ` : ''}
      <div class="sr-sos-core" role="img" aria-label="SOS Alert: ${countText}">
        <span class="sr-sos-title">SOS</span>
        <span class="sr-sos-count-micro">${count} ${label}</span>
      </div>
      <div class="sr-sos-pill">
        <span class="sr-sos-pill-dot"></span>
        <span>SOS ${countText}</span>
      </div>
    </div>
  `;

  return L.divIcon({
    html,
    className: 'sr-leaflet-div-icon sr-sos-leaflet-icon',
    iconSize: [120, 120],
    iconAnchor: [60, 60],
    popupAnchor: [0, -35],
  });
}

/**
 * 2. Water / Flood Zone Label Badge Icon Generator
 * Floating badge matching media_1791015140209.jpg ("Flood Area 15 devices")
 */
export function createWaterLabelMarkerIcon(options: WaterLabelMarkerOptions = {}): L.DivIcon {
  const {
    label = 'Flood Area',
    deviceCount = 15,
    theme = 'dark',
    className = '',
  } = options;

  const countString = deviceCount !== undefined ? `${deviceCount} devices` : 'Active hazard';
  const iconSvg = getWaterFloodIconSvg('#FFFFFF', 16);

  const html = `
    <div class="sr-badge-marker flood ${theme === 'light' ? 'theme-light' : ''} ${className}" role="status">
      <div class="sr-badge-icon-bubble">
        ${iconSvg}
      </div>
      <div class="sr-badge-content">
        <span class="sr-badge-title">${label}</span>
        <span class="sr-badge-subtitle">${countString}</span>
      </div>
    </div>
  `;

  return L.divIcon({
    html,
    className: 'sr-leaflet-div-icon sr-badge-leaflet-icon',
    iconSize: [160, 40],
    iconAnchor: [80, 20],
    popupAnchor: [0, -22],
  });
}

/**
 * 3. LandslideMarker Icon Generator
 * Warning/red marker with icon and badge ("Landslide 5 devices")
 */
export function createLandslideMarkerIcon(options: LandslideMarkerOptions = {}): L.DivIcon {
  const {
    label = 'Landslide',
    deviceCount = 5,
    theme = 'dark',
    className = '',
  } = options;

  const countString = deviceCount !== undefined ? `${deviceCount} devices` : 'Danger zone';
  const iconSvg = getLandslideIconSvg('#FFFFFF', 16);

  const html = `
    <div class="sr-badge-marker landslide ${theme === 'light' ? 'theme-light' : ''} ${className}" role="status">
      <div class="sr-badge-icon-bubble">
        ${iconSvg}
      </div>
      <div class="sr-badge-content">
        <span class="sr-badge-title">${label}</span>
        <span class="sr-badge-subtitle">${countString}</span>
      </div>
    </div>
  `;

  return L.divIcon({
    html,
    className: 'sr-leaflet-div-icon sr-badge-leaflet-icon',
    iconSize: [150, 40],
    iconAnchor: [75, 20],
    popupAnchor: [0, -22],
  });
}

/**
 * 4. RescueTeamMarker Icon Generator
 * High-visibility green badge (#1E8E4E / #4CD08A) with unit type icon
 * (boat, 4WD truck, ambulance, helicopter) and "Rescue Team 4 devices"
 */
export function createRescueTeamMarkerIcon(options: RescueTeamMarkerOptions = {}): L.DivIcon {
  const {
    unitType = 'boat',
    unitName = 'Rescue Team',
    deviceCount = 4,
    theme = 'dark',
    className = '',
  } = options;

  const countString = deviceCount !== undefined ? `${deviceCount} devices` : 'Active unit';
  const iconSvg = getUnitTypeIconSvg(unitType, '#FFFFFF', 16);

  const html = `
    <div class="sr-badge-marker rescue-team ${theme === 'light' ? 'theme-light' : ''} ${className}" role="status">
      <div class="sr-badge-icon-bubble">
        ${iconSvg}
      </div>
      <div class="sr-badge-content">
        <span class="sr-badge-title">${unitName}</span>
        <span class="sr-badge-subtitle">${countString}</span>
      </div>
    </div>
  `;

  return L.divIcon({
    html,
    className: 'sr-leaflet-div-icon sr-badge-leaflet-icon',
    iconSize: [160, 40],
    iconAnchor: [80, 20],
    popupAnchor: [0, -22],
  });
}

/**
 * 5. DeviceClusterMarker Icon Generator
 * Teal circle (#0E8A94 / #3CC6D0) sized proportionally to peer count.
 */
export function createDeviceClusterMarkerIcon(options: DeviceClusterMarkerOptions): L.DivIcon {
  const { count, theme = 'dark', className = '' } = options;

  let sizeClass = 'size-sm';
  let pixelSize = 32;

  if (count >= 50) {
    sizeClass = 'size-xl';
    pixelSize = 58;
  } else if (count >= 16) {
    sizeClass = 'size-lg';
    pixelSize = 48;
  } else if (count >= 6) {
    sizeClass = 'size-md';
    pixelSize = 40;
  }

  const html = `
    <div class="sr-device-cluster-marker ${sizeClass} ${theme === 'light' ? 'theme-light' : ''} ${className}" role="img" aria-label="${count} devices nearby">
      <span class="cluster-count">${count}</span>
    </div>
  `;

  return L.divIcon({
    html,
    className: 'sr-leaflet-div-icon sr-cluster-leaflet-icon',
    iconSize: [pixelSize, pixelSize],
    iconAnchor: [pixelSize / 2, pixelSize / 2],
    popupAnchor: [0, -pixelSize / 2 - 5],
  });
}

/**
 * 6. SearchZoneLabel Icon Generator (Centroid marker)
 */
export function createSearchZoneLabelIcon(options: SearchZoneLabelOptions = {}): L.DivIcon {
  const {
    label = 'Search Zone',
    confidence = 88,
    radiusKm,
    theme = 'dark',
    className = '',
  } = options;

  const subtitle = radiusKm ? `~${radiusKm} km · AI Conf ${confidence}%` : `AI Conf ${confidence}% · Estimate`;
  const iconSvg = getSearchRadarIconSvg('#FFC400', 16);

  const html = `
    <div class="sr-badge-marker ${theme === 'light' ? 'theme-light' : ''} ${className}" style="border-color: rgba(255,196,0,0.5);">
      <div class="sr-badge-icon-bubble" style="background: rgba(255, 196, 0, 0.2); color: #FFC400;">
        ${iconSvg}
      </div>
      <div class="sr-badge-content">
        <span class="sr-badge-title" style="color: ${theme === 'light' ? '#8A5A00' : '#FFD21F'};">${label}</span>
        <span class="sr-badge-subtitle">${subtitle}</span>
      </div>
    </div>
  `;

  return L.divIcon({
    html,
    className: 'sr-leaflet-div-icon',
    iconSize: [180, 40],
    iconAnchor: [90, 20],
    popupAnchor: [0, -22],
  });
}

/**
 * 7. Communication Gap Label Icon Generator
 */
export function createCommGapLabelIcon(options: CommGapLabelOptions = {}): L.DivIcon {
  const {
    label = 'Silence Zone',
    sublabel = 'No mesh signal · Cut-off',
    theme = 'dark',
    className = '',
  } = options;

  const iconSvg = getRadioOffIconSvg('#FFFFFF', 16);

  const html = `
    <div class="sr-badge-marker ${theme === 'light' ? 'theme-light' : ''} ${className}" style="border-color: rgba(169, 139, 255, 0.5);">
      <div class="sr-badge-icon-bubble" style="background: radial-gradient(circle, #A98BFF 0%, #7A4DD8 100%);">
        ${iconSvg}
      </div>
      <div class="sr-badge-content">
        <span class="sr-badge-title" style="color: ${theme === 'light' ? '#7A4DD8' : '#A98BFF'};">${label}</span>
        <span class="sr-badge-subtitle">${sublabel}</span>
      </div>
    </div>
  `;

  return L.divIcon({
    html,
    className: 'sr-leaflet-div-icon',
    iconSize: [170, 40],
    iconAnchor: [85, 20],
    popupAnchor: [0, -22],
  });
}

/**
 * 8. Individual Mesh Device Node Dot Marker
 */
export function createDeviceNodeMarkerIcon(options: DeviceNodeMarkerOptions = {}): L.DivIcon {
  const { status = 'online', deviceId = '' } = options;

  const html = `
    <div class="sr-device-node-marker ${status}" title="${deviceId ? `Device ${deviceId}` : status}"></div>
  `;

  return L.divIcon({
    html,
    className: 'sr-leaflet-div-icon',
    iconSize: [18, 18],
    iconAnchor: [9, 9],
    popupAnchor: [0, -10],
  });
}
