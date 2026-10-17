import 'dart:math' as math;

import '../../models/location_observation.dart';

/// Signal trend detected over rolling RSSI sample window.
enum SignalTrend {
  approaching,
  retreating,
  stationary;

  String get label => name.toUpperCase();

  static SignalTrend fromString(String val) {
    return SignalTrend.values.firstWhere(
      (e) => e.name.toLowerCase() == val.trim().toLowerCase(),
      orElse: () => SignalTrend.stationary,
    );
  }
}

/// Confidence rating for peer distance/proximity estimation.
enum ProximityConfidence {
  high,
  medium,
  unreliable;

  String get label => name.toUpperCase();

  static ProximityConfidence fromString(String val) {
    return ProximityConfidence.values.firstWhere(
      (e) => e.name.toLowerCase() == val.trim().toLowerCase(),
      orElse: () => ProximityConfidence.unreliable,
    );
  }
}

/// Rich proximity and distance estimation for a peer node.
class PeerProximityEstimate {
  final double distanceMeters;
  final double uncertaintyMeters;
  final ProximityConfidence confidence;
  final SignalTrend trend;
  final int sampleCount;
  final double? rawMedianRssi;
  final double? variance;
  final DateTime? timestamp;

  const PeerProximityEstimate({
    required this.distanceMeters,
    required this.uncertaintyMeters,
    required this.confidence,
    required this.trend,
    required this.sampleCount,
    this.rawMedianRssi,
    this.variance,
    this.timestamp,
  });

  /// Positional constructor for convenience
  const PeerProximityEstimate.positional(
    this.distanceMeters,
    this.uncertaintyMeters,
    this.confidence,
    this.trend,
    this.sampleCount, [
    this.rawMedianRssi,
    this.variance,
    this.timestamp,
  ]);

  double get distance => distanceMeters;
  double get uncertainty => uncertaintyMeters;
  int get samples => sampleCount;

  Map<String, dynamic> toJson() => {
        'distance_meters': distanceMeters,
        'uncertainty_meters': uncertaintyMeters,
        'confidence': confidence.name.toUpperCase(),
        'trend': trend.name,
        'sample_count': sampleCount,
        if (rawMedianRssi != null) 'raw_median_rssi': rawMedianRssi,
        if (variance != null) 'variance': variance,
        if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
      };

  @override
  String toString() =>
      'PeerProximityEstimate(dist: ${distanceMeters.toStringAsFixed(1)}m ±${uncertaintyMeters.toStringAsFixed(1)}m, '
      'conf: ${confidence.name.toUpperCase()}, trend: ${trend.name}, samples: $sampleCount)';
}

/// Estimates peer-to-peer physical distances from radio observations (BLE RSSI and Wi-Fi RTT).
///
/// Implements calibrated log-distance path loss propagation models, rolling median filtering
/// over 7 samples, signal trend detection (approaching, retreating, stationary), and
/// statistical variance-based confidence ratings.
class PeerRangeEstimator {
  /// Default calibrated RSSI at 1-meter reference distance for standard BLE radios (in dBm).
  static const double defaultReferenceRssi = -59.0;
  static const double defaultBleTxPowerAt1M = defaultReferenceRssi;

  /// Default path loss exponent (n) for indoor/disaster obstacle model (2.4).
  static const double defaultPathLossExponent = 2.4;

  /// Maximum samples retained per peer in rolling filter.
  static const int maxRollingBufferSize = 7;

  /// Minimum distance uncertainty for BLE RSSI observations (in meters).
  static const double minBleDistanceUncertaintyMeters = 15.0;

  /// Maximum distance uncertainty for BLE RSSI observations (in meters).
  static const double maxBleDistanceUncertaintyMeters = 30.0;

  /// Default uncertainty for Wi-Fi RTT observations (in meters).
  static const double defaultWifiRttUncertaintyMeters = 3.0;

  // Global static buffer store ensuring `const PeerRangeEstimator()` compiles and functions
  static final Map<String, List<int>> _globalPeerRssiBuffers = {};
  final Map<String, List<int>>? _localBuffers;

  const PeerRangeEstimator() : _localBuffers = null;

