import 'dart:math' as math;

/// Freshness status of the geospatial fix observation.
class GeospatialFreshness {
  static const String live = 'LIVE';
  static const String stale = 'STALE';
  static const String unknown = 'UNKNOWN';

  const GeospatialFreshness._();
}

/// Comprehensive result of a geospatial distance calculation between two coordinates.
///
/// Implements WGS84 great-circle Haversine computation, combined horizontal uncertainty,
/// observation freshness categorization, and straight-line safety labeling.
class GeospatialDistanceResult {
  /// Calculated great-circle distance along Earth's spherical surface in meters.
  /// Null if coordinates are unavailable.
  final double? distanceMeters;

  /// Human-readable formatted distance (e.g. "420 m", "2.4 km", or "Unavailable").
  final String distanceFormatted;

  /// Combined horizontal uncertainty radius in meters (`accuracy1 + accuracy2`).
  /// Null if coordinates are unavailable.
  final double? uncertaintyMeters;

  /// Formatted uncertainty label (e.g. "± 18 m" or "± 1.2 km").
  final String uncertaintyFormatted;

  /// Always true. Explicitly labeled "Straight-line surface distance"
  /// to warn search & rescue operators that physical terrain/rubble obstacles exist.
  final bool isStraightLine;

  /// Observation freshness: 'LIVE' (within 60s), 'STALE' (> 60s), or 'UNKNOWN'.
  final String freshnessStatus;

  /// Standard summary badge string (e.g. "2.4 km ± 25 m • Straight-line").
  final String summaryLabel;

  /// Flag indicating whether valid WGS84 GPS coordinates were provided.
  final bool isCoordinatesAvailable;

  /// Actionable guidance when coordinates are missing, prompting Bluetooth RSSI proximity estimation.
  final String? fallbackPrompt;

  /// Initial compass azimuth bearing in degrees (0..360), if computable.
  final double? bearingDegrees;

  /// Cardinal compass heading (e.g. "N", "NE", "E", "SW"), if computable.
  final String? compassDirection;

  /// Minimum probable distance accounting for uncertainty: `max(0, distance - uncertainty)`.
  double? get minDistanceMeters =>
      distanceMeters != null && uncertaintyMeters != null
          ? math.max(0.0, distanceMeters! - uncertaintyMeters!)
          : null;

  /// Maximum probable distance accounting for uncertainty: `distance + uncertainty`.
  double? get maxDistanceMeters =>
      distanceMeters != null && uncertaintyMeters != null
          ? distanceMeters! + uncertaintyMeters!
          : null;

  /// Whether the distance calculation is live and has high confidence.
  bool get isHighConfidence =>
      isCoordinatesAvailable &&
      freshnessStatus == GeospatialFreshness.live &&
      (uncertaintyMeters ?? 1000.0) <= 50.0;

  const GeospatialDistanceResult({
    required this.distanceMeters,
    required this.distanceFormatted,
    required this.uncertaintyMeters,
    required this.uncertaintyFormatted,
    this.isStraightLine = true,
    required this.freshnessStatus,
    required this.summaryLabel,
    required this.isCoordinatesAvailable,
    this.fallbackPrompt,
    this.bearingDegrees,
    this.compassDirection,
  });

  /// Factory creating fallback result when remote or local coordinates are missing.
  ///
  /// Prompts for Bluetooth RSSI proximity estimation rather than guessing GPS coordinates.
  factory GeospatialDistanceResult.coordinatesUnavailable({
    double? bleRssiDistanceMeters,
    double? bleRssiUncertaintyMeters,
    String? customMessage,
  }) {
    final hasBle = bleRssiDistanceMeters != null;
    final distFormatted = hasBle
        ? HaversineDistance.formatDistance(bleRssiDistanceMeters)
        : 'Coordinates Unavailable';
    final uncFormatted = bleRssiUncertaintyMeters != null
        ? HaversineDistance.formatUncertainty(bleRssiUncertaintyMeters)
        : '± -- m';

    final summary = hasBle
        ? '$distFormatted $uncFormatted • BLE Proximity (Straight-line)'
        : 'Coordinates unavailable • Use BLE RSSI proximity';

    return GeospatialDistanceResult(
      distanceMeters: bleRssiDistanceMeters,
      distanceFormatted: distFormatted,
      uncertaintyMeters: bleRssiUncertaintyMeters,
      uncertaintyFormatted: uncFormatted,
      isStraightLine: true,
      freshnessStatus: GeospatialFreshness.unknown,
      summaryLabel: summary,
      isCoordinatesAvailable: false,
      fallbackPrompt: customMessage ??
          'Remote GPS coordinates unavailable. Switch to Bluetooth RSSI proximity estimation instead of guessing GPS coordinates.',
    );
  }

