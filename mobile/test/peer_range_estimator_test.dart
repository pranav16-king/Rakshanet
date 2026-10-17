import 'package:flutter_test/flutter_test.dart';
import 'package:rakshanet_mobile/services/location/peer_range_estimator.dart';

void main() {
  group('PeerRangeEstimator - Calibrated Path-Loss Ranging & Trend Analysis', () {
    late PeerRangeEstimator estimator;

    setUp(() {
      estimator = PeerRangeEstimator.withBuffers();
      estimator.clearBuffers();
    });

    test('Calibrated path-loss model computes 1.0m at reference RSSI (-59 dBm, n=2.4)', () {
      final dist = PeerRangeEstimator.calculateDistance(
        measuredRssi: -59.0,
        referenceRssi: -59.0,
        pathLossExponent: 2.4,
      );
      expect(dist, closeTo(1.0, 0.01));
    });

    test('Distance scales accurately with signal attenuation using n=2.4', () {
      // At -71 dBm: delta = 12 dBm. 10^(12 / 24) = 10^0.5 = 3.162m
      final dist71 = PeerRangeEstimator.calculateDistance(
        measuredRssi: -71.0,
        referenceRssi: -59.0,
        pathLossExponent: 2.4,
      );
      expect(dist71, closeTo(3.16, 0.05));

      // At -83 dBm: delta = 24 dBm. 10^(24 / 24) = 10^1.0 = 10.0m
      final dist83 = PeerRangeEstimator.calculateDistance(
        measuredRssi: -83.0,
        referenceRssi: -59.0,
        pathLossExponent: 2.4,
      );
      expect(dist83, closeTo(10.0, 0.1));
    });

    test('Rolling median filter maintains maximum 7 samples and rejects multipath spikes', () {
      const peerId = 'PEER-NODE-DELTA';
      // Feed 7 samples with an extreme multipath anomaly (-95 dBm)
      final samples = [-62, -61, -63, -95, -62, -60, -62];

      for (final s in samples) {
        estimator.addRssiSample(peerId, s);
      }

      final buffer = estimator.getBuffer(peerId);
      expect(buffer.length, equals(7));

      // Adding an 8th sample removes the oldest sample (-62)
      estimator.addRssiSample(peerId, -61);
      final updatedBuffer = estimator.getBuffer(peerId);
      expect(updatedBuffer.length, equals(7));
      expect(updatedBuffer.first, equals(-61)); // Second sample becomes first
      expect(updatedBuffer.last, equals(-61));

      // Median should completely filter out the -95 spike
      final estimate = estimator.getProximityEstimate(peerId)!;
      expect(estimate.rawMedianRssi, closeTo(-61.5, 1.0));
      expect(estimate.distanceMeters, lessThan(3.0));
    });

    test('Signal trend detection identifies approaching peer (RSSI increasing)', () {
      const peerId = 'PEER-APPROACHING';
      // Peer starts far (-85 dBm) and approaches rescuer (-62 dBm)
      final samples = [-86, -85, -84, -75, -70, -64, -62];

      PeerProximityEstimate? lastEstimate;
      for (final s in samples) {
        lastEstimate = estimator.addRssiSample(peerId, s);
      }

      expect(lastEstimate, isNotNull);
      expect(lastEstimate!.trend, equals(SignalTrend.approaching));
    });

    test('Signal trend detection identifies retreating peer (RSSI decreasing)', () {
      const peerId = 'PEER-RETREATING';
      // Peer moves away: -60 dBm -> -88 dBm
      final samples = [-60, -61, -62, -72, -78, -85, -88];

      PeerProximityEstimate? lastEstimate;
      for (final s in samples) {
        lastEstimate = estimator.addRssiSample(peerId, s);
      }

      expect(lastEstimate, isNotNull);
      expect(lastEstimate!.trend, equals(SignalTrend.retreating));
    });

    test('Signal trend detection identifies stationary peer (RSSI stable)', () {
      const peerId = 'PEER-STATIONARY';
      // Peer remains steady around -68 dBm (minor ±1 dBm jitter)
      final samples = [-68, -69, -68, -68, -67, -68, -69];

      PeerProximityEstimate? lastEstimate;
      for (final s in samples) {
        lastEstimate = estimator.addRssiSample(peerId, s);
      }

      expect(lastEstimate, isNotNull);
      expect(lastEstimate!.trend, equals(SignalTrend.stationary));
    });

    test('Confidence rating: UNRELIABLE when sample count is 1', () {
      const peerId = 'PEER-SINGLE-SAMPLE';
      final estimate = estimator.addRssiSample(peerId, -65);

      expect(estimate.sampleCount, equals(1));
      expect(estimate.confidence, equals(ProximityConfidence.unreliable));
      expect(estimate.uncertaintyMeters, equals(PeerRangeEstimator.maxBleDistanceUncertaintyMeters));
    });

    test('Confidence rating: MEDIUM when sample count is between 2 and 4', () {
      const peerId = 'PEER-FEW-SAMPLES';
      estimator.addRssiSample(peerId, -65);
      estimator.addRssiSample(peerId, -64);
      final estimate = estimator.addRssiSample(peerId, -66);

      expect(estimate.sampleCount, equals(3));
      expect(estimate.confidence, equals(ProximityConfidence.medium));
    });

    test('Confidence rating: HIGH when sample count >= 5 and variance < 15 dBm', () {
      const peerId = 'PEER-STEADY-HIGH-CONF';
      // 6 very stable samples (low variance)
      final stableSamples = [-60, -61, -60, -59, -60, -61];
      PeerProximityEstimate? estimate;
      for (final s in stableSamples) {
        estimate = estimator.addRssiSample(peerId, s);
      }

      expect(estimate!.sampleCount, equals(6));
      expect(estimate.variance!, lessThan(15.0));
      expect(estimate.confidence, equals(ProximityConfidence.high));
    });

    test('Confidence rating: UNRELIABLE when variance > 30 dBm even with >= 5 samples', () {
      const peerId = 'PEER-WILD-MULTIPATH';
      // Wild oscillations (-40 to -95) -> variance >> 30
      final noisySamples = [-45, -92, -48, -95, -50, -90];
      PeerProximityEstimate? estimate;
      for (final s in noisySamples) {
        estimate = estimator.addRssiSample(peerId, s);
      }

      expect(estimate!.sampleCount, equals(6));
      expect(estimate.variance!, greaterThan(30.0));
      expect(estimate.confidence, equals(ProximityConfidence.unreliable));
    });

    test('Outputs complete PeerProximityEstimate with all required properties', () {
      const peerId = 'PEER-COMPLETE';
      final samples = [-70, -71, -70, -72, -71];
      PeerProximityEstimate? estimate;
      for (final s in samples) {
        estimate = estimator.addRssiSample(peerId, s);
      }

      expect(estimate, isNotNull);
      expect(estimate!.distanceMeters, greaterThan(0.5));
      expect(estimate.uncertaintyMeters, greaterThanOrEqualTo(PeerRangeEstimator.minBleDistanceUncertaintyMeters));
      expect(estimate.confidence, equals(ProximityConfidence.high));
      expect(estimate.trend, equals(SignalTrend.stationary));
      expect(estimate.sampleCount, equals(5));
      expect(estimate.rawMedianRssi, closeTo(-71.0, 1.0));
    });
  });
}
