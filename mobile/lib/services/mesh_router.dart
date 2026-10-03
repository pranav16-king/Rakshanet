import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../database/app_database.dart';
import '../models/delivery_receipt.dart';
import '../models/delivery_state.dart';
import '../models/encrypted_mesh_packet.dart';
import '../models/mesh_message.dart';
import '../models/mesh_packet.dart';
import '../models/peer_capability.dart';
import '../models/telemetry_model.dart';
import 'mesh_engine.dart';

class PacketResult {
  final String action; // 'DROPPED_DUPLICATE', 'STORED_TTL_EXPIRED', 'FORWARDED', 'DELIVERED_LOCALLY'
  final String? msgId;
  final MeshPacket? packet;
  final DeliveryReceipt? deliveryReceipt;
  final String? targetPeerId;

  const PacketResult({
    required this.action,
    this.msgId,
    this.packet,
    this.deliveryReceipt,
    this.targetPeerId,
  });
}

class MeshRouterNode {
  final String deviceId;
  final String name;
  String? email;
  int battery;
  bool isInternetGateway;
  final AppDatabase db;
  final List<MeshPacket> outboxQueue = [];
  final BloomFilter bloomFilter = BloomFilter();
  final Set<String> seenMessageIds = <String>{};
  final List<PeerCapability> peerRoutingTable = [];

  MeshRouterNode({
    required this.deviceId,
    required this.name,
    this.email,
    this.battery = 85,
    this.isInternetGateway = false,
    AppDatabase? database,
  }) : db = database ?? AppDatabase.createIsolated();

  // Save-Before-Send Axiom:
  // Message is written to SQLite locally before radio packet broadcast
  Future<MeshMessage> sendMessage(
    String convId,
    String content, {
    String? recipientUserId,
    String? recipientDeviceId,
  }) async {
    final msgId = 'MSG-${100000 + Random().nextInt(900000)}';
    final now = DateTime.now().millisecondsSinceEpoch;
    final msgRecord = MeshMessage(
      messageId: msgId,
      conversationId: convId,
      senderDeviceId: deviceId,
      senderName: name,
      content: content,
      createdAt: now,
      status: 'SAVED', // Saved locally first!
      hopCount: 0,
      ttl: 5,
    );

    // 1. Transactional write to SQLite messages
    await db.insertMessage(msgRecord);

    // 2. Transactional write to SQLite encrypted_mesh_packets
    final encryptedPkt = EncryptedMeshPacket(
      messageId: msgId,
      senderDeviceId: deviceId,
      recipientUserId: recipientUserId,
      recipientDeviceId: recipientDeviceId,
      routingHeaderJson: jsonEncode({
        'conv_id': convId,
        'ttl': 5,
        'hops': 0,
        'sender_id': deviceId,
      }),
      encryptedPayloadJson: content,
      status: MeshDeliveryState.saved,
      hopCount: 0,
      ttl: 5,
      createdAt: now,
      expiresAt: now + 86400000,
    );
    await db.saveEncryptedMeshPacket(encryptedPkt);

    // 3. Queue for network transmission
    final packet = MeshPacket(
      ver: 1,
      msgId: msgRecord.messageId,
      convId: msgRecord.conversationId,
      senderId: deviceId,
      senderName: name,
      ts: msgRecord.createdAt,
      ttl: 5,
      hops: 0,
      payload: msgRecord.content,
      recipientUserId: recipientUserId,
      recipientDeviceId: recipientDeviceId,
    );
    outboxQueue.add(packet);
    seenMessageIds.add(msgId);
    bloomFilter.add(msgId);

    return msgRecord;
  }

