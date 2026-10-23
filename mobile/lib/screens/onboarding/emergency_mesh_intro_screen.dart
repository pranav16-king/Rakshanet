import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../providers/mesh_provider.dart';
import '../../providers/telemetry_provider.dart';
import '../../services/bluetooth_radio_service.dart';
import '../../theme/emergency_design_tokens.dart';
import '../../widgets/mesh/mesh_telemetry_card.dart';
import '../../widgets/mesh/mesh_topology_visualizer.dart';
import '../shell/main_shell.dart';

/// Real-time Mesh Screen Network State indicator enum.
///
/// Follows Spec Section 2:
/// Meaningful status values representing the actual local and remote radio state:
/// - Initializing: Local hardware & storage checking
/// - Permission Required: Missing Bluetooth or Location permissions
/// - Radio Unavailable: Hardware Bluetooth/Wi-Fi disabled
/// - Discovering Peers: Actively scanning/advertising over direct RF
/// - Peers Found: Detected nearby nodes
/// - Connected: Active physical radio link established
/// - Offline — No Peers: Radio active, but 0 neighbors in range
/// - Connection Failed: Attempted handshake timed out or rejected
enum MeshScreenStatus {
  initializing,
  permissionRequired,
  radioUnavailable,
  discoveringPeers,
  peersFound,
  connected,
  offlineNoPeers,
  connectionFailed,
}

/// Upgraded Emergency Mesh Screen
///
/// Replaces the legacy basic status screen with an interactive, technically
/// accurate offline mesh interface:
/// - Fixed layout with zero heading duplication & zero text truncation
/// - Responsive, scrollable body with proper safe-area insets
/// - Live topology visualization with real peers & optional demo simulation
/// - Accurate BLE & Wi-Fi Direct discovery state
/// - Structured 5-category telemetry dashboard
/// - Non-overlapping fixed bottom action bar
class EmergencyMeshIntroScreen extends StatefulWidget {
  const EmergencyMeshIntroScreen({super.key});

  @override
  State<EmergencyMeshIntroScreen> createState() =>
      _EmergencyMeshIntroScreenState();
}

