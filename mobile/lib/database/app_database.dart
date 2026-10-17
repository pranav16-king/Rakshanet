import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/chat_message.dart';
import '../models/delivery_receipt.dart';
import '../models/delivery_state.dart';
import '../models/emergency_report.dart';
import '../models/encrypted_mesh_packet.dart';
import '../models/mesh_message.dart';
import '../models/missing_person.dart';
import '../models/nearby_device.dart';
import '../models/peer_capability.dart';
import '../models/shelter_resource.dart';
import '../models/user_profile.dart';
import '../services/device_identity_service.dart';

/// Database management for RakshaNet with:
/// 1. Native SQLite via sqflite on supported platforms.
/// 2. Resilient in-memory fallback if native sqflite driver is unavailable.
/// 3. A local source of truth for user- or mesh-reported records.
class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();

  Database? _db;
  bool _isInMemory = false;
  final Completer<void> _initCompleter = Completer<void>();
  bool _isInitializing = false;

  // In-memory table storage for fallback
  final Map<String, List<Map<String, dynamic>>> _memoryTables = {
    'user_profile': [],
    'nearby_devices': [],
    'conversations': [],
    'messages': [],
    'message_relays': [],
    'emergency_reports': [],
    'shelters': [],
    'missing_persons': [],
    'groups': [],
    'group_members': [],
    'group_invites': [],
    'attachment_chunks': [],
    'encrypted_mesh_packets': [],
    'peer_capabilities': [],
    'delivery_receipts': [],
    'offline_map_regions': [],
    'location_history': [],
  };

  AppDatabase._internal();

  /// Create an isolated in-memory database instance (for multi-phone simulations & testing)
  static AppDatabase createIsolated() {
    final db = AppDatabase._internal();
    db._activateInMemoryFallback();
    if (!db._initCompleter.isCompleted) {
      db._initCompleter.complete();
    }
    return db;
  }

  bool get isInMemoryFallback => _isInMemory;

  /// Ensure database is initialized before executing operations
  Future<void> ensureInitialized() async {
    if (_initCompleter.isCompleted) return;

    if (!_isInitializing) {
      _isInitializing = true;
      try {
        await _initDatabase();
        if (!_initCompleter.isCompleted) {
          _initCompleter.complete();
        }
      } catch (e, stack) {
        debugPrint('[AppDatabase] SQLite init error: $e\n$stack');
        _activateInMemoryFallback();
        if (!_initCompleter.isCompleted) {
          _initCompleter.complete();
        }
      }
    } else {
      await _initCompleter.future;
    }
  }

  Future<Database?> get database async {
    await ensureInitialized();
    return _db;
  }

  Future<void> _initDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = p.join(databasesPath, 'rakshanet.db');

      _db = await openDatabase(
        path,
        version: 6,
        onCreate: (db, version) async {
          await _createTables(db);
          await _seedInitialData(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          await _upgradeTables(db);
        },
      );
      await _upgradeTables(_db!);
      _isInMemory = false;
      debugPrint('[AppDatabase] Native SQLite connected at $path');
    } catch (e) {
      debugPrint(
        '[AppDatabase] Native SQLite driver unavailable ($e). Switching to in-memory fallback.',
      );
      _activateInMemoryFallback();
    }
  }

  Future<void> _upgradeTables(Database db) async {
    final cols = [
      'people_helped INTEGER DEFAULT 0',
      'messages_relayed INTEGER DEFAULT 0',
      'sos_forwarded INTEGER DEFAULT 0',
      'missing_found INTEGER DEFAULT 0',
      'age INTEGER',
      "email TEXT NOT NULL DEFAULT ''",
    ];
    for (final col in cols) {
      try {
        await db.execute('ALTER TABLE user_profile ADD COLUMN $col');
      } catch (_) {}
    }

    // The initial messages table pre-dated attachments, targeting, and relay
    // metadata.  Keep upgrades additive so a saved offline outbox is never
    // discarded during an app update.
    final messageCols = [
      "message_type TEXT NOT NULL DEFAULT 'TEXT'",
      'recipient_target TEXT',
      'category TEXT',
      'proximity TEXT',
      'location_title TEXT',
      'location_distance TEXT',
      'created_at INTEGER',
      'attachment_path TEXT',
      'attachment_name TEXT',
      'attachment_mime_type TEXT',
      'attachment_bytes INTEGER',
    ];
    for (final col in messageCols) {
      try {
        await db.execute('ALTER TABLE messages ADD COLUMN $col');
      } catch (_) {}
    }

    // Earlier builds inserted demonstration shelters with invented capacities
    // and coordinates. Remove only those known IDs; user- and mesh-reported
    // shelter records remain untouched.
    await db.delete(
      'shelters',
      where: 'id IN (?, ?, ?)',
      whereArgs: const ['shelter_01', 'shelter_02', 'shelter_03'],
    );

    // Fix conversation_id mismatch: unify legacy 'global_emergency' → 'CONV_COMMUNITY'
    try {
      await db.update(
        'conversations',
        {'conversation_id': 'CONV_COMMUNITY'},
        where: 'conversation_id = ?',
        whereArgs: ['global_emergency'],
      );
    } catch (_) {}

    // Ensure the community conversation row always exists with the correct ID
    try {
      await db.insert('conversations', {
        'id': 'conv_community',
        'conversation_id': 'CONV_COMMUNITY',
        'type': 'BROADCAST',
        'title': 'Community Chat',
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'last_message': 'Offline mesh channel active.',
        'unread_count': 0,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    } catch (_) {}

    // Create groups tables if missing
    try {
      await db.execute(
        'CREATE TABLE IF NOT EXISTS groups ('
        'id TEXT PRIMARY KEY, '
        'name TEXT NOT NULL, '
        'description TEXT, '
        'creator_id TEXT NOT NULL, '
        'created_at INTEGER NOT NULL, '
        'updated_at INTEGER NOT NULL, '
        'conversation_id TEXT NOT NULL, '
        'member_count INTEGER DEFAULT 1'
        ')',
      );
    } catch (_) {}
    try {
      await db.execute(
        'CREATE TABLE IF NOT EXISTS group_members ('
        'id TEXT PRIMARY KEY, '
        'group_id TEXT NOT NULL, '
        'member_device_id TEXT NOT NULL, '
        'member_name TEXT NOT NULL, '
        "status TEXT NOT NULL DEFAULT 'PENDING', "
        'joined_at INTEGER, '
        'invited_at INTEGER NOT NULL'
        ')',
      );
    } catch (_) {}
    try {
      await db.execute(
        'CREATE TABLE IF NOT EXISTS group_invites ('
        'id TEXT PRIMARY KEY, '
        'group_id TEXT NOT NULL, '
        'group_name TEXT NOT NULL, '
        'inviter_id TEXT NOT NULL, '
        'inviter_name TEXT NOT NULL, '
        'invitee_device_id TEXT NOT NULL, '
        "status TEXT NOT NULL DEFAULT 'PENDING', "
        'sent_at INTEGER NOT NULL, '
        'responded_at INTEGER'
        ')',
      );
    } catch (_) {}

    // Attachment Chunks table for offline-first encrypted image transfer
    try {
      await db.execute(
        'CREATE TABLE IF NOT EXISTS attachment_chunks ('
        'id TEXT PRIMARY KEY, '
        'message_id TEXT NOT NULL, '
        'attachment_id TEXT NOT NULL, '
        'chunk_index INTEGER NOT NULL, '
        'total_chunks INTEGER NOT NULL, '
        'chunk_path TEXT, '
        'checksum TEXT NOT NULL, '
        'status TEXT NOT NULL, '
        'updated_at INTEGER NOT NULL'
        ')',
      );
    } catch (_) {}

    // Version 6: Store-and-forward mesh packet tables, peer capabilities, delivery receipts
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS encrypted_mesh_packets (
          message_id TEXT PRIMARY KEY,
          sender_device_id TEXT NOT NULL,
          recipient_user_id TEXT,
          recipient_device_id TEXT,
          routing_header_json TEXT NOT NULL,
          encrypted_payload_json TEXT NOT NULL,
          status TEXT NOT NULL,
          hop_count INTEGER DEFAULT 0,
          ttl INTEGER DEFAULT 5,
          created_at INTEGER NOT NULL,
          expires_at INTEGER NOT NULL
        )
      ''');
    } catch (_) {}
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS peer_capabilities (
          peer_id TEXT PRIMARY KEY,
          device_id TEXT NOT NULL,
          transports TEXT,
          battery_level INTEGER,
          is_relay INTEGER,
          is_internet_gateway INTEGER,
          last_seen INTEGER
        )
      ''');
    } catch (_) {}
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS delivery_receipts (
          receipt_id TEXT PRIMARY KEY,
          message_id TEXT NOT NULL,
          recipient_id TEXT NOT NULL,
          ack_timestamp INTEGER NOT NULL,
          signature TEXT
        )
      ''');
    } catch (_) {}

    // Missing Persons columns migration
    final mpCols = [
      "gender TEXT DEFAULT 'Unspecified'",
      'lat REAL',
      'lng REAL',
      'photo_url TEXT',
      'reported_at INTEGER',
      "reported_by TEXT DEFAULT 'Anonymous'",
      "sightings_json TEXT DEFAULT '[]'",
    ];
    for (final col in mpCols) {
      try {
        await db.execute('ALTER TABLE missing_persons ADD COLUMN $col');
      } catch (_) {}
    }

    // Offline Map Regions (Spec Sections 2 & 3)
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS offline_map_regions (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          min_lat REAL NOT NULL,
          max_lat REAL NOT NULL,
          min_lng REAL NOT NULL,
          max_lng REAL NOT NULL,
          min_zoom INTEGER NOT NULL,
          max_zoom INTEGER NOT NULL,
          total_tiles INTEGER NOT NULL,
          downloaded_tiles INTEGER NOT NULL,
          size_bytes INTEGER DEFAULT 0,
          status TEXT NOT NULL,
          downloaded_at INTEGER,
          file_path TEXT
        )
      ''');
    } catch (_) {}

    // Location History (Spec Section 4)
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS location_history (
          id TEXT PRIMARY KEY,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          horizontal_accuracy REAL NOT NULL,
          altitude REAL,
          speed REAL,
          bearing REAL,
          timestamp INTEGER NOT NULL,
          source TEXT NOT NULL,
          is_live INTEGER DEFAULT 1,
          is_stale INTEGER DEFAULT 0
        )
      ''');
    } catch (_) {}
  }

  void _activateInMemoryFallback() {
    _isInMemory = true;
    _seedInMemoryData();
    debugPrint('[AppDatabase] In-memory store activated successfully.');
  }

  Future<void> _createTables(Database db) async {
    // 1. User Profile
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_profile (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL DEFAULT '',
        name TEXT NOT NULL,
        device_id TEXT NOT NULL,
        blood_group TEXT,
        emergency_contact TEXT,
        medical_notes TEXT,
        language TEXT DEFAULT 'en',
        is_registered INTEGER DEFAULT 0,
        age INTEGER,
        people_helped INTEGER DEFAULT 0,
        messages_relayed INTEGER DEFAULT 0,
        sos_forwarded INTEGER DEFAULT 0,
        missing_found INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 2. Nearby Devices
    await db.execute('''
      CREATE TABLE IF NOT EXISTS nearby_devices (
        device_id TEXT PRIMARY KEY,
        display_name TEXT NOT NULL,
        connection_type TEXT NOT NULL,
        rssi INTEGER NOT NULL,
        proximity_band TEXT NOT NULL,
        last_seen INTEGER NOT NULL,
        is_connected INTEGER DEFAULT 0,
        hop_count INTEGER DEFAULT 1,
        battery_level INTEGER
      )
    ''');

    // 3. Conversations
    await db.execute('''
      CREATE TABLE IF NOT EXISTS conversations (
        id TEXT PRIMARY KEY,
        conversation_id TEXT UNIQUE NOT NULL,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        last_message TEXT,
        unread_count INTEGER DEFAULT 0
      )
    ''');

    // 4. Messages (Offline-First local source of truth)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS messages (
        message_id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        sender_name TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        created_at INTEGER,
        status TEXT NOT NULL,
        hop_count INTEGER DEFAULT 0,
        ttl INTEGER DEFAULT 5,
        is_location_shared INTEGER DEFAULT 0,
        latitude REAL,
        longitude REAL,
        message_type TEXT NOT NULL DEFAULT 'TEXT',
        recipient_target TEXT,
        category TEXT,
        proximity TEXT,
        location_title TEXT,
        location_distance TEXT,
        attachment_path TEXT,
        attachment_name TEXT,
        attachment_mime_type TEXT,
        attachment_bytes INTEGER
      )
    ''');

    // 5. Message Relays (Audit trail)
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

    // 6. Emergency Reports
    await db.execute('''
      CREATE TABLE IF NOT EXISTS emergency_reports (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        description TEXT NOT NULL,
        status TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        location TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        people_affected INTEGER DEFAULT 1,
        severity TEXT DEFAULT 'HIGH'
      )
    ''');

    // 7. Shelter Resources
    await db.execute('''
      CREATE TABLE IF NOT EXISTS shelters (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        distance REAL NOT NULL,
        open_status TEXT NOT NULL,
        capacity INTEGER NOT NULL,
        max_capacity INTEGER NOT NULL,
        supplies TEXT NOT NULL,
        address TEXT,
        latitude REAL,
        longitude REAL
      )
    ''');

    // 8. Missing Persons
    await db.execute('''
      CREATE TABLE IF NOT EXISTS missing_persons (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        gender TEXT DEFAULT 'Unspecified',
        description TEXT NOT NULL,
        last_seen_location TEXT NOT NULL,
        lat REAL,
        lng REAL,
        last_seen_time INTEGER NOT NULL,
        reported_at INTEGER,
        photo_url TEXT,
        photo_path TEXT,
        status TEXT NOT NULL,
        contact_phone TEXT,
        reported_by TEXT DEFAULT 'Anonymous',
        sightings_json TEXT DEFAULT '[]'
      )
    ''');

    // 9. Attachment Chunks (Offline-First encrypted chunked image transfer)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS attachment_chunks (
        id TEXT PRIMARY KEY,
        message_id TEXT NOT NULL,
        attachment_id TEXT NOT NULL,
        chunk_index INTEGER NOT NULL,
        total_chunks INTEGER NOT NULL,
        chunk_path TEXT,
        checksum TEXT NOT NULL,
        status TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 10. Encrypted Mesh Packets (Store-and-forward relay queue & persistence)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS encrypted_mesh_packets (
        message_id TEXT PRIMARY KEY,
        sender_device_id TEXT NOT NULL,
        recipient_user_id TEXT,
        recipient_device_id TEXT,
        routing_header_json TEXT NOT NULL,
        encrypted_payload_json TEXT NOT NULL,
        status TEXT NOT NULL,
        hop_count INTEGER DEFAULT 0,
        ttl INTEGER DEFAULT 5,
        created_at INTEGER NOT NULL,
        expires_at INTEGER NOT NULL
      )
    ''');

    // 11. Peer Capabilities (Hardware/transports & routing scoring table)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS peer_capabilities (
        peer_id TEXT PRIMARY KEY,
        device_id TEXT NOT NULL,
        transports TEXT,
        battery_level INTEGER,
        is_relay INTEGER,
        is_internet_gateway INTEGER,
        last_seen INTEGER
      )
    ''');

    // 12. Delivery Receipts (Cryptographic ACK audit trail)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS delivery_receipts (
        receipt_id TEXT PRIMARY KEY,
        message_id TEXT NOT NULL,
        recipient_id TEXT NOT NULL,
        ack_timestamp INTEGER NOT NULL,
        signature TEXT
      )
    ''');

    // 13. Mesh Groups
    await db.execute('''
      CREATE TABLE IF NOT EXISTS groups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        creator_id TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        conversation_id TEXT NOT NULL,
        member_count INTEGER DEFAULT 1
      )
    ''');

    // 14. Group Members
    await db.execute('''
      CREATE TABLE IF NOT EXISTS group_members (
        id TEXT PRIMARY KEY,
        group_id TEXT NOT NULL,
        member_device_id TEXT NOT NULL,
        member_name TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'PENDING',
        joined_at INTEGER,
        invited_at INTEGER NOT NULL
      )
    ''');

    // 15. Group Invites
    await db.execute('''
      CREATE TABLE IF NOT EXISTS group_invites (
        id TEXT PRIMARY KEY,
        group_id TEXT NOT NULL,
        group_name TEXT NOT NULL,
        inviter_id TEXT NOT NULL,
        inviter_name TEXT NOT NULL,
        invitee_device_id TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'PENDING',
        sent_at INTEGER NOT NULL,
        responded_at INTEGER
      )
    ''');

    // 16. Offline Map Regions (Spec Sections 2 & 3)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS offline_map_regions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        min_lat REAL NOT NULL,
        max_lat REAL NOT NULL,
        min_lng REAL NOT NULL,
        max_lng REAL NOT NULL,
        min_zoom INTEGER NOT NULL,
        max_zoom INTEGER NOT NULL,
        total_tiles INTEGER NOT NULL,
        downloaded_tiles INTEGER NOT NULL,
        size_bytes INTEGER DEFAULT 0,
        status TEXT NOT NULL,
        downloaded_at INTEGER,
        file_path TEXT
      )
    ''');

    // 17. Location History (Spec Section 4)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS location_history (
        id TEXT PRIMARY KEY,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        horizontal_accuracy REAL NOT NULL,
        altitude REAL,
        speed REAL,
        bearing REAL,
        timestamp INTEGER NOT NULL,
        source TEXT NOT NULL,
        is_live INTEGER DEFAULT 1,
        is_stale INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _seedInitialData(Database db) async {
    // Seed default community broadcast conversation
    await db.insert('conversations', {
      'id': 'conv_community',
      'conversation_id': 'CONV_COMMUNITY',
      'type': 'BROADCAST',
      'title': 'Community Chat',
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
      'last_message': 'Offline mesh channel active.',
      'unread_count': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  void _seedInMemoryData() {
    _memoryTables['conversations']!.clear();
    _memoryTables['conversations']!.add({
      'id': 'conv_community',
      'conversation_id': 'CONV_COMMUNITY',
      'type': 'BROADCAST',
      'title': 'Community Chat',
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
      'last_message': 'Offline mesh channel active.',
      'unread_count': 0,
    });
  }

  // =========================================================================
  // Unified Database Operations (Dispatches to SQLite or In-Memory fallback)
  // =========================================================================

  Future<int> insert(
    String table,
    Map<String, dynamic> values, {
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    await ensureInitialized();
    if (!_isInMemory && _db != null) {
      try {
        return await _db!.insert(
          table,
          values,
          conflictAlgorithm: conflictAlgorithm,
        );
      } catch (e) {
        debugPrint(
          '[AppDatabase] Warning: insert into $table failed ($e). Attempting sanitized column insert.',
        );
        try {
          final info = await _db!.rawQuery('PRAGMA table_info($table)');
          final cols = info.map((r) => r['name'] as String).toSet();
          final sanitized = Map<String, dynamic>.from(values)
            ..removeWhere((k, _) => !cols.contains(k));
          return await _db!.insert(
            table,
            sanitized,
            conflictAlgorithm: conflictAlgorithm,
          );
        } catch (e2) {
          debugPrint('[AppDatabase] Secondary insert fallback failed: $e2');
        }
      }
    }

    final tableList = _memoryTables[table] ??= [];
    final pkKey = _getPrimaryKey(table);
    final pkVal = values[pkKey];

    if (pkVal != null) {
      final existingIndex = tableList.indexWhere((row) => row[pkKey] == pkVal);
      if (existingIndex != -1) {
        if (conflictAlgorithm == ConflictAlgorithm.ignore) {
          return 0;
        }
        // Replace
        tableList[existingIndex] = Map<String, dynamic>.from(values);
        return 1;
      }
    }

    tableList.add(Map<String, dynamic>.from(values));
    return 1;
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    await ensureInitialized();
    if (!_isInMemory && _db != null) {
      return await _db!.query(
        table,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );
    }

    final tableList = _memoryTables[table] ?? [];
    var results = List<Map<String, dynamic>>.from(
      tableList.map((e) => Map<String, dynamic>.from(e)),
    );

    // Apply where filter
    if (where != null && where.isNotEmpty) {
      results = results
          .where((row) => _matchesWhere(row, where, whereArgs))
          .toList();
    }

    // Apply sorting
    if (orderBy != null && orderBy.isNotEmpty) {
      final parts = orderBy.split(' ');
      final col = parts.first.trim();
      final isDesc =
          parts.length > 1 && parts[1].toUpperCase().contains('DESC');

      results.sort((a, b) {
        final valA = a[col];
        final valB = b[col];
        if (valA == null && valB == null) return 0;
        if (valA == null) return isDesc ? 1 : -1;
        if (valB == null) return isDesc ? -1 : 1;

        if (valA is Comparable && valB is Comparable) {
          final comp = valA.compareTo(valB);
          return isDesc ? -comp : comp;
        }
        return 0;
      });
    }

    // Apply offset and limit
    if (offset != null && offset > 0) {
      if (offset >= results.length) {
        results = [];
      } else {
        results = results.sublist(offset);
      }
    }

    if (limit != null && limit >= 0 && limit < results.length) {
      results = results.sublist(0, limit);
    }

    // Apply column selection
    if (columns != null && columns.isNotEmpty) {
      results = results.map((row) {
        final projected = <String, dynamic>{};
        for (final col in columns) {
          if (row.containsKey(col)) {
            projected[col] = row[col];
          }
        }
        return projected;
      }).toList();
    }

    return results;
  }

  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    await ensureInitialized();
    if (!_isInMemory && _db != null) {
      return await _db!.update(
        table,
        values,
        where: where,
        whereArgs: whereArgs,
        conflictAlgorithm: conflictAlgorithm,
      );
    }

    final tableList = _memoryTables[table] ?? [];
    int count = 0;
    for (int i = 0; i < tableList.length; i++) {
      if (where == null ||
          where.isEmpty ||
          _matchesWhere(tableList[i], where, whereArgs)) {
        tableList[i] = {...tableList[i], ...values};
        count++;
      }
    }
    return count;
  }

  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    await ensureInitialized();
    if (!_isInMemory && _db != null) {
      return await _db!.delete(table, where: where, whereArgs: whereArgs);
    }

    final tableList = _memoryTables[table] ?? [];
    if (where == null || where.isEmpty) {
      final len = tableList.length;
      tableList.clear();
      return len;
    }

    final initialCount = tableList.length;
    tableList.removeWhere((row) => _matchesWhere(row, where, whereArgs));
    return initialCount - tableList.length;
  }

  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    await ensureInitialized();
    if (!_isInMemory && _db != null) {
      return await _db!.rawQuery(sql, arguments);
    }
    // Fallback: check if rawQuery is a COUNT or simple SELECT
    return [];
  }

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
    for (final table in _memoryTables.keys) {
      _memoryTables[table]!.clear();
    }
  }

  String _getPrimaryKey(String table) {
    switch (table) {
      case 'user_profile':
        return 'id';
      case 'nearby_devices':
        return 'device_id';
      case 'conversations':
        return 'id';
      case 'messages':
        return 'message_id';
      case 'message_relays':
        return 'id';
      case 'emergency_reports':
        return 'id';
      case 'shelters':
        return 'id';
      case 'missing_persons':
        return 'id';
      case 'attachment_chunks':
        return 'id';
      case 'encrypted_mesh_packets':
        return 'message_id';
      case 'peer_capabilities':
        return 'peer_id';
      case 'delivery_receipts':
        return 'receipt_id';
      default:
        return 'id';
    }
  }

  bool _matchesWhere(
    Map<String, dynamic> row,
    String whereClause,
    List<Object?>? args,
  ) {
    final clean = whereClause.trim();
    if (clean.isEmpty) return true;

    bool evalCondition(String condition, Object? arg) {
      final match =
          RegExp(r'^(\w+)\s*(=|!=|<>)\s*\?$').firstMatch(condition.trim());
      if (match == null) return true;
      final col = match.group(1)!;
      final op = match.group(2)!;
      final eq = _compareEquals(row[col], arg);
      if (op == '!=' || op == '<>') {
        return !eq;
      }
      return eq;
    }

    // Handle compound with AND: "col1 = ? AND col2 != ?"
    final andParts = clean.split(RegExp(r'\s+AND\s+', caseSensitive: false));
    if (andParts.length > 1 && args != null && args.length == andParts.length) {
      for (int i = 0; i < andParts.length; i++) {
        if (!evalCondition(andParts[i], args[i])) {
          return false;
        }
      }
      return true;
    }

    // Handle OR: "col = ? OR col = ?"
    final orParts = clean.split(RegExp(r'\s+OR\s+', caseSensitive: false));
    if (orParts.length > 1 && args != null && args.length == orParts.length) {
      for (int i = 0; i < orParts.length; i++) {
        if (evalCondition(orParts[i], args[i])) {
          return true;
        }
      }
      return false;
    }

    // Handle single condition
    if (args != null && args.isNotEmpty) {
      return evalCondition(clean, args.first);
    }

    return true;
  }

  bool _compareEquals(dynamic a, dynamic b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.toString() == b.toString();
  }

  // =========================================================================
  // Entity Helper Methods for Providers & UI (Direct Database Operations)
  // =========================================================================

  /// Fetch messages for a specific conversation or all messages
  Future<List<ChatMessage>> getMessages({
    String? conversationId,
    int limit = 100,
    int offset = 0,
  }) async {
    final rows = await query(
      'messages',
      where: conversationId != null ? 'conversation_id = ?' : null,
      whereArgs: conversationId != null ? [conversationId] : null,
      orderBy: 'timestamp ASC',
      limit: limit,
      offset: offset,
    );
    return rows
        .map(
          (r) => ChatMessage.fromMap(
            r,
            myDeviceId: DeviceIdentityService.instance.deviceId,
          ),
        )
        .toList();
  }

  /// CRITICAL AXIOM: Save-Before-Send. Persist message to SQLite before radio broadcast.
  Future<void> saveMessage(ChatMessage message) async {
    await insert(
      'messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await update(
      'conversations',
      {
        'last_message': message.content,
        'updated_at': message.timestamp.millisecondsSinceEpoch,
      },
      where: 'conversation_id = ?',
      whereArgs: [message.conversationId],
    );
  }

  /// Update message lifecycle status
  Future<void> updateMessageStatus(String messageId, dynamic status) async {
    final statusStr = status is MessageStatus
        ? status.name.toUpperCase()
        : (status != null ? status.toString() : 'SAVED');
    await update(
      'messages',
      {'status': statusStr},
      where: 'message_id = ?',
      whereArgs: [messageId],
    );
  }

  /// Fetch all outbox messages pending broadcast/relay
  Future<List<ChatMessage>> getPendingOutboxMessages() async {
    final rows = await query(
      'messages',
      where: 'status = ? OR status = ? OR status = ?',
      whereArgs: ['SAVED', 'QUEUED', 'SENDING'],
      orderBy: 'timestamp ASC',
    );
    return rows
        .map(
          (r) => ChatMessage.fromMap(
            r,
            myDeviceId: DeviceIdentityService.instance.deviceId,
          ),
        )
        .toList();
  }

  /// Fetch all filed emergency reports
  Future<List<EmergencyReport>> getEmergencyReports() async {
    final rows = await query('emergency_reports', orderBy: 'timestamp DESC');
    return rows.map((r) => EmergencyReport.fromMap(r)).toList();
  }

  /// Save emergency incident report (Save-Before-Send)
  Future<void> saveEmergencyReport(EmergencyReport report) async {
    await insert(
      'emergency_reports',
      report.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Fetch nearby mesh devices
  Future<List<NearbyDevice>> getNearbyDevices() async {
    final rows = await query('nearby_devices', orderBy: 'last_seen DESC');
    return rows.map((r) => NearbyDevice.fromMap(r)).toList();
  }

  /// Upsert discovered nearby device (MeshDevice or NearbyDevice)
  Future<void> saveNearbyDevice(dynamic device) async {
    final Map<String, dynamic> map = device is Map<String, dynamic>
        ? Map<String, dynamic>.from(device)
        : Map<String, dynamic>.from((device as dynamic).toMap());
    if (map.containsKey('signal_strength') && !map.containsKey('rssi')) {
      map['rssi'] = map['signal_strength'];
    }
    // Remove extra non-table columns from MeshDevice.toMap()
    map.remove('id');
    map.remove('signal_strength');
    await insert(
      'nearby_devices',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Fetch active user profile (prioritizing registered session rows)
  Future<UserProfile?> getUserProfile() async {
    final registeredRows = await query(
      'user_profile',
      where: 'is_registered = ?',
      whereArgs: [1],
      orderBy: 'updated_at DESC',
      limit: 1,
    );
    if (registeredRows.isNotEmpty) {
      return UserProfile.fromMap(registeredRows.first);
    }

    final rows = await query(
      'user_profile',
      orderBy: 'updated_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserProfile.fromMap(rows.first);
  }

  /// Save or replace user profile
  Future<void> saveUserProfile(UserProfile profile) async {
    if (profile.isRegistered && profile.id != 'unregistered') {
      try {
        await delete(
          'user_profile',
          where: 'id = ?',
          whereArgs: ['unregistered'],
        );
      } catch (_) {}
    }
    await insert(
      'user_profile',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Clear user profile (factory reset)
  Future<void> clearUserProfile() async {
    await delete('user_profile');
  }

  /// Fetch all relief shelter resources
  Future<List<ShelterResource>> getShelters() async {
    final rows = await query('shelters', orderBy: 'distance ASC');
    return rows.map((r) => ShelterResource.fromMap(r)).toList();
  }

  /// Save relief shelter resource
  Future<void> saveShelter(ShelterResource shelter) async {
    await insert(
      'shelters',
      shelter.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Fetch missing person bulletins with optional status and search filters
  Future<List<MissingPerson>> getMissingPersons({String? status, String? search}) async {
    String? where;
    List<dynamic>? whereArgs;

    final conditions = <String>[];
    final args = <dynamic>[];

    if (status != null && status.toUpperCase() != 'ALL') {
      conditions.add('UPPER(status) = ?');
      args.add(status.toUpperCase());
    }

    if (search != null && search.trim().isNotEmpty) {
      conditions.add('(name LIKE ? OR last_seen_location LIKE ? OR description LIKE ?)');
      final term = '%${search.trim()}%';
      args.addAll([term, term, term]);
    }

    if (conditions.isNotEmpty) {
      where = conditions.join(' AND ');
      whereArgs = args;
    }

    final rows = await query(
      'missing_persons',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'reported_at DESC, last_seen_time DESC',
    );
    return rows.map((r) => MissingPerson.fromMap(r)).toList();
  }

  /// Get missing person by ID
  Future<MissingPerson?> getMissingPersonById(String id) async {
    final rows = await query(
      'missing_persons',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return MissingPerson.fromMap(rows.first);
  }

  /// Save or replace missing person bulletin
  Future<void> saveMissingPerson(MissingPerson person) async {
    await insert(
      'missing_persons',
      person.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update status of a missing person
  Future<void> updateMissingPersonStatus(String id, String status) async {
    await update(
      'missing_persons',
      {'status': status.toUpperCase()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Add a citizen sighting to a missing person record
  Future<void> addMissingPersonSighting(String personId, MissingPersonSighting sighting) async {
    final person = await getMissingPersonById(personId);
    if (person == null) return;

    final updatedSightings = List<MissingPersonSighting>.from(person.sightings)..add(sighting);
    final updated = person.copyWith(sightings: updatedSightings);
    await saveMissingPerson(updated);
  }

  // =========================================================================
  // Attachment Chunks Operations (Image Transfer with Resumption)
  // =========================================================================

  /// Save or replace an image attachment chunk record
  Future<void> saveAttachmentChunk(Map<String, dynamic> chunkData) async {
    await insert(
      'attachment_chunks',
      Map<String, dynamic>.from(chunkData),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Fetch all chunks for a message
  Future<List<Map<String, dynamic>>> getAttachmentChunksForMessage(
    String messageId,
  ) async {
    return await query(
      'attachment_chunks',
      where: 'message_id = ?',
      whereArgs: [messageId],
      orderBy: 'chunk_index ASC',
    );
  }

  /// Fetch unsent chunks for transmission resumption
  Future<List<Map<String, dynamic>>> getUnsentChunks(String messageId) async {
    return await query(
      'attachment_chunks',
      where: 'message_id = ? AND status != ?',
      whereArgs: [messageId, 'SENT'],
      orderBy: 'chunk_index ASC',
    );
  }

  /// Fetch received chunks for reassembly
  Future<List<Map<String, dynamic>>> getReceivedChunks(
    String attachmentId,
  ) async {
    return await query(
      'attachment_chunks',
      where: 'attachment_id = ? AND status = ?',
      whereArgs: [attachmentId, 'RECEIVED'],
      orderBy: 'chunk_index ASC',
    );
  }

  /// Update status of a specific chunk
  Future<void> updateChunkStatus(String chunkId, String status) async {
    await update(
      'attachment_chunks',
      {
        'status': status,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [chunkId],
    );
  }

  // =========================================================================
  // Encrypted Mesh Packets & Store-and-Forward Relay Queue
  // =========================================================================

  /// Save or replace an encrypted mesh packet in SQLite outbox/relay store
  Future<void> saveEncryptedMeshPacket(dynamic packet) async {
    final Map<String, dynamic> row = packet is EncryptedMeshPacket
        ? packet.toMap()
        : Map<String, dynamic>.from(packet as Map);
    await insert(
      'encrypted_mesh_packets',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Fetch a single encrypted packet by message ID
  Future<EncryptedMeshPacket?> getEncryptedMeshPacket(String messageId) async {
    final rows = await query(
      'encrypted_mesh_packets',
      where: 'message_id = ?',
      whereArgs: [messageId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return EncryptedMeshPacket.fromMap(rows.first);
  }

  /// Check whether an encrypted packet already exists in local SQLite
  Future<bool> hasEncryptedMeshPacket(String messageId) async {
    final rows = await query(
      'encrypted_mesh_packets',
      columns: const ['message_id'],
      where: 'message_id = ?',
      whereArgs: [messageId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Fetch all packets pending transmission or server sync (SAVED / QUEUED)
  Future<List<EncryptedMeshPacket>> getQueuedMeshPackets() async {
    final rows = await query(
      'encrypted_mesh_packets',
      where: "status = ? OR status = ?",
      whereArgs: const ['SAVED', 'QUEUED'],
      orderBy: 'created_at ASC',
    );
    return rows.map((r) => EncryptedMeshPacket.fromMap(r)).toList();
  }

  /// Fetch all encrypted mesh packets in local storage
  Future<List<EncryptedMeshPacket>> getAllEncryptedMeshPackets() async {
    final rows = await query(
      'encrypted_mesh_packets',
      orderBy: 'created_at ASC',
    );
    return rows.map((r) => EncryptedMeshPacket.fromMap(r)).toList();
  }

  /// Update lifecycle status of an encrypted mesh packet
  Future<void> updateMeshPacketStatus(
    String messageId,
    dynamic status, {
    int? hopCount,
    int? ttl,
  }) async {
    final statusStr = status is MeshDeliveryState
        ? status.toDbString()
        : status.toString();
    final values = <String, dynamic>{'status': statusStr};
    if (hopCount != null) values['hop_count'] = hopCount;
    if (ttl != null) values['ttl'] = ttl;
    await update(
      'encrypted_mesh_packets',
      values,
      where: 'message_id = ?',
      whereArgs: [messageId],
    );
  }

  // =========================================================================
  // Peer Capabilities & Dynamic Routing Scoring
  // =========================================================================

  /// Save or update peer device capabilities
  Future<void> savePeerCapability(dynamic peer) async {
    final Map<String, dynamic> row = peer is PeerCapability
        ? peer.toMap()
        : Map<String, dynamic>.from(peer as Map);
    await insert(
      'peer_capabilities',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Fetch all known peers sorted by last seen
  Future<List<PeerCapability>> getPeerCapabilities() async {
    final rows = await query(
      'peer_capabilities',
      orderBy: 'last_seen DESC',
    );
    return rows.map((r) => PeerCapability.fromMap(r)).toList();
  }

  /// Fetch a specific peer capability by peer ID or device ID
  Future<PeerCapability?> getPeerCapability(String peerOrDeviceId) async {
    final rows = await query(
      'peer_capabilities',
      where: 'peer_id = ? OR device_id = ?',
      whereArgs: [peerOrDeviceId, peerOrDeviceId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return PeerCapability.fromMap(rows.first);
  }

  // =========================================================================
  // Delivery Receipts & Cryptographic Acks
  // =========================================================================

  /// Persist a delivery receipt / ACK
  Future<void> saveDeliveryReceipt(dynamic receipt) async {
    final Map<String, dynamic> row = receipt is DeliveryReceipt
        ? receipt.toMap()
        : Map<String, dynamic>.from(receipt as Map);
    await insert(
      'delivery_receipts',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Fetch delivery receipts for a message
  Future<List<DeliveryReceipt>> getDeliveryReceipts(String messageId) async {
    final rows = await query(
      'delivery_receipts',
      where: 'message_id = ?',
      whereArgs: [messageId],
      orderBy: 'ack_timestamp DESC',
    );
    return rows.map((r) => DeliveryReceipt.fromMap(r)).toList();
  }

  // =========================================================================
  // Compatibility & Multi-Node Simulation Helpers
  // =========================================================================

  Future<bool> hasMessage(String messageId) async {
    final rows = await query(
      'messages',
      columns: const ['message_id'],
      where: 'message_id = ?',
      whereArgs: [messageId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> insertMessage(dynamic message) async {
    if (message is ChatMessage) {
      await saveMessage(message);
    } else if (message is MeshMessage) {
      await insert(
        'messages',
        {
          'message_id': message.messageId,
          'conversation_id': message.conversationId,
          'sender_id': message.senderDeviceId,
          'sender_name': message.senderName,
          'content': message.content,
          'timestamp': message.createdAt,
          'created_at': message.createdAt,
          'status': message.status,
          'hop_count': message.hopCount,
          'ttl': message.ttl,
          'message_type': 'TEXT',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else if (message is Map<String, dynamic>) {
      await insert(
        'messages',
        message,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> recordRelay({
    required String messageId,
    required String fromDeviceId,
    required String toDeviceId,
    required int hopNumber,
    String status = 'FORWARDED',
  }) async {
    await insert(
      'message_relays',
      {
        'id': 'relay_${DateTime.now().microsecondsSinceEpoch}_$hopNumber',
        'message_id': messageId,
        'from_device_id': fromDeviceId,
        'to_device_id': toDeviceId,
        'hop_number': hopNumber,
        'received_at': DateTime.now().millisecondsSinceEpoch,
        'forwarded_at': DateTime.now().millisecondsSinceEpoch,
        'status': status,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getRelays() async {
    return await query('message_relays', orderBy: 'received_at ASC');
  }

  // =========================================================================
  // Offline Map Regions (Spec Sections 2 & 3)
  // =========================================================================

  /// Save or replace an offline map sector / region
  Future<void> saveOfflineMapRegion(OfflineMapRegion region) async {
    await insert(
      'offline_map_regions',
      region.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieve all recorded offline map regions
  Future<List<OfflineMapRegion>> getOfflineMapRegions() async {
    final rows = await query(
      'offline_map_regions',
      orderBy: 'downloaded_at DESC, name ASC',
    );
    return rows.map((r) => OfflineMapRegion.fromMap(r)).toList();
  }

  /// Retrieve a specific offline map region by ID
  Future<OfflineMapRegion?> getOfflineMapRegion(String id) async {
    final rows = await query(
      'offline_map_regions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return OfflineMapRegion.fromMap(rows.first);
  }

  /// Update download status, tile progress, and storage metrics
  Future<void> updateOfflineMapRegionStatus(
    String id,
    String status, {
    int? downloadedTiles,
    int? sizeBytes,
    int? downloadedAt,
    String? filePath,
  }) async {
    final values = <String, dynamic>{
      'status': status,
    };
    if (downloadedTiles != null) values['downloaded_tiles'] = downloadedTiles;
    if (sizeBytes != null) values['size_bytes'] = sizeBytes;
    if (downloadedAt != null) values['downloaded_at'] = downloadedAt;
    if (filePath != null) values['file_path'] = filePath;

    await update(
      'offline_map_regions',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete an offline map region from database
  Future<int> deleteOfflineMapRegion(String id) async {
    return await delete(
      'offline_map_regions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

