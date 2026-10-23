import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rakshanet_mobile/providers/mesh_provider.dart';
import 'package:rakshanet_mobile/providers/telemetry_provider.dart';
import 'package:rakshanet_mobile/providers/theme_provider.dart';
import 'package:rakshanet_mobile/screens/tools/ai_assistant_screen.dart';
import 'package:rakshanet_mobile/screens/tabs/ai_help_tab.dart';
import 'package:rakshanet_mobile/services/ai/hybrid_ai_service.dart';

Widget _buildTestApp({required Widget child}) {
  final mesh = MeshProvider()..stopScan();
  final telemetry = TelemetryProvider()..stopPolling();
  final theme = ThemeProvider();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeProvider>.value(value: theme),
      ChangeNotifierProvider<TelemetryProvider>.value(value: telemetry),
      ChangeNotifierProvider<MeshProvider>.value(value: mesh),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    HybridAiService.instance.forceOfflineMode = true;
  });

  group('Offline AI Assistant UI & Disaster Model Tests', () {
    testWidgets('1. AiAssistantScreen mounts with header and categorized suggestion filters',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp(child: const AiAssistantScreen()));
      await tester.pumpAndSettle();

      // Verify Screen Title and Engine Indicators
      expect(find.text('AI Assistant'), findsOneWidget);
      expect(find.text('Forced Offline • On-Device'), findsOneWidget);

      // Verify Category Filter Tabs
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Medical'), findsOneWidget);
      expect(find.text('Hazards'), findsOneWidget);
      expect(find.text('Rescue'), findsOneWidget);
      expect(find.text('CBRN'), findsOneWidget);
      expect(find.text('Survival'), findsOneWidget);

      // Verify Default Suggestions visible
      expect(find.text('CPR Protocol'), findsOneWidget);
      expect(find.text('Severe Bleeding'), findsOneWidget);
    });

    testWidgets('2. Category Filter Tabs switch suggestions dynamically',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp(child: const AiAssistantScreen()));
      await tester.pumpAndSettle();

      // Tap 'CBRN' filter tab
      await tester.tap(find.text('CBRN'));
      await tester.pumpAndSettle();

      // Verify CBRN suggestions appear
      expect(find.text('CBRN Decontamination'), findsOneWidget);
      expect(find.text('Toxic Gas Shelter'), findsOneWidget);
      expect(find.text('Nuclear Fallout (7:10)'), findsOneWidget);

      // Tap 'Rescue' filter tab
      await tester.tap(find.text('Rescue'));
      await tester.pumpAndSettle();

      // Verify Rescue suggestions appear
      expect(find.text('START Triage'), findsOneWidget);
      expect(find.text('Rubble Tapping'), findsOneWidget);
      expect(find.text('Swiftwater Rescue'), findsOneWidget);
    });

    testWidgets('3. Submitting START Triage query produces structured card with CRITICAL badge',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp(child: const AiAssistantScreen()));
      await tester.pumpAndSettle();

      // Enter query
      final inputFinder = find.byType(TextField);
      expect(inputFinder, findsOneWidget);
      await tester.enterText(inputFinder, 'How to do mass casualty triage?');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // Verify response card rendered with CRITICAL EMERGENCY PROTOCOL badge
      expect(find.text('CRITICAL EMERGENCY PROTOCOL'), findsOneWidget);
      expect(find.textContaining('START Mass Casualty Triage'), findsOneWidget);

      // Verify step indicators
      expect(find.text('1'), findsWidgets);
      expect(find.text('2'), findsWidgets);

      // Verify Copy Button exists
      expect(find.byIcon(Icons.copy_rounded), findsWidgets);
    });

    testWidgets('4. Submitting Water Still query produces structured card with HIGH PRIORITY badge',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp(child: const AiAssistantScreen()));
      await tester.pumpAndSettle();

      // Enter solar still query
      final inputFinder = find.byType(TextField);
      await tester.enterText(inputFinder, 'How to build a solar still in drought?');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // Verify solar still response rendered
      expect(find.textContaining('Solar Still'), findsWidgets);
      expect(find.text('HIGH PRIORITY PROTOCOL'), findsWidgets);
    });

    testWidgets('5. AiHelpTab renders live on-device SLM with real knowledge response',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp(child: const Scaffold(body: AiHelpTab())));
      await tester.pumpAndSettle();

      // Header indicates on-device SLM with 69+ models
      expect(find.textContaining('On-Device Offline SLM'), findsOneWidget);
      expect(find.text('0 KB DATA'), findsOneWidget);

      // Suggestion chips
      expect(find.text('START Triage Protocol'), findsOneWidget);
      expect(find.text('CBRN Decontamination'), findsOneWidget);

      // Tap 'CBRN Decontamination' chip
      await tester.tap(find.text('CBRN Decontamination'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // Real offline SLM returns response
      expect(find.textContaining('CBRN Full Decontamination'), findsOneWidget);
      expect(find.text('CRITICAL PROTOCOL'), findsOneWidget);
    });
  });
}
