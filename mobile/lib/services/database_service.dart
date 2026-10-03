import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/chat_message.dart';
import 'device_identity_service.dart';

/// Compatibility facade for mesh persistence.
///
/// The app used to open a second connection to `rakshanet.db` with a different
/// messages schema. On a real phone that made every chat insert fail while
/// tests silently fell back to memory. All durable app data now goes through
/// [AppDatabase], the single SQLite owner.
class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;

  static String get myDeviceId => DeviceIdentityService.instance.deviceId;
  static String get myDisplayName => DeviceIdentityService.instance.displayName;

  Future<void> insertMessage(Map<String, dynamic> row) async {
    await AppDatabase.instance.insert(
      'messages',
      Map<String, dynamic>.from(row),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateMessageStatus({
    required String messageId,
    required String status,
    int? hopCount,
  }) async {
    final values = <String, dynamic>{'status': status};
    if (hopCount != null) values['hop_count'] = hopCount;
    await AppDatabase.instance.update(
      'messages',
      values,
      where: 'message_id = ?',
      whereArgs: [messageId],
    );
  }

  Future<bool> messageExists(String messageId) async {
    final rows = await AppDatabase.instance.query(
      'messages',
      columns: const ['message_id'],
      where: 'message_id = ?',
      whereArgs: [messageId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<List<ChatMessage>> getMessagesForConversation(
    String conversationId,
  ) async {
    final rows = await AppDatabase.instance.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp ASC',
    );
    return rows
        .map((row) => ChatMessage.fromDbMap(row, myDeviceId: myDeviceId))
        .toList();
  }

  Future<List<ChatMessage>> getAllMessages() =>
      AppDatabase.instance.getMessages(limit: 5000);

  Future<ChatMessage?> getMessageById(String messageId) async {
    final rows = await AppDatabase.instance.query(
      'messages',
      where: 'message_id = ?',
      whereArgs: [messageId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ChatMessage.fromDbMap(rows.first, myDeviceId: myDeviceId);
  }

  Future<List<ChatMessage>> getPendingOutboxMessages() async {
    final rows = await AppDatabase.instance.query(
      'messages',
      where: 'status = ? OR status = ?',
      whereArgs: const ['SAVED', 'QUEUED'],
      orderBy: 'timestamp ASC',
    );
    return rows
        .map((row) => ChatMessage.fromDbMap(row, myDeviceId: myDeviceId))
        .toList();
  }

  Future<void> recordRelayAudit({
    required String messageId,
    required String fromDeviceId,
    required String toDeviceId,
    required int hopNumber,
    required String status,
  }) async {
    await AppDatabase.instance.insert('message_relays', {
      'id':
          'RELAY-${DateTime.now().microsecondsSinceEpoch}-${messageId.hashCode}',
      'message_id': messageId,
      'from_device_id': fromDeviceId,
      'to_device_id': toDeviceId,
      'hop_number': hopNumber,
      'received_at': DateTime.now().millisecondsSinceEpoch,
      'status': status,
    });
  }
}
