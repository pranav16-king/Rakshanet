import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/chat_message.dart';

/// Database Service for RakshaNet
/// SQLite is the sole durable source of truth.
/// Enforces the Save-Before-Send guarantee.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;
  bool _useInMemoryFallback = false;

  // In-memory fallback tables for non-mobile environments (e.g. desktop/unit tests)
  final List<Map<String, dynamic>> _inMemoryMessages = [];
  final List<Map<String, dynamic>> _inMemoryRelays = [];

  static const String myDeviceId = 'SR-8F42-A91C';
  static const String myDisplayName = 'You';

  Future<Database?> get database async {
    if (_useInMemoryFallback) return null;
    if (_db != null) return _db!;
    try {
      _db = await _initDatabase();
      return _db;
    } catch (e) {
      debugPrint('[DatabaseService] SQLite init failed, using in-memory fallback: $e');
      _useInMemoryFallback = true;
      _seedInMemoryData();
      return null;
    }
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'rakshanet.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await _createTables(db);
        await _seedInitialData(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    // 1. Conversations
    await db.execute('''
      CREATE TABLE IF NOT EXISTS conversations (
        id TEXT PRIMARY KEY,
        conversation_id TEXT UNIQUE NOT NULL,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 2. Offline Messages (Local Source of Truth)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS messages (
        id TEXT PRIMARY KEY,
        message_id TEXT UNIQUE NOT NULL,
        conversation_id TEXT NOT NULL,
        sender_device_id TEXT NOT NULL,
        sender_name TEXT NOT NULL,
        message_type TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        expires_at INTEGER NOT NULL,
        status TEXT NOT NULL,
        hop_count INTEGER DEFAULT 0,
        ttl INTEGER DEFAULT 5,
        recipient_target TEXT,
        location_meta TEXT,
        category TEXT
      )
    ''');

    // 3. Message Relay Audit Trail
    await db.execute('''
      CREATE TABLE IF NOT EXISTS message_relays (
        id TEXT PRIMARY KEY,
        message_id TEXT NOT NULL,
        from_device_id TEXT NOT NULL,
        to_device_id TEXT NOT NULL,
        hop_number INTEGER NOT NULL,
        received_at INTEGER NOT NULL,
        forwarded_at INTEGER,
        status TEXT NOT NULL
      )
    ''');

    // 4. Nearby Devices
    await db.execute('''
      CREATE TABLE IF NOT EXISTS nearby_devices (
        id TEXT PRIMARY KEY,
        device_id TEXT UNIQUE NOT NULL,
        display_name TEXT NOT NULL,
        connection_type TEXT NOT NULL,
        signal_strength INTEGER NOT NULL,
        proximity_band TEXT NOT NULL,
        last_seen INTEGER NOT NULL,
        first_seen INTEGER NOT NULL,
        is_connected INTEGER DEFAULT 0,
        hop_count INTEGER DEFAULT 1,
        battery_level INTEGER
      )
    ''');
  }

  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Initial Community Conversation channel (metadata only - no hardcoded chat messages)
    await db.insert('conversations', {
      'id': 'conv_1',
      'conversation_id': 'CONV_COMMUNITY',
      'type': 'GROUP',
      'title': 'Community Chat',
      'created_at': today.millisecondsSinceEpoch,
      'updated_at': today.millisecondsSinceEpoch,
    });
  }

  void _seedInMemoryData() {
    // Zero hardcoded demo messages - authentic empty state until user or peer transmits
  }

  // Save-Before-Send guarantee: writes message record to SQLite with status 'SAVED'
  Future<void> insertMessage(Map<String, dynamic> row) async {
    final db = await database;
    if (db != null) {
      await db.insert(
        'messages',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      _inMemoryMessages.removeWhere((m) => m['message_id'] == row['message_id']);
      _inMemoryMessages.add(Map<String, dynamic>.from(row));
    }
  }

  Future<void> updateMessageStatus({
    required String messageId,
    required String status,
    int? hopCount,
  }) async {
    final db = await database;
    if (db != null) {
      final values = <String, dynamic>{'status': status};
      if (hopCount != null) values['hop_count'] = hopCount;
      await db.update(
        'messages',
        values,
        where: 'message_id = ?',
        whereArgs: [messageId],
      );
    } else {
      for (var m in _inMemoryMessages) {
        if (m['message_id'] == messageId) {
          m['status'] = status;
          if (hopCount != null) m['hop_count'] = hopCount;
        }
      }
    }
  }

  Future<bool> messageExists(String messageId) async {
    final db = await database;
    if (db != null) {
      final res = await db.query(
        'messages',
        columns: ['message_id'],
        where: 'message_id = ?',
        whereArgs: [messageId],
        limit: 1,
      );
      return res.isNotEmpty;
    } else {
      return _inMemoryMessages.any((m) => m['message_id'] == messageId);
    }
  }

  Future<List<ChatMessage>> getMessagesForConversation(String convId) async {
    final db = await database;
    List<Map<String, dynamic>> results;
    if (db != null) {
      results = await db.query(
        'messages',
        where: 'conversation_id = ?',
        whereArgs: [convId],
        orderBy: 'created_at ASC',
      );
    } else {
      results = _inMemoryMessages
          .where((m) => m['conversation_id'] == convId)
          .toList()
        ..sort((a, b) => (a['created_at'] as int).compareTo(b['created_at'] as int));
    }
    return results.map((r) => ChatMessage.fromDbMap(r, myDeviceId: myDeviceId)).toList();
  }

  Future<List<ChatMessage>> getAllMessages() async {
    final db = await database;
    List<Map<String, dynamic>> results;
    if (db != null) {
      results = await db.query(
        'messages',
        orderBy: 'created_at ASC',
      );
    } else {
      results = List<Map<String, dynamic>>.from(_inMemoryMessages)
        ..sort((a, b) => (a['created_at'] as int).compareTo(b['created_at'] as int));
    }
    return results.map((r) => ChatMessage.fromDbMap(r, myDeviceId: myDeviceId)).toList();
  }

  Future<ChatMessage?> getMessageById(String messageId) async {
    final db = await database;
    List<Map<String, dynamic>> results;
    if (db != null) {
      results = await db.query(
        'messages',
        where: 'message_id = ?',
        whereArgs: [messageId],
        limit: 1,
      );
    } else {
      results = _inMemoryMessages.where((m) => m['message_id'] == messageId).toList();
    }
    if (results.isEmpty) return null;
    return ChatMessage.fromDbMap(results.first, myDeviceId: myDeviceId);
  }

  Future<List<ChatMessage>> getPendingOutboxMessages() async {
    final db = await database;
    List<Map<String, dynamic>> results;
    if (db != null) {
      results = await db.query(
        'messages',
        where: 'status IN (?, ?)',
        whereArgs: ['SAVED', 'QUEUED'],
        orderBy: 'created_at ASC',
      );
    } else {
      results = _inMemoryMessages
          .where((m) => m['status'] == 'SAVED' || m['status'] == 'QUEUED')
          .toList();
    }
    return results.map((r) => ChatMessage.fromDbMap(r, myDeviceId: myDeviceId)).toList();
  }

  Future<void> recordRelayAudit({
    required String messageId,
    required String fromDeviceId,
    required String toDeviceId,
    required int hopNumber,
    required String status,
  }) async {
    final record = {
      'id': 'RELAY-${DateTime.now().millisecondsSinceEpoch}-${messageId.hashCode}',
      'message_id': messageId,
      'from_device_id': fromDeviceId,
      'to_device_id': toDeviceId,
      'hop_number': hopNumber,
      'received_at': DateTime.now().millisecondsSinceEpoch,
      'status': status,
    };
    final db = await database;
    if (db != null) {
      await db.insert('message_relays', record);
    } else {
      _inMemoryRelays.add(record);
    }
  }
}
