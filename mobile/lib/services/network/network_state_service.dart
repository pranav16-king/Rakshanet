import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../database/app_database.dart';
import '../device_identity_service.dart';
import '../transport/transport_manager.dart';

/// The 6 distinct physical and operational transport states recognized by RakshaNet.
enum TransportState {
  /// Verified HTTP ping to gateway or 8.8.8.8 succeeded. Full cloud/gateway access.
  internetAvailable,

  /// Connected to a Wi-Fi SSID / local router, but gateway/internet is unreachable.
  wifiNoInternet,

  /// Connected to cellular LTE/5G network.
  cellularData,

  /// Peer-to-peer Wi-Fi Direct or Nearby Connections active for device-to-device mesh.
  p2pTransportAvailable,

  /// Bluetooth Low Energy active only (no IP or Wi-Fi transport active).
  bluetoothOnly,

  /// All radios offline or device in airplane mode.
  noTransport;

  String get label => name;

  static TransportState fromString(String val) {
    return TransportState.values.firstWhere(
      (e) => e.name.toLowerCase() == val.trim().toLowerCase(),
      orElse: () => TransportState.noTransport,
    );
  }
}

/// Result summary of an auto-recovery synchronization cycle.
class SyncResult {
  final bool success;
  final int syncedMeshPackets;
  final int syncedSosEvents;
  final int syncedLocationPoints;
  final int totalSynced;
  final String? errorMessage;
  final DateTime timestamp;

  const SyncResult({
    required this.success,
    this.syncedMeshPackets = 0,
    this.syncedSosEvents = 0,
    this.syncedLocationPoints = 0,
    this.totalSynced = 0,
    this.errorMessage,
    required this.timestamp,
  });

  @override
  String toString() =>
      'SyncResult(success: $success, totalSynced: $totalSynced '
      '[mesh: $syncedMeshPackets, sos: $syncedSosEvents, loc: $syncedLocationPoints], '
      'ts: ${timestamp.toIso8601String()})';
}

/// Network State Monitor & Auto-Recovery Sync Service (SignalRescue AI / RakshaNet).
///
/// Responsibilities:
/// 1. Tracks 6 distinct radio transport states:
///    - `internetAvailable`: verified HTTP ping to gateway / 8.8.8.8
///    - `wifiNoInternet`: Wi-Fi SSID connected but Internet ping unreachable
///    - `cellularData`: LTE/5G cellular IP active
///    - `p2pTransportAvailable`: Wi-Fi Direct / Nearby active
///    - `bluetoothOnly`: BLE active without IP transport
///    - `noTransport`: all radios offline / airplane mode
///
/// 2. Auto-Recovery Sync Engine:
///    - Detects transition: `internetAvailable` becomes true
///    - Queries unsynced SQLite records (`encrypted_mesh_packets` where status != 'SYNCED',
///      `sos_events`, `location_history`)
///    - Posts idempotently to FastAPI gateway (`/api/v1/packets`) with unique `messageId`
///    - Exponential backoff with jitter (initial 1s, max 30s, jitter ±20%)
///    - Marks records as `syncedToServer` on 200 OK
///    - Emits `lastSyncTimestamp`
class NetworkStateService extends ChangeNotifier {
  static NetworkStateService? _instance;
  static NetworkStateService get instance => _instance ??= NetworkStateService();

  final http.Client _httpClient;
  final AppDatabase _db;
  final math.Random _random;
  final bool testModeNoDelays;

  TransportState _currentState = TransportState.noTransport;
  DateTime? _lastSyncTimestamp;
  bool _isSyncing = false;
  Timer? _monitorTimer;

  // Stream controllers
  final StreamController<TransportState> _stateController =
      StreamController<TransportState>.broadcast();
  final StreamController<DateTime> _lastSyncTimestampController =
      StreamController<DateTime>.broadcast();

  // Test override hook
  TransportState? _mockState;

  NetworkStateService({
    http.Client? httpClient,
    AppDatabase? database,
    math.Random? random,
    this.testModeNoDelays = false,
  })  : _httpClient = httpClient ?? http.Client(),
        _db = database ?? AppDatabase.instance,
        _random = random ?? math.Random() {
    _ensureTablesExist();
  }

  // ---------------------------------------------------------------------------
  // Getters & Streams
  // ---------------------------------------------------------------------------

  TransportState get currentState => _mockState ?? _currentState;

