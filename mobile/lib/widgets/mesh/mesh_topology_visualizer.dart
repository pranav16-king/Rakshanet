import 'package:flutter/material.dart';
import '../../models/mesh_device.dart';
import '../../theme/emergency_design_tokens.dart';
import 'peer_details_sheet.dart';

/// Live Mesh Topology Diagram Visualizer
///
/// Implements Spec Section 3:
/// - Real discovered node graph with true connection states
/// - Clear transport markers (BLE GATT / Wi-Fi Direct) with zero text truncation
/// - Directional transmission packet wave animation
/// - Visual state for Inactive, Discovering (pulse), Connected, Relay, and Gateway
/// - Optional Demo Simulation toggle clearly tagged `[DEMO SIMULATION]`
class MeshTopologyVisualizer extends StatefulWidget {
  final List<MeshDevice> realPeers;
  final bool isScanning;
  final bool isMeshActive;
  final bool isSimulationMode;
  final ValueChanged<bool>? onSimulationModeChanged;
  final VoidCallback? onTriggerScan;

  const MeshTopologyVisualizer({
    super.key,
    required this.realPeers,
    required this.isScanning,
    required this.isMeshActive,
    this.isSimulationMode = false,
    this.onSimulationModeChanged,
    this.onTriggerScan,
  });

  @override
  State<MeshTopologyVisualizer> createState() => _MeshTopologyVisualizerState();
}

