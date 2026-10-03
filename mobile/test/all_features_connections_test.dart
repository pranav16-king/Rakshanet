import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rakshanet_mobile/models/chat_message.dart';
import 'package:rakshanet_mobile/models/message_envelope.dart';
import 'package:rakshanet_mobile/models/emergency_report.dart';
import 'package:rakshanet_mobile/models/nearby_device.dart';
import 'package:rakshanet_mobile/models/shelter_resource.dart';
import 'package:rakshanet_mobile/models/missing_person.dart';
import 'package:rakshanet_mobile/services/mesh_engine.dart';
import 'package:rakshanet_mobile/services/chat_service.dart';
import 'package:rakshanet_mobile/services/database_service.dart';
import 'package:rakshanet_mobile/database/app_database.dart';
import 'package:rakshanet_mobile/database/repositories/profile_repository.dart';
import 'package:rakshanet_mobile/database/repositories/report_repository.dart';
import 'package:rakshanet_mobile/database/repositories/device_repository.dart';
import 'package:rakshanet_mobile/providers/profile_provider.dart';
import 'package:rakshanet_mobile/providers/theme_provider.dart';
import 'package:rakshanet_mobile/theme/app_tokens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppDatabase.instance.ensureInitialized();
  });

  group('Comprehensive Features & Connections Integration Test Suite', () {
    // =========================================================================
    // 1. CONNECTION: User Setup & Mandatory Profile Registration Gate
    // =========================================================================
    test('1. Profile Registration Gate: Fresh start blocks access, registration persists to SQLite', () async {
      SharedPreferences.setMockInitialValues({});
      final profileProvider = ProfileProvider();
      await Future.delayed(const Duration(milliseconds: 30));
      await profileProvider.loadProfile();

      // Verify gating: unregistered users cannot access main application shell
      expect(profileProvider.isRegistered, isFalse, reason: 'Fresh install must require profile setup');

      // Complete mandatory registration
      await profileProvider.registerUser(
        name: 'Dr. Anita Roy',
        phone: '+91 9811223344',
        bloodGroup: 'AB+',
        preferredLanguage: 'Hindi',
        medicalNotes: 'First Aid Responder',
      );

      // Verify state unlocked
      expect(profileProvider.isRegistered, isTrue);
      expect(profileProvider.profile.name, equals('Dr. Anita Roy'));
      expect(profileProvider.profile.bloodGroup, equals('AB+'));
      expect(profileProvider.profile.emergencyContact, equals('+91 9811223344'));
      expect(profileProvider.profile.preferredLanguage, equals('Hindi'));
      expect(profileProvider.profile.deviceId.startsWith('SR-'), isTrue,
          reason: 'Must generate pseudonymous device identifier SR-XXXX');

      // Verify ProfileRepository can fetch directly from SQLite
      final profileRepo = ProfileRepository();
      final savedProfile = await profileRepo.getProfile();
      expect(savedProfile, isNotNull);
      expect(savedProfile?.name, equals('Dr. Anita Roy'));
      expect(savedProfile?.bloodGroup, equals('AB+'));
    });

    // =========================================================================
    // 2. CONNECTION: Save-Before-Send Guaranteed Offline Messaging
    // =========================================================================
    test('2. Chat Connection: Save-Before-Send guarantee commits to SQLite before radio emit', () async {
      final chatService = ChatService();
      final testMsg = await chatService.sendMessage(
        content: 'Urgent medical kit needed at Primary School shelter',
        conversationId: 'global_emergency',
      );

      // Message should be saved locally immediately
      expect(testMsg.content, equals('Urgent medical kit needed at Primary School shelter'));
      expect(testMsg.isSaved || testMsg.isSentNearby || testMsg.isQueued, isTrue);

      // Verify persistent record in local SQLite database
      final dbService = DatabaseService();
      final persisted = await dbService.getMessageById(testMsg.messageId);
      expect(persisted, isNotNull, reason: 'Message must exist in SQLite before network broadcast');
      expect(persisted?.content, equals('Urgent medical kit needed at Primary School shelter'));

      // Test status progression to Relayed
      await dbService.updateMessageStatus(
        messageId: testMsg.messageId,
        status: 'RELAYED',
        hopCount: 2,
      );
      final updated = await dbService.getMessageById(testMsg.messageId);
      expect(updated?.isRelayed, isTrue);
      expect(updated?.hopCount, equals(2));
    });

    // =========================================================================
    // 3. CONNECTION: Bloom Filter Deduplication & Loop Suppression
    // =========================================================================
    test('3. Mesh Networking: Deduplication filter silently suppresses broadcast storms', () async {
      final meshEngine = MeshEngine();
      final packetId = 'dedup-test-${DateTime.now().microsecondsSinceEpoch}';

      final packet = MessageEnvelope(
        uuid: packetId,
        senderId: 'SR-ALPHA-01',
        senderName: 'Alpha Responder',
        conversationId: 'global_emergency',
        payload: 'Water level rising 10cm/hr near river bank',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        ttl: 4,
        hops: 1,
      );

      // First reception: successfully processed and forwarded
      final action1 = await meshEngine.receivePacket(packet);
      expect(action1 == RelayAction.forwarded || action1 == RelayAction.deliveredToMe, isTrue);

      // Repeated reception of identical UUID: MUST be dropped immediately
      final action2 = await meshEngine.receivePacket(packet);
      expect(action2, equals(RelayAction.droppedDuplicate),
          reason: 'Duplicate packet must be dropped to prevent routing loops');
    });

    // =========================================================================
    // 4. CONNECTION: 4-Phone Delay-Tolerant Multi-Hop Relay Simulation
    // =========================================================================
    test('4. 4-Phone Multi-Hop Chain: Phone A -> B -> C -> D maintains TTL decay and hop count', () async {
      final meshEngine = MeshEngine();
      final relayMsgId = 'chain-test-${DateTime.now().microsecondsSinceEpoch}';

      final originMessage = ChatMessage(
        messageId: relayMsgId,
        conversationId: 'global_emergency',
        senderId: 'SR-PHONE-A',
        senderName: 'Phone A (Origin/Victim)',
        content: 'SOS: Building collapsed, 3 people trapped in basement',
        timestamp: DateTime.now(),
        status: MessageDeliveryStatus.saved,
        hopCount: 0,
        ttl: 5,
      );

      final chain = await meshEngine.simulateRelay(originMessage, [
        'Phone B (Pedestrian Relay)',
        'Phone C (Shelter Node)',
        'Phone D (Rescue Hub Gateway)',
      ]);

      // Verify complete chain of 4 devices
      expect(chain.length, equals(4));

      // Hop 0 (Phone A)
      expect(chain[0].hopCount, equals(0));
      expect(chain[0].ttl, equals(5));

      // Hop 1 (Phone B)
      expect(chain[1].hopCount, equals(1));
      expect(chain[1].ttl, equals(4));

      // Hop 2 (Phone C)
      expect(chain[2].hopCount, equals(2));
      expect(chain[2].ttl, equals(3));

      // Hop 3 (Phone D - Destination Gateway)
      expect(chain[3].hopCount, equals(3));
      expect(chain[3].ttl, equals(2));
      expect(chain[3].isDelivered, isTrue);
      expect(chain[3].content, equals('SOS: Building collapsed, 3 people trapped in basement'));
    });

    // =========================================================================
    // 5. CONNECTION: TTL Expiration Guard
    // =========================================================================
    test('5. TTL Limit Guard: Packet with TTL <= 1 is stored locally and halted from forward', () async {
      final meshEngine = MeshEngine();
      final expiredPacketId = 'ttl-guard-${DateTime.now().microsecondsSinceEpoch}';

      final envelope = MessageEnvelope(
        uuid: expiredPacketId,
        senderId: 'SR-EXHAUSTED-HOP',
        senderName: 'Distant Node',
        conversationId: 'global_emergency',
        payload: 'Relay packet reaching max hops',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        ttl: 1, // At expiration threshold
        hops: 5,
      );

      final action = await meshEngine.receivePacket(envelope);
      expect(action, equals(RelayAction.storedTtlExpired),
          reason: 'Packet with TTL <= 1 must store locally without radio forward');
    });

    // =========================================================================
    // 6. FEATURE: Emergency Incident Reporting (SOS Beacon) & SQLite Persistence
    // =========================================================================
    test('6. Emergency Report Feature: Creates, categorizes, and persists critical distress incident', () async {
      final reportRepo = ReportRepository();
      final report = EmergencyReport.create(
        id: 'SOS-INCIDENT-001',
        category: 'Trapped',
        peopleCount: 4,
        description: 'Basement entry blocked by collapsed wall',
        status: 'QUEUED',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        latitude: 19.8762,
        longitude: 75.3433,
        severity: 'P1-CRITICAL',
      );

      // Save to SQLite
      await reportRepo.saveReport(report);

      // Verify retrieval
      final saved = await reportRepo.getReportById('SOS-INCIDENT-001');
      expect(saved, isNotNull);
      expect(saved?.id, equals('SOS-INCIDENT-001'));
      expect(saved?.category, equals('Trapped'));
      expect(saved?.peopleCount, equals(4));
      expect(saved?.severity, equals('P1-CRITICAL'));

      // Update status to ACKNOWLEDGED
      await reportRepo.updateReportStatus('SOS-INCIDENT-001', 'ACKNOWLEDGED');
      final updated = await reportRepo.getReportById('SOS-INCIDENT-001');
      expect(updated?.status, equals('ACKNOWLEDGED'));
    });

    // =========================================================================
    // 7. FEATURE: BLE Peer Discovery & Telemetry Connections
    // =========================================================================
    test('7. BLE Peer Connection: RSSI thresholds map accurately to Proximity Bands and SQLite', () async {
      final deviceRepo = DeviceRepository();

      final peer = NearbyDevice(
        deviceId: 'SR-PEER-01',
        displayName: 'Volunteer Phone A',
        connectionType: 'BLE',
        rssi: -55, // Strong signal (< -65 is Immediate)
        proximityBand: NearbyDevice.calculateBand(-55),
        isConnected: true,
        hopCount: 1,
        batteryLevel: 88,
        lastSeen: DateTime.now(),
      );

      await deviceRepo.upsertDevice(peer);

      final retrieved = await deviceRepo.getDeviceById('SR-PEER-01');
      expect(retrieved, isNotNull);
      expect(retrieved?.proximityBand, equals('IMMEDIATE'));
      expect(retrieved?.batteryLevel, equals(88));
      expect(retrieved?.hopCount, equals(1));

      // Test distant device calculation
      expect(NearbyDevice.calculateBand(-72), equals('NEAR'));
      expect(NearbyDevice.calculateBand(-89), equals('FAR'));
    });

    // =========================================================================
    // 8. FEATURE: Shelter & Relief Resource Directory
    // =========================================================================
    test('8. Shelter Resources Feature: Capacity, occupancy percentages, and supply availability', () async {
      final reportRepo = ReportRepository();

      const shelter = ShelterResource(
        id: 'SHELTER-001',
        name: 'Govt Higher Secondary School',
        distance: 0.45,
        openStatus: 'OPEN',
        capacity: 175,
        maxCapacity: 250,
        supplies: ['Food', 'Clean Water', 'Medical Kits'],
        address: 'Sector 4 Main Road',
      );

      await reportRepo.saveShelter(shelter);

      final retrieved = await reportRepo.getShelterById('SHELTER-001');
      expect(retrieved, isNotNull);
      expect(retrieved?.name, equals('Govt Higher Secondary School'));
      expect(retrieved?.capacity, equals(175));
      expect(retrieved?.maxCapacity, equals(250));

      // Occupancy percentage calculation
      final occupancyRate = (retrieved!.capacity / retrieved.maxCapacity) * 100;
      expect(occupancyRate, equals(70.0));
      expect(retrieved.supplies.contains('Food'), isTrue);
      expect(retrieved.supplies.contains('Clean Water'), isTrue);
      expect(retrieved.supplies.contains('Medical Kits'), isTrue);
      expect(retrieved.isOpen, isTrue);
      expect(retrieved.isFull, isFalse);
    });

    // =========================================================================
    // 9. FEATURE: Missing Persons Registry
    // =========================================================================
    test('9. Missing Persons Feature: Record submission, photo path, and status updates', () async {
      final reportRepo = ReportRepository();

      final missingPerson = MissingPerson(
        id: 'MP-2026-001',
        name: 'Rahul Sharma',
        age: 8,
        description: 'Red t-shirt, blue shorts, dark sneakers',
        lastSeenLocation: 'Sector 3 Relief Point',
        lastSeenTime: DateTime.now(),
        photoPath: '/data/user/0/rakshanet/photos/rahul.jpg',
        status: 'SEARCHING',
        contactPhone: '+91 9888776655',
      );

      await reportRepo.saveMissingPerson(missingPerson);

      final list = await reportRepo.getMissingPersons();
      expect(list.any((p) => p.id == 'MP-2026-001'), isTrue);

      final person = list.firstWhere((p) => p.id == 'MP-2026-001');
      expect(person.name, equals('Rahul Sharma'));
      expect(person.age, equals(8));
      expect(person.isFound, isFalse);

      // Update to FOUND
      await reportRepo.updateMissingPersonStatus('MP-2026-001', 'FOUND');
      final updatedList = await reportRepo.getMissingPersons();
      final updatedPerson = updatedList.firstWhere((p) => p.id == 'MP-2026-001');
      expect(updatedPerson.isFound, isTrue);
    });

    // =========================================================================
    // 10. FEATURE: High-Visibility & Low-Power OLED Black Themes
    // =========================================================================
    test('10. Theme Engine Feature: True OLED #000000 Black switches display to zero power draw', () async {
      final themeProvider = ThemeProvider();

      // Default Dark Theme (Night Navy)
      expect(themeProvider.isLowPower, isFalse);
      expect(themeProvider.bg, equals(AppTokens.nightNavy));

      // Switch to OLED Power Saving mode
      await themeProvider.setLowPower(true);
      expect(themeProvider.isLowPower, isTrue);
      expect(themeProvider.bg, equals(AppTokens.oledBg));
      expect(AppTokens.oledBg.toARGB32(), equals(0xFF000000),
          reason: 'OLED theme must be true black #000000 to shut off subpixels');

      // Switch back to Night Navy
      await themeProvider.setLowPower(false);
      expect(themeProvider.isLowPower, isFalse);
      expect(themeProvider.bg, equals(AppTokens.nightNavy));
    });

    // =========================================================================
    // 11. STRICT INTEGRITY: Zero Hardcoded Data & Clean Empty State Handling
    // =========================================================================
    test('11. Zero Hardcoded Data: Non-existent IDs return null rather than mock values', () async {
      final dbService = DatabaseService();
      final nonExistentId = 'nonexistent-uuid-999';

      final result = await dbService.getMessageById(nonExistentId);
      expect(result, isNull, reason: 'Never substitute missing database records with fake mock objects');

      final reportRepo = ReportRepository();
      final nonExistentReport = await reportRepo.getReportById('fake-report-id');
      expect(nonExistentReport, isNull, reason: 'Missing reports must return null');
    });
  });
}
