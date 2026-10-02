import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../models/chat_message.dart';
import '../../models/conversation.dart';
import '../app_database.dart';

/// Repository handling Offline-First Chat Pipeline with Save-Before-Send guarantee
class ChatRepository {
  final AppDatabase _db;
  static const String _messagesTable = 'messages';
  static const String _conversationsTable = 'conversations';
  static const String _relaysTable = 'message_relays';

  ChatRepository([AppDatabase? db]) : _db = db ?? AppDatabase.instance;

  /// Fetch messages for a specific conversation ordered chronologically
  Future<List<ChatMessage>> getMessages(
    String conversationId, {
    int limit = 100,
    int offset = 0,
  }) async {
    final rows = await _db.query(
      _messagesTable,
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp ASC',
      limit: limit,
      offset: offset,
    );
    return rows.map((r) => ChatMessage.fromMap(r)).toList();
  }

  /// CRITICAL AXIOM: Save Before Send.
  /// Persist message to SQLite before any radio broadcast is attempted.
  Future<void> saveMessage(ChatMessage message) async {
    await _db.insert(
      _messagesTable,
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Also update parent conversation's last message and timestamp
    await _db.update(
      _conversationsTable,
      {
        'last_message': message.content,
        'updated_at': message.timestamp.millisecondsSinceEpoch,
      },
      where: 'conversation_id = ?',
      whereArgs: [message.conversationId],
    );
  }

  /// Update message lifecycle status: 'SAVED', 'QUEUED', 'SENT_NEARBY', 'RELAYED', 'DELIVERED', 'FAILED'
  Future<void> updateMessageStatus(String messageId, dynamic status) async {
    final statusStr = status is MessageStatus
        ? status.name.toUpperCase()
        : (status != null ? status.toString() : 'SAVED');
    await _db.update(
      _messagesTable,
      {'status': statusStr},
      where: 'message_id = ?',
      whereArgs: [messageId],
    );
  }

  /// Fetch all messages queued or saved waiting for mesh radio transmission
  Future<List<ChatMessage>> getQueuedMessages() async {
    final rows = await _db.query(
      _messagesTable,
      where: 'status = ? OR status = ?',
      whereArgs: ['SAVED', 'QUEUED'],
      orderBy: 'timestamp ASC',
    );
    return rows.map((r) => ChatMessage.fromMap(r)).toList();
  }

  /// Deduplication check for loop suppression and multi-hop forwarding
  Future<bool> hasMessage(String messageId) async {
    final rows = await _db.query(
      _messagesTable,
      columns: ['message_id'],
      where: 'message_id = ?',
      whereArgs: [messageId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Fetch all conversation channels
  Future<List<Conversation>> getConversations() async {
    final rows = await _db.query(
      _conversationsTable,
      orderBy: 'updated_at DESC',
    );
    return rows.map((r) => Conversation.fromMap(r)).toList();
  }

  /// Fetch conversation by conversationId
  Future<Conversation?> getConversationById(String conversationId) async {
    final rows = await _db.query(
      _conversationsTable,
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Conversation.fromMap(rows.first);
  }

  /// Save or update conversation
  Future<void> saveConversation(Conversation conversation) async {
    await _db.insert(
      _conversationsTable,
      conversation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Record audit hop in message_relays
  Future<void> recordRelay({
    required String messageId,
    required String fromDeviceId,
    required String toDeviceId,
    required int hopNumber,
    required String status,
  }) async {
    final relayId = 'relay_${const Uuid().v4()}';
    await _db.insert(
      _relaysTable,
      {
        'id': relayId,
        'message_id': messageId,
        'from_device_id': fromDeviceId,
        'to_device_id': toDeviceId,
        'hop_number': hopNumber,
        'received_at': DateTime.now().millisecondsSinceEpoch,
        'status': status,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieve audit trail hops for a message
  Future<List<Map<String, dynamic>>> getRelaysForMessage(String messageId) async {
    return await _db.query(
      _relaysTable,
      where: 'message_id = ?',
      whereArgs: [messageId],
      orderBy: 'hop_number ASC',
    );
  }

  /// Delete message by id
  Future<void> deleteMessage(String messageId) async {
    await _db.delete(
      _messagesTable,
      where: 'message_id = ?',
      whereArgs: [messageId],
    );
  }
}
