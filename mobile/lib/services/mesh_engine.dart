import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/message_envelope.dart';
import '../models/chat_message.dart';
import 'database_service.dart';
import 'bluetooth_radio_service.dart';

/// Actions taken by MeshEngine when processing incoming packets
enum RelayAction {
  droppedDuplicate,
  storedTtlExpired,
  forwarded,
  deliveredToMe,
}

class _OutboxItem {
  const _OutboxItem(this.envelope, {this.attachmentPath});

  final MessageEnvelope envelope;
  final String? attachmentPath;
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
  final BluetoothRadioService _radioService = BluetoothRadioService();
  StreamSubscription<Uint8List>? _radioSubscription;
  StreamSubscription? _peerSubscription;

  // Deduplication structures (Bloom filter + in-memory Set)
  final BloomFilter _bloomFilter = BloomFilter();
  final Set<String> _seenMessageIds = <String>{};

  // Outbox transmission queue
  final List<_OutboxItem> _outboxQueue = [];
  final Set<String> _queuedMessageIds = <String>{};
  bool _isProcessingOutbox = false;

  // Stream controller for real-time mesh events
  final _envelopeController = StreamController<MessageEnvelope>.broadcast();
  Stream<MessageEnvelope> get incomingEnvelopes => _envelopeController.stream;

  // Outbox delivery status update callbacks
  final _statusUpdateController = StreamController<ChatMessage>.broadcast();
  Stream<ChatMessage> get messageStatusUpdates =>
      _statusUpdateController.stream;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  int _relayedMessagesCount = 8;
  int get relayedMessagesCount => _relayedMessagesCount;

  /// Initializes the MeshEngine and recovers any pending outbox messages from SQLite
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // 1. Hook physical Bluetooth radio incoming stream
    _radioSubscription = _radioService.incomingPayloadStream.listen((
      rawBytes,
    ) async {
      try {
        final jsonStr = utf8.decode(rawBytes);
        final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
        final envelope = MessageEnvelope.fromJson(jsonMap);
        await receivePacket(envelope);
      } catch (e) {
        debugPrint('[MeshEngine] Malformed RF packet dropped: $e');
      }
    });
    _peerSubscription = _radioService.peerUpdateStream.listen((peers) {
      if (peers.isNotEmpty) {
        syncAllPendingMessages();
      }
    });

