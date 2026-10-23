import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rakshanet_mobile/database/app_database.dart';
import 'package:rakshanet_mobile/services/network/network_state_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NetworkStateService - Transport States & Auto-Recovery Sync', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.createIsolated();
      await db.ensureInitialized();
    });

    test('Tracks all 6 distinct transport states accurately', () {
      final service = NetworkStateService(
        database: db,
        testModeNoDelays: true,
      );

      // 1. noTransport
      service.setTransportStateForTesting(TransportState.noTransport);
      expect(service.currentState, equals(TransportState.noTransport));
      expect(service.noTransport, isTrue);
      expect(service.internetAvailable, isFalse);

      // 2. bluetoothOnly
      service.setTransportStateForTesting(TransportState.bluetoothOnly);
      expect(service.currentState, equals(TransportState.bluetoothOnly));
      expect(service.bluetoothOnly, isTrue);

      // 3. p2pTransportAvailable
      service.setTransportStateForTesting(TransportState.p2pTransportAvailable);
      expect(service.currentState, equals(TransportState.p2pTransportAvailable));
      expect(service.p2pTransportAvailable, isTrue);

      // 4. cellularData
      service.setTransportStateForTesting(TransportState.cellularData);
      expect(service.currentState, equals(TransportState.cellularData));
      expect(service.cellularData, isTrue);

      // 5. wifiNoInternet
      service.setTransportStateForTesting(TransportState.wifiNoInternet);
      expect(service.currentState, equals(TransportState.wifiNoInternet));
      expect(service.wifiNoInternet, isTrue);
      expect(service.internetAvailable, isFalse);

      // 6. internetAvailable
      service.setTransportStateForTesting(TransportState.internetAvailable);
      expect(service.currentState, equals(TransportState.internetAvailable));
      expect(service.internetAvailable, isTrue);
    });

    test('Emits state change notifications on stream and ValueNotifier', () async {
      final service = NetworkStateService(
        database: db,
        testModeNoDelays: true,
      );

      final stateHistory = <TransportState>[];
      final sub = service.onTransportStateChanged.listen((s) => stateHistory.add(s));

      service.setTransportStateForTesting(TransportState.bluetoothOnly);
      service.setTransportStateForTesting(TransportState.wifiNoInternet);
      service.setTransportStateForTesting(TransportState.internetAvailable);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      await sub.cancel();

      expect(stateHistory, containsAllInOrder([
        TransportState.bluetoothOnly,
        TransportState.wifiNoInternet,
        TransportState.internetAvailable,
      ]));
    });

    test('Exponential backoff with jitter formula adheres to bounds (1s to 30s, ±20%)', () {
      final random = math.Random(42);
      final service = NetworkStateService(
        database: db,
        random: random,
        testModeNoDelays: true,
      );

      // Attempt 1: 1s base -> between 800ms and 1200ms
      for (int i = 0; i < 20; i++) {
        final delay1 = service.calculateBackoffDelay(1);
        expect(delay1.inMilliseconds, greaterThanOrEqualTo(800));
        expect(delay1.inMilliseconds, lessThanOrEqualTo(1200));
      }

      // Attempt 2: 2s base -> between 1600ms and 2400ms
      final delay2 = service.calculateBackoffDelay(2);
      expect(delay2.inMilliseconds, greaterThanOrEqualTo(1600));
      expect(delay2.inMilliseconds, lessThanOrEqualTo(2400));

      // Attempt 6 (exponential exceeds 30s max, clamped at 30s) -> between 24s and 36s
      final delayMax = service.calculateBackoffDelay(10);
      expect(delayMax.inMilliseconds, greaterThanOrEqualTo(24000));
      expect(delayMax.inMilliseconds, lessThanOrEqualTo(36000));
    });

    test('Auto-recovery queries unsynced records, posts to gateway with idempotency key, and marks syncedToServer', () async {
      // 1. Prepopulate unsynced records in SQLite
      await db.insert('encrypted_mesh_packets', {
        'message_id': 'PKT-TEST-9001',
        'sender_device_id': 'DEV-ALPHA',
        'routing_header_json': '{"ver":1}',
        'encrypted_payload_json': '{"cipher":"xyz"}',
        'status': 'QUEUED', // Not SYNCED
        'created_at': 1700000000,
        'expires_at': 1700086400,
      });

      await db.insert('sos_events', {
        'id': 'SOS-EVENT-01',
        'message_id': 'SOS-MSG-01',
        'sender_device_id': 'DEV-ALPHA',
        'sender_name': 'Aarav',
        'latitude': 12.9716,
        'longitude': 77.5946,
        'urgency': 'CRITICAL',
        'status': 'PENDING',
        'synced_to_server': 0,
        'created_at': 1700000010,
      });

      await db.insert('location_history', {
        'id': 'LOC-HIST-01',
        'message_id': 'LOC-MSG-01',
        'device_id': 'DEV-ALPHA',
        'latitude': 12.9715,
        'longitude': 77.5945,
        'horizontal_accuracy': 4.5,
        'status': 'PENDING',
        'synced_to_server': 0,
        'timestamp': 1700000020,
      });

      // 2. Mock HTTP client intercepting /api/v1/packets
      String? postedBody;
      String? receivedIdempotencyKey;
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/packets' || request.url.path.endsWith('/packets')) {
          postedBody = request.body;
          receivedIdempotencyKey = request.headers['X-Idempotency-Key'];
          return http.Response(
            jsonEncode({
              'status': 'SUCCESS',
              'accepted_count': 3,
              'duplicate_count': 0,
              'receipt_id': 'RCPT-TEST-888',
              'synced_packet_ids': ['PKT-TEST-9001', 'SOS-MSG-01', 'LOC-MSG-01'],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = NetworkStateService(
        httpClient: mockClient,
        database: db,
        testModeNoDelays: true,
      );

      DateTime? emittedTimestamp;
      service.onLastSyncTimestamp.listen((ts) => emittedTimestamp = ts);

      // 3. Trigger Auto-Recovery Sync
      final result = await service.triggerAutoRecoverySync();

      expect(result.success, isTrue);
      expect(result.totalSynced, equals(3));
      expect(result.syncedMeshPackets, equals(1));
      expect(result.syncedSosEvents, equals(1));
      expect(result.syncedLocationPoints, equals(1));

      // Verify posted request body & idempotency key
      expect(postedBody, isNotNull);
      final decodedJson = jsonDecode(postedBody!) as Map<String, dynamic>;
      final packets = decodedJson['packets'] as List;
      expect(packets.length, equals(3));
      expect(receivedIdempotencyKey, isNotNull);
      expect(receivedIdempotencyKey, equals('PKT-TEST-9001'));

      // Verify records are updated to syncedToServer in SQLite
      final packetRows = await db.query(
        'encrypted_mesh_packets',
        where: 'message_id = ?',
        whereArgs: ['PKT-TEST-9001'],
      );
      expect(packetRows.first['status'], equals('syncedToServer'));

      final sosRows = await db.query(
        'sos_events',
        where: 'message_id = ?',
        whereArgs: ['SOS-MSG-01'],
      );
      expect(sosRows.first['status'], equals('syncedToServer'));
      expect(sosRows.first['synced_to_server'], equals(1));

      final locRows = await db.query(
        'location_history',
        where: 'message_id = ?',
        whereArgs: ['LOC-MSG-01'],
      );
      expect(locRows.first['status'], equals('syncedToServer'));
      expect(locRows.first['synced_to_server'], equals(1));

      // Verify timestamp emitted
      expect(service.lastSyncTimestamp, isNotNull);
      expect(emittedTimestamp, isNotNull);
    });

    test('Auto-recovery retries on transient 500 error and recovers on next attempt', () async {
      await db.insert('encrypted_mesh_packets', {
        'message_id': 'PKT-RETRY-01',
        'sender_device_id': 'DEV-ALPHA',
        'routing_header_json': '{}',
        'encrypted_payload_json': '{}',
        'status': 'SAVED',
        'created_at': 1700000000,
        'expires_at': 1700086400,
      });

      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        if (requestCount == 1) {
          // First attempt fails with 503 Service Unavailable
          return http.Response('Gateway busy', 503);
        }
        // Second attempt succeeds
        return http.Response(
          jsonEncode({
            'status': 'SUCCESS',
            'accepted_count': 1,
            'receipt_id': 'RCPT-RETRY-OK',
          }),
          200,
        );
      });

      final service = NetworkStateService(
        httpClient: mockClient,
        database: db,
        testModeNoDelays: true,
      );

      final result = await service.triggerAutoRecoverySync();

      expect(result.success, isTrue);
      expect(requestCount, equals(2));
      expect(result.syncedMeshPackets, equals(1));

      final rows = await db.query(
        'encrypted_mesh_packets',
        where: 'message_id = ?',
        whereArgs: ['PKT-RETRY-01'],
      );
      expect(rows.first['status'], equals('syncedToServer'));
    });
  });
}
