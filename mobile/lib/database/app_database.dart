import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/chat_message.dart';
import '../models/emergency_report.dart';
import '../models/missing_person.dart';
import '../models/nearby_device.dart';
import '../models/shelter_resource.dart';
import '../models/user_profile.dart';

/// Database management for RakshaNet with:
/// 1. Native SQLite via sqflite on supported platforms.
/// 2. Resilient in-memory fallback if native sqflite driver is unavailable.
/// 3. Seed data for offline disaster shelters and global emergency channel.
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
  };

  AppDatabase._internal();

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
        version: 2,
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
      debugPrint('[AppDatabase] Native SQLite driver unavailable ($e). Switching to in-memory fallback.');
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
    ];
    for (final col in cols) {
      try {
        await db.execute('ALTER TABLE user_profile ADD COLUMN $col');
      } catch (_) {}
    }
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
        status TEXT NOT NULL,
        hop_count INTEGER DEFAULT 0,
        ttl INTEGER DEFAULT 5,
        is_location_shared INTEGER DEFAULT 0,
        latitude REAL,
        longitude REAL
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
        description TEXT NOT NULL,
        last_seen_location TEXT NOT NULL,
        last_seen_time INTEGER NOT NULL,
        photo_path TEXT,
        status TEXT NOT NULL,
        contact_phone TEXT
      )
    ''');
  }

  Future<void> _seedInitialData(Database db) async {
    // Seed default global emergency broadcast conversation
    await db.insert('conversations', {
      'id': 'conv_broadcast_sos',
      'conversation_id': 'global_emergency',
      'type': 'BROADCAST',
      'title': 'Emergency Broadcast Channel',
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
      'last_message': 'Emergency mesh channel initialized. Transmitting on BLE 5.x.',
      'unread_count': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Seed default disaster shelters
    final defaultShelters = _getDefaultShelters();
    for (final shelter in defaultShelters) {
      await db.insert('shelters', shelter.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  void _seedInMemoryData() {
    _memoryTables['conversations']!.clear();
    _memoryTables['conversations']!.add({
      'id': 'conv_broadcast_sos',
      'conversation_id': 'global_emergency',
      'type': 'BROADCAST',
      'title': 'Emergency Broadcast Channel',
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
      'last_message': 'Emergency mesh channel initialized. Transmitting on BLE 5.x.',
      'unread_count': 0,
    });

    _memoryTables['shelters']!.clear();
    for (final shelter in _getDefaultShelters()) {
      _memoryTables['shelters']!.add(shelter.toMap());
    }
  }

  List<ShelterResource> _getDefaultShelters() {
    return [
      const ShelterResource(
        id: 'shelter_01',
        name: 'Community Relief Center - Sector 4',
        distance: 1.2,
        openStatus: 'OPEN',
        capacity: 140,
        maxCapacity: 300,
        supplies: ['Food', 'Clean Water', 'Medical Kits', 'Generators', 'Blankets'],
        address: 'Sector 4 Community Grounds, Gate 2',
        latitude: 28.6139,
        longitude: 77.2090,
      ),
      const ShelterResource(
        id: 'shelter_02',
        name: 'Red Cross Mobile Medical Station',
        distance: 2.8,
        openStatus: 'OPEN',
        capacity: 45,
        maxCapacity: 60,
        supplies: ['First Aid', 'Oxygen Cylinders', 'IV Fluids', 'Doctor on duty'],
        address: 'District Stadium Parking Complex',
        latitude: 28.6250,
        longitude: 77.2180,
      ),
      const ShelterResource(
        id: 'shelter_03',
        name: 'Highland Evacuation Camp',
        distance: 4.5,
        openStatus: 'OPEN',
        capacity: 220,
        maxCapacity: 500,
        supplies: ['Tents', 'Dry Rations', 'Water Purification', 'Satellite Phone'],
        address: 'Hilltop Secondary School Campus',
        latitude: 28.6380,
        longitude: 77.1950,
      ),
    ];
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
        return await _db!.insert(table, values, conflictAlgorithm: conflictAlgorithm);
      } catch (e) {
        debugPrint('[AppDatabase] Warning: insert into $table failed ($e). Attempting sanitized column insert.');
        try {
          final info = await _db!.rawQuery('PRAGMA table_info($table)');
          final cols = info.map((r) => r['name'] as String).toSet();
          final sanitized = Map<String, dynamic>.from(values)
            ..removeWhere((k, _) => !cols.contains(k));
          return await _db!.insert(table, sanitized, conflictAlgorithm: conflictAlgorithm);
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
    var results = List<Map<String, dynamic>>.from(tableList.map((e) => Map<String, dynamic>.from(e)));

    // Apply where filter
    if (where != null && where.isNotEmpty) {
      results = results.where((row) => _matchesWhere(row, where, whereArgs)).toList();
    }

    // Apply sorting
    if (orderBy != null && orderBy.isNotEmpty) {
      final parts = orderBy.split(' ');
      final col = parts.first.trim();
      final isDesc = parts.length > 1 && parts[1].toUpperCase().contains('DESC');

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
      if (where == null || where.isEmpty || _matchesWhere(tableList[i], where, whereArgs)) {
        tableList[i] = {
          ...tableList[i],
          ...values,
        };
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

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<Object?>? arguments]) async {
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
      default:
        return 'id';
    }
  }

  bool _matchesWhere(Map<String, dynamic> row, String whereClause, List<Object?>? args) {
    final clean = whereClause.trim();
    if (clean.isEmpty) return true;

    // Handle single column equality: "column = ?"
    final eqMatch = RegExp(r'^(\w+)\s*=\s*\?$').firstMatch(clean);
    if (eqMatch != null && args != null && args.isNotEmpty) {
      final col = eqMatch.group(1)!;
      final target = args.first;
      return _compareEquals(row[col], target);
    }

    // Handle compound with AND: "col1 = ? AND col2 = ?"
    final andParts = clean.split(RegExp(r'\s+AND\s+', caseSensitive: false));
    if (andParts.length > 1 && args != null && args.length == andParts.length) {
      for (int i = 0; i < andParts.length; i++) {
        final subPart = andParts[i].trim();
        final subMatch = RegExp(r'^(\w+)\s*=\s*\?$').firstMatch(subPart);
        if (subMatch != null) {
          final col = subMatch.group(1)!;
          if (!_compareEquals(row[col], args[i])) {
            return false;
          }
        }
      }
      return true;
    }

    // Handle OR: "col = ? OR col = ?"
    final orParts = clean.split(RegExp(r'\s+OR\s+', caseSensitive: false));
    if (orParts.length > 1 && args != null && args.length == orParts.length) {
      for (int i = 0; i < orParts.length; i++) {
        final subPart = orParts[i].trim();
        final subMatch = RegExp(r'^(\w+)\s*=\s*\?$').firstMatch(subPart);
        if (subMatch != null) {
          final col = subMatch.group(1)!;
          if (_compareEquals(row[col], args[i])) {
            return true;
          }
        }
      }
      return false;
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
    return rows.map((r) => ChatMessage.fromMap(r)).toList();
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
    return rows.map((r) => ChatMessage.fromMap(r)).toList();
  }

  /// Fetch all filed emergency reports
  Future<List<EmergencyReport>> getEmergencyReports() async {
    final rows = await query(
      'emergency_reports',
      orderBy: 'timestamp DESC',
    );
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
    final rows = await query(
      'nearby_devices',
      orderBy: 'last_seen DESC',
    );
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

  /// Fetch active user profile
  Future<UserProfile?> getUserProfile() async {
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
    final rows = await query(
      'shelters',
      orderBy: 'distance ASC',
    );
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

  /// Fetch missing person bulletins
  Future<List<MissingPerson>> getMissingPersons() async {
    final rows = await query(
      'missing_persons',
      orderBy: 'last_seen_time DESC',
    );
    return rows.map((r) => MissingPerson.fromMap(r)).toList();
  }

  /// Save missing person bulletin
  Future<void> saveMissingPerson(MissingPerson person) async {
    await insert(
      'missing_persons',
      person.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