  bool get internetAvailable => currentState == TransportState.internetAvailable;
  bool get wifiNoInternet => currentState == TransportState.wifiNoInternet;
  bool get cellularData => currentState == TransportState.cellularData;
  bool get p2pTransportAvailable =>
      currentState == TransportState.p2pTransportAvailable;
  bool get bluetoothOnly => currentState == TransportState.bluetoothOnly;
  bool get noTransport => currentState == TransportState.noTransport;

  // Convenience aliases
  bool get isInternetAvailable => internetAvailable;
  bool get isWifiNoInternet => wifiNoInternet;
  bool get isCellularData => cellularData;
  bool get isP2pTransportAvailable => p2pTransportAvailable;
  bool get isBluetoothOnly => bluetoothOnly;
  bool get isNoTransport => noTransport;

  DateTime? get lastSyncTimestamp => _lastSyncTimestamp;
  bool get isSyncing => _isSyncing;

  Stream<TransportState> get onTransportStateChanged => _stateController.stream;
  Stream<DateTime> get onLastSyncTimestamp =>
      _lastSyncTimestampController.stream;

  // ---------------------------------------------------------------------------
  // Lifecycle & Periodic Monitoring
  // ---------------------------------------------------------------------------

  /// Starts periodic state polling and auto-recovery monitoring.
  void startMonitoring({Duration interval = const Duration(seconds: 15)}) {
    _monitorTimer?.cancel();
    evaluateTransportState();
    _monitorTimer = Timer.periodic(interval, (_) => evaluateTransportState());
  }

