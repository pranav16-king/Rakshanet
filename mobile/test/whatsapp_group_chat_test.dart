import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rakshanet_mobile/database/app_database.dart';
import 'package:rakshanet_mobile/models/chat_group.dart';
import 'package:rakshanet_mobile/providers/mesh_provider.dart';
import 'package:rakshanet_mobile/providers/telemetry_provider.dart';
import 'package:rakshanet_mobile/providers/theme_provider.dart';
import 'package:rakshanet_mobile/screens/chat/chat_screen.dart';
import 'package:rakshanet_mobile/services/chat_service.dart';
import 'package:rakshanet_mobile/services/device_identity_service.dart';
import 'package:rakshanet_mobile/services/group_service.dart';

Widget _buildTestApp({
  required Widget child,
  ThemeProvider? themeProvider,
  ChatService? chatService,
  GroupService? groupService,
  MeshProvider? meshProvider,
  TelemetryProvider? telemetryProvider,
}) {
  final mesh = meshProvider ?? MeshProvider();
  mesh.stopScan();

  final telemetry = telemetryProvider ?? TelemetryProvider();
  telemetry.stopPolling();

  final chat = chatService ?? ChatService();
  chat.stopTimers();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeProvider>.value(
        value: themeProvider ?? ThemeProvider(),
      ),
      ChangeNotifierProvider<ChatService>.value(
        value: chat,
      ),
      ChangeNotifierProvider<GroupService>.value(
        value: groupService ?? GroupService(),
      ),
      ChangeNotifierProvider<MeshProvider>.value(
        value: mesh,
      ),
      ChangeNotifierProvider<TelemetryProvider>.value(
        value: telemetry,
      ),
    ],
    child: MaterialApp(
      home: child,
      routes: {
        '/create-group': (context) => const Scaffold(body: Text('Create Group Screen')),
        '/pending-invites': (context) => const Scaffold(body: Text('Pending Invites Screen')),
      },
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppDatabase.instance.ensureInitialized();
    await DeviceIdentityService.instance.initialize();
  });

  group('WhatsApp-Style Mesh Groups & Chat Auto-Scroll Test Suite', () {
    testWidgets(
      'WG1: ChatScreen mounts on Nearby tab with community input bar and shortcuts',
      (WidgetTester tester) async {
        final chatService = ChatService()..stopTimers();
        final groupService = GroupService();

        await tester.pumpWidget(
          _buildTestApp(
            child: const ChatScreen(),
            chatService: chatService,
            groupService: groupService,
          ),
        );
        await tester.pump();

        // On Nearby tab, message input bar is visible
        expect(find.text('Type an emergency message...'), findsOneWidget);
        expect(find.text('Community Chat'), findsOneWidget);
        expect(find.text('Need medical help'), findsOneWidget);
      },
    );

    testWidgets(
      'WG2: Switching to Group tab renders WhatsApp Groups Directory with actions and no floating input bar',
      (WidgetTester tester) async {
        final chatService = ChatService()..stopTimers();
        final groupService = GroupService();
        groupService.selectGroup(null); // Ensure no group is selected

        await tester.pumpWidget(
          _buildTestApp(
            child: const ChatScreen(),
            chatService: chatService,
            groupService: groupService,
          ),
        );
        await tester.pump();

        // Switch to Group tab
        chatService.setActiveFilter('Group');
        await tester.pump();

        // In WhatsApp directory mode, directory header and quick actions must be rendered
        expect(find.text('Mesh Groups'), findsOneWidget);
        expect(find.text('New Group'), findsOneWidget);
        expect(find.text('Join with Code'), findsOneWidget);
        expect(find.textContaining('JOINED MESH GROUPS'), findsOneWidget);

        // Bottom text input bar should NOT be shown in directory view
        expect(find.text('Type a message...'), findsNothing);
      },
    );

    testWidgets(
      'WG3: Selecting a group enters dedicated group room with back navigation and scoped input',
      (WidgetTester tester) async {
        final chatService = ChatService()..stopTimers();
        final groupService = GroupService();

        // Seed a sample group
        final testGroup = ChatGroup(
          id: 'GRP-TEST01',
          name: 'NDRF Rescue Unit Alpha',
          description: 'Emergency rescue unit Alpha',
          creatorId: 'SR-HQ-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          conversationId: 'CONV_GRP-TEST01',
          memberCount: 3,
        );
        await AppDatabase.instance.insert(
          'groups',
          testGroup.toMap(),
        );
        await groupService.loadGroups();

        await tester.pumpWidget(
          _buildTestApp(
            child: const ChatScreen(),
            chatService: chatService,
            groupService: groupService,
          ),
        );
        await tester.pump();

        // Switch to Group tab
        chatService.setActiveFilter('Group');
        await tester.pump();

        // Group tile is visible in WhatsApp directory
        expect(find.text('NDRF Rescue Unit Alpha'), findsOneWidget);
        expect(find.text('GRP-TEST01'), findsOneWidget);

        // Select the group
        groupService.selectGroup(testGroup.id);
        await tester.pump();

        // In dedicated group room:
        // 1. Group title and back button
        expect(find.text('NDRF Rescue Unit Alpha'), findsWidgets);
        expect(find.text('All Groups'), findsWidgets);
        // 2. Scoped input bar for group
        expect(find.text('Message NDRF Rescue Unit Alpha...'), findsOneWidget);

        // Tap All Groups back navigation
        final backButton = find.text('All Groups').first;
        await tester.tap(backButton);
        await tester.pump();

        // Verified back in WhatsApp Groups Directory
        expect(groupService.selectedGroup, isNull);
        expect(find.text('New Group'), findsOneWidget);
        expect(find.text('Join with Code'), findsOneWidget);
      },
    );
  });
}
