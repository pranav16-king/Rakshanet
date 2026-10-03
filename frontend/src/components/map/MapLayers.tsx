/**
 * RakshaNet / SignalRescue AI — React-Leaflet Map Components & Layer Definitions
 * Source: design.md Section 2.6 and media_1791015140209.jpg
 */

import React, { useMemo } from 'react';
import { Marker, Polygon, Circle, Polyline, Popup } from 'react-leaflet';
import type L from 'leaflet';
import {
  createSOSMarkerIcon,
  createWaterLabelMarkerIcon,
  createLandslideMarkerIcon,
  createRescueTeamMarkerIcon,
  createDeviceClusterMarkerIcon,
  createSearchZoneLabelIcon,
  createCommGapLabelIcon,
  createDeviceNodeMarkerIcon,
} from './markerGenerators';
import {
  getFloodZonePolygonOptions,
  getCommGapPolygonOptions,
  getSearchZonePolygonOptions,
  getMeshPolylineOptions,
  getPolygonCentroid,
  generateIsochronePoints,
} from './vectorCanvas';
import type { RescueUnitType } from './svgIcons';

/* =========================================================================
   1. SOS MARKER COMPONENT
   ========================================================================= */

export interface SOSMarkerProps {
  position: L.LatLngExpression;
  count?: number;
  label?: string;
  theme?: 'dark' | 'light';
  pulsing?: boolean;
  onClick?: () => void;
  popupContent?: React.ReactNode;
}

export function SOSMarker({
  position,
  count = 12,
  label = 'users',
  theme = 'dark',
  pulsing = true,
  onClick,
  popupContent,
}: SOSMarkerProps) {
  const icon = useMemo(
    () => createSOSMarkerIcon({ count, label, theme, pulsing }),
    [count, label, theme, pulsing]
  );

  return (
    <Marker
      position={position}
      icon={icon}
      eventHandlers={onClick ? { click: onClick } : undefined}
    >
      {popupContent && <Popup>{popupContent}</Popup>}
    </Marker>
  );
}

/* =========================================================================
   2. FLOOD ZONE POLYGON COMPONENT
   ========================================================================= */

export interface FloodZonePolygonProps {
  positions?: L.LatLngExpression[] | L.LatLngExpression[][];
  center?: L.LatLngExpression;
  radius?: number; // meters if circular
  label?: string;
  deviceCount?: number;
  theme?: 'dark' | 'light';
  showLabel?: boolean;
  onClick?: () => void;
  popupContent?: React.ReactNode;
}

export function FloodZonePolygon({
  positions,
  center,
  radius,
  label = 'Flood Area',
  deviceCount = 15,
  theme = 'dark',
  showLabel = true,
  onClick,
  popupContent,
}: FloodZonePolygonProps) {
  const pathOptions = useMemo(() => getFloodZonePolygonOptions(theme), [theme]);

  // Centroid for label badge
  const labelPosition: L.LatLngExpression | null = useMemo(() => {
    if (center) return center;
    if (positions && positions.length > 0) {
      // Cast safely to extract numeric points
      const points = positions as unknown as [number, number][];
      return getPolygonCentroid(points);
    }
    return null;
  }, [center, positions]);

  const labelIcon = useMemo(
    () => createWaterLabelMarkerIcon({ label, deviceCount, theme }),
    [label, deviceCount, theme]
  );

  return (
    <>
      {positions ? (
        <Polygon
          positions={positions}
          pathOptions={pathOptions}
          eventHandlers={onClick ? { click: onClick } : undefined}
        >
          {popupContent && <Popup>{popupContent}</Popup>}
        </Polygon>
      ) : center && radius ? (
        <Circle
          center={center}
          radius={radius}
          pathOptions={pathOptions}
          eventHandlers={onClick ? { click: onClick } : undefined}
        >
          {popupContent && <Popup>{popupContent}</Popup>}
        </Circle>
      ) : null}

      {showLabel && labelPosition && (
        <Marker
          position={labelPosition}
          icon={labelIcon}
          eventHandlers={onClick ? { click: onClick } : undefined}
        >
          {popupContent && <Popup>{popupContent}</Popup>}
        </Marker>
      )}
    </>
  );
}

