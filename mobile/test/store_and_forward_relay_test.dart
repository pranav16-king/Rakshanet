import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakshanet_mobile/database/app_database.dart';
import 'package:rakshanet_mobile/models/delivery_receipt.dart';
import 'package:rakshanet_mobile/models/delivery_state.dart';
import 'package:rakshanet_mobile/models/encrypted_mesh_packet.dart';
import 'package:rakshanet_mobile/models/mesh_packet.dart';
import 'package:rakshanet_mobile/models/message_envelope.dart';
import 'package:rakshanet_mobile/models/peer_capability.dart';
import 'package:rakshanet_mobile/services/database_service.dart';
import 'package:rakshanet_mobile/services/mesh_engine.dart';
import 'package:rakshanet_mobile/services/mesh_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. Delivery State Enum & UI Helper Verification', () {
    test('MeshDeliveryState enum values and UI status strings', () {
      expect(MeshDeliveryState.values.length, equals(7));

      expect(
        MeshDeliveryState.saved.statusString(),
        equals('Saved on this phone'),
      );
      expect(
        MeshDeliveryState.queued.statusString(),
        equals('Queued in outbox'),
      );
      expect(
        MeshDeliveryState.relayed.statusString(3),
        equals('Relayed by 3 devices'),
      );
      expect(
        MeshDeliveryState.relayed.statusString(1),
        equals('Relayed by 1 devices'),
      );
      expect(
        MeshDeliveryState.deliveredToRecipient.statusString(),
        equals('Reached recipient'),
      );
      expect(
        MeshDeliveryState.syncedToServer.statusString(),
        equals('Synced to command center'),
      );
      expect(MeshDeliveryState.failed.statusString(), equals('Delivery failed'));
      expect(
        MeshDeliveryState.expired.statusString(),
        equals('Message expired'),
      );
    });

    test('MeshDeliveryState icons and color verification', () {
      expect(MeshDeliveryState.saved.icon, equals(Icons.check));
      expect(
        MeshDeliveryState.queued.icon,
        equals(Icons.access_time_rounded),
      );
      expect(
        MeshDeliveryState.relayed.icon,
        equals(Icons.compare_arrows_rounded),
      );
      expect(
        MeshDeliveryState.deliveredToRecipient.icon,
        equals(Icons.done_all_rounded),
      );
      expect(
        MeshDeliveryState.syncedToServer.icon,
        equals(Icons.cloud_done_rounded),
      );

      // Color checks
      expect(
        MeshDeliveryState.deliveredToRecipient.color,
        equals(const Color(0xFF1E8E4E)),
      );
      expect(
        MeshDeliveryState.syncedToServer.color,
        equals(const Color(0xFF3B82F6)),
      );
      expect(
        MeshDeliveryState.failed.color,
        equals(const Color(0xFFD92D20)),
      );
    });

    test('MeshDeliveryState serialization and parsing', () {
      expect(MeshDeliveryState.saved.toDbString(), equals('SAVED'));
      expect(MeshDeliveryState.queued.toDbString(), equals('QUEUED'));
      expect(MeshDeliveryState.relayed.toDbString(), equals('RELAYED'));
      expect(
        MeshDeliveryState.deliveredToRecipient.toDbString(),
        equals('DELIVERED'),
      );
      expect(MeshDeliveryState.syncedToServer.toDbString(), equals('SYNCED'));
      expect(MeshDeliveryState.failed.toDbString(), equals('FAILED'));
      expect(MeshDeliveryState.expired.toDbString(), equals('EXPIRED'));

      expect(
        MeshDeliveryState.fromString('SAVED'),
        equals(MeshDeliveryState.saved),
      );
      expect(
        MeshDeliveryState.fromString('QUEUED'),
        equals(MeshDeliveryState.queued),
      );
      expect(
        MeshDeliveryState.fromString('RELAYED'),
        equals(MeshDeliveryState.relayed),
      );
      expect(
        MeshDeliveryState.fromString('DELIVERED'),
        equals(MeshDeliveryState.deliveredToRecipient),
      );
      expect(
        MeshDeliveryState.fromString('SYNCED'),
        equals(MeshDeliveryState.syncedToServer),
      );
      expect(
        MeshDeliveryState.fromString('SYNCED_TO_SERVER'),
        equals(MeshDeliveryState.syncedToServer),
      );
    });
  });

  group('2. AppDatabase Version 6 & Store-and-Forward Tables', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.createIsolated();
    });

    test('Encrypted Mesh Packets table CRUD & status transitions', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final packet = EncryptedMeshPacket(
        messageId: 'PKT-TEST-001',
        senderDeviceId: 'SR-AAAA-1111',
        recipientUserId: 'rescuer@example.com',
        recipientDeviceId: 'SR-BBBB-2222',
        routingHeaderJson: '{"ttl":5,"hops":0}',
        encryptedPayloadJson: '{"content":"Medical help needed"}',
        status: MeshDeliveryState.saved,
        hopCount: 0,
        ttl: 5,
        createdAt: now,
        expiresAt: now + 86400000,
      );

      await db.saveEncryptedMeshPacket(packet);

      final exists = await db.hasEncryptedMeshPacket('PKT-TEST-001');
      expect(exists, isTrue);

      final retrieved = await db.getEncryptedMeshPacket('PKT-TEST-001');
      expect(retrieved, isNotNull);
      expect(retrieved!.recipientUserId, equals('rescuer@example.com'));
      expect(retrieved.status, equals(MeshDeliveryState.saved));

      // Transition status to QUEUED -> RELAYED -> SYNCED
      await db.updateMeshPacketStatus('PKT-TEST-001', MeshDeliveryState.queued);
      var queuedList = await db.getQueuedMeshPackets();
      expect(queuedList.any((p) => p.messageId == 'PKT-TEST-001'), isTrue);

      await db.updateMeshPacketStatus(
        'PKT-TEST-001',
        MeshDeliveryState.syncedToServer,
      );
      final synced = await db.getEncryptedMeshPacket('PKT-TEST-001');
      expect(synced!.status, equals(MeshDeliveryState.syncedToServer));
    });

    test('Peer Capabilities table & Routing Scoring', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      final peerA = PeerCapability(
        peerId: 'SR-PEER-A',
        deviceId: 'SR-PEER-A',
        transports: 'BLE',
        batteryLevel: 40,
        isRelay: true,
        isInternetGateway: false,
        lastSeen: now,
      );

      final peerB = PeerCapability(
        peerId: 'SR-PEER-B',
        deviceId: 'SR-PEER-B',
        transports: 'BLE,Wi-Fi',
        batteryLevel: 95,
        isRelay: true,
        isInternetGateway: true, // Gateway bonus
        lastSeen: now,
      );

      await db.savePeerCapability(peerA);
      await db.savePeerCapability(peerB);

      final peers = await db.getPeerCapabilities();
      expect(peers.length, equals(2));

      // Peer B has internet gateway (50) + higher battery (95 * 0.3) -> higher score than Peer A
      expect(peerB.routingScore > peerA.routingScore, isTrue);
    });

    test('Delivery Receipts table CRUD', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final receipt = DeliveryReceipt(
        receiptId: 'RCPT-12345678',
        messageId: 'PKT-TEST-001',
        recipientId: 'SR-DEST-9999',
        ackTimestamp: now,
        signature: 'SIG-ED25519-SR-DEST-9999-PKT-TEST-001',
      );

      await db.saveDeliveryReceipt(receipt);

      final receipts = await db.getDeliveryReceipts('PKT-TEST-001');
      expect(receipts.isNotEmpty, isTrue);
      expect(receipts.first.receiptId, equals('RCPT-12345678'));
      expect(
        receipts.first.signature,
        equals('SIG-ED25519-SR-DEST-9999-PKT-TEST-001'),
      );
    });
  });

  group('3. MeshRouterNode Store-and-Forward Routing Logic', () {
    test(
      'Targeted Packet Delivery to Self: Delivers locally and returns signed ACK',
      () async {
        final node = MeshRouterNode(
          deviceId: 'SR-NODE-ME',
          name: 'My Responder Phone',
          email: 'rescuer@rakshanet.org',
          battery: 90,
        );

        final now = DateTime.now().millisecondsSinceEpoch;
        final packet = MeshPacket(
          ver: 1,
          msgId: 'PKT-FOR-ME-101',
          convId: 'CONV_PRIVATE',
          senderId: 'SR-ORIGIN-01',
          senderName: 'Origin Node',
          ts: now,
          ttl: 5,
          hops: 2,
          payload: 'High priority casualty location',
          recipientUserId: 'rescuer@rakshanet.org',
          recipientDeviceId: 'SR-NODE-ME',
        );

        final result = await node.receivePacket(packet);

        expect(result.action, equals('DELIVERED_LOCALLY'));
        expect(result.deliveryReceipt, isNotNull);
        expect(result.deliveryReceipt!.recipientId, equals('SR-NODE-ME'));
        expect(result.deliveryReceipt!.signature, isNotNull);

        // Verify message stored in SQLite
        final stored = await node.db.hasMessage('PKT-FOR-ME-101');
        expect(stored, isTrue);
      },
    );

    test('TTL Guard: Packet with TTL <= 1 halts radio forwarding', () async {
      final node = MeshRouterNode(
        deviceId: 'SR-NODE-ME',
        name: 'My Node',
        email: 'node@example.com',
      );

      final now = DateTime.now().millisecondsSinceEpoch;
      final dyingPacket = MeshPacket(
        ver: 1,
        msgId: 'PKT-EXPIRED-999',
        convId: 'CONV_REMOTE',
        senderId: 'SR-OTHER',
        senderName: 'Other Node',
        ts: now,
        ttl: 1, // Will expire
        hops: 4,
        payload: 'Packet at last breath',
        recipientUserId: 'other@example.com',
        recipientDeviceId: 'SR-FAR-AWAY',
      );

      final result = await node.receivePacket(dyingPacket);
      expect(result.action, equals('STORED_TTL_EXPIRED'));

      // Packet must be stored locally in SQLite encrypted_mesh_packets with EXPIRED status
      final pktRecord = await node.db.getEncryptedMeshPacket('PKT-EXPIRED-999');
      expect(pktRecord, isNotNull);
      expect(pktRecord!.status, equals(MeshDeliveryState.expired));
    });

    test(
      'Multi-Hop Relay: Decrements TTL, increments hops, and selects best peer candidate',
      () async {
        final node = MeshRouterNode(
          deviceId: 'SR-INTERMEDIATE',
          name: 'Relay Hop Node',
          email: 'relay@example.com',
        );

        final now = DateTime.now().millisecondsSinceEpoch;

        // Register candidate peers
        node.peerRoutingTable.addAll([
          PeerCapability(
            peerId: 'PEER-WEAK',
            deviceId: 'PEER-WEAK',
            batteryLevel: 25,
            isRelay: false,
            isInternetGateway: false,
            lastSeen: now,
          ),
          PeerCapability(
            peerId: 'PEER-STRONG-GATEWAY',
            deviceId: 'PEER-STRONG-GATEWAY',
            batteryLevel: 90,
            isRelay: true,
            isInternetGateway: true,
            lastSeen: now,
          ),
        ]);

        final packet = MeshPacket(
          ver: 1,
          msgId: 'PKT-FORWARD-202',
          convId: 'CONV_REMOTE',
          senderId: 'SR-SENDER-01',
          senderName: 'Sender',
          ts: now,
          ttl: 4,
          hops: 1,
          payload: 'Forwarded telemetry data',
          recipientUserId: 'hq@commandcenter.gov',
          recipientDeviceId: 'SR-COMMAND-HQ',
        );

        final result = await node.receivePacket(packet);

        expect(result.action, equals('FORWARDED'));
        expect(result.packet, isNotNull);
        expect(result.packet!.ttl, equals(3)); // 4 - 1
        expect(result.packet!.hops, equals(2)); // 1 + 1
        expect(result.targetPeerId, equals('PEER-STRONG-GATEWAY')); // Best scored peer

        // Verify relay audit recorded in SQLite
        final relays = await node.db.getRelays();
        expect(relays.any((r) => r['message_id'] == 'PKT-FORWARD-202'), isTrue);
      },
    );

    test('Deduplication: Drops identical packet silently', () async {
      final node = MeshRouterNode(
        deviceId: 'SR-NODE',
        name: 'Node',
        email: 'node@example.com',
      );

      final packet = MeshPacket(
        ver: 1,
        msgId: 'PKT-DUP-CHECK',
        convId: 'CONV_COMMUNITY',
        senderId: 'SR-PEER',
        senderName: 'Peer',
        ts: DateTime.now().millisecondsSinceEpoch,
        ttl: 5,
        hops: 0,
        payload: 'Deduplication test payload',
      );

      final res1 = await node.receivePacket(packet);
      expect(res1.action, equals('DELIVERED_LOCALLY'));

      final res2 = await node.receivePacket(packet);
      expect(res2.action, equals('DROPPED_DUPLICATE'));
    });
  });

  group('4. MeshEngine Store-and-Forward Engine & Gateway Upload', () {
    late MeshEngine engine;
    late DatabaseService dbService;

    setUp(() async {
      engine = MeshEngine();
      dbService = DatabaseService();
      await engine.initialize();
    });

    test('MeshEngine destination check & signed delivery ACK creation', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final envelope = MessageEnvelope(
        uuid: 'PKT-ENGINE-FOR-ME',
        senderId: 'SR-OUTSIDE-NODE',
        senderName: 'Outside Node',
        conversationId: 'CONV_COMMUNITY',
        timestamp: now,
        ttl: 5,
        hops: 1,
        type: 'TEXT',
        payload: 'Direct message to local community channel',
      );

      final action = await engine.receivePacket(envelope);
      expect(action, equals(RelayAction.deliveredToMe));

      // Verify delivery receipt was persisted
      final receipts = await AppDatabase.instance.getDeliveryReceipts(
        'PKT-ENGINE-FOR-ME',
      );
      expect(receipts.isNotEmpty, isTrue);
      expect(receipts.first.recipientId, equals(DatabaseService.myDeviceId));
      expect(receipts.first.signature, contains('SIG-ED25519'));

      // Verify encrypted packet persisted with delivered state
      final pkt = await AppDatabase.instance.getEncryptedMeshPacket(
        'PKT-ENGINE-FOR-ME',
      );
      expect(pkt, isNotNull);
      expect(pkt!.status, equals(MeshDeliveryState.deliveredToRecipient));
    });

    test('MeshEngine outbox queueing & simulated multi-hop progression', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final envelope = MessageEnvelope(
        uuid: 'PKT-OUTBOX-001',
        senderId: DatabaseService.myDeviceId,
        senderName: DatabaseService.myDisplayName,
        conversationId: 'CONV_COMMUNITY',
        timestamp: now,
        ttl: 5,
        hops: 0,
        type: 'TEXT',
        payload: 'Outbox queue test payload',
      );

      engine.queueOutboxMessage(envelope);

      // Packet stored in encrypted_mesh_packets as QUEUED
      final pkt = await AppDatabase.instance.getEncryptedMeshPacket(
        'PKT-OUTBOX-001',
      );
      expect(pkt, isNotNull);
      expect(
        pkt!.status == MeshDeliveryState.queued ||
            pkt.status == MeshDeliveryState.relayed,
        isTrue,
      );
    });
  });
}
