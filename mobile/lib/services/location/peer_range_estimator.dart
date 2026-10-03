import 'dart:math' as math;

import '../../models/location_observation.dart';

/// Estimates peer-to-peer physical distances from radio observations (BLE RSSI and Wi-Fi RTT).
///
/// Implements log-distance path loss propagation models and enforces the safety rule
/// that BLE RSSI is noisy and non-deterministic, assigning appropriate distance
/// uncertainties and confidence penalties.
class PeerRangeEstimator {
  /// Default calibrated RSSI at 1-meter reference distance for standard BLE radios (in dBm).
  static const double defaultBleTxPowerAt1M = -59.0;

  /// Default path loss exponent (n) for disaster / indoor / multipath propagation environments.
  /// (Free space = 2.0; typical urban/indoor rubble = 2.5 - 3.5).
  static const double defaultPathLossExponent = 2.8;

  /// Minimum distance uncertainty for BLE RSSI observations (in meters).
  static const double minBleDistanceUncertaintyMeters = 15.0;

  /// Maximum distance uncertainty for BLE RSSI observations (in meters).
  static const double maxBleDistanceUncertaintyMeters = 30.0;

  /// Default uncertainty for Wi-Fi RTT observations (in meters).
  static const double defaultWifiRttUncertaintyMeters = 3.0;

  const PeerRangeEstimator();

  /// Estimates peer distance from BLE RSSI using the log-distance path loss model:
  ///
  /// d = 10 ^ ((txPower - RSSI) / (10 * n))
  ///
  /// CRITICAL RULE: BLE RSSI is inherently noisy, subject to multipath interference,
  /// antenna shadowing, and physical obstacles. Distance estimation from BLE is NEVER
  /// exact. This method explicitly assigns high distance uncertainty (±15 to ±30m)
  /// and conservative confidence ratings (0.25 to 0.60).
  PeerRangeReading estimateFromBleRssi(
    int rssi, {
    double txPower = defaultBleTxPowerAt1M,
    double pathLossExponent = defaultPathLossExponent,
  }) {
    // Sanitize RSSI boundaries (realistic BLE operational envelope: -110 dBm to -25 dBm)
    final clampedRssi = rssi.clamp(-115, -25).toDouble();
    final safeExponent = pathLossExponent > 0.5 ? pathLossExponent : defaultPathLossExponent;

    // Log-distance path loss equation: d = 10 ^ ((txPower - RSSI) / (10 * n))
    final exponent = (txPower - clampedRssi) / (10.0 * safeExponent);
    final rawDistance = math.pow(10.0, exponent).toDouble();

    // Physical mesh constraints: clamp distance between 0.5m and 120.0m
    final distance = rawDistance.clamp(0.5, 120.0);

    // Distance uncertainty scales with distance: ±15m to ±30m
    // Because logarithmic derivative d(dist)/d(RSSI) increases with distance,
    // weak signals have greater uncertainty.
    final uncertainty = (minBleDistanceUncertaintyMeters + (distance * 0.35))
        .clamp(minBleDistanceUncertaintyMeters, maxBleDistanceUncertaintyMeters);

    // Confidence rating: BLE RSSI never exceeds 0.60 confidence
    // Strong signals (-30 to -60 dBm): 0.50 - 0.60
    // Moderate signals (-61 to -80 dBm): 0.38 - 0.49
    // Weak signals (< -80 dBm): 0.25 - 0.37
    final confidence = (0.60 - (distance / 120.0) * 0.35).clamp(0.25, 0.60);

    return PeerRangeReading(
      distance: distance,
      uncertainty: uncertainty,
      source: LocationSource.bleRssi,
      confidence: confidence,
    );
  }

  /// Estimates peer distance using Wi-Fi RTT (Fine Timing Measurement, 802.11mc).
  ///
  /// Wi-Fi RTT measures round-trip time-of-flight at the PHY layer, providing
  /// sub-meter to few-meter precision. Assigns high confidence (0.85 to 0.95)
  /// and tight uncertainty bounds (±2m to ±5m).
  PeerRangeReading estimateFromWifiRtt(
    double measuredDistanceMeters, {
    double? rttStdDevMeters,
  }) {
    final distance = math.max(0.2, measuredDistanceMeters);

    // Uncertainty bounded tightly between ±2.0m and ±5.0m
    final uncertainty = rttStdDevMeters != null
        ? (rttStdDevMeters * 2.0).clamp(2.0, 5.0)
        : defaultWifiRttUncertaintyMeters;

    // Confidence is very high for time-of-flight ranging
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