  Map<String, dynamic> toMap() => {
        'distanceMeters': distanceMeters,
        'distanceFormatted': distanceFormatted,
        'uncertaintyMeters': uncertaintyMeters,
        'uncertaintyFormatted': uncertaintyFormatted,
        'isStraightLine': isStraightLine,
        'freshnessStatus': freshnessStatus,
        'summaryLabel': summaryLabel,
        'isCoordinatesAvailable': isCoordinatesAvailable,
        'fallbackPrompt': fallbackPrompt,
        'bearingDegrees': bearingDegrees,
        'compassDirection': compassDirection,
      };

  @override
  String toString() =>
      'GeospatialDistanceResult($summaryLabel, freshness: $freshnessStatus)';
}

/// Great-circle Haversine Distance Calculator for SignalRescue AI / RakshaNet.
///
/// Employs Earth's volumetric mean spherical radius R = 6,371,000 meters.
/// Strict emergency rescue rule: Never hallucinate or extrapolate missing coordinates.
/// In GPS-denied environments, fall back to BLE RSSI proximity estimation.
class HaversineDistance {
  /// Radius of Earth in meters (WGS84 spherical approximation).
  static const double earthRadiusMeters = 6371000.0;

  /// Stale threshold in milliseconds (60 seconds).
  static const int staleThresholdMs = 60000;

  const HaversineDistance._();

  /// Calculates geodesic distance between two users/nodes with accuracy error bounds.
  ///
  /// Specification parameters:
  /// - `lat1`, `lng1`: Device 1 coordinates (degrees)
  /// - `accuracy1`: Device 1 1-sigma horizontal accuracy (meters)
  /// - `timestamp1`: Device 1 fix timestamp (epoch milliseconds)
  /// - `lat2`, `lng2`: Device 2 coordinates (degrees)
  /// - `accuracy2`: Device 2 1-sigma horizontal accuracy (meters)
  /// - `timestamp2`: Device 2 fix timestamp (epoch milliseconds)
  ///
  /// Returns [GeospatialDistanceResult] with formatted distance, combined uncertainty,
  /// straight-line indicator, and freshness status.
  static GeospatialDistanceResult calculateDistance({
    required double lat1,
    required double lng1,
    required double accuracy1,
    required int timestamp1,
    required double lat2,
    required double lng2,
    required double accuracy2,
    required int timestamp2,
    int? currentTimestampMs,
  }) {
    // 1. Sanitize coordinate boundaries
    final safeLat1 = lat1.clamp(-90.0, 90.0);
    final safeLng1 = lng1.clamp(-180.0, 180.0);
    final safeLat2 = lat2.clamp(-90.0, 90.0);
    final safeLng2 = lng2.clamp(-180.0, 180.0);

    final safeAcc1 = math.max(0.0, accuracy1);
    final safeAcc2 = math.max(0.0, accuracy2);

    // 2. Haversine distance computation:
    // a = sin²(Δlat / 2) + cos(lat1) * cos(lat2) * sin²(Δlng / 2)
    // c = 2 * atan2(√a, √(1 − a))
    // d = R * c
    final dLat = (safeLat2 - safeLat1) * math.pi / 180.0;
    final dLng = (safeLng2 - safeLng1) * math.pi / 180.0;
    final lat1Rad = safeLat1 * math.pi / 180.0;
    final lat2Rad = safeLat2 * math.pi / 180.0;

    final sinHalfLat = math.sin(dLat / 2.0);
    final sinHalfLng = math.sin(dLng / 2.0);

    final a = (sinHalfLat * sinHalfLat) +
        math.cos(lat1Rad) * math.cos(lat2Rad) * (sinHalfLng * sinHalfLng);

    // Clamp 'a' to [0.0, 1.0] to prevent floating point domain errors in sqrt
    final clampedA = a.clamp(0.0, 1.0);
    final c = 2.0 * math.atan2(math.sqrt(clampedA), math.sqrt(1.0 - clampedA));
    final distanceMeters = earthRadiusMeters * c;

    // 3. Combined horizontal uncertainty radius: accuracy1 + accuracy2
    final uncertaintyMeters = safeAcc1 + safeAcc2;

    // 4. Freshness status determination:
    final now = currentTimestampMs ?? DateTime.now().millisecondsSinceEpoch;
    final age1 = (now - timestamp1).abs();
    final age2 = (now - timestamp2).abs();

    String freshnessStatus;
    if (timestamp1 <= 0 || timestamp2 <= 0) {
      freshnessStatus = GeospatialFreshness.unknown;
    } else if (age1 <= staleThresholdMs && age2 <= staleThresholdMs) {
      freshnessStatus = GeospatialFreshness.live;
    } else {
      freshnessStatus = GeospatialFreshness.stale;
    }

    // 5. Compass azimuth bearing from point 1 to point 2
    final bearing = calculateBearingDegrees(safeLat1, safeLng1, safeLat2, safeLng2);
    final compass = cardinalDirection(bearing);

    // 6. Formatting
    final distanceFormatted = formatDistance(distanceMeters);
    final uncertaintyFormatted = formatUncertainty(uncertaintyMeters);
    final summaryLabel =
        '$distanceFormatted $uncertaintyFormatted • Straight-line';

    return GeospatialDistanceResult(
      distanceMeters: distanceMeters,
      distanceFormatted: distanceFormatted,
      uncertaintyMeters: uncertaintyMeters,
      uncertaintyFormatted: uncertaintyFormatted,
      isStraightLine: true,
      freshnessStatus: freshnessStatus,
      summaryLabel: summaryLabel,
      isCoordinatesAvailable: true,
      bearingDegrees: bearing,
      compassDirection: compass,
    );
  }