/* =========================================================================
   3. LANDSLIDE MARKER COMPONENT
   ========================================================================= */

export interface LandslideMarkerProps {
  position: L.LatLngExpression;
  label?: string;
  deviceCount?: number;
  severity?: 'critical' | 'warning';
  theme?: 'dark' | 'light';
  onClick?: () => void;
  popupContent?: React.ReactNode;
}

export function LandslideMarker({
  position,
  label = 'Landslide',
  deviceCount = 5,
  severity = 'warning',
  theme = 'dark',
  onClick,
  popupContent,
}: LandslideMarkerProps) {
  const icon = useMemo(
    () => createLandslideMarkerIcon({ label, deviceCount, severity, theme }),
    [label, deviceCount, severity, theme]
  );

  return (
    <Marker
      position={position}
      icon={icon}
      eventHandlers={onClick ? { click: onClick } : undefined}
    >
      {popupContent && <Popup>{popupContent}</Popup>}
    </Marker>
  );
}

/* =========================================================================
   4. RESCUE TEAM MARKER COMPONENT
   ========================================================================= */

export interface RescueTeamMarkerProps {
  position: L.LatLngExpression;
  unitType?: RescueUnitType;
  unitName?: string;
  deviceCount?: number;
  theme?: 'dark' | 'light';
  onClick?: () => void;
  popupContent?: React.ReactNode;
}

export function RescueTeamMarker({
  position,
  unitType = 'boat',
  unitName = 'Rescue Team',
  deviceCount = 4,
  theme = 'dark',
  onClick,
  popupContent,
}: RescueTeamMarkerProps) {
  const icon = useMemo(
    () => createRescueTeamMarkerIcon({ unitType, unitName, deviceCount, theme }),
    [unitType, unitName, deviceCount, theme]
  );

  return (
    <Marker
      position={position}
      icon={icon}
      eventHandlers={onClick ? { click: onClick } : undefined}
    >
      {popupContent && <Popup>{popupContent}</Popup>}
    </Marker>
  );
}

/* =========================================================================
   5. DEVICE CLUSTER MARKER COMPONENT
   ========================================================================= */

export interface DeviceClusterMarkerProps {
  position: L.LatLngExpression;
  count: number;
  theme?: 'dark' | 'light';
  onClick?: () => void;
  popupContent?: React.ReactNode;
}

export function DeviceClusterMarker({
  position,
  count,
  theme = 'dark',
  onClick,
  popupContent,
}: DeviceClusterMarkerProps) {
  const icon = useMemo(
    () => createDeviceClusterMarkerIcon({ count, theme }),
    [count, theme]
  );

  return (
    <Marker
      position={position}
      icon={icon}
      eventHandlers={onClick ? { click: onClick } : undefined}
    >
      {popupContent && <Popup>{popupContent}</Popup>}
    </Marker>
  );
}

/* =========================================================================
   6. COMMUNICATION GAP POLYGON COMPONENT
   ========================================================================= */

export interface CommunicationGapPolygonProps {
  positions: L.LatLngExpression[] | L.LatLngExpression[][];
  label?: string;
  sublabel?: string;
  showLabel?: boolean;
  theme?: 'dark' | 'light';
  onClick?: () => void;
  popupContent?: React.ReactNode;
}

export function CommunicationGapPolygon({
  positions,
  label = 'Silence Zone',
  sublabel = 'No mesh signal · Cut-off',
  showLabel = true,
  theme = 'dark',
  onClick,
  popupContent,
}: CommunicationGapPolygonProps) {
  const pathOptions = useMemo(() => getCommGapPolygonOptions(theme), [theme]);

  const labelPosition: L.LatLngExpression | null = useMemo(() => {
    if (positions && positions.length > 0) {
      const points = positions as unknown as [number, number][];
      return getPolygonCentroid(points);
    }
    return null;
  }, [positions]);

  const labelIcon = useMemo(
    () => createCommGapLabelIcon({ label, sublabel, theme }),
    [label, sublabel, theme]
  );

  return (
    <>
      <Polygon
        positions={positions}
        pathOptions={pathOptions}
        eventHandlers={onClick ? { click: onClick } : undefined}
      >
        {popupContent && <Popup>{popupContent}</Popup>}
      </Polygon>

      {showLabel && labelPosition && (
        <Marker
          position={labelPosition}
          icon={labelIcon}
          eventHandlers={onClick ? { click: onClick } : undefined}
        >
          {popupContent && <Popup>{popupContent}</Popup>}
        </Marker>
      )}
    </>
  );
}

