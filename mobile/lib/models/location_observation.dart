/// Models for peer-to-peer location observation and multilateration estimation.
///
/// Used by RakshaNet / SignalRescue AI for probabilistic positioning in GPS-denied
/// or degraded emergency disaster environments.
library;


/// Source mechanism used to estimate peer distance.
class LocationSource {
  static const String wifiRtt = 'WIFI_RTT';
  static const String bleRssi = 'BLE_RSSI';
  static const String manual = 'MANUAL';

  const LocationSource._();
}

/// Represents an estimated distance observation between the host device and a peer.
class PeerRangeReading {
  /// Estimated physical distance in meters.
  final double distance;

  /// Uncertainty radius / error bound in meters (e.g. ±15-30m for BLE, ±2-5m for Wi-Fi RTT).
  final double uncertainty;

  /// Measurement method: 'WIFI_RTT', 'BLE_RSSI', or 'MANUAL'.
  final String source;

  /// Confidence score between 0.0 (unreliable) and 1.0 (authoritative).
  final double confidence;

  const PeerRangeReading({
    required this.distance,
    required this.uncertainty,
    required this.source,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
        'distance': distance,
        'uncertainty': uncertainty,
        'source': source,
        'confidence': confidence,
      };

  factory PeerRangeReading.fromJson(Map<String, dynamic> json) {
    return PeerRangeReading(
      distance: (json['distance'] as num).toDouble(),
      uncertainty: (json['uncertainty'] as num).toDouble(),
      source: json['source'] as String? ?? LocationSource.bleRssi,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
    );
  }

  PeerRangeReading copyWith({
    double? distance,
    double? uncertainty,
    String? source,
    double? confidence,
  }) {
    return PeerRangeReading(
      distance: distance ?? this.distance,
      uncertainty: uncertainty ?? this.uncertainty,
      source: source ?? this.source,
      confidence: confidence ?? this.confidence,
    );
  }

  @override
  String toString() =>
      'PeerRangeReading(dist: ${distance.toStringAsFixed(1)}m, ±${uncertainty.toStringAsFixed(1)}m, src: $source, conf: ${(confidence * 100).toStringAsFixed(0)}%)';
}

/// Anchor device with known GPS coordinates and observed distance to the target device.
class LocationAnchor {
  /// Mesh device identifier of the anchor node.
  final String peerDeviceId;

  /// Anchor's reported latitude (WGS84 degrees).
  final double latitude;

  /// Anchor's reported longitude (WGS84 degrees).
  final double longitude;

  /// GPS 1-sigma horizontal accuracy reported by anchor device in meters.
  final double anchorGpsAccuracy;

  /// Estimated distance from local device to this anchor in meters.
  final double estimatedDistance;

  /// Error bound / uncertainty on the estimated distance in meters.
  final double distanceUncertainty;

  /// Epoch millisecond timestamp when observation was recorded.
  final int timestamp;

  /// Ranging technology: 'WIFI_RTT', 'BLE_RSSI', or 'MANUAL'.
  final String source;

  /// Ranging confidence score (0.0 to 1.0).
  final double confidence;

  const LocationAnchor({
    required this.peerDeviceId,
    required this.latitude,
    required this.longitude,
    required this.anchorGpsAccuracy,
    required this.estimatedDistance,
    required this.distanceUncertainty,
    required this.timestamp,
    required this.source,
    required this.confidence,
  });

  /// Check whether anchor GPS accuracy is acceptable for multilateration (<= 50m).
  bool get isGpsAccurate => anchorGpsAccuracy <= 50.0;

  /// Check whether this observation is stale (> maxAgeMs, default 60 seconds).
  bool isStale({int maxAgeMs = 60000, int? currentTimeMs}) {
    final now = currentTimeMs ?? DateTime.now().millisecondsSinceEpoch;
    return (now - timestamp) > maxAgeMs;
  }

  /// Composite weight used in weighted least squares:
  /// weight = (1 / distanceUncertainty) * (1 / anchorGpsAccuracy)
  double get weight {
    final safeDistUncertainty = distanceUncertainty > 0 ? distanceUncertainty : 1.0;
    final safeGpsAccuracy = anchorGpsAccuracy > 0 ? anchorGpsAccuracy : 1.0;
    return (1.0 / safeDistUncertainty) * (1.0 / safeGpsAccuracy);
  }

  Map<String, dynamic> toJson() => {
        'peer_device_id': peerDeviceId,
        'latitude': latitude,
        'longitude': longitude,
        'anchor_gps_accuracy': anchorGpsAccuracy,
        'estimated_distance': estimatedDistance,
        'distance_uncertainty': distanceUncertainty,
        'timestamp': timestamp,
        'source': source,
        'confidence': confidence,
      };

