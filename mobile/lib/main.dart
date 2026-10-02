import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/mesh_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/user_profile_provider.dart';
import 'providers/device_status_provider.dart';
import 'providers/emergency_report_provider.dart';
import 'providers/telemetry_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/profile/profile_setup_screen.dart';
import 'screens/shell/main_shell.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/tools/shelters_screen.dart';
import 'screens/tools/missing_person_screen.dart';
import 'screens/tools/safety_tools_screen.dart';
import 'screens/tools/live_map_screen.dart';
import 'screens/tools/ai_assistant_screen.dart';
import 'screens/settings/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => MeshProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => DeviceStatusProvider()),
        ChangeNotifierProvider(create: (_) => EmergencyReportProvider()),
        ChangeNotifierProvider(create: (_) => TelemetryProvider()),
      ],
      child: const RakshaNetApp(),
    ),
  );
}

class RakshaNetApp extends StatelessWidget {
  const RakshaNetApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'RakshaNet',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData,
      home: const SplashScreen(),
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/profile-setup': (_) => const ProfileSetupScreen(),
        '/main': (_) => const MainShell(),
        '/profile': (_) => const ProfileScreen(),
        '/shelters': (_) => const SheltersScreen(),
        '/missing-person': (_) => const MissingPersonScreen(),
        '/safety-tools': (_) => const SafetyToolsScreen(),
        '/live-map': (_) => const LiveMapScreen(),
        '/ai-assistant': (_) => const AiAssistantScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
