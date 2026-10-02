import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_tokens.dart';
import '../chat/chat_screen.dart';
import '../home/home_screen.dart';
import '../tools/ai_assistant_screen.dart';
import '../tools/live_map_screen.dart';
import '../tools/safety_tools_screen.dart';

/// Main Navigation Shell for RakshaNet Mobile
/// Hosts the 5 primary tabs:
/// 0: Chat (Offline Mesh Chat, Screen 5)
/// 1: Map (Live Mesh Vector Map, Screen 6)
/// 2: SOS (Home / SOS Central Beacon, Screen 3)
/// 3: Nearby/Tools (Safety Tools 2x3 grid, Shelters & Missing Person, Screen 11)
/// 4: AI (Offline AI Survival Assistant, Screen 7)
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

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final isLowPower = theme.isLowPower;

    final navBg = isLowPower ? AppTokens.oledBg : theme.surface;
    final navBorder = isLowPower ? AppTokens.oledBorder : theme.border;

    return Scaffold(
      backgroundColor: theme.bg,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          ChatScreen(),
          LiveMapScreen(),
          HomeScreen(),
          SafetyToolsScreen(),
          AiAssistantScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        height: AppTokens.tabBarHeight + MediaQuery.of(context).padding.bottom,
        decoration: BoxDecoration(
          color: navBg,
          border: Border(
            top: BorderSide(color: navBorder, width: 1),
          ),
          boxShadow: [
            if (!isLowPower)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.chat_bubble_outline_rounded,
                activeIcon: Icons.chat_bubble_rounded,
                label: 'Chat',
                theme: theme,
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.map_outlined,
                activeIcon: Icons.map_rounded,
                label: 'Map',
                theme: theme,
              ),
              _buildSosNavItem(
                index: 2,
                theme: theme,
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.grid_view_rounded,
                activeIcon: Icons.grid_view_rounded,
                label: 'Nearby/Tools',
                theme: theme,
              ),
              _buildNavItem(
                index: 4,
                icon: Icons.auto_awesome_outlined,
                activeIcon: Icons.auto_awesome_rounded,
                label: 'AI',
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required ThemeProvider theme,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppTokens.signalYellow : theme.textMuted;

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppTokens.touchMin),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTokens.signalYellow.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSosNavItem({
    required int index,
    required ThemeProvider theme,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppTokens.touchMin),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? AppTokens.sosRed : AppTokens.sosRed.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTokens.sosRed,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: isSelected ? Colors.white : AppTokens.sosRed,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'SOS',
                style: TextStyle(
                  color: isSelected ? AppTokens.sosRed : theme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
