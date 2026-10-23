import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rakshanet_mobile/database/app_database.dart';
import 'package:rakshanet_mobile/database/repositories/missing_person_repository.dart';
import 'package:rakshanet_mobile/models/missing_person.dart';
import 'package:rakshanet_mobile/providers/missing_persons_provider.dart';
import 'package:rakshanet_mobile/services/device_identity_service.dart';
import 'package:rakshanet_mobile/services/mesh_engine.dart';
import 'package:rakshanet_mobile/widgets/missing_person_photo_thumbnail.dart';

// Minimal 1x1 transparent PNG in base64
const String kSampleBase64Png =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DeviceIdentityService.instance.initialize();
  });

  group('MissingPersonPhotoThumbnail Unit & Source Detection Tests', () {
    test('detectSourceType identifies file, network, base64, and none sources accurately', () {
      // 1. None / Empty
      expect(MissingPersonPhotoThumbnail.detectSourceType(null), equals(PhotoSourceType.none));
      expect(MissingPersonPhotoThumbnail.detectSourceType(''), equals(PhotoSourceType.none));
      expect(MissingPersonPhotoThumbnail.detectSourceType('   '), equals(PhotoSourceType.none));

      // 2. Network HTTP/HTTPS
      expect(
        MissingPersonPhotoThumbnail.detectSourceType('http://192.168.1.50:8000/media/person1.jpg'),
        equals(PhotoSourceType.network),
      );
      expect(
        MissingPersonPhotoThumbnail.detectSourceType('https://rakshanet.org/photos/missing_01.png'),
        equals(PhotoSourceType.network),
      );

      // 3. Inlined Base64 (Data URI & Raw Base64)
      expect(
        MissingPersonPhotoThumbnail.detectSourceType('data:image/png;base64,$kSampleBase64Png'),
        equals(PhotoSourceType.base64),
      );
      expect(
        MissingPersonPhotoThumbnail.detectSourceType(kSampleBase64Png),
        equals(PhotoSourceType.base64),
      );

      // 4. Local File paths
      expect(
        MissingPersonPhotoThumbnail.detectSourceType('/data/user/0/com.rakshanet.mobile/cache/photo.jpg'),
        equals(PhotoSourceType.file),
      );
      expect(
        MissingPersonPhotoThumbnail.detectSourceType('file:///storage/emulated/0/DCIM/rescue.jpg'),
        equals(PhotoSourceType.file),
      );
      expect(
        MissingPersonPhotoThumbnail.detectSourceType(r'C:\Users\Emergency\Photos\victim.png'),
        equals(PhotoSourceType.file),
      );
      expect(
        MissingPersonPhotoThumbnail.detectSourceType('relative/path/to/image.jpg'),
        equals(PhotoSourceType.file),
      );
    });

    test('decodeBase64Photo decodes data URI and raw base64, and returns null for invalid input', () {
      // Data URI decoding
      final dataUriBytes = MissingPersonPhotoThumbnail.decodeBase64Photo('data:image/png;base64,$kSampleBase64Png');
      expect(dataUriBytes, isNotNull);
      expect(dataUriBytes!.isNotEmpty, isTrue);

      // Raw Base64 decoding
      final rawBytes = MissingPersonPhotoThumbnail.decodeBase64Photo(kSampleBase64Png);
      expect(rawBytes, isNotNull);
      expect(rawBytes!.length, equals(dataUriBytes.length));

      // Null, empty, and corrupt inputs return null safely
      expect(MissingPersonPhotoThumbnail.decodeBase64Photo(null), isNull);
      expect(MissingPersonPhotoThumbnail.decodeBase64Photo(''), isNull);
      expect(MissingPersonPhotoThumbnail.decodeBase64Photo('not-a-valid-base64!@#%'), isNull);
    });
  });

  group('MissingPersonPhotoThumbnail Widget Tests', () {
    testWidgets('Renders fallback initial when photo is null or empty', (WidgetTester tester) async {
      final personNoPhoto = MissingPerson(
        id: 'mp_fallback_01',
        name: 'Rahul Sen',
        age: 34,
        gender: 'Male',
        description: 'Blue shirt, dark trousers',
        lastSeenLocation: 'Sector 5 Camp',
        status: 'MISSING',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MissingPersonPhotoThumbnail(
              person: personNoPhoto,
              size: 56.0,
            ),
          ),
        ),
      );
      await tester.pump();

      // Fallback initial "R" should be rendered
      expect(find.text('R'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('Renders MemoryImage when photo is provided as inlined base64 data URI', (WidgetTester tester) async {
      final personBase64 = MissingPerson(
        id: 'mp_base64_01',
        name: 'Priya Sharma',
        age: 26,
        gender: 'Female',
        description: 'Red jacket, silver earrings',
        photoPath: 'data:image/png;base64,$kSampleBase64Png',
        lastSeenLocation: 'Red Cross Shelter 2',
        status: 'MISSING',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MissingPersonPhotoThumbnail(
              person: personBase64,
              size: 64.0,
            ),
          ),
        ),
      );
      await tester.pump();

      // MemoryImage should be rendered
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('P'), findsNothing);
    });

    testWidgets('Renders FileImage when valid file exists on disk', (WidgetTester tester) async {
      final tempDir = Directory.systemTemp.createTempSync('photo_widget_test');
      final sampleImageFile = File('${tempDir.path}/test_person.png');
      sampleImageFile.writeAsBytesSync(base64Decode(kSampleBase64Png));

      final personWithFile = MissingPerson(
        id: 'mp_file_01',
        name: 'Deepak Patel',
        age: 41,
        gender: 'Male',
        description: 'Striped shirt, glasses',
        photoPath: sampleImageFile.path,
        lastSeenLocation: 'Relief Post B',
        status: 'MISSING',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MissingPersonPhotoThumbnail(
              person: personWithFile,
              size: 64.0,
            ),
          ),
        ),
      );
      await tester.pump();

      // FileImage should be rendered
      expect(find.byType(Image), findsOneWidget);

      sampleImageFile.deleteSync();
      tempDir.deleteSync();
    });

    testWidgets('Tapping thumbnail opens full-screen photo detail dialog with person details', (WidgetTester tester) async {
      final person = MissingPerson(
        id: 'mp_dialog_01',
        name: 'Sunita Mehra',
        age: 30,
        gender: 'Female',
        description: 'Floral scarf, black coat',
        photoPath: 'data:image/png;base64,$kSampleBase64Png',
        lastSeenLocation: 'Community Hall 1',
        status: 'MISSING',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MissingPersonPhotoThumbnail(
              person: person,
              size: 64.0,
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap on thumbnail
      await tester.tap(find.byType(MissingPersonPhotoThumbnail));
      await tester.pumpAndSettle();

      // Verify dialog is opened with full person info and close button
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Sunita Mehra'), findsOneWidget);
      expect(find.textContaining('30 yrs • Female • MISSING'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Close dialog
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    });
  });

  group('MissingPersonsProvider Search By Photo Provider Logic Tests', () {
    test('searchFoundPersonByPhoto offline path queues DTN packet and finds local match', () async {
      final db = AppDatabase.createIsolated();
      final repository = MissingPersonRepository(db);
      final meshEngine = MeshEngine();
      meshEngine.stopTimers();

      final provider = MissingPersonsProvider(
        repository: repository,
        meshEngine: meshEngine,
      );

      final tempDir = Directory.systemTemp.createTempSync('photo_provider_test');
      final queryPhoto = File('${tempDir.path}/query_person.jpg');
      queryPhoto.writeAsBytesSync(base64Decode(kSampleBase64Png));

      // Seed missing person in repository with same photo path
      final seededPerson = MissingPerson(
        id: 'mp_seeded_001',
        name: 'Kavita Roy',
        age: 22,
        gender: 'Female',
        description: 'Green dress, silver watch',
        lastSeenLocation: 'Station Road',
        photoPath: queryPhoto.path,
        contactPhone: '+91 9123456789',
        status: 'MISSING',
      );
      await repository.saveReport(seededPerson);
      await provider.loadReports(silent: true);

      // Execute photo search in offline environment
      final searchResult = await provider.searchFoundPersonByPhoto(
        queryPhoto,
        lat: 12.9716,
        lng: 77.5946,
      );

      // Assert result structure
      expect(searchResult['offline'], isTrue);
      expect(searchResult['queued_for_mesh'], isTrue);
      expect(searchResult['match_found'], isTrue);
      expect(searchResult['top_match'], isNotNull);
      expect(searchResult['top_match']['name'], equals('Kavita Roy'));

      // Verify buffered entry in SQLite mesh_photo_queries table
      final pendingQueries = await db.getPendingMeshPhotoQueries();
      expect(pendingQueries.length, greaterThanOrEqualTo(1));
      final queryRow = pendingQueries.first;
      expect(queryRow['status'], equals('QUEUED'));
      expect(queryRow['photo_path'], equals(queryPhoto.path));
      expect(queryRow['latitude'], equals(12.9716));
      expect(queryRow['longitude'], equals(77.5946));

      // Cleanup
      queryPhoto.deleteSync();
      tempDir.deleteSync();
      provider.dispose();
    });

    test('searchFoundPersonByPhoto with non-matching photo still queues DTN packet and reports no local match', () async {
      final db = AppDatabase.createIsolated();
      final repository = MissingPersonRepository(db);
      final meshEngine = MeshEngine();
      meshEngine.stopTimers();

      final provider = MissingPersonsProvider(
        repository: repository,
        meshEngine: meshEngine,
      );

      final tempDir = Directory.systemTemp.createTempSync('photo_no_match_test');
      final queryPhoto = File('${tempDir.path}/unmatched_face.jpg');
      queryPhoto.writeAsBytesSync(base64Decode(kSampleBase64Png));

      // Seed missing person with different non-matching path
      final existingPerson = MissingPerson(
        id: 'mp_other_002',
        name: 'Anil Kumar',
        age: 50,
        gender: 'Male',
        description: 'Grey shirt',
        lastSeenLocation: 'Park Plaza',
        photoPath: '/different/path/other.jpg',
        status: 'MISSING',
      );
      await repository.saveReport(existingPerson);
      await provider.loadReports(silent: true);

      final result = await provider.searchFoundPersonByPhoto(
        queryPhoto,
        lat: 28.6139,
        lng: 77.2090,
      );

      expect(result['offline'], isTrue);
      expect(result['queued_for_mesh'], isTrue);
      expect(result['match_found'], isFalse);
      expect(result['top_match'], isNull);

      // Verify buffered in SQLite mesh_photo_queries
      final pendingQueries = await db.getPendingMeshPhotoQueries();
      expect(pendingQueries.any((q) => q['photo_path'] == queryPhoto.path), isTrue);

      // Cleanup
      queryPhoto.deleteSync();
      tempDir.deleteSync();
      provider.dispose();
    });
  });
}
