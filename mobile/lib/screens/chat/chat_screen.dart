import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_message.dart';
import '../../services/chat_service.dart';
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

  final List<String> _emergencyShortcuts = [
    'Need medical help',
    'We are safe here',
    'Road blocked',
    'Need drinking water',
    'Trapped - send help',
  ];

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
    final chatService = Provider.of<ChatService>(context);
    final messages = chatService.communityMessages;

    return Scaffold(
      backgroundColor: AppTokens.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildHeader(context, chatService),

            // Filter Tabs: "Nearby", "Group", "Rescue", "Saved"
            _buildFilterTabs(chatService),

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
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            return _buildMessageRow(msg);
                          },
                        ),
            ),

            // Emergency Shortcuts Bar
            _buildEmergencyShortcutsBar(),

            // Bottom Input Bar
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  /// Authentic empty state when SQLite messages table is empty
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppTokens.darkSurfaceSunken,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 32,
                color: AppTokens.darkTextMuted,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No messages yet',
              style: TextStyle(
                color: AppTokens.darkText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Stay connected, nearby peer messages will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTokens.darkTextMuted,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Screen 5 Header: "Community Chat", subtitle "Nearby devices • 24 online", search icon
  Widget _buildHeader(BuildContext context, ChatService chatService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTokens.darkBg,
        border: Border(
          bottom: BorderSide(
            color: AppTokens.darkBorder,
            width: 1,
          ),
        ),
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
                const Text(
                  'Community Chat',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTokens.darkText,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppTokens.darkSuccess,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Nearby devices • ${chatService.onlineDevices} online',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTokens.darkTextMuted,
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
            icon: const Icon(Icons.search, color: AppTokens.darkText, size: 24),
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
                const Icon(Icons.outbox_rounded,
                    color: AppTokens.signalYellow, size: 24),
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
  Widget _buildFilterTabs(ChatService chatService) {
    final tabs = ['Nearby', 'Group', 'Rescue', 'Saved'];

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
                color: isSelected
                    ? AppTokens.signalYellow
                    : AppTokens.darkSurface,
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                border: Border.all(
                  color: isSelected
                      ? AppTokens.signalYellow
                      : AppTokens.darkBorder,
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                tab,
                style: TextStyle(
                  color: isSelected ? AppTokens.nightNavy : AppTokens.darkText,
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

  /// Message row (mine vs theirs)
  Widget _buildMessageRow(ChatMessage msg) {
    if (msg.isMine) {
      return _buildMyMessageBubble(msg);
    } else {
      return _buildTheirMessageBubble(msg);
    }
  }

  /// Outgoing message bubble (mine)
  Widget _buildMyMessageBubble(ChatMessage msg) {
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
                color: const Color(0xFF2E2712), // Warm yellow-navy contrast tint
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
                border: Border.all(
                  color: AppTokens.darkPrimary.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sender Tag "You"
                  const Text(
                    'You',
                    style: TextStyle(
                      color: AppTokens.signalYellow,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Message Text
                  Text(
                    msg.content,
                    style: const TextStyle(
                      color: AppTokens.darkText,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),

                  // Optional Location Preview
                  if (msg.location != null) ...[
                    const SizedBox(height: 8),
                    _buildLocationPreviewCard(msg.location!),
                  ],

                  const SizedBox(height: 6),

                  // Bottom row: Timestamp + Delivery Status Tick
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        msg.formattedTime,
                        style: const TextStyle(
                          color: AppTokens.darkTextMuted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 6),
                      msg.buildStatusWidget(),
                      const SizedBox(width: 4),
                      Text(
                        msg.status.label,
                        style: TextStyle(
                          fontSize: 10,
                          color: msg.status == MessageDeliveryStatus.delivered
                              ? AppTokens.darkSuccess
                              : (msg.status == MessageDeliveryStatus.sentNearby ||
                                      msg.status == MessageDeliveryStatus.relayed
                                  ? AppTokens.darkInfo
                                  : AppTokens.darkTextMuted),
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

  /// Incoming message bubble (theirs)
  Widget _buildTheirMessageBubble(ChatMessage msg) {
    final initial =
        msg.senderName.isNotEmpty ? msg.senderName[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sender Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTokens.darkSurfaceSunken,
            child: Text(
              initial,
              style: const TextStyle(
                color: AppTokens.darkInfo,
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
                color: AppTokens.darkSurface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(
                  color: AppTokens.darkBorder,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sender Name
                  Text(
                    msg.senderName,
                    style: const TextStyle(
                      color: AppTokens.darkText,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Message Content
                  Text(
                    msg.content,
                    style: const TextStyle(
                      color: AppTokens.darkText,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),

                  // Shared Location Preview Card
                  if (msg.location != null) ...[
                    const SizedBox(height: 8),
                    _buildLocationPreviewCard(msg.location!),
                  ],

                  const SizedBox(height: 6),

                  // Timestamp
                  Text(
                    msg.formattedTime,
                    style: const TextStyle(
                      color: AppTokens.darkTextMuted,
                      fontSize: 11,
                    ),
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
  /// ("Shared location: Near Village School ~1.2 km from you")
  Widget _buildLocationPreviewCard(LocationPreview location) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2633), // Beacon teal soft container
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(
          color: AppTokens.darkInfo.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTokens.darkInfo.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on,
              color: AppTokens.darkInfo,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Shared location',
                  style: TextStyle(
                    color: AppTokens.darkInfo,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  location.title,
                  style: const TextStyle(
                    color: AppTokens.darkText,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  location.distance,
                  style: const TextStyle(
                    color: AppTokens.darkTextMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Emergency Shortcuts Bar ("Need medical help", "We are safe here", "Road blocked", etc.)
  Widget _buildEmergencyShortcutsBar() {
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
            backgroundColor: AppTokens.darkSurfaceSunken,
            side: const BorderSide(color: AppTokens.darkBorderStrong),
            avatar: const Icon(
              Icons.emergency_outlined,
              size: 14,
              color: AppTokens.darkSos,
            ),
            label: Text(
              shortcut,
              style: const TextStyle(
                color: AppTokens.darkText,
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
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTokens.darkBgAlt,
        border: Border(
          top: BorderSide(
            color: AppTokens.darkBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Expanded input pill
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppTokens.darkSurface,
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                border: Border.all(
                  color: AppTokens.darkBorder,
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  // Smile / Attachment icon
                  IconButton(
                    icon: const Icon(
                      Icons.sentiment_satisfied_alt,
                      color: AppTokens.darkTextMuted,
                      size: 22,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                    onPressed: () {},
                  ),

                  // Text input
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      style: const TextStyle(
                        color: AppTokens.darkText,
                        fontSize: 15,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color: AppTokens.darkTextMuted,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 4),
                      ),
                    ),
                  ),

                  // Microphone Button
                  IconButton(
                    icon: const Icon(
                      Icons.mic_none,
                      color: AppTokens.darkTextMuted,
                      size: 22,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
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
