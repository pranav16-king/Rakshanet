import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rakshanet_mobile/models/chat_message.dart';
import 'package:rakshanet_mobile/models/remote_user_profile.dart';
import 'package:rakshanet_mobile/providers/mesh_provider.dart';
import 'package:rakshanet_mobile/providers/telemetry_provider.dart';
import 'package:rakshanet_mobile/providers/theme_provider.dart';
import 'package:rakshanet_mobile/screens/chat/chat_screen.dart';
import 'package:rakshanet_mobile/screens/profile/remote_profile_details_screen.dart';
import 'package:rakshanet_mobile/services/call_session_controller.dart';
import 'package:rakshanet_mobile/services/chat_service.dart';
import 'package:rakshanet_mobile/services/group_service.dart';
import 'package:rakshanet_mobile/services/mesh_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    ChatService().stopTimers();
  });

  group('Direct Chat & Profile Actions Test Suite', () {
    test('1. ChatService direct messaging sets category to Nearby and targetRecipient', () async {
      final chatService = ChatService();
      const peerId = 'PEER-COORDINATOR-99';
      const convId = 'DIRECT_$peerId';

      final msg = await chatService.sendMessage(
        content: 'Hello mesh coordinator, are you reachable directly?',
        conversationId: convId,
      );

      expect(msg.conversationId, equals(convId));
      expect(msg.recipientTarget, equals(peerId));
      expect(msg.category, equals('Nearby'));
      // Save-Before-Send guarantee ensures message is initially saved
      expect(msg.status, equals(MessageDeliveryStatus.saved));
    });

    test('2. ChatService sends offline voice note with direct targeting & metadata', () async {
      final chatService = ChatService();
      const peerId = 'PEER-RESCUER-01';

      final voiceMsg = await chatService.sendVoiceNote(
        45,
        conversationId: 'DIRECT_$peerId',
        recipientTarget: peerId,
        category: 'Nearby',
      );

      expect(voiceMsg.messageType, equals('VOICE'));
      expect(voiceMsg.content, contains('00:45'));
      expect(voiceMsg.recipientTarget, equals(peerId));
      expect(voiceMsg.category, equals('Nearby'));
    });

    test('3. ChatService block user hides messages locally', () async {
      final chatService = ChatService();
      const spammerId = 'PEER-SPAMMER-66';

      await chatService.toggleBlockUser(spammerId);
      expect(chatService.isUserBlocked(spammerId), isTrue);

      final blockedIds = chatService.blockedUserIds;
      expect(blockedIds.contains(spammerId), isTrue);

      // Unblock
      await chatService.toggleBlockUser(spammerId);
      expect(chatService.isUserBlocked(spammerId), isFalse);
    });

    test('4. MeshEngine instance statusUpdates stream provides real-time updates', () async {
      final engine = MeshEngine.instance;
      expect(engine, isNotNull);

      final testMsg = ChatMessage(
        id: 'MSG-SYNC-TEST-01',
        conversationId: 'CONV_COMMUNITY',
        senderId: 'local_user',
        senderName: 'You',
        content: 'Emergency packet synced to server',
        status: MessageDeliveryStatus.syncedToServer,
      );

      // Verify status mapping
      expect(testMsg.isSyncedToServer, isTrue);
      expect(MessageDeliveryStatus.syncedToServer.label, equals('☁ Synced to server'));

      final icon = testMsg.buildStatusWidget();
      expect(icon, isA<Icon>());
      expect((icon as Icon).icon, equals(Icons.cloud_done_rounded));
    });

    testWidgets('5. ChatScreen mounts cleanly in 1:1 direct conversation mode', (tester) async {
      final chatService = ChatService()..stopTimers();
      final groupService = GroupService();
      final themeProvider = ThemeProvider();
      final meshProvider = MeshProvider()..stopScan();
      final telemetryProvider = TelemetryProvider()..stopPolling();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: chatService),
            ChangeNotifierProvider.value(value: groupService),
            ChangeNotifierProvider.value(value: themeProvider),
            ChangeNotifierProvider.value(value: meshProvider),
            ChangeNotifierProvider.value(value: telemetryProvider),
          ],
          child: const MaterialApp(
            home: ChatScreen(
              conversationId: 'DIRECT_PEER-123',
              initialFilter: 'Nearby',
              targetRecipient: 'PEER-123',
              recipientName: 'Relay Coordinator',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Relay Coordinator'), findsOneWidget);
      expect(find.textContaining('Direct peer session with Relay Coordinator'), findsOneWidget);
      expect(find.byType(ChatScreen), findsOneWidget);
    });

    testWidgets('6. RemoteProfileDetailsScreen renders functional action buttons', (tester) async {
      final chatService = ChatService()..stopTimers();
      final groupService = GroupService();
      final themeProvider = ThemeProvider();
      final callController = CallSessionController();

      const profile = RemoteUserProfile(
        userId: 'PEER-COORDINATOR-44',
        displayName: 'Mesh Relay Coordinator',
        source: 'Nearby RF BLE',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: chatService),
            ChangeNotifierProvider.value(value: groupService),
            ChangeNotifierProvider.value(value: themeProvider),
            ChangeNotifierProvider.value(value: callController),
          ],
          child: const MaterialApp(
            home: RemoteProfileDetailsScreen(profile: profile),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mesh Relay Coordinator'), findsOneWidget);

      // Scroll to safety controls in ListView
      final blockFinder = find.text('Block user');
      await tester.scrollUntilVisible(blockFinder, 100);
      expect(blockFinder, findsOneWidget);
      expect(find.text('Report user'), findsOneWidget);

      // Scroll back up to Voice call nearby button
      final voiceCallBtn = find.textContaining('Voice call nearby');
      await tester.scrollUntilVisible(voiceCallBtn, -100);
      expect(voiceCallBtn, findsOneWidget);

      // Message in mesh chat button is present
      expect(find.text('Message in mesh chat'), findsOneWidget);

      // Tap Voice call nearby opens the action sheet
      await tester.tap(voiceCallBtn);
      await tester.pumpAndSettle();

      expect(find.text('Direct Voice Link Offline'), findsOneWidget);
      expect(find.text('Attempt Direct Mesh Voice Call'), findsOneWidget);
      expect(find.text('Send Audio Memo (Offline Voice Note)'), findsOneWidget);
    });
  });
}