/* =========================================================================
   7. SEARCH ZONE POLYGON COMPONENT (Isochrone Search Areas)
   ========================================================================= */

export interface SearchZonePolygonProps {
  positions?: L.LatLngExpression[] | L.LatLngExpression[][];
  center?: [number, number];
  radiusMeters?: number;
  label?: string;
  confidence?: number;
  showLabel?: boolean;
  theme?: 'dark' | 'light';
  onClick?: () => void;
  popupContent?: React.ReactNode;
}

export function SearchZonePolygon({
  positions,
  center,
  radiusMeters = 1500,
  label = 'Search Zone',
  confidence = 88,
  showLabel = true,
  theme = 'dark',
  onClick,
  popupContent,
}: SearchZonePolygonProps) {
  const pathOptions = useMemo(() => getSearchZonePolygonOptions(theme), [theme]);

  // If positions not explicitly provided, calculate isochrone coordinates from center
  const calculatedPositions = useMemo(() => {
    if (positions) return positions;
    if (center && radiusMeters) {
      return generateIsochronePoints(center, radiusMeters, 36) as unknown as L.LatLngExpression[];
    }
    return [];
  }, [positions, center, radiusMeters]);

  const labelPosition: L.LatLngExpression | null = useMemo(() => {
    if (center) return center;
    if (calculatedPositions && calculatedPositions.length > 0) {
      const points = calculatedPositions as unknown as [number, number][];
      return getPolygonCentroid(points);
    }
    return null;
  }, [center, calculatedPositions]);

  const radiusKm = radiusMeters ? +(radiusMeters / 1000).toFixed(1) : undefined;
  const labelIcon = useMemo(
    () => createSearchZoneLabelIcon({ label, confidence, radiusKm, theme }),
    [label, confidence, radiusKm, theme]
  );

  if (calculatedPositions.length === 0) return null;

  return (
    <>
      <Polygon
        positions={calculatedPositions}
        pathOptions={pathOptions}
        eventHandlers={onClick ? { click: onClick } : undefined}
      >
        {popupContent && <Popup>{popupContent}</Popup>}
      </Polygon>

      {showLabel && labelPosition && (
        <Marker
          position={labelPosition}
          icon={labelIcon}
          eventHandlers={onClick ? { click: onClick } : undefined}
        >
          {popupContent && <Popup>{popupContent}</Popup>}
        </Marker>
      )}
    </>
  );
}

/* =========================================================================
   8. MESH CONNECTION LINE COMPONENT
   ========================================================================= */

export interface MeshConnectionLineProps {
  positions: L.LatLngExpression[];
  status?: 'active' | 'relay' | 'weak' | 'broken';
  theme?: 'dark' | 'light';
}

export function MeshConnectionLine({
  positions,
  status = 'active',
  theme = 'dark',
}: MeshConnectionLineProps) {
  const pathOptions = useMemo(() => getMeshPolylineOptions(status, theme), [status, theme]);

  return <Polyline positions={positions} pathOptions={pathOptions} />;
}

/* =========================================================================
   9. DEVICE NODE MARKER COMPONENT
   ========================================================================= */

export interface DeviceNodeMarkerProps {
  position: L.LatLngExpression;
  status?: 'online' | 'relay' | 'offline';
  deviceId?: string;
  theme?: 'dark' | 'light';
  onClick?: () => void;
  popupContent?: React.ReactNode;
}

export function DeviceNodeMarker({
  position,
  status = 'online',
  deviceId,
  theme = 'dark',
  onClick,
  popupContent,
}: DeviceNodeMarkerProps) {
  const icon = useMemo(
    () => createDeviceNodeMarkerIcon({ status, deviceId, theme }),
    [status, deviceId, theme]
  );

  return (
    <Marker
      position={position}
      icon={icon}
      eventHandlers={onClick ? { click: onClick } : undefined}
    >
      {popupContent && <Popup>{popupContent}</Popup>}
    </Marker>
  );
}
