import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../providers/sos_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/incident_dispatch_service.dart';
import '../../services/location/location_service.dart';
import '../../services/sos_alert_service.dart';
import '../../theme/app_tokens.dart';
import '../../utils/haversine_distance.dart';
import '../../widgets/beacon_sos_button.dart';
import 'live_map_screen.dart';

/// Screen displaying active emergency SOS distress alerts, high-visibility siren controls,
/// reliable location positioning, and geospatial distance calculation between rescue nodes.
///
/// Implements Spec Sections 4 & 5 ("Reliable device location" & "Calculate distance between two users").
class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _pulseScale = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutQuad),
    );
    _pulseOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutQuad),
    );

    // Refresh distance and relative time every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _openMapToDistress(double? lat, double? lng, {String? targetName}) {
    if (lat != null && lng != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LiveMapScreen(
            initialCenter: LatLng(lat, lng),
            initialZoom: 16.5,
            initialNavTarget: LatLng(lat, lng),
            initialNavTargetName: targetName ?? 'SOS Distress Node',
          ),
        ),
      );
    } else {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const LiveMapScreen()));
    }
  }

  Future<void> _handleSosTriggered(DeviceLocationFix? fix) async {
    try {
      final effectiveFix = fix ??
          LocationService.instance.currentLocation ??
          LocationService.instance.currentFix ??
          LocationService.instance.lastKnownPosition;
      final result = await IncidentDispatchService().dispatchSos(
        category: 'Other',
        peopleCount: 1,
        initialFix: effectiveFix,
      );
      final lat = result.locationFix?.latitude ?? effectiveFix?.latitude;
      final lng = result.locationFix?.longitude ?? effectiveFix?.longitude;
      SosProvider.instance.triggerLocalSos(
        category: result.report.type.label,
        peopleCount: result.report.peopleCount,
        latitude: lat,
        longitude: lng,
        messageId: result.report.id,
      );

      if (mounted) {
        final targetLoc = (lat != null && lng != null)
            ? LatLng(lat, lng)
            : null;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LiveMapScreen(
              initialCenter: targetLoc,
              initialZoom: 16.5,
              initialNavTarget: targetLoc,
              initialNavTargetName: 'Your SOS location',
            ),
          ),
        );
      }
    } catch (error) {
      debugPrint('[SosScreen] SOS dispatch failed: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('SOS could not be saved: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final alertService = SosAlertService.instance;
    final locationService = LocationService.instance;
    final currentAlert = alertService.currentAlert;
    final alertHistory = alertService.alertHistory;
    final localFix = locationService.currentFix;

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        backgroundColor: theme.surface,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTokens.sosRed,
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              ),
              child: const Text(
                'SOS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Emergency Distress Center',
              style: TextStyle(
                color: theme.text,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: alertService.isMutedNotifier,
            builder: (context, isMuted, _) {
              return IconButton(
                tooltip: isMuted ? 'Unmute Siren Alarm' : 'Mute Siren Alarm',
                icon: Icon(
                  isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: isMuted ? theme.textMuted : AppTokens.signalYellow,
                ),
                onPressed: () {
                  if (isMuted) {
                    alertService.unmuteSiren();
                  } else {
                    alertService.muteSiren();
                  }
                },
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Current Device Location & GNSS Sensor Status
          _buildDeviceLocationCard(theme, localFix),
          const SizedBox(height: 16),

          // 2. Active Distress Alert (if present)
          if (currentAlert != null) ...[
            _buildActiveDistressBanner(theme, currentAlert, localFix),
            const SizedBox(height: 16),
          ],

          // 3. Central Emergency Beacon Trigger
          Center(
            child: Column(
              children: [
                const SizedBox(height: 12),
                BeaconSosButton(
                  onTriggered: () => _handleSosTriggered(localFix),
                ),
                const SizedBox(height: 10),
                Text(
                  'Press and hold for 1.5s to broadcast Distress Beacon',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.textMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. Incident & Distress History Log with Geospatial Distance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Distress Alerts & Incident Log',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${alertHistory.length} total',
                style: TextStyle(color: theme.textMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (alertHistory.isEmpty)
            _buildEmptyAlertHistoryCard(theme)
          else
            ...alertHistory.map(
              (alert) => _buildAlertHistoryCard(theme, alert, localFix),
            ),
        ],
      ),
    );
  }

  /// Card showing local device position resolved via priority hierarchy
  Widget _buildDeviceLocationCard(ThemeProvider theme, DeviceLocationFix? fix) {
    final hasFix = fix != null;
    final isStale = fix?.isStale ?? true;

    Color badgeColor;
    String statusTitle;
    if (!hasFix) {
      badgeColor = AppTokens.darkTextMuted;
      statusTitle = 'Acquiring Positioning...';
    } else if (isStale) {
      badgeColor = AppTokens.warningAmber;
      statusTitle = 'Last Known Location (Stale fix)';
    } else if (fix.source == LocationFixSource.hardwareGps) {
      badgeColor = AppTokens.beaconTeal;
      statusTitle = 'GNSS Hardware Constellation Fix';
    } else if (fix.source == LocationFixSource.fusedGps) {
      badgeColor = AppTokens.beaconTeal;
      statusTitle = 'Fresh Fused Network/GPS Fix';
    } else {
      badgeColor = AppTokens.signalYellow;
      statusTitle = 'Peer Mesh Multilateration Fix';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(
          color: isStale ? theme.border : badgeColor.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasFix
                    ? Icons.my_location_rounded
                    : Icons.location_searching_rounded,
                color: badgeColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusTitle,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (hasFix)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isStale
                        ? AppTokens.warningAmber.withValues(alpha: 0.15)
                        : AppTokens.beaconTeal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  ),
                  child: Text(
                    isStale ? 'STALE' : 'LIVE',
                    style: TextStyle(
                      color: isStale
                          ? AppTokens.warningAmber
                          : AppTokens.beaconTeal,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (hasFix) ...[
            Text(
              fix.formattedCoordinates,
              style: TextStyle(
                color: theme.text,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Accuracy: ${fix.formattedAccuracy}',
                  style: TextStyle(color: theme.textMuted, fontSize: 12),
                ),
                Text(' • ', style: TextStyle(color: theme.textMuted)),
                Text(
                  'Source: ${fix.source}',
                  style: TextStyle(color: theme.textMuted, fontSize: 12),
                ),
                Text(' • ', style: TextStyle(color: theme.textMuted)),
                Text(
                  'Age: ${fix.ageSeconds}s',
                  style: TextStyle(color: theme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ] else ...[
            Text(
              'Awaiting GPS / Network satellite fix. Move outdoors or within range of peer anchors.',
              style: TextStyle(color: theme.textMuted, fontSize: 12.5),
            ),
          ],
        ],
      ),
    );
  }

  /// Active distress alert banner with full GeospatialDistanceResult calculations
  Widget _buildActiveDistressBanner(
    ThemeProvider theme,
    EmergencyAlertEvent alert,
    DeviceLocationFix? localFix,
  ) {
    final distanceResult = HaversineDistance.calculateDistanceNullable(
      lat1: localFix?.latitude,
      lng1: localFix?.longitude,
      accuracy1: localFix?.horizontalAccuracyMeters ?? 20.0,
      timestamp1: localFix?.timestamp ?? DateTime.now().millisecondsSinceEpoch,
      lat2: alert.lat,
      lng2: alert.lng,
      accuracy2: 15.0,
      timestamp2: alert.timestamp.millisecondsSinceEpoch,
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B0707),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: AppTokens.sosRed, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: AppTokens.sosRed.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Emergency Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: AppTokens.sosRed,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTokens.radiusMd - 2),
              ),
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) => Container(
                    width: 14 * _pulseScale.value,
                    height: 14 * _pulseScale.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(
                        alpha: _pulseOpacity.value * 0.9,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'CRITICAL DISTRESS ACTIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Text(
                  alert.timeAgo,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        alert.formattedSender,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${alert.casualties} Casualties',
                      style: const TextStyle(
                        color: AppTokens.signalYellow,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Distance calculation summary
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            distanceResult.isCoordinatesAvailable
                                ? Icons.straighten_rounded
                                : Icons.bluetooth_searching_rounded,
                            color: AppTokens.signalYellow,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              distanceResult.summaryLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  distanceResult.freshnessStatus ==
                                      GeospatialFreshness.live
                                  ? AppTokens.beaconTeal.withValues(alpha: 0.25)
                                  : AppTokens.warningAmber.withValues(
                                      alpha: 0.25,
                                    ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              distanceResult.freshnessStatus,
                              style: TextStyle(
                                color:
                                    distanceResult.freshnessStatus ==
                                        GeospatialFreshness.live
                                    ? AppTokens.beaconTeal
                                    : AppTokens.warningAmber,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!distanceResult.isCoordinatesAvailable &&
                          distanceResult.fallbackPrompt != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          distanceResult.fallbackPrompt!,
                          style: const TextStyle(
                            color: Color(0xFFFFB4AB),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTokens.beaconTeal,
                          foregroundColor: AppTokens.nightNavy,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTokens.radiusSm,
                            ),
                          ),
                        ),
                        onPressed: () => _openMapToDistress(
                          alert.lat,
                          alert.lng,
                          targetName: alert.formattedSender,
                        ),
                        icon: const Icon(Icons.map_rounded, size: 16),
                        label: const Text(
                          'View On Map',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTokens.radiusSm,
                            ),
                          ),
                        ),
                        onPressed: () => SosAlertService.instance
                            .acknowledgeAndRespond(alert),
                        icon: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 16,
                        ),
                        label: const Text('Acknowledge'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// History log item with GeospatialDistanceResult
  Widget _buildAlertHistoryCard(
    ThemeProvider theme,
    EmergencyAlertEvent alert,
    DeviceLocationFix? localFix,
  ) {
    final distanceResult = HaversineDistance.calculateDistanceNullable(
      lat1: localFix?.latitude,
      lng1: localFix?.longitude,
      accuracy1: localFix?.horizontalAccuracyMeters ?? 25.0,
      timestamp1: localFix?.timestamp ?? DateTime.now().millisecondsSinceEpoch,
      lat2: alert.lat,
      lng2: alert.lng,
      accuracy2: 15.0,
      timestamp2: alert.timestamp.millisecondsSinceEpoch,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      onTap: () => _openMapToDistress(
        alert.lat,
        alert.lng,
        targetName: alert.formattedSender,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(color: theme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  alert.formattedSender,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  alert.timeAgo,
                  style: TextStyle(color: theme.textMuted, fontSize: 11.5),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Distance: ${distanceResult.summaryLabel}',
                    style: const TextStyle(
                      color: AppTokens.sosRed,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTokens.sosRed,
                  size: 18,
                ),
              ],
            ),
            if (!distanceResult.isCoordinatesAvailable &&
                distanceResult.fallbackPrompt != null) ...[
              const SizedBox(height: 3),
              Text(
                distanceResult.fallbackPrompt!,
                style: TextStyle(color: theme.textMuted, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAlertHistoryCard(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: theme.border),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.shield_outlined, color: AppTokens.beaconTeal, size: 36),
            const SizedBox(height: 8),
            Text(
              'No Active SOS Distress Signals',
              style: TextStyle(
                color: theme.text,
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'All mesh nodes in range are operating normally.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textMuted, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}
