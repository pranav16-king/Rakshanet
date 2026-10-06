import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/mesh_provider.dart';
import '../../providers/telemetry_provider.dart';
import '../../theme/emergency_design_tokens.dart';
import '../../widgets/emergency_profile_components.dart';
import '../shell/main_shell.dart';

/// Dedicated post-profile screen introducing the Emergency Mesh Network.
/// Reads real live states from [MeshProvider] and [TelemetryProvider] with zero mock/fake data.
class EmergencyMeshIntroScreen extends StatefulWidget {
  const EmergencyMeshIntroScreen({super.key});

  @override
  State<EmergencyMeshIntroScreen> createState() =>
      _EmergencyMeshIntroScreenState();
}

class _EmergencyMeshIntroScreenState extends State<EmergencyMeshIntroScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final mesh = context.read<MeshProvider>();
      if (mesh.isMeshActive && !mesh.isScanning) {
        mesh.startScan();
      }
      context.read<TelemetryProvider>().refreshTelemetry();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _navigateToMainShell() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const MainShell(),
        transitionsBuilder: (_, a, _, c) =>
            FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 320),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final meshProvider = context.watch<MeshProvider>();
    final telemetryProvider = context.watch<TelemetryProvider>();

    final peerCount = meshProvider.connectedPeerCount;
    final isScanning = meshProvider.isScanning;
    final isMeshActive = meshProvider.isMeshActive;
    final hasGpsFix = telemetryProvider.hasGpsFix;

    final String meshStatusLabel = !isMeshActive
        ? 'Mesh radio paused'
        : peerCount > 0
            ? 'Connected to nearby peers'
            : isScanning
                ? 'Searching for nearby devices'
                : 'Standby — Ready to discover peers';

    final Color meshStatusColor = !isMeshActive
        ? AppColors.textMuted
        : peerCount > 0
            ? AppColors.success
            : AppColors.cyan;

    final String connectionStateLabel = !isMeshActive
        ? 'Offline'
        : peerCount > 0
            ? 'Connected / Relaying'
            : 'Scanning (0 active links)';

    final String gpsStatusLabel = hasGpsFix
        ? 'Device GPS lock active'
        : 'Peer-assisted location (Waiting for GPS fix)';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            EmergencyHeader(
              title: 'Emergency Mesh',
              stepText: 'Ready',
              onBack: _navigateToMainShell,
            ),

            // Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Emergency Mesh',
                      style: AppTypography.pageTitle,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Connect with nearby devices when cellular or internet connectivity is unavailable.',
                      style: AppTypography.pageSubtitle,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Subtle Technical Network Topology Card (Not a gaming radar)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, _) {
                                  return Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: meshStatusColor.withValues(
                                        alpha:
                                            0.5 + (_pulseController.value * 0.5),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  meshStatusLabel,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              StatusBadge(
                                label: isMeshActive ? 'ACTIVE' : 'PAUSED',
                                color: isMeshActive
                                    ? AppColors.cyan
                                    : AppColors.textMuted,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Clean Linear Node Topology Diagram
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.lg,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondarySurface,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildTopologyNode(
                                  icon: Icons.smartphone_rounded,
                                  label: 'This Device',
                                  sublabel: 'Local SQLite',
                                  color: AppColors.primaryAmber,
                                  isActive: true,
                                ),
                                Expanded(
                                  child: _buildTopologyLink(
                                    label: 'BLE / Wi-Fi',
                                    isActive: isMeshActive,
                                  ),
                                ),
                                _buildTopologyNode(
                                  icon: Icons.hub_outlined,
                                  label: 'Nearby Peers',
                                  sublabel: peerCount == 1
                                      ? '1 detected'
                                      : '$peerCount detected',
                                  color: peerCount > 0
                                      ? AppColors.success
                                      : AppColors.cyan,
                                  isActive: peerCount > 0,
                                ),
                                Expanded(
                                  child: _buildTopologyLink(
                                    label: 'Store & Forward',
                                    isActive: peerCount > 0,
                                  ),
                                ),
                                _buildTopologyNode(
                                  icon: Icons.shield_outlined,
                                  label: 'Responders',
                                  sublabel: 'E2E Encrypted',
                                  color: AppColors.blue,
                                  isActive: peerCount > 0,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Live Telemetry & Mesh Metrics Grid
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(
                            icon: Icons.portable_wifi_off_outlined,
                            title: 'Network & Telemetry Status',
                          ),
                          const SizedBox(height: 4),
                          _buildMetricRow(
                            icon: Icons.devices_other_rounded,
                            title: 'Nearby Devices',
                            value: peerCount == 1
                                ? '1 device detected'
                                : '$peerCount devices detected',
                            valueColor: peerCount > 0
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                          const Divider(
                              color: AppColors.borderSubtle, height: 22),
                          _buildMetricRow(
                            icon: Icons.wifi_tethering_rounded,
                            title: 'Connection Range',
                            value: 'BLE (~30–100m) • Wi-Fi Direct (~200m)',
                            valueColor: AppColors.textPrimary,
                          ),
                          const Divider(
                              color: AppColors.borderSubtle, height: 22),
                          _buildMetricRow(
                            icon: Icons.gps_fixed_rounded,
                            title: 'GPS Availability',
                            value: gpsStatusLabel,
                            valueColor: hasGpsFix
                                ? AppColors.success
                                : AppColors.primaryAmber,
                          ),
                          const Divider(
                              color: AppColors.borderSubtle, height: 22),
                          _buildMetricRow(
                            icon: Icons.swap_horiz_rounded,
                            title: 'Connection Status',
                            value: connectionStateLabel,
                            valueColor: peerCount > 0
                                ? AppColors.success
                                : AppColors.cyan,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // End-to-End Encryption & Relay Assurance Card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.secondarySurface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(
                            Icons.enhanced_encryption_outlined,
                            color: AppColors.cyan,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Messages and locations are end-to-end encrypted. Intermediate relay devices forward packets without reading your content.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),

            // Sticky Bottom Action Area
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              decoration: const BoxDecoration(
                color: AppColors.secondarySurface,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
                boxShadow: AppShadows.stickyBar,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryButton(
                    label: 'Continue',
                    onPressed: _navigateToMainShell,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopologyNode({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required bool isActive,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isActive ? 0.16 : 0.08),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: color.withValues(alpha: isActive ? 0.55 : 0.25),
              width: 1.2,
            ),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sublabel,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTopologyLink({
    required String label,
    required bool isActive,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 2,
            decoration: BoxDecoration(
              color: isActive ? AppColors.cyan : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isActive ? AppColors.cyan : AppColors.textMuted,
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow({
    required IconData icon,
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: Text(
            title,
            style: AppTypography.fieldLabel,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
