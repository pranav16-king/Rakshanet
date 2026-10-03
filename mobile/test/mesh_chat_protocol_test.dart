import 'package:flutter_test/flutter_test.dart';
import 'package:rakshanet_mobile/models/chat_message.dart';
import 'package:rakshanet_mobile/models/message_envelope.dart';
import 'package:rakshanet_mobile/services/chat_service.dart';
import 'package:rakshanet_mobile/services/mesh_engine.dart';
import 'package:rakshanet_mobile/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mesh Chat Protocol & Save-Before-Send Tests', () {
    late DatabaseService dbService;
    late MeshEngine meshEngine;

    setUp(() {
      dbService = DatabaseService();
      meshEngine = MeshEngine();
    });

    test('Save-Before-Send: Message is persisted with status SAVED before broadcast', () async {
      final chatService = ChatService();
      final msg = await chatService.sendMessage(
        content: 'Emergency medical supplies required at Sector 5',
        conversationId: 'CONV_COMMUNITY',
      );

      // Verify immediate local status
      expect(msg.status, equals(MessageDeliveryStatus.saved));
      expect(msg.isSaved, isTrue);

      // Verify persistent record in SQLite
      final inDb = await dbService.messageExists(msg.messageId);
      expect(inDb, isTrue, reason: 'Message must exist in SQLite before transmission');

      // Verify retrieved record from database
      final all = await dbService.getAllMessages();
      final savedMsg = all.firstWhere((m) => m.messageId == msg.messageId);
      expect(savedMsg.content, equals('Emergency medical supplies required at Sector 5'));
      expect(
        savedMsg.status == MessageDeliveryStatus.saved ||
            savedMsg.status == MessageDeliveryStatus.queued ||
            savedMsg.status == MessageDeliveryStatus.sentNearby,
        isTrue,
      );
    });

    test('Deduplication: Bloom filter and Set drop duplicate packet silently', () async {
      final envelope = MessageEnvelope(
        uuid: 'PKT-TEST-DEDUP-001',
        senderId: 'PEER-NODE-1',
        senderName: 'Test Peer',
        conversationId: 'CONV_COMMUNITY',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        ttl: 5,
        hops: 1,
        type: 'TEXT',
        payload: 'Flood barrier intact at northern bank',
      );

      // First reception: should be forwarded
      final action1 = await meshEngine.receivePacket(envelope);
      expect(action1 == RelayAction.forwarded || action1 == RelayAction.deliveredToMe, isTrue);

      // Second reception (loop packet): must be dropped as duplicate
      final action2 = await meshEngine.receivePacket(envelope);
      expect(action2, equals(RelayAction.droppedDuplicate));
    });

    test('TTL Expiration Guard: Decrements TTL; halts radio retransmission when TTL <= 1', () async {
      final expiringEnvelope = MessageEnvelope(
        uuid: 'PKT-TEST-TTL-EXPIRED-001',
        senderId: 'PEER-NODE-4',
        senderName: 'Exhausted Peer',
        conversationId: 'CONV_COMMUNITY',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        ttl: 1, // At threshold
        hops: 4,
        type: 'TEXT',
        payload: 'Reaching end of line',
      );

      final action = await meshEngine.receivePacket(expiringEnvelope);
      expect(action, equals(RelayAction.storedTtlExpired));

      // Must still be persisted locally in SQLite
      final exists = await dbService.messageExists(expiringEnvelope.uuid);
      expect(exists, isTrue);
    });

    test('4-Phone Multi-Hop Relay Simulation: Phone A -> Phone B -> Phone C -> Phone D', () async {
      final initialMsg = ChatMessage(
        messageId: 'MSG-4PHONE-CHAIN',
        conversationId: 'CONV_COMMUNITY',
        senderId: 'PHONE_A',
        senderName: 'Phone A (Originator)',
        content: 'Critical evacuation underway - bridge safe for pedestrians',
        timestamp: DateTime.now(),
        status: MessageDeliveryStatus.saved,
        hopCount: 0,
        ttl: 5,
      );

      final hopJourney = await meshEngine.simulate4PhoneRelay(initialMsg);

      // Verify all 4 nodes in the relay chain
      expect(hopJourney.length, equals(4));

      // Node A (Origin): hop 0, TTL 5, SAVED
      expect(hopJourney[0].hopCount, equals(0));
      expect(hopJourney[0].ttl, equals(5));

      // Node B (Relay 1): hop 1, TTL 4, RELAYED
      expect(hopJourney[1].hopCount, equals(1));
      expect(hopJourney[1].ttl, equals(4));
      expect(hopJourney[1].status, equals(MessageDeliveryStatus.relayed));

      // Node C (Relay 2): hop 2, TTL 3, RELAYED
      expect(hopJourney[2].hopCount, equals(2));
      expect(hopJourney[2].ttl, equals(3));
      expect(hopJourney[2].status, equals(MessageDeliveryStatus.relayed));

      // Node D (Destination / Rescue): hop 3, TTL 2, DELIVERED
      expect(hopJourney[3].hopCount, equals(3));
      expect(hopJourney[3].ttl, equals(2));
      expect(hopJourney[3].status, equals(MessageDeliveryStatus.delivered));
    });
  });
}
