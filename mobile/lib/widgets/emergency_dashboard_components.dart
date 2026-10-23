import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/emergency_design_tokens.dart';

/// 1. Compact, logo-free App Header (64–72dp height).
typedef RakshaNetHeader = SignalRescueHeader;
class SignalRescueHeader extends StatelessWidget {
  final int batteryLevel;
  final bool isMeshActive;
  final bool isOnline;
  final VoidCallback onOpenSettings;

  const SignalRescueHeader({
    super.key,
    required this.batteryLevel,
    required this.isMeshActive,
    required this.isOnline,
    required this.onOpenSettings,
  });

  Color _batteryColor() {
    if (batteryLevel <= 0) return AppColors.textSecondary;
    if (batteryLevel > 50) return AppColors.success;
    if (batteryLevel >= 20) return AppColors.primaryAmber;
    return AppColors.danger;
  }

  IconData _batteryIcon() {
    if (batteryLevel <= 0) return Icons.battery_std_rounded;
    if (batteryLevel < 20) return Icons.battery_alert_rounded;
    if (batteryLevel < 50) return Icons.battery_3_bar_rounded;
    if (batteryLevel < 85) return Icons.battery_5_bar_rounded;
    return Icons.battery_full_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final statusDotColor = isOnline
        ? AppColors.success
        : isMeshActive
            ? AppColors.cyan
            : AppColors.primaryAmber;

    final batColor = _batteryColor();

    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Left: Typography Title & Subtitle (NO Logo)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Flexible(
                      child: Text(
                        'RakshaNet',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.headerTitle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusDotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Emergency Network',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.headerSubtitle,
                ),
              ],
            ),
          ),

          // Right: Compact Battery Readout + 44x44dp Settings Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.connectivityCardBg,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.connectivityCardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_batteryIcon(), size: 16, color: batColor),
                const SizedBox(width: 5),
                Text(
                  batteryLevel > 0 ? '$batteryLevel%' : '--%',
                  style: TextStyle(
                    color: batColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: 'Settings',
            child: InkWell(
              onTap: onOpenSettings,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.connectivityCardBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.connectivityCardBorder),
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 2. Emergency Readiness Summary Card.
class SystemReadinessCard extends StatelessWidget {
  final bool isMeshActive;
  final bool isScanning;
  final int peerCount;
  final bool isOnline;
  final bool hasGpsFix;
  final int batteryLevel;

  const SystemReadinessCard({
    super.key,
    required this.isMeshActive,
    required this.isScanning,
    required this.peerCount,
    required this.isOnline,
    required this.hasGpsFix,
    required this.batteryLevel,
  });

  @override
  Widget build(BuildContext context) {
    // Compute actual readiness state from real telemetry
    final String readinessTitle;
    final Color readinessColor;
    final IconData readinessIcon;

    if (!isMeshActive && !isOnline) {
      readinessTitle = 'OFFLINE — ATTENTION REQUIRED';
      readinessColor = AppColors.danger;
      readinessIcon = Icons.warning_amber_rounded;
    } else if (batteryLevel > 0 && batteryLevel < 15) {
      readinessTitle = 'ATTENTION REQUIRED (LOW BATTERY)';
      readinessColor = AppColors.danger;
      readinessIcon = Icons.battery_alert_rounded;
    } else if (isOnline || peerCount > 0) {
      readinessTitle = 'READY FOR EMERGENCY';
      readinessColor = AppColors.success;
      readinessIcon = Icons.check_circle_outline_rounded;
    } else {
      readinessTitle = 'LIMITED — OFFLINE MESH ACTIVE';
      readinessColor = AppColors.primaryAmber;
      readinessIcon = Icons.info_outline_rounded;
    }

    final String meshStateText = !isMeshActive
        ? 'Offline'
        : peerCount > 0
            ? 'Connected'
            : isScanning
                ? 'Searching'
                : 'Standby';

    final String internetStateText = isOnline ? 'Online' : 'Offline';
    final String gpsStateText = hasGpsFix ? 'Available' : 'Unavailable';
    final String batteryStateText =
        batteryLevel > 0 ? '$batteryLevel%' : 'Checking...';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.connectivityCardBg,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: readinessColor.withValues(alpha: 0.38),
          width: 1,
        ),
        boxShadow: AppElevation.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'SYSTEM STATUS',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: readinessColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: readinessColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(readinessIcon, size: 13, color: readinessColor),
                    const SizedBox(width: 5),
                    Text(
                      readinessTitle,
                      style: TextStyle(
                        color: readinessColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.secondarySurface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryColumn(
                    label: 'Mesh',
                    value: meshStateText,
                    valueColor: !isMeshActive
                        ? AppColors.textMuted
                        : peerCount > 0
                            ? AppColors.success
                            : AppColors.cyan,
                  ),
                ),
                _buildVerticalDivider(),
                Expanded(
                  child: _buildSummaryColumn(
                    label: 'Internet',
                    value: internetStateText,
                    valueColor:
                        isOnline ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
                _buildVerticalDivider(),
                Expanded(
                  child: _buildSummaryColumn(
                    label: 'GPS',
                    value: gpsStateText,
                    valueColor:
                        hasGpsFix ? AppColors.cyan : AppColors.primaryAmber,
                  ),
                ),
                _buildVerticalDivider(),
                Expanded(
                  child: _buildSummaryColumn(
                    label: 'Battery',
                    value: batteryStateText,
                    valueColor: batteryLevel <= 0
                        ? AppColors.textSecondary
                        : batteryLevel > 50
                            ? AppColors.success
                            : batteryLevel >= 20
                                ? AppColors.primaryAmber
                                : AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 26,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppColors.borderSubtle,
    );
  }

  Widget _buildSummaryColumn({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: valueColor,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// 3. Individual Compact Connectivity Status Card (110–122dp height, zero text truncation).
class ConnectivityStatusCard extends StatelessWidget {
  final String title;
  final String shortTitle;
  final IconData icon;
  final String status;
  final String secondary;
  final Color semanticColor;
  final VoidCallback? onTap;

  const ConnectivityStatusCard({
    super.key,
    required this.title,
    required this.shortTitle,
    required this.icon,
    required this.status,
    required this.secondary,
    required this.semanticColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '$title: $status. $secondary',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          constraints: const BoxConstraints(minHeight: 110),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.connectivityCardBg,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: AppColors.connectivityCardBorder,
              width: 1,
            ),
            boxShadow: AppElevation.card,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final useShortTitle = constraints.maxWidth < 135;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: semanticColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: semanticColor.withValues(alpha: 0.32),
                          ),
                        ),
                        child: Icon(
                          icon,
                          size: 18,
                          color: semanticColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          useShortTitle ? shortTitle : title,
                          maxLines: 1,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: semanticColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              secondary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.statusSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 4. Responsive 2-Column Connectivity Status Grid.
class ConnectivityGrid extends StatelessWidget {
  final bool isMeshActive;
  final bool isScanning;
  final int peerCount;
  final bool isOnline;
  final bool hasGpsFix;
  final int batteryLevel;
  final VoidCallback onTapMesh;

  const ConnectivityGrid({
    super.key,
    required this.isMeshActive,
    required this.isScanning,
    required this.peerCount,
    required this.isOnline,
    required this.hasGpsFix,
    required this.batteryLevel,
    required this.onTapMesh,
  });

  @override
  Widget build(BuildContext context) {
    // 1. MESH NETWORK
    final String meshStatus = !isMeshActive
        ? 'Offline'
        : peerCount > 0
            ? 'Connected'
            : isScanning
                ? 'Searching'
                : 'Ready';
    final String meshSecondary = !isMeshActive
        ? 'Radio paused'
        : peerCount == 1
            ? '1 peer connected'
            : '$peerCount peers';
    final Color meshColor = !isMeshActive
        ? AppColors.textMuted
        : peerCount > 0
            ? AppColors.cyan
            : AppColors.blue;

    // 2. INTERNET
    final String internetStatus = isOnline ? 'Online' : 'Offline';
    final String internetSecondary =
        isOnline ? 'Cloud sync active' : 'Local mesh only';
    final Color internetColor =
        isOnline ? AppColors.success : AppColors.textMuted;

    // 3. GPS
    final String gpsStatus = hasGpsFix ? 'Available' : 'Unavailable';
    final String gpsSecondary =
        hasGpsFix ? 'Location ready' : 'Peer-assisted mode';
    final Color gpsColor =
        hasGpsFix ? AppColors.cyan : AppColors.primaryAmber;

    // 4. BATTERY
    final String batteryStatus =
        batteryLevel > 0 ? '$batteryLevel%' : 'Checking...';
    final String batterySecondary = batteryLevel <= 0
        ? 'Reading sensor'
        : batteryLevel > 50
            ? 'Healthy reserve'
            : batteryLevel >= 20
                ? 'Moderate level'
                : 'Low battery';
    final Color batteryColor = batteryLevel <= 0
        ? AppColors.textSecondary
        : batteryLevel > 50
            ? AppColors.success
            : batteryLevel >= 20
                ? AppColors.primaryAmber
                : AppColors.danger;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ConnectivityStatusCard(
                title: 'MESH NETWORK',
                shortTitle: 'MESH',
                icon: Icons.hub_outlined,
                status: meshStatus,
                secondary: meshSecondary,
                semanticColor: meshColor,
                onTap: onTapMesh,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ConnectivityStatusCard(
                title: 'INTERNET',
                shortTitle: 'INTERNET',
                icon: isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                status: internetStatus,
                secondary: internetSecondary,
                semanticColor: internetColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ConnectivityStatusCard(
                title: 'GPS',
                shortTitle: 'GPS',
                icon: hasGpsFix
                    ? Icons.location_on_outlined
                    : Icons.location_off_outlined,
                status: gpsStatus,
                secondary: gpsSecondary,
                semanticColor: gpsColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ConnectivityStatusCard(
                title: 'BATTERY',
                shortTitle: 'BATTERY',
                icon: batteryLevel > 0 && batteryLevel < 20
                    ? Icons.battery_alert_rounded
                    : Icons.battery_std_rounded,
                status: batteryStatus,
                secondary: batterySecondary,
                semanticColor: batteryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 5. Compact Live Mesh Activity Card below Connectivity Grid.
class MeshStatusCard extends StatefulWidget {
  final bool isMeshActive;
  final bool isScanning;
  final int peerCount;
  final VoidCallback onTapScan;

  const MeshStatusCard({
    super.key,
    required this.isMeshActive,
    required this.isScanning,
    required this.peerCount,
    required this.onTapScan,
  });

  @override
  State<MeshStatusCard> createState() => _MeshStatusCardState();
}

class _MeshStatusCardState extends State<MeshStatusCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanPulseCtrl;

  @override
  void initState() {
    super.initState();
    _scanPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanPulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String messageText;
    final Color statusColor;

    if (!widget.isMeshActive) {
      messageText = 'No nearby mesh peers detected (Mesh paused)';
      statusColor = AppColors.textMuted;
    } else if (widget.peerCount > 0) {
      messageText = widget.peerCount == 1
          ? '1 nearby device connected'
          : '${widget.peerCount} nearby devices connected';
      statusColor = AppColors.success;
    } else if (widget.isScanning) {
      messageText = 'Scanning for nearby devices...';
      statusColor = AppColors.cyan;
    } else {
      messageText = 'No nearby mesh peers detected';
      statusColor = AppColors.textSecondary;
    }

    return InkWell(
      onTap: widget.onTapScan,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.connectivityCardBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.connectivityCardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.radar_rounded,
                size: 18,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mesh Network',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    messageText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.peerCount > 0
                      ? 'Active'
                      : widget.isScanning
                          ? 'Scanning'
                          : 'Idle',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedBuilder(
                  animation: _scanPulseCtrl,
                  builder: (context, _) {
                    final alpha = widget.isScanning
                        ? (0.35 + _scanPulseCtrl.value * 0.65)
                        : 1.0;
                    return Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor.withValues(alpha: alpha),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 6. Controlled SOS Button (190–210dp diameter, strict 3-second hold, never triggers on simple tap).
class SOSButton extends StatefulWidget {
  final double diameter;
  final VoidCallback onHoldCompleted;
  final ValueChanged<double>? onProgressChanged;

  const SOSButton({
    super.key,
    required this.diameter,
    required this.onHoldCompleted,
    this.onProgressChanged,
  });

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton> {
  static const int _holdDurationMs = 3000;
  static const int _tickMs = 40;

  Timer? _holdTimer;
  double _progress = 0.0;
  bool _isPressed = false;

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  void _startHold() {
    HapticFeedback.mediumImpact();
    _holdTimer?.cancel();
    setState(() {
      _isPressed = true;
      _progress = 0.0;
    });
    widget.onProgressChanged?.call(0.0);

    int elapsed = 0;
    _holdTimer = Timer.periodic(const Duration(milliseconds: _tickMs), (timer) {
      elapsed += _tickMs;
      final nextProgress = (elapsed / _holdDurationMs).clamp(0.0, 1.0);
      if (mounted) {
        setState(() {
          _progress = nextProgress;
        });
        widget.onProgressChanged?.call(nextProgress);
      }

      if (elapsed >= _holdDurationMs) {
        timer.cancel();
        HapticFeedback.heavyImpact();
        if (mounted) {
          setState(() {
            _isPressed = false;
            _progress = 0.0;
          });
          widget.onProgressChanged?.call(0.0);
        }
        widget.onHoldCompleted();
      }
    });
  }

  void _cancelHold() {
    if (_progress < 1.0) {
      _holdTimer?.cancel();
      if (mounted) {
        setState(() {
          _isPressed = false;
          _progress = 0.0;
        });
        widget.onProgressChanged?.call(0.0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.diameter;
    final String subLabel;
    if (!_isPressed || _progress == 0.0) {
      subLabel = 'Hold 3 sec';
    } else if (_progress < 0.7) {
      subLabel = 'Keep holding...';
    } else {
      subLabel = 'Release to cancel';
    }

    return Semantics(
      button: true,
      label:
          'Emergency SOS Button. Press and hold for 3 seconds to broadcast an emergency alert.',
      child: GestureDetector(
        onTapDown: (_) => _startHold(),
        onTapUp: (_) => _cancelHold(),
        onTapCancel: _cancelHold,
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: SizedBox(
            width: size + 20,
            height: size + 20,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Subtle outer ring track
                Container(
                  width: size + 14,
                  height: size + 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.sosRed.withValues(alpha: 0.25),
                      width: 2,
                    ),
                  ),
                ),

                // Press-and-Hold Progress Ring
                if (_isPressed && _progress > 0)
                  SizedBox(
                    width: size + 14,
                    height: size + 14,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 5,
                      color: AppColors.primaryAmber,
                      backgroundColor: AppColors.sosRed.withValues(alpha: 0.2),
                    ),
                  ),

                // Controlled Red SOS Circle (#EF4444)
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.sosRed,
                        AppColors.sosRedDark,
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 1.5,
                    ),
                    boxShadow: AppElevation.sosControlled,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'SOS',
                        style: AppTypography.sosLabel,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.24),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          subLabel,
                          style: TextStyle(
                            color: _isPressed
                                ? AppColors.primaryAmber
                                : Colors.white.withValues(alpha: 0.92),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 7. Dedicated Emergency Action Section (Heading, Subtitle, Controlled SOSButton, Active State, Broadcast Channels).
class EmergencyAction extends StatelessWidget {
  final double sosDiameter;
  final bool isAlertActive;
  final bool isMeshActive;
  final int peerCount;
  final bool isOnline;
  final bool hasGpsFix;
  final VoidCallback onHoldCompleted;
  final VoidCallback onCancelAlert;
  final VoidCallback onOpenReportDetails;

  const EmergencyAction({
    super.key,
    required this.sosDiameter,
    required this.isAlertActive,
    required this.isMeshActive,
    required this.peerCount,
    required this.isOnline,
    required this.hasGpsFix,
    required this.onHoldCompleted,
    required this.onCancelAlert,
    required this.onOpenReportDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.connectivityCardBg,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: isAlertActive
              ? AppColors.sosRed.withValues(alpha: 0.65)
              : AppColors.connectivityCardBorder,
          width: isAlertActive ? 1.5 : 1.0,
        ),
        boxShadow: AppElevation.card,
      ),
      child: Column(
        children: [
          // Section Heading & Subtitle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emergency_share_outlined,
                size: 16,
                color: isAlertActive ? AppColors.sosRed : AppColors.primaryAmber,
              ),
              const SizedBox(width: 6),
              Text(
                isAlertActive ? 'EMERGENCY ALERT ACTIVE' : 'EMERGENCY',
                style: TextStyle(
                  color:
                      isAlertActive ? AppColors.sosRed : AppColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isAlertActive
                ? 'Emergency broadcast is active across available channels'
                : 'Press and hold to broadcast an emergency alert',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),

          if (!isAlertActive) ...[
            // Controlled SOS Button
            SOSButton(
              diameter: sosDiameter,
              onHoldCompleted: onHoldCompleted,
            ),
            const SizedBox(height: 10),
            const Text(
              'HOLD TO BROADCAST',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ] else ...[
            // Triggered / Active Alert Operational Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.secondarySurface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.sosRed.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.graphic_eq_rounded,
                        size: 18,
                        color: AppColors.sosRed,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Emergency broadcast active',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildActiveAlertRow(
                    label: 'Mesh relay',
                    value: !isMeshActive
                        ? 'Offline'
                        : peerCount > 0
                            ? 'Relaying ($peerCount peers)'
                            : 'Searching',
                    isReady: isMeshActive,
                  ),
                  const SizedBox(height: 6),
                  _buildActiveAlertRow(
                    label: 'Internet',
                    value: isOnline ? 'Available' : 'Unavailable',
                    isReady: isOnline,
                  ),
                  const SizedBox(height: 6),
                  _buildActiveAlertRow(
                    label: 'Location',
                    value: hasGpsFix ? 'Available' : 'Unavailable',
                    isReady: hasGpsFix,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            onPressed: onOpenReportDetails,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                            ),
                            child: const Text(
                              'Update Details',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: onCancelAlert,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.sosRed,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                            ),
                            child: const Text(
                              'CANCEL ALERT',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Broadcast Channels Readiness Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.secondarySurface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 14,
              runSpacing: 6,
              children: [
                const Text(
                  'Broadcast channels:',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                _buildChannelChip(
                  label: 'Internet',
                  isReady: isOnline,
                ),
                _buildChannelChip(
                  label: 'Mesh',
                  isReady: isMeshActive,
                ),
                _buildChannelChip(
                  label: 'GPS',
                  isReady: hasGpsFix,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAlertRow({
    required String label,
    required String value,
    required bool isReady,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isReady ? AppColors.success : AppColors.primaryAmber,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildChannelChip({
    required String label,
    required bool isReady,
  }) {
    final color = isReady ? AppColors.success : AppColors.textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isReady ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          size: 13,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: isReady ? AppColors.textPrimary : AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// 8. Compact Horizontal Quick-Action Bar for existing tools (Map, Nearby, Contacts, AI).
class QuickActionBar extends StatelessWidget {
  final VoidCallback onTapMap;
  final VoidCallback onTapNearby;
  final VoidCallback onTapContacts;
  final VoidCallback onTapAi;

  const QuickActionBar({
    super.key,
    required this.onTapMap,
    required this.onTapNearby,
    required this.onTapContacts,
    required this.onTapAi,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            'QUICK EMERGENCY ACTIONS',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                icon: Icons.map_outlined,
                label: 'Map',
                color: AppColors.cyan,
                onTap: onTapMap,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionTile(
                icon: Icons.grid_view_rounded,
                label: 'Nearby',
                color: AppColors.blue,
                onTap: onTapNearby,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionTile(
                icon: Icons.contact_phone_outlined,
                label: 'Contacts',
                color: AppColors.primaryAmber,
                onTap: onTapContacts,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionTile(
                icon: Icons.auto_awesome_outlined,
                label: 'AI Guide',
                color: AppColors.success,
                onTap: onTapAi,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.connectivityCardBg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.connectivityCardBorder),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 9. Quiet, Grounded Bottom Navigation Bar (72–80dp height, #080F1C background, no oversized circle).
class SignalRescueBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const SignalRescueBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bottomNavBg,
        border: Border(
          top: BorderSide(color: AppColors.connectivityCardBorder, width: 1),
        ),
        boxShadow: AppElevation.bottomNav,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.chat_bubble_outline_rounded,
                activeIcon: Icons.chat_bubble_rounded,
                label: 'Chat',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.map_outlined,
                activeIcon: Icons.map_rounded,
                label: 'Map',
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.shield_outlined,
                activeIcon: Icons.shield_rounded,
                label: 'SOS',
                isEmergencyTab: true,
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.handyman_outlined,
                activeIcon: Icons.handyman_rounded,
                label: 'Tools',
              ),
              _buildNavItem(
                index: 4,
                icon: Icons.psychology_outlined,
                activeIcon: Icons.psychology_rounded,
                label: 'AI',
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
    bool isEmergencyTab = false,
  }) {
    final isSelected = currentIndex == index;
    final Color activeColor =
        isEmergencyTab ? AppColors.sosRed : AppColors.primaryAmber;
    final Color itemColor =
        isSelected ? activeColor : AppColors.textSecondary;

    return Expanded(
      child: Semantics(
        selected: isSelected,
        button: true,
        label: label,
        child: InkWell(
          onTap: () => onTabSelected(index),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? activeColor.withValues(alpha: 0.16)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(100),
                    border: isSelected
                        ? Border.all(
                            color: activeColor.withValues(alpha: 0.35),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    size: 22,
                    color: itemColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: itemColor,
                    fontSize: 11.5,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