  /// Constructor with an isolated local buffer (ideal for isolated testing)
  PeerRangeEstimator.withBuffers([Map<String, List<int>>? buffers])
      : _localBuffers = buffers ?? {};

  Map<String, List<int>> get _buffers => _localBuffers ?? _globalPeerRssiBuffers;

  /// Clears rolling buffer for a specific peer or all peers.
  void clearBuffers([String? peerId]) {
    if (peerId != null) {
      _buffers.remove(peerId);
    } else {
      _buffers.clear();
    }
  }

  /// Returns unmodifiable copy of sample buffer for peer.
  List<int> getBuffer(String peerId) {
    final list = _buffers[peerId];
    return list != null ? List<int>.unmodifiable(list) : const [];
  }

  /// Calibrated path-loss model:
  /// distance = 10 ^ ((referenceRSSI - measuredRSSI) / (10 * pathLossExponent))
  static double calculateDistance({
    required double measuredRssi,
    double referenceRssi = defaultReferenceRssi,
    double pathLossExponent = defaultPathLossExponent,
  }) {
    final safeExponent =
        pathLossExponent > 0.1 ? pathLossExponent : defaultPathLossExponent;
    final clampedRssi = measuredRssi.clamp(-115.0, -25.0);
    final exponent = (referenceRssi - clampedRssi) / (10.0 * safeExponent);
    final rawDistance = math.pow(10.0, exponent).toDouble();
    return rawDistance.clamp(0.5, 120.0);
  }

  /// Calculates rolling median of samples to reject multipath spikes and noise.
  static double calculateMedian(List<num> samples) {
    if (samples.isEmpty) return defaultReferenceRssi;
    final sorted = List<num>.from(samples)..sort();
    final len = sorted.length;
    final mid = len ~/ 2;
    if (len % 2 == 1) {
      return sorted[mid].toDouble();
    } else {
      return (sorted[mid - 1] + sorted[mid]) / 2.0;
    }
  }

  /// Calculates variance of sample set in dBm².
  static double calculateVariance(List<num> samples) {
    if (samples.length <= 1) return 0.0;
    final sum = samples.fold<double>(0.0, (acc, val) => acc + val.toDouble());
    final mean = sum / samples.length;
    final sumSquaredDiff = samples.fold<double>(
      0.0,
      (sumDiff, val) => sumDiff + math.pow(val.toDouble() - mean, 2),
    );
    return sumSquaredDiff / samples.length;
  }

  /// Signal trend detection:
  /// Compare rolling median of first 3 samples vs last 3 samples.
  /// If samples.length < 3, trend is stationary.
  /// If median(last 3) > median(first 3) + deadband -> approaching (RSSI increasing / closer).
  /// If median(last 3) < median(first 3) - deadband -> retreating (RSSI decreasing / farther).
  /// Otherwise -> stationary.
  static SignalTrend detectSignalTrend(
    List<num> samples, {
    double deadbandDbm = 1.5,
  }) {
    if (samples.length < 3) {
      return SignalTrend.stationary;
    }

    final firstThree = samples.sublist(0, 3);
    final lastThree = samples.sublist(samples.length - 3);

    final firstMedian = calculateMedian(firstThree);
    final lastMedian = calculateMedian(lastThree);

    final delta = lastMedian - firstMedian;

    if (delta > deadbandDbm) {
      return SignalTrend.approaching;
    } else if (delta < -deadbandDbm) {
      return SignalTrend.retreating;
    } else {
      return SignalTrend.stationary;
    }
  }

  /// Confidence rating:
  /// - HIGH (sample count >= 5, variance < 15 dBm)
  /// - MEDIUM (sample count 2-4, or sample count >= 5 with variance <= 30)
  /// - UNRELIABLE (sample count 1 or variance > 30 dBm)
  static ProximityConfidence evaluateConfidence(
    int sampleCount,
    double variance,
  ) {
    if (sampleCount <= 1 || variance > 30.0) {
      return ProximityConfidence.unreliable;
    }
    if (sampleCount >= 5 && variance < 15.0) {
      return ProximityConfidence.high;
    }
    return ProximityConfidence.medium;
  }

