import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rakshanet_mobile/database/app_database.dart';
import 'package:rakshanet_mobile/database/repositories/missing_person_repository.dart';
import 'package:rakshanet_mobile/models/missing_person.dart';
import 'package:rakshanet_mobile/providers/missing_persons_provider.dart';
import 'package:rakshanet_mobile/providers/theme_provider.dart';
import 'package:rakshanet_mobile/screens/tools/match_found_person_dialog.dart';
import 'package:rakshanet_mobile/services/mesh_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Visual Recognition: Match Found Person & Offline DTN Tests', () {
    test('searchFoundPersonByPhoto buffers query offline when network unavailable', () async {
      final db = AppDatabase.createIsolated();
      final repository = MissingPersonRepository(db);
      final meshEngine = MeshEngine();
      meshEngine.stopTimers();

      final provider = MissingPersonsProvider(
        repository: repository,
        meshEngine: meshEngine,
      );

      // Create a temporary mock photo file
      final tempDir = Directory.systemTemp.createTempSync('photo_test');
      final testPhoto = File('${tempDir.path}/found_person_sample.jpg');
      testPhoto.writeAsBytesSync(List.generate(128, (i) => i % 256));

      // Pre-seed a missing person record
      final samplePerson = MissingPerson(
        id: 'mp_test_001',
        name: 'Aarav Sharma',
        age: 28,
        gender: 'Male',
        description: 'Red jacket, blue jeans',
        lastSeenLocation: 'Sector 4 Shelter',
        photoPath: testPhoto.path,
        contactPhone: '+91 9876543210',
        status: 'MISSING',
      );
      await repository.saveReport(samplePerson);
      await provider.loadReports(silent: true);

      // Search by photo (will run offline DTN path)
      final result = await provider.searchFoundPersonByPhoto(
        testPhoto,
        lat: 19.0760,
        lng: 72.8777,
      );

      expect(result['offline'], isTrue);
      expect(result['queued_for_mesh'], isTrue);
      expect(result['match_found'], isTrue);
      expect(result['top_match'], isNotNull);
      expect(result['top_match']['name'], equals('Aarav Sharma'));

      // Check SQLite table mesh_photo_queries has buffered record
      final pendingQueries = await db.getPendingMeshPhotoQueries();
      expect(pendingQueries.length, greaterThanOrEqualTo(1));
      expect(pendingQueries.first['status'], equals('QUEUED'));
      expect(pendingQueries.first['photo_path'], equals(testPhoto.path));

      // Cleanup
      testPhoto.deleteSync();
      tempDir.deleteSync();
      provider.dispose();
    });

    testWidgets('MatchFoundPersonDialog renders header, buttons, and camera/gallery triggers', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
            ChangeNotifierProvider<MissingPersonsProvider>(create: (_) => MissingPersonsProvider()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MatchFoundPersonDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Visual Recognition: Match Found Person'), findsOneWidget);
      expect(find.text('Capture or Select Found Person Photo'), findsOneWidget);

      // Verify Camera and Gallery buttons
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
    });
  });
}
