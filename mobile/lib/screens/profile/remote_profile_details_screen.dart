import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/call_session.dart';
import '../../models/remote_user_profile.dart';
import '../../providers/theme_provider.dart';
import '../../services/call_history_repository.dart';
import '../../services/call_session_controller.dart';
import '../../services/group_service.dart';
import '../../theme/app_tokens.dart';

class RemoteProfileDetailsScreen extends StatefulWidget {
  const RemoteProfileDetailsScreen({super.key, required this.profile});

  final RemoteUserProfile profile;

  @override
  State<RemoteProfileDetailsScreen> createState() =>
      _RemoteProfileDetailsScreenState();
}

class _RemoteProfileDetailsScreenState
    extends State<RemoteProfileDetailsScreen> {
  final CallHistoryRepository _history = const CallHistoryRepository();
  late Future<List<CallHistoryEntry>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _history.forPeer(widget.profile.userId);
  }

  void _showUnavailable(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final calls = context.watch<CallSessionController>();
    final groups = context
        .watch<GroupService>()
        .groups
        .where(
          (group) => group.members.any(
            (member) => member.deviceId == widget.profile.userId,
          ),
        )
        .toList();
    final availability = calls.availabilityFor(widget.profile);

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        backgroundColor: theme.bg,
        foregroundColor: theme.text,
        elevation: 0,
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Center(
            child: Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTokens.beaconTeal.withValues(alpha: 0.18),
                border: Border.all(color: AppTokens.beaconTeal, width: 2),
              ),
              child: Text(
                widget.profile.initials,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTokens.beaconTeal,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            widget.profile.displayName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.text,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Identity not verified • observed through ${widget.profile.source.toLowerCase()}',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 22),
          _availabilityCard(theme, availability),
          const SizedBox(height: 14),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: availability.isAvailable
                  ? () async {
                      final error = await calls.startOutgoing(widget.profile);
                      if (mounted && error != null) _showUnavailable(error);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTokens.signalYellow,
                foregroundColor: AppTokens.nightNavy,
                disabledBackgroundColor: theme.surfaceSunken,
                disabledForegroundColor: theme.textMuted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                ),
              ),
              icon: const Icon(Icons.call_rounded),
              label: const Text(
                'Voice call nearby',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _showUnavailable(
                'Direct messages are not configured. Community and group mesh chat remain available.',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.text,
                side: BorderSide(color: theme.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                ),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('Message in mesh chat'),
            ),
          ),
          const SizedBox(height: 22),
          _sectionTitle(theme, 'SHARED GROUPS'),
          const SizedBox(height: 8),
          if (groups.isEmpty)
            _infoRow(
              theme,
              icon: Icons.groups_outlined,
              title: 'No shared groups recorded on this device',
              subtitle:
                  'Group membership is only shown when it exists locally.',
            )
          else
            ...groups.map(
              (group) => _infoRow(
                theme,
                icon: Icons.groups_rounded,
                title: group.name,
                subtitle:
                    '${group.memberCount} member${group.memberCount == 1 ? '' : 's'}',
              ),
            ),
          const SizedBox(height: 22),
          _sectionTitle(theme, 'SAFETY'),
          const SizedBox(height: 8),
          _disabledSafetyAction(
            theme,
            icon: Icons.block_outlined,
            title: 'Block user',
            explanation: 'Local safety controls are not configured, so no block action is performed.',
          ),
          _disabledSafetyAction(
            theme,
            icon: Icons.flag_outlined,
            title: 'Report user',
            explanation: 'A verified reporting channel is not configured, so no report is sent.',
          ),
          const SizedBox(height: 22),
          _sectionTitle(theme, 'LOCAL CALL HISTORY'),
          const SizedBox(height: 8),
          FutureBuilder<List<CallHistoryEntry>>(
            future: _historyFuture,
            builder: (context, snapshot) {
              final history = snapshot.data ?? const <CallHistoryEntry>[];
              if (history.isEmpty) {
                return _infoRow(
                  theme,
                  icon: Icons.history_rounded,
                  title: 'No calls recorded',
                  subtitle: 'Only call metadata is stored on this phone. Audio is never recorded.',
                );
              }
              return Column(
                children: [
                  ...history.map((entry) => _historyRow(theme, entry)),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () async {
                        await _history.clearLocalHistory();
                        if (mounted) {
                          setState(
                            () => _historyFuture = _history.forPeer(
                              widget.profile.userId,
                            ),
                          );
                        }
                      },
                      child: const Text('Clear local call history'),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _availabilityCard(
    ThemeProvider theme,
    NearbyCallAvailability availability,
  ) {
    final color = availability.isAvailable
        ? AppTokens.beaconTeal
        : theme.textMuted;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Icon(
            availability.isAvailable
                ? Icons.bluetooth_connected_rounded
                : Icons.portable_wifi_off_rounded,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  availability.isAvailable
                      ? 'Nearby voice available'
                      : 'Nearby voice unavailable',
                  style: TextStyle(
                    color: theme.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  availability.message,
                  style: TextStyle(color: theme.textMuted, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(ThemeProvider theme, String label) => Text(
    label,
    style: TextStyle(
      color: theme.textMuted,
      fontWeight: FontWeight.w800,
      fontSize: 12,
      letterSpacing: 0.8,
    ),
  );

  Widget _infoRow(
    ThemeProvider theme, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: theme.surface,
      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      border: Border.all(color: theme.border),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppTokens.beaconTeal),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: theme.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(color: theme.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _disabledSafetyAction(
    ThemeProvider theme, {
    required IconData icon,
    required String title,
    required String explanation,
  }) => Semantics(
    button: true,
    enabled: false,
    label: '$title unavailable. $explanation',
    child: Opacity(
      opacity: 0.6,
      child: _infoRow(theme, icon: icon, title: title, subtitle: explanation),
    ),
  );

  Widget _historyRow(ThemeProvider theme, CallHistoryEntry entry) => _infoRow(
    theme,
    icon: entry.direction == CallDirection.outgoing
        ? Icons.call_made_rounded
        : Icons.call_received_rounded,
    title:
        '${entry.direction.name == 'outgoing' ? 'Outgoing' : 'Incoming'} • ${entry.status.name}',
    subtitle: entry.durationSeconds > 0
        ? '${entry.durationSeconds}s connected • Nearby Bluetooth/Wi-Fi'
        : 'No audio connection • Nearby Bluetooth/Wi-Fi',
  );
}