  /// Stops periodic state polling.
  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }

  @override
  void dispose() {
    stopMonitoring();
    _stateController.close();
    _lastSyncTimestampController.close();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Transport State Evaluation Logic
  // ---------------------------------------------------------------------------

  /// Evaluates current radio interfaces and performs verified HTTP ping to determine state.
  Future<TransportState> evaluateTransportState({
    String gatewayHealthUrl = AppConfig.healthUrl,
  }) async {
    if (_mockState != null) {
      _applyStateTransition(_mockState!);
      return _mockState!;
    }

    final previousState = _currentState;
    TransportState detectedState = TransportState.noTransport;

    // Step 1: Verified HTTP ping to gateway / 8.8.8.8
    final hasInternet = await verifyInternetHttpPing(gatewayHealthUrl: gatewayHealthUrl);

    if (hasInternet) {
      detectedState = TransportState.internetAvailable;
    } else {
      // Step 2: Inspect hardware interfaces
      final interfaces = await _safeGetNetworkInterfaces();
      final hasWifi = interfaces.any((i) => _isWifiInterface(i));
      final hasCellular = interfaces.any((i) => _isCellularInterface(i));

      if (hasWifi) {
        // Connected to local Wi-Fi router but gateway/internet unreachable
        detectedState = TransportState.wifiNoInternet;
      } else if (hasCellular) {
        // Connected to mobile data network
        detectedState = TransportState.cellularData;
      } else {
        // Step 3: Check device-to-device mesh radios
        final tm = TransportManager.instance;
        final hasP2p = tm.wifiDirectTransport.isAvailable || tm.onlinePeers.isNotEmpty;
        final hasBle = tm.bleTransport.isAvailable;

        if (hasP2p) {
          detectedState = TransportState.p2pTransportAvailable;
        } else if (hasBle) {
          detectedState = TransportState.bluetoothOnly;
        } else {
          detectedState = TransportState.noTransport;
        }
      }
    }

    _applyStateTransition(detectedState, previousState: previousState);
    return detectedState;
  }

  /// Performs verified HTTP ping to FastAPI gateway or 8.8.8.8.
  Future<bool> verifyInternetHttpPing({
    String gatewayHealthUrl = AppConfig.healthUrl,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    // 1. Primary check: FastAPI gateway health endpoint
    try {
      final res = await _httpClient
          .get(Uri.parse(gatewayHealthUrl))
          .timeout(timeout);
      if (res.statusCode >= 200 && res.statusCode < 400) {
        return true;
      }
    } catch (_) {
      // Fallback to secondary internet probe
    }

    // 2. Secondary check: HTTP / Socket probe to 8.8.8.8 / Google DNS
    try {
      final res = await _httpClient
          .get(Uri.parse('http://8.8.8.8'))
          .timeout(const Duration(seconds: 2));
      if (res.statusCode >= 200 && res.statusCode < 400) {
        return true;
      }
    } catch (_) {}

    try {
      final socket = await Socket.connect(
        '8.8.8.8',
        53,
        timeout: const Duration(seconds: 2),
      );
      await socket.close();
      return true;
    } catch (_) {}

    return false;
  }

  void _applyStateTransition(
    TransportState newState, {
    TransportState? previousState,
  }) {
    final oldState = previousState ?? _currentState;
    _currentState = newState;

    if (oldState != newState) {
      _stateController.add(newState);
      notifyListeners();

      // AUTO-RECOVERY TRIGGER:
      // When internetAvailable transitions to true, launch auto-recovery sync engine
      if (oldState != TransportState.internetAvailable &&
          newState == TransportState.internetAvailable) {
        debugPrint(
          '[NetworkStateService] Internet connectivity established ($oldState -> $newState). Triggering auto-recovery sync...',
        );
        triggerAutoRecoverySync();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Auto-Recovery Sync Engine (Spec Section 10)
  // ---------------------------------------------------------------------------

  /// Executes idempotent auto-recovery synchronization:
  /// 1. Queries unsynced SQLite records (`encrypted_mesh_packets` where status != 'SYNCED',
  ///    `sos_events`, `location_history`).
  /// 2. Posts to FastAPI gateway `/api/v1/packets` with unique idempotency keys (`messageId`).
  /// 3. Retries using exponential backoff with jitter (initial 1s, max 30s, jitter ±20%).
  /// 4. On 200 OK, marks records as `syncedToServer`.
  /// 5. Emits `lastSyncTimestamp`.
  Future<SyncResult> triggerAutoRecoverySync({
    String gatewayPacketsUrl = AppConfig.packetsUrl,
    int maxRetries = 5,
  }) async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        errorMessage: 'Sync cycle already in progress',
        timestamp: DateTime.now(),
      );
    }

    _isSyncing = true;
    notifyListeners();

    try {
      await _ensureTablesExist();

      // 1. Query unsynced records
      final unsyncedPackets = await _queryUnsyncedMeshPackets();
      final unsyncedSos = await _queryUnsyncedSosEvents();
      final unsyncedLocations = await _queryUnsyncedLocations();

      final totalRecords =
          unsyncedPackets.length + unsyncedSos.length + unsyncedLocations.length;

      if (totalRecords == 0) {
        debugPrint('[NetworkStateService] Auto-recovery: No unsynced records pending.');
        _isSyncing = false;
        notifyListeners();
        return SyncResult(
          success: true,
          totalSynced: 0,
          timestamp: DateTime.now(),
        );
      }

      debugPrint(
        '[NetworkStateService] Auto-recovery sync starting for $totalRecords records '
        '(${unsyncedPackets.length} mesh packets, ${unsyncedSos.length} SOS, ${unsyncedLocations.length} locations)',
      );

      // 2. Prepare payload and track IDs
      final myDeviceId = DeviceIdentityService.instance.deviceId;
      final payloadList = <Map<String, dynamic>>[];
      final packetIds = <String>[];
      final sosIds = <String>[];
      final locationIds = <String>[];

      for (final p in unsyncedPackets) {
        final id = (p['message_id'] ?? p['messageId'] ?? '').toString();
        if (id.isEmpty) continue;
        packetIds.add(id);
        payloadList.add({
          'ver': 1,
          'msg_id': id,
          'message_id': id,
          'sender_id': p['sender_device_id'] ?? myDeviceId,
          'conv_id': 'CONV_COMMUNITY',
          'ts': p['created_at'] ?? DateTime.now().millisecondsSinceEpoch,
          'ttl': p['ttl'] ?? 5,
          'hops': p['hop_count'] ?? 0,
          'type': 'ENCRYPTED_MESH',
          'payload': p['encrypted_payload_json'] ?? p['routing_header_json'] ?? '',
          'meta': {'synced_via': 'auto_recovery'},
        });
      }

      for (final s in unsyncedSos) {
        final id = (s['message_id'] ?? s['id'] ?? '').toString();
        if (id.isEmpty) continue;
        sosIds.add(id);
        payloadList.add({
          'ver': 1,
          'msg_id': id,
          'message_id': id,
          'sender_id': s['sender_device_id'] ?? myDeviceId,
          'sender_name': s['sender_name'] ?? 'Survivor',
          'conv_id': 'CONV_COMMUNITY',
          'ts': s['created_at'] ?? DateTime.now().millisecondsSinceEpoch,
          'ttl': 5,
          'hops': 0,
          'type': 'SOS',
          'payload': 'Emergency SOS Alert',
          'location': {
            'lat': s['latitude'],
            'lng': s['longitude'],
            'fix_type': 'LIVE_GPS',
          },
          'meta': {
            'urgency': s['urgency'] ?? 'CRITICAL',
            'synced_via': 'auto_recovery',
          },
        });
      }

      for (final l in unsyncedLocations) {
        final id = (l['message_id'] ?? l['id'] ?? '').toString();
        if (id.isEmpty) continue;
        locationIds.add(id);
        payloadList.add({
          'ver': 1,
          'msg_id': id,
          'message_id': id,
          'sender_id': l['device_id'] ?? myDeviceId,
          'conv_id': 'CONV_COMMUNITY',
          'ts': l['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
          'ttl': 5,
          'hops': 0,
          'type': 'LOCATION_HISTORY',
          'payload': 'Location breadcrumb trace',
          'location': {
            'lat': l['latitude'],
            'lng': l['longitude'],
            'accuracy': l['horizontal_accuracy'],
            'fix_type': l['source'] ?? 'LIVE_GPS',
          },
          'meta': {'synced_via': 'auto_recovery'},
        });
      }

      final batchBody = jsonEncode({
        'device_id': myDeviceId,
        'sync_timestamp': DateTime.now().millisecondsSinceEpoch,
        'packets': payloadList,
      });

      // 3. Post with exponential backoff & jitter
      bool uploadSuccess = false;
      String? lastError;

      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          final idempotencyKey = payloadList.isNotEmpty
              ? payloadList.first['msg_id']
              : 'IDEMP-${DateTime.now().millisecondsSinceEpoch}';

          final response = await _httpClient
              .post(
                Uri.parse(gatewayPacketsUrl),
                headers: {
                  'Content-Type': 'application/json',
                  'X-Idempotency-Key': idempotencyKey,
                },
                body: batchBody,
              )
              .timeout(const Duration(seconds: 10));

          if (response.statusCode >= 200 && response.statusCode < 300) {
            uploadSuccess = true;
            break;
          } else {
            lastError =
                'Gateway rejected upload with HTTP ${response.statusCode}: ${response.body}';
          }
        } catch (e) {
          lastError = e.toString();
        }

        if (attempt < maxRetries) {
          final delay = calculateBackoffDelay(attempt);
          debugPrint(
            '[NetworkStateService] Sync attempt $attempt failed ($lastError). Retrying in ${delay.inMilliseconds}ms...',
          );
          if (!testModeNoDelays) {
            await Future.delayed(delay);
          }
        }
      }

      if (!uploadSuccess) {
        _isSyncing = false;
        notifyListeners();
        return SyncResult(
          success: false,
          errorMessage: lastError ?? 'Unknown sync failure',
          timestamp: DateTime.now(),
        );
      }

      // 4. Mark records as syncedToServer in SQLite
      await _markRecordsSynced(packetIds, sosIds, locationIds);

      // 5. Emit lastSyncTimestamp
      _lastSyncTimestamp = DateTime.now();
      _lastSyncTimestampController.add(_lastSyncTimestamp!);
      _isSyncing = false;
      notifyListeners();

      final result = SyncResult(
        success: true,
        syncedMeshPackets: packetIds.length,
        syncedSosEvents: sosIds.length,
        syncedLocationPoints: locationIds.length,
        totalSynced: totalRecords,
        timestamp: _lastSyncTimestamp!,
      );

      debugPrint(
        '[NetworkStateService] Auto-recovery sync completed successfully: $result',
      );
      return result;
    } catch (e, stack) {
      debugPrint('[NetworkStateService] Auto-recovery fatal exception: $e\n$stack');
      _isSyncing = false;
      notifyListeners();
      return SyncResult(
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// Calculates exponential backoff delay with jitter (initial 1s, max 30s, jitter ±20%).
  Duration calculateBackoffDelay(
    int attempt, {
    Duration initial = const Duration(seconds: 1),
    Duration maxBackoff = const Duration(seconds: 30),
    double jitterFactor = 0.20,
  }) {
    // 2^(attempt - 1) * initial
    final expMs =
        initial.inMilliseconds * math.pow(2.0, math.max(0, attempt - 1));
    final clampedMs =
        math.min(expMs.toDouble(), maxBackoff.inMilliseconds.toDouble());
    // Jitter ±20% (multiplier between 0.8 and 1.2)
    final jitterMultiplier =
        1.0 + (_random.nextDouble() * 2.0 - 1.0) * jitterFactor;
    final delayMs = (clampedMs * jitterMultiplier).round();
    return Duration(milliseconds: math.max(50, delayMs));
  }

  // ---------------------------------------------------------------------------
  // Internal SQLite Query & Sync Helpers
  // ---------------------------------------------------------------------------

  Future<void> _ensureTablesExist() async {
    try {
      final db = await _db.database;
      if (db != null && !_db.isInMemoryFallback) {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS sos_events (
            id TEXT PRIMARY KEY,
            message_id TEXT NOT NULL,
            sender_device_id TEXT NOT NULL,
            sender_name TEXT,
            latitude REAL,
            longitude REAL,
            urgency TEXT DEFAULT 'CRITICAL',
            status TEXT DEFAULT 'PENDING',
            synced_to_server INTEGER DEFAULT 0,
            created_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS location_history (
            id TEXT PRIMARY KEY,
            message_id TEXT,
            device_id TEXT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            horizontal_accuracy REAL,
            altitude REAL,
            speed REAL,
            bearing REAL,
            timestamp INTEGER NOT NULL,
            source TEXT,
            status TEXT DEFAULT 'PENDING',
            synced_to_server INTEGER DEFAULT 0,
            is_live INTEGER DEFAULT 1,
            is_stale INTEGER DEFAULT 0
          )
        ''');
      }
    } catch (e) {
      debugPrint('[NetworkStateService] Notice on table creation: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _queryUnsyncedMeshPackets() async {
    try {
      final rows = await _db.query(
        'encrypted_mesh_packets',
        where: "status != ? AND status != ?",
        whereArgs: const ['SYNCED', 'syncedToServer'],
      );
      return rows;
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _queryUnsyncedSosEvents() async {
    try {
      final rows = await _db.query(
        'sos_events',
        where: "status != ? AND status != ?",
        whereArgs: const ['SYNCED', 'syncedToServer'],
      );
      return rows;
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _queryUnsyncedLocations() async {
    try {
      final rows = await _db.query(
        'location_history',
        where: "status != ? AND status != ?",
        whereArgs: const ['SYNCED', 'syncedToServer'],
      );
      return rows;
    } catch (_) {
      return [];
    }
  }

  Future<void> _markRecordsSynced(
    List<String> packetIds,
    List<String> sosIds,
    List<String> locationIds,
  ) async {
    for (final id in packetIds) {
      await _db.update(
        'encrypted_mesh_packets',
        {'status': 'syncedToServer'},
        where: 'message_id = ?',
        whereArgs: [id],
      );
      await _db.update(
        'messages',
        {'status': 'SYNCED'},
        where: 'message_id = ?',
        whereArgs: [id],
      );
    }

    for (final id in sosIds) {
      await _db.update(
        'sos_events',
        {'status': 'syncedToServer', 'synced_to_server': 1},
        where: 'message_id = ? OR id = ?',
        whereArgs: [id, id],
      );
    }

    for (final id in locationIds) {
      await _db.update(
        'location_history',
        {'status': 'syncedToServer', 'synced_to_server': 1},
        where: 'message_id = ? OR id = ?',
        whereArgs: [id, id],
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Interface Classification Helpers
  // ---------------------------------------------------------------------------

  Future<List<NetworkInterface>> _safeGetNetworkInterfaces() async {
    try {
      return await NetworkInterface.list();
    } catch (_) {
      return [];
    }
  }

  bool _isWifiInterface(NetworkInterface iface) {
    final name = iface.name.toLowerCase();
    return name.contains('wlan') ||
        name.contains('wifi') ||
        name.contains('wi-fi') ||
        name.contains('en0') ||
        name.contains('eth');
  }

  bool _isCellularInterface(NetworkInterface iface) {
    final name = iface.name.toLowerCase();
    return name.contains('rmnet') ||
        name.contains('pdp') ||
        name.contains('ccmni') ||
        name.contains('cellular') ||
        name.contains('mobile') ||
        name.contains('wwan');
  }

  // ---------------------------------------------------------------------------
  // Testing Hooks
  // ---------------------------------------------------------------------------

  @visibleForTesting
  void setTransportStateForTesting(TransportState state) {
    final previous = _currentState;
    _mockState = state;
    _applyStateTransition(state, previousState: previous);
  }

  @visibleForTesting
  void resetForTesting() {
    _mockState = null;
    _currentState = TransportState.noTransport;
    _lastSyncTimestamp = null;
    _isSyncing = false;
  }
}
