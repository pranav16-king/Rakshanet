import 'package:flutter/material.dart';
import '../models/mesh_message.dart';
import '../theme/app_tokens.dart';

class ChatBubble extends StatelessWidget {
  final MeshMessage message;
  final bool isMe;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = isMe
        ? AppTokens.darkPrimarySoft
        : theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(
            color: isMe ? AppTokens.signalYellow.withValues(alpha: 0.4) : AppTokens.darkBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                message.senderName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTokens.beaconTeal,
                ),
              ),
            Text(
              message.content,
              style: TextStyle(
                fontSize: 15,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.hopCount > 0) ...[
                  const Icon(Icons.share, size: 12, color: AppTokens.beaconTeal),
                  const SizedBox(width: 2),
                  Text(
                    'Hop ${message.hopCount}',
                    style: const TextStyle(fontSize: 11, color: AppTokens.beaconTeal),
                  ),
                  const SizedBox(width: 6),
                ],
                _buildStatusIcon(message.status),
                const SizedBox(width: 4),
                Text(
                  message.status,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    switch (status) {
      case 'SAVED':
        return const Icon(Icons.save_outlined, size: 12, color: Colors.grey);
      case 'SENT_TO_NEARBY':
      case 'RELAYED':
        return const Icon(Icons.check, size: 12, color: AppTokens.beaconTeal);
      case 'DELIVERED':
        return const Icon(Icons.done_all, size: 12, color: AppTokens.lightSuccess);
      default:
        return const Icon(Icons.access_time, size: 12, color: Colors.grey);
    }
  }
}
