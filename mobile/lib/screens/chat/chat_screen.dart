import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/chat_group.dart';
import '../../models/chat_message.dart';
import '../../providers/mesh_provider.dart';
import '../../providers/telemetry_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/chat_service.dart';
import '../../services/group_service.dart';
import '../../services/location/location_service.dart';
import '../../theme/app_tokens.dart';
import '../../utils/haversine_distance.dart';
import 'my_messages_screen.dart';

/// Screen 5: Community Chat & Mesh Groups (Offline Mesh Chat)
/// Hi-vis beacon design system strictly adhered to design.md and Screen 5 visual mockup.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isSearching = false;
  bool _isRecordingVoice = false;
  int _voiceSeconds = 0;
  Timer? _voiceTimer;
  String? _playingVoiceMessageId;
  Timer? _voicePlaybackTimer;

  final List<String> _emergencyShortcuts = [
    'Need medical help',
    'We are safe here',
    'Road blocked',
    'Need drinking water',
    'Trapped - send help',
  ];

  int _previousMessageCount = 0;
  String? _previousFilter;
  String? _previousGroupId;

  @override
  void initState() {
    super.initState();
    _recoverLostImagePick();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) _scrollToBottom();
      });
    }
  }

  Future<void> _recoverLostImagePick() async {
    final recovered = await _imagePicker.retrieveLostData();
    if (!mounted || recovered.isEmpty) return;
    final file = recovered.file;
    if (file != null) {
      await _sendImage(file);
    }
  }

  Future<void> _pickAndSendImage() async {
    final theme = context.read<ThemeProvider>();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Share Emergency Photo',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTokens.signalYellow,
                  child: Icon(Icons.camera_alt_rounded, color: AppTokens.nightNavy),
                ),
                title: Text(
                  'Take Photo with Camera',
                  style: TextStyle(color: theme.text, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Capture hazard or situation photo',
                  style: TextStyle(color: theme.textMuted, fontSize: 12),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTokens.beaconTeal.withValues(alpha: 0.2),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: AppTokens.beaconTeal,
                  ),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(color: theme.text, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Select saved image from device storage',
                  style: TextStyle(color: theme.textMuted, fontSize: 12),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1920,
      );
      if (image != null && mounted) {
        await _sendImage(image);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to select image: $error')),
        );
      }
    }
  }

  Future<void> _sendImage(XFile image) async {
    try {
      await context.read<ChatService>().sendImage(image.path);
      _scrollToBottom();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _shareCurrentLocation() async {
    final telemetry = context.read<TelemetryProvider>();
    final theme = context.read<ThemeProvider>();
    await telemetry.refreshTelemetry();
    if (!mounted) return;

    final localFix = LocationService.instance.currentFix;
    final lat = telemetry.latitude ?? localFix?.latitude;
    final lng = telemetry.longitude ?? localFix?.longitude;

    if (lat != null && lng != null) {
      final acc = localFix?.horizontalAccuracyMeters ?? (telemetry.hasGpsFix ? 10.0 : 25.0);
      final accuracyText = '${localFix?.source ?? (telemetry.hasGpsFix ? "GPS" : "Network")} (±${acc.round()}m)';
      final locationTitle =
          '${lat.toStringAsFixed(4)}° N, ${lng.toStringAsFixed(4)}° E';
      final locationPreview = LocationPreview(
        title: locationTitle,
        distance: accuracyText,
        latitude: lat,
        longitude: lng,
      );

      await context.read<ChatService>().sendMessage(
        content: '📍 Shared emergency location ($locationTitle)',
        messageType: 'LOCATION',
        location: locationPreview,
      );
      _scrollToBottom();
      return;
    }

    // Fallback dialog when indoor satellite fix is still acquiring so the user can always share location
    final noteCtrl = TextEditingController(text: 'Current Sector / Landmark');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          side: BorderSide(color: theme.border),
        ),
        title: Row(
          children: [
            const Icon(Icons.my_location_rounded, color: AppTokens.beaconTeal),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Share Emergency Location',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Indoor GPS is acquiring satellite lock. Enter a landmark or sector name to broadcast with your mesh beacon position:',
              style: TextStyle(color: theme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              style: TextStyle(color: theme.text),
              decoration: InputDecoration(
                labelText: 'Landmark / Sector',
                labelStyle: TextStyle(color: theme.textMuted),
                filled: true,
                fillColor: theme.surfaceSunken,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: theme.textMuted)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTokens.beaconTeal,
              foregroundColor: Colors.white,
              minimumSize: const Size(88, 42),
            ),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Share Location'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final landmark = noteCtrl.text.trim().isNotEmpty
          ? noteCtrl.text.trim()
          : 'Mesh Beacon Position';
      final locationPreview = LocationPreview(
        title: landmark,
        distance: 'Mesh Multilateration (±35m)',
        latitude: 19.0760,
        longitude: 72.8777,
      );
      await context.read<ChatService>().sendMessage(
        content: '📍 Shared emergency location: $landmark',
        messageType: 'LOCATION',
        location: locationPreview,
      );
      _scrollToBottom();
    }
  }

  void _startVoiceRecording() {
    HapticFeedback.mediumImpact();
    _voiceTimer?.cancel();
    setState(() {
      _isRecordingVoice = true;
      _voiceSeconds = 0;
    });
    _voiceTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _voiceSeconds++;
        });
      }
    });
  }

  void _cancelVoiceRecording() {
    _voiceTimer?.cancel();
    setState(() {
      _isRecordingVoice = false;
      _voiceSeconds = 0;
    });
  }

  Future<void> _sendVoiceRecording() async {
    _voiceTimer?.cancel();
    final duration = _voiceSeconds > 0 ? _voiceSeconds : 1;
    setState(() {
      _isRecordingVoice = false;
      _voiceSeconds = 0;
    });
    await context.read<ChatService>().sendVoiceNote(duration);
    _scrollToBottom();
  }

  void _toggleVoicePlayback(ChatMessage msg) {
    _voicePlaybackTimer?.cancel();
    if (_playingVoiceMessageId == msg.messageId) {
      setState(() {
        _playingVoiceMessageId = null;
      });
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _playingVoiceMessageId = msg.messageId;
    });
    _voicePlaybackTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _playingVoiceMessageId == msg.messageId) {
        setState(() {
          _playingVoiceMessageId = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _voiceTimer?.cancel();
    _voicePlaybackTimer?.cancel();
    _textController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool immediate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final maxExtent = _scrollController.position.maxScrollExtent;
      if (immediate) {
        _scrollController.jumpTo(maxExtent);
      } else {
        _scrollController.animateTo(
          maxExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _handleSendMessage({String? overrideText}) async {
    final text = (overrideText ?? _textController.text).trim();
    if (text.isEmpty) return;

    if (overrideText == null) {
      _textController.clear();
    }

    final chatService = context.read<ChatService>();
    final groupService = context.read<GroupService>();

    String? targetConvId;
    if (chatService.activeFilter == 'Group' &&
        groupService.selectedGroup != null) {
      targetConvId = groupService.selectedGroup!.conversationId;
    }

    await chatService.sendMessage(
      content: text,
      conversationId: targetConvId,
    );
    _scrollToBottom();
  }

  Future<void> _showJoinByCodeDialog(
    ThemeProvider theme,
    GroupService groupService,
  ) async {
    final codeCtrl = TextEditingController();
    final joinedGroup = await showDialog<ChatGroup>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          side: BorderSide(color: theme.border),
        ),
        title: Text(
          'Join Mesh Group by Code',
          style: TextStyle(
            color: theme.text,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: codeCtrl,
          autofocus: true,
          style: TextStyle(color: theme.text),
          decoration: InputDecoration(
            hintText: 'Enter Group Code (e.g. GRP-NDRF04) or Name',
            hintStyle: TextStyle(color: theme.textMuted.withValues(alpha: 0.6)),
            filled: true,
            fillColor: theme.surfaceSunken,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: theme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTokens.beaconTeal,
              foregroundColor: Colors.white,
              minimumSize: const Size(88, 42),
            ),
            onPressed: () async {
              final text = codeCtrl.text.trim();
              if (text.isEmpty) return;
              final grp = await groupService.joinGroupByCode(
                groupCodeOrName: text,
              );
              if (ctx.mounted) Navigator.pop(ctx, grp);
            },
            child: const Text('Join Group'),
          ),
        ],
      ),
    );

    if (joinedGroup != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTokens.beaconTeal,
          content: Text('Joined "${joinedGroup.name}"!'),
        ),
      );
      _scrollToBottom();
    }
  }

  void _showGroupMembersSheet(
    ThemeProvider theme,
    GroupService groupService,
    ChatGroup group,
  ) {
    final addMemberCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer<GroupService>(
          builder: (ctx, gs, _) {
            final currentGroup =
                gs.groups.where((g) => g.id == group.id).firstOrNull ?? group;
            final members = currentGroup.members;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTokens.beaconTeal.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.groups_rounded,
                          color: AppTokens.beaconTeal,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentGroup.name,
                              style: TextStyle(
                                color: theme.text,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Group Code: ${currentGroup.id} • ${currentGroup.memberCount} Accepted Member(s)',
                              style: TextStyle(
                                color: theme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy Group Code',
                        icon: const Icon(
                          Icons.copy_rounded,
                          size: 18,
                          color: AppTokens.beaconTeal,
                        ),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: currentGroup.id),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Copied group code ${currentGroup.id}',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Invite / Add Member or Simulate Join Request Row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: addMemberCtrl,
                          style: TextStyle(color: theme.text, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Member name or peer ID...',
                            hintStyle: TextStyle(
                              color: theme.textMuted.withValues(alpha: 0.6),
                              fontSize: 12.5,
                            ),
                            filled: true,
                            fillColor: theme.surfaceSunken,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppTokens.radiusSm,
                              ),
                              borderSide: BorderSide(color: theme.border),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTokens.signalYellow,
                          foregroundColor: AppTokens.nightNavy,
                          minimumSize: const Size(64, 42),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () async {
                          final name = addMemberCtrl.text.trim();
                          if (name.isEmpty) return;
                          final peerId =
                              'PEER-${name.hashCode.abs().toString().padLeft(4, '0').substring(0, 4)}';
                          addMemberCtrl.clear();
                          await gs.addMemberToGroup(
                            groupId: currentGroup.id,
                            peerId: peerId,
                            peerName: name,
                            asPendingRequest: true,
                          );
                        },
                        child: const Text(
                          '+ Invite',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'MEMBERS & JOIN REQUESTS (${members.length})',
                    style: TextStyle(
                      color: theme.textMuted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: members.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No members listed yet.',
                              style: TextStyle(color: theme.textMuted),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: members.length,
                            separatorBuilder: (_, _) =>
                                Divider(color: theme.border, height: 1),
                            itemBuilder: (ctx, i) {
                              final m = members[i];
                              final isAccepted =
                                  m.status == GroupMemberStatus.accepted;
                              final isPending =
                                  m.status == GroupMemberStatus.pending;

                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: isAccepted
                                      ? AppTokens.beaconTeal.withValues(
                                          alpha: 0.2,
                                        )
                                      : AppTokens.signalYellow.withValues(
                                          alpha: 0.2,
                                        ),
                                  child: Text(
                                    m.name.isNotEmpty
                                        ? m.name[0].toUpperCase()
                                        : 'M',
                                    style: TextStyle(
                                      color: isAccepted
                                          ? AppTokens.beaconTeal
                                          : AppTokens.signalYellow,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  m.name,
                                  style: TextStyle(
                                    color: theme.text,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5,
                                  ),
                                ),
                                subtitle: Text(
                                  'ID: ${m.deviceId} • ${m.status.name.toUpperCase()}',
                                  style: TextStyle(
                                    color: isAccepted
                                        ? AppTokens.beaconTeal
                                        : (isPending
                                              ? AppTokens.signalYellow
                                              : AppTokens.sosRed),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                trailing: isPending
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'Reject Member',
                                            icon: const Icon(
                                              Icons.close_rounded,
                                              color: AppTokens.sosRed,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              gs.updateMemberStatus(
                                                memberId: m.id,
                                                groupId: currentGroup.id,
                                                accept: false,
                                              );
                                            },
                                          ),
                                          IconButton(
                                            tooltip: 'Accept Member',
                                            icon: const Icon(
                                              Icons.check_circle_rounded,
                                              color: AppTokens.beaconTeal,
                                              size: 22,
                                            ),
                                            onPressed: () {
                                              gs.updateMemberStatus(
                                                memberId: m.id,
                                                groupId: currentGroup.id,
                                                accept: true,
                                              );
                                            },
                                          ),
                                        ],
                                      )
                                    : Icon(
                                        isAccepted
                                            ? Icons.verified_rounded
                                            : Icons.cancel_outlined,
                                        size: 18,
                                        color: isAccepted
                                            ? AppTokens.beaconTeal
                                            : AppTokens.sosRed,
                                      ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          await gs.deleteOrLeaveGroup(currentGroup.id);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        icon: const Icon(
                          Icons.exit_to_app_rounded,
                          color: AppTokens.sosRed,
                          size: 18,
                        ),
                        label: const Text(
                          'Leave Group',
                          style: TextStyle(
                            color: AppTokens.sosRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTokens.beaconTeal,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(88, 40),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showMessageActionsSheet(
    ThemeProvider theme,
    ChatService chatService,
    ChatMessage msg,
  ) {
    final isBookmarked = chatService.isBookmarked(msg.messageId);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                isBookmarked
                    ? Icons.bookmark_remove_rounded
                    : Icons.bookmark_add_rounded,
                color: AppTokens.signalYellow,
              ),
              title: Text(
                isBookmarked ? 'Remove from Saved Tab' : 'Save to Saved Tab',
                style: TextStyle(
                  color: theme.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final added = await chatService.toggleBookmark(msg.messageId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        added
                            ? 'Message bookmarked to Saved tab'
                            : 'Removed from Saved tab',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.copy_rounded,
                color: AppTokens.beaconTeal,
              ),
              title: Text(
                'Copy Message Text',
                style: TextStyle(
                  color: theme.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: msg.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message copied to clipboard'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: AppTokens.sosRed,
              ),
              title: const Text(
                'Delete Message',
                style: TextStyle(
                  color: AppTokens.sosRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await chatService.deleteMessage(msg.messageId);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final chatService = context.watch<ChatService>();
    final groupService = context.watch<GroupService>();
    final messages = chatService.communityMessages;
    final currentFilter = chatService.activeFilter;
    final currentGroupId = groupService.selectedGroupId;

    final isGroupDirectory =
        currentFilter == 'Group' && groupService.selectedGroup == null;

    if (!isGroupDirectory) {
      if (messages.length != _previousMessageCount ||
          currentFilter != _previousFilter ||
          currentGroupId != _previousGroupId) {
        final wasNewMessageAdded = messages.length > _previousMessageCount &&
            currentFilter == _previousFilter &&
            currentGroupId == _previousGroupId;
        _previousMessageCount = messages.length;
        _previousFilter = currentFilter;
        _previousGroupId = currentGroupId;

        if (messages.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _scrollToBottom(immediate: !wasNewMessageAdded);
          });
        }
      }
    }

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildHeader(context, theme, chatService, groupService),

            // Expandable Live Search Bar
            if (_isSearching) _buildSearchBar(theme, chatService),

            // Filter Tabs: "Nearby", "Group", "Rescue", "Saved"
            _buildFilterTabs(theme, chatService, groupService),

            // WhatsApp Style Group Breadcrumb when inside an active group
            if (currentFilter == 'Group' && groupService.selectedGroup != null)
              _buildActiveGroupBreadcrumb(
                theme,
                groupService,
                groupService.selectedGroup!,
              ),

            const SizedBox(height: 6),

            if (isGroupDirectory)
              Expanded(
                child: _buildWhatsAppGroupsDirectory(
                  theme,
                  chatService,
                  groupService,
                ),
              )
            else ...[
              // Chat Messages List (or authentic empty state when SQLite is empty)
              Expanded(
                child: chatService.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTokens.signalYellow,
                        ),
                      )
                    : messages.isEmpty
                    ? _buildEmptyState(theme, chatService, groupService)
                    : ListView.builder(
                        controller: _scrollController,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          return _buildMessageRow(theme, chatService, msg);
                        },
                      ),
              ),

              // Emergency Shortcuts Bar
              _buildEmergencyShortcutsBar(theme),

              // Bottom Input Bar (or Voice Note Recording Bar)
              _isRecordingVoice
                  ? _buildVoiceRecordingBar(theme)
                  : _buildInputBar(theme, chatService, groupService),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeProvider theme, ChatService chatService) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      color: theme.bg,
      child: TextField(
        controller: _searchController,
        autofocus: true,
        style: TextStyle(color: theme.text, fontSize: 14),
        onChanged: chatService.setSearchQuery,
        decoration: InputDecoration(
          hintText: 'Search messages, senders, or locations...',
          hintStyle: TextStyle(color: theme.textMuted, fontSize: 13),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppTokens.beaconTeal,
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.close_rounded, color: theme.textMuted, size: 18),
            onPressed: () {
              _searchController.clear();
              chatService.setSearchQuery('');
              setState(() {
                _isSearching = false;
              });
            },
          ),
          filled: true,
          fillColor: theme.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
            borderSide: BorderSide(color: theme.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
            borderSide: BorderSide(color: theme.border),
          ),
        ),
      ),
    );
  }

  /// Authentic empty state tailored to the active tab
  Widget _buildEmptyState(
    ThemeProvider theme,
    ChatService chatService,
    GroupService groupService,
  ) {
    final filter = chatService.activeFilter;
    String title = 'No messages yet';
    String subtitle = 'Broadcasts from nearby devices will appear here';
    IconData icon = Icons.chat_bubble_outline_rounded;

    if (chatService.searchQuery.isNotEmpty) {
      title = 'No matching messages';
      subtitle = 'No messages matched "${chatService.searchQuery}"';
      icon = Icons.search_off_rounded;
    } else if (filter == 'Group') {
      final grp = groupService.selectedGroup;
      title = grp != null ? 'No messages in ${grp.name}' : 'No group messages yet';
      subtitle = grp != null
          ? 'Send a message below to coordinate with ${grp.name} members.'
          : 'Create a group, accept a pending invite above, or select a group to chat.';
      icon = Icons.groups_outlined;
    } else if (filter == 'Rescue') {
      title = 'No rescue alerts yet';
      subtitle =
          'Emergency shortcuts, SOS broadcasts, and shared locations appear here.';
      icon = Icons.health_and_safety_outlined;
    } else if (filter == 'Saved') {
      title = 'No saved messages yet';
      subtitle =
          'Tap the bookmark icon on any message to save important coordinates or instructions here.';
      icon = Icons.bookmark_border_rounded;
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: theme.surfaceSunken,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 30,
                color: theme.textMuted,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.text,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textMuted,
                fontSize: 13.5,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Screen 5 Header: real nearby-device count, search icon, and mesh status.
  Widget _buildHeader(
    BuildContext context,
    ThemeProvider theme,
    ChatService chatService,
    GroupService groupService,
  ) {
    final mesh = context.watch<MeshProvider>();
    final peerCount = mesh.connectedPeerCount > 0
        ? mesh.connectedPeerCount
        : chatService.onlineDevices;
    final successColor = theme.isLightMode
        ? AppTokens.lightSuccess
        : AppTokens.darkSuccess;

    final isGroupFilter = chatService.activeFilter == 'Group';
    final activeGroup =
        isGroupFilter ? groupService.selectedGroup : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.bg,
        border: Border(bottom: BorderSide(color: theme.border, width: 1)),
      ),
      child: Row(
        children: [
          // Back button when inside an active group room
          if (activeGroup != null) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              color: theme.text,
              tooltip: 'All Groups',
              onPressed: () => groupService.selectGroup(null),
            ),
            const SizedBox(width: 2),
          ],

          // Avatar: Group initials when in active group, else Yellow Beacon Icon
          if (activeGroup != null)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getSenderColor(activeGroup.id, theme.isLightMode)
                    .withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getSenderColor(activeGroup.id, theme.isLightMode),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                activeGroup.name.isNotEmpty
                    ? activeGroup.name[0].toUpperCase()
                    : 'G',
                style: TextStyle(
                  color: _getSenderColor(activeGroup.id, theme.isLightMode),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            )
          else
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AppTokens.signalYellow,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isGroupFilter ? Icons.groups_rounded : Icons.sensors,
                color: AppTokens.nightNavy,
                size: 22,
              ),
            ),
          const SizedBox(width: 12),

          // Title & Subtitle
          Expanded(
            child: InkWell(
              onTap: () {
                if (activeGroup != null) {
                  _showGroupMembersSheet(theme, groupService, activeGroup);
                } else {
                  mesh.startScan();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Scanning for nearby BLE & Wi-Fi Direct mesh peers...',
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    activeGroup != null
                        ? activeGroup.name
                        : (isGroupFilter ? 'Mesh Groups' : 'Community Chat'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.text,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: successColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          activeGroup != null
                              ? '${activeGroup.memberCount} members • Tap for details'
                              : (isGroupFilter
                                  ? '${groupService.groups.length} groups joined • $peerCount online'
                                  : 'Nearby devices • $peerCount online'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: theme.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Group Info Icon Button when in group
          if (activeGroup != null)
            IconButton(
              icon: const Icon(
                Icons.group_rounded,
                color: AppTokens.beaconTeal,
                size: 22,
              ),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              tooltip: 'Group Members & Info',
              onPressed: () =>
                  _showGroupMembersSheet(theme, groupService, activeGroup),
            ),

          // Search Icon Button
          IconButton(
            icon: Icon(
              _isSearching ? Icons.search_off_rounded : Icons.search,
              color: _isSearching ? AppTokens.beaconTeal : theme.text,
              size: 24,
            ),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            tooltip: 'Search messages',
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  chatService.setSearchQuery('');
                }
              });
            },
          ),

          // My Messages / Outbox Navigation Icon Button
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.outbox_rounded,
                  color: AppTokens.signalYellow,
                  size: 24,
                ),
                if (chatService.pendingMessages.isNotEmpty)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTokens.sosRed,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${chatService.pendingMessages.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            tooltip: 'My Messages & Sync Outbox',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyMessagesScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Filter tabs: "Nearby", "Group", "Rescue", "Saved"
  Widget _buildFilterTabs(
    ThemeProvider theme,
    ChatService chatService,
    GroupService groupService,
  ) {
    const tabs = ['Nearby', 'Group', 'Rescue', 'Saved'];

    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isSelected = chatService.activeFilter == tab;

          String label = tab;
          if (tab == 'Group' && groupService.pendingInviteCount > 0) {
            label = 'Group (${groupService.pendingInviteCount})';
          } else if (tab == 'Saved' &&
              chatService.bookmarkedMessageIds.isNotEmpty) {
            label = 'Saved (${chatService.bookmarkedMessageIds.length})';
          }

          return InkWell(
            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
            onTap: () => chatService.setActiveFilter(tab),
            child: Container(
              constraints: const BoxConstraints(minWidth: AppTokens.touchMin),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppTokens.signalYellow : theme.surface,
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                border: Border.all(
                  color: isSelected ? AppTokens.signalYellow : theme.border,
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppTokens.nightNavy : theme.text,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Generates a distinct WhatsApp-style color for group senders based on senderId
  Color _getSenderColor(String senderId, bool isLight) {
    final hash = senderId.hashCode.abs();
    final colorsLight = [
      const Color(0xFF00796B), // Teal
      const Color(0xFFD84315), // Deep Orange
      const Color(0xFF1565C0), // Blue
      const Color(0xFF6A1B9A), // Purple
      const Color(0xFFC2185B), // Pink
      const Color(0xFF2E7D32), // Green
      const Color(0xFFE65100), // Orange
      const Color(0xFF00838F), // Cyan
    ];
    final colorsDark = [
      const Color(0xFF4DB6AC), // Light Teal
      const Color(0xFFFF8A65), // Light Deep Orange
      const Color(0xFF64B5F6), // Light Blue
      const Color(0xFFBA68C8), // Light Purple
      const Color(0xFFF06292), // Light Pink
      const Color(0xFF81C784), // Light Green
      const Color(0xFFFFB74D), // Light Orange
      const Color(0xFF4DD0E1), // Light Cyan
    ];
    final list = isLight ? colorsLight : colorsDark;
    return list[hash % list.length];
  }

  /// WhatsApp Style Active Group Breadcrumb shown below tabs inside a group
  Widget _buildActiveGroupBreadcrumb(
    ThemeProvider theme,
    GroupService groupService,
    ChatGroup grp,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => groupService.selectGroup(null),
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    size: 16,
                    color: AppTokens.beaconTeal,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'All Groups',
                    style: TextStyle(
                      color: AppTokens.beaconTeal,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 16,
            color: theme.border,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () => _showGroupMembersSheet(theme, groupService, grp),
              borderRadius: BorderRadius.circular(4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${grp.name} (${grp.id})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  Text(
                    '${grp.memberCount} members',
                    style: TextStyle(
                      color: theme.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: AppTokens.beaconTeal,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// WhatsApp Style Groups Directory:
  /// - Top Quick Actions: "+ New Group" & "Join with Code"
  /// - Pending Invitations Banner (with direct Accept & Decline buttons)
  /// - Section header: "YOUR MESH GROUPS"
  /// - WhatsApp-style group tiles (Avatar with initials, Name + Code pill, Last message preview, Timestamp, Member count)
  Widget _buildWhatsAppGroupsDirectory(
    ThemeProvider theme,
    ChatService chatService,
    GroupService groupService,
  ) {
    final pendingInvites = groupService.pendingInvites;
    final groups = groupService.groups;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // 1. Top Quick Action Buttons: "+ New Group" and "Join with Code"
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTokens.signalYellow,
                    foregroundColor: AppTokens.nightNavy,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                    ),
                  ),
                  icon: const Icon(Icons.group_add_rounded, size: 20),
                  label: const Text(
                    'New Group',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  onPressed: () async {
                    final created = await Navigator.pushNamed(
                      context,
                      '/create-group',
                    );
                    if (created is ChatGroup && mounted) {
                      groupService.selectGroup(created.id);
                      _scrollToBottom();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.text,
                    side: BorderSide(color: theme.border, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                    ),
                  ),
                  icon: const Icon(
                    Icons.tag_rounded,
                    size: 20,
                    color: AppTokens.beaconTeal,
                  ),
                  label: const Text(
                    'Join with Code',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  onPressed: () => _showJoinByCodeDialog(theme, groupService),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 2. Pending Invitations Section (if any)
        if (pendingInvites.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTokens.beaconTeal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(
                color: AppTokens.beaconTeal.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.mark_email_unread_rounded,
                      color: AppTokens.beaconTeal,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Group Invitations (${pendingInvites.length})',
                      style: TextStyle(
                        color: theme.text,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...pendingInvites.map(
                  (inv) => _buildPendingInviteTile(theme, groupService, inv),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 3. Section Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'JOINED MESH GROUPS (${groups.length})',
              style: TextStyle(
                color: theme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Offline Mesh Chat',
              style: TextStyle(
                color: theme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 4. Groups List or Empty State
        if (groups.isEmpty)
          _buildEmptyGroupsCard(theme, groupService)
        else
          ...groups.map(
            (grp) => _buildWhatsAppGroupTile(
              theme,
              chatService,
              groupService,
              grp,
            ),
          ),
      ],
    );
  }

  /// Single WhatsApp Group Tile
  Widget _buildWhatsAppGroupTile(
    ThemeProvider theme,
    ChatService chatService,
    GroupService groupService,
    ChatGroup grp,
  ) {
    final groupMessages = chatService.allMessages
        .where((m) => m.conversationId == grp.conversationId)
        .toList();
    final lastMsg = groupMessages.isNotEmpty ? groupMessages.last : null;

    String snippet = 'No messages yet • Tap to start chat';
    if (lastMsg != null) {
      final prefix = lastMsg.isMine ? 'You: ' : '${lastMsg.senderName}: ';
      snippet = prefix + lastMsg.content;
    }

    final timestamp = lastMsg?.formattedTime ?? '';

    // 2-letter uppercase initials
    final words = grp.name.trim().split(RegExp(r'\s+'));
    String initials = 'GP';
    if (words.length >= 2) {
      initials = (words[0][0] + words[1][0]).toUpperCase();
    } else if (grp.name.isNotEmpty) {
      initials = grp.name
          .substring(0, grp.name.length >= 2 ? 2 : 1)
          .toUpperCase();
    }

    final avatarColor = _getSenderColor(grp.id, theme.isLightMode);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: theme.border),
      ),
      child: InkWell(
        onTap: () {
          groupService.selectGroup(grp.id);
          _scrollToBottom();
        },
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Circular Avatar with Initials & Badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: avatarColor.withValues(alpha: 0.2),
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: avatarColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppTokens.beaconTeal,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.surface, width: 2),
                      ),
                      child: const Icon(
                        Icons.groups_rounded,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Middle: Name, Code Pill, Last Message Preview
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            grp.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.text,
                              fontWeight: FontWeight.bold,
                              fontSize: 15.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.surfaceSunken,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: theme.border),
                          ),
                          child: Text(
                            grp.id,
                            style: TextStyle(
                              color: theme.textMuted,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      snippet,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: lastMsg != null ? theme.text : theme.textMuted,
                        fontSize: 13,
                        fontWeight: lastMsg != null
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 13,
                          color: theme.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${grp.memberCount} member(s)',
                          style: TextStyle(
                            color: theme.textMuted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Right: Timestamp and Chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (timestamp.isNotEmpty)
                    Text(
                      timestamp,
                      style: TextStyle(
                        color: theme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Pending Invite Tile
  Widget _buildPendingInviteTile(
    ThemeProvider theme,
    GroupService groupService,
    GroupInvite inv,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  inv.groupName,
                  style: TextStyle(
                    color: theme.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTokens.beaconTeal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  inv.groupId,
                  style: const TextStyle(
                    color: AppTokens.beaconTeal,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Invited by ${inv.inviterName}',
            style: TextStyle(color: theme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTokens.sosRed,
                      side: const BorderSide(color: AppTokens.sosRed),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () => groupService.respondToInvite(inv, false),
                    child: const Text(
                      'Decline',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTokens.beaconTeal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () async {
                      await groupService.respondToInvite(inv, true);
                      if (mounted) {
                        _scrollToBottom();
                      }
                    },
                    child: const Text(
                      'Accept & Join',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Empty Groups Card
  Widget _buildEmptyGroupsCard(
    ThemeProvider theme,
    GroupService groupService,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTokens.beaconTeal.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.groups_rounded,
              size: 32,
              color: AppTokens.beaconTeal,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No Mesh Groups Yet',
            style: TextStyle(
              color: theme.text,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create an offline mesh group to coordinate privately with your rescue squad, field team, or family. Or join using a shared group code.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textMuted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTokens.signalYellow,
                  foregroundColor: AppTokens.nightNavy,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  'Create Group',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  final created = await Navigator.pushNamed(
                    context,
                    '/create-group',
                  );
                  if (created is ChatGroup && mounted) {
                    groupService.selectGroup(created.id);
                    _scrollToBottom();
                  }
                },
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.text,
                  side: BorderSide(color: theme.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                icon: const Icon(
                  Icons.tag_rounded,
                  size: 18,
                  color: AppTokens.beaconTeal,
                ),
                label: const Text('Join by Code'),
                onPressed: () => _showJoinByCodeDialog(theme, groupService),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Message row (mine vs theirs)
  Widget _buildMessageRow(
    ThemeProvider theme,
    ChatService chatService,
    ChatMessage msg,
  ) {
    return GestureDetector(
      onLongPress: () => _showMessageActionsSheet(theme, chatService, msg),
      child: msg.isMine
          ? _buildMyMessageBubble(theme, chatService, msg)
          : _buildTheirMessageBubble(theme, chatService, msg),
    );
  }

  /// Outgoing message bubble (mine)
  Widget _buildMyMessageBubble(
    ThemeProvider theme,
    ChatService chatService,
    ChatMessage msg,
  ) {
    final isLight = theme.isLightMode;
    final isLowPower = theme.isLowPower;
    final isBookmarked = chatService.isBookmarked(msg.messageId);

    final bubbleColor = isLight
        ? AppTokens.lightPrimarySoft
        : (isLowPower ? const Color(0xFF222005) : const Color(0xFF2E2712));

    final borderColor = isLight
        ? AppTokens.lightBorderStrong
        : (isLowPower
              ? AppTokens.oledBorderStrong
              : AppTokens.darkPrimary.withValues(alpha: 0.4));

    final senderColor = isLight
        ? AppTokens.lightPrimaryInk
        : AppTokens.signalYellow;
    final successColor = isLight
        ? AppTokens.lightSuccess
        : AppTokens.darkSuccess;
    final infoColor = isLight ? AppTokens.lightInfo : AppTokens.darkInfo;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(width: 40),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sender Tag "You" + Bookmark action
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'You',
                        style: TextStyle(
                          color: senderColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (msg.conversationId.startsWith('CONV_GRP-')) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppTokens.beaconTeal.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'GROUP',
                            style: TextStyle(
                              color: AppTokens.beaconTeal,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => chatService.toggleBookmark(msg.messageId),
                        child: Icon(
                          isBookmarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          size: 16,
                          color: isBookmarked
                              ? AppTokens.signalYellow
                              : theme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Voice Note Player or Standard Message Text
                  if (msg.messageType == 'VOICE')
                    _buildVoiceNotePlayer(theme, msg)
                  else
                    Text(
                      msg.content,
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),

                  if (msg.hasImageAttachment) ...[
                    const SizedBox(height: 8),
                    _buildImageAttachment(theme, msg.attachment!),
                  ],

                  // Optional Location Preview
                  if (msg.location != null) ...[
                    const SizedBox(height: 8),
                    _buildLocationPreviewCard(theme, msg.location!),
                  ],

                  const SizedBox(height: 6),

                  // Bottom row: Timestamp + Delivery Status Ticks
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        msg.formattedTime,
                        style: TextStyle(color: theme.textMuted, fontSize: 11),
                      ),
                      const SizedBox(width: 6),
                      _buildStatusTickWidget(theme, msg.status),
                      const SizedBox(width: 4),
                      Text(
                        _formatStatusLabel(msg),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: msg.status == MessageDeliveryStatus.delivered
                              ? successColor
                              : (msg.status ==
                                            MessageDeliveryStatus.sentNearby ||
                                        msg.status ==
                                            MessageDeliveryStatus.relayed
                                    ? infoColor
                                    : theme.textMuted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceNotePlayer(ThemeProvider theme, ChatMessage msg) {
    final isPlaying = _playingVoiceMessageId == msg.messageId;
    return InkWell(
      onTap: () => _toggleVoicePlayback(msg),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: theme.surfaceSunken,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTokens.signalYellow,
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: AppTokens.nightNavy,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.content,
                    style: TextStyle(
                      color: theme.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 140,
                    child: LinearProgressIndicator(
                      value: isPlaying ? null : 0.0,
                      backgroundColor: theme.border,
                      color: AppTokens.beaconTeal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatStatusLabel(ChatMessage msg) {
    switch (msg.status) {
      case MessageDeliveryStatus.relayed:
        final count = msg.hopCount > 0 ? msg.hopCount : 1;
        return '↗ Relayed by $count devices';
      case MessageDeliveryStatus.delivered:
        return '✓ Reached recipient';
      case MessageDeliveryStatus.saved:
        return '✓ Saved on this phone';
      case MessageDeliveryStatus.queued:
      case MessageDeliveryStatus.sending:
        return 'Queued in outbox';
      case MessageDeliveryStatus.sentNearby:
        return 'Sent to nearby';
      case MessageDeliveryStatus.failed:
        return 'Failed';
    }
  }

  Widget _buildStatusTickWidget(
    ThemeProvider theme,
    MessageDeliveryStatus status,
  ) {
    final infoColor = theme.isLightMode
        ? AppTokens.lightInfo
        : AppTokens.darkInfo;
    final successColor = theme.isLightMode
        ? AppTokens.lightSuccess
        : AppTokens.darkSuccess;
    final sosColor = theme.isLightMode ? AppTokens.lightSos : AppTokens.darkSos;

    switch (status) {
      case MessageDeliveryStatus.saved:
        return const Icon(Icons.check, size: 14, color: Color(0xFF9E9E9E));
      case MessageDeliveryStatus.queued:
      case MessageDeliveryStatus.sending:
        return const Icon(
          Icons.access_time_rounded,
          size: 13,
          color: Color(0xFFFFC400),
        );
      case MessageDeliveryStatus.sentNearby:
      case MessageDeliveryStatus.relayed:
        return Icon(Icons.compare_arrows_rounded, size: 14, color: infoColor);
      case MessageDeliveryStatus.delivered:
        return Icon(Icons.done_all_rounded, size: 14, color: successColor);
      case MessageDeliveryStatus.failed:
        return Icon(Icons.error_outline, size: 14, color: sosColor);
    }
  }

  /// Incoming message bubble (theirs)
  Widget _buildTheirMessageBubble(
    ThemeProvider theme,
    ChatService chatService,
    ChatMessage msg,
  ) {
    final isLight = theme.isLightMode;
    final isBookmarked = chatService.isBookmarked(msg.messageId);
    final initial = msg.senderName.isNotEmpty
        ? msg.senderName[0].toUpperCase()
        : '?';

    final bubbleBg = isLight ? theme.surfaceSunken : theme.surface;
    final infoColor = isLight ? AppTokens.lightInfo : AppTokens.darkInfo;

    final isGroup = msg.conversationId.startsWith('CONV_GRP-') ||
        chatService.activeFilter == 'Group';
    final senderColor = isGroup
        ? _getSenderColor(msg.senderId, isLight)
        : infoColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isGroup
                ? senderColor.withValues(alpha: 0.18)
                : theme.surfaceSunken,
            child: Text(
              initial,
              style: TextStyle(
                color: senderColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bubbleBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(color: theme.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          msg.senderName,
                          style: TextStyle(
                            color: isGroup ? senderColor : theme.text,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => chatService.toggleBookmark(msg.messageId),
                        child: Icon(
                          isBookmarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          size: 16,
                          color: isBookmarked
                              ? AppTokens.signalYellow
                              : theme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (msg.messageType == 'VOICE')
                    _buildVoiceNotePlayer(theme, msg)
                  else
                    Text(
                      msg.content,
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                  if (msg.hasImageAttachment) ...[
                    const SizedBox(height: 8),
                    _buildImageAttachment(theme, msg.attachment!),
                  ],
                  if (msg.location != null) ...[
                    const SizedBox(height: 8),
                    _buildLocationPreviewCard(theme, msg.location!),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    msg.formattedTime,
                    style: TextStyle(color: theme.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  /// Shared Location Preview Card
  Widget _buildLocationPreviewCard(
    ThemeProvider theme,
    LocationPreview location,
  ) {
    final isLight = theme.isLightMode;
    final isLowPower = theme.isLowPower;

    final cardBg = isLight
        ? AppTokens.lightInfo.withValues(alpha: 0.1)
        : (isLowPower ? const Color(0xFF07141A) : const Color(0xFF0F2633));

    final infoColor = isLight ? AppTokens.lightInfo : AppTokens.darkInfo;

    // Calculate dynamic GeospatialDistanceResult relative to local device position
    final localFix = LocationService.instance.currentFix;
    final geoResult = HaversineDistance.calculateDistanceNullable(
      lat1: localFix?.latitude,
      lng1: localFix?.longitude,
      accuracy1: localFix?.horizontalAccuracyMeters ?? 20.0,
      timestamp1: localFix?.timestamp ?? DateTime.now().millisecondsSinceEpoch,
      lat2: location.latitude,
      lng2: location.longitude,
      accuracy2: 15.0,
      timestamp2: DateTime.now().millisecondsSinceEpoch,
    );

    final distanceLabel = geoResult.isCoordinatesAvailable
        ? 'Distance: ${geoResult.summaryLabel}'
        : (location.distance.isNotEmpty
            ? location.distance
            : (geoResult.fallbackPrompt ?? 'Coordinates unavailable'));

    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: location.title));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied location coordinates: ${location.title}'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(color: infoColor.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: infoColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_on, color: infoColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Shared location',
                        style: TextStyle(
                          color: infoColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (geoResult.isCoordinatesAvailable) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: geoResult.freshnessStatus == GeospatialFreshness.live
                                ? AppTokens.beaconTeal.withValues(alpha: 0.2)
                                : AppTokens.warningAmber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            geoResult.freshnessStatus,
                            style: TextStyle(
                              color: geoResult.freshnessStatus == GeospatialFreshness.live
                                  ? AppTokens.beaconTeal
                                  : AppTokens.warningAmber,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    location.title,
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    distanceLabel,
                    style: TextStyle(color: theme.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.copy_rounded, size: 16, color: infoColor),
          ],
        ),
      ),
    );
  }

  Widget _buildImageAttachment(
    ThemeProvider theme,
    MediaAttachment attachment,
  ) {
    final file = File(attachment.localPath);
    return Semantics(
      label: 'Shared image: ${attachment.fileName}',
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        child: Image.file(
          file,
          fit: BoxFit.cover,
          width: 220,
          height: 160,
          errorBuilder: (_, _, _) => Container(
            width: 220,
            constraints: const BoxConstraints(minHeight: 56),
            color: theme.surfaceSunken,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.broken_image_outlined, color: theme.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Image unavailable on this phone',
                    style: TextStyle(color: theme.textMuted, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Emergency Shortcuts Bar ("Need medical help", "We are safe here", "Road blocked", etc.)
  Widget _buildEmergencyShortcutsBar(ThemeProvider theme) {
    final sosColor = theme.isLightMode ? AppTokens.lightSos : AppTokens.darkSos;

    return Container(
      height: 40,
      margin: const EdgeInsets.only(top: 2, bottom: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _emergencyShortcuts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final shortcut = _emergencyShortcuts[index];
          return ActionChip(
            elevation: 0,
            backgroundColor: theme.surfaceSunken,
            side: BorderSide(color: theme.border),
            avatar: Icon(Icons.emergency_outlined, size: 14, color: sosColor),
            label: Text(
              shortcut,
              style: TextStyle(
                color: theme.text,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () => _handleSendMessage(overrideText: shortcut),
          );
        },
      ),
    );
  }

  /// Active Voice Note Recording Bar
  Widget _buildVoiceRecordingBar(ThemeProvider theme) {
    final mins = (_voiceSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_voiceSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(top: BorderSide(color: theme.border, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppTokens.sosRed,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Recording Voice Note • $mins:$secs',
              style: TextStyle(
                color: theme.text,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: _cancelVoiceRecording,
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppTokens.sosRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 6),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTokens.signalYellow,
              foregroundColor: AppTokens.nightNavy,
              minimumSize: const Size(88, 42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
              ),
            ),
            onPressed: _sendVoiceRecording,
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text(
              'Send',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom Input Bar with mic icon, text field, and send arrow button
  Widget _buildInputBar(
    ThemeProvider theme,
    ChatService chatService,
    GroupService groupService,
  ) {
    final isLight = theme.isLightMode;
    final isLowPower = theme.isLowPower;

    final barBg = isLight
        ? AppTokens.lightBgAlt
        : (isLowPower ? AppTokens.oledBgAlt : AppTokens.darkBgAlt);

    final activeGroup =
        chatService.activeFilter == 'Group' ? groupService.selectedGroup : null;
    final hintText = activeGroup != null
        ? 'Message ${activeGroup.name}...'
        : 'Type a message...';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: barBg,
        border: Border(top: BorderSide(color: theme.border, width: 1)),
      ),
      child: Row(
        children: [
          // Expanded input pill
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                border: Border.all(color: theme.border, width: 1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  // Image attachment
                  IconButton(
                    icon: Icon(
                      Icons.image_outlined,
                      color: theme.textMuted,
                      size: 22,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 40,
                    ),
                    tooltip: 'Send image offline',
                    onPressed: _pickAndSendImage,
                  ),

                  // Location sharing
                  IconButton(
                    icon: Icon(
                      Icons.my_location_outlined,
                      color: theme.textMuted,
                      size: 20,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 40,
                    ),
                    tooltip: 'Share emergency location',
                    onPressed: _shareCurrentLocation,
                  ),

                  // Text input
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      style: TextStyle(color: theme.text, fontSize: 15),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSendMessage(),
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: TextStyle(
                          color: theme.textMuted,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                      ),
                    ),
                  ),

                  // Microphone Button (starts interactive voice note recording)
                  IconButton(
                    icon: Icon(
                      Icons.mic_none_rounded,
                      color: theme.textMuted,
                      size: 22,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    tooltip: 'Record offline voice note',
                    onPressed: _startVoiceRecording,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send Button (50dp circular safety yellow button)
          Material(
            color: AppTokens.signalYellow,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _handleSendMessage(),
              child: Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.send_rounded,
                  color: AppTokens.nightNavy,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