  /// Records a new RSSI sample for [peerId], updates the 7-sample rolling buffer,
  /// and outputs a calibrated [PeerProximityEstimate].
  PeerProximityEstimate addRssiSample(
    String peerId,
    int rssi, {
    double referenceRssi = defaultReferenceRssi,
    double pathLossExponent = defaultPathLossExponent,
    double deadbandDbm = 1.5,
  }) {
    final buffer = _buffers.putIfAbsent(peerId, () => <int>[]);
    buffer.add(rssi);
    if (buffer.length > maxRollingBufferSize) {
      buffer.removeAt(0);
    }

    return estimateFromRssiSamples(
      buffer,
      referenceRssi: referenceRssi,
      pathLossExponent: pathLossExponent,
      deadbandDbm: deadbandDbm,
    );
  }

  /// Directly estimates peer proximity from a given buffer of RSSI samples.
  PeerProximityEstimate estimateFromRssiSamples(
    List<int> samples, {
    double referenceRssi = defaultReferenceRssi,
    double pathLossExponent = defaultPathLossExponent,
    double deadbandDbm = 1.5,
  }) {
    final sampleCount = samples.length;
    if (sampleCount == 0) {
      return const PeerProximityEstimate(
        distanceMeters: 50.0,
        uncertaintyMeters: maxBleDistanceUncertaintyMeters,
        confidence: ProximityConfidence.unreliable,
        trend: SignalTrend.stationary,
        sampleCount: 0,
      );
    }

    final medianRssi = calculateMedian(samples);
    final variance = calculateVariance(samples);
    final confidence = evaluateConfidence(sampleCount, variance);
    final trend = detectSignalTrend(samples, deadbandDbm: deadbandDbm);

    final distance = calculateDistance(
      measuredRssi: medianRssi,
      referenceRssi: referenceRssi,
      pathLossExponent: pathLossExponent,
    );

    // Distance uncertainty scales with distance and penalizes noisy/unreliable estimates
    double uncertainty = (minBleDistanceUncertaintyMeters + (distance * 0.35))
        .clamp(minBleDistanceUncertaintyMeters, maxBleDistanceUncertaintyMeters);
    if (confidence == ProximityConfidence.unreliable) {
      uncertainty = maxBleDistanceUncertaintyMeters;
    }

    return PeerProximityEstimate(
      distanceMeters: distance,
      uncertaintyMeters: uncertainty,
      confidence: confidence,
      trend: trend,
      sampleCount: sampleCount,
      rawMedianRssi: medianRssi,
      variance: variance,
      timestamp: DateTime.now(),
    );
  }

  /// Alias for [addRssiSample].
  PeerProximityEstimate estimatePeerProximity(
    String peerId,
    int rssi, {
    double referenceRssi = defaultReferenceRssi,
    double pathLossExponent = defaultPathLossExponent,
  }) =>
      addRssiSample(
        peerId,
        rssi,
        referenceRssi: referenceRssi,
        pathLossExponent: pathLossExponent,
      );

  /// Retrieves the latest proximity estimate for [peerId] without adding new samples.
  PeerProximityEstimate? getProximityEstimate(
    String peerId, {
    double referenceRssi = defaultReferenceRssi,
    double pathLossExponent = defaultPathLossExponent,
  }) {
    final buffer = _buffers[peerId];
    if (buffer == null || buffer.isEmpty) return null;
    return estimateFromRssiSamples(
      buffer,
      referenceRssi: referenceRssi,
      pathLossExponent: pathLossExponent,
    );
  }

  // ---------------------------------------------------------------------------
  // Backward Compatible Single-Reading Estimators & Anchor Helpers
  // ---------------------------------------------------------------------------

