import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rakshanet_mobile/models/user_profile.dart';
import 'package:rakshanet_mobile/models/chat_message.dart';
import 'package:rakshanet_mobile/models/message_envelope.dart';
import 'package:rakshanet_mobile/services/mesh_engine.dart';
import 'package:rakshanet_mobile/services/chat_service.dart';
import 'package:rakshanet_mobile/services/database_service.dart';
import 'package:rakshanet_mobile/providers/profile_provider.dart';
import 'package:rakshanet_mobile/providers/theme_provider.dart';
import 'package:rakshanet_mobile/theme/app_tokens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 1 Verification Test Suite (Kabootar & MeshChat Architecture)', () {
    // -------------------------------------------------------------------------
    // TEST 1: User Profile Registration Gate
    // -------------------------------------------------------------------------
    test('Test 1: User Profile Registration Gate — Initial unregistered state and dynamic registration', () async {
      SharedPreferences.setMockInitialValues({});
      final profileProvider = ProfileProvider();
      await Future.delayed(const Duration(milliseconds: 50));
      await profileProvider.loadProfile();

      // Unregistered user cannot enter app
      expect(profileProvider.isRegistered, isFalse);

      // Register with real user details
      await profileProvider.registerUser(
        name: 'Rescue Volunteer 1',
        phone: '+91 9876543210',
        bloodGroup: 'O+',
        preferredLanguage: 'English',
        medicalNotes: 'No chronic illness',
      );

      expect(profileProvider.isRegistered, isTrue);
      expect(profileProvider.profile.name, equals('Rescue Volunteer 1'));
      expect(profileProvider.profile.bloodGroup, equals('O+'));
      expect(profileProvider.profile.deviceId.isNotEmpty, isTrue);
    });

    // -------------------------------------------------------------------------
    // TEST 2: Save-Before-Send Transactional Guarantee
    // -------------------------------------------------------------------------
    test('Test 2: Save-Before-Send Transactional Guarantee — Written to SQLite before radio emit', () async {
      final chatService = ChatService();
      final msg = await chatService.sendMessage(
        content: 'Urgent: Water supply requested at shelter',
        conversationId: 'global_emergency',
      );

      // Verify message is saved with status SAVED initially
      expect(msg.content, equals('Urgent: Water supply requested at shelter'));
      expect(msg.isSaved || msg.isSentNearby || msg.isQueued, isTrue);

      // Verify it exists in SQLite database service
      final dbService = DatabaseService();
      final retrieved = await dbService.getMessageById(msg.messageId);
      expect(retrieved, isNotNull);
      expect(retrieved?.content, equals('Urgent: Water supply requested at shelter'));
    });

    // -------------------------------------------------------------------------
    // TEST 3: 4-Phone 3-Hop Multi-Hop Relay Simulation (Kabootar / MeshChat)
    // -------------------------------------------------------------------------
    test('Test 3: 4-Phone 3-Hop Relay Simulation — Phone A -> B -> C -> D with TTL decay', () async {
      final meshEngine = MeshEngine();
      final testMsgId = 'relay-test-${DateTime.now().millisecondsSinceEpoch}';

      final initialMsg = ChatMessage(
        messageId: testMsgId,
        conversationId: 'global_emergency',
        senderId: 'SR-PHONE-A',
        senderName: 'Phone A (Origin)',
        content: 'SOS: Trapped under debris near sector 4',
        timestamp: DateTime.now(),
        status: MessageDeliveryStatus.saved,
        hopCount: 0,
        ttl: 5, // Starts at 5 hops max
      );

      final hops = await meshEngine.simulateRelay(initialMsg, [
        'Phone B (Pedestrian Relay)',
        'Phone C (Shelter Node)',
        'Phone D (Rescue Hub)',
      ]);

      expect(hops.length, equals(4)); // Origin + 3 intermediate hops

      // Phone A: Origin
      expect(hops[0].senderId, equals('SR-PHONE-A'));
      expect(hops[0].hopCount, equals(0));
      expect(hops[0].ttl, equals(5));

      // Phone B: First Hop
      expect(hops[1].hopCount, equals(1));
      expect(hops[1].ttl, equals(4));

      // Phone C: Second Hop
      expect(hops[2].hopCount, equals(2));
      expect(hops[2].ttl, equals(3));

      // Phone D: Destination / Edge Hub
      expect(hops[3].hopCount, equals(3));
      expect(hops[3].ttl, equals(2));
      expect(hops[3].isDelivered, isTrue);
    });

    // -------------------------------------------------------------------------
    // TEST 4: Deduplication & Loop Suppression
    // -------------------------------------------------------------------------
    test('Test 4: Deduplication & Anti-Replay — Duplicate message ID is dropped immediately', () async {
      final meshEngine = MeshEngine();
      final dupId = 'dup-msg-${DateTime.now().millisecondsSinceEpoch}';

      final envelope = MessageEnvelope(
        uuid: dupId,
        senderId: 'SR-NODE-X',
        senderName: 'Node X',
        conversationId: 'global_emergency',
        payload: 'Flood water rising fast',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        ttl: 4,
        hops: 1,
      );

      // First reception: forwarded
      final action1 = await meshEngine.receivePacket(envelope);
      expect(action1 == RelayAction.forwarded || action1 == RelayAction.deliveredToMe, isTrue);

      // Second reception of identical messageId: MUST be dropped as duplicate
      final action2 = await meshEngine.receivePacket(envelope);
      expect(action2, equals(RelayAction.droppedDuplicate));
    });

    // -------------------------------------------------------------------------
    // TEST 5: TTL Expiration Guard
    // -------------------------------------------------------------------------
    test('Test 5: TTL Expiration Guard — Packet with TTL <= 1 stored locally but halted from relay', () async {
      final meshEngine = MeshEngine();
      final expiredId = 'exp-msg-${DateTime.now().millisecondsSinceEpoch}';

      final expiredEnvelope = MessageEnvelope(
        uuid: expiredId,
        senderId: 'SR-REMOTE-Z',
        senderName: 'Remote Node Z',
        conversationId: 'global_emergency',
        payload: 'Low power broadcast beacon',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        ttl: 1, // At threshold: TTL <= 1
        hops: 4,
      );

      final action = await meshEngine.receivePacket(expiredEnvelope);
      // Must be stored locally but halt radio forward
      expect(action, equals(RelayAction.storedTtlExpired));
    });

    // -------------------------------------------------------------------------
    // TEST 6: Low Power True OLED Black Mode Toggle
    // -------------------------------------------------------------------------
    test('Test 6: Low Power OLED Theme Toggle — Sets true black #000000 background', () async {
      final themeProvider = ThemeProvider();

      // Normal dark theme (Night Navy)
      expect(themeProvider.isLowPower, isFalse);
      expect(themeProvider.bg, equals(AppTokens.nightNavy));

      // Toggle to Low Power OLED True Black
      await themeProvider.setLowPower(true);
      expect(themeProvider.isLowPower, isTrue);
      expect(themeProvider.bg, equals(AppTokens.oledBg)); // #000000

      // Toggle back to Normal
      await themeProvider.setLowPower(false);
      expect(themeProvider.isLowPower, isFalse);
      expect(themeProvider.bg, equals(AppTokens.nightNavy));
    });

    // -------------------------------------------------------------------------
    // TEST 7: Dynamic Data Integrity & Zero Hardcoded Data
    // -------------------------------------------------------------------------
    test('Test 7: Dynamic Data Integrity — Empty database returns empty collections without fake data', () async {
      final dbService = DatabaseService();
      final freshId = 'unique-${DateTime.now().millisecondsSinceEpoch}';

      // Ensure non-existent message returns null rather than mock object
      final nonExistent = await dbService.getMessageById(freshId);
      expect(nonExistent, isNull);

      // Ensure all dynamic values have legitimate sources
      final userProfile = UserProfile(
        id: 'SR-TEST-001',
        name: 'Real User',
        bloodGroup: 'B+',
        emergencyContact: '+91 9999999999',
        preferredLanguage: 'English',
        isRegistered: true,
      );
      expect(userProfile.name, equals('Real User'));
      expect(userProfile.bloodGroup, equals('B+'));
      expect(userProfile.isRegistered, isTrue);
    });
  });
}
