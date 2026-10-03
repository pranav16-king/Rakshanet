import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/mesh_provider.dart';
import '../../providers/telemetry_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/app_bar_actions.dart';
import '../../widgets/beacon_sos_button.dart';
import '../../widgets/status_card.dart';
import '../../widgets/offline_banner.dart';
import '../settings/settings_screen.dart';
import 'emergency_report_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onOpenSettings;

  const HomeScreen({
    super.key,
    this.onOpenSettings,
  });

  void _navigateToEmergencyReport(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const EmergencyReportScreen(),
        transitionsBuilder: (_, a, _, c) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: c,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final meshProvider = Provider.of<MeshProvider>(context);
    final telemetryProvider = Provider.of<TelemetryProvider>(context);

    // Dynamic telemetry from providers - never hardcoded strings
    final int peerCount = meshProvider.nearbyDevices.isNotEmpty
        ? meshProvider.nearbyDevices.length
        : meshProvider.connectedPeerCount;
    final bool isMeshActive = meshProvider.isMeshActive;
    final bool isOnline = telemetryProvider.isOnline;
    final bool hasGps = telemetryProvider.hasGpsFix;
    final int batteryLevel = telemetryProvider.batteryLevel;

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        backgroundColor: theme.bg,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/rakshanet_logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppTokens.signalYellow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.radar_rounded, color: AppTokens.nightNavy, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'SignalRescue AI',
              style: TextStyle(
                color: theme.isLight ? AppTokens.lightPrimaryInk : AppTokens.signalYellow,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        actions: [
          // Theme changes button (Light / Dark / Low-Power OLED)
          const ThemeToggleButton(),

          // Profile icon button (navigates to Screen 13 Profile & Volunteer)
          const ProfileAvatarButton(),

          // Settings button
          IconButton(
            icon: Icon(Icons.settings_outlined, color: theme.text, size: 24),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // 4 Dynamic Status Cards Grid (2x2) matching Screen 3 mockup
              Row(
                children: [
                  Expanded(
                    child: StatusCard(
                      icon: isMeshActive ? Icons.hub_rounded : Icons.hub_outlined,
                      title: 'Mesh Connected',
                      value: isMeshActive
                          ? (peerCount > 0 ? '$peerCount Devices' : '0 Devices')
                          : 'Inactive',
                      accentColor: isMeshActive && peerCount > 0 ? AppTokens.beaconTeal : AppTokens.darkTextMuted,
                      onTap: () => meshProvider.startScan(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatusCard(
                      icon: isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                      title: 'Internet',
                      value: isOnline ? 'Online' : 'Offline',
                      accentColor: isOnline ? AppTokens.darkSuccess : AppTokens.sosRed,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: StatusCard(
                      icon: hasGps ? Icons.location_on_rounded : Icons.location_off_rounded,
                      title: 'GPS',
                      value: hasGps ? 'Active' : 'Offline',
                      accentColor: hasGps ? AppTokens.darkSuccess : AppTokens.darkTextMuted,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatusCard(
                      icon: batteryLevel <= 20
                          ? Icons.battery_alert_rounded
                          : Icons.battery_charging_full_rounded,
                      title: 'Battery',
                      value: '$batteryLevel%',
                      accentColor: batteryLevel <= 20 ? AppTokens.sosRed : AppTokens.signalYellow,
                      onTap: () {},
                    ),
                  ),
                ],
              ),

              // Clean empty state if no peers detected yet
              if (peerCount == 0) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    border: Border.all(color: theme.border),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.isLight
                              ? AppTokens.lightPrimaryInk
                              : AppTokens.signalYellow,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No nearby mesh peers detected yet. Scanning...',
                          style: TextStyle(
                            color: theme.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(flex: 1),

              // Central Large Circular SOS Beacon Button (176dp, 3s hold) matching Screen 3 mockup
              BeaconSosButton(
                size: AppTokens.sosHomeSize,
                onTriggered: () => _navigateToEmergencyReport(context),
              ),

              const Spacer(flex: 1),

              // Offline Warning Banner matching Screen 3 mockup (dynamic based on online status)
              if (telemetryProvider.showOfflineBanner)
                const OfflineBanner(),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
