import 'dart:math';
import '../models/mesh_message.dart';
import '../models/mesh_packet.dart';
import '../models/telemetry_model.dart';
import '../database/sqlite_database.dart';

class PacketResult {
  final String action; // 'DROPPED_DUPLICATE', 'STORED_TTL_EXPIRED', 'FORWARDED'
  final String? msgId;
  final MeshPacket? packet;

  const PacketResult({
    required this.action,
    this.msgId,
    this.packet,
  });
}

class MeshRouterNode {
  final String deviceId;
  final String name;
  int battery;
  final AppDatabase db;
  final List<MeshPacket> outboxQueue = [];

  MeshRouterNode({
    required this.deviceId,
    required this.name,
    this.battery = 85,
    AppDatabase? database,
  }) : db = database ?? AppDatabase.createIsolated();

  // Save-Before-Send Axiom:
  // Message is written to SQLite locally before radio packet broadcast
  Future<MeshMessage> sendMessage(String convId, String content) async {
    final msgId = 'MSG-${100000 + Random().nextInt(900000)}';
    final msgRecord = MeshMessage(
      messageId: msgId,
      conversationId: convId,
      senderDeviceId: deviceId,
      senderName: name,
      content: content,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      status: 'SAVED', // Saved locally first!
      hopCount: 0,
      ttl: 5,
    );

    // 1. Transactional write to SQLite
    await db.insertMessage(msgRecord);

    // 2. Queue for network transmission
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
    );
    outboxQueue.add(packet);

    return msgRecord;
  }

  // Receive and Process RF BLE Packet
  Future<PacketResult> receivePacket(MeshPacket packet) async {
    // 1. Deduplication Check
    final alreadyExists = await db.hasMessage(packet.msgId);
    if (alreadyExists) {
      return PacketResult(action: 'DROPPED_DUPLICATE', msgId: packet.msgId);
    }

    // 2. Local SQLite Persistence
    final msg = MeshMessage(
      messageId: packet.msgId,
      conversationId: packet.convId,
      senderDeviceId: packet.senderId,
      senderName: packet.senderName,
      content: packet.payload,
      createdAt: packet.ts,
      status: packet.hops > 0 ? 'RELAYED' : 'SENT_TO_NEARBY',
      hopCount: packet.hops,
      ttl: packet.ttl,
    );
    await db.insertMessage(msg);

    // 3. Relay Audit Trail
    await db.recordRelay(
      messageId: packet.msgId,
      fromDeviceId: packet.senderId,
      toDeviceId: deviceId,
      hopNumber: packet.hops + 1,
    );

    // 4. Forwarding Decision
    if (packet.ttl <= 1) {
      return PacketResult(action: 'STORED_TTL_EXPIRED', msgId: packet.msgId);
    }

    final forwardPacket = packet.copyWith(
      ttl: packet.ttl - 1,
      hops: packet.hops + 1,
    );

    return PacketResult(action: 'FORWARDED', packet: forwardPacket);
  }

  RadioScanProfile getRadioScanProfile() {
    return RadioScanProfile.fromBattery(battery);
  }
}
