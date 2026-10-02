import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/chat_message.dart';
import '../../theme/app_tokens.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final TextEditingController _msgController = TextEditingController();
  int _selectedCategoryIndex = 0;
  final List<String> _categories = ['Nearby', 'Group', 'Rescue', 'Saved'];

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    context.read<ChatProvider>().sendMessage(text);
    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final chat = context.watch<ChatProvider>();
    final messages = chat.messages;

    final surface = theme.surface;
    final textColor = theme.text;
    final textMuted = theme.textMuted;
    final borderColor = theme.border;

    return Column(
      children: [
        // Category Pills (Mockup Screen 5: Nearby, Group, Rescue, Saved)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: List.generate(_categories.length, (index) {
              final isSelected = _selectedCategoryIndex == index;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_categories[index]),
                  selected: isSelected,
                  selectedColor: AppTokens.signalYellow,
                  backgroundColor: surface,
                  labelStyle: TextStyle(
                    color: isSelected ? AppTokens.lightOnPrimary : textColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppTokens.signalYellow : borderColor,
                  ),
                  onSelected: (val) {
                    setState(() => _selectedCategoryIndex = index);
                  },
                ),
              );
            }),
          ),
        ),

        // Message List
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.forum_outlined, size: 56, color: textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'No mesh messages yet',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Messages broadcast or received via BLE/Wi-Fi Direct will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return _buildMessageRow(msg, theme);
                  },
                ),
        ),

        // Bottom Input Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: surface,
            border: Border(top: BorderSide(color: borderColor, width: 1)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.mic_none),
                  color: textMuted,
                  tooltip: 'Voice memo',
                  onPressed: () {},
                ),
                Expanded(
                  child: Container(
                    height: AppTokens.inputHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: theme.surfaceSunken,
                      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                      border: Border.all(color: borderColor),
                    ),
                    child: Center(
                      child: TextField(
                        controller: _msgController,
                        style: TextStyle(color: textColor, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Type an offline message...',
                          hintStyle: TextStyle(color: textMuted, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _sendMessage,
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppTokens.signalYellow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: AppTokens.lightOnPrimary,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageRow(ChatMessage msg, ThemeProvider theme) {
    final isMe = msg.isOutgoing;
    final timeStr =
        '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF334155),
              child: Text(
                msg.senderName.substring(0, 1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      msg.senderName,
                      style: TextStyle(
                        color: theme.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeStr,
                      style: TextStyle(
                        color: theme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF3A3010) : theme.surfaceSunken,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(AppTokens.radiusMd),
                      topRight: const Radius.circular(AppTokens.radiusMd),
                      bottomLeft: isMe
                          ? const Radius.circular(AppTokens.radiusMd)
                          : const Radius.circular(2),
                      bottomRight: isMe
                          ? const Radius.circular(2)
                          : const Radius.circular(AppTokens.radiusMd),
                    ),
                    border: Border.all(
                      color: isMe ? AppTokens.signalYellow : theme.border,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    msg.content,
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        msg.status.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: msg.status == MessageStatus.delivered
                              ? const Color(0xFF4CD08A)
                              : AppTokens.signalYellow,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        msg.status == MessageStatus.delivered
                            ? Icons.done_all
                            : Icons.access_time,
                        size: 12,
                        color: msg.status == MessageStatus.delivered
                            ? const Color(0xFF4CD08A)
                            : AppTokens.signalYellow,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 6),
        ],
      ),
    );
  }
}