  /// Safe helper accepting nullable coordinates.
  ///
  /// When either local or remote coordinates are missing, gracefully returns
  /// [GeospatialDistanceResult.coordinatesUnavailable] with an explicit prompt
  /// for Bluetooth RSSI proximity estimation rather than guessing GPS coordinates.
  static GeospatialDistanceResult calculateDistanceNullable({
    required double? lat1,
    required double? lng1,
    double? accuracy1,
    int? timestamp1,
    required double? lat2,
    required double? lng2,
    double? accuracy2,
    int? timestamp2,
    double? bleRssiDistanceMeters,
    double? bleRssiUncertaintyMeters,
    int? currentTimestampMs,
  }) {
    if (lat1 == null || lng1 == null || lat2 == null || lng2 == null) {
      return GeospatialDistanceResult.coordinatesUnavailable(
        bleRssiDistanceMeters: bleRssiDistanceMeters,
        bleRssiUncertaintyMeters: bleRssiUncertaintyMeters,
      );
    }

    return calculateDistance(
      lat1: lat1,
      lng1: lng1,
      accuracy1: accuracy1 ?? 15.0,
      timestamp1: timestamp1 ?? DateTime.now().millisecondsSinceEpoch,
      lat2: lat2,
      lng2: lng2,
      accuracy2: accuracy2 ?? 15.0,
      timestamp2: timestamp2 ?? DateTime.now().millisecondsSinceEpoch,
      currentTimestampMs: currentTimestampMs,
    );
  }

  /// Initial compass bearing in degrees (0.0 to 360.0).
  static double calculateBearingDegrees(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final lat1Rad = lat1 * math.pi / 180.0;
    final lat2Rad = lat2 * math.pi / 180.0;
    final dLon = (lng2 - lng1) * math.pi / 180.0;

    final y = math.sin(dLon) * math.cos(lat2Rad);
    final x = math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(dLon);

    final brng = math.atan2(y, x) * 180.0 / math.pi;
    return (brng + 360.0) % 360.0;
  }

  /// Formatted cardinal direction (e.g. "N", "NE", "E", "SE", "S", "SW", "W", "NW").
  static String cardinalDirection(double degrees) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((degrees + 22.5) % 360.0 / 45.0).floor() % 8;
    return directions[index];
  }

  /// Formats raw meters into human-friendly distance strings ("420 m" or "2.4 km").
  static String formatDistance(double meters) {
    if (meters < 1000.0) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000.0).toStringAsFixed(1)} km';
    }
  }

  /// Formats horizontal uncertainty into standard badge representation ("± 18 m" or "± 1.2 km").
  static String formatUncertainty(double meters) {
    if (meters < 1000.0) {
      return '± ${meters.round()} m';
    } else {
      return '± ${(meters / 1000.0).toStringAsFixed(1)} km';
    }
  }
}

/// Standalone top-level function matching specification requirement:
///
/// GeospatialDistanceResult calculateDistance({
///   required double lat1,
///   required double lng1,
///   required double accuracy1,
///   required int timestamp1,
///   required double lat2,
///   required double lng2,
///   required double accuracy2,
///   required int timestamp2,
/// })
GeospatialDistanceResult calculateDistance({
  required double lat1,
  required double lng1,
  required double accuracy1,
  required int timestamp1,
  required double lat2,
  required double lng2,
  required double accuracy2,
  required int timestamp2,
}) {
  return HaversineDistance.calculateDistance(
    lat1: lat1,
    lng1: lng1,
    accuracy1: accuracy1,
    timestamp1: timestamp1,
    lat2: lat2,
    lng2: lng2,
    accuracy2: accuracy2,
    timestamp2: timestamp2,
  );
}