  factory LocationAnchor.fromJson(Map<String, dynamic> json) {
    return LocationAnchor(
      peerDeviceId: (json['peer_device_id'] ?? json['peerDeviceId'] ?? '') as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      anchorGpsAccuracy: (json['anchor_gps_accuracy'] ?? json['anchorGpsAccuracy'] as num).toDouble(),
      estimatedDistance: (json['estimated_distance'] ?? json['estimatedDistance'] as num).toDouble(),
      distanceUncertainty: (json['distance_uncertainty'] ?? json['distanceUncertainty'] as num).toDouble(),
      timestamp: (json['timestamp'] as num).toInt(),
      source: (json['source'] as String?) ?? LocationSource.bleRssi,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
    );
  }

  LocationAnchor copyWith({
    String? peerDeviceId,
    double? latitude,
    double? longitude,
    double? anchorGpsAccuracy,
    double? estimatedDistance,
    double? distanceUncertainty,
    int? timestamp,
    String? source,
    double? confidence,
  }) {
    return LocationAnchor(
      peerDeviceId: peerDeviceId ?? this.peerDeviceId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      anchorGpsAccuracy: anchorGpsAccuracy ?? this.anchorGpsAccuracy,
      estimatedDistance: estimatedDistance ?? this.estimatedDistance,
      distanceUncertainty: distanceUncertainty ?? this.distanceUncertainty,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
      confidence: confidence ?? this.confidence,
    );
  }

  @override
  String toString() =>
      'LocationAnchor($peerDeviceId at ($latitude, $longitude), dist: ${estimatedDistance.toStringAsFixed(1)}m ±${distanceUncertainty.toStringAsFixed(1)}m, gpsAcc: ${anchorGpsAccuracy.toStringAsFixed(1)}m, conf: $confidence)';
}

/// Result of probabilistic multilateration or direct GPS observation.
class EstimatedLocation {
  /// Solved or measured latitude.
  final double latitude;

  /// Solved or measured longitude.
  final double longitude;

  /// Uncertainty radius in meters (horizontal error bound).
  final double uncertaintyRadiusMeters;

  /// Number of GPS anchors utilized in multilateration (1 if standalone GPS fix).
  final int anchorCount;

  /// Root-mean-square residual error in meters across participating anchors.
  final double residualError;

  /// Qualitative confidence rating: 'High', 'Medium', or 'Low'.
  final String confidenceRating;

  /// True if direct standalone hardware GPS fix; false if multilaterated from peer anchors.
  final bool isExactGps;

  /// Timestamp in epoch milliseconds when calculated.
  final int timestamp;

  const EstimatedLocation({
    required this.latitude,
    required this.longitude,
    required this.uncertaintyRadiusMeters,
    required this.anchorCount,
    required this.residualError,
    required this.confidenceRating,
    required this.isExactGps,
    required this.timestamp,
  });

  /// Human-readable emergency telemetry display string.
  /// e.g. "Estimated Location • ±35 m • 4 GPS anchors"
  /// or "Exact GPS • ±5 m"
  String get displayString {
    final roundedUncertainty = uncertaintyRadiusMeters.round();
    if (isExactGps) {
      return 'Exact GPS • ±$roundedUncertainty m';
    }
    final anchorLabel = anchorCount == 1 ? '1 GPS anchor' : '$anchorCount GPS anchors';
    return 'Estimated Location • ±$roundedUncertainty m • $anchorLabel';
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'uncertainty_radius_meters': uncertaintyRadiusMeters,
        'anchor_count': anchorCount,
        'residual_error': residualError,
        'confidence_rating': confidenceRating,
        'is_exact_gps': isExactGps,
        'timestamp': timestamp,
        'display_string': displayString,
      };

  factory EstimatedLocation.fromJson(Map<String, dynamic> json) {
    return EstimatedLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      uncertaintyRadiusMeters: (json['uncertainty_radius_meters'] ?? json['uncertaintyRadiusMeters'] as num).toDouble(),
      anchorCount: (json['anchor_count'] ?? json['anchorCount'] as num).toInt(),
      residualError: (json['residual_error'] ?? json['residualError'] as num).toDouble(),
      confidenceRating: (json['confidence_rating'] ?? json['confidenceRating'] ?? 'Medium') as String,
      isExactGps: (json['is_exact_gps'] ?? json['isExactGps'] ?? false) as bool,
      timestamp: (json['timestamp'] as num).toInt(),
    );
  }

  EstimatedLocation copyWith({
    double? latitude,
    double? longitude,
    double? uncertaintyRadiusMeters,
    int? anchorCount,
    double? residualError,
    String? confidenceRating,
    bool? isExactGps,
    int? timestamp,
  }) {
    return EstimatedLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      uncertaintyRadiusMeters: uncertaintyRadiusMeters ?? this.uncertaintyRadiusMeters,
      anchorCount: anchorCount ?? this.anchorCount,
      residualError: residualError ?? this.residualError,
      confidenceRating: confidenceRating ?? this.confidenceRating,
      isExactGps: isExactGps ?? this.isExactGps,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() =>
      'EstimatedLocation($latitude, $longitude, $displayString, conf: $confidenceRating, resErr: ${residualError.toStringAsFixed(2)}m)';
}
