import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_message.dart';
import '../../services/chat_service.dart';
import '../../theme/app_tokens.dart';

/// Screen 10: My Messages & Sync Status
/// Displays Outbox queue, pending reports, sent items, received broadcasts,
/// and live sync status with government and rescue agencies.
class MyMessagesScreen extends StatefulWidget {
  const MyMessagesScreen({super.key});

  @override
  State<MyMessagesScreen> createState() => _MyMessagesScreenState();
}

class _MyMessagesScreenState extends State<MyMessagesScreen> {
  int _selectedTabIndex = 0; // 0: Pending, 1: Sent, 2: Received

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);
    final pendingMessages = chatService.pendingMessages;
    final sentMessages = chatService.sentMessages;
    final receivedMessages = chatService.receivedMessages;

    return Scaffold(
      backgroundColor: AppTokens.darkBg,
      appBar: AppBar(
        backgroundColor: AppTokens.darkBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTokens.darkText),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        title: const Text(
          'My Messages',
          style: TextStyle(
            color: AppTokens.darkText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppTokens.darkBorder,
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            // Segmented Filter Tabs: Pending / Sent / Received
            _buildSegmentedTabs(),

            const SizedBox(height: 12),

            // Content Area based on Tab
            Expanded(
              child: _buildTabContent(
                pendingMessages: pendingMessages,
                sentMessages: sentMessages,
                receivedMessages: receivedMessages,
                isSyncing: chatService.isSyncing,
              ),
            ),

            // Bottom Sync Status Card (matching Screen 10 mockup)
            _buildSyncStatusCard(
              context: context,
              pendingCount: pendingMessages.length,
              isSyncing: chatService.isSyncing,
              onSyncTap: () => chatService.syncAllPendingNow(),
            ),
          ],
        ),
      ),
    );
  }

  /// Segmented tabs bar
  Widget _buildSegmentedTabs() {
    final tabs = ['Pending', 'Sent', 'Received'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTokens.darkSurfaceSunken,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        border: Border.all(color: AppTokens.darkBorder),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppTokens.signalYellow : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    color: isSelected
                        ? AppTokens.nightNavy
                        : AppTokens.darkTextMuted,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent({
    required List<ChatMessage> pendingMessages,
    required List<ChatMessage> sentMessages,
    required List<ChatMessage> receivedMessages,
    required bool isSyncing,
  }) {
    if (_selectedTabIndex == 0) {
      // Pending Tab
      if (pendingMessages.isEmpty) {
        return _buildEmptyState(
          icon: Icons.check_circle_outline,
          title: 'All messages sent!',
          subtitle: 'No pending items waiting for network sync.',
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: pendingMessages.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = pendingMessages[index];
          return _buildPendingMessageCard(item);
        },
      );
    } else if (_selectedTabIndex == 1) {
      // Sent Tab
      if (sentMessages.isEmpty) {
        return _buildEmptyState(
          icon: Icons.outbox,
          title: 'No sent messages yet',
          subtitle: 'Messages relayed through the mesh network will show here.',
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: sentMessages.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = sentMessages[index];
          return _buildSentMessageCard(item);
        },
      );
    } else {
      // Received Tab
      if (receivedMessages.isEmpty) {
        return _buildEmptyState(
          icon: Icons.inbox,
          title: 'No received broadcasts',
          subtitle: 'Broadcasts from nearby peer devices will appear here.',
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: receivedMessages.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = receivedMessages[index];
          return _buildReceivedMessageCard(item);
        },
      );
    }
  }

  /// Screen 10 Pending Card:
  /// SOS - Trapped ("To: Nearby devices", "Waiting for network...")
  /// Location Update ("To: Rescue Team", "Waiting for network...")
  /// Missing Person Report ("To: Government", "Waiting for network...")
  Widget _buildPendingMessageCard(ChatMessage item) {
    IconData iconData = Icons.warning_amber_rounded;
    Color iconBgColor = AppTokens.sosRed;
    String title = item.category ?? 'Emergency Alert';
    String toTarget = item.recipientTarget ?? 'To: Nearby devices';

    if (item.category == 'SOS - Trapped' || item.messageType == 'SOS') {
      iconData = Icons.emergency_outlined;
      iconBgColor = AppTokens.sosRed;
      title = 'SOS - Trapped';
      toTarget = item.recipientTarget ?? 'To: Nearby devices';
    } else if (item.category == 'Location Update' ||
        item.messageType == 'LOCATION') {
      iconData = Icons.location_on;
      iconBgColor = const Color(0xFF2F6FDE);
      title = 'Location Update';
      toTarget = item.recipientTarget ?? 'To: Rescue Team';
    } else if (item.category == 'Missing Person Report' ||
        item.messageType == 'REPORT') {
      iconData = Icons.person_search;
      iconBgColor = AppTokens.darkWarning;
      title = 'Missing Person Report';
      toTarget = item.recipientTarget ?? 'To: Government';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTokens.darkSurface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: AppTokens.darkBorder),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconBgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            iconData,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppTokens.darkText,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              toTarget,
              style: const TextStyle(
                color: AppTokens.darkTextMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTokens.darkSos,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Waiting for network...',
                  style: TextStyle(
                    color: AppTokens.darkSos,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              item.formattedTime,
              style: const TextStyle(
                color: AppTokens.darkTextMuted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            const Icon(
              Icons.chevron_right,
              color: AppTokens.darkTextMuted,
              size: 20,
            ),
          ],
        ),
        onTap: () => _showItemDetailDialog(item, title, toTarget),
      ),
    );
  }

  Widget _buildSentMessageCard(ChatMessage item) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.darkSurface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: AppTokens.darkBorder),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTokens.darkInfo.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.done_all,
            color: AppTokens.darkInfo,
            size: 22,
          ),
        ),
        title: Text(
          item.category ?? (item.recipientTarget ?? 'Broadcast'),
          style: const TextStyle(
            color: AppTokens.darkText,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              item.content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTokens.darkTextMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Status: ${item.status.label} (${item.hopCount} hops)',
              style: const TextStyle(
                color: AppTokens.darkSuccess,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Text(
          item.formattedTime,
          style: const TextStyle(
            color: AppTokens.darkTextMuted,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildReceivedMessageCard(ChatMessage item) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.darkSurface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: AppTokens.darkBorder),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTokens.darkSurfaceSunken,
          radius: 22,
          child: Text(
            item.senderName.isNotEmpty ? item.senderName[0] : '?',
            style: const TextStyle(
              color: AppTokens.darkInfo,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          item.senderName,
          style: const TextStyle(
            color: AppTokens.darkText,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          item.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTokens.darkTextMuted,
            fontSize: 13,
          ),
        ),
        trailing: Text(
          item.formattedTime,
          style: const TextStyle(
            color: AppTokens.darkTextMuted,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  /// Bottom Sync status card matching Screen 10 mockup:
  /// "● Network available! 3 messages will be sent automatically to government and rescue agencies."
  Widget _buildSyncStatusCard({
    required BuildContext context,
    required int pendingCount,
    required bool isSyncing,
    required VoidCallback onSyncTap,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2B20), // Subtle emergency green tint
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(
          color: AppTokens.darkSuccess.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circular green indicator icon
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: AppTokens.darkSuccess.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: isSyncing
                ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTokens.darkSuccess,
                    ),
                  )
                : const Icon(
                    Icons.sync_alt,
                    color: AppTokens.darkSuccess,
                    size: 20,
                  ),
          ),
          const SizedBox(width: 12),

          // Message & Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTokens.darkSuccess,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Network available!',
                      style: TextStyle(
                        color: AppTokens.darkText,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  pendingCount > 0
                      ? '$pendingCount messages will be sent automatically to government and rescue agencies.'
                      : 'All messages synchronized with government and rescue coordination.',
                  style: const TextStyle(
                    color: AppTokens.darkTextMuted,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
                if (pendingCount > 0) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: isSyncing ? null : onSyncTap,
                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTokens.darkSuccess,
                        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                      ),
                      child: Text(
                        isSyncing ? 'Syncing now...' : 'Sync Now',
                        style: const TextStyle(
                          color: AppTokens.nightNavy,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppTokens.darkTextMuted),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: AppTokens.darkText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTokens.darkTextMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showItemDetailDialog(ChatMessage item, String title, String toTarget) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTokens.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTokens.darkBorderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: AppTokens.darkText,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                toTarget,
                style: const TextStyle(
                  color: AppTokens.signalYellow,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Divider(color: AppTokens.darkBorder, height: 24),
              Text(
                item.content,
                style: const TextStyle(
                  color: AppTokens.darkText,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.lock_clock,
                      size: 16, color: AppTokens.darkTextMuted),
                  const SizedBox(width: 6),
                  Text(
                    'Created: ${item.formattedTime}  •  TTL: ${item.ttl}  •  Status: ${item.status.label}',
                    style: const TextStyle(
                      color: AppTokens.darkTextMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
