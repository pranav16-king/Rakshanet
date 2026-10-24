import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rakshanet_mobile/database/app_database.dart';
import 'package:rakshanet_mobile/database/repositories/profile_repository.dart';
import 'package:rakshanet_mobile/database/repositories/missing_person_repository.dart';
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
import 'package:rakshanet_mobile/screens/chat/chat_screen.dart';
import 'package:rakshanet_mobile/screens/home/emergency_report_screen.dart';
import 'package:rakshanet_mobile/screens/onboarding/profile_setup_screen.dart' as onboarding;
import 'package:rakshanet_mobile/screens/profile/profile_setup_screen.dart' as profile_screen;
import 'package:rakshanet_mobile/screens/tools/live_map_screen.dart';
import 'package:rakshanet_mobile/screens/tools/missing_persons_screen.dart';
import 'package:rakshanet_mobile/services/chat_service.dart';
import 'package:rakshanet_mobile/services/device_identity_service.dart';
import 'package:rakshanet_mobile/services/group_service.dart';
import 'package:rakshanet_mobile/services/user_auth_service.dart';
import 'package:rakshanet_mobile/theme/app_theme.dart';
import 'package:rakshanet_mobile/theme/app_tokens.dart';

Widget _buildTestApp({
  required Widget child,
  ThemeProvider? themeProvider,
  ProfileProvider? profileProvider,
  MeshProvider? meshProvider,
  ChatProvider? chatProvider,
  ChatService? chatService,
  GroupService? groupService,
  UserAuthService? userAuthService,
  EmergencyReportProvider? emergencyReportProvider,
  MissingPersonsProvider? missingPersonsProvider,
  SosProvider? sosProvider,
  UserProfileProvider? userProfileProvider,
  DeviceStatusProvider? deviceStatusProvider,
  TelemetryProvider? telemetryProvider,
}) {
  final mesh = meshProvider ?? MeshProvider();
  mesh.stopScan();

  final telemetry = telemetryProvider ?? TelemetryProvider();
  telemetry.stopPolling();

  final deviceStatus = deviceStatusProvider ?? DeviceStatusProvider();
  deviceStatus.stopPolling();

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
      ChangeNotifierProvider<MeshProvider>.value(
        value: mesh,
      ),
      ChangeNotifierProvider<ChatProvider>.value(
        value: chatProvider ?? ChatProvider(),
      ),
      ChangeNotifierProvider<ChatService>.value(
        value: chat,
      ),
      ChangeNotifierProvider<GroupService>.value(
        value: groupService ?? GroupService(),
      ),
      ChangeNotifierProvider<UserAuthService>.value(
        value: userAuthService ?? UserAuthService.instance,
      ),
      ChangeNotifierProvider<EmergencyReportProvider>.value(
        value: emergencyReportProvider ?? EmergencyReportProvider(),
      ),
      ChangeNotifierProvider<MissingPersonsProvider>.value(
        value: missingPersonsProvider ?? MissingPersonsProvider(),
      ),
      ChangeNotifierProvider<SosProvider>.value(
        value: sosProvider ?? SosProvider.instance,
      ),
      ChangeNotifierProvider<UserProfileProvider>.value(
        value: userProfileProvider ?? UserProfileProvider(),
      ),
      ChangeNotifierProvider<DeviceStatusProvider>.value(
        value: deviceStatus,
      ),
      ChangeNotifierProvider<TelemetryProvider>.value(
        value: telemetry,
      ),
    ],
    child: MaterialApp(
      home: child,
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

  group('RakshaNet Zero-Pre-entered Data & Feature Integrity Suite', () {
    // =========================================================================
    // Test A: Zero Pre-entered Data Audit
    // =========================================================================
    group('Test A: Zero Pre-entered Data Audit', () {
      testWidgets(
        'A1: Onboarding ProfileSetupScreen initializes all controllers empty',
        (WidgetTester tester) async {
          final profileProvider = ProfileProvider();
          final themeProvider = ThemeProvider();

          await tester.pumpWidget(
            _buildTestApp(
              child: const onboarding.ProfileSetupScreen(),
              profileProvider: profileProvider,
              themeProvider: themeProvider,
            ),
          );
          await tester.pump();

          // All TextFields in ProfileSetupScreen must initialize with empty text
          final textFields = tester.widgetList<TextField>(find.byType(TextField));
          expect(textFields.isNotEmpty, isTrue, reason: 'Profile fields must exist');

          for (final field in textFields) {
            expect(field.controller?.text ?? '', isEmpty,
                reason: 'Field controller must initialize empty ("")');
          }

          // Verify placeholder / hint text is displayed, not pre-filled text
          expect(find.text('Enter your full name'), findsOneWidget);
          expect(find.text('Optional email for cloud backup'), findsOneWidget);
        },
      );

      testWidgets(
        'A2: Profile Tab ProfileSetupScreen initializes all controllers empty',
        (WidgetTester tester) async {
          final profileProvider = ProfileProvider();
          final themeProvider = ThemeProvider();

          await tester.pumpWidget(
            _buildTestApp(
              child: const profile_screen.ProfileSetupScreen(),
              profileProvider: profileProvider,
              themeProvider: themeProvider,
            ),
          );
          await tester.pump();

          final textFields = tester.widgetList<TextField>(find.byType(TextField));
          expect(textFields.isNotEmpty, isTrue);

          for (final field in textFields) {
            expect(field.controller?.text ?? '', isEmpty,
                reason: 'Field controller must initialize empty ("")');
          }

          expect(find.text('Enter your full name'), findsOneWidget);
          expect(find.text('Optional email for cloud backup'), findsOneWidget);
        },
      );

      testWidgets(
        'A3: EmergencyReportScreen notes controller initializes empty',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              child: const EmergencyReportScreen(),
            ),
          );
          await tester.pump();

          final textFields = tester.widgetList<TextField>(find.byType(TextField));
          expect(textFields.isNotEmpty, isTrue);

          for (final field in textFields) {
            expect(field.controller?.text, isEmpty,
                reason: 'Emergency report notes controller must initialize empty ("")');
          }
          expect(
            find.text('Additional details (e.g. severe leg wound, 2nd floor, elderly)...'),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'A4: ChatScreen message input text controller initializes empty',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              child: const ChatScreen(),
            ),
          );
          await tester.pump();

          final textFields = tester.widgetList<TextField>(find.byType(TextField));
          expect(textFields.isNotEmpty, isTrue);

          final chatInputField = textFields.first;
          expect(chatInputField.controller?.text, isEmpty,
              reason: 'Chat input controller must initialize empty ("")');
          expect(find.text('Type a message...'), findsOneWidget);
        },
      );

      testWidgets(
        'A5: MissingPersonsScreen registry and report modal initialize empty',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              child: const MissingPersonsScreen(),
            ),
          );
          await tester.pump();

          // Registry search bar initializes empty
          final searchField = tester.widget<TextField>(find.byType(TextField));
          expect(searchField.controller?.text, isEmpty);

          // Tap "Report Missing" FAB to open modal
          final reportFab = find.text('Report Missing');
          expect(reportFab, findsOneWidget);
          await tester.tap(reportFab);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));

          // In modal, all form fields initialize empty
          final modalFields = tester.widgetList<TextFormField>(find.byType(TextFormField));
          expect(modalFields.length, greaterThanOrEqualTo(4));

          for (final field in modalFields) {
            expect(field.controller?.text, isEmpty,
                reason: 'Missing person modal field must initialize empty ("")');
          }
        },
      );
    });

    // =========================================================================
    // Test B: Input Validation & Real Data Flow
    // =========================================================================
    group('Test B: Input Validation & Real Data Flow', () {
      testWidgets(
        'B1: ProfileSetupScreen empty required fields fail validation with descriptive warnings',
        (WidgetTester tester) async {
          tester.view.physicalSize = const Size(800, 1400);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final profileProvider = ProfileProvider();

          await tester.pumpWidget(
            _buildTestApp(
              child: const onboarding.ProfileSetupScreen(),
              profileProvider: profileProvider,
            ),
          );
          await tester.pump();

          // Tap Continue without filling mandatory name or detecting IMEI
          final continueButton = find.text('Continue');
          expect(continueButton, findsOneWidget);
          await tester.ensureVisible(continueButton);
          await tester.tap(continueButton);
          await tester.pump(); // frame 1: validator runs
          await tester.pump(); // frame 2: post-frame callback rebuilds error UI

          // Descriptive warnings must be displayed
          expect(find.text('Full Name is required'), findsOneWidget);
          expect(find.text('Please tap "Detect & Auto-Fill Mobile IMEI ID" below'), findsOneWidget);

          // State must remain unregistered
          expect(profileProvider.isRegistered, isFalse);
        },
      );

      testWidgets(
        'B2: ProfileSetupScreen entering real user input successfully persists to SQLite and updates state',
        (WidgetTester tester) async {
          tester.view.physicalSize = const Size(800, 1400);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final profileProvider = ProfileProvider();

          await tester.pumpWidget(
            _buildTestApp(
              child: const onboarding.ProfileSetupScreen(),
              profileProvider: profileProvider,
            ),
          );
          await tester.pump();

          // 1. Enter Full Name
          final nameFinder = find.widgetWithText(TextField, 'Enter your full name');
          await tester.enterText(nameFinder, 'Dr. Priya Sharma');

          // 2. Tap Detect IMEI and accept dialog
          final detectButton = find.text('Detect & Auto-Fill Mobile IMEI ID');
          await tester.ensureVisible(detectButton);
          await tester.tap(detectButton);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          final agreeButton = find.text('Agree & Auto-Fill');
          expect(agreeButton, findsOneWidget);
          await tester.tap(agreeButton);
          await tester.pump();
          await tester.pump(const Duration(seconds: 3)); // Allow native channel timeout to complete

          // 3. Tap Continue to move to review step
          final continueButton = find.text('Continue');
          await tester.ensureVisible(continueButton);
          await tester.tap(continueButton);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          // 4. On Review Step, tap Save & Continue
          final saveButton = find.text('Save & Continue');
          expect(saveButton, findsOneWidget);
          await tester.ensureVisible(saveButton);
          await tester.tap(saveButton);
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));

          // State updated
          expect(profileProvider.isRegistered, isTrue);
          expect(profileProvider.profile.name, equals('Dr. Priya Sharma'));
          expect(profileProvider.profile.deviceId.isNotEmpty, isTrue);
          expect(
            RegExp(r'^\d{15}$|^SR-').hasMatch(profileProvider.profile.deviceId),
            isTrue,
            reason: 'Device ID must be valid 15-digit hardware IMEI or SR- prefix',
          );

          // Persisted to SQLite via ProfileRepository
          final profileRepo = ProfileRepository();
          final savedProfile = await profileRepo.getProfile();
          expect(savedProfile, isNotNull);
          expect(savedProfile?.name, equals('Dr. Priya Sharma'));
        },
      );

      testWidgets(
        'B3: MissingPersonsScreen validation fails on empty, and real submission persists to SQLite',
        (WidgetTester tester) async {
          tester.view.physicalSize = const Size(800, 1400);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final mpProvider = MissingPersonsProvider();

          await tester.pumpWidget(
            _buildTestApp(
              child: const MissingPersonsScreen(),
              missingPersonsProvider: mpProvider,
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));

          // Tap Report Missing FAB
          final reportFab = find.text('Report Missing');
          await tester.tap(reportFab);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));

          // Tap Broadcast Bulletin with empty fields
          final submitButton = find.text('Broadcast Bulletin to Mesh');
          await tester.ensureVisible(submitButton);
          await tester.tap(submitButton);
          await tester.pump();

          // Validation warnings must trigger
          expect(find.text('Name is required'), findsOneWidget);
          expect(find.text('Required'), findsOneWidget); // Age
          expect(find.text('Location is required'), findsOneWidget);
          expect(find.text('Description is required'), findsOneWidget);

          // Now enter real report data
          final nameField = find.widgetWithText(TextFormField, 'e.g. Rameshwar Sen');
          await tester.enterText(nameField, 'Aarav Kumar');

          final ageField = find.widgetWithText(TextFormField, 'e.g. 68');
          await tester.enterText(ageField, '10');

          final locField = find.widgetWithText(TextFormField, 'e.g. Ward 14 Relief Camp / Sector 3');
          await tester.enterText(locField, 'Sector 4 Shelter Grounds');

          final descField = find.widgetWithText(TextFormField, 'e.g. Wearing white kurta, brown shawl. Hearing impaired.');
          await tester.enterText(descField, 'Red t-shirt, blue cap');
          await tester.pump();

          // Submit real data
          await tester.ensureVisible(submitButton);
          await tester.tap(submitButton);
          await tester.pump();
          await tester.pump(const Duration(seconds: 3)); // Drain background upload timer

          // Verify SQLite persistence via repository
          final repo = MissingPersonRepository();
          final reports = await repo.getMissingPersons();
          expect(reports.any((r) => r.name == 'Aarav Kumar'), isTrue);
          final saved = reports.firstWhere((r) => r.name == 'Aarav Kumar');
          expect(saved.age, equals(10));
          expect(saved.description, equals('Red t-shirt, blue cap'));
          expect(saved.lastSeenLocation, equals('Sector 4 Shelter Grounds'));
        },
      );
    });

    // =========================================================================
    // Test C: Provider Resolution Integrity
    // =========================================================================
    group('Test C: Provider Resolution Integrity', () {
      testWidgets(
        'C1: ChatScreen mounts cleanly under MultiProvider with Provider<ChatService>',
        (WidgetTester tester) async {
          final themeProvider = ThemeProvider();
          final chatService = ChatService();
          final groupService = GroupService();
          final meshProvider = MeshProvider()..stopScan();

          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
                ChangeNotifierProvider<ChatService>.value(value: chatService),
                ChangeNotifierProvider<GroupService>.value(value: groupService),
                ChangeNotifierProvider<MeshProvider>.value(value: meshProvider),
              ],
              child: const MaterialApp(
                home: ChatScreen(),
              ),
            ),
          );
          await tester.pump();

          // Verify ChatScreen renders cleanly without throwing ProviderNotFoundException
          expect(find.byType(ChatScreen), findsOneWidget);
          expect(find.text('Type a message...'), findsOneWidget);
        },
      );

      testWidgets(
        'C2: ChatScreen throws ProviderNotFoundException when ChatService is omitted',
        (WidgetTester tester) async {
          final themeProvider = ThemeProvider();
          final groupService = GroupService();
          final meshProvider = MeshProvider()..stopScan();

          FlutterErrorDetails? caughtError;
          final originalOnError = FlutterError.onError;
          FlutterError.onError = (details) {
            caughtError = details;
          };
          try {
            await tester.pumpWidget(
              MultiProvider(
                providers: [
                  ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
                  ChangeNotifierProvider<GroupService>.value(value: groupService),
                  ChangeNotifierProvider<MeshProvider>.value(value: meshProvider),
                  // ChatService intentionally omitted to verify exception prevention
                ],
                child: const MaterialApp(
                  home: ChatScreen(),
                ),
              ),
            );
          } finally {
            FlutterError.onError = originalOnError;
          }

          expect(caughtError?.exception, isA<ProviderNotFoundException>());
        },
      );
    });

    // =========================================================================
    // Test D: Live Map Zero-Fake-Data Integrity
    // =========================================================================
    group('Test D: Live Map Zero-Fake-Data Integrity', () {
      testWidgets(
        'D1: LiveMapScreen displays 0 fake devices and 0 fake SOS cards when SQLite is empty',
        (WidgetTester tester) async {
          final themeProvider = ThemeProvider();
          final meshProvider = MeshProvider();
          meshProvider.stopScan();
          final emergencyProvider = EmergencyReportProvider();

          await tester.pumpWidget(
            _buildTestApp(
              child: const LiveMapScreen(),
              themeProvider: themeProvider,
              meshProvider: meshProvider,
              emergencyReportProvider: emergencyProvider,
            ),
          );

          // Pump frames without pumpAndSettle (LiveMap has repeating pulse animation)
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));

          // 1. Shows authentic 'No Active Distress Alerts Nearby'
          expect(find.text('No Active Distress Alerts Nearby'), findsOneWidget);
          expect(find.text('All clear in local offline mesh range'), findsOneWidget);

          // 2. Zero fake devices in mesh provider
          expect(meshProvider.nearbyDevices, isEmpty);

          // 3. Zero fake SOS cards in active incident view
          expect(emergencyProvider.reports, isEmpty);
          expect(find.textContaining('CRITICAL EMERGENCY'), findsNothing);
          expect(find.textContaining('SOS #'), findsNothing);
        },
      );
    });

    // =========================================================================
    // Test E: Three-Tier Theme Switching
    // =========================================================================
    group('Test E: Three-Tier Theme Switching', () {
      test(
        'E1: ThemeProvider switches between Light (#FFFCEB), Dark (#0B1220), and OLED Low-Power (#000000)',
        () async {
          final themeProvider = ThemeProvider();

          // 1. Light Mode: #FFFCEB
          await themeProvider.setThemeMode(AppThemeMode.light);
          expect(themeProvider.isLight, isTrue);
          expect(themeProvider.isDark, isFalse);
          expect(themeProvider.isLowPower, isFalse);
          expect(themeProvider.bg, equals(AppTokens.lightBg));
          expect(themeProvider.bg.toARGB32(), equals(0xFFFFFCEB),
              reason: 'Light theme must be exactly #FFFCEB');

          // 2. Dark Mode: #0B1220
          await themeProvider.setThemeMode(AppThemeMode.dark);
          expect(themeProvider.isLight, isFalse);
          expect(themeProvider.isDark, isTrue);
          expect(themeProvider.isLowPower, isFalse);
          expect(themeProvider.bg, equals(AppTokens.darkBg));
          expect(themeProvider.bg.toARGB32(), equals(0xFF0B1220),
              reason: 'Dark theme must be exactly #0B1220 (Night Navy)');

          // 3. OLED Low-Power Mode: #000000 True Black
          await themeProvider.setLowPower(true);
          expect(themeProvider.isLowPower, isTrue);
          expect(themeProvider.isDark, isTrue);
          expect(themeProvider.bg, equals(AppTokens.oledBg));
          expect(themeProvider.bg.toARGB32(), equals(0xFF000000),
              reason: 'OLED Low-Power theme must be true #000000 black to shut off pixels');

          // 4. Return to Dark Mode
          await themeProvider.setLowPower(false);
          expect(themeProvider.isLowPower, isFalse);
          expect(themeProvider.bg, equals(AppTokens.darkBg));
        },
      );

      testWidgets(
        'E2: Widget tree reacts dynamically to Three-Tier Theme switches',
        (WidgetTester tester) async {
          final themeProvider = ThemeProvider();

          await tester.pumpWidget(
            ChangeNotifierProvider<ThemeProvider>.value(
              value: themeProvider,
              child: Consumer<ThemeProvider>(
                builder: (context, theme, _) {
                  return MaterialApp(
                    home: Scaffold(
                      backgroundColor: theme.bg,
                      body: Text(
                        'Active Mode: ${theme.isLowPower ? 'OLED' : (theme.isLight ? 'LIGHT' : 'DARK')}',
                        style: TextStyle(color: theme.text),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
          await tester.pump();

          // Default Dark
          expect(find.text('Active Mode: DARK'), findsOneWidget);
          var scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
          expect(scaffold.backgroundColor, equals(const Color(0xFF0B1220)));

          // Switch to Light
          await themeProvider.setThemeMode(AppThemeMode.light);
          await tester.pump();
          expect(find.text('Active Mode: LIGHT'), findsOneWidget);
          scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
          expect(scaffold.backgroundColor, equals(const Color(0xFFFFFCEB)));

          // Switch to OLED Low-Power
          await themeProvider.setLowPower(true);
          await tester.pump();
          expect(find.text('Active Mode: OLED'), findsOneWidget);
          scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
          expect(scaffold.backgroundColor, equals(const Color(0xFF000000)));
        },
      );
    });
  });
}
