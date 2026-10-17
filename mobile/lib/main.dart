import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/theme_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/mesh_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/user_profile_provider.dart';
import 'providers/device_status_provider.dart';
import 'providers/emergency_report_provider.dart';
import 'providers/missing_persons_provider.dart';
import 'providers/sos_provider.dart';
import 'providers/telemetry_provider.dart';
import 'services/chat_service.dart';
import 'services/device_identity_service.dart';
import 'widgets/global_sos_overlay.dart';
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

import 'services/group_service.dart';
import 'services/user_auth_service.dart';
import 'screens/chat/create_group_screen.dart';
import 'screens/chat/pending_invites_screen.dart';

import 'screens/tools/sos_screen.dart';
import 'services/location/location_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DeviceIdentityService.instance.initialize();
  unawaited(LocationService.instance.initialize());
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => MeshProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ChatService()),
        ChangeNotifierProvider(create: (_) => GroupService()),
        ChangeNotifierProvider(create: (_) => UserAuthService.instance),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => DeviceStatusProvider()),
        ChangeNotifierProvider(create: (_) => EmergencyReportProvider()),
        ChangeNotifierProvider(create: (_) => MissingPersonsProvider()),
        ChangeNotifierProvider(create: (_) => SosProvider.instance),
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
      builder: (context, child) => GlobalSosOverlay(
        child: child ?? const SizedBox.shrink(),
      ),
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
        '/sos': (_) => const SosScreen(),
        '/create-group': (_) => const CreateGroupScreen(),
        '/pending-invites': (_) => const PendingInvitesScreen(),
      },
    );
  }
}
