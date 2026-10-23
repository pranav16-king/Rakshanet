import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../providers/telemetry_provider.dart';
import '../screens/tools/live_map_screen.dart';
import '../services/device_identity_service.dart';
import '../services/location/location_service.dart';
import '../services/sos_alert_service.dart';
import '../theme/app_tokens.dart';
import '../utils/haversine_distance.dart';

/// Global SOS Emergency Overlay
///
/// Wraps the application root or main shell to immediately display an
/// attention-grabbing emergency modal/banner over ANY screen whenever an incoming
/// or local SOS distress packet is received.
///
/// Features:
/// 1. Pulsing high-visibility red SOS badge (`#D92D20` with multi-ring beacon pulse)
/// 2. Emergency siren icon with interactive MUTE/UNMUTE audio toggle
/// 3. Sender Identity: Display Name & Device ID (e.g. `Priya Sharma • SR-9A1C`)
/// 4. Precise location: GPS Coordinates + real-time estimated distance in meters/km
/// 5. Human-readable timestamp ("Just now" / "1m ago")
/// 6. Action buttons:
///    - "Acknowledge & Respond": Dispatches signed mesh ACK packet to sender
///    - "View on Map": Centers and animates LiveMapScreen to distress coordinates
///    - "Silence Alarm": Mutes audio siren while keeping alert visible
class GlobalSosOverlay extends StatefulWidget {
  final Widget child;

  const GlobalSosOverlay({super.key, required this.child});

  @override
  State<GlobalSosOverlay> createState() => _GlobalSosOverlayState();
}

class _GlobalSosOverlayState extends State<GlobalSosOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;
  Timer? _tickerTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _pulseScale = Tween<double>(begin: 1.0, end: 1.45).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutQuad),
    );
    _pulseOpacity = Tween<double>(begin: 0.65, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutQuad),
    );

    // Refresh relative timestamp display every 5 seconds while active
    _tickerTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && SosAlertService.instance.currentAlert != null) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _onViewOnMap(BuildContext context, EmergencyAlertEvent alert) {
    final myDeviceId = DeviceIdentityService.instance.deviceId;
    final isSelf = alert.isLocal ||
        (alert.senderDeviceId.isNotEmpty && alert.senderDeviceId == myDeviceId);

    if (alert.lat != null && alert.lng != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LiveMapScreen(
            initialCenter: LatLng(alert.lat!, alert.lng!),
            initialZoom: isSelf ? 17.0 : 16.5,
            initialNavTarget: isSelf ? null : LatLng(alert.lat!, alert.lng!),
            initialNavTargetName: isSelf ? null : 'SOS: ${alert.formattedSender}',
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const LiveMapScreen(),
        ),
      );
    }
  }

  Future<void> _onAcknowledgeAndRespond(
    BuildContext context,
    EmergencyAlertEvent alert,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final myDeviceId = DeviceIdentityService.instance.deviceId;
    final isSelf = alert.isLocal ||
        (alert.senderDeviceId.isNotEmpty && alert.senderDeviceId == myDeviceId);

    await SosAlertService.instance.acknowledgeAndRespond(alert);

    if (isSelf) {
      messenger?.showSnackBar(
        const SnackBar(
          backgroundColor: AppTokens.beaconTeal,
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Distress beacon active & broadcasting. Overlay dismissed.',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
          duration: Duration(seconds: 4),
        ),
      );
    } else {
      messenger?.showSnackBar(
        SnackBar(
          backgroundColor: AppTokens.beaconTeal,
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Distress ACK dispatched via mesh radio to ${alert.formattedSender}.',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base application screen tree
        widget.child,

        // High-priority SOS emergency overlay listener
        ValueListenableBuilder<EmergencyAlertEvent?>(
          valueListenable: SosAlertService.instance.activeAlertNotifier,
          builder: (context, alert, _) {
            if (alert == null) {
              return const SizedBox.shrink();
            }

            return _EmergencyBannerOverlay(
              alert: alert,
              pulseController: _pulseController,
              pulseScale: _pulseScale,
              pulseOpacity: _pulseOpacity,
              onViewOnMap: () => _onViewOnMap(context, alert),
              onAcknowledgeAndRespond: () =>
                  _onAcknowledgeAndRespond(context, alert),
              onDismiss: () => SosAlertService.instance.dismissAlert(),
              onToggleSiren: () {
                if (SosAlertService.instance.isMuted) {
                  SosAlertService.instance.unmuteSiren();
                } else {
                  SosAlertService.instance.muteSiren();
                }
              },
            );
          },
        ),
      ],
    );
  }
}

