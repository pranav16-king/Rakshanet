import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import '../../config/app_config.dart';
import '../../database/app_database.dart';
import '../../models/chat_message.dart';
import '../../models/delivery_state.dart';
import '../../models/emergency_report.dart';
import '../../models/encrypted_mesh_packet.dart';
import '../../models/missing_person.dart';
import '../../models/user_profile.dart';
import '../chat_service.dart';
import '../database_service.dart';
import '../device_identity_service.dart';
import '../group_service.dart';
import '../location/location_service.dart';
import '../mesh_engine.dart';
import '../transport/transport_manager.dart';
import '../user_auth_service.dart';

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
  final int syncedEmergencyReports;
  final int syncedLocationPoints;
  final int syncedMissingPersons;
  final int totalSynced;
  final String? errorMessage;
  final DateTime timestamp;

  const SyncResult({
    required this.success,
    this.syncedMeshPackets = 0,
    this.syncedSosEvents = 0,
    this.syncedEmergencyReports = 0,
    this.syncedLocationPoints = 0,
    this.syncedMissingPersons = 0,
    this.totalSynced = 0,
    this.errorMessage,
    required this.timestamp,
  });

  @override
  String toString() =>
      'SyncResult(success: $success, totalSynced: $totalSynced '
      '[mesh: $syncedMeshPackets, sos: $syncedSosEvents, reports: $syncedEmergencyReports, '
      'loc: $syncedLocationPoints, missing: $syncedMissingPersons], '
      'ts: ${timestamp.toIso8601String()})';
}

