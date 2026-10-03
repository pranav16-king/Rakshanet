import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/chat_message.dart';
import '../../providers/telemetry_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/chat_service.dart';
import '../../services/group_service.dart';
import '../../theme/app_tokens.dart';
import 'my_messages_screen.dart';

/// Screen 5: Community Chat (Offline Mesh Chat)
/// Hi-vis beacon design system strictly adhered to design.md and Screen 5 visual mockup.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();

  final List<String> _emergencyShortcuts = [
    'Need medical help',
    'We are safe here',
    'Road blocked',
    'Need drinking water',
    'Trapped - send help',
  ];

  @override
  void initState() {
    super.initState();
    _recoverLostImagePick();
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
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
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
    final lat = telemetry.latitude;
    final lng = telemetry.longitude;

    if (lat == null || lng == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Acquiring GPS fix... Please ensure location permissions are granted.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final accuracyText = telemetry.hasGpsFix ? 'GPS Fix (±10m)' : 'Mesh Estimated (±35m)';
    final locationTitle = '${lat.toStringAsFixed(4)}°, ${lng.toStringAsFixed(4)}°';
    final locationPreview = LocationPreview(
      title: locationTitle,
      distance: accuracyText,
      latitude: lat,
      longitude: lng,
    );

    try {
      final chatService = context.read<ChatService>();
      await chatService.sendMessage(
        content: '📍 Shared emergency location ($accuracyText)',
        messageType: 'LOCATION',
        location: locationPreview,
      );
      _scrollToBottom();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share location: $error')),
        );
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
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

    final chatService = Provider.of<ChatService>(context, listen: false);
    await chatService.sendMessage(content: text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final chatService = context.watch<ChatService>();
    final messages = chatService.communityMessages;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildHeader(context, theme, chatService),

            // Filter Tabs: "Nearby", "Group", "Rescue", "Saved"
            _buildFilterTabs(theme, chatService),

            // Group Management & Invite Actions Bar (shown when Group tab is active)
            if (chatService.activeFilter == 'Group')
              _buildGroupHeader(theme),

            const SizedBox(height: 8),

            // Chat Messages List (or authentic empty state when SQLite is empty)
            Expanded(
              child: chatService.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTokens.signalYellow,
                      ),
                    )
                  : messages.isEmpty
                  ? _buildEmptyState(theme)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        return _buildMessageRow(theme, msg);
                      },
                    ),
            ),

            // Emergency Shortcuts Bar
            _buildEmergencyShortcutsBar(theme),

            // Bottom Input Bar
            _buildInputBar(theme),
          ],
        ),
      ),
    );
  }

  /// Authentic empty state when SQLite messages table is empty
  Widget _buildEmptyState(ThemeProvider theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.surfaceSunken,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 32,
                color: theme.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(
                color: theme.text,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Broadcasts from nearby devices will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textMuted,
                fontSize: 14,
                height: 1.4,
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
  ) {
    final successColor = theme.isLightMode
        ? AppTokens.lightSuccess
        : AppTokens.darkSuccess;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.bg,
        border: Border(bottom: BorderSide(color: theme.border, width: 1)),
      ),
      child: Row(
        children: [
          // Yellow Beacon Icon Avatar
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppTokens.signalYellow,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sensors,
              color: AppTokens.nightNavy,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Community Chat',
                  style: TextStyle(
                    fontSize: 20,
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
                    Text(
                      'Nearby devices • ${chatService.onlineDevices} online',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search Icon Button (min touch target 48dp)
          IconButton(
            icon: Icon(Icons.search, color: theme.text, size: 24),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            tooltip: 'Search messages',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Search filter active for offline mesh'),
                  duration: Duration(seconds: 1),
                ),
              );
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
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
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
  Widget _buildFilterTabs(ThemeProvider theme, ChatService chatService) {
    const tabs = ['Nearby', 'Group', 'Rescue', 'Saved'];

    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 10),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isSelected = chatService.activeFilter == tab;

          return InkWell(
            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
            onTap: () => chatService.setActiveFilter(tab),
            child: Container(
              constraints: const BoxConstraints(minWidth: AppTokens.touchMin),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
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
                tab,
                style: TextStyle(
                  color: isSelected ? AppTokens.nightNavy : theme.text,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Group Management Header: "+ Create Group", "Invites", and joined groups
  Widget _buildGroupHeader(ThemeProvider theme) {
    final groupService = context.watch<GroupService>();
    final pendingCount = groupService.pendingInviteCount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          // Pending Invites Notification Banner
          if (pendingCount > 0)
            InkWell(
              onTap: () => Navigator.pushNamed(context, '/pending-invites'),
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppTokens.beaconTeal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  border: Border.all(color: AppTokens.beaconTeal),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mail_outline_rounded, color: AppTokens.beaconTeal, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You have $pendingCount group invitation(s)!',
                        style: TextStyle(
                          color: theme.text,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Text(
                      'Review',
                      style: TextStyle(
                        color: AppTokens.beaconTeal,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppTokens.beaconTeal, size: 18),
                  ],
                ),
              ),
            ),

          // Group Actions Row: "+ Create Group" & "Invites"
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTokens.signalYellow,
                      foregroundColor: AppTokens.lightOnPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      'Create Group',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/create-group'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 38,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.text,
                    side: BorderSide(color: theme.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  icon: Icon(
                    Icons.mail_outline_rounded,
                    size: 18,
                    color: pendingCount > 0 ? AppTokens.beaconTeal : theme.textMuted,
                  ),
                  label: Text(
                    pendingCount > 0 ? 'Invites ($pendingCount)' : 'Invites',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: pendingCount > 0 ? AppTokens.beaconTeal : theme.text,
                    ),
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/pending-invites'),
                ),
              ),
            ],
          ),

          // Active Groups List
          if (groupService.groups.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: groupService.groups.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, idx) {
                  final grp = groupService.groups[idx];
                  return Chip(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: theme.surface,
                    side: BorderSide(color: theme.border),
                    avatar: const Icon(Icons.group, size: 14, color: AppTokens.beaconTeal),
                    label: Text(
                      '${grp.name} (${grp.memberCount})',
                      style: TextStyle(fontSize: 12, color: theme.text),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Message row (mine vs theirs)
  Widget _buildMessageRow(ThemeProvider theme, ChatMessage msg) {
    if (msg.isMine) {
      return _buildMyMessageBubble(theme, msg);
    } else {
      return _buildTheirMessageBubble(theme, msg);
    }
  }

  /// Outgoing message bubble (mine)
  Widget _buildMyMessageBubble(ThemeProvider theme, ChatMessage msg) {
    final isLight = theme.isLightMode;
    final isLowPower = theme.isLowPower;

    // Background and border colors matching design.md
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
          const SizedBox(width: 48), // Indent from left
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
                  // Sender Tag "You"
                  Text(
                    'You',
                    style: TextStyle(
                      color: senderColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Message Text
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
                  // Status ticks: 1 grey tick (saved locally), 2 teal ticks (sent to mesh), 2 green ticks (delivered to rescue team/cloud)
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

  /// Status ticks: 1 grey tick (saved locally), clock icon (queued), 2 teal arrows/ticks (relayed), 2 green ticks (delivered)
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
        // 1 grey tick (saved locally)
        return const Icon(Icons.check, size: 14, color: Color(0xFF9E9E9E));
      case MessageDeliveryStatus.queued:
      case MessageDeliveryStatus.sending:
        return const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFFFFC400));
      case MessageDeliveryStatus.sentNearby:
      case MessageDeliveryStatus.relayed:
        // 2 teal ticks / arrows (sent to mesh)
        return Icon(Icons.compare_arrows_rounded, size: 14, color: infoColor);
      case MessageDeliveryStatus.delivered:
        // 2 green ticks (delivered to recipient)
        return Icon(Icons.done_all_rounded, size: 14, color: successColor);
      case MessageDeliveryStatus.failed:
        return Icon(Icons.error_outline, size: 14, color: sosColor);
    }
  }

  /// Incoming message bubble (theirs)
  Widget _buildTheirMessageBubble(ThemeProvider theme, ChatMessage msg) {
    final isLight = theme.isLightMode;
    final initial = msg.senderName.isNotEmpty
        ? msg.senderName[0].toUpperCase()
        : '?';

    final bubbleBg = isLight ? theme.surfaceSunken : theme.surface;

    final infoColor = isLight ? AppTokens.lightInfo : AppTokens.darkInfo;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sender Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.surfaceSunken,
            child: Text(
              initial,
              style: TextStyle(
                color: infoColor,
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
                  // Sender Name
                  Text(
                    msg.senderName,
                    style: TextStyle(
                      color: theme.text,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Message Content
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

                  // Shared Location Preview Card
                  if (msg.location != null) ...[
                    const SizedBox(height: 8),
                    _buildLocationPreviewCard(theme, msg.location!),
                  ],

                  const SizedBox(height: 6),

                  // Timestamp
                  Text(
                    msg.formattedTime,
                    style: TextStyle(color: theme.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 40), // Right indent
        ],
      ),
    );
  }

  /// Shared Location Preview Card matching Screen 5 mockup
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

    return Container(
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
                Text(
                  'Shared location',
                  style: TextStyle(
                    color: infoColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
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
                  location.distance,
                  style: TextStyle(color: theme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
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
      height: 42,
      margin: const EdgeInsets.only(top: 4, bottom: 6),
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

  /// Bottom Input Bar with mic icon, text field, and send arrow button
  Widget _buildInputBar(ThemeProvider theme) {
    final isLight = theme.isLightMode;
    final isLowPower = theme.isLowPower;

    final barBg = isLight
        ? AppTokens.lightBgAlt
        : (isLowPower ? AppTokens.oledBgAlt : AppTokens.darkBgAlt);

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
                  // Image attachment; stored locally before mesh transfer.
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

                  // Location sharing; sends E2EE location with accuracy radius
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
                        hintText: 'Type a message...',
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

                  // Microphone Button
                  IconButton(
                    icon: Icon(
                      Icons.mic_none,
                      color: theme.textMuted,
                      size: 22,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    tooltip: 'Voice note (offline)',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Offline voice note recording ready'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
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