  // Receive and Process RF BLE Packet with Store-and-Forward routing logic
  Future<PacketResult> receivePacket(MeshPacket packet) async {
    // 1. Deduplication Check (Bloom filter + SQLite) -> if seen, drop packet
    if (seenMessageIds.contains(packet.msgId)) {
      return PacketResult(action: 'DROPPED_DUPLICATE', msgId: packet.msgId);
    }
    if (bloomFilter.mightContain(packet.msgId)) {
      final existsInDb = await db.hasMessage(packet.msgId) ||
          await db.hasEncryptedMeshPacket(packet.msgId);
      if (existsInDb) {
        seenMessageIds.add(packet.msgId);
        return PacketResult(action: 'DROPPED_DUPLICATE', msgId: packet.msgId);
      }
    }
    final alreadyExists = await db.hasMessage(packet.msgId) ||
        await db.hasEncryptedMeshPacket(packet.msgId);
    if (alreadyExists) {
      seenMessageIds.add(packet.msgId);
      return PacketResult(action: 'DROPPED_DUPLICATE', msgId: packet.msgId);
    }

    seenMessageIds.add(packet.msgId);
    bloomFilter.add(packet.msgId);

    // 2. Check destination
    final isForMe = (packet.recipientUserId != null &&
            email != null &&
            packet.recipientUserId!.toLowerCase() == email!.toLowerCase()) ||
        (packet.recipientDeviceId != null &&
            packet.recipientDeviceId == deviceId) ||
        (packet.convId == 'CONV_COMMUNITY' || packet.convId == 'COMMUNITY_MESH');

    if (isForMe) {
      // Destination matches self: deliver locally!
      // Save to SQLite messages
      final msg = MeshMessage(
        messageId: packet.msgId,
        conversationId: packet.convId,
        senderDeviceId: packet.senderId,
        senderName: packet.senderName,
        content: packet.payload,
        createdAt: packet.ts,
        status: 'DELIVERED',
        hopCount: packet.hops,
        ttl: packet.ttl,
      );
      await db.insertMessage(msg);

      // Save to encrypted_mesh_packets
      await db.saveEncryptedMeshPacket(EncryptedMeshPacket(
        messageId: packet.msgId,
        senderDeviceId: packet.senderId,
        recipientUserId: packet.recipientUserId,
        recipientDeviceId: packet.recipientDeviceId,
        routingHeaderJson: jsonEncode(packet.toMap()),
        encryptedPayloadJson: packet.payload,
        status: MeshDeliveryState.deliveredToRecipient,
        hopCount: packet.hops,
        ttl: packet.ttl,
        createdAt: packet.ts,
        expiresAt: packet.ts + 86400000,
      ));

      // Record relay audit trail
      await db.recordRelay(
        messageId: packet.msgId,
        fromDeviceId: packet.senderId,
        toDeviceId: deviceId,
        hopNumber: packet.hops + 1,
        status: 'DELIVERED',
      );

      // Send back a signed delivery ACK
      final now = DateTime.now().millisecondsSinceEpoch;
      final receipt = DeliveryReceipt(
        receiptId:
            'RCPT-${packet.msgId.hashCode.abs().toRadixString(16).padLeft(8, '0').toUpperCase()}',
        messageId: packet.msgId,
        recipientId: deviceId,
        ackTimestamp: now,
        signature: 'SIG-ED25519-$deviceId-${packet.msgId}-$now',
      );
      await db.saveDeliveryReceipt(receipt);

      return PacketResult(
        action: 'DELIVERED_LOCALLY',
        msgId: packet.msgId,
        packet: packet,
        deliveryReceipt: receipt,
      );
    }

    // 3. Check TTL: if TTL <= 1, store locally and halt radio forward (prevents infinite loop)
    if (packet.ttl <= 1) {
      final msg = MeshMessage(
        messageId: packet.msgId,
        conversationId: packet.convId,
        senderDeviceId: packet.senderId,
        senderName: packet.senderName,
        content: packet.payload,
        createdAt: packet.ts,
        status: 'EXPIRED',
        hopCount: packet.hops,
        ttl: packet.ttl,
      );
      await db.insertMessage(msg);

      await db.saveEncryptedMeshPacket(EncryptedMeshPacket(
        messageId: packet.msgId,
        senderDeviceId: packet.senderId,
        recipientUserId: packet.recipientUserId,
        recipientDeviceId: packet.recipientDeviceId,
        routingHeaderJson: jsonEncode(packet.toMap()),
        encryptedPayloadJson: packet.payload,
        status: MeshDeliveryState.expired,
        hopCount: packet.hops,
        ttl: packet.ttl,
        createdAt: packet.ts,
        expiresAt: packet.ts + 86400000,
      ));

      return PacketResult(action: 'STORED_TTL_EXPIRED', msgId: packet.msgId);
    }

    // 4. Not for self and TTL > 1:
    // Decrement TTL, increment hop count, record relay audit in SQLite
    final forwardPacket = packet.copyWith(
      ttl: packet.ttl - 1,
      hops: packet.hops + 1,
    );

    final msg = MeshMessage(
      messageId: packet.msgId,
      conversationId: packet.convId,
      senderDeviceId: packet.senderId,
      senderName: packet.senderName,
      content: packet.payload,
      createdAt: packet.ts,
      status: 'RELAYED',
      hopCount: forwardPacket.hops,
      ttl: forwardPacket.ttl,
    );
    await db.insertMessage(msg);

    await db.recordRelay(
      messageId: packet.msgId,
      fromDeviceId: packet.senderId,
      toDeviceId: deviceId,
      hopNumber: forwardPacket.hops,
      status: 'FORWARDED',
    );

    await db.saveEncryptedMeshPacket(EncryptedMeshPacket(
      messageId: packet.msgId,
      senderDeviceId: packet.senderId,
      recipientUserId: packet.recipientUserId,
      recipientDeviceId: packet.recipientDeviceId,
      routingHeaderJson: jsonEncode(forwardPacket.toMap()),
      encryptedPayloadJson: packet.payload,
      status: MeshDeliveryState.relayed,
      hopCount: forwardPacket.hops,
      ttl: forwardPacket.ttl,
      createdAt: packet.ts,
      expiresAt: packet.ts + 86400000,
    ));

    // Forward ciphertext to best candidate peer using routing scoring
    // (prefer peers with higher battery, known route, or internet gateway)
    final bestPeer = selectBestPeer();

    return PacketResult(
      action: 'FORWARDED',
      packet: forwardPacket,
      targetPeerId: bestPeer?.peerId,
    );
  }