/// Network State Monitor & Auto-Recovery Sync Service (RakshaNet).
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
  static NetworkStateService get instance =>
      _instance ??= NetworkStateService();

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
  }) : _httpClient = httpClient ?? http.Client(),
       _db = database ?? AppDatabase.instance,
       _random = random ?? math.Random() {
    _ensureTablesExist();
  }

  // ---------------------------------------------------------------------------
  // Getters & Streams
  // ---------------------------------------------------------------------------

  TransportState get currentState => _mockState ?? _currentState;

  bool get internetAvailable =>
      currentState == TransportState.internetAvailable;
  bool get wifiNoInternet => currentState == TransportState.wifiNoInternet;
  bool get cellularData => currentState == TransportState.cellularData;
  bool get p2pTransportAvailable =>
      currentState == TransportState.p2pTransportAvailable;
  bool get bluetoothOnly => currentState == TransportState.bluetoothOnly;
  bool get noTransport => currentState == TransportState.noTransport;

  // Convenience aliases
  bool get isInternetAvailable =>
      _currentState == TransportState.internetAvailable;
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
  Stream<DateTime> get lastSyncTimestampStream => onLastSyncTimestamp;

  // ---------------------------------------------------------------------------
  // Lifecycle & Periodic Monitoring
  // ---------------------------------------------------------------------------

  /// Starts periodic state polling and auto-recovery monitoring.
  void startMonitoring({Duration interval = const Duration(seconds: 15)}) {
    _monitorTimer?.cancel();
    unawaited(syncIfInternetAvailable());
    _monitorTimer = Timer.periodic(
      interval,
      (_) => unawaited(syncIfInternetAvailable()),
    );
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
    final hasInternet = await verifyInternetHttpPing(
      gatewayHealthUrl: gatewayHealthUrl,
    );

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
        final hasP2p =
            tm.wifiDirectTransport.isAvailable || tm.onlinePeers.isNotEmpty;
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

  /// Uploads only from this phone after it has itself verified gateway access.
  /// A nearby peer advertising an internet capability is not treated as proof
  /// that this device can reach the cloud; it must first receive the packet
  /// over the mesh and run this method on its own connection.
  Future<SyncResult> syncIfInternetAvailable() async {
    final state = await evaluateTransportState();
    if (state != TransportState.internetAvailable) {
      return SyncResult(
        success: false,
        errorMessage: 'No verified gateway connection on this device',
        timestamp: DateTime.now(),
      );
    }
    if (_isSyncing) {
      return SyncResult(
        success: false,
        errorMessage: 'Sync cycle already in progress',
        timestamp: DateTime.now(),
      );
    }
    return triggerAutoRecoverySync();
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
  ///    `sos_events`, `emergency_reports`, `location_history`, `missing_persons`).
  /// 2. Posts to FastAPI gateway `${AppConfig.backendBaseUrl}/api/v1/telemetry/sync`
  ///    with GPS coordinates, device_id, timestamp, and metadata.
  /// 3. Retries using exponential backoff with jitter (initial 1s, max 30s, jitter ±20%).
  /// 4. On 200/201 OK, marks records as `syncedToServer` and `SYNCED`.
  /// 5. Notifies `MeshEngine.instance.notifyPacketSynced(messageId)` for each synced message.
  /// 6. Emits `lastSyncTimestamp`.
  Future<SyncResult> triggerAutoRecoverySync({
    String? gatewayPacketsUrl,
    int maxRetries = 5,
  }) async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        errorMessage: 'Sync cycle already in progress',
        timestamp: DateTime.now(),
      );
    }

    // Strict Offline Resilience Guard:
    // Never perform blocking HTTP calls or throw uncaught SocketException when offline.
    if (!testModeNoDelays && currentState != TransportState.internetAvailable) {
      final state = await evaluateTransportState();
      if (state != TransportState.internetAvailable) {
        return SyncResult(
          success: false,
          errorMessage:
              'No verified gateway connection on this device ($state)',
          timestamp: DateTime.now(),
        );
      }
    }

    _isSyncing = true;
    notifyListeners();

    try {
      await _ensureTablesExist();

      // 1. Query unsynced records
      final unsyncedPackets = await _queryUnsyncedMeshPackets();
      final unsyncedSos = await _queryUnsyncedSosEvents();
      final unsyncedReports = await _queryUnsyncedEmergencyReports();
      final unsyncedLocations = await _queryUnsyncedLocations();
      final unsyncedMissingPersons = await _queryUnsyncedMissingPersons();

      final totalRecords =
          unsyncedPackets.length +
          unsyncedSos.length +
          unsyncedReports.length +
          unsyncedLocations.length +
          unsyncedMissingPersons.length;

      if (totalRecords == 0) {
        debugPrint(
          '[NetworkStateService] Auto-recovery: No unsynced records pending.',
        );
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
        '(${unsyncedPackets.length} mesh packets, ${unsyncedSos.length} SOS, '
        '${unsyncedReports.length} reports, ${unsyncedLocations.length} locations, '
        '${unsyncedMissingPersons.length} missing persons)',
      );

      // 2. Prepare payload and track IDs
      final myDeviceId = DeviceIdentityService.instance.deviceId;
      final payloadList = <Map<String, dynamic>>[];
      final packetIds = <String>[];
      final sosIds = <String>[];
      final reportIds = <String>[];
      final locationIds = <String>[];
      final missingPersonIds = <String>[];
      final uploadedMessageIds = <String>{};

      for (final p in unsyncedPackets) {
        final id = (p['message_id'] ?? p['messageId'] ?? '').toString();
        if (id.isEmpty) continue;
        packetIds.add(id);
        uploadedMessageIds.add(id);
        Map<String, dynamic> routing = const {};
        final storedRouting = p['routing_header_json']?.toString();
        if (storedRouting != null && storedRouting.isNotEmpty) {
          try {
            final decoded = jsonDecode(storedRouting);
            if (decoded is Map) routing = Map<String, dynamic>.from(decoded);
          } catch (_) {}
        }
        final meta = <String, dynamic>{
          if (routing['metadata'] is Map)
            ...Map<String, dynamic>.from(routing['metadata'] as Map),
          if (routing['meta'] is Map)
            ...Map<String, dynamic>.from(routing['meta'] as Map),
          'synced_via': 'auto_recovery',
        };
        final rawConvId = routing['conv_id'] ?? routing['conversationId'];
        final convId = (rawConvId != null && rawConvId.toString().isNotEmpty)
            ? rawConvId.toString()
            : 'CONV_COMMUNITY';
        final senderId = routing['sender_id'] ??
            routing['senderId'] ??
            p['sender_device_id'] ??
            myDeviceId;
        final senderName = (routing['sender_name'] ??
                routing['senderName'] ??
                p['sender_name'])
            ?.toString()
            .trim();
        final ts = routing['ts'] ??
            routing['timestamp'] ??
            p['created_at'] ??
            DateTime.now().millisecondsSinceEpoch;
        final payloadContent = routing['payload'] ??
            p['encrypted_payload_json'] ??
            p['routing_header_json'] ??
            '';
        final packet = <String, dynamic>{
          'ver': 1,
          'msg_id': id,
          'message_id': id,
          'sender_id': senderId,
          'conv_id': convId,
          'ts': ts,
          'ttl': routing['ttl'] ?? p['ttl'] ?? 5,
          'hops': routing['hops'] ?? p['hop_count'] ?? 0,
          'type': routing['type'] ?? 'MESH_PACKET',
          'payload': payloadContent,
          'meta': meta,
        };
        if (senderName != null && senderName.isNotEmpty) {
          packet['sender_name'] = senderName;
        }
        final location = <String, dynamic>{
          if (meta['latitude'] != null) 'lat': meta['latitude'],
          if (meta['longitude'] != null) 'lng': meta['longitude'],
          if (meta['accuracy_m'] != null) 'accuracy': meta['accuracy_m'],
          if (meta['location_source'] != null)
            'fix_type': meta['location_source'],
        };
        if (location.containsKey('lat') && location.containsKey('lng')) {
          packet['location'] = location;
        }
        payloadList.add(packet);
      }

      for (final s in unsyncedSos) {
        final id = (s['message_id'] ?? s['id'] ?? '').toString();
        if (id.isEmpty) continue;
        sosIds.add(id);
        if (uploadedMessageIds.contains(id)) continue;
        uploadedMessageIds.add(id);
        final packet = <String, dynamic>{
          'ver': 1,
          'msg_id': id,
          'message_id': id,
          'sender_id': s['sender_device_id'] ?? myDeviceId,
          'conv_id': 'CONV_COMMUNITY',
          'ts': s['created_at'] ?? DateTime.now().millisecondsSinceEpoch,
          'ttl': 5,
          'hops': 0,
          'type': 'SOS',
          'payload': jsonEncode({
            'category': s['category'],
            'people_count': s['people_count'],
            'notes': s['notes'],
          }),
          'meta': {
            'urgency': s['urgency'] ?? 'CRITICAL',
            'category': s['category'] ?? 'Emergency SOS',
            'peopleCount': s['people_count'] ?? 1,
            'location_source': s['location_source'],
            'location_is_stale': s['location_is_stale'] == 1,
            'synced_via': 'auto_recovery',
          },
        };
        final senderName = s['sender_name']?.toString().trim() ?? '';
        if (senderName.isNotEmpty) packet['sender_name'] = senderName;
        if (s['latitude'] != null && s['longitude'] != null) {
          packet['location'] = {
            'lat': s['latitude'],
            'lng': s['longitude'],
            if (s['location_accuracy'] != null)
              'accuracy': s['location_accuracy'],
            if (s['location_source'] != null) 'fix_type': s['location_source'],
          };
        }
        payloadList.add(packet);
      }

      for (final r in unsyncedReports) {
        final id = (r['id'] ?? r['message_id'] ?? '').toString();
        if (id.isEmpty) continue;
        reportIds.add(id);
        if (uploadedMessageIds.contains(id)) continue;
        uploadedMessageIds.add(id);
        final packet = <String, dynamic>{
          'ver': 1,
          'msg_id': id,
          'message_id': id,
          'sender_id': r['sender_device_id'] ?? myDeviceId,
          'conv_id': 'CONV_COMMUNITY',
          'ts':
              r['timestamp'] ??
              r['created_at'] ??
              DateTime.now().millisecondsSinceEpoch,
          'ttl': 5,
          'hops': 0,
          'type': 'SOS',
          'payload':
              r['description']?.toString() ??
              r['notes']?.toString() ??
              'Emergency Report',
          'meta': {
            'urgency': r['severity'] ?? 'CRITICAL',
            'category': r['type'] ?? 'Emergency SOS',
            'peopleCount': r['people_affected'] ?? 1,
            'synced_via': 'auto_recovery',
          },
        };
        if (r['latitude'] != null && r['longitude'] != null) {
          packet['location'] = {
            'lat': r['latitude'],
            'lng': r['longitude'],
            'fix_type': 'STORED_GPS',
          };
        }
        payloadList.add(packet);
      }

      for (final l in unsyncedLocations) {
        final id = (l['message_id'] ?? l['id'] ?? '').toString();
        if (id.isEmpty) continue;
        locationIds.add(id);
        if (uploadedMessageIds.contains(id)) continue;
        uploadedMessageIds.add(id);
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

      for (final m in unsyncedMissingPersons) {
        final id = (m['id'] ?? '').toString();
        if (id.isEmpty) continue;
        missingPersonIds.add(id);
        if (uploadedMessageIds.contains(id)) continue;
        uploadedMessageIds.add(id);
        final packet = <String, dynamic>{
          'ver': 1,
          'msg_id': id,
          'message_id': id,
          'sender_id': myDeviceId,
          'conv_id': 'CONV_COMMUNITY',
          'ts':
              m['reported_at'] ??
              m['last_seen_time'] ??
              DateTime.now().millisecondsSinceEpoch,
          'ttl': 5,
          'hops': 0,
          'type': 'MISSING_PERSON',
          'payload': jsonEncode(m),
          'meta': {
            'synced_via': 'auto_recovery',
            'name': m['name'],
            'age': m['age'],
          },
        };
        if (m['lat'] != null && m['lng'] != null) {
          packet['location'] = {'lat': m['lat'], 'lng': m['lng']};
        }
        payloadList.add(packet);
      }

      final locationFix = LocationService.instance.currentLocation;
      final batchBody = jsonEncode({
        'device_id': myDeviceId,
        'sync_timestamp': DateTime.now().millisecondsSinceEpoch,
        if (locationFix != null) ...{
          'lat': locationFix.latitude,
          'lng': locationFix.longitude,
          'accuracy': locationFix.horizontalAccuracyMeters,
          'location': {
            'lat': locationFix.latitude,
            'lng': locationFix.longitude,
            'accuracy': locationFix.horizontalAccuracyMeters,
            'fix_type': locationFix.source,
          },
        },
        'metadata': {
          'client': 'rakshanet_mobile',
          'synced_via': 'auto_recovery',
        },
        'packets': payloadList,
      });

      // 3. Post with exponential backoff & jitter
      bool uploadSuccess = false;
      String? lastError;
      final targetUrl = gatewayPacketsUrl ?? AppConfig.telemetrySyncUrl;

      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          final idempotencyKey = payloadList.isNotEmpty
              ? payloadList.first['msg_id']
              : 'IDEMP-${DateTime.now().millisecondsSinceEpoch}';

          http.Response response = await _httpClient
              .post(
                Uri.parse(targetUrl),
                headers: {
                  'Content-Type': 'application/json',
                  'X-Idempotency-Key': idempotencyKey,
                },
                body: batchBody,
              )
              .timeout(const Duration(seconds: 10));

          // If 404 on default telemetry/sync, fallback to packetsUrl (for older mock test servers)
          if (response.statusCode == 404 &&
              gatewayPacketsUrl == null &&
              targetUrl != AppConfig.packetsUrl) {
            try {
              final fallbackResponse = await _httpClient
                  .post(
                    Uri.parse(AppConfig.packetsUrl),
                    headers: {
                      'Content-Type': 'application/json',
                      'X-Idempotency-Key': idempotencyKey,
                    },
                    body: batchBody,
                  )
                  .timeout(const Duration(seconds: 10));
              if (fallbackResponse.statusCode >= 200 &&
                  fallbackResponse.statusCode < 300) {
                response = fallbackResponse;
              }
            } catch (_) {}
          }

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

      // 4. Mark records as syncedToServer in SQLite and notify MeshEngine
      await _markRecordsSynced(
        packetIds,
        sosIds,
        reportIds,
        locationIds,
        missingPersonIds,
        uploadedMessageIds,
      );

      // 5. Fetch cloud available data using IMEI as primary key and synchronize into SQLite
      if (!testModeNoDelays) {
        try {
          await fetchAndSyncCloudDataByImei(client: _httpClient);
        } catch (e) {
          debugPrint('[NetworkStateService] Notice on cloud data fetch: $e');
        }
        try {
          await syncIncomingMessagesFromGateway(client: _httpClient);
        } catch (e) {
          debugPrint('[NetworkStateService] Notice on incoming messages sync: $e');
        }
      }

      // 6. Emit lastSyncTimestamp
      _lastSyncTimestamp = DateTime.now();
      _lastSyncTimestampController.add(_lastSyncTimestamp!);
      _isSyncing = false;
      notifyListeners();

      final result = SyncResult(
        success: true,
        syncedMeshPackets: packetIds.length,
        syncedSosEvents: sosIds.length,
        syncedEmergencyReports: reportIds.length,
        syncedLocationPoints: locationIds.length,
        syncedMissingPersons: missingPersonIds.length,
        totalSynced: totalRecords,
        timestamp: _lastSyncTimestamp!,
      );

      debugPrint(
        '[NetworkStateService] Auto-recovery sync completed successfully: $result',
      );
      return result;
    } catch (e, stack) {
      debugPrint(
        '[NetworkStateService] Auto-recovery fatal exception: $e\n$stack',
      );
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
    final clampedMs = math.min(
      expMs.toDouble(),
      maxBackoff.inMilliseconds.toDouble(),
    );
    // Jitter ±20% (multiplier between 0.8 and 1.2)
    final jitterMultiplier =
        1.0 + (_random.nextDouble() * 2.0 - 1.0) * jitterFactor;
    final delayMs = (clampedMs * jitterMultiplier).round();
    return Duration(milliseconds: math.max(50, delayMs));
  }

  /// Fetches cloud-available data from the backend using the device's IMEI / Unique ID as primary key.
  /// Synchronizes user profile, emergency reports/incidents, and missing persons into SQLite
  /// and updates in-memory stores so the application can immediately use all cloud data.
  Future<bool> fetchAndSyncCloudDataByImei({
    String? imei,
    http.Client? client,
  }) async {
    // Strict Offline Resilience Guard:
    if (!testModeNoDelays && !isInternetAvailable) {
      debugPrint('[NetworkStateService] Offline: skipping cloud fetch by IMEI');
      return false;
    }

    final targetImei = (imei != null && imei.trim().isNotEmpty)
        ? imei.trim()
        : DeviceIdentityService.instance.uniqueImeiId;

    if (targetImei.isEmpty) {
      debugPrint(
        '[NetworkStateService] No valid IMEI or unique ID available for cloud fetch',
      );
      return false;
    }

    final httpClient = client ?? _httpClient;

    try {
      final cloudDataUri = Uri.parse(AppConfig.cloudDataUrl(targetImei));
      final response = await httpClient
          .get(cloudDataUri)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) return false;
        final data = decoded;

        // 1. Sync and apply User Profile
        if (data['user_profile'] is Map) {
          final profileMap = Map<String, dynamic>.from(
            data['user_profile'] as Map,
          );
          final userProfile = UserProfile(
            id: targetImei,
            deviceId: targetImei,
            email: profileMap['email']?.toString() ?? '',
            name: profileMap['name']?.toString() ?? 'User $targetImei',
            bloodGroup:
                profileMap['bloodGroup']?.toString() ??
                profileMap['blood_group']?.toString() ??
                '',
            emergencyContact:
                profileMap['phone']?.toString() ??
                profileMap['emergencyContact']?.toString() ??
                '',
            medicalNotes:
                profileMap['medicalNotes']?.toString() ??
                profileMap['medical_notes']?.toString() ??
                '',
            language: profileMap['language']?.toString() ?? 'English',
            isRegistered: true,
            createdAt: profileMap['created_at'] is int
                ? profileMap['created_at'] as int
                : DateTime.now().millisecondsSinceEpoch,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          );

          await AppDatabase.instance.saveUserProfile(userProfile);
          await UserAuthService.instance.markOfflineLoginAvailable(
            targetImei,
            email: userProfile.email,
            name: userProfile.name,
          );
        }

        // 2. Sync and apply Emergency Reports / Incidents into SQLite
        if (data['incidents'] is List) {
          final incidents = data['incidents'] as List;
          for (final inc in incidents) {
            if (inc is Map) {
              final id = (inc['id'] ?? inc['incident_id'] ?? '').toString();
              if (id.isEmpty) continue;
              final report = EmergencyReport.create(
                id: id,
                category:
                    inc['category']?.toString() ??
                    inc['type']?.toString() ??
                    'Other',
                peopleCount:
                    (inc['people_affected'] ?? inc['casualties'] ?? 1) as int,
                notes:
                    inc['description']?.toString() ??
                    inc['notes']?.toString() ??
                    '',
                latitude: (inc['lat'] ?? inc['latitude']) is num
                    ? ((inc['lat'] ?? inc['latitude']) as num).toDouble()
                    : null,
                longitude: (inc['lng'] ?? inc['longitude']) is num
                    ? ((inc['lng'] ?? inc['longitude']) as num).toDouble()
                    : null,
                location: inc['location']?.toString(),
                status: 'SYNCED',
                timestamp:
                    inc['created_at'] ??
                    inc['timestamp'] ??
                    DateTime.now().millisecondsSinceEpoch,
                severity:
                    inc['severity']?.toString() ??
                    inc['urgency']?.toString() ??
                    'HIGH',
              );
              await AppDatabase.instance.saveEmergencyReport(report);
            }
          }
        }

        // 3. Sync and apply Missing Persons into SQLite
        if (data['missing_persons'] is List) {
          final missingList = data['missing_persons'] as List;
          for (final m in missingList) {
            if (m is Map) {
              final id = (m['id'] ?? '').toString();
              if (id.isEmpty) continue;
              final person = MissingPerson.fromMap(
                Map<String, dynamic>.from(m),
              );
              await AppDatabase.instance.saveMissingPerson(person);
            }
          }
        }

        // 4. Sync and apply recent telemetry packets and messages into SQLite
        if (data['recent_packets'] is List) {
          await _ingestPacketsBatch(data['recent_packets'] as List);
        }

        debugPrint(
          '[NetworkStateService] Successfully fetched and synchronized cloud data for IMEI $targetImei',
        );
        return true;
      } else {
        debugPrint(
          '[NetworkStateService] Cloud data fetch for IMEI $targetImei returned ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('[NetworkStateService] Cloud data fetch by IMEI notice: $e');
    }

    return false;
  }

  /// Downloads incoming mesh and group chat messages from the FastAPI gateway
  /// and persists them into local SQLite tables so all nodes stay in sync.
  Future<int> syncIncomingMessagesFromGateway({http.Client? client}) async {
    if (!testModeNoDelays && !isInternetAvailable) return 0;
    final httpClient = client ?? _httpClient;
    int syncedCount = 0;

    try {
      final uri = Uri.parse('${AppConfig.messagesUrl}?limit=100');
      final res =
          await httpClient.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        final List<dynamic> messageList = decoded is List
            ? decoded
            : (decoded['messages'] ?? decoded['packets'] ?? []);
        syncedCount = await _ingestPacketsBatch(messageList);
      }
    } catch (e) {
      debugPrint('[NetworkStateService] Notice on syncIncomingMessagesFromGateway: $e');
    }
    return syncedCount;
  }

  /// Batch ingests external messages/packets into local SQLite tables
  Future<int> _ingestPacketsBatch(List<dynamic> packetList) async {
    final myDeviceId = DeviceIdentityService.instance.deviceId;
    final dbService = DatabaseService();
    int newCount = 0;

    for (final m in packetList) {
      if (m is! Map) continue;
      final msgId =
          (m['id'] ?? m['msg_id'] ?? m['message_id'] ?? '').toString();
      if (msgId.isEmpty) continue;
      final senderId = (m['sender_id'] ?? m['senderId'] ?? '').toString();
      if (senderId == myDeviceId) continue; // Skip self-authored messages

      final exists = await dbService.messageExists(msgId);
      if (exists) continue;

      final rawConv = (m['conv_id'] ?? m['conversationId'] ?? 'CONV_COMMUNITY').toString();
      final convId = rawConv.isNotEmpty ? rawConv : 'CONV_COMMUNITY';
      final senderName =
          (m['sender_name'] ?? m['senderName'] ?? 'Mesh Peer').toString();
      final content = (m['payload'] ?? m['content'] ?? '').toString();
      final ts = (m['timestamp'] ?? m['ts'] ?? DateTime.now().millisecondsSinceEpoch) as int;
      final type = (m['type'] ?? m['packet_type'] ?? 'TEXT').toString();
      final hops = ((m['hops'] ?? 0) as num).toInt();
      final ttl = ((m['ttl'] ?? 5) as num).toInt();

      final isGroupMsg = convId.startsWith('CONV_GRP-') || convId.startsWith('GRP-');
      final category = isGroupMsg ? 'Group' : (type == 'SOS' ? 'Rescue' : 'Nearby');

      // If group message, ensure group and conversation exist locally
      if (isGroupMsg) {
        final groupId = convId.startsWith('CONV_') ? convId.substring(5) : convId;
        await _ensureGroupExistsLocally(groupId, senderId, senderName, content);
      }

      final chatMsg = ChatMessage(
        messageId: msgId,
        conversationId: convId,
        senderId: senderId,
        senderName: senderName,
        isMine: false,
        content: content,
        timestamp: DateTime.fromMillisecondsSinceEpoch(ts),
        status: MessageDeliveryStatus.syncedToServer,
        hopCount: hops,
        ttl: ttl,
        messageType: type,
        category: category,
      );

      await dbService.insertMessage(chatMsg.toDbMap());
      await AppDatabase.instance.saveEncryptedMeshPacket(
        EncryptedMeshPacket(
          messageId: msgId,
          senderDeviceId: senderId,
          routingHeaderJson: jsonEncode(m),
          encryptedPayloadJson: content,
          status: MeshDeliveryState.deliveredToRecipient,
          hopCount: hops,
          ttl: ttl,
          createdAt: ts,
          expiresAt: ts + 86400000,
        ),
      );
      newCount++;
    }

    if (newCount > 0) {
      debugPrint('[NetworkStateService] Ingested $newCount new cloud messages');
      await ChatService().reloadMessages();
      await GroupService().loadGroups();
    }
    return newCount;
  }

  Future<void> _ensureGroupExistsLocally(
    String groupId,
    String senderId,
    String senderName,
    String messageContent,
  ) async {
    try {
      final existing = await AppDatabase.instance.query(
        'groups',
        where: 'id = ?',
        whereArgs: [groupId],
        limit: 1,
      );
      if (existing.isNotEmpty) return;

      // Try fetching group metadata from gateway
      String groupName = 'Mesh Group ($groupId)';
      String? groupDesc;
      try {
        final res = await _httpClient
            .get(Uri.parse(AppConfig.groupByIdUrl(groupId)))
            .timeout(const Duration(seconds: 4));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final gData = jsonDecode(res.body);
          if (gData is Map && gData['name'] != null) {
            groupName = gData['name'].toString();
            groupDesc = gData['description']?.toString();
          }
        }
      } catch (_) {}

      // Fallback: check if message content is a welcome message containing the group name
      if (groupName.startsWith('Mesh Group (GRP-')) {
        final match = RegExp(r'Created mesh group "([^"]+)"').firstMatch(messageContent);
        if (match != null && match.group(1) != null) {
          groupName = match.group(1)!;
        }
      }

      final now = DateTime.now();
      await AppDatabase.instance.insert(
        'groups',
        {
          'id': groupId,
          'name': groupName,
          'description': groupDesc ?? 'Mesh coordination group',
          'creator_id': senderId,
          'created_at': now.millisecondsSinceEpoch,
          'updated_at': now.millisecondsSinceEpoch,
          'conversation_id': 'CONV_$groupId',
          'member_count': 2,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await AppDatabase.instance.insert(
        'group_members',
        {
          'id': 'MEM-${groupId}_$senderId',
          'group_id': groupId,
          'member_device_id': senderId,
          'member_name': senderName,
          'status': 'ACCEPTED',
          'joined_at': now.millisecondsSinceEpoch,
          'invited_at': now.millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final myDeviceId = DeviceIdentityService.instance.deviceId;
      final myName = DatabaseService.myDisplayName;
      await AppDatabase.instance.insert(
        'group_members',
        {
          'id': 'MEM-${groupId}_SELF',
          'group_id': groupId,
          'member_device_id': myDeviceId,
          'member_name': '$myName (You)',
          'status': 'ACCEPTED',
          'joined_at': now.millisecondsSinceEpoch,
          'invited_at': now.millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await AppDatabase.instance.insert(
        'conversations',
        {
          'id': 'conv_$groupId',
          'conversation_id': 'CONV_$groupId',
          'type': 'GROUP',
          'title': groupName,
          'created_at': now.millisecondsSinceEpoch,
          'updated_at': now.millisecondsSinceEpoch,
          'last_message': 'Group channel synced from gateway',
          'unread_count': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('[NetworkStateService] Error ensuring group exists locally: $e');
    }
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
            reported_by TEXT DEFAULT 'Anonymous'
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

  Future<List<Map<String, dynamic>>> _queryUnsyncedEmergencyReports() async {
    try {
      final rows = await _db.query(
        'emergency_reports',
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

  Future<List<Map<String, dynamic>>> _queryUnsyncedMissingPersons() async {
    try {
      final rows = await _db.query(
        'missing_persons',
        where: "status != ? AND status != ? AND status != ?",
        whereArgs: const ['SYNCED', 'syncedToServer', 'RESOLVED'],
      );
      return rows;
    } catch (_) {
      return [];
    }
  }

  Future<void> _markRecordsSynced(
    List<String> packetIds,
    List<String> sosIds,
    List<String> reportIds,
    List<String> locationIds,
    List<String> missingPersonIds,
    Set<String> uploadedMessageIds,
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
      await _db.update(
        'emergency_reports',
        {'status': 'SYNCED'},
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    for (final id in reportIds) {
      await _db.update(
        'emergency_reports',
        {'status': 'SYNCED'},
        where: 'id = ?',
        whereArgs: [id],
      );
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

    for (final id in missingPersonIds) {
      await _db.update(
        'missing_persons',
        {'status': 'SYNCED'},
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    // Notify MeshEngine for each synced message ID so that in-memory ChatService and UI instantly update
    for (final id in uploadedMessageIds) {
      try {
        MeshEngine.instance.notifyPacketSynced(id);
      } catch (e) {
        debugPrint(
          '[NetworkStateService] Error notifying MeshEngine for $id: $e',
        );
      }
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
