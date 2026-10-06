import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:rakshanet_mobile/services/map/offline_map_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineMapService Tests', () {
    test('1. Geodetic Distance Calculation (Haversine)', () {
      // New Delhi (28.6139, 77.2090) to Mumbai (19.0760, 72.8777) ~1150 km
      const delhi = LatLng(28.6139, 77.2090);
      const mumbai = LatLng(19.0760, 72.8777);

      final distanceMeters = OfflineMapService.distanceMeters(delhi, mumbai);
      final distanceKm = distanceMeters / 1000.0;

      expect(distanceKm, greaterThan(1100));
      expect(distanceKm, lessThan(1200));
      print('Distance Delhi to Mumbai: ${distanceKm.toStringAsFixed(1)} km');
    });

    test('2. Compass Bearing and Cardinal Direction', () {
      const p1 = LatLng(20.0, 78.0);
      const pNorth = LatLng(21.0, 78.0);
      const pEast = LatLng(20.0, 79.0);

      final bearingNorth = OfflineMapService.bearingDegrees(p1, pNorth);
      final bearingEast = OfflineMapService.bearingDegrees(p1, pEast);

      expect(bearingNorth, closeTo(0.0, 1.0));
      expect(OfflineMapService.cardinalDirection(bearingNorth), 'N');

      expect(bearingEast, closeTo(90.0, 2.0));
      expect(OfflineMapService.cardinalDirection(bearingEast), 'E');
      print('Bearings: North = $bearingNorth°, East = $bearingEast°');
    });

    test('3. Distance String Formatting', () {
      expect(OfflineMapService.formatDistance(450.0), '450 m');
      expect(OfflineMapService.formatDistance(1200.0), '1.2 km');
      expect(OfflineMapService.formatDistance(15800.0), '15.8 km');
      print('Format distance tests passed.');
    });

    test('4. Tactical Grid Fallback PNG Tile Generation', () async {
      final darkGridBytes = await OfflineMapService.instance.getTacticalGridTileBytes(isDark: true);
      final lightGridBytes = await OfflineMapService.instance.getTacticalGridTileBytes(isDark: false);

      expect(darkGridBytes.isNotEmpty, isTrue);
      expect(lightGridBytes.isNotEmpty, isTrue);
      // Valid PNG header starts with 0x89, 'P', 'N', 'G'
      expect(darkGridBytes[0], 0x89);
      expect(darkGridBytes[1], 0x50); // 'P'
      expect(darkGridBytes[2], 0x4E); // 'N'
      expect(darkGridBytes[3], 0x47); // 'G'
      print('Tactical Grid Tile Generation Passed: ${darkGridBytes.length} bytes PNG');
    });
  });
}
