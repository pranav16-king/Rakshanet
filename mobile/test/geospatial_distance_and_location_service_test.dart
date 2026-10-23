import 'package:flutter_test/flutter_test.dart';
import 'package:rakshanet_mobile/services/location/location_service.dart';
import 'package:rakshanet_mobile/utils/haversine_distance.dart';

void main() {
  group('Haversine Distance & GeospatialDistanceResult Tests', () {
    const lat1 = 13.0827; // Chennai Central
    const lng1 = 80.2707;
    const lat2 = 13.0878; // ~600m away
    const lng2 = 80.2785;

    test('calculateDistance implements Haversine with R=6371000m accurately', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final result = calculateDistance(
        lat1: lat1,
        lng1: lng1,
        accuracy1: 8.0,
        timestamp1: now - 5000, // 5s ago (fresh)
        lat2: lat2,
        lng2: lng2,
        accuracy2: 12.0,
        timestamp2: now - 8000, // 8s ago (fresh)
      );

      expect(result.isCoordinatesAvailable, isTrue);
      expect(result.distanceMeters, isNotNull);
      // Expected distance is ~1010 meters
      expect(result.distanceMeters!, greaterThan(900.0));
      expect(result.distanceMeters!, lessThan(1200.0));

      // Uncertainty should be 8.0 + 12.0 = 20.0m
      expect(result.uncertaintyMeters, equals(20.0));
      expect(result.uncertaintyFormatted, equals('± 20 m'));

      // Straight line flag
      expect(result.isStraightLine, isTrue);

      // Freshness: both within 60s -> LIVE
      expect(result.freshnessStatus, equals(GeospatialFreshness.live));

      // Summary label format
      expect(result.summaryLabel, contains('± 20 m • Straight-line'));
    });

    test('calculateDistance correctly labels distanceFormatted in meters vs kilometers', () {
      final now = DateTime.now().millisecondsSinceEpoch;

      // Close points (~100m)
      final closeResult = calculateDistance(
        lat1: 13.0000,
        lng1: 80.0000,
        accuracy1: 5.0,
        timestamp1: now,
        lat2: 13.0005,
        lng2: 80.0005,
        accuracy2: 5.0,
        timestamp2: now,
      );
      expect(closeResult.distanceFormatted, endsWith('m'));
      expect(closeResult.distanceFormatted, isNot(contains('km')));

      // Far points (~240 km)
      final farResult = calculateDistance(
        lat1: 13.0827,
        lng1: 80.2707, // Chennai
        accuracy1: 15.0,
        timestamp1: now,
        lat2: 12.9716,
        lng2: 77.5946, // Bangalore (~290 km)
        accuracy2: 15.0,
        timestamp2: now,
      );
      expect(farResult.distanceFormatted, endsWith('km'));
      expect(farResult.distanceMeters!, greaterThan(250000));
    });

    test('calculateDistance marks STALE when fix is older than 60 seconds', () {
      final now = DateTime.now().millisecondsSinceEpoch;

      final staleResult = calculateDistance(
        lat1: lat1,
        lng1: lng1,
        accuracy1: 10.0,
        timestamp1: now - 65000, // 65 seconds ago (> 60s)
        lat2: lat2,
        lng2: lng2,
        accuracy2: 10.0,
        timestamp2: now,
      );

      expect(staleResult.freshnessStatus, equals(GeospatialFreshness.stale));
    });

    test('calculateDistance marks UNKNOWN when timestamp is missing or zero', () {
      final unknownResult = calculateDistance(
        lat1: lat1,
        lng1: lng1,
        accuracy1: 10.0,
        timestamp1: 0,
        lat2: lat2,
        lng2: lng2,
        accuracy2: 10.0,
        timestamp2: 0,
      );

      expect(unknownResult.freshnessStatus, equals(GeospatialFreshness.unknown));
    });

    test('Fallback prompts Bluetooth RSSI when remote coordinates are null', () {
      final fallbackResult = HaversineDistance.calculateDistanceNullable(
        lat1: lat1,
        lng1: lng1,
        accuracy1: 10.0,
        timestamp1: DateTime.now().millisecondsSinceEpoch,
        lat2: null,
        lng2: null,
        accuracy2: null,
        timestamp2: null,
      );

      expect(fallbackResult.isCoordinatesAvailable, isFalse);
      expect(fallbackResult.isStraightLine, isTrue);
      expect(fallbackResult.freshnessStatus, equals(GeospatialFreshness.unknown));
      expect(fallbackResult.fallbackPrompt, contains('Bluetooth RSSI proximity estimation'));
      expect(fallbackResult.summaryLabel, contains('Coordinates unavailable • Use BLE RSSI proximity'));
    });

    test('Fallback supports BLE RSSI distance and uncertainty when provided', () {
      final bleFallbackResult = HaversineDistance.calculateDistanceNullable(
        lat1: lat1,
        lng1: lng1,
        lat2: null,
        lng2: null,
        bleRssiDistanceMeters: 14.5,
        bleRssiUncertaintyMeters: 18.0,
      );

      expect(bleFallbackResult.isCoordinatesAvailable, isFalse);
      expect(bleFallbackResult.distanceMeters, equals(14.5));
      expect(bleFallbackResult.uncertaintyMeters, equals(18.0));
      expect(bleFallbackResult.summaryLabel, contains('15 m ± 18 m • BLE Proximity (Straight-line)'));
    });
  });

  group('DeviceLocationFix & LocationService Priority Tests', () {
    test('DeviceLocationFix sets isLive and isStale correctly based on 60s age', () {
      final now = DateTime.now().millisecondsSinceEpoch;

      final liveFix = DeviceLocationFix.create(
        latitude: 13.0827,
        longitude: 80.2707,
        horizontalAccuracyMeters: 8.5,
        timestamp: now - 15000, // 15s ago
        source: LocationFixSource.hardwareGps,
      );

      expect(liveFix.isLive, isTrue);
      expect(liveFix.isStale, isFalse);
      expect(liveFix.source, equals(LocationFixSource.hardwareGps));
      expect(liveFix.formattedCoordinates, contains('13.0827° N, 80.2707° E'));
      expect(liveFix.formattedAccuracy, equals('± 9 m'));

      final staleFix = DeviceLocationFix.create(
        latitude: 13.0827,
        longitude: 80.2707,
        horizontalAccuracyMeters: 15.0,
        timestamp: now - 75000, // 75s ago
        source: LocationFixSource.fusedGps,
      );

      expect(staleFix.isLive, isFalse);
      expect(staleFix.isStale, isTrue);
      expect(staleFix.source, equals(LocationFixSource.lastKnown));
    });

    test('Android Location Notification Config matches foreground service compliance', () {
      const config = AndroidLocationNotificationConfig();

      expect(config.channelId, equals('rakshanet_location_tracking'));
      expect(config.channelName, equals('Emergency Location Tracking'));
      expect(config.title, contains('RakshaNet'));

      final map = config.toMap();
      expect(map['channelId'], equals('rakshanet_location_tracking'));
      expect(map['title'], isNotEmpty);
      expect(map['text'], isNotEmpty);
    });

    test('Peer multilateration fix can be created and structured as expected', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final fix = DeviceLocationFix.create(
        latitude: 12.9200,
        longitude: 80.1200,
        horizontalAccuracyMeters: 28.0,
        timestamp: now - 2000,
        source: LocationFixSource.peerMultilateration,
      );

      expect(fix.source, equals(LocationFixSource.peerMultilateration));
      expect(fix.isLive, isTrue);
      expect(fix.isStale, isFalse);
    });
  });
}
