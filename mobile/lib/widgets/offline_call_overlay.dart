import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/call_session.dart';
import '../providers/theme_provider.dart';
import '../services/call_session_controller.dart';
import '../theme/app_tokens.dart';

/// App-foreground-only nearby-call UI. It deliberately has no notification or
/// background service: capture/playback is stopped as soon as the app pauses.
class OfflineCallOverlay extends StatelessWidget {
  const OfflineCallOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Consumer<CallSessionController>(
          builder: (context, calls, _) {
            final session = calls.session;
            if (session == null) return const SizedBox.shrink();
            return _NearbyCallView(session: session);
          },
        ),
      ],
    );
  }
}

class _NearbyCallView extends StatelessWidget {
  const _NearbyCallView({required this.session});

  final NearbyCallSession session;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final calls = context.read<CallSessionController>();
    final isIncoming = session.state == NearbyCallState.incoming;
    final isActive = session.state == NearbyCallState.active;
    final isTerminal = session.isTerminal;

    return Material(
      color: theme.bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTokens.beaconTeal.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                      border: Border.all(
                        color: AppTokens.beaconTeal.withValues(alpha: 0.55),
                      ),
                    ),
                    child: const Text(
                      'NEARBY AUDIO • OFFLINE',
                      style: TextStyle(
                        color: AppTokens.beaconTeal,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isTerminal)
                    IconButton(
                      tooltip: 'Close call',
                      onPressed: calls.dismissTerminalCall,
                      icon: Icon(Icons.close_rounded, color: theme.text),
                    ),
                ],
              ),
              const Spacer(),
              Container(
                width: 112,
                height: 112,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTokens.beaconTeal.withValues(alpha: 0.18),
                  border: Border.all(color: AppTokens.beaconTeal, width: 2),
                ),
                child: Text(
                  _initials(session.peerName),
                  style: const TextStyle(
                    color: AppTokens.beaconTeal,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                session.peerName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.text,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _stateLabel(session),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isTerminal ? theme.textMuted : AppTokens.beaconTeal,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (isActive) ...[
                const SizedBox(height: 8),
                _CallDuration(connectedAt: session.connectedAt!),
              ],
              const SizedBox(height: 10),
              Text(
                session.message ?? 'No internet connection is used.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.textMuted, fontSize: 13),
              ),
              const Spacer(),
              if (isIncoming) ...[
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.call_end_rounded,
                        label: 'Decline',
                        background: theme.surface,
                        foreground: AppTokens.sosRed,
                        border: AppTokens.sosRed.withValues(alpha: 0.55),
                        onPressed: () => calls.rejectIncoming(),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.call_rounded,
                        label: 'Accept',
                        background: AppTokens.signalYellow,
                        foreground: AppTokens.nightNavy,
                        onPressed: () async {
                          final error = await calls.acceptIncoming();
                          if (context.mounted && error != null) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text(error)));
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ] else if (isActive) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _RoundControl(
                      icon: session.isMuted
                          ? Icons.mic_off_rounded
                          : Icons.mic_rounded,
                      label: session.isMuted ? 'Unmute' : 'Mute',
                      active: session.isMuted,
                      onPressed: () => calls.toggleMute(),
                    ),
                    _RoundControl(
                      icon: session.isSpeakerOn
                          ? Icons.volume_up_rounded
                          : Icons.hearing_rounded,
                      label: session.isSpeakerOn ? 'Speaker' : 'Earpiece',
                      active: session.isSpeakerOn,
                      onPressed: () => calls.toggleSpeaker(),
                    ),
                    _RoundControl(
                      icon: Icons.call_end_rounded,
                      label: 'End call',
                      active: true,
                      danger: true,
                      onPressed: () => calls.endCall(),
                    ),
                  ],
                ),
              ] else if (isTerminal) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTokens.signalYellow,
                      foregroundColor: AppTokens.nightNavy,
                    ),
                    onPressed: calls.dismissTerminalCall,
                    child: const Text(
                      'Close',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTokens.sosRed,
                      side: BorderSide(
                        color: AppTokens.sosRed.withValues(alpha: 0.65),
                      ),
                    ),
                    onPressed:
                        session.direction == CallDirection.outgoing &&
                            (session.state == NearbyCallState.outgoing ||
                                session.state == NearbyCallState.ringing)
                        ? () => calls.cancelOutgoing()
                        : () => calls.endCall(),
                    icon: const Icon(Icons.call_end_rounded),
                    label: const Text(
                      'Cancel call',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _stateLabel(NearbyCallSession session) {
    switch (session.state) {
      case NearbyCallState.outgoing:
        return 'Calling nearby device…';
      case NearbyCallState.ringing:
        return 'Ringing…';
      case NearbyCallState.incoming:
        return 'Incoming voice call';
      case NearbyCallState.connecting:
        return 'Connecting local audio…';
      case NearbyCallState.active:
        return 'Connected';
      case NearbyCallState.ending:
        return 'Ending call…';
      case NearbyCallState.ended:
      case NearbyCallState.failed:
        return 'Call finished';
      case NearbyCallState.idle:
        return '';
    }
  }

  String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return '?';
    return '${words.first[0]}${words.length > 1 && words[1].isNotEmpty ? words[1][0] : ''}'
        .toUpperCase();
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
    this.border,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final Color? border;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 58,
    child: ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        side: border == null ? null : BorderSide(color: border!),
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    ),
  );
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.icon,
    required this.label,
    required this.active,
    required this.onPressed,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool danger;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final color = danger
        ? AppTokens.sosRed
        : (active ? AppTokens.signalYellow : theme.surface);
    final iconColor = danger || active ? Colors.white : theme.text;
    return Semantics(
      button: true,
      label: label,
      child: Column(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: iconColor,
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
              ),
              onPressed: onPressed,
              child: Icon(icon),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: theme.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _CallDuration extends StatefulWidget {
  const _CallDuration({required this.connectedAt});

  final DateTime connectedAt;

  @override
  State<_CallDuration> createState() => _CallDurationState();
}

class _CallDurationState extends State<_CallDuration> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(widget.connectedAt);
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return Text(
      '$minutes:$seconds',
      style: const TextStyle(
        color: AppTokens.signalYellow,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}
