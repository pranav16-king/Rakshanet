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
import 'package:rakshanet_mobile/providers/profile_provider.dart';
import 'package:rakshanet_mobile/providers/telemetry_provider.dart';
import 'package:rakshanet_mobile/providers/theme_provider.dart';
import 'package:rakshanet_mobile/providers/user_profile_provider.dart';
import 'package:rakshanet_mobile/screens/chat/chat_screen.dart';
import 'package:rakshanet_mobile/screens/home/emergency_report_screen.dart';
import 'package:rakshanet_mobile/screens/onboarding/profile_setup_screen.dart' as onboarding;
import 'package:rakshanet_mobile/screens/profile/profile_setup_screen.dart' as profile_screen;
import 'package:rakshanet_mobile/screens/tools/live_map_screen.dart';
import 'package:rakshanet_mobile/screens/tools/missing_person_screen.dart';
import 'package:rakshanet_mobile/services/chat_service.dart';
import 'package:rakshanet_mobile/theme/app_theme.dart';
import 'package:rakshanet_mobile/theme/app_tokens.dart';

Widget _buildTestApp({
  required Widget child,
  ThemeProvider? themeProvider,
  ProfileProvider? profileProvider,
  MeshProvider? meshProvider,
  ChatProvider? chatProvider,
  ChatService? chatService,
  EmergencyReportProvider? emergencyReportProvider,
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
        value: chatService ?? ChatService(),
      ),
      ChangeNotifierProvider<EmergencyReportProvider>.value(
        value: emergencyReportProvider ?? EmergencyReportProvider(),
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

          // All TextFormFields must initialize with empty text
          final textFormFields = tester.widgetList<TextFormField>(
            find.byType(TextFormField),
          );
          expect(textFormFields.length, equals(3),
              reason: 'Should contain Name, Phone, and Medical Notes fields');

          for (final field in textFormFields) {
            expect(field.controller?.text, isEmpty,
                reason: 'Field controller must initialize empty ("")');
          }

          // Verify hintText is displayed, not pre-filled text
          expect(find.text('e.g. Amit Sharma'), findsOneWidget);
          expect(find.text('e.g. +91 98765 43210'), findsOneWidget);
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

          final textFormFields = tester.widgetList<TextFormField>(
            find.byType(TextFormField),
          );
          expect(textFormFields.length, equals(3));

          for (final field in textFormFields) {
            expect(field.controller?.text, isEmpty,
                reason: 'Field controller must initialize empty ("")');
          }

          expect(find.text('e.g. Amit Sharma'), findsOneWidget);
          expect(find.text('e.g. +91 98765 43210'), findsOneWidget);
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
        'A5: MissingPersonScreen all controllers initialize empty',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              child: const MissingPersonScreen(),
            ),
          );
          await tester.pump();

          final textFormFields = tester.widgetList<TextFormField>(
            find.byType(TextFormField),
          );
          expect(textFormFields.length, equals(4),
              reason: 'Must contain Name, Age, Description, and Location');

          for (final field in textFormFields) {
            expect(field.controller?.text, isEmpty,
                reason: 'Missing person controller must initialize empty ("")');
          }

          // Time field placeholder must show 'Select time (tap to set)'
          expect(find.text('Select time (tap to set)'), findsOneWidget);
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

          // Tap Join Mesh & Continue without filling any inputs
          final submitButton = find.widgetWithText(ElevatedButton, 'Join Mesh & Continue');
          expect(submitButton, findsOneWidget);
          await tester.ensureVisible(submitButton);
          await tester.tap(submitButton);
          await tester.pump();

          // Descriptive warnings must be displayed
          expect(find.text('Please enter your name'), findsOneWidget);
          expect(find.text('Please enter your phone number'), findsOneWidget);

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

          // Find the 3 TextFormFields
          final textFormFields = find.byType(TextFormField);
          expect(textFormFields, findsNWidgets(3));

          // 1. Enter Real Name
          await tester.enterText(textFormFields.at(0), 'Dr. Priya Sharma');
          // 2. Enter Real Phone
          await tester.enterText(textFormFields.at(1), '+91 9811223344');
          // 3. Enter Real Medical Notes
          await tester.enterText(textFormFields.at(2), 'Trauma First-aid Certified');
          await tester.pump();

          // Tap Join Mesh & Continue
          final submitButton = find.widgetWithText(ElevatedButton, 'Join Mesh & Continue');
          await tester.ensureVisible(submitButton);
          await tester.tap(submitButton);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          // State updated
          expect(profileProvider.isRegistered, isTrue);
          expect(profileProvider.profile.name, equals('Dr. Priya Sharma'));
          expect(profileProvider.profile.emergencyContact, equals('+91 9811223344'));
          expect(profileProvider.profile.medicalNotes, equals('Trauma First-aid Certified'));
          expect(profileProvider.profile.deviceId.startsWith('SR-'), isTrue);

          // Persisted to SQLite via ProfileRepository
          final profileRepo = ProfileRepository();
          final savedProfile = await profileRepo.getProfile();
          expect(savedProfile, isNotNull);
          expect(savedProfile?.name, equals('Dr. Priya Sharma'));
          expect(savedProfile?.emergencyContact, equals('+91 9811223344'));
        },
      );

      testWidgets(
        'B3: MissingPersonScreen validation fails on empty, and real submission persists to SQLite',
        (WidgetTester tester) async {
          tester.view.physicalSize = const Size(800, 1400);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            _buildTestApp(
              child: const MissingPersonScreen(),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));

          // Tap Submit Report with empty fields
          final submitButton = find.widgetWithText(ElevatedButton, 'Submit Report');
          await tester.ensureVisible(submitButton);
          await tester.tap(submitButton);
          await tester.pump();

          // Validation warnings must trigger
          expect(find.text('Required'), findsNWidgets(3)); // Name, Age, Description
          expect(find.text('Location is required'), findsOneWidget);

          // Now enter real report data
          final fields = find.byType(TextFormField);
          await tester.enterText(fields.at(0), 'Aarav Kumar');
          await tester.enterText(fields.at(1), '10');
          await tester.enterText(fields.at(2), 'Red t-shirt, blue cap');
          await tester.enterText(fields.at(3), 'Sector 4 Shelter Grounds');
          await tester.pump();

          // Submit real data
          await tester.ensureVisible(submitButton);
          await tester.tap(submitButton);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          // Success modal sheet appears
          expect(find.text('Missing Person Report Saved to SQLite'), findsOneWidget);
          expect(
            find.textContaining('Report for "Aarav Kumar" committed to offline database.'),
            findsOneWidget,
          );

          // Verify SQLite persistence
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

          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
                ChangeNotifierProvider<ChatService>.value(value: chatService),
              ],
              child: const MaterialApp(
                home: ChatScreen(),
              ),
            ),
          );
          await tester.pump();

          // Verify ChatScreen renders cleanly without throwing ProviderNotFoundException
          expect(find.byType(ChatScreen), findsOneWidget);
          expect(find.text('Community Chat'), findsOneWidget);
          expect(find.text('Type a message...'), findsOneWidget);
        },
      );

      testWidgets(
        'C2: ChatScreen throws ProviderNotFoundException when ChatService is omitted',
        (WidgetTester tester) async {
          final themeProvider = ThemeProvider();

          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
                // ChatService intentionally omitted to verify exception prevention
              ],
              child: const MaterialApp(
                home: ChatScreen(),
              ),
            ),
          );

          final dynamic error = tester.takeException();
          expect(error, isNotNull);
          expect(error, isA<ProviderNotFoundException>());
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

          // 1. Shows authentic 'No active distress alerts nearby'
          expect(find.text('No active distress alerts nearby'), findsOneWidget);
          expect(find.text('All clear in local mesh range'), findsOneWidget);

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
