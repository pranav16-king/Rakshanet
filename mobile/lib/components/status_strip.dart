import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/telemetry_provider.dart';
import '../theme/app_tokens.dart';

class StatusStrip extends StatelessWidget {
  const StatusStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final telemetry = context.watch<TelemetryProvider>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (telemetry.showOfflineBanner)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            color: AppTokens.lightWarning,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, size: 16, color: Colors.black87),
                SizedBox(width: 6),
                Text(
                  'OFFLINE MESH MODE ACTIVE — ZERO INTERNET',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        Container(
          height: AppTokens.statusStrip,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: Theme.of(context).cardColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Mesh Count
              Row(
                children: [
                  const Icon(Icons.hub, size: 16, color: AppTokens.beaconTeal),
                  const SizedBox(width: 6),
                  Text(
                    'Mesh: ${telemetry.meshCount}',
                    key: const Key('status_mesh_count'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
              // Internet status
              Row(
                children: [
                  Icon(
                    telemetry.isOnline ? Icons.wifi : Icons.cloud_off,
                    size: 16,
                    color: telemetry.isOnline ? AppTokens.lightSuccess : AppTokens.darkTextMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    telemetry.isOnline ? 'Online' : 'Offline',
                    key: const Key('status_internet_state'),
                    style: TextStyle(
                      fontSize: 13,
                      color: telemetry.isOnline ? AppTokens.lightSuccess : AppTokens.darkTextMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              // GPS Fix
              Row(
                children: [
                  Icon(
                    telemetry.hasGpsFix ? Icons.location_on : Icons.location_off,
                    size: 16,
                    color: telemetry.hasGpsFix ? AppTokens.lightSuccess : AppTokens.sosRed,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    telemetry.hasGpsFix ? 'GPS Fix' : 'No GPS',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              // Battery Level
              Row(
                children: [
                  Icon(
                    telemetry.batteryLevel > 50
                        ? Icons.battery_charging_full
                        : (telemetry.batteryLevel >= 20 ? Icons.battery_alert : Icons.battery_0_bar),
                    size: 16,
                    color: telemetry.batteryLevel < 20 ? AppTokens.sosRed : AppTokens.signalYellow,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${telemetry.batteryLevel}%',
                    key: const Key('status_battery_level'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
