import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/message_envelope.dart';
import '../models/chat_message.dart';
import 'database_service.dart';

/// Actions taken by MeshEngine when processing incoming packets
enum RelayAction {
  droppedDuplicate,
  storedTtlExpired,
  forwarded,
  deliveredToMe,
}

/// Space-efficient Bloom filter for mesh loop suppression & deduplication
class BloomFilter {
  final int size;
  final List<bool> _bits;
  final int hashFunctions;

  BloomFilter({this.size = 2048, this.hashFunctions = 3})
      : _bits = List.filled(size, false);

  void add(String item) {
    for (int i = 0; i < hashFunctions; i++) {
      final hash = _hash(item, i) % size;
      _bits[hash] = true;
    }
  }

  bool mightContain(String item) {
    for (int i = 0; i < hashFunctions; i++) {
      final hash = _hash(item, i) % size;
      if (!_bits[hash]) return false;
    }
    return true;
  }

  int _hash(String item, int seed) {
    int hash = seed;
    for (int i = 0; i < item.length; i++) {
      hash = (hash * 31 + item.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return hash;
  }

  void clear() {
    _bits.fillRange(0, size, false);
  }
}

/// MeshEngine: Delay-Tolerant Mesh Protocol & Outbox Queue Manager
/// Inspired by Kabootar & MeshChat architectures:
/// - Delay-tolerant message envelope
/// - Deduplication Bloom filter + SQLite verification
/// - Automatic TTL decrement & loop suppression
/// - Outbox queue manager with Save-Before-Send guarantee
/// - 4-Phone multi-hop relay simulation
class MeshEngine extends ChangeNotifier {
  static final MeshEngine _instance = MeshEngine._internal();
  factory MeshEngine() => _instance;
  MeshEngine._internal();

  final DatabaseService _dbService = DatabaseService();

  // Deduplication structures (Bloom filter + in-memory Set)
  final BloomFilter _bloomFilter = BloomFilter();
  final Set<String> _seenMessageIds = <String>{};

  // Outbox transmission queue
  final List<MessageEnvelope> _outboxQueue = [];
  bool _isProcessingOutbox = false;

  // Stream controller for real-time mesh events
  final _envelopeController = StreamController<MessageEnvelope>.broadcast();
  Stream<MessageEnvelope> get incomingEnvelopes => _envelopeController.stream;

  // Outbox delivery status update callbacks
  final _statusUpdateController = StreamController<ChatMessage>.broadcast();
  Stream<ChatMessage> get messageStatusUpdates => _statusUpdateController.stream;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  int _relayedMessagesCount = 8;
  int get relayedMessagesCount => _relayedMessagesCount;

  /// Initializes the MeshEngine and recovers any pending outbox messages from SQLite
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // 1. Warm deduplication filter with existing messages from SQLite
    try {
      final existingMessages = await _dbService.getAllMessages();
      for (final msg in existingMessages) {
        _seenMessageIds.add(msg.id);
        _bloomFilter.add(msg.id);
      }

      // 2. Outbox Queue Manager Recovery: restore pending messages
      final pendingMessages = await _dbService.getPendingOutboxMessages();
      for (final p in pendingMessages) {
        final env = MessageEnvelope(
          uuid: p.messageId,
          senderId: p.senderId,
          senderName: p.senderName,
          conversationId: p.conversationId,
          timestamp: p.timestamp.millisecondsSinceEpoch,
          ttl: p.ttl,
          hops: p.hopCount,
          type: p.messageType,
          payload: p.content,
          recipientTarget: p.recipientTarget,
          metadata: p.location?.toJson(),
        );
        _outboxQueue.add(env);
      }

      if (_outboxQueue.isNotEmpty) {
        _processOutboxQueue();
      }
    } catch (e) {
      debugPrint('[MeshEngine] Init error: $e');
    }

    notifyListeners();
  }

  /// Process an incoming network packet envelope from peer over BLE
  /// Implements: Deduplication -> SQLite Check -> TTL Check -> Forwarding
  Future<RelayAction> receivePacket(MessageEnvelope envelope) async {
    final msgId = envelope.uuid;

    // 1. Fast Bloom filter & in-memory check
    if (_seenMessageIds.contains(msgId)) {
      debugPrint('[MeshEngine] Loop suppression: Dropped duplicate $msgId');
      return RelayAction.droppedDuplicate;
    }

    if (_bloomFilter.mightContain(msgId)) {
      // Confirm against SQLite source of truth
      final existsInDb = await _dbService.messageExists(msgId);
      if (existsInDb) {
        _seenMessageIds.add(msgId);
        debugPrint('[MeshEngine] SQLite confirmed duplicate: Dropped $msgId');
        return RelayAction.droppedDuplicate;
      }
    }

    // Mark as seen
    _seenMessageIds.add(msgId);
    _bloomFilter.add(msgId);

    // 2. Persist to SQLite
    final isForMe = envelope.conversationId == 'CONV_COMMUNITY' ||
        envelope.senderId != DatabaseService.myDeviceId;

    final chatMessage = ChatMessage(
      messageId: envelope.uuid,
      conversationId: envelope.conversationId,
      senderId: envelope.senderId,
      senderName: envelope.senderName,
      isMine: envelope.senderId == DatabaseService.myDeviceId,
      content: envelope.payload,
      timestamp: DateTime.fromMillisecondsSinceEpoch(envelope.timestamp),
      status: envelope.hops > 0
          ? MessageDeliveryStatus.relayed
          : MessageDeliveryStatus.delivered,
      hopCount: envelope.hops,
      ttl: envelope.ttl,
      messageType: envelope.type,
      recipientTarget: envelope.recipientTarget,
      location: envelope.metadata != null
          ? LocationPreview.fromJson(envelope.metadata!)
          : null,
    );

    await _dbService.insertMessage(chatMessage.toDbMap());

    // 3. Record relay audit
    await _dbService.recordRelayAudit(
      messageId: envelope.uuid,
      fromDeviceId: envelope.senderId,
      toDeviceId: DatabaseService.myDeviceId,
      hopNumber: envelope.hops + 1,
      status: 'RECEIVED',
    );

    // 4. Automatic TTL decrement & forwarding rule (TTL expiration guard)
    if (envelope.ttl <= 1) {
      debugPrint('[MeshEngine] TTL expired (${envelope.ttl}). Stored locally; halted radio forward.');
      _envelopeController.add(envelope);
      notifyListeners();
      return RelayAction.storedTtlExpired;
    }

    // Envelope still has TTL: decrement TTL and forward
    final forwardedEnvelope = envelope.copyForRelay();

    // Audit downstream forwarding
    await _dbService.recordRelayAudit(
      messageId: forwardedEnvelope.uuid,
      fromDeviceId: DatabaseService.myDeviceId,
      toDeviceId: 'BLE_BROADCAST',
      hopNumber: forwardedEnvelope.hops,
      status: 'FORWARDED',
    );

    _relayedMessagesCount++;
    _envelopeController.add(forwardedEnvelope);
    notifyListeners();

    debugPrint(
        '[MeshEngine] Forwarded packet ${envelope.uuid}: hops=${forwardedEnvelope.hops}, ttl=${forwardedEnvelope.ttl}');
    return isForMe ? RelayAction.deliveredToMe : RelayAction.forwarded;
  }

  /// Outbox Queue Manager:
  /// Enqueues message already written to SQLite with status 'SAVED'
  /// Attempts local BLE broadcast, advancing to SENT_NEARBY -> RELAYED -> DELIVERED
  void queueOutboxMessage(MessageEnvelope envelope) {
    _seenMessageIds.add(envelope.uuid);
    _bloomFilter.add(envelope.uuid);
    _outboxQueue.add(envelope);
    _processOutboxQueue();
  }

  /// Outbox processing worker with simulated disaster mesh transitions
  Future<void> _processOutboxQueue() async {
    if (_isProcessingOutbox || _outboxQueue.isEmpty) return;
    _isProcessingOutbox = true;

    while (_outboxQueue.isNotEmpty) {
      final envelope = _outboxQueue.removeAt(0);

      try {
        // Step 1: Update status to QUEUED in SQLite
        await _dbService.updateMessageStatus(
          messageId: envelope.uuid,
          status: 'QUEUED',
        );

        // Step 2: Simulate BLE local broadcast attempt (0.5s delay)
        await Future.delayed(const Duration(milliseconds: 500));
        await _dbService.updateMessageStatus(
          messageId: envelope.uuid,
          status: 'SENT_NEARBY',
          hopCount: 0,
        );

        final sentNearbyMsg = ChatMessage(
          messageId: envelope.uuid,
          conversationId: envelope.conversationId,
          senderId: envelope.senderId,
          senderName: envelope.senderName,
          isMine: true,
          content: envelope.payload,
          timestamp: DateTime.fromMillisecondsSinceEpoch(envelope.timestamp),
          status: MessageDeliveryStatus.sentNearby,
          hopCount: 0,
          ttl: envelope.ttl,
          messageType: envelope.type,
          recipientTarget: envelope.recipientTarget,
          location: envelope.metadata != null
              ? LocationPreview.fromJson(envelope.metadata!)
              : null,
        );
        _statusUpdateController.add(sentNearbyMsg);
        notifyListeners();

        // Step 3: Simulate multi-hop mesh relay ACK from intermediate peer (1.5s delay)
        await Future.delayed(const Duration(milliseconds: 1500));
        await _dbService.updateMessageStatus(
          messageId: envelope.uuid,
          status: 'RELAYED',
          hopCount: 2,
        );

        final relayedMsg = sentNearbyMsg.copyWith(
          status: MessageDeliveryStatus.relayed,
          hopCount: 2,
          ttl: envelope.ttl > 2 ? envelope.ttl - 2 : 1,
        );
        _statusUpdateController.add(relayedMsg);
        _relayedMessagesCount++;
        notifyListeners();

        // Step 4: Final delivery confirmation (1.5s delay)
        await Future.delayed(const Duration(milliseconds: 1500));
        await _dbService.updateMessageStatus(
          messageId: envelope.uuid,
          status: 'DELIVERED',
          hopCount: 2,
        );

        final deliveredMsg = relayedMsg.copyWith(
          status: MessageDeliveryStatus.delivered,
        );
        _statusUpdateController.add(deliveredMsg);
        notifyListeners();
      } catch (e) {
        debugPrint('[MeshEngine] Outbox processing error for ${envelope.uuid}: $e');
        await _dbService.updateMessageStatus(
          messageId: envelope.uuid,
          status: 'FAILED',
        );
      }
    }

    _isProcessingOutbox = false;
  }

  /// Multi-hop simulation method: simulateRelay(message, intermediateNodeIds)
  /// Demonstrates Phone A -> Phone B -> Phone C -> Phone D packet delivery
  /// with hop count increment and TTL decrement.
  Future<List<ChatMessage>> simulateRelay(
    ChatMessage message, [
    List<String>? intermediateNodeIds,
  ]) async {
    final nodes = intermediateNodeIds ?? [
      'Phone B (Relay 1)',
      'Phone C (Relay 2)',
      'Phone D (Rescue HQ)',
    ];

    final results = <ChatMessage>[];
    var currentHop = message.hopCount;
    var currentTtl = message.ttl;
    var currentMsg = message;

    // Step 0: Ensure saved locally
    await _dbService.insertMessage(currentMsg.toDbMap());
    results.add(currentMsg);

    String fromDevice = currentMsg.senderId;

    for (int i = 0; i < nodes.length; i++) {
      final nextNode = nodes[i];
      final isLast = i == nodes.length - 1;

      // Check TTL guard
      if (currentTtl <= 1) {
        debugPrint(
            '[MeshEngine.simulateRelay] TTL exhausted ($currentTtl) before $nextNode. Halting relay.');
        break;
      }

      currentHop++;
      currentTtl--;

      final newStatus = isLast
          ? MessageDeliveryStatus.delivered
          : MessageDeliveryStatus.relayed;

      currentMsg = currentMsg.copyWith(
        hopCount: currentHop,
        ttl: currentTtl,
        status: newStatus,
      );

      // Persist to SQLite
      await _dbService.updateMessageStatus(
        messageId: currentMsg.messageId,
        status: currentMsg.statusString,
        hopCount: currentHop,
      );

      // Record audit trail
      await _dbService.recordRelayAudit(
        messageId: currentMsg.messageId,
        fromDeviceId: fromDevice,
        toDeviceId: nextNode,
        hopNumber: currentHop,
        status: isLast ? 'DELIVERED' : 'FORWARDED',
      );

      _relayedMessagesCount++;
      _statusUpdateController.add(currentMsg);
      notifyListeners();

      results.add(currentMsg);
      fromDevice = nextNode;

      await Future.delayed(const Duration(milliseconds: 300));
    }

    return results;
  }

  /// Convenience 4-Phone multi-hop relay simulation
  /// Phone A (Origin) -> Phone B (Relay 1) -> Phone C (Relay 2) -> Phone D (Rescue Station)
  Future<List<ChatMessage>> simulate4PhoneRelay(ChatMessage initialMessage) {
    return simulateRelay(
      initialMessage,
      [
        'Phone B (Relay 1)',
        'Phone C (Relay 2)',
        'Phone D (Rescue Station)',
      ],
    );
  }

  /// Trigger manual synchronization of all pending outbox items
  Future<void> syncAllPendingMessages() async {
    final pending = await _dbService.getPendingOutboxMessages();
    for (final p in pending) {
      final env = MessageEnvelope(
        uuid: p.messageId,
        senderId: p.senderId,
        senderName: p.senderName,
        conversationId: p.conversationId,
        timestamp: p.timestamp.millisecondsSinceEpoch,
        ttl: p.ttl,
        hops: p.hopCount,
        type: p.messageType,
        payload: p.content,
        recipientTarget: p.recipientTarget,
        metadata: p.location?.toJson(),
      );
      queueOutboxMessage(env);
    }
  }

  @override
  void dispose() {
    _envelopeController.close();
    _statusUpdateController.close();
    super.dispose();
  }
}