class _EmergencyMeshIntroScreenState extends State<EmergencyMeshIntroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _isInitializing = true;
  bool _hasPermissions = true;
  bool _isSimulationMode = false;
  Timer? _initializationTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _verifyPermissionsAndInit();
  }

  @override
  void dispose() {
    _initializationTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _verifyPermissionsAndInit() async {
    setState(() {
      _isInitializing = true;
    });

    try {
      final radioService = BluetoothRadioService.instance;
      final permissionsOk = await radioService.checkAndRequestPermissions();

      if (mounted) {
        setState(() {
          _hasPermissions = permissionsOk;
        });

        final mesh = context.read<MeshProvider>();
        if (permissionsOk && mesh.isMeshActive && !mesh.isScanning) {
          mesh.startScan();
        }
        context.read<TelemetryProvider>().refreshTelemetry();
      }
    } catch (e) {
      debugPrint('[EmergencyMeshIntroScreen] Init error: $e');
    } finally {
      _initializationTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _isInitializing = false;
          });
        }
      });
    }
  }

  void _triggerScan() {
    final mesh = context.read<MeshProvider>();
    mesh.startScan();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.cardSurface,
        content: Text('Starting direct 2.4 GHz RF peer discovery (BLE & Wi-Fi Direct)...'),
        duration: Duration(seconds: 2),
      ),
    );
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

  MeshScreenStatus _resolveStatus({
    required MeshProvider mesh,
    required bool isInitializing,
    required bool hasPermissions,
  }) {
    if (isInitializing) return MeshScreenStatus.initializing;
    if (!hasPermissions) return MeshScreenStatus.permissionRequired;
    if (!mesh.isMeshActive) return MeshScreenStatus.radioUnavailable;

    final peerCount = mesh.connectedPeerCount;
    final nearbyCount = mesh.nearbyDevices.length;
    final isScanning = mesh.isScanning;

    if (peerCount > 0) return MeshScreenStatus.connected;
    if (nearbyCount > 0) return MeshScreenStatus.peersFound;
    if (isScanning) return MeshScreenStatus.discoveringPeers;
    return MeshScreenStatus.offlineNoPeers;
  }

  String _statusBadgeLabel(MeshScreenStatus status) {
    switch (status) {
      case MeshScreenStatus.initializing:
        return 'INITIALIZING';
      case MeshScreenStatus.permissionRequired:
        return 'PERMISSION REQUIRED';
      case MeshScreenStatus.radioUnavailable:
        return 'RADIO UNAVAILABLE';
      case MeshScreenStatus.discoveringPeers:
        return 'DISCOVERING PEERS';
      case MeshScreenStatus.peersFound:
        return 'PEERS FOUND';
      case MeshScreenStatus.connected:
        return 'CONNECTED';
      case MeshScreenStatus.offlineNoPeers:
        return 'OFFLINE — NO PEERS';
      case MeshScreenStatus.connectionFailed:
        return 'CONNECTION FAILED';
    }
  }

  Color _statusBadgeColor(MeshScreenStatus status) {
    switch (status) {
      case MeshScreenStatus.initializing:
        return AppColors.primaryAmber;
      case MeshScreenStatus.permissionRequired:
        return AppColors.primaryAmber;
      case MeshScreenStatus.radioUnavailable:
        return AppColors.danger;
      case MeshScreenStatus.discoveringPeers:
        return AppColors.cyan;
      case MeshScreenStatus.peersFound:
        return AppColors.cyan;
      case MeshScreenStatus.connected:
        return AppColors.success;
      case MeshScreenStatus.offlineNoPeers:
        return AppColors.textMuted;
      case MeshScreenStatus.connectionFailed:
        return AppColors.danger;
    }
  }

  IconData _statusBadgeIcon(MeshScreenStatus status) {
    switch (status) {
      case MeshScreenStatus.initializing:
        return Icons.hourglass_top_rounded;
      case MeshScreenStatus.permissionRequired:
        return Icons.security_rounded;
      case MeshScreenStatus.radioUnavailable:
        return Icons.portable_wifi_off_rounded;
      case MeshScreenStatus.discoveringPeers:
        return Icons.radar_rounded;
      case MeshScreenStatus.peersFound:
        return Icons.hub_rounded;
      case MeshScreenStatus.connected:
        return Icons.check_circle_rounded;
      case MeshScreenStatus.offlineNoPeers:
        return Icons.wifi_off_rounded;
      case MeshScreenStatus.connectionFailed:
        return Icons.error_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final meshProvider = context.watch<MeshProvider>();
    final telemetryProvider = context.watch<TelemetryProvider>();

    final status = _resolveStatus(
      mesh: meshProvider,
      isInitializing: _isInitializing,
      hasPermissions: _hasPermissions,
    );

    final statusLabel = _statusBadgeLabel(status);
    final statusColor = _statusBadgeColor(status);
    final statusIcon = _statusBadgeIcon(status);

    final isScanningOrConnecting = meshProvider.isScanning || status == MeshScreenStatus.initializing;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Redesigned Top Status Header (Spec Section 2)
            _buildTopStatusHeader(
              statusLabel: statusLabel,
              statusColor: statusColor,
              statusIcon: statusIcon,
              isActivityRunning: isScanningOrConnecting,
            ),

            // 2. Scrollable Content Area with Safe Margin (Never obscured by bottom button)
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.xl + 20, // generous bottom padding so content scrolls cleanly
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Subtitle Banner (No duplicate heading!)
                    _buildSectionBanner(),

                    const SizedBox(height: AppSpacing.md),

                    // Permission Warning Banner if missing
                    if (!_hasPermissions) ...[
                      _buildPermissionWarningCard(),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Section 1: Live Mesh Topology Visualization (Spec Section 3)
                    MeshTopologyVisualizer(
                      realPeers: meshProvider.physicalPeers.isNotEmpty
                          ? meshProvider.physicalPeers
                          : meshProvider.nearbyDevices,
                      isScanning: meshProvider.isScanning,
                      isMeshActive: meshProvider.isMeshActive,
                      isSimulationMode: _isSimulationMode,
                      onSimulationModeChanged: (val) {
                        setState(() {
                          _isSimulationMode = val;
                        });
                      },
                      onTriggerScan: _triggerScan,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Section 2: Structured Network & Telemetry Dashboard (Spec Section 5)
                    MeshTelemetryCard(
                      meshProvider: meshProvider,
                      telemetryProvider: telemetryProvider,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Section 3: End-to-End Encryption & Security Notice
                    _buildEncryptionNoticeCard(),

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),

            // 3. Docked Bottom Action Bar (Spec Section 1: Never overlays content)
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  /// Top Status Header: 44x44 back button, title, actual network state, status badge
  Widget _buildTopStatusHeader({
    required String statusLabel,
    required Color statusColor,
    required IconData statusIcon,
    required bool isActivityRunning,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        children: [
          // 44x44 minimum touch target Back button
          Semantics(
            button: true,
            label: 'Back to safety hub',
            child: InkWell(
              onTap: _navigateToMainShell,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.secondarySurface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // Title & Actual Network State Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Emergency Mesh',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    if (isActivityRunning) ...[
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) {
                          return Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.cyan.withValues(
                                alpha: 0.4 + (_pulseController.value * 0.6),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 5),
                    ],
                    Flexible(
                      child: Text(
                        isActivityRunning ? '2.4 GHz Direct RF Active' : 'Direct Radio Standby',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.xs),

          // Compact Status Pill Badge (Spec Section 2: Real state, never fake "Ready")
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 12, color: statusColor),
                const SizedBox(width: 4.5),
                Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Distinct Section Banner (Replaces duplicate Emergency Mesh heading)
  Widget _buildSectionBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.cell_tower_rounded, color: AppColors.cyan, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'OFFLINE P2P MESH RELAY',
                  style: TextStyle(
                    color: AppColors.cyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Direct device-to-device radio hops connect you with disaster survivors and rescue personnel when cellular infrastructure and internet are unavailable.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Interactive permission grant card if runtime permissions are missing
  Widget _buildPermissionWarningCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primaryAmber, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: AppColors.primaryAmber, size: 20),
              SizedBox(width: 8),
              Text(
                'Bluetooth & Location Permissions Required',
                style: TextStyle(
                  color: AppColors.primaryAmber,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Android requires Location and Nearby Devices permissions to discover physical radio beacons without cellular towers.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAmber,
                foregroundColor: AppColors.textOnAmber,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              onPressed: () async {
                await openAppSettings();
                _verifyPermissionsAndInit();
              },
              icon: const Icon(Icons.settings_rounded, size: 16),
              label: const Text('Grant Permissions in Settings', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  /// End-to-End Encryption Assurance Card
  Widget _buildEncryptionNoticeCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
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
              'All mesh transmissions and location packets are end-to-end encrypted with Curve25519 & AES-GCM. Intermediate relay devices forward data blindly without accessing your private message payloads.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Docked Bottom Action Bar respecting Safe Areas (Never obscures content)
  Widget _buildBottomActionBar() {
    return Container(
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
          Row(
            children: [
              // Scan Now secondary trigger
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.cyan,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    onPressed: _triggerScan,
                    icon: const Icon(Icons.radar_rounded, size: 18),
                    label: const Text(
                      'Scan Radio',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // Primary Continue button
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAmber,
                      foregroundColor: AppColors.textOnAmber,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    onPressed: _navigateToMainShell,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Continue to Safety Hub',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
