import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/mesh_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/mesh_device.dart';
import '../../models/remote_user_profile.dart';
import '../profile/remote_profile_details_screen.dart';
import '../../theme/app_tokens.dart';

class NearbyTab extends StatelessWidget {
  const NearbyTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final mesh = context.watch<MeshProvider>();

    final cardBg = theme.surface;
    final borderColor = theme.border;
    final textColor = theme.text;
    final textMuted = theme.textMuted;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Mesh Status Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF4CD08A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${mesh.connectedPeerCount} Mesh Peers Online',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      mesh.isScanning ? Icons.sync : Icons.refresh,
                      color: AppTokens.signalYellow,
                    ),
                    onPressed: () => mesh.startScan(),
                    tooltip: 'Scan for devices',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Direct BLE & Wi-Fi Direct multi-hop relay. Offline messages are forwarded autonomously.',
                style: TextStyle(color: textMuted, fontSize: 13),
              ),
              const SizedBox(height: 14),

              // Radio Mode Selector
              Text(
                'Radio Profile:',
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Normal'),
                    selected: mesh.radioMode == RadioMode.normal,
                    selectedColor: AppTokens.signalYellow,
                    onSelected: (_) => mesh.setRadioMode(RadioMode.normal),
                  ),
                  ChoiceChip(
                    label: const Text('Low Power'),
                    selected: mesh.radioMode == RadioMode.lowPower,
                    selectedColor: AppTokens.signalYellow,
                    onSelected: (_) => mesh.setRadioMode(RadioMode.lowPower),
                  ),
                  ChoiceChip(
                    label: const Text('Emergency'),
                    selected: mesh.radioMode == RadioMode.emergency,
                    selectedColor: AppTokens.sosRed,
                    labelStyle: TextStyle(
                      color: mesh.radioMode == RadioMode.emergency
                          ? Colors.white
                          : textColor,
                    ),
                    onSelected: (_) => mesh.setRadioMode(RadioMode.emergency),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'Discovered Devices',
          style: TextStyle(
            color: textColor,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),

        if (mesh.isScanning)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(
              color: AppTokens.signalYellow,
              backgroundColor: Color(0xFF1E293B),
            ),
          ),

        if (mesh.nearbyDevices.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(color: theme.border),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.radar_rounded,
                  size: 48,
                  color: AppTokens.beaconTeal,
                ),
                const SizedBox(height: 14),
                Text(
                  'Scanning for Nearby Mesh Nodes...',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No peer devices detected in radio range yet. RakshaNet will automatically connect via BLE & Wi-Fi Direct when survivors or responders are nearby.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.7),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          )
        else
          ...mesh.nearbyDevices.map(
            (device) => _buildDeviceCard(context, device, theme),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDeviceCard(
    BuildContext context,
    MeshDevice device,
    ThemeProvider theme,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => RemoteProfileDetailsScreen(
              profile: RemoteUserProfile.fromMeshDevice(device),
            ),
          ),
        ),
        child: Semantics(
          button: true,
          label: 'Open ${device.displayName} profile',
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(color: theme.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  ),
                  child: const Icon(
                    Icons.devices_other,
                    color: AppTokens.beaconTeal,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            device.displayName,
                            style: TextStyle(
                              color: theme.text,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTokens.beaconTeal.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppTokens.radiusXs,
                              ),
                            ),
                            child: Text(
                              '${device.hopCount} hop',
                              style: const TextStyle(
                                color: AppTokens.beaconTeal,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Nearby device • ${device.proximityDisplay} • ${device.signalStrength} dBm',
                        style: TextStyle(
                          color: theme.textMuted,
                          fontSize: 12,
                          fontFamily: 'monospace',
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