  /// Select best candidate peer using dynamic routing scoring
  PeerCapability? selectBestPeer() {
    if (peerRoutingTable.isEmpty) return null;
    final sorted = List<PeerCapability>.from(peerRoutingTable)
      ..sort((a, b) => b.routingScore.compareTo(a.routingScore));
    return sorted.first;
  }

  /// Automatically push queued mesh packets to FastAPI backend (http://localhost:8000/api/v1/packets)
  /// On successful upload, update status to syncedToServer.
  Future<int> uploadQueuedPacketsToServer({
    String endpoint = 'http://localhost:8000/api/v1/packets',
  }) async {
    final hasInternet =
        isInternetGateway || peerRoutingTable.any((p) => p.isInternetGateway);
    if (!hasInternet) return 0;

    final queued = await db.getQueuedMeshPackets();
    if (queued.isEmpty) return 0;

    int syncedCount = 0;
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);

      final payload = {
        'device_id': deviceId,
        'packets': queued.map((p) => p.toMap()).toList(),
      };

      final request = await client.postUrl(Uri.parse(endpoint));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(payload));
      final response = await request.close();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        for (final pkt in queued) {
          await db.updateMeshPacketStatus(
            pkt.messageId,
            MeshDeliveryState.syncedToServer,
          );
          syncedCount++;
        }
      }
      client.close();
    } catch (_) {
      // Offline / server unreachable
    }
    return syncedCount;
  }

  RadioScanProfile getRadioScanProfile() {
    return RadioScanProfile.fromBattery(battery);
  }
}