  /// Estimates peer distance from BLE RSSI using the log-distance path loss model:
  ///
  /// d = 10 ^ ((txPower - RSSI) / (10 * n))
  PeerRangeReading estimateFromBleRssi(
    int rssi, {
    double txPower = defaultBleTxPowerAt1M,
    double pathLossExponent = defaultPathLossExponent,
  }) {
    final clampedRssi = rssi.clamp(-115, -25).toDouble();
    final safeExponent =
        pathLossExponent > 0.5 ? pathLossExponent : defaultPathLossExponent;

    final exponent = (txPower - clampedRssi) / (10.0 * safeExponent);
    final rawDistance = math.pow(10.0, exponent).toDouble();
    final distance = rawDistance.clamp(0.5, 120.0);

    final uncertainty = (minBleDistanceUncertaintyMeters + (distance * 0.35))
        .clamp(minBleDistanceUncertaintyMeters, maxBleDistanceUncertaintyMeters);

    final confidence = (0.60 - (distance / 120.0) * 0.35).clamp(0.25, 0.60);

    return PeerRangeReading(
      distance: distance,
      uncertainty: uncertainty,
      source: LocationSource.bleRssi,
      confidence: confidence,
    );
  }

  /// Estimates peer distance using Wi-Fi RTT (Fine Timing Measurement, 802.11mc).
  PeerRangeReading estimateFromWifiRtt(
    double measuredDistanceMeters, {
    double? rttStdDevMeters,
  }) {
    final distance = math.max(0.2, measuredDistanceMeters);

    final uncertainty = rttStdDevMeters != null
        ? (rttStdDevMeters * 2.0).clamp(2.0, 5.0)
        : defaultWifiRttUncertaintyMeters;

    final confidence = (0.95 - (uncertainty / 20.0)).clamp(0.85, 0.95);

    return PeerRangeReading(
      distance: distance,
      uncertainty: uncertainty,
      source: LocationSource.wifiRtt,
      confidence: confidence,
    );
  }

  /// Creates a manual distance reading (e.g. visual observation by rescuer).
  PeerRangeReading estimateManual(
    double distanceMeters, {
    double uncertaintyMeters = 10.0,
    double confidence = 0.70,
  }) {
    return PeerRangeReading(
      distance: math.max(0.5, distanceMeters),
      uncertainty: uncertaintyMeters.clamp(3.0, 50.0),
      source: LocationSource.manual,
      confidence: confidence.clamp(0.1, 0.9),
    );
  }

  /// Assembles a complete LocationAnchor from an anchor's GPS fix and a peer range reading.
  LocationAnchor createAnchor({
    required String peerDeviceId,
    required double latitude,
    required double longitude,
    required double anchorGpsAccuracy,
    required PeerRangeReading rangeReading,
    int? timestamp,
  }) {
    return LocationAnchor(
      peerDeviceId: peerDeviceId,
      latitude: latitude,
      longitude: longitude,
      anchorGpsAccuracy: anchorGpsAccuracy,
      estimatedDistance: rangeReading.distance,
      distanceUncertainty: rangeReading.uncertainty,
      timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch,
      source: rangeReading.source,
      confidence: rangeReading.confidence,
    );
  }

  /// Convenience factory to create a LocationAnchor directly from BLE RSSI.
  LocationAnchor createAnchorFromBle({
    required String peerDeviceId,
    required double latitude,
    required double longitude,
    required double anchorGpsAccuracy,
    required int rssi,
    double txPower = defaultBleTxPowerAt1M,
    double pathLossExponent = defaultPathLossExponent,
    int? timestamp,
  }) {
    final range = estimateFromBleRssi(
      rssi,
      txPower: txPower,
      pathLossExponent: pathLossExponent,
    );
    return createAnchor(
      peerDeviceId: peerDeviceId,
      latitude: latitude,
      longitude: longitude,
      anchorGpsAccuracy: anchorGpsAccuracy,
      rangeReading: range,
      timestamp: timestamp,
    );
  }

  /// Convenience factory to create a LocationAnchor directly from Wi-Fi RTT.
  LocationAnchor createAnchorFromWifiRtt({
    required String peerDeviceId,
    required double latitude,
    required double longitude,
    required double anchorGpsAccuracy,
    required double rttDistanceMeters,
    double? rttStdDevMeters,
    int? timestamp,
  }) {
    final range = estimateFromWifiRtt(
      rttDistanceMeters,
      rttStdDevMeters: rttStdDevMeters,
    );
    return createAnchor(
      peerDeviceId: peerDeviceId,
      latitude: latitude,
      longitude: longitude,
      anchorGpsAccuracy: anchorGpsAccuracy,
      rangeReading: range,
      timestamp: timestamp,
    );
  }
}
