import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rakshanet_mobile/main.dart';
import 'package:rakshanet_mobile/providers/theme_provider.dart';
import 'package:rakshanet_mobile/providers/profile_provider.dart';
import 'package:rakshanet_mobile/providers/user_profile_provider.dart';
import 'package:rakshanet_mobile/providers/mesh_provider.dart';
import 'package:rakshanet_mobile/providers/telemetry_provider.dart';
import 'package:rakshanet_mobile/providers/chat_provider.dart';
import 'package:rakshanet_mobile/providers/device_status_provider.dart';
import 'package:rakshanet_mobile/providers/emergency_report_provider.dart';
import 'package:rakshanet_mobile/providers/missing_persons_provider.dart';
import 'package:rakshanet_mobile/providers/sos_provider.dart';
import 'package:rakshanet_mobile/services/chat_service.dart';
import 'package:rakshanet_mobile/services/group_service.dart';
import 'package:rakshanet_mobile/services/user_auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('RakshaNet App smoke test and splash screen display', (WidgetTester tester) async {
    final meshProvider = MeshProvider()..stopScan();
    final telemetryProvider = TelemetryProvider()..stopPolling();
    final chatService = ChatService()..stopTimers();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => ProfileProvider()),
          ChangeNotifierProvider(create: (_) => UserProfileProvider()),
          ChangeNotifierProvider<MeshProvider>.value(value: meshProvider),
          ChangeNotifierProvider<TelemetryProvider>.value(value: telemetryProvider),
          ChangeNotifierProvider(create: (_) => ChatProvider()),
          ChangeNotifierProvider<ChatService>.value(value: chatService),
          ChangeNotifierProvider(create: (_) => GroupService()),
          ChangeNotifierProvider(create: (_) => UserAuthService.instance),
          ChangeNotifierProvider(create: (_) => DeviceStatusProvider()),
          ChangeNotifierProvider(create: (_) => EmergencyReportProvider()),
          ChangeNotifierProvider(create: (_) => MissingPersonsProvider()),
          ChangeNotifierProvider(create: (_) => SosProvider.instance),
        ],
        child: const RakshaNetApp(),
      ),
    );
    await tester.pump();

    // Verify MaterialApp is rendered
    expect(find.byType(MaterialApp), findsOneWidget);

    // Drain the splash sequence timers and navigation transition
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  });
}
