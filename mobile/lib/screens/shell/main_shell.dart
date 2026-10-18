import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/signal_rescue_bottom_nav.dart';
import '../chat/chat_screen.dart';
import '../home/emergency_report_screen.dart';
import '../home/home_screen.dart';
import '../tools/ai_assistant_screen.dart';
import '../tools/live_map_screen.dart';
import '../tools/safety_tools_screen.dart';

/// Main Navigation Shell for RakshaNet Mobile
/// Hosts the 5 primary tabs with the Floating Rounded Capsule Bottom Navigation Dock:
/// 0: Chat (Offline Mesh Chat)
/// 1: Map (Live Mesh Vector Map)
/// 2: SOS (Home / SOS Central Beacon)
/// 3: Tools (Safety & Survival Tools)
/// 4: AI (Offline AI Survival Assistant)
class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 2});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openEmergencyReport() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const EmergencyReportScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.bg,
      extendBody: false,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const ChatScreen(),
          const LiveMapScreen(),
          HomeScreen(onSelectTab: _onTabTapped),
          const SafetyToolsScreen(),
          const AiAssistantScreen(),
        ],
      ),
      bottomNavigationBar: SignalRescueBottomNav(
        currentIndex: _currentIndex,
        onTabSelected: _onTabTapped,
        onSosHoldTriggered: _openEmergencyReport,
      ),
    );
  }
}