    // 2. Warm deduplication filter with existing messages from SQLite
    try {
      final existingMessages = await _dbService.getAllMessages();
      for (final msg in existingMessages) {
        _seenMessageIds.add(msg.id);
        _bloomFilter.add(msg.id);
      }

      // 3. Outbox Queue Manager Recovery: restore pending messages
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
        _outboxQueue.add(
          _OutboxItem(env, attachmentPath: p.attachment?.localPath),
        );
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

    if (envelope.type == 'ACK' ||
        envelope.type == 'RELAY_ACK' ||
        envelope.type == 'DELIVERY_ACK') {
      return _receiveAcknowledgement(envelope);
    }

    // 2. Persist to SQLite
    final isForMe =
        envelope.conversationId == 'CONV_COMMUNITY' ||
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

    // Receiving a packet is evidence of a real mesh hop. It is not evidence
    // that a rescue endpoint has received it, so acknowledge it as RELAYED.
    await _sendRelayAcknowledgement(envelope);

    // 4. Automatic TTL decrement & forwarding rule (TTL expiration guard)
    if (envelope.ttl <= 1) {
      debugPrint(
        '[MeshEngine] TTL expired (${envelope.ttl}). Stored locally; halted radio forward.',
      );
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

    // Physically re-broadcast forwarded packet over Bluetooth RF airwaves
    try {
      final relayedTo = await _radioService.broadcastJson(
        forwardedEnvelope.toJson(),
      );
      debugPrint(
        '[MeshEngine] Relayed ${forwardedEnvelope.uuid} to $relayedTo Bluetooth peer(s)',
      );
    } catch (e) {
      debugPrint('[MeshEngine] Radio relay broadcast error: $e');
    }

    _relayedMessagesCount++;
    _envelopeController.add(forwardedEnvelope);
    notifyListeners();

    debugPrint(
      '[MeshEngine] Forwarded packet ${envelope.uuid}: hops=${forwardedEnvelope.hops}, ttl=${forwardedEnvelope.ttl}',
    );
    return isForMe ? RelayAction.deliveredToMe : RelayAction.forwarded;
  }

  /// Persists an incoming image after the radio layer has copied it into the
  /// app's private storage, then treats it as a normal delay-tolerant packet.
  Future<RelayAction> receiveMediaPacket(
    MessageEnvelope envelope,
    MediaAttachment attachment,
  ) async {
    final messageId = envelope.uuid;
    if (_seenMessageIds.contains(messageId)) {
      return RelayAction.droppedDuplicate;
    }
    if (_bloomFilter.mightContain(messageId) &&
        await _dbService.messageExists(messageId)) {
      _seenMessageIds.add(messageId);
      return RelayAction.droppedDuplicate;
    }

    _seenMessageIds.add(messageId);
    _bloomFilter.add(messageId);
    await _dbService.insertMessage(
      ChatMessage(
        messageId: messageId,
        conversationId: envelope.conversationId,
        senderId: envelope.senderId,
        senderName: envelope.senderName,
        isMine: envelope.senderId == DatabaseService.myDeviceId,
        content: envelope.payload,
        timestamp: DateTime.fromMillisecondsSinceEpoch(envelope.timestamp),
        status: MessageDeliveryStatus.delivered,
        hopCount: envelope.hops,
        ttl: envelope.ttl,
        messageType: envelope.type,
        recipientTarget: envelope.recipientTarget,
        location: envelope.metadata != null
            ? LocationPreview.fromJson(envelope.metadata!)
            : null,
        category: envelope.metadata?['category']?.toString(),
        attachment: attachment,
      ).toDbMap(),
    );
    await _dbService.recordRelayAudit(
      messageId: messageId,
      fromDeviceId: envelope.senderId,
      toDeviceId: DatabaseService.myDeviceId,
      hopNumber: envelope.hops + 1,
      status: 'RECEIVED_MEDIA',
    );
    await relayReceivedMedia(envelope, attachment.localPath);
    _envelopeController.add(envelope);
    notifyListeners();
    return envelope.ttl <= 1
        ? RelayAction.storedTtlExpired
        : RelayAction.deliveredToMe;
  }

  /// Outbox Queue Manager:
  /// Enqueues message already written to SQLite with status 'SAVED'
  /// Attempts local BLE broadcast, advancing to SENT_NEARBY -> RELAYED -> DELIVERED
  void queueOutboxMessage(MessageEnvelope envelope, {String? attachmentPath}) {
    _seenMessageIds.add(envelope.uuid);
    _bloomFilter.add(envelope.uuid);
    if (_queuedMessageIds.contains(envelope.uuid)) return;
    _queuedMessageIds.add(envelope.uuid);
    _outboxQueue.add(_OutboxItem(envelope, attachmentPath: attachmentPath));
    _processOutboxQueue();
  }

  /// Outbox processing worker. Status only advances when a physical peer
  /// accepted bytes; relayed and delivered are driven by real ACK frames.
  Future<void> _processOutboxQueue() async {
    if (_isProcessingOutbox || _outboxQueue.isEmpty) return;
    _isProcessingOutbox = true;

    while (_outboxQueue.isNotEmpty) {
      final item = _outboxQueue.removeAt(0);
      final envelope = item.envelope;
      _queuedMessageIds.remove(envelope.uuid);

      try {
        // Step 1: Update status to QUEUED in SQLite
        await _dbService.updateMessageStatus(
          messageId: envelope.uuid,
          status: 'QUEUED',
        );
        await _publishStatus(envelope, MessageDeliveryStatus.queued);

        // Step 2: Physically broadcast envelope over Bluetooth RF airwaves
        int peerCount = 0;
        try {
          if (item.attachmentPath != null) {
            final message = await _dbService.getMessageById(envelope.uuid);
            final attachment = message?.attachment;
            if (attachment == null) {
              throw StateError(
                'The queued media attachment is no longer available.',
              );
            }
            peerCount = await _radioService.broadcastMedia(
              filePath: item.attachmentPath!,
              envelope: envelope.toJson(),
              fileName: attachment.fileName,
              mimeType: attachment.mimeType,
              byteLength: attachment.byteLength,
            );
          } else {
            peerCount = await _radioService.broadcastJson(envelope.toJson());
          }
          debugPrint(
            '[MeshEngine] Outbox RF broadcast: ${envelope.uuid} pushed to $peerCount physical peer(s)',
          );
        } catch (e) {
          debugPrint('[MeshEngine] Outbox RF broadcast exception: $e');
        }

        if (peerCount == 0) {
          // The durable row remains QUEUED and will be retried when a peer
          // appears or after an explicit sync. Never invent delivery progress.
          continue;
        }

        await _dbService.updateMessageStatus(
          messageId: envelope.uuid,
          status: 'SENT_NEARBY',
          hopCount: 0,
        );

        await _publishStatus(envelope, MessageDeliveryStatus.sentNearby);
      } catch (e) {
        debugPrint(
          '[MeshEngine] Outbox processing error for ${envelope.uuid}: $e',
        );
        await _dbService.updateMessageStatus(
          messageId: envelope.uuid,
          status: 'FAILED',
        );
      }
    }

    _isProcessingOutbox = false;
  }

  Future<RelayAction> _receiveAcknowledgement(
    MessageEnvelope acknowledgement,
  ) async {
    final targetId =
        acknowledgement.metadata?['ack_msg_id']?.toString() ??
        acknowledgement.payload;
    final isDeliveryAck = acknowledgement.type == 'DELIVERY_ACK';
    final status = isDeliveryAck
        ? MessageDeliveryStatus.delivered
        : MessageDeliveryStatus.relayed;
    final existing = await _dbService.getMessageById(targetId);
    if (existing != null && existing.isMine) {
      await _dbService.updateMessageStatus(
        messageId: targetId,
        status: status.name.toUpperCase(),
        hopCount: acknowledgement.hops,
      );
      _statusUpdateController.add(
        existing.copyWith(status: status, hopCount: acknowledgement.hops),
      );
      notifyListeners();
    }

    if (acknowledgement.ttl <= 1) {
      return RelayAction.storedTtlExpired;
    }

    final relayed = acknowledgement.copyForRelay();
    await _radioService.broadcastBytes(relayed.toBytes());
    return RelayAction.forwarded;
  }

  Future<void> _sendRelayAcknowledgement(MessageEnvelope received) async {
    final acknowledgement = MessageEnvelope(
      uuid: 'ACK-${received.uuid}-${DateTime.now().microsecondsSinceEpoch}',
      senderId: DatabaseService.myDeviceId,
      senderName: DatabaseService.myDisplayName,
      conversationId: received.conversationId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      ttl: received.ttl,
      hops: received.hops + 1,
      type: 'RELAY_ACK',
      payload: received.uuid,
      metadata: {'ack_msg_id': received.uuid},
    );
    await _radioService.broadcastBytes(acknowledgement.toBytes());
  }

  /// Used by the media receiver after its file is durably stored. The file is
  /// then eligible for store-and-forward just like a text envelope.
  Future<void> relayReceivedMedia(
    MessageEnvelope received,
    String attachmentPath,
  ) async {
    await _sendRelayAcknowledgement(received);
    if (received.ttl > 1) {
      queueOutboxMessage(
        received.copyForRelay(),
        attachmentPath: attachmentPath,
      );
    }
  }

  Future<void> _publishStatus(
    MessageEnvelope envelope,
    MessageDeliveryStatus status,
  ) async {
    final persisted = await _dbService.getMessageById(envelope.uuid);
    if (persisted != null) {
      _statusUpdateController.add(
        persisted.copyWith(status: status, hopCount: envelope.hops),
      );
    }
    notifyListeners();
  }

  /// Multi-hop simulation method: simulateRelay(message, intermediateNodeIds)
  /// Demonstrates Phone A -> Phone B -> Phone C -> Phone D packet delivery
  /// with hop count increment and TTL decrement.
  Future<List<ChatMessage>> simulateRelay(
    ChatMessage message, [
    List<String>? intermediateNodeIds,
  ]) async {
    final nodes =
        intermediateNodeIds ??
        ['Phone B (Relay 1)', 'Phone C (Relay 2)', 'Phone D (Rescue HQ)'];

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
          '[MeshEngine.simulateRelay] TTL exhausted ($currentTtl) before $nextNode. Halting relay.',
        );
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
    return simulateRelay(initialMessage, [
      'Phone B (Relay 1)',
      'Phone C (Relay 2)',
      'Phone D (Rescue Station)',
    ]);
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
      queueOutboxMessage(env, attachmentPath: p.attachment?.localPath);
    }
  }

  @override
  void dispose() {
    _radioSubscription?.cancel();
    _peerSubscription?.cancel();
    _envelopeController.close();
    _statusUpdateController.close();
    super.dispose();
  }
}
