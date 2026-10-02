import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/mesh_provider.dart';
import '../../providers/telemetry_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/beacon_sos_button.dart';
import '../../widgets/status_card.dart';
import '../../widgets/offline_banner.dart';
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

  void _showSettingsDialog(BuildContext context) {
    final profileProvider = Provider.of<UserProfileProvider>(context, listen: false);
    final telemetryProvider = Provider.of<TelemetryProvider>(context, listen: false);
    final meshProvider = Provider.of<MeshProvider>(context, listen: false);

    final peerCount = meshProvider.nearbyDevices.isNotEmpty
        ? meshProvider.nearbyDevices.length
        : meshProvider.connectedPeerCount;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTokens.darkBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLg)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Device & Profile Quick Info',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTokens.darkSurface,
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  border: Border.all(color: AppTokens.darkBorder),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Registered User', profileProvider.profile?.name.isNotEmpty == true ? profileProvider.profile!.name : 'Anonymous / Not Registered'),
                    const Divider(color: AppTokens.darkBorder, height: 16),
                    _buildInfoRow('Mesh Node ID', profileProvider.profile?.id.isNotEmpty == true ? profileProvider.profile!.id : 'SR-UNASSIGNED'),
                    const Divider(color: AppTokens.darkBorder, height: 16),
                    _buildInfoRow('Blood Group', profileProvider.profile?.bloodGroup.isNotEmpty == true ? profileProvider.profile!.bloodGroup : 'Unknown'),
                    const Divider(color: AppTokens.darkBorder, height: 16),
                    _buildInfoRow('Battery Level', '${telemetryProvider.batteryLevel}%'),
                    const Divider(color: AppTokens.darkBorder, height: 16),
                    _buildInfoRow('Mesh Peers', '$peerCount Connected'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: AppTokens.buttonPrimary,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTokens.signalYellow,
                    foregroundColor: AppTokens.nightNavy,
                  ),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTokens.darkTextMuted, fontSize: 13.5)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: AppTokens.nightNavy,
      appBar: AppBar(
        backgroundColor: AppTokens.nightNavy,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppTokens.signalYellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.radar_rounded, color: AppTokens.nightNavy, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'SignalRescue AI',
              style: TextStyle(
                color: AppTokens.signalYellow,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 26),
            tooltip: 'Settings',
            onPressed: onOpenSettings ?? () => _showSettingsDialog(context),
          ),
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
                    color: AppTokens.darkSurface,
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    border: Border.all(color: AppTokens.darkBorder),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTokens.signalYellow,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No nearby mesh peers detected yet. Scanning...',
                          style: TextStyle(
                            color: AppTokens.darkTextMuted,
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
