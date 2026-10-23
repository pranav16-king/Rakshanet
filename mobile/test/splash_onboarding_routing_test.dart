import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rakshanet_mobile/database/app_database.dart';
import 'package:rakshanet_mobile/models/user_profile.dart';
import 'package:rakshanet_mobile/providers/chat_provider.dart';
import 'package:rakshanet_mobile/providers/device_status_provider.dart';
import 'package:rakshanet_mobile/providers/emergency_report_provider.dart';
import 'package:rakshanet_mobile/providers/mesh_provider.dart';
import 'package:rakshanet_mobile/providers/missing_persons_provider.dart';
import 'package:rakshanet_mobile/providers/profile_provider.dart';
import 'package:rakshanet_mobile/providers/sos_provider.dart';
import 'package:rakshanet_mobile/providers/telemetry_provider.dart';
import 'package:rakshanet_mobile/providers/theme_provider.dart';
import 'package:rakshanet_mobile/providers/user_profile_provider.dart';
import 'package:rakshanet_mobile/screens/onboarding/emergency_mesh_intro_screen.dart';
import 'package:rakshanet_mobile/screens/onboarding/splash_screen.dart';
import 'package:rakshanet_mobile/screens/profile/profile_setup_screen.dart';
import 'package:rakshanet_mobile/screens/shell/main_shell.dart';
import 'package:rakshanet_mobile/services/call_session_controller.dart';
import 'package:rakshanet_mobile/services/chat_service.dart';
import 'package:rakshanet_mobile/services/device_identity_service.dart';
import 'package:rakshanet_mobile/services/group_service.dart';
import 'package:rakshanet_mobile/services/user_auth_service.dart';

Widget _buildSplashApp({
  required ProfileProvider profileProvider,
  required UserProfileProvider userProfileProvider,
}) {
  final mesh = MeshProvider()..stopScan();
  final telemetry = TelemetryProvider()..stopPolling();
  final chatService = ChatService()..stopTimers();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
      ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
      ChangeNotifierProvider<UserProfileProvider>.value(value: userProfileProvider),
      ChangeNotifierProvider<MeshProvider>.value(value: mesh),
      ChangeNotifierProvider<ChatProvider>(create: (_) => ChatProvider()),
      ChangeNotifierProvider<ChatService>.value(value: chatService),
      ChangeNotifierProvider<GroupService>(create: (_) => GroupService()),
      ChangeNotifierProvider<UserAuthService>.value(value: UserAuthService.instance),
      ChangeNotifierProvider<CallSessionController>(create: (_) => CallSessionController()),
      ChangeNotifierProvider<DeviceStatusProvider>(create: (_) => DeviceStatusProvider()),
      ChangeNotifierProvider<EmergencyReportProvider>(create: (_) => EmergencyReportProvider()),
      ChangeNotifierProvider<MissingPersonsProvider>(create: (_) => MissingPersonsProvider()),
      ChangeNotifierProvider<SosProvider>.value(value: SosProvider.instance),
      ChangeNotifierProvider<TelemetryProvider>.value(value: telemetry),
    ],
    child: MaterialApp(
      home: const SplashScreen(),
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/profile-setup': (_) => const ProfileSetupScreen(),
        '/emergency-mesh-intro': (_) => const EmergencyMeshIntroScreen(),
        '/main': (_) => const MainShell(),
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

  group('New User vs Returning User Splash Screen Routing Verification', () {
    testWidgets(
      'S1: New user with no registered profile is routed to ProfileSetupScreen',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final profileProvider = ProfileProvider();
        final userProfileProvider = UserProfileProvider();

        await tester.pumpWidget(
          _buildSplashApp(
            profileProvider: profileProvider,
            userProfileProvider: userProfileProvider,
          ),
        );

        // Initial splash screen renders
        expect(find.byType(SplashScreen), findsOneWidget);
        expect(find.text('RakshaNet'), findsOneWidget);

        // Advance through the startup phases
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 500));

        // New user MUST see ProfileSetupScreen (Emergency Profile Setup)
        expect(find.byType(ProfileSetupScreen), findsOneWidget);
        expect(find.text('Emergency Profile Setup'), findsOneWidget);
        expect(find.text('Detect & Auto-Fill Mobile IMEI ID'), findsOneWidget);
      },
    );

    testWidgets(
      'S2: Returning registered user is routed directly to MainShell',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // Seed registered user profile into SQLite
        final registeredProfile = UserProfile(
          id: '864201048829103',
          name: 'Priya Sharma',
          isRegistered: true,
          email: 'priya@emergency.in',
          emergencyContact: '+91 98765 43210',
          bloodGroup: 'O+',
          preferredLanguage: 'English',
        );
        await AppDatabase.instance.saveUserProfile(registeredProfile);

        final profileProvider = ProfileProvider();
        await profileProvider.loadProfile();

        final userProfileProvider = UserProfileProvider();
        await userProfileProvider.loadProfile();

        await tester.pumpWidget(
          _buildSplashApp(
            profileProvider: profileProvider,
            userProfileProvider: userProfileProvider,
          ),
        );

        // Initial splash screen renders
        expect(find.byType(SplashScreen), findsOneWidget);

        // Advance through startup sequence
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 500));

        // Returning registered user MUST bypass onboarding and enter MainShell
        expect(find.byType(MainShell), findsOneWidget);
        expect(find.byType(ProfileSetupScreen), findsNothing);
      },
    );
  });
}
