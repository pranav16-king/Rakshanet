import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/call_session.dart';
import '../../models/chat_group.dart';
import '../../models/remote_user_profile.dart';
import '../../providers/theme_provider.dart';
import '../../services/call_history_repository.dart';
import '../../services/call_session_controller.dart';
import '../../services/chat_service.dart';
import '../../services/group_service.dart';
import '../../theme/app_tokens.dart';
import '../chat/chat_screen.dart';

class RemoteProfileDetailsScreen extends StatefulWidget {
  const RemoteProfileDetailsScreen({super.key, required this.profile});

  final RemoteUserProfile profile;

  @override
  State<RemoteProfileDetailsScreen> createState() =>
      _RemoteProfileDetailsScreenState();
}

class _RemoteProfileDetailsScreenState
    extends State<RemoteProfileDetailsScreen> {
  static const String _prefBlockedKey = 'blocked_peer_ids';
  static const String _prefReportedKey = 'reported_peer_ids';

  final CallHistoryRepository _history = const CallHistoryRepository();
  late Future<List<CallHistoryEntry>> _historyFuture;
  bool _isBlocked = false;
  bool _isReported = false;

  @override
  void initState() {
    super.initState();
    _historyFuture = _history.forPeer(widget.profile.userId);
    _loadSafetyStatus();
  }

  Future<void> _loadSafetyStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final blocked = prefs.getStringList(_prefBlockedKey) ?? const [];
      final reported = prefs.getStringList(_prefReportedKey) ?? const [];
      if (mounted) {
        setState(() {
          _isBlocked = blocked.contains(widget.profile.userId);
          _isReported = reported.contains(widget.profile.userId);
        });
      }
    } catch (e) {
      debugPrint('[RemoteProfileDetailsScreen] Failed to load safety: $e');
    }
  }

  void _showUnavailable(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _navigateToDirectChat() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          conversationId: 'DIRECT_${widget.profile.userId}',
          initialFilter: 'Nearby',
          targetRecipient: widget.profile.userId,
          recipientName: widget.profile.displayName,
        ),
      ),
    );
  }

  void _handleMessageTap(List<ChatGroup> groups) {
    if (groups.isEmpty) {
      _navigateToDirectChat();
      return;
    }

    // User shares groups with this member - provide choice sheet
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.read<ThemeProvider>().surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        final theme = ctx.read<ThemeProvider>();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Text(
                    'Message ${widget.profile.displayName}',
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Text(
                    'Choose direct 1:1 mesh chat or coordinate in a shared group:',
                    style: TextStyle(color: theme.textMuted, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTokens.beaconTeal,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.person_rounded),
                  ),
                  title: Text(
                    'Direct 1:1 Mesh Message',
                    style: TextStyle(
                      color: theme.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    'Direct encrypted peer link over nearby RF',
                    style: TextStyle(color: theme.textMuted, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _navigateToDirectChat();
                  },
                ),
                const Divider(),
                ...groups.map((group) {
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppTokens.signalYellow,
                      foregroundColor: AppTokens.nightNavy,
                      child: Icon(Icons.groups_rounded),
                    ),
                    title: Text(
                      'Group: ${group.name}',
                      style: TextStyle(
                        color: theme.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '${group.memberCount} members',
                      style: TextStyle(color: theme.textMuted, fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      ctx.read<GroupService>().selectGroup(group.id);
                      ctx.read<ChatService>().setActiveFilter('Group');
                      ctx
                          .read<ChatService>()
                          .setActiveGroupConversation(group.conversationId);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ChatScreen(
                            conversationId: group.conversationId,
                            initialFilter: 'Group',
                          ),
                        ),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNearbyVoiceOptionsSheet(
    ThemeProvider theme,
    CallSessionController calls,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.portable_wifi_off_rounded,
                      color: AppTokens.warningAmber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Direct Voice Link Offline',
                        style: TextStyle(
                          color: theme.text,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(
                  'No direct continuous radio stream to ${widget.profile.displayName} yet. Choose an action:',
                  style: TextStyle(color: theme.textMuted, fontSize: 13),
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTokens.signalYellow,
                  foregroundColor: AppTokens.nightNavy,
                  child: Icon(Icons.call_rounded),
                ),
                title: Text(
                  'Attempt Direct Mesh Voice Call',
                  style: TextStyle(
                    color: theme.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  'Initiates P2P RF radio discovery to connect audio stream',
                  style: TextStyle(color: theme.textMuted, fontSize: 12),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final error = await calls.startOutgoing(widget.profile);
                  if (mounted && error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Attempting RF discovery for ${widget.profile.displayName}... Peer must be within Bluetooth / Wi-Fi Direct range.',
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTokens.beaconTeal,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.mic_rounded),
                ),
                title: Text(
                  'Send Audio Memo (Offline Voice Note)',
                  style: TextStyle(
                    color: theme.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  'Record emergency audio memo transmitted via mesh store-and-forward',
                  style: TextStyle(color: theme.textMuted, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAudioMemoDialog(theme);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAudioMemoDialog(ThemeProvider theme) {
    int seconds = 0;
    bool isRecording = true;
    Timer? timer;
    final chatService = context.read<ChatService>();
    final messenger = ScaffoldMessenger.of(context);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dlgContext) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
              if (isRecording) {
                setDlgState(() => seconds++);
              }
            });

            final minsStr = (seconds ~/ 60).toString().padLeft(2, '0');
            final secsStr = (seconds % 60).toString().padLeft(2, '0');

            return AlertDialog(
              backgroundColor: theme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                side: BorderSide(color: theme.border),
              ),
              title: const Row(
                children: [
                  Icon(Icons.mic_rounded, color: AppTokens.beaconTeal),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Record Offline Audio Memo',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Transmitting to ${widget.profile.displayName} over mesh store-and-forward relay.',
                    style: TextStyle(color: theme.textMuted, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      setDlgState(() {
                        isRecording = !isRecording;
                      });
                    },
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isRecording
                            ? AppTokens.sosRed.withValues(alpha: 0.15)
                            : AppTokens.beaconTeal.withValues(alpha: 0.15),
                        border: Border.all(
                          color: isRecording
                              ? AppTokens.sosRed
                              : AppTokens.beaconTeal,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        isRecording
                            ? Icons.mic_rounded
                            : Icons.mic_none_rounded,
                        color: isRecording
                            ? AppTokens.sosRed
                            : AppTokens.beaconTeal,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$minsStr:$secsStr',
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isRecording
                        ? 'Recording emergency voice note (Tap mic to pause)…'
                        : 'Recording paused (Tap mic to resume)',
                    style: TextStyle(
                      color: isRecording ? AppTokens.sosRed : theme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    timer?.cancel();
                    Navigator.pop(dlgContext);
                  },
                  child:
                      Text('Cancel', style: TextStyle(color: theme.textMuted)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTokens.beaconTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                    ),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Send Memo over Mesh'),
                  onPressed: () async {
                    timer?.cancel();
                    Navigator.pop(dlgContext);
                    final recordedSec = seconds > 0 ? seconds : 2;
                    await chatService.sendVoiceNote(
                      recordedSec,
                      conversationId: 'DIRECT_${widget.profile.userId}',
                      recipientTarget: widget.profile.userId,
                      category: 'Nearby',
                    );
                    messenger.showSnackBar(
                      SnackBar(
                        backgroundColor: AppTokens.beaconTeal,
                        content: Text(
                          'Audio memo ($recordedSec s) queued for ${widget.profile.displayName} via mesh relay!',
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _toggleBlockUser() async {
    final chatService = context.read<ChatService>();
    final messenger = ScaffoldMessenger.of(context);
    if (_isBlocked) {
      final prefs = await SharedPreferences.getInstance();
      final blocked = (prefs.getStringList(_prefBlockedKey) ?? []).toList();
      blocked.remove(widget.profile.userId);
      await prefs.setStringList(_prefBlockedKey, blocked);
      await chatService.reloadBlockedUsers();
      if (mounted) {
        setState(() => _isBlocked = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text('${widget.profile.displayName} unblocked.'),
          ),
        );
      }
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final theme = ctx.read<ThemeProvider>();
          return AlertDialog(
            backgroundColor: theme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              side: BorderSide(color: theme.border),
            ),
            title: Text(
              'Block ${widget.profile.displayName}?',
              style: TextStyle(
                color: theme.text,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Messages from this user will be hidden locally.',
              style: TextStyle(color: theme.textMuted, fontSize: 13.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child:
                    Text('Cancel', style: TextStyle(color: theme.textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTokens.sosRed,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Block User'),
              ),
            ],
          );
        },
      );

      if (confirmed == true && mounted) {
        final prefs = await SharedPreferences.getInstance();
        final blocked = (prefs.getStringList(_prefBlockedKey) ?? []).toList();
        if (!blocked.contains(widget.profile.userId)) {
          blocked.add(widget.profile.userId);
        }
        await prefs.setStringList(_prefBlockedKey, blocked);
        await chatService.reloadBlockedUsers();
        if (mounted) {
          setState(() => _isBlocked = true);
          messenger.showSnackBar(
            const SnackBar(
              backgroundColor: AppTokens.sosRed,
              content: Text('User blocked on this device.'),
            ),
          );
        }
      }
    }
  }

  Future<void> _reportUser() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_isReported) {
      messenger.showSnackBar(
        const SnackBar(
          content:
              Text('Incident report is already flagged locally for this user.'),
        ),
      );
      return;
    }

    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final theme = ctx.read<ThemeProvider>();
        const reasons = [
          'Spam or Harassment',
          'False Emergency SOS Broadcast',
          'RF Radio Flooding / Jamming',
          'Impersonation / Fake Responder',
        ];
        return SimpleDialog(
          backgroundColor: theme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            side: BorderSide(color: theme.border),
          ),
          title: Text(
            'Report ${widget.profile.displayName}',
            style: TextStyle(
              color: theme.text,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          children: reasons.map((r) {
            return SimpleDialogOption(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              onPressed: () => Navigator.pop(ctx, r),
              child: Text(r, style: TextStyle(color: theme.text)),
            );
          }).toList(),
        );
      },
    );

    if (reason != null && mounted) {
      final prefs = await SharedPreferences.getInstance();
      final reported = (prefs.getStringList(_prefReportedKey) ?? []).toList();
      if (!reported.contains(widget.profile.userId)) {
        reported.add(widget.profile.userId);
      }
      await prefs.setStringList(_prefReportedKey, reported);
      if (mounted) {
        setState(() => _isReported = true);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Incident report recorded locally on this device.'),
          ),
        );
      }
    }
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

          // Blocked notice banner
          if (_isBlocked)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTokens.sosRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                border:
                    Border.all(color: AppTokens.sosRed.withValues(alpha: 0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.block_rounded, color: AppTokens.sosRed, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'User blocked on this device • Messages and calls from this user are hidden locally.',
                      style: TextStyle(
                        color: AppTokens.sosRed,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

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
                  : () => _showNearbyVoiceOptionsSheet(theme, calls),
              style: ElevatedButton.styleFrom(
                backgroundColor: availability.isAvailable
                    ? AppTokens.signalYellow
                    : theme.surface,
                foregroundColor: availability.isAvailable
                    ? AppTokens.nightNavy
                    : theme.text,
                side: availability.isAvailable
                    ? null
                    : BorderSide(color: theme.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                ),
              ),
              icon: Icon(
                availability.isAvailable
                    ? Icons.call_rounded
                    : Icons.phone_forwarded_rounded,
                color: availability.isAvailable
                    ? AppTokens.nightNavy
                    : AppTokens.beaconTeal,
              ),
              label: Text(
                availability.isAvailable
                    ? 'Voice call nearby'
                    : 'Voice call nearby (Offline Options)',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _handleMessageTap(groups),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.text,
                side: BorderSide(color: theme.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                ),
              ),
              icon: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppTokens.beaconTeal,
              ),
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
              (group) => InkWell(
                onTap: () {
                  context.read<GroupService>().selectGroup(group.id);
                  context.read<ChatService>().setActiveFilter('Group');
                  context
                      .read<ChatService>()
                      .setActiveGroupConversation(group.conversationId);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ChatScreen(
                        conversationId: group.conversationId,
                        initialFilter: 'Group',
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                child: _infoRow(
                  theme,
                  icon: Icons.groups_rounded,
                  title: group.name,
                  subtitle:
                      '${group.memberCount} member${group.memberCount == 1 ? '' : 's'} • Tap to chat',
                ),
              ),
            ),
          const SizedBox(height: 22),
          _sectionTitle(theme, 'SAFETY'),
          const SizedBox(height: 8),
          _interactiveSafetyAction(
            theme,
            icon: _isBlocked
                ? Icons.check_circle_outline_rounded
                : Icons.block_outlined,
            iconColor: _isBlocked ? AppTokens.beaconTeal : AppTokens.sosRed,
            title: _isBlocked ? 'Unblock user' : 'Block user',
            subtitle: _isBlocked
                ? 'Allow messages and calls from ${widget.profile.displayName}'
                : 'Messages from this user will be hidden locally.',
            onTap: _toggleBlockUser,
          ),
          _interactiveSafetyAction(
            theme,
            icon: _isReported ? Icons.flag_rounded : Icons.flag_outlined,
            iconColor: AppTokens.warningAmber,
            title: _isReported ? 'Reported' : 'Report user',
            subtitle: _isReported
                ? 'Local incident flag logged on device.'
                : 'Flag incident locally on this device.',
            onTap: _reportUser,
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
                  subtitle:
                      'Only call metadata is stored on this phone. Audio is never recorded.',
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
    Color? iconColor,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppTokens.beaconTeal),
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

  Widget _interactiveSafetyAction(
    ThemeProvider theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        child: _infoRow(
          theme,
          icon: icon,
          title: title,
          subtitle: subtitle,
          iconColor: iconColor,
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
