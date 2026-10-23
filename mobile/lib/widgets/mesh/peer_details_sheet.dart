import 'package:flutter/material.dart';
import '../../models/mesh_device.dart';
import '../../theme/emergency_design_tokens.dart';

/// Modal Bottom Sheet displaying detailed, privacy-preserving technical
/// information about a discovered or connected peer device.
///
/// Complies with Spec Section 6 ("Functional Connection Details Panel"):
/// - Privacy-preserving alias (never exposes raw hardware identifiers)
/// - Discovery & last-seen timestamp
/// - Transport protocol (BLE GATT / Wi-Fi Direct P2P)
/// - Cryptographic authentication state
/// - Physical link quality & RSSI signal strength
/// - Hop distance to destination
/// - Actionable connection operations (Connect, Disconnect, Ping)
class PeerDetailsSheet extends StatelessWidget {
  final MeshDevice peer;
  final bool isSimulated;
  final VoidCallback? onConnect;
  final VoidCallback? onDisconnect;
  final VoidCallback? onPing;

  const PeerDetailsSheet({
    super.key,
    required this.peer,
    this.isSimulated = false,
    this.onConnect,
    this.onDisconnect,
    this.onPing,
  });

  static Future<void> show(
    BuildContext context, {
    required MeshDevice peer,
    bool isSimulated = false,
    VoidCallback? onConnect,
    VoidCallback? onDisconnect,
    VoidCallback? onPing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PeerDetailsSheet(
        peer: peer,
        isSimulated: isSimulated,
        onConnect: onConnect,
        onDisconnect: onDisconnect,
        onPing: onPing,
      ),
    );
  }

  /// Derives an anonymized, privacy-preserving node alias (e.g. Node #A4F9)
  String get privacyAlias {
    final cleanId = peer.deviceId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (cleanId.length >= 4) {
      final sub = cleanId.substring(cleanId.length - 4).toUpperCase();
      return 'Node #$sub';
    }
    final hash = peer.deviceId.hashCode.abs().toRadixString(16).padLeft(4, '0').toUpperCase();
    return 'Node #${hash.substring(hash.length - 4)}';
  }

  String get signalRating {
    final rssi = peer.signalStrength;
    if (rssi >= -65) return 'Excellent (High Throughput)';
    if (rssi >= -75) return 'Good (Stable Link)';
    if (rssi >= -85) return 'Fair (Text & GPS Relays)';
    return 'Weak / Fringe (< 1 kbps)';
  }

  Color get signalColor {
    final rssi = peer.signalStrength;
    if (rssi >= -65) return AppColors.success;
    if (rssi >= -75) return AppColors.cyan;
    if (rssi >= -85) return AppColors.primaryAmber;
    return AppColors.danger;
  }

  String get formattedLastSeen {
    final diff = DateTime.now().difference(peer.lastSeen);
    if (diff.inSeconds < 10) return 'Just now (Active RF keep-alive)';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = peer.isConnected;
    final transportLabel = peer.connectionType == ConnectionType.wifiDirect
        ? 'Wi-Fi Direct (P2P High-Speed)'
        : 'Bluetooth Low Energy 5.x (GATT)';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1.5),
          left: BorderSide(color: AppColors.border, width: 1),
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag pill
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isConnected
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.cyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isConnected ? AppColors.success : AppColors.cyan,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      peer.isGateway
                          ? Icons.cloud_done_outlined
                          : (peer.hopCount > 1 ? Icons.alt_route_rounded : Icons.cell_tower_rounded),
                      color: isConnected ? AppColors.success : AppColors.cyan,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                peer.displayName.isNotEmpty ? peer.displayName : privacyAlias,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isSimulated) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryAmber.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.primaryAmber, width: 0.8),
                                ),
                                child: const Text(
                                  'DEMO',
                                  style: TextStyle(
                                    color: AppColors.primaryAmber,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$privacyAlias • ${peer.hopCount == 1 ? "Direct 1-Hop Neighbor" : "${peer.hopCount}-Hop Mesh Relay"}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (isConnected ? AppColors.success : AppColors.textMuted)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isConnected ? AppColors.success : AppColors.border,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isConnected ? AppColors.success : AppColors.textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isConnected ? 'CONNECTED' : 'DISCOVERED',
                          style: TextStyle(
                            color: isConnected ? AppColors.success : AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Detail Metrics Table
              Container(
                decoration: BoxDecoration(
                  color: AppColors.secondarySurface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  children: [
                    _buildDetailRow(
                      icon: Icons.wifi_tethering_rounded,
                      label: 'Radio Transport',
                      value: transportLabel,
                      valueColor: AppColors.cyan,
                    ),
                    const Divider(color: AppColors.borderSubtle, height: 16),
                    _buildDetailRow(
                      icon: Icons.signal_cellular_alt_rounded,
                      label: 'Signal Quality (RSSI)',
                      value: '${peer.signalStrength} dBm • $signalRating',
                      valueColor: signalColor,
                    ),
                    const Divider(color: AppColors.borderSubtle, height: 16),
                    _buildDetailRow(
                      icon: Icons.near_me_outlined,
                      label: 'RF Proximity Band',
                      value: '${peer.proximityDisplay} (Subject to obstacles)',
                      valueColor: AppColors.textPrimary,
                    ),
                    const Divider(color: AppColors.borderSubtle, height: 16),
                    _buildDetailRow(
                      icon: Icons.verified_user_outlined,
                      label: 'Authentication',
                      value: isConnected
                          ? 'Verified Ed25519 Identity (Encrypted)'
                          : 'Proximity Unverified (Zero Trust)',
                      valueColor: isConnected ? AppColors.success : AppColors.primaryAmber,
                    ),
                    const Divider(color: AppColors.borderSubtle, height: 16),
                    _buildDetailRow(
                      icon: Icons.battery_charging_full_rounded,
                      label: 'Remote Battery Level',
                      value: '${peer.batteryLevel}% reported',
                      valueColor: peer.batteryLevel > 20 ? AppColors.textPrimary : AppColors.danger,
                    ),
                    const Divider(color: AppColors.borderSubtle, height: 16),
                    _buildDetailRow(
                      icon: Icons.schedule_rounded,
                      label: 'Last Seen Online',
                      value: formattedLastSeen,
                      valueColor: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Tactical Note
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs + 2),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 15),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Unauthenticated proximity devices are never treated as trusted emergency responders.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        onPing?.call();
                      },
                      icon: const Icon(Icons.radar_rounded, size: 18, color: AppColors.cyan),
                      label: const Text(
                        'Ping Node',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isConnected ? AppColors.danger : AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (isConnected) {
                          onDisconnect?.call();
                        } else {
                          onConnect?.call();
                        }
                      },
                      icon: Icon(
                        isConnected ? Icons.link_off_rounded : Icons.link_rounded,
                        size: 18,
                      ),
                      label: Text(
                        isConnected ? 'Disconnect' : 'Connect Link',
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
