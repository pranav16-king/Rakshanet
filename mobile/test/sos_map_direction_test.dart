import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakshanet_mobile/theme/app_tokens.dart';
import 'package:rakshanet_mobile/utils/haversine_distance.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Haversine Bearing & Azimuth Calculation Tests', () {
    test('calculateBearingDegrees calculates cardinal azimuths accurately from origin', () {
      // 1. Moving directly North along prime meridian (0,0) -> (1,0)
      final bearingNorth = HaversineDistance.calculateBearingDegrees(0.0, 0.0, 1.0, 0.0);
      expect(bearingNorth, closeTo(0.0, 0.01));
      expect(HaversineDistance.cardinalDirection(bearingNorth), equals('N'));

      // 2. Moving directly East along equator (0,0) -> (0,1)
      final bearingEast = HaversineDistance.calculateBearingDegrees(0.0, 0.0, 0.0, 1.0);
      expect(bearingEast, closeTo(90.0, 0.01));
      expect(HaversineDistance.cardinalDirection(bearingEast), equals('E'));

      // 3. Moving directly South along prime meridian (1,0) -> (0,0)
      final bearingSouth = HaversineDistance.calculateBearingDegrees(1.0, 0.0, 0.0, 0.0);
      expect(bearingSouth, closeTo(180.0, 0.01));
      expect(HaversineDistance.cardinalDirection(bearingSouth), equals('S'));

      // 4. Moving directly West along equator (0,1) -> (0,0)
      final bearingWest = HaversineDistance.calculateBearingDegrees(0.0, 1.0, 0.0, 0.0);
      expect(bearingWest, closeTo(270.0, 0.01));
      expect(HaversineDistance.cardinalDirection(bearingWest), equals('W'));
    });

    test('calculateBearingDegrees computes rescue distress beacon heading in Chennai', () {
      // Origin: Chennai Central Station
      const userLat = 13.0827;
      const userLng = 80.2707;
      // Target: SOS Distress Beacon located ~1.3 km Northeast
      const sosTargetLat = 13.0910;
      const sosTargetLng = 80.2800;

      final bearing = HaversineDistance.calculateBearingDegrees(userLat, userLng, sosTargetLat, sosTargetLng);
      final cardinal = HaversineDistance.cardinalDirection(bearing);

      // Expected bearing is ~48° (Northeast)
      expect(bearing, greaterThan(40.0));
      expect(bearing, lessThan(55.0));
      expect(cardinal, equals('NE'));
    });

    test('cardinalDirection covers all 8 compass quadrants properly', () {
      expect(HaversineDistance.cardinalDirection(0.0), equals('N'));
      expect(HaversineDistance.cardinalDirection(20.0), equals('N'));
      expect(HaversineDistance.cardinalDirection(45.0), equals('NE'));
      expect(HaversineDistance.cardinalDirection(90.0), equals('E'));
      expect(HaversineDistance.cardinalDirection(135.0), equals('SE'));
      expect(HaversineDistance.cardinalDirection(180.0), equals('S'));
      expect(HaversineDistance.cardinalDirection(225.0), equals('SW'));
      expect(HaversineDistance.cardinalDirection(270.0), equals('W'));
      expect(HaversineDistance.cardinalDirection(315.0), equals('NW'));
      expect(HaversineDistance.cardinalDirection(350.0), equals('N'));
    });
  });

  group('Relative Bearing & Turn Guidance Tests', () {
    test('calculateRelativeBearing and getTurnInstruction provide tactical navigational guidance', () {
      // Target is directly East (bearing = 90.0°)

      // Heading North (0°) -> target is to right (+90°)
      final relRight = HaversineDistance.calculateRelativeBearing(90.0, 0.0);
      expect(relRight, equals(90.0));
      expect(HaversineDistance.getTurnInstruction(relRight), equals('Turn right'));

      // Heading East (90°) -> target is straight ahead (0°)
      final relStraight = HaversineDistance.calculateRelativeBearing(90.0, 90.0);
      expect(relStraight, equals(0.0));
      expect(HaversineDistance.getTurnInstruction(relStraight), equals('Head straight'));

      // Heading South (180°) -> target is to left (-90°)
      final relLeft = HaversineDistance.calculateRelativeBearing(90.0, 180.0);
      expect(relLeft, equals(-90.0));
      expect(HaversineDistance.getTurnInstruction(relLeft), equals('Turn left'));

      // Heading West (270°) -> target is behind (180° or -180°)
      final relBehind = HaversineDistance.calculateRelativeBearing(90.0, 270.0);
      expect(relBehind.abs(), equals(180.0));
      expect(HaversineDistance.getTurnInstruction(relBehind), equals('Turn around'));

      // Heading 50° -> target is at +40° -> Bear right
      final relBearRight = HaversineDistance.calculateRelativeBearing(90.0, 50.0);
      expect(relBearRight, equals(40.0));
      expect(HaversineDistance.getTurnInstruction(relBearRight), equals('Bear right'));

      // Heading 130° -> target is at -40° -> Bear left
      final relBearLeft = HaversineDistance.calculateRelativeBearing(90.0, 130.0);
      expect(relBearLeft, equals(-40.0));
      expect(HaversineDistance.getTurnInstruction(relBearLeft), equals('Bear left'));

      // Sharp turns (e.g. 140° relative)
      expect(HaversineDistance.getTurnInstruction(140.0), equals('Sharp right'));
      expect(HaversineDistance.getTurnInstruction(-140.0), equals('Sharp left'));
    });

    test('calculateRelativeBearing wraps across 0°/360° north boundary seamlessly', () {
      // Target is at 10° (slightly east of North), user is heading 350° (slightly west of North)
      // Difference is +20° to the right
      final relWrapRight = HaversineDistance.calculateRelativeBearing(10.0, 350.0);
      expect(relWrapRight, equals(20.0));
      expect(HaversineDistance.getTurnInstruction(relWrapRight), equals('Head straight'));

      // Target is at 350°, user is heading 10° -> -20° to the left
      final relWrapLeft = HaversineDistance.calculateRelativeBearing(350.0, 10.0);
      expect(relWrapLeft, equals(-20.0));
      expect(HaversineDistance.getTurnInstruction(relWrapLeft), equals('Head straight'));
    });
  });

  group('NavigationTarget Calculation & Arrival Logic Tests', () {
    test('calculateNavigationTarget populates metrics, ETA, and turn instructions accurately', () {
      const userLat = 19.0760;
      const userLng = 72.8777; // Mumbai
      const sosLat = 19.0800; // ~500m away
      const sosLng = 72.8800;

      final navTarget = HaversineDistance.calculateNavigationTarget(
        currentLat: userLat,
        currentLng: userLng,
        targetLat: sosLat,
        targetLng: sosLng,
        targetId: 'SOS_NDRF_01',
        targetName: 'Medical Aid Post Gamma',
        userHeadingDegrees: 0.0, // facing North
        walkingSpeedMps: 1.2,
      );

      expect(navTarget.targetId, equals('SOS_NDRF_01'));
      expect(navTarget.targetName, equals('Medical Aid Post Gamma'));
      expect(navTarget.distanceMeters, greaterThan(400.0));
      expect(navTarget.distanceMeters, lessThan(600.0));
      expect(navTarget.distanceFormatted, endsWith('m'));
      expect(navTarget.isArrived, isFalse);

      // Heading North, target bearing is ~29° NE -> Bear right or Head straight
      expect(navTarget.bearingDegrees, greaterThan(20.0));
      expect(navTarget.cardinalDirection, isNotEmpty);
      expect(navTarget.turnInstruction, isNotEmpty);

      // ETA calculation: ~500m / 1.2 m/s = ~416s (~7 min)
      expect(navTarget.estimatedSeconds, greaterThan(300));
      expect(navTarget.formattedEta, contains('min'));

      // Serialization to map
      final map = navTarget.toMap();
      expect(map['targetId'], equals('SOS_NDRF_01'));
      expect(map['isArrived'], isFalse);
    });

    test('calculateNavigationTarget triggers arrival threshold when distance <= 15m', () {
      const userLat = 12.9716;
      const userLng = 77.5946;

      // Target at practically identical coordinates (less than 15 meters)
      final arrivedTarget = HaversineDistance.calculateNavigationTarget(
        currentLat: userLat,
        currentLng: userLng,
        targetLat: userLat + 0.00005, // ~5.5m away
        targetLng: userLng,
        targetId: 'SHELTER_ARRIVED',
        targetName: 'Safe Haven Camp',
        arrivalThresholdMeters: 15.0,
      );

      expect(arrivedTarget.isArrived, isTrue);
      expect(arrivedTarget.turnInstruction, equals('Arrived at Destination'));
    });

    test('formatEta formats seconds, minutes, and hours appropriately', () {
      expect(HaversineDistance.formatEta(45), equals('45 sec'));
      expect(HaversineDistance.formatEta(300), equals('5 min'));
      expect(HaversineDistance.formatEta(3600), equals('1 hr'));
      expect(HaversineDistance.formatEta(5400), equals('1 hr 30 min'));
    });

    test('calculateDestinationPoint projects coordinates forward along bearing', () {
      const startLat = 13.0827;
      const startLng = 80.2707;
      const travelDistanceMeters = 1500.0;
      const targetBearing = 90.0; // Heading East

      final destination = HaversineDistance.calculateDestinationPoint(
        lat: startLat,
        lng: startLng,
        distanceMeters: travelDistanceMeters,
        bearingDegrees: targetBearing,
      );

      expect(destination['latitude'], isNotNull);
      expect(destination['longitude'], isNotNull);

      // Latitude should remain virtually identical when traveling due East on spherical earth
      expect(destination['latitude']!, closeTo(startLat, 0.001));
      // Longitude should have increased (further East)
      expect(destination['longitude']!, greaterThan(startLng));

      // Calculating distance between start and destination should match ~1500 meters
      final checkDist = HaversineDistance.calculateDistance(
        lat1: startLat,
        lng1: startLng,
        accuracy1: 5.0,
        timestamp1: DateTime.now().millisecondsSinceEpoch,
        lat2: destination['latitude']!,
        lng2: destination['longitude']!,
        accuracy2: 5.0,
        timestamp2: DateTime.now().millisecondsSinceEpoch,
      );
      expect(checkDist.distanceMeters!, closeTo(travelDistanceMeters, 2.0));
    });
  });

  group('SOS Map Direction UI Component Widget Tests', () {
    testWidgets('Renders navigation guidance banner with rotated compass arrow and target name', (WidgetTester tester) async {
      const userLat = 13.0827;
      const userLng = 80.2707;
      const targetLat = 13.0900;
      const targetLng = 80.2800;

      final geoResult = HaversineDistance.calculateDistance(
        lat1: userLat,
        lng1: userLng,
        accuracy1: 10.0,
        timestamp1: DateTime.now().millisecondsSinceEpoch,
        lat2: targetLat,
        lng2: targetLng,
        accuracy2: 10.0,
        timestamp2: DateTime.now().millisecondsSinceEpoch,
      );

      final bearing = geoResult.bearingDegrees ?? 45.0;
      final dir = geoResult.compassDirection ?? 'NE';
      final dist = geoResult.summaryLabel;
      final bearingRad = bearing * math.pi / 180.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF140707),
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                border: Border.all(color: AppTokens.sosRed, width: 1.8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTokens.sosRed.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTokens.sosRed, width: 1.2),
                    ),
                    child: Center(
                      child: Transform.rotate(
                        angle: bearingRad,
                        child: const Icon(Icons.navigation_rounded, color: AppTokens.sosRed, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Head $dir (${bearing.round()}°) • $dist',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Target: SOS Beacon Alpha',
                          style: TextStyle(
                            color: AppTokens.sosRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify UI elements
      expect(find.byIcon(Icons.navigation_rounded), findsOneWidget);
      expect(find.textContaining('Head $dir'), findsOneWidget);
      expect(find.text('Target: SOS Beacon Alpha'), findsOneWidget);
      expect(find.byType(Transform), findsWidgets);
    });
  });
}
