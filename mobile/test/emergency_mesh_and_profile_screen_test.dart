import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rakshanet_mobile/database/app_database.dart';
import 'package:rakshanet_mobile/models/mesh_device.dart';
import 'package:rakshanet_mobile/providers/mesh_provider.dart';
import 'package:rakshanet_mobile/providers/profile_provider.dart';
import 'package:rakshanet_mobile/providers/telemetry_provider.dart';
import 'package:rakshanet_mobile/providers/theme_provider.dart';
import 'package:rakshanet_mobile/providers/user_profile_provider.dart';
import 'package:rakshanet_mobile/screens/onboarding/emergency_mesh_intro_screen.dart';
import 'package:rakshanet_mobile/screens/profile/profile_setup_screen.dart';
import 'package:rakshanet_mobile/services/chat_service.dart';
import 'package:rakshanet_mobile/services/device_identity_service.dart';
import 'package:rakshanet_mobile/widgets/mesh/peer_details_sheet.dart';

Widget _buildTestApp({
  required Widget child,
  ThemeProvider? themeProvider,
  ProfileProvider? profileProvider,
  UserProfileProvider? userProfileProvider,
  MeshProvider? meshProvider,
  TelemetryProvider? telemetryProvider,
  ChatService? chatService,
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
      ChangeNotifierProvider<ProfileProvider>.value(
        value: profileProvider ?? ProfileProvider(),
      ),
      ChangeNotifierProvider<UserProfileProvider>.value(
        value: userProfileProvider ?? UserProfileProvider(),
      ),
      ChangeNotifierProvider<MeshProvider>.value(
        value: mesh,
      ),
      ChangeNotifierProvider<TelemetryProvider>.value(
        value: telemetry,
      ),
      ChangeNotifierProvider<ChatService>.value(
        value: chat,
      ),
    ],
    child: MaterialApp(
      home: child,
      routes: {
        '/main-shell': (context) => const Scaffold(body: Text('Safety Hub Shell')),
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

  group('Emergency Mesh & Profile Setup Screen Verification Suite', () {
    testWidgets(
      'M1: EmergencyMeshIntroScreen mounts with non-duplicate header, real network status, and no fake "Ready" badge',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildTestApp(
            child: const EmergencyMeshIntroScreen(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));

        // Header Title and Subtitle
        expect(find.text('Emergency Mesh'), findsOneWidget);
        expect(find.textContaining('Direct'), findsWidgets);

        // Meaningful status badge present (never fake "Ready")
        expect(find.text('Ready'), findsNothing);
        expect(
          find.byWidgetPredicate((w) =>
              w is Text &&
              (w.data == 'OFFLINE — NO PEERS' ||
                  w.data == 'DISCOVERING PEERS' ||
                  w.data == 'INITIALIZING' ||
                  w.data == 'PERMISSION REQUIRED' ||
                  w.data == 'PEERS FOUND')),
          findsOneWidget,
        );

        // Distinct Section Banner
        expect(find.text('OFFLINE P2P MESH RELAY'), findsOneWidget);

        // Topology and Telemetry sections
        expect(find.text('Live Topology Diagram'), findsOneWidget);
        expect(find.text('Network & Hardware Telemetry'), findsOneWidget);

        // Non-overlapping docked action buttons
        expect(find.text('Scan Radio'), findsOneWidget);
        expect(find.text('Continue to Safety Hub'), findsOneWidget);
      },
    );

    testWidgets(
      'M2: Live Topology simulation mode toggles with clear [DEMO SIMULATION] badge',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildTestApp(
            child: const EmergencyMeshIntroScreen(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));

        // Tap Test Mode / Demo toggle
        final demoToggle = find.text('Test Mode');
        expect(demoToggle, findsOneWidget);
        await tester.tap(demoToggle);
        await tester.pump();

        // Must display active simulation banner and simulated nodes
        expect(find.textContaining('DEMO SIMULATION ACTIVE'), findsOneWidget);
        expect(find.text('Citizen Phone'), findsOneWidget);
        expect(find.text('Relay Beacon'), findsOneWidget);
        expect(find.text('Rescue Station'), findsOneWidget);
      },
    );

    testWidgets(
      'M3: Tapping a discovered node opens PeerDetailsSheet with privacy alias and zero-trust note',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final samplePeer = MeshDevice(
          id: 'test_node_42',
          deviceId: 'SR-DEV-42A9',
          displayName: 'Field Responder Alpha',
          connectionType: ConnectionType.ble,
          signalStrength: -72,
          proximityBand: ProximityBand.near,
          hopCount: 1,
          batteryLevel: 88,
          lastSeen: DateTime.now(),
          isConnected: true,
        );

        await tester.pumpWidget(
          _buildTestApp(
            child: PeerDetailsSheet(peer: samplePeer),
          ),
        );
        await tester.pump();

        // Privacy-preserving alias (never raw device identifier)
        expect(find.textContaining('Node #42A9'), findsOneWidget);
        expect(find.text('CONNECTED'), findsOneWidget);
        expect(find.textContaining('Bluetooth Low Energy'), findsOneWidget);
        expect(find.textContaining('Verified Ed25519 Identity'), findsOneWidget);
        expect(find.textContaining('Unauthenticated proximity devices are never treated as trusted emergency responders.'), findsOneWidget);
        expect(find.text('Ping Node'), findsOneWidget);
        expect(find.text('Disconnect'), findsOneWidget);
      },
    );

    testWidgets(
      'P1: ProfileSetupScreen compact layout displays Full Name, IMEI, and Detect button above the fold',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildTestApp(
            child: const ProfileSetupScreen(),
          ),
        );
        await tester.pump();

        // Compact header elements
        expect(find.text('Emergency Profile'), findsOneWidget);
        expect(find.text('1 of 2'), findsOneWidget);
        expect(find.text('STEP 1 OF 2'), findsOneWidget);
        expect(find.text('Profile Details'), findsOneWidget);

        // Title and Offline Ready status card
        expect(find.text('Emergency Profile Setup'), findsOneWidget);
        expect(find.text('Offline Ready'), findsOneWidget);
        expect(find.text('LOCAL STORAGE ACTIVE'), findsOneWidget);
        expect(find.text('No cloud connection required'), findsOneWidget);

        // Form Fields (placeholders & buttons)
        expect(find.widgetWithText(TextField, 'Enter your full name'), findsOneWidget);
        expect(find.text('Detect & Auto-Fill Mobile IMEI ID'), findsOneWidget);

        // Bottom CTA
        expect(find.text('Continue'), findsOneWidget);
        expect(find.textContaining('stored locally on this device'), findsOneWidget);
      },
    );
  });
}
