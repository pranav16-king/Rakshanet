import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:rakshanet_mobile/models/encrypted_location_payload.dart';
import 'package:rakshanet_mobile/models/location_observation.dart';
import 'package:rakshanet_mobile/services/location/location_estimation_engine.dart';
import 'package:rakshanet_mobile/services/location/peer_range_estimator.dart';

void main() {
  group('PeerRangeEstimator Tests', () {
    const estimator = PeerRangeEstimator();

    test('BLE RSSI log-distance path loss at 1m reference distance', () {
      final reading = estimator.estimateFromBleRssi(
        -59,
        txPower: -59.0,
        pathLossExponent: 2.8,
      );

      // At txPower (-59 dBm), distance = 10^0 = 1.0 meter
      expect(reading.distance, closeTo(1.0, 0.05));
      expect(reading.source, equals(LocationSource.bleRssi));
      // Ble uncertainty rule: bounded between 15m and 30m
      expect(reading.uncertainty, greaterThanOrEqualTo(15.0));
      expect(reading.uncertainty, lessThanOrEqualTo(30.0));
      // BLE confidence rule: bounded between 0.25 and 0.60
      expect(reading.confidence, greaterThanOrEqualTo(0.25));
      expect(reading.confidence, lessThanOrEqualTo(0.60));
    });

    test('BLE RSSI distance increases as signal attenuates', () {
      final nearReading = estimator.estimateFromBleRssi(-65);
      final midReading = estimator.estimateFromBleRssi(-80);
      final farReading = estimator.estimateFromBleRssi(-95);

      expect(nearReading.distance, lessThan(midReading.distance));
      expect(midReading.distance, lessThan(farReading.distance));

      // Uncertainty should be higher for further/weaker signals
      expect(farReading.uncertainty, greaterThanOrEqualTo(nearReading.uncertainty));
      // Confidence should be lower for further/weaker signals
      expect(farReading.confidence, lessThan(nearReading.confidence));
    });

    test('Wi-Fi RTT provides high confidence and tight uncertainty (2-5m)', () {
      final rttReading = estimator.estimateFromWifiRtt(12.5, rttStdDevMeters: 1.2);

      expect(rttReading.distance, closeTo(12.5, 0.1));
      expect(rttReading.source, equals(LocationSource.wifiRtt));
      expect(rttReading.uncertainty, greaterThanOrEqualTo(2.0));
      expect(rttReading.uncertainty, lessThanOrEqualTo(5.0));
      expect(rttReading.confidence, greaterThanOrEqualTo(0.85));
    });

    test('createAnchor factory builds valid LocationAnchor', () {
      final anchor = estimator.createAnchorFromBle(
        peerDeviceId: 'SR-B101-C202',
        latitude: 12.9716,
        longitude: 77.5946,
        anchorGpsAccuracy: 6.5,
        rssi: -72,
      );

      expect(anchor.peerDeviceId, equals('SR-B101-C202'));
      expect(anchor.isGpsAccurate, isTrue);
      expect(anchor.estimatedDistance, greaterThan(1.0));
      expect(anchor.weight, greaterThan(0.0));
      expect(anchor.source, equals(LocationSource.bleRssi));
    });
  });

  group('LocationEstimationEngine Tests', () {
    const engine = LocationEstimationEngine();
    final now = DateTime.now().millisecondsSinceEpoch;

    test('Rejects stale anchors older than 60 seconds', () {
      final freshAnchor = LocationAnchor(
        peerDeviceId: 'A1',
        latitude: 12.9710,
        longitude: 77.5940,
        anchorGpsAccuracy: 5.0,
        estimatedDistance: 20.0,
        distanceUncertainty: 15.0,
        timestamp: now,
        source: LocationSource.bleRssi,
        confidence: 0.5,
      );

      final staleAnchor = freshAnchor.copyWith(
        peerDeviceId: 'A2',
        timestamp: now - 65000, // 65 seconds old
      );

      final result = engine.estimateLocation([
        freshAnchor,
        staleAnchor,
      ], referenceTimeMs: now);

      // Only 1 fresh anchor -> insufficient anchors (< 3)
      expect(result, isNull);
    });

    test('Rejects inaccurate anchors with GPS accuracy > 50m', () {
      final accurateAnchor = LocationAnchor(
        peerDeviceId: 'A1',
        latitude: 12.9710,
        longitude: 77.5940,
        anchorGpsAccuracy: 10.0,
        estimatedDistance: 20.0,
        distanceUncertainty: 15.0,
        timestamp: now,
        source: LocationSource.bleRssi,
        confidence: 0.5,
      );

      final degradedGpsAnchor = accurateAnchor.copyWith(
        peerDeviceId: 'A2',
        anchorGpsAccuracy: 65.0, // > 50m
      );

      final result = engine.estimateLocation([
        accurateAnchor,
        degradedGpsAnchor,
      ], referenceTimeMs: now);

      expect(result, isNull);
    });

    test('Accurately solves 2D multilateration for 4 surrounding anchors', () {
      // True target location (Ground Truth)
      const targetLat = 12.971598;
      const targetLon = 77.594562;

      // Coordinate converter helper for exact distances
      const r = LocationEstimationEngine.earthRadiusMeters;
      const degToRad = math.pi / 180.0;
      final latRad = targetLat * degToRad;

      double distToTarget(double lat, double lon) {
        final dx = (lon - targetLon) * degToRad * r * math.cos(latRad);
        final dy = (lat - targetLat) * degToRad * r;
        return math.sqrt(dx * dx + dy * dy);
      }

      // Generate 4 anchors positioned around the target:
      // Anchor 1: ~35m North
      const a1Lat = targetLat + 0.000315;
      const a1Lon = targetLon;
      // Anchor 2: ~40m South
      const a2Lat = targetLat - 0.000360;
      const a2Lon = targetLon;
      // Anchor 3: ~38m East
      const a3Lat = targetLat;
      final a3Lon = targetLon + (38.0 / (degToRad * r * math.cos(latRad)));
      // Anchor 4: ~32m West
      const a4Lat = targetLat;
      final a4Lon = targetLon - (32.0 / (degToRad * r * math.cos(latRad)));

      final anchors = [
        LocationAnchor(
          peerDeviceId: 'NODE_N',
          latitude: a1Lat,
          longitude: a1Lon,
          anchorGpsAccuracy: 4.0,
          estimatedDistance: distToTarget(a1Lat, a1Lon),
          distanceUncertainty: 5.0,
          timestamp: now,
          source: LocationSource.wifiRtt,
          confidence: 0.9,
        ),
        LocationAnchor(
          peerDeviceId: 'NODE_S',
          latitude: a2Lat,
          longitude: a2Lon,
          anchorGpsAccuracy: 4.0,
          estimatedDistance: distToTarget(a2Lat, a2Lon),
          distanceUncertainty: 5.0,
          timestamp: now,
          source: LocationSource.wifiRtt,
          confidence: 0.9,
        ),
        LocationAnchor(
          peerDeviceId: 'NODE_E',
          latitude: a3Lat,
          longitude: a3Lon,
          anchorGpsAccuracy: 4.0,
          estimatedDistance: distToTarget(a3Lat, a3Lon),
          distanceUncertainty: 5.0,
          timestamp: now,
          source: LocationSource.wifiRtt,
          confidence: 0.9,
        ),
        LocationAnchor(
          peerDeviceId: 'NODE_W',
          latitude: a4Lat,
          longitude: a4Lon,
          anchorGpsAccuracy: 4.0,
          estimatedDistance: distToTarget(a4Lat, a4Lon),
          distanceUncertainty: 5.0,
          timestamp: now,
          source: LocationSource.wifiRtt,
          confidence: 0.9,
        ),
      ];

      final solved = engine.estimateLocation(anchors, referenceTimeMs: now);

      expect(solved, isNotNull);
      // Solved coordinates should match target within sub-meter precision
      expect(solved!.latitude, closeTo(targetLat, 0.00001));
      expect(solved.longitude, closeTo(targetLon, 0.00001));
      expect(solved.anchorCount, equals(4));
      expect(solved.residualError, lessThan(1.0));
      expect(solved.displayString, contains('4 GPS anchors'));
      expect(solved.displayString, contains('Estimated Location • ±'));
    });

    test('Iterative outlier rejection eliminates corrupted anchor', () {
      const targetLat = 12.971598;
      const targetLon = 77.594562;

      const r = LocationEstimationEngine.earthRadiusMeters;
      const degToRad = math.pi / 180.0;
      final latRad = targetLat * degToRad;

      double distToTarget(double lat, double lon) {
        final dx = (lon - targetLon) * degToRad * r * math.cos(latRad);
        final dy = (lat - targetLat) * degToRad * r;
        return math.sqrt(dx * dx + dy * dy);
      }

      // 4 genuine anchors
      final a1Lat = targetLat + 0.00030;
      final a1Lon = targetLon;
      final a2Lat = targetLat - 0.00030;
      final a2Lon = targetLon;
      final a3Lat = targetLat;
      final a3Lon = targetLon + (30.0 / (degToRad * r * math.cos(latRad)));
      final a4Lat = targetLat;
      final a4Lon = targetLon - (30.0 / (degToRad * r * math.cos(latRad)));

      // 5th corrupted outlier anchor (true distance is ~40m, but spoofed/multipath corrupted to 200m)
      final a5Lat = targetLat + 0.00025;
      final a5Lon = targetLon + 0.00025;

      final anchors = [
        LocationAnchor(
          peerDeviceId: 'VALID_1',
          latitude: a1Lat,
          longitude: a1Lon,
          anchorGpsAccuracy: 4.0,
          estimatedDistance: distToTarget(a1Lat, a1Lon),
          distanceUncertainty: 4.0,
          timestamp: now,
          source: LocationSource.wifiRtt,
          confidence: 0.9,
        ),
        LocationAnchor(
          peerDeviceId: 'VALID_2',
          latitude: a2Lat,
          longitude: a2Lon,
          anchorGpsAccuracy: 4.0,
          estimatedDistance: distToTarget(a2Lat, a2Lon),
          distanceUncertainty: 4.0,
          timestamp: now,
          source: LocationSource.wifiRtt,
          confidence: 0.9,
        ),
        LocationAnchor(
          peerDeviceId: 'VALID_3',
          latitude: a3Lat,
          longitude: a3Lon,
          anchorGpsAccuracy: 4.0,
          estimatedDistance: distToTarget(a3Lat, a3Lon),
          distanceUncertainty: 4.0,
          timestamp: now,
          source: LocationSource.wifiRtt,
          confidence: 0.9,
        ),
        LocationAnchor(
          peerDeviceId: 'VALID_4',
          latitude: a4Lat,
          longitude: a4Lon,
          anchorGpsAccuracy: 4.0,
          estimatedDistance: distToTarget(a4Lat, a4Lon),
          distanceUncertainty: 4.0,
          timestamp: now,
          source: LocationSource.wifiRtt,
          confidence: 0.9,
        ),
        LocationAnchor(
          peerDeviceId: 'OUTLIER_CORRUPTED',
          latitude: a5Lat,
          longitude: a5Lon,
          anchorGpsAccuracy: 4.0,
          estimatedDistance: 200.0, // Major outlier
          distanceUncertainty: 4.0,
          timestamp: now,
          source: LocationSource.wifiRtt,
          confidence: 0.9,
        ),
      ];

      final result = engine.estimateLocationWithDiagnostics(anchors, referenceTimeMs: now);

      expect(result.diagnostics.outlierRejectedCount, equals(1));
      expect(result.diagnostics.participatingAnchorCount, equals(4));
      // Location is still resolved accurately despite corrupted anchor
      expect(result.location.latitude, closeTo(targetLat, 0.00005));
      expect(result.location.longitude, closeTo(targetLon, 0.00005));
    });
  });

  group('EncryptedLocationPayload Tests', () {
    test('End-to-end encryption & decryption preserves coordinates and secrecy', () async {
      final secretKey = await EncryptedLocationPayload.deriveKeyFromSecret('RescueKey-9942');

      const originalLocation = EstimatedLocation(
        latitude: 12.971598,
        longitude: 77.594562,
        uncertaintyRadiusMeters: 28.5,
        anchorCount: 4,
        residualError: 3.1,
        confidenceRating: 'High',
        isExactGps: false,
        timestamp: 1727952000000,
      );

      final encrypted = await EncryptedLocationPayload.encrypt(
        location: originalLocation,
        senderDeviceId: 'SR-SENDER-0001',
        recipientDeviceId: 'SR-RESCUE-LEAD',
        secretKeyBytes: secretKey,
        emergencyNotes: 'Trapped under concrete beam in lower basement',
      );

      // Verify privacy guarantee:
      // JSON representation of encrypted payload contains ONLY ciphertext, nonce, mac
      final jsonMap = encrypted.toJson();
      final serializedJson = jsonEncode(jsonMap);

      expect(serializedJson, isNot(contains('12.971598')));
      expect(serializedJson, isNot(contains('77.594562')));
      expect(serializedJson, isNot(contains('Trapped under concrete beam')));

      // Decrypt with correct key
      final decrypted = await encrypted.decrypt(secretKeyBytes: secretKey);

      expect(decrypted.latitude, closeTo(12.971598, 0.00001));
      expect(decrypted.longitude, closeTo(77.594562, 0.00001));
      expect(decrypted.uncertaintyRadiusMeters, closeTo(28.5, 0.01));
      expect(decrypted.anchorCount, equals(4));
      expect(decrypted.confidenceRating, equals('High'));
      expect(decrypted.notes, equals('Trapped under concrete beam in lower basement'));

      // Convert to EstimatedLocation
      final restored = decrypted.toEstimatedLocation();
      expect(restored.displayString, contains('4 GPS anchors'));
    });

    test('Packaging inside MessageEnvelope preserves mesh confidentiality', () async {
      final secretKey = await EncryptedLocationPayload.deriveKeyFromSecret('RescueKey-Mesh-1');

      const location = EstimatedLocation(
        latitude: 13.0827,
        longitude: 80.2707,
        uncertaintyRadiusMeters: 35.0,
        anchorCount: 3,
        residualError: 5.2,
        confidenceRating: 'Medium',
        isExactGps: false,
        timestamp: 1727952100000,
      );

      final payload = await EncryptedLocationPayload.encrypt(
        location: location,
        senderDeviceId: 'SR-USER-A1',
        recipientDeviceId: 'SR-HQ-RESCUE',
        secretKeyBytes: secretKey,
      );

      final envelope = payload.toMessageEnvelope(conversationId: 'CONV_EMERGENCY');

      expect(envelope.type, equals('ENCRYPTED_LOCATION'));
      expect(envelope.recipientTarget, equals('SR-HQ-RESCUE'));

      // Simulate relay packet forwarding:
      // Relay node can read envelope headers but not the coordinates
      expect(envelope.payload, isNot(contains('13.0827')));

      final extractedPayload = EncryptedLocationPayload.fromMessageEnvelope(envelope);
      expect(extractedPayload, isNotNull);

      // Destination decrypts
      final decrypted = await extractedPayload!.decrypt(secretKeyBytes: secretKey);
      expect(decrypted.latitude, closeTo(13.0827, 0.0001));
      expect(decrypted.longitude, closeTo(80.2707, 0.0001));
    });

    test('Decryption with wrong secret key throws authentication failure', () async {
      final keyAlice = await EncryptedLocationPayload.deriveKeyFromSecret('Key-Alice-Secret');
      final keyEve = await EncryptedLocationPayload.deriveKeyFromSecret('Key-Eve-Intruder');

      const location = EstimatedLocation(
        latitude: 12.9716,
        longitude: 77.5946,
        uncertaintyRadiusMeters: 20.0,
        anchorCount: 3,
        residualError: 2.0,
        confidenceRating: 'High',
        isExactGps: true,
        timestamp: 1727952200000,
      );

      final encrypted = await EncryptedLocationPayload.encrypt(
        location: location,
        senderDeviceId: 'SR-USER-A1',
        recipientDeviceId: 'SR-HQ-RESCUE',
        secretKeyBytes: keyAlice,
      );

      // Attempting decryption with Eve's key must fail
      expect(
        () async => await encrypted.decrypt(secretKeyBytes: keyEve),
        throwsA(isA<Exception>()),
      );
    });
  });
}
