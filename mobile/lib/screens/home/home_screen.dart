import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/mesh_provider.dart';
import '../../providers/telemetry_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/app_bar_actions.dart';
import '../../widgets/beacon_sos_button.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/status_card.dart';
import '../settings/settings_screen.dart';
import 'emergency_report_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onOpenSettings;
  final ValueChanged<int>? onSelectTab;

  const HomeScreen({
    super.key,
    this.onOpenSettings,
    this.onSelectTab,
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

    // Dynamic real-time telemetry from providers - zero hardcoded fake data
    final int peerCount = meshProvider.connectedPeerCount;
    final bool isMeshActive = meshProvider.isMeshActive;
    final bool isScanning = meshProvider.isScanning;
    final bool isOnline = telemetryProvider.isOnline;
    final bool hasGps = telemetryProvider.hasGpsFix;
    final int batteryLevel = telemetryProvider.batteryLevel;

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        backgroundColor: theme.bg,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
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
                  child: const Icon(
                    Icons.radar_rounded,
                    color: AppTokens.nightNavy,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'SignalRescue AI',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.isLight
                      ? AppTokens.lightPrimaryInk
                      : AppTokens.signalYellow,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // 1. Theme / Low-Power Battery Saver Toggle Button
          const ThemeToggleButton(),

          // 2. User Profile Avatar Button (with initial & blood group badge)
          const ProfileAvatarButton(),

          // 3. Settings Button
          IconButton(
            icon: Icon(Icons.settings_outlined, color: theme.text, size: 24),
            tooltip: 'Settings',
            onPressed: () {
              if (onOpenSettings != null) {
                onOpenSettings!();
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              }
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive SOS size so the red SOS button always fits completely on screen
            final double sosButtonSize =
                constraints.maxHeight < 560 ? 152.0 : AppTokens.sosHomeSize;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: [
                  // 1. 4 Dynamic Status Cards Grid (2x2) with non-truncated titles
                  Row(
                    children: [
                      Expanded(
                        child: StatusCard(
                          icon: isMeshActive
                              ? Icons.hub_rounded
                              : Icons.hub_outlined,
                          title: 'Mesh Network',
                          value: isMeshActive
                              ? (peerCount == 1
                                  ? '1 Device'
                                  : '$peerCount Devices')
                              : 'Inactive',
                          accentColor: isMeshActive && peerCount > 0
                              ? AppTokens.beaconTeal
                              : AppTokens.darkTextMuted,
                          onTap: () => meshProvider.startScan(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatusCard(
                          icon: isOnline
                              ? Icons.wifi_rounded
                              : Icons.wifi_off_rounded,
                          title: 'Internet',
                          value: isOnline ? 'Online' : 'Offline',
                          accentColor: isOnline
                              ? AppTokens.darkSuccess
                              : AppTokens.sosRed,
                          onTap: () => telemetryProvider.refreshTelemetry(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: StatusCard(
                          icon: hasGps
                              ? Icons.location_on_rounded
                              : Icons.location_off_rounded,
                          title: 'GPS',
                          value: hasGps ? 'Active' : 'Offline',
                          accentColor: hasGps
                              ? AppTokens.darkSuccess
                              : AppTokens.darkTextMuted,
                          onTap: () => telemetryProvider.refreshTelemetry(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatusCard(
                          icon: batteryLevel <= 20
                              ? Icons.battery_alert_rounded
                              : Icons.battery_charging_full_rounded,
                          title: 'Battery',
                          value: batteryLevel > 0 ? '$batteryLevel%' : '--%',
                          accentColor: batteryLevel <= 20
                              ? AppTokens.sosRed
                              : AppTokens.signalYellow,
                          onTap: () => telemetryProvider.refreshTelemetry(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 2. Mesh Peer Discovery Status Banner with tap-to-scan action
                  InkWell(
                    onTap: () => meshProvider.startScan(),
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: theme.surface,
                        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                        border: Border.all(
                          color: peerCount > 0
                              ? AppTokens.beaconTeal.withValues(alpha: 0.45)
                              : theme.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (peerCount == 0 && isScanning)
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.isLight
                                    ? AppTokens.lightPrimaryInk
                                    : AppTokens.signalYellow,
                              ),
                            )
                          else
                            Icon(
                              peerCount > 0
                                  ? Icons.check_circle_rounded
                                  : Icons.radar_rounded,
                              size: 16,
                              color: peerCount > 0
                                  ? AppTokens.darkSuccess
                                  : AppTokens.signalYellow,
                            ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              peerCount > 0
                                  ? 'Connected to $peerCount nearby mesh peer(s). Relay active.'
                                  : 'No nearby mesh peers detected yet. Scanning...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: peerCount > 0
                                    ? theme.text
                                    : theme.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Scan',
                            style: TextStyle(
                              color: theme.isLight
                                  ? AppTokens.lightPrimaryInk
                                  : AppTokens.beaconTeal,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 1),

                  // 3. Subtle Readiness Label Above Red SOS Button
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTokens.sosRed.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                      border: Border.all(
                        color: AppTokens.sosRed.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppTokens.sosRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'EMERGENCY SOS BEACON READY',
                          style: TextStyle(
                            color: theme.isLight
                                ? AppTokens.sosRed
                                : const Color(0xFFFF8A80),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 4. Central Large Circular Red SOS Beacon Button (176dp, 3s hold)
                  BeaconSosButton(
                    size: sosButtonSize,
                    onTriggered: () => _navigateToEmergencyReport(context),
                  ),

                  const SizedBox(height: 6),

                  // 5. Compact Broadcast Channel Status Row Below SOS Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildChannelChip(
                        label: 'Mesh Radio',
                        isActive: isMeshActive,
                        theme: theme,
                      ),
                      const SizedBox(width: 8),
                      _buildChannelChip(
                        label: 'Internet',
                        isActive: isOnline,
                        theme: theme,
                      ),
                      const SizedBox(width: 8),
                      _buildChannelChip(
                        label: 'GPS Lock',
                        isActive: hasGps,
                        theme: theme,
                      ),
                    ],
                  ),

                  const Spacer(flex: 1),

                  // 6. Offline Warning Banner when internet is disconnected
                  if (telemetryProvider.showOfflineBanner)
                    const OfflineBanner(),

                  const SizedBox(height: 6),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildChannelChip({
    required String label,
    required bool isActive,
    required ThemeProvider theme,
  }) {
    final color = isActive ? AppTokens.darkSuccess : theme.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        border: Border.all(
          color: isActive
              ? AppTokens.darkSuccess.withValues(alpha: 0.4)
              : theme.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: isActive ? theme.text : theme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
