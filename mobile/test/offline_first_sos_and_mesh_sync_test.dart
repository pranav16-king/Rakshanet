import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:rakshanet_mobile/config/app_config.dart';
import 'package:rakshanet_mobile/database/app_database.dart';
import 'package:rakshanet_mobile/models/chat_message.dart';
import 'package:rakshanet_mobile/providers/sos_provider.dart';
import 'package:rakshanet_mobile/services/chat_service.dart';
import 'package:rakshanet_mobile/services/database_service.dart';
import 'package:rakshanet_mobile/services/mesh_engine.dart';
import 'package:rakshanet_mobile/services/network/network_state_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Offline-First SOS, Mesh Sync & Network Recovery Tests', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.createIsolated();
      await db.ensureInitialized();
    });

    test('NetworkStateService exposes isInternetAvailable correctly', () {
      final service = NetworkStateService(
        database: db,
        testModeNoDelays: true,
      );

      service.setTransportStateForTesting(TransportState.noTransport);
      expect(service.isInternetAvailable, isFalse);

      service.setTransportStateForTesting(TransportState.bluetoothOnly);
      expect(service.isInternetAvailable, isFalse);

      service.setTransportStateForTesting(TransportState.wifiNoInternet);
      expect(service.isInternetAvailable, isFalse);

      service.setTransportStateForTesting(TransportState.internetAvailable);
      expect(service.isInternetAvailable, isTrue);
    });

    test('MeshEngine.notifyPacketSynced updates SQLite and emits syncedToServer', () async {
      final engine = MeshEngine.instance;
      final dbService = DatabaseService();

      const testMsgId = 'MSG-SYNC-TEST-001';
      final initialMsg = ChatMessage(
        messageId: testMsgId,
        conversationId: 'CONV_COMMUNITY',
        senderId: 'DEV-SELF',
        senderName: 'You',
        content: 'Test distress packet',
        timestamp: DateTime.now(),
        status: MessageDeliveryStatus.queued,
      );

      await dbService.insertMessage(initialMsg.toDbMap());

      ChatMessage? updatedMsgReceived;
      final sub = engine.messageStatusUpdates.listen((msg) {
        if (msg.messageId == testMsgId) {
          updatedMsgReceived = msg;
        }
      });

      engine.notifyPacketSynced(testMsgId);

      // Wait brief duration for async unawaited execution to complete
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      expect(updatedMsgReceived, isNotNull);
      expect(updatedMsgReceived!.status, equals(MessageDeliveryStatus.syncedToServer));

      // Verify in SQLite
      final persisted = await dbService.getMessageById(testMsgId);
      expect(persisted, isNotNull);
      expect(persisted!.status, equals(MessageDeliveryStatus.syncedToServer));
    });

    test('SosProvider triggers offline SOS without crashing and commits to SQLite outbox', () async {
      NetworkStateService.instance.setTransportStateForTesting(TransportState.noTransport);
      expect(NetworkStateService.instance.isInternetAvailable, isFalse);

      const sosMsgId = 'SOS-TEST-OFFLINE-001';
      await SosProvider.instance.triggerSos(
        category: 'Flood',
        peopleCount: 3,
        latitude: 13.0827,
        longitude: 80.2707,
        accuracy: 8.5,
        notes: 'Water level rising quickly',
        messageId: sosMsgId,
      );

      // Verify emergency_reports
      final reportRows = await AppDatabase.instance.query(
        'emergency_reports',
        where: 'id = ?',
        whereArgs: [sosMsgId],
      );
      expect(reportRows.isNotEmpty, isTrue);
      expect(reportRows.first['people_affected'], equals(3));
      expect(reportRows.first['latitude'], equals(13.0827));
      expect(reportRows.first['longitude'], equals(80.2707));

      // Verify sos_events
      final eventRows = await AppDatabase.instance.query(
        'sos_events',
        where: 'id = ? OR message_id = ?',
        whereArgs: [sosMsgId, sosMsgId],
      );
      expect(eventRows.isNotEmpty, isTrue);
      expect(eventRows.first['urgency'], equals('CRITICAL'));
      expect(eventRows.first['synced_to_server'], equals(0));

      // Verify location_history
      final locRows = await AppDatabase.instance.query(
        'location_history',
        where: 'message_id = ?',
        whereArgs: [sosMsgId],
      );
      expect(locRows.isNotEmpty, isTrue);
      expect(locRows.first['latitude'], equals(13.0827));
      expect(locRows.first['horizontal_accuracy'], equals(8.5));
    });

    test('NetworkStateService auto-recovery pushes unsynced reports & missing persons to telemetry/sync', () async {
      // 1. Populate unsynced emergency_reports & missing_persons
      await db.insert('emergency_reports', {
        'id': 'REPORT-AUTO-01',
        'type': 'Medical Emergency',
        'description': 'Oxygen cylinder needed',
        'status': 'QUEUED',
        'timestamp': 1700000000,
        'location': 'Ward 4',
        'latitude': 13.08,
        'longitude': 80.27,
        'people_affected': 2,
        'severity': 'CRITICAL',
      });

      await db.insert('missing_persons', {
        'id': 'MISSING-AUTO-01',
        'name': 'Rahul Verma',
        'age': 34,
        'gender': 'Male',
        'description': 'Blue shirt and jeans',
        'last_seen_location': 'Central Station',
        'lat': 13.081,
        'lng': 80.271,
        'last_seen_time': 1700000000,
        'reported_at': 1700000050,
        'status': 'REPORTED',
      });

      String? postedBody;
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/v1/telemetry/sync') ||
            request.url.path.contains('/packets')) {
          postedBody = request.body;
          return http.Response(
            jsonEncode({
              'status': 'SUCCESS',
              'accepted_count': 2,
              'duplicate_count': 0,
              'receipt_id': 'RCPT-AUTO-100',
              'synced_packet_ids': ['REPORT-AUTO-01', 'MISSING-AUTO-01'],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not found', 404);
      });

      final service = NetworkStateService(
        httpClient: mockClient,
        database: db,
        testModeNoDelays: true,
      );

      final result = await service.triggerAutoRecoverySync();

      expect(result.success, isTrue);
      expect(result.syncedEmergencyReports, equals(1));
      expect(result.syncedMissingPersons, equals(1));

      expect(postedBody, isNotNull);
      final jsonMap = jsonDecode(postedBody!) as Map<String, dynamic>;
      expect(jsonMap['packets'], isList);
      final packets = jsonMap['packets'] as List;
      expect(packets.length, equals(2));

      // Verify records are updated to SYNCED in SQLite
      final reportRows = await db.query(
        'emergency_reports',
        where: 'id = ?',
        whereArgs: ['REPORT-AUTO-01'],
      );
      expect(reportRows.first['status'], equals('SYNCED'));

      final missingRows = await db.query(
        'missing_persons',
        where: 'id = ?',
        whereArgs: ['MISSING-AUTO-01'],
      );
      expect(missingRows.first['status'], equals('SYNCED'));
    });
  });
}
