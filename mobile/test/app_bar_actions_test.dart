import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rakshanet_mobile/providers/theme_provider.dart';
import 'package:rakshanet_mobile/providers/profile_provider.dart';
import 'package:rakshanet_mobile/providers/mesh_provider.dart';
import 'package:rakshanet_mobile/providers/telemetry_provider.dart';
import 'package:rakshanet_mobile/widgets/app_bar_actions.dart';
import 'package:rakshanet_mobile/screens/home/home_screen.dart';
import 'package:rakshanet_mobile/screens/profile/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppBar Actions & Theme/Profile Integration Tests', () {
    testWidgets('HomeScreen mounts ThemeToggleButton and ProfileAvatarButton in actions',
        (WidgetTester tester) async {
      final themeProvider = ThemeProvider();
      final profileProvider = ProfileProvider();
      final meshProvider = MeshProvider();
      final telemetryProvider = TelemetryProvider();
      telemetryProvider.stopPolling();
      meshProvider.stopScan();

      addTearDown(() {
        telemetryProvider.dispose();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
            ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
            ChangeNotifierProvider<MeshProvider>.value(value: meshProvider),
            ChangeNotifierProvider<TelemetryProvider>.value(value: telemetryProvider),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();

      // Verify buttons exist in HomeScreen top bar
      expect(find.byType(ThemeToggleButton), findsOneWidget);
      expect(find.byType(ProfileAvatarButton), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('Tapping ThemeToggleButton opens theme picker modal and switches theme',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final themeProvider = ThemeProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>.value(
          value: themeProvider,
          child: const MaterialApp(
            home: Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(56),
                child: Row(
                  children: [
                    ThemeToggleButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap ThemeToggleButton
      await tester.tap(find.byType(ThemeToggleButton));
      await tester.pumpAndSettle();

      // Modal bottom sheet appears with theme options
      expect(find.text('Choose Theme Mode'), findsOneWidget);
      expect(find.text('Light Theme'), findsOneWidget);
      expect(find.text('Dark Theme'), findsOneWidget);
      expect(find.text('Low-Power OLED (Pure Black)'), findsOneWidget);

      // Select Light Theme
      await tester.tap(find.text('Light Theme'));
      await tester.pumpAndSettle();

      expect(themeProvider.isLight, isTrue);
    });

    testWidgets('Tapping ProfileAvatarButton pushes ProfileScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final themeProvider = ThemeProvider();
      final profileProvider = ProfileProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
            ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(56),
                child: Row(
                  children: [
                    ProfileAvatarButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap ProfileAvatarButton
      await tester.tap(find.byType(ProfileAvatarButton));
      await tester.pumpAndSettle();

      // ProfileScreen should be pushed and visible
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('Profile & Volunteer'), findsOneWidget);
    });
  });
}