class _MeshTopologyVisualizerState extends State<MeshTopologyVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _inspectPeer(MeshDevice peer, {bool isDemo = false}) {
    PeerDetailsSheet.show(
      context,
      peer: peer,
      isSimulated: isDemo,
      onPing: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.cardSurface,
            content: Text('Ping packet sent to ${peer.displayName} via 2.4 GHz direct RF'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasRealPeers = widget.realPeers.isNotEmpty;
    final isSim = widget.isSimulationMode;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title & Demo Simulation Switch Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, _) {
                      final double pulseVal = widget.isScanning
                          ? (0.4 + _animController.value * 0.6)
                          : (hasRealPeers ? 1.0 : 0.4);
                      final Color pulseColor = hasRealPeers
                          ? AppColors.success
                          : (widget.isScanning ? AppColors.cyan : AppColors.textMuted);
                      return Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: pulseColor.withValues(alpha: pulseVal),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Live Topology Diagram',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              // Simulation Mode Pill Toggle
              InkWell(
                onTap: () {
                  widget.onSimulationModeChanged?.call(!isSim);
                },
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSim
                        ? AppColors.primaryAmber.withValues(alpha: 0.15)
                        : AppColors.secondarySurface,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: isSim ? AppColors.primaryAmber : AppColors.borderSubtle,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSim ? Icons.science_rounded : Icons.science_outlined,
                        size: 13,
                        color: isSim ? AppColors.primaryAmber : AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isSim ? 'Demo Active' : 'Test Mode',
                        style: TextStyle(
                          color: isSim ? AppColors.primaryAmber : AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Simulation Mode Warning Banner if active
          if (isSim) ...[
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryAmber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.primaryAmber.withValues(alpha: 0.4), width: 1),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline_rounded, color: AppColors.primaryAmber, size: 14),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'DEMO SIMULATION ACTIVE — Illustrating multi-hop radio routing and rescue responder link.',
                      style: TextStyle(
                        color: AppColors.primaryAmber,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Main Topology Canvas
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.secondarySurface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: isSim
                ? _buildSimulatedMultiHopTopology()
                : (hasRealPeers
                    ? _buildRealDiscoveredTopology()
                    : _buildEmptyScanningState()),
          ),

          const SizedBox(height: AppSpacing.xs),

          // Clarification text preventing false range expectations
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Discovery does not guarantee immediate throughput. Effective RF range (~30–100m BLE, ~100–200m Wi-Fi Direct) depends on concrete rubble, moisture, and line-of-sight.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Empty state when no physical peers are discovered yet
  Widget _buildEmptyScanningState() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNodeBadge(
              icon: Icons.smartphone_rounded,
              title: 'This Device',
              subtitle: 'Local SQLite',
              color: AppColors.primaryAmber,
              isPulsing: widget.isScanning,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('This Device: Local zero-internet node running encrypted SQLite store.'),
                  ),
                );
              },
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          widget.isScanning ? '2.4 GHz BLE SCANNING' : 'RADIO STANDBY',
                          style: const TextStyle(
                            color: AppColors.cyan,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'No peer nodes detected within range.',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Broadcasting presence over BLE advertisement beacon.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.cyan,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          ),
          onPressed: widget.onTriggerScan,
          icon: Icon(
            widget.isScanning ? Icons.sync_rounded : Icons.search_rounded,
            size: 16,
          ),
          label: Text(
            widget.isScanning ? 'Scanning in progress...' : 'Scan Again for Nearby Nodes',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  /// Real topology when actual peers have been discovered
  Widget _buildRealDiscoveredTopology() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal node flow
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              // 1. This Device
              _buildNodeBadge(
                icon: Icons.smartphone_rounded,
                title: 'This Device',
                subtitle: 'Local SQLite',
                color: AppColors.primaryAmber,
                isPulsing: false,
                onTap: () {},
              ),

              // Links & Discovered Peers
              for (int i = 0; i < widget.realPeers.length; i++) ...[
                _buildAnimatedTransportConnector(
                  transportText: widget.realPeers[i].connectionType == ConnectionType.wifiDirect
                      ? 'Wi-Fi Direct'
                      : 'BLE GATT',
                  isConnected: widget.realPeers[i].isConnected,
                ),
                _buildNodeBadge(
                  icon: widget.realPeers[i].isGateway
                      ? Icons.cloud_done_outlined
                      : (widget.realPeers[i].hopCount > 1
                          ? Icons.alt_route_rounded
                          : Icons.cell_tower_rounded),
                  title: widget.realPeers[i].displayName.isNotEmpty
                      ? widget.realPeers[i].displayName
                      : 'Peer #${widget.realPeers[i].deviceId.hashCode.abs().toRadixString(16).substring(0, 4).toUpperCase()}',
                  subtitle: '${widget.realPeers[i].signalStrength} dBm',
                  color: widget.realPeers[i].isConnected ? AppColors.success : AppColors.cyan,
                  isPulsing: widget.realPeers[i].isConnected,
                  onTap: () => _inspectPeer(widget.realPeers[i], isDemo: false),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Center(
          child: Text(
            'Tap any peer node to inspect physical link telemetry, ping, or disconnect.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ),
      ],
    );
  }

  /// Simulated 4-node multi-hop mesh for verification, training, and UI demonstration
  Widget _buildSimulatedMultiHopTopology() {
    final demoPeer1 = MeshDevice(
      id: 'demo_peer_1',
      deviceId: 'SR-NODE-7A2B',
      displayName: 'Citizen Phone',
      connectionType: ConnectionType.ble,
      signalStrength: -68,
      proximityBand: ProximityBand.immediate,
      hopCount: 1,
      batteryLevel: 85,
      lastSeen: DateTime.now().subtract(const Duration(seconds: 4)),
      isConnected: true,
    );

    final demoPeer2 = MeshDevice(
      id: 'demo_relay_2',
      deviceId: 'SR-RELAY-9F1C',
      displayName: 'Relay Beacon',
      connectionType: ConnectionType.wifiDirect,
      signalStrength: -78,
      proximityBand: ProximityBand.near,
      hopCount: 2,
      batteryLevel: 92,
      lastSeen: DateTime.now().subtract(const Duration(seconds: 12)),
      isConnected: true,
    );

    final demoResponder = MeshDevice(
      id: 'demo_responder_3',
      deviceId: 'NDRF-RESCUE-BASE',
      displayName: 'Rescue Station',
      connectionType: ConnectionType.wifiDirect,
      signalStrength: -84,
      proximityBand: ProximityBand.far,
      hopCount: 3,
      batteryLevel: 99,
      lastSeen: DateTime.now().subtract(const Duration(seconds: 2)),
      isConnected: true,
      isGateway: true,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              // Node 1: Local Device
              _buildNodeBadge(
                icon: Icons.smartphone_rounded,
                title: 'This Device',
                subtitle: 'Local SQLite',
                color: AppColors.primaryAmber,
                isPulsing: false,
                onTap: () {},
              ),

              // Link 1: BLE Direct Link
              _buildAnimatedTransportConnector(
                transportText: 'BLE (GATT)',
                isConnected: true,
              ),

              // Node 2: Citizen Peer
              _buildNodeBadge(
                icon: Icons.devices_other_rounded,
                title: demoPeer1.displayName,
                subtitle: '-68 dBm • 1-Hop',
                color: AppColors.cyan,
                isPulsing: true,
                onTap: () => _inspectPeer(demoPeer1, isDemo: true),
              ),

              // Link 2: Wi-Fi Direct Multi-Hop Link
              _buildAnimatedTransportConnector(
                transportText: 'Wi-Fi Direct',
                isConnected: true,
              ),

              // Node 3: Relay Device
              _buildNodeBadge(
                icon: Icons.alt_route_rounded,
                title: demoPeer2.displayName,
                subtitle: 'Relay • 2-Hop',
                color: AppColors.cyan,
                isPulsing: true,
                onTap: () => _inspectPeer(demoPeer2, isDemo: true),
              ),

              // Link 3: E2E Encrypted Store & Forward
              _buildAnimatedTransportConnector(
                transportText: 'Store & Forward',
                isConnected: true,
              ),

              // Node 4: Rescue Team Gateway
              _buildNodeBadge(
                icon: Icons.shield_rounded,
                title: demoResponder.displayName,
                subtitle: 'NDRF Base • Uplink',
                color: AppColors.success,
                isPulsing: true,
                onTap: () => _inspectPeer(demoResponder, isDemo: true),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Center(
          child: Text(
            'Tap any simulated node above to test the Connection Details panel.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ),
      ],
    );
  }

  /// Compact, high-visibility Node Icon badge
  Widget _buildNodeBadge({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isPulsing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (isPulsing)
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, _) {
                      final scale = 1.0 + (_animController.value * 0.28);
                      final opacity = (1.0 - _animController.value).clamp(0.0, 1.0);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                              color: color.withValues(alpha: opacity * 0.6),
                              width: 1.5,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: color.withValues(alpha: 0.7),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 82),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 82),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Clean connector between nodes with full, untruncated transport pill
  Widget _buildAnimatedTransportConnector({
    required String transportText,
    required bool isConnected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Moving packet animation or solid line
          SizedBox(
            width: 72,
            height: 12,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Base line
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: isConnected ? AppColors.cyan.withValues(alpha: 0.4) : AppColors.border,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                // Moving packet dot
                if (isConnected)
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, _) {
                      return Align(
                        alignment: Alignment(
                          -1.0 + (_animController.value * 2.0),
                          0.0,
                        ),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.cyan,
                            boxShadow: [
                              BoxShadow(color: AppColors.cyan, blurRadius: 4),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Transport Tag: Never truncated!
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isConnected ? AppColors.cyan.withValues(alpha: 0.4) : AppColors.borderSubtle,
                width: 0.8,
              ),
            ),
            child: Text(
              transportText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isConnected ? AppColors.cyan : AppColors.textMuted,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