class _EmergencyBannerOverlay extends StatelessWidget {
  final EmergencyAlertEvent alert;
  final AnimationController pulseController;
  final Animation<double> pulseScale;
  final Animation<double> pulseOpacity;
  final VoidCallback onViewOnMap;
  final VoidCallback onAcknowledgeAndRespond;
  final VoidCallback onDismiss;
  final VoidCallback onToggleSiren;

  const _EmergencyBannerOverlay({
    required this.alert,
    required this.pulseController,
    required this.pulseScale,
    required this.pulseOpacity,
    required this.onViewOnMap,
    required this.onAcknowledgeAndRespond,
    required this.onDismiss,
    required this.onToggleSiren,
  });

  @override
  Widget build(BuildContext context) {
    final myDeviceId = DeviceIdentityService.instance.deviceId;
    final isSelf = alert.isLocal ||
        (alert.senderDeviceId.isNotEmpty && alert.senderDeviceId == myDeviceId);

    // Read current user GPS from LocationService & TelemetryProvider for real distance calculation
    final telemetry = Provider.of<TelemetryProvider?>(context, listen: true);
    final localFix = LocationService.instance.currentFix;
    final userLat = telemetry?.latitude ?? localFix?.latitude;
    final userLng = telemetry?.longitude ?? localFix?.longitude;
    final userAcc = localFix?.horizontalAccuracyMeters ?? 20.0;
    final userTs = localFix?.timestamp ?? DateTime.now().millisecondsSinceEpoch;

    final geoResult = HaversineDistance.calculateDistanceNullable(
      lat1: userLat,
      lng1: userLng,
      accuracy1: userAcc,
      timestamp1: userTs,
      lat2: alert.lat,
      lng2: alert.lng,
      accuracy2: 15.0,
      timestamp2: alert.timestamp.millisecondsSinceEpoch,
    );

    final isSirenMuted = SosAlertService.instance.isMuted;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Semi-transparent emergency red vignette barrier
          Positioned.fill(
            child: GestureDetector(
              onTap: () {}, // Blocks touches from passing accidentally to background
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTokens.sosRed.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.45),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Sliding Floating Emergency Alert Card (Safe Area aware)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF140707), // Extreme high-contrast dark red obsidian
                      borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                      border: Border.all(
                        color: AppTokens.sosRed,
                        width: 2.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTokens.sosRed.withValues(alpha: 0.55),
                          blurRadius: 24,
                          spreadRadius: 3,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.8),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. Top Emergency Header Strip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: const BoxDecoration(
                            color: AppTokens.sosRed,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(AppTokens.radiusLg - 2),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Pulsing SOS Beacon Badge
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  AnimatedBuilder(
                                    animation: pulseController,
                                    builder: (context, _) => Container(
                                      width: 26 * pulseScale.value,
                                      height: 26 * pulseScale.value,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(
                                          alpha: pulseOpacity.value * 0.7,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                    child: const Icon(
                                      Icons.warning_rounded,
                                      size: 15,
                                      color: AppTokens.sosRed,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isSelf
                                      ? 'LOCAL DISTRESS BEACON ACTIVE'
                                      : 'GLOBAL SOS DISTRESS ALERT',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              // Relative timestamp badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  borderRadius:
                                      BorderRadius.circular(AppTokens.radiusPill),
                                ),
                                child: Text(
                                  alert.timeAgo,
                                  style: const TextStyle(
                                    color: AppTokens.signalYellow,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Dismiss Close Button
                              InkWell(
                                onTap: onDismiss,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 2. Alert Body Content
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Sender row & Siren Sound Mute button
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Large SOS Beacon Badge Icon
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppTokens.sosRed.withValues(alpha: 0.18),
                                      borderRadius:
                                          BorderRadius.circular(AppTokens.radiusMd),
                                      border: Border.all(
                                        color: AppTokens.sosRed.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'SOS',
                                        style: TextStyle(
                                          color: AppTokens.sosRed,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isSelf
                                              ? 'You (My Distress Beacon)'
                                              : alert.formattedSender,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Category: ${alert.category} • ${alert.casualties} ${alert.casualties == 1 ? 'Person' : 'People'}',
                                          style: TextStyle(
                                            color: isSelf
                                                ? AppTokens.signalYellow
                                                : const Color(0xFFFF8A80),
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Siren Sound Toggle Button
                                  InkWell(
                                    onTap: onToggleSiren,
                                    borderRadius:
                                        BorderRadius.circular(AppTokens.radiusMd),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSirenMuted
                                            ? Colors.white.withValues(alpha: 0.08)
                                            : AppTokens.sosRed.withValues(alpha: 0.25),
                                        borderRadius:
                                            BorderRadius.circular(AppTokens.radiusMd),
                                        border: Border.all(
                                          color: isSirenMuted
                                              ? Colors.white.withValues(alpha: 0.25)
                                              : AppTokens.sosRed,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isSirenMuted
                                                ? Icons.volume_off_rounded
                                                : Icons.volume_up_rounded,
                                            color: isSirenMuted
                                                ? Colors.white70
                                                : AppTokens.signalYellow,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            isSirenMuted
                                                ? 'Muted'
                                                : 'Siren On',
                                            style: TextStyle(
                                              color: isSirenMuted
                                                  ? Colors.white70
                                                  : Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Location & Distance Card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius:
                                      BorderRadius.circular(AppTokens.radiusMd),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_rounded,
                                      color: AppTokens.signalYellow,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            alert.formattedCoordinates,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(
                                              isSelf
                                                  ? "Origin: Your Location (Distress Beacon)"
                                                  : "Distance: ${geoResult.summaryLabel}",
                                              style: TextStyle(
                                                color: isSelf
                                                    ? AppTokens.beaconTeal
                                                    : (geoResult.isCoordinatesAvailable
                                                        ? AppTokens.signalYellow
                                                        : AppTokens.darkTextMuted),
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          if (!geoResult.isCoordinatesAvailable &&
                                              geoResult.fallbackPrompt != null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Text(
                                                geoResult.fallbackPrompt!,
                                                style: const TextStyle(
                                                  color: Color(0xFFFFB4AB),
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Medical / Situational Notes if provided
                              if (alert.medicalNotes != null &&
                                  alert.medicalNotes!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTokens.sosRed.withValues(alpha: 0.08),
                                    borderRadius:
                                        BorderRadius.circular(AppTokens.radiusMd),
                                    border: Border.all(
                                      color: AppTokens.sosRed.withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Text(
                                    alert.medicalNotes!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFFFEE4E2),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 14),

                              // 3. Action Buttons Row (Acknowledge & Respond, View on Map, Silence)
                              Row(
                                children: [
                                  // Primary Action: Acknowledge & Respond (or Acknowledge Status for self)
                                  Expanded(
                                    flex: 6,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isSelf ? AppTokens.beaconTeal : AppTokens.sosRed,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size.fromHeight(46),
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppTokens.radiusMd,
                                          ),
                                        ),
                                      ),
                                      onPressed: onAcknowledgeAndRespond,
                                      icon: const Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 18,
                                      ),
                                      label: Text(
                                        isSelf ? "Acknowledge Status" : "Acknowledge & Respond",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Secondary Action: View on Map
                                  Expanded(
                                    flex: 4,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTokens.signalYellow,
                                        side: const BorderSide(
                                          color: AppTokens.signalYellow,
                                          width: 1.5,
                                        ),
                                        minimumSize: const Size.fromHeight(46),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppTokens.radiusMd,
                                          ),
                                        ),
                                      ),
                                      onPressed: onViewOnMap,
                                      icon: const Icon(
                                        Icons.map_rounded,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'View Map',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Third Action: Silence Alarm
                              SizedBox(
                                width: double.infinity,
                                height: 38,
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white70,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppTokens.radiusMd,
                                      ),
                                    ),
                                  ),
                                  onPressed: onToggleSiren,
                                  icon: Icon(
                                    isSirenMuted
                                        ? Icons.volume_up_rounded
                                        : Icons.volume_off_rounded,
                                    size: 16,
                                  ),
                                  label: Text(
                                    isSirenMuted
                                        ? 'Unmute Alarm Siren'
                                        : 'Silence Siren Alarm (Keep Alert on Screen)',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
