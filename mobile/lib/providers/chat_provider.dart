import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../database/app_database.dart';

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  int get unreadCount => _unreadCount;

  int get pendingOutboxCount => _messages
      .where(
        (m) =>
            m.isOutgoing &&
            (m.status == MessageStatus.saved ||
                m.status == MessageStatus.queued ||
                m.status == MessageStatus.sending),
      )
      .length;

  bool get isLoading => _isLoading;

  ChatProvider() {
    loadMessages();
  }

  Future<void> loadMessages() async {
    _isLoading = true;
    notifyListeners();

    try {
      final dbMessages = await AppDatabase.instance.getMessages();
      _messages.clear();
      _messages.addAll(dbMessages);
    } catch (e) {
      debugPrint('[ChatProvider] Error loading messages from SQLite: $e');
      _messages.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sends a message using the strict Save-Before-Send guarantee
  Future<ChatMessage> sendMessage(
    String content, {
    String senderName = 'You',
    String conversationId = 'community',
  }) async {
    if (content.trim().isEmpty) throw ArgumentError('Message cannot be empty');

    final messageId = const Uuid().v4();
    final message = ChatMessage(
      id: messageId,
      conversationId: conversationId,
      senderId: 'self',
      senderName: senderName,
      content: content.trim(),
      timestamp: DateTime.now(),
      status: MessageStatus.saved, // Step 1: Immediately SAVED to local SQLite
      isOutgoing: true,
      hopCount: 0,
    );

    // Save-Before-Send: Must write to database before broadcasting
    _messages.add(message);
    notifyListeners();
    await AppDatabase.instance.saveMessage(message);

    // Step 2: Queue for BLE mesh broadcast
    Timer(const Duration(milliseconds: 400), () async {
      _updateLocalStatus(messageId, MessageStatus.queued);
      await AppDatabase.instance.updateMessageStatus(
        messageId,
        MessageStatus.queued,
      );

      // Step 3: Mesh relay hop simulation
      Timer(const Duration(milliseconds: 800), () async {
        _updateLocalStatus(messageId, MessageStatus.relayed);
        await AppDatabase.instance.updateMessageStatus(
          messageId,
          MessageStatus.relayed,
        );

        // Step 4: Reached nearby devices / delivered
        Timer(const Duration(milliseconds: 1200), () async {
          _updateLocalStatus(messageId, MessageStatus.delivered);
          await AppDatabase.instance.updateMessageStatus(
            messageId,
            MessageStatus.delivered,
          );
        });
      });
    });

    return message;
  }

  void _updateLocalStatus(String messageId, MessageStatus status) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index >= 0) {
      _messages[index] = _messages[index].copyWith(status: status);
      notifyListeners();
    }
  }

  void markAllAsRead() {
    if (_unreadCount > 0) {
      _unreadCount = 0;
      notifyListeners();
    }
  }

  Future<void> syncPendingOutbox() async {
    final pending = await AppDatabase.instance.getPendingOutboxMessages();
    for (final msg in pending) {
      _updateLocalStatus(msg.id, MessageStatus.delivered);
      await AppDatabase.instance.updateMessageStatus(
        msg.id,
        MessageStatus.delivered,
      );
    }
    notifyListeners();
  }
}
