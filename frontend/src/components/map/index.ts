/**
 * RakshaNet — Interactive Map Assets, Custom GIS Vector Canvas & Leaflet Styles
 * Source of Truth: design.md Section 2.6 and media_1791015140209.jpg
 */

// Styles
import './map.css';

// Master Map View
export { RakshaMapView, type RakshaMapViewProps } from './MapView';

// React-Leaflet Layer & Marker Components
export {
  SOSMarker,
  type SOSMarkerProps,
  FloodZonePolygon,
  type FloodZonePolygonProps,
  LandslideMarker,
  type LandslideMarkerProps,
  RescueTeamMarker,
  type RescueTeamMarkerProps,
  DeviceClusterMarker,
  type DeviceClusterMarkerProps,
  CommunicationGapPolygon,
  type CommunicationGapPolygonProps,
  SearchZonePolygon,
  type SearchZonePolygonProps,
  MeshConnectionLine,
  type MeshConnectionLineProps,
  DeviceNodeMarker,
  type DeviceNodeMarkerProps,
} from './MapLayers';

// Leaflet DivIcon Marker Generators
export {
  createSOSMarkerIcon,
  type SOSMarkerOptions,
  createWaterLabelMarkerIcon,
  type WaterLabelMarkerOptions,
  createLandslideMarkerIcon,
  type LandslideMarkerOptions,
  createRescueTeamMarkerIcon,
  type RescueTeamMarkerOptions,
  createDeviceClusterMarkerIcon,
  type DeviceClusterMarkerOptions,
  createSearchZoneLabelIcon,
  type SearchZoneLabelOptions,
  createCommGapLabelIcon,
  type CommGapLabelOptions,
  createDeviceNodeMarkerIcon,
  type DeviceNodeMarkerOptions,
} from './markerGenerators';

// SVG Icon Generators
export {
  getUnitTypeIconSvg,
  getWaterFloodIconSvg,
  getLandslideIconSvg,
  getSosBeaconIconSvg,
  getRadioMeshIconSvg,
  getRadioOffIconSvg,
  getSearchRadarIconSvg,
  type RescueUnitType,
} from './svgIcons';

// Vector Canvas & GIS Polygon Utilities
export {
  getFloodZonePolygonOptions,
  getCommGapPolygonOptions,
  getSearchZonePolygonOptions,
  getMeshPolylineOptions,
  injectMapSvgPatterns,
  getPolygonCentroid,
  generateIsochronePoints,
  type MapTheme,
} from './vectorCanvas';

// Tile Layers & Offline Fallback Canvas
export {
  RakshaTileLayer,
  type RakshaTileLayerProps,
  getTileLayerConfig,
  TILE_CONFIGS,
  type MapTileTheme,
  type TileLayerConfig,
} from './tileLayers';

export {
  OfflineGridLayer,
  createOfflineGridLayer,
  type OfflineGridLayerOptions,
} from './OfflineGridLayer';

// Design Tokens for Map
export { mapLayerTokens, brandTokens, darkTokens, lightTokens, oledTokens } from '../../theme/tokens';

// Live Map Side Drawer & Controls
export { LiveDeviceItem, type LiveDeviceItemProps } from './LiveDeviceItem';
export { LiveMapLayersDrawer, type LiveMapLayersDrawerProps } from './LiveMapLayersDrawer';
export { MapControlBar, type MapControlBarProps } from './MapControlBar';
export { MapCanvas, type MapCanvasProps } from './MapCanvas';
export { NodeDetailDrawer, type NodeDetailDrawerProps } from './NodeDetailDrawer';
