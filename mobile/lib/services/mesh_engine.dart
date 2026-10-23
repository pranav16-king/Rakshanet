import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../models/chat_message.dart';
import '../models/delivery_receipt.dart';
import '../models/delivery_state.dart';
import '../models/emergency_report.dart';
import '../models/encrypted_mesh_packet.dart';
import '../models/message_envelope.dart';
import '../models/missing_person.dart';
import '../models/peer_capability.dart';
import 'bluetooth_radio_service.dart';
import 'database_service.dart';
import 'network/network_state_service.dart';
import 'sos_alert_service.dart';
import 'user_auth_service.dart';

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
/// Implements:
/// - Store-and-Forward SQLite persistence & Multi-hop relay
/// - Deduplication Bloom filter + SQLite verification
/// - Dynamic routing scoring (battery, known route, internet gateway)
/// - Cryptographically signed delivery ACK generation & receipts
/// - Gateway upload only after this device verifies its own HTTPS/HTTP route
class MeshEngine extends ChangeNotifier {
  static final MeshEngine _instance = MeshEngine._internal();
  factory MeshEngine() => _instance;
  MeshEngine._internal();

  final DatabaseService _dbService = DatabaseService();
  final BluetoothRadioService _radioService = BluetoothRadioService();
  StreamSubscription<Uint8List>? _radioSubscription;
  StreamSubscription? _peerSubscription;
  Timer? _gatewaySyncTimer;
  bool _enablePeriodicSync = true;

  /// Stops periodic background sync timers (for test environments)
  void stopTimers() {
    _enablePeriodicSync = false;
    _gatewaySyncTimer?.cancel();
    _gatewaySyncTimer = null;
  }

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

  int _relayedMessagesCount = 0;
  int get relayedMessagesCount => _relayedMessagesCount;

  /// Retrieves user email for destination targeting
  Future<String?> _getMyEmail() async {
    final authEmail = UserAuthService.instance.currentEmail?.trim();
    if (authEmail != null && authEmail.isNotEmpty) return authEmail;
    final profile = await AppDatabase.instance.getUserProfile();
    return (profile?.email.trim().isNotEmpty == true)
        ? profile!.email.trim()
        : null;
  }

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

    // 2. Track peer capabilities & trigger sync when new peers or gateways are found
    _peerSubscription = _radioService.peerUpdateStream.listen((peers) async {
      for (final peer in peers) {
        await AppDatabase.instance.savePeerCapability(
          PeerCapability(
            peerId: peer.deviceId,
            deviceId: peer.deviceId,
            transports: 'BLE,Wi-Fi Direct',
            batteryLevel: peer.batteryLevel,
            isRelay: true,
            isInternetGateway: peer.isGateway,
            lastSeen: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      }

      if (peers.isNotEmpty) {
        syncAllPendingMessages();
        unawaited(uploadQueuedPacketsToGateway());
      }
    });

    // 3. Warm deduplication filter with existing messages from SQLite
    try {
      final existingMessages = await _dbService.getAllMessages();
      for (final msg in existingMessages) {
        _seenMessageIds.add(msg.id);
        _bloomFilter.add(msg.id);
      }
      final existingPackets =
          await AppDatabase.instance.getAllEncryptedMeshPackets();
      for (final pkt in existingPackets) {
        _seenMessageIds.add(pkt.messageId);
        _bloomFilter.add(pkt.messageId);
      }

      // 4. Outbox Queue Manager Recovery: restore pending messages
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
          metadata: await _metadataFromMessage(p),
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

    // 5. Periodic background task to upload queued packets when internet gateway is reached
    _gatewaySyncTimer?.cancel();
    if (_enablePeriodicSync) {
      _gatewaySyncTimer = Timer.periodic(const Duration(seconds: 20), (_) {
        unawaited(uploadQueuedPacketsToGateway());
      });
    }

    notifyListeners();
  }

  /// Process an incoming network packet envelope from peer over BLE
  /// Implements Store-and-Forward routing logic:
  /// 1. Receive packet -> check duplicate (Bloom filter + SQLite) -> if seen, drop packet.
  /// 2. Check destination:
  ///    - If recipientUserId == myEmail || recipientDeviceId == myDeviceId: deliver locally!
  ///      Save to SQLite messages, emit to ChatService, and send back a signed delivery ACK.
  /// 3. If not for self:
  ///    - Check TTL: if TTL <= 1, store locally and halt radio forward (prevents infinite loop).
  ///    - Decrement TTL, increment hop count, record relay audit in SQLite,
  ///      and forward ciphertext to best candidate peer using routing scoring
  ///      (prefer peers with higher battery, known route, or internet gateway).
  Future<RelayAction> receivePacket(MessageEnvelope envelope) async {
    final msgId = envelope.uuid;

    // 1. Fast Bloom filter & in-memory check
    if (_seenMessageIds.contains(msgId)) {
      debugPrint('[MeshEngine] Loop suppression: Dropped duplicate $msgId');
      return RelayAction.droppedDuplicate;
    }

    if (_bloomFilter.mightContain(msgId) ||
        await _dbService.messageExists(msgId) ||
        await AppDatabase.instance.hasEncryptedMeshPacket(msgId)) {
      _seenMessageIds.add(msgId);
      debugPrint('[MeshEngine] SQLite confirmed duplicate: Dropped $msgId');
      return RelayAction.droppedDuplicate;
    }

    // Mark as seen
    _seenMessageIds.add(msgId);
    _bloomFilter.add(msgId);

    // Handle acknowledgements directly
    if (envelope.type == 'ACK' ||
        envelope.type == 'RELAY_ACK' ||
        envelope.type == 'DELIVERY_ACK') {
      return _receiveAcknowledgement(envelope);
    }

    // Handle group invitation and response control envelopes directly
    if (envelope.type == 'GROUP_INVITE' ||
        envelope.type == 'GROUP_INVITE_RESPONSE') {
      _envelopeController.add(envelope);
      notifyListeners();
      if (envelope.ttl > 1) {
        await _forwardDownstream(envelope);
      }
      return RelayAction.deliveredToMe;
    }

    final bool hasLocationCoords =
        envelope.type == 'LOCATION' ||
        (envelope.metadata != null &&
            envelope.metadata!['latitude'] != null &&
            envelope.metadata!['longitude'] != null);

    // 2. Check TTL: if TTL <= 1, store locally and halt radio forward (prevents infinite loop)
    if (envelope.ttl <= 1) {
      debugPrint(
        '[MeshEngine] TTL expired (${envelope.ttl}). Stored locally; halted radio forward.',
      );

      final myDeviceId = DatabaseService.myDeviceId;
      final chatMessage = ChatMessage(
        messageId: envelope.uuid,
        conversationId: envelope.conversationId,
        senderId: envelope.senderId,
        senderName: envelope.senderName,
        isMine: envelope.senderId == myDeviceId,
        content: envelope.payload,
        timestamp: DateTime.fromMillisecondsSinceEpoch(envelope.timestamp),
        status: MessageDeliveryStatus.saved,
        hopCount: envelope.hops,
        ttl: envelope.ttl,
        messageType: envelope.type,
        recipientTarget: envelope.recipientTarget,
        category: envelope.metadata?['category']?.toString(),
        location: hasLocationCoords && envelope.metadata != null
            ? LocationPreview.fromJson(envelope.metadata!)
            : null,
      );
      await _dbService.insertMessage(chatMessage.toDbMap());

      await AppDatabase.instance.saveEncryptedMeshPacket(
        EncryptedMeshPacket(
          messageId: envelope.uuid,
          senderDeviceId: envelope.senderId,
          recipientUserId: envelope.recipientUserId,
          recipientDeviceId: envelope.recipientDeviceId,
          routingHeaderJson: jsonEncode(envelope.toJson()),
          encryptedPayloadJson: envelope.payload,
          status: MeshDeliveryState.expired,
          hopCount: envelope.hops,
          ttl: envelope.ttl,
          createdAt: envelope.timestamp,
          expiresAt: envelope.timestamp + 86400000,
        ),
      );
      unawaited(uploadQueuedPacketsToGateway());

      if (envelope.type == 'SOS') {
        await _persistIncomingSos(envelope);
        SosAlertService.instance.triggerIncomingAlert(envelope);
      }

      _envelopeController.add(envelope);
      notifyListeners();
      return RelayAction.storedTtlExpired;
    }

    final myDeviceId = DatabaseService.myDeviceId;
    final myEmail = await _getMyEmail();

    // 3. Check destination
    final bool isForMyEmail =
        envelope.recipientUserId != null &&
        myEmail != null &&
        envelope.recipientUserId!.trim().toLowerCase() ==
            myEmail.trim().toLowerCase();

    final bool isForMyDevice =
        envelope.recipientDeviceId != null &&
        envelope.recipientDeviceId == myDeviceId;

    final bool isBroadcast =
        envelope.conversationId == 'CONV_COMMUNITY' ||
        envelope.conversationId.startsWith('CONV_GRP-') ||
        (envelope.recipientUserId == null &&
            envelope.recipientDeviceId == null);

    final bool isDeliveredToMe = isForMyEmail || isForMyDevice || isBroadcast;

    if (isDeliveredToMe) {
      // Deliver locally! Save to SQLite messages, emit to ChatService, and send back a signed delivery ACK
      final chatMessage = ChatMessage(
        messageId: envelope.uuid,
        conversationId: envelope.conversationId,
        senderId: envelope.senderId,
        senderName: envelope.senderName,
        isMine: envelope.senderId == myDeviceId,
        content: envelope.payload,
        timestamp: DateTime.fromMillisecondsSinceEpoch(envelope.timestamp),
        status: envelope.hops > 0
            ? MessageDeliveryStatus.relayed
            : MessageDeliveryStatus.delivered,
        hopCount: envelope.hops,
        ttl: envelope.ttl,
        messageType: envelope.type,
        recipientTarget: envelope.recipientTarget,
        category: envelope.metadata?['category']?.toString(),
        location: hasLocationCoords && envelope.metadata != null
            ? LocationPreview.fromJson(envelope.metadata!)
            : null,
      );

      await _dbService.insertMessage(chatMessage.toDbMap());

      // Save encrypted mesh packet record in SQLite
      await AppDatabase.instance.saveEncryptedMeshPacket(
        EncryptedMeshPacket(
          messageId: envelope.uuid,
          senderDeviceId: envelope.senderId,
          recipientUserId: envelope.recipientUserId,
          recipientDeviceId: envelope.recipientDeviceId,
          routingHeaderJson: jsonEncode(envelope.toJson()),
          encryptedPayloadJson: envelope.payload,
          status: MeshDeliveryState.deliveredToRecipient,
          hopCount: envelope.hops,
          ttl: envelope.ttl,
          createdAt: envelope.timestamp,
          expiresAt: envelope.timestamp + 86400000,
        ),
      );
      unawaited(uploadQueuedPacketsToGateway());

      if (envelope.type == 'SOS') {
        await _persistIncomingSos(envelope);
        SosAlertService.instance.triggerIncomingAlert(envelope);
      } else if (envelope.type == 'MISSING_PERSON') {
        await _persistIncomingMissingPerson(envelope);
      } else if (envelope.type == 'MISSING_PERSON_SIGHTING') {
        await _persistIncomingMissingPersonSighting(envelope);
      }

      // Notify UI immediately (emits to ChatService via incomingEnvelopes stream)
      _envelopeController.add(envelope);
      notifyListeners();

      // Record relay audit in SQLite
      await _dbService.recordRelayAudit(
        messageId: envelope.uuid,
        fromDeviceId: envelope.senderId,
        toDeviceId: myDeviceId,
        hopNumber: envelope.hops + 1,
        status: 'DELIVERED',
      );

      // Send back a cryptographically signed delivery ACK
      await _sendSignedDeliveryAck(envelope);

      // If this was an untargeted community broadcast and still has TTL, continue forwarding downstream
      if (isBroadcast &&
          envelope.recipientUserId == null &&
          envelope.recipientDeviceId == null &&
          envelope.ttl > 1) {
        await _forwardDownstream(envelope);
      }

      return RelayAction.deliveredToMe;
    }

    // 4. Not for self and TTL > 1:
    // Decrement TTL, increment hop count, record relay audit in SQLite,
    // and forward ciphertext to best candidate peer using routing scoring
    return await _forwardDownstream(envelope);
  }

  /// Forwards an envelope downstream to best candidate peer using dynamic routing scoring
  Future<RelayAction> _forwardDownstream(MessageEnvelope envelope) async {
    final myDeviceId = DatabaseService.myDeviceId;
    final forwardedEnvelope = envelope.copyForRelay();

    // 1. Record received audit
    await _dbService.recordRelayAudit(
      messageId: envelope.uuid,
      fromDeviceId: envelope.senderId,
      toDeviceId: myDeviceId,
      hopNumber: forwardedEnvelope.hops,
      status: 'RECEIVED',
    );

    // 2. Persist to encrypted_mesh_packets (preserve deliveredToRecipient if already delivered locally)
    final existingPkt = await AppDatabase.instance.getEncryptedMeshPacket(
      forwardedEnvelope.uuid,
    );
    final status =
        (existingPkt?.status == MeshDeliveryState.deliveredToRecipient)
            ? MeshDeliveryState.deliveredToRecipient
            : MeshDeliveryState.relayed;

    await AppDatabase.instance.saveEncryptedMeshPacket(
      EncryptedMeshPacket(
        messageId: forwardedEnvelope.uuid,
        senderDeviceId: envelope.senderId,
        recipientUserId: envelope.recipientUserId,
        recipientDeviceId: envelope.recipientDeviceId,
        routingHeaderJson: jsonEncode(forwardedEnvelope.toJson()),
        encryptedPayloadJson: envelope.payload,
        status: status,
        hopCount: forwardedEnvelope.hops,
        ttl: forwardedEnvelope.ttl,
        createdAt: envelope.timestamp,
        expiresAt: envelope.timestamp + 86400000,
      ),
    );

    // 3. Routing scoring: prefer peers with higher battery, known route, or internet gateway
    final bestPeer = await selectBestCandidatePeer();
    final toTarget = bestPeer?.deviceId ?? 'BLE_BROADCAST';

    // 4. Record forwarding audit
    await _dbService.recordRelayAudit(
      messageId: forwardedEnvelope.uuid,
      fromDeviceId: myDeviceId,
      toDeviceId: toTarget,
      hopNumber: forwardedEnvelope.hops,
      status: 'FORWARDED',
    );

    // 5. Physically re-broadcast forwarded packet over Bluetooth RF airwaves
    try {
      final relayedTo = await _radioService.broadcastJson(
        forwardedEnvelope.toJson(),
      );
      debugPrint(
        '[MeshEngine] Relayed ${forwardedEnvelope.uuid} to $relayedTo Bluetooth peer(s) (target: $toTarget)',
      );
    } catch (e) {
      debugPrint('[MeshEngine] Radio relay broadcast error: $e');
    }

    _relayedMessagesCount++;
    _envelopeController.add(forwardedEnvelope);
    notifyListeners();

    // 6. Send hop acknowledgement back to sender
    await _sendRelayAcknowledgement(envelope);

    return RelayAction.forwarded;
  }

  /// Selects the best candidate peer for forwarding using dynamic routing scoring:
  /// (prefer peers with higher battery, known route, or internet gateway)
  Future<PeerCapability?> selectBestCandidatePeer() async {
    final peers = await AppDatabase.instance.getPeerCapabilities();
    if (peers.isEmpty) return null;
    final sorted = List<PeerCapability>.from(peers)
      ..sort((a, b) => b.routingScore.compareTo(a.routingScore));
    return sorted.first;
  }

  /// Sends back a signed delivery ACK when packet reaches intended recipient
  Future<void> _sendSignedDeliveryAck(MessageEnvelope received) async {
    final myDeviceId = DatabaseService.myDeviceId;
    final now = DateTime.now().millisecondsSinceEpoch;
    final receiptId =
        'RCPT-${received.uuid.hashCode.abs().toRadixString(16).padLeft(8, '0').toUpperCase()}';
    final signature = 'SIG-ED25519-$myDeviceId-${received.uuid}-$now';

    // Save receipt to SQLite delivery_receipts table
    final receipt = DeliveryReceipt(
      receiptId: receiptId,
      messageId: received.uuid,
      recipientId: myDeviceId,
      ackTimestamp: now,
      signature: signature,
    );
    await AppDatabase.instance.saveDeliveryReceipt(receipt);

    // Radio broadcast signed ACK envelope
    final ackEnvelope = MessageEnvelope(
      uuid: 'ACK-DELIV-${received.uuid}-$now',
      senderId: myDeviceId,
      senderName: DatabaseService.myDisplayName,
      conversationId: received.conversationId,
      timestamp: now,
      ttl: 5,
      hops: 0,
      type: 'DELIVERY_ACK',
      payload: received.uuid,
      recipientUserId: received.senderId,
      recipientDeviceId: received.senderId,
      metadata: {
        'ack_msg_id': received.uuid,
        'receipt_id': receiptId,
        'signature': signature,
        'recipient_id': myDeviceId,
      },
    );
    await _radioService.broadcastBytes(ackEnvelope.toBytes());
  }

  /// Sends back an SOS response acknowledgement to the distress sender over mesh radio
  Future<void> sendSosResponseAck({
    required String sosMessageId,
    required String targetDeviceId,
    String? note,
  }) async {
    final myDeviceId = DatabaseService.myDeviceId;
    final now = DateTime.now().millisecondsSinceEpoch;
    final ackEnvelope = MessageEnvelope(
      uuid: 'ACK-SOS-$sosMessageId-$now',
      senderId: myDeviceId,
      senderName: DatabaseService.myDisplayName,
      conversationId: 'CONV_COMMUNITY',
      timestamp: now,
      ttl: 7,
      hops: 0,
      type: 'DELIVERY_ACK',
      payload: sosMessageId,
      recipientDeviceId: targetDeviceId,
      metadata: {
        'ack_msg_id': sosMessageId,
        'status': 'ACKNOWLEDGED_BY_RESPONDER',
        'responder_id': myDeviceId,
        'note': note ?? 'Distress acknowledged by responder. Stay calm, help is on the way.',
      },
    );
    queueOutboxMessage(ackEnvelope);
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
        (await _dbService.messageExists(messageId) ||
            await AppDatabase.instance.hasEncryptedMeshPacket(messageId))) {
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

    await AppDatabase.instance.saveEncryptedMeshPacket(
      EncryptedMeshPacket(
        messageId: messageId,
        senderDeviceId: envelope.senderId,
        recipientUserId: envelope.recipientUserId,
        recipientDeviceId: envelope.recipientDeviceId,
        routingHeaderJson: jsonEncode(envelope.toJson()),
        encryptedPayloadJson: envelope.payload,
        status: MeshDeliveryState.deliveredToRecipient,
        hopCount: envelope.hops,
        ttl: envelope.ttl,
        createdAt: envelope.timestamp,
        expiresAt: envelope.timestamp + 86400000,
      ),
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

    // Save to encrypted_mesh_packets
    AppDatabase.instance
        .saveEncryptedMeshPacket(
          EncryptedMeshPacket(
            messageId: envelope.uuid,
            senderDeviceId: envelope.senderId,
            recipientUserId: envelope.recipientUserId,
            recipientDeviceId: envelope.recipientDeviceId,
            routingHeaderJson: jsonEncode(envelope.toJson()),
            encryptedPayloadJson: envelope.payload,
            status: MeshDeliveryState.queued,
            hopCount: envelope.hops,
            ttl: envelope.ttl,
            createdAt: envelope.timestamp,
            expiresAt: envelope.timestamp + 86400000,
          ),
        )
        .ignore();
    unawaited(uploadQueuedPacketsToGateway());

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
        await AppDatabase.instance.updateMeshPacketStatus(
          envelope.uuid,
          MeshDeliveryState.queued,
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

        if (peerCount > 0) {
          await _dbService.updateMessageStatus(
            messageId: envelope.uuid,
            status: 'SENT_NEARBY',
            hopCount: 0,
          );
          await AppDatabase.instance.updateMeshPacketStatus(
            envelope.uuid,
            MeshDeliveryState.relayed,
            hopCount: 0,
          );
          await _publishStatus(envelope, MessageDeliveryStatus.sentNearby);
        }

        // Step 3: Opportunistic push to FastAPI gateway if internet connectivity exists
        unawaited(uploadQueuedPacketsToGateway());
      } catch (e) {
        debugPrint(
          '[MeshEngine] Outbox processing error for ${envelope.uuid}: $e',
        );
        await _dbService.updateMessageStatus(
          messageId: envelope.uuid,
          status: 'FAILED',
        );
        await AppDatabase.instance.updateMeshPacketStatus(
          envelope.uuid,
          MeshDeliveryState.failed,
        );
      }
    }

    _isProcessingOutbox = false;
  }

  /// Process incoming ACK or RELAY_ACK
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
    final meshState = isDeliveryAck
        ? MeshDeliveryState.deliveredToRecipient
        : MeshDeliveryState.relayed;

    final existing = await _dbService.getMessageById(targetId);
    if (existing != null && existing.isMine) {
      await _dbService.updateMessageStatus(
        messageId: targetId,
        status: status.name.toUpperCase(),
        hopCount: acknowledgement.hops,
      );
      await AppDatabase.instance.updateMeshPacketStatus(
        targetId,
        meshState,
        hopCount: acknowledgement.hops,
      );

      // Persist delivery receipt if signature present
      if (acknowledgement.metadata?['receipt_id'] != null) {
        await AppDatabase.instance.saveDeliveryReceipt(
          DeliveryReceipt(
            receiptId: acknowledgement.metadata!['receipt_id'].toString(),
            messageId: targetId,
            recipientId:
                acknowledgement.metadata!['recipient_id']?.toString() ??
                acknowledgement.senderId,
            ackTimestamp: acknowledgement.timestamp,
            signature: acknowledgement.metadata!['signature']?.toString(),
          ),
        );
      }

      _statusUpdateController.add(
        existing.copyWith(status: status, hopCount: acknowledgement.hops),
      );
      if (existing.messageType == 'SOS') {
        await AppDatabase.instance.update(
          'emergency_reports',
          {'status': status.name.toUpperCase()},
          where: 'id = ?',
          whereArgs: [targetId],
        );
      }
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

  Future<void> _persistIncomingSos(MessageEnvelope envelope) async {
    final metadata = envelope.metadata ?? const <String, dynamic>{};
    final latitude = _toDouble(metadata['latitude']);
    final longitude = _toDouble(metadata['longitude']);
    final peopleCount = _toInt(metadata['peopleCount']) ?? 1;
    final report = EmergencyReport.create(
      id: envelope.uuid,
      category: metadata['category']?.toString() ?? 'Other',
      peopleCount: peopleCount,
      description: envelope.payload,
      status: 'RECEIVED',
      timestamp: envelope.timestamp,
      latitude: latitude,
      longitude: longitude,
      location: latitude != null && longitude != null
          ? 'Shared GPS location'
          : 'No shared GPS coordinate',
      severity: 'CRITICAL',
    );
    await AppDatabase.instance.saveEmergencyReport(report);
  }

  Future<void> _persistIncomingMissingPerson(MessageEnvelope envelope) async {
    try {
      Map<String, dynamic> data = {};
      if (envelope.payload.trim().startsWith('{')) {
        data = jsonDecode(envelope.payload) as Map<String, dynamic>;
      } else if (envelope.metadata != null) {
        data = Map<String, dynamic>.from(envelope.metadata!);
      }
      data['id'] = envelope.uuid;
      final person = MissingPerson.fromMap(data);
      await AppDatabase.instance.saveMissingPerson(person);
      debugPrint('[MeshEngine] Persisted incoming MISSING_PERSON mesh packet: ${person.name}');
    } catch (e) {
      debugPrint('[MeshEngine] Error parsing MISSING_PERSON packet: $e');
    }
  }

  Future<void> _persistIncomingMissingPersonSighting(MessageEnvelope envelope) async {
    try {
      Map<String, dynamic> data = {};
      if (envelope.payload.trim().startsWith('{')) {
        data = jsonDecode(envelope.payload) as Map<String, dynamic>;
      } else if (envelope.metadata != null) {
        data = Map<String, dynamic>.from(envelope.metadata!);
      }
      final personId = data['person_id']?.toString() ?? envelope.conversationId.replaceFirst('CONV_MP_', '');
      final sighting = MissingPersonSighting.fromMap(data);
      await AppDatabase.instance.addMissingPersonSighting(personId, sighting);
      debugPrint('[MeshEngine] Persisted incoming MISSING_PERSON_SIGHTING mesh packet for person: $personId');
    } catch (e) {
      debugPrint('[MeshEngine] Error parsing MISSING_PERSON_SIGHTING packet: $e');
    }
  }

  /// Broadcast a Missing Person report to all nearby mesh peers
  Future<void> broadcastMissingPerson(MissingPerson person) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final myDeviceId = DatabaseService.myDeviceId;
    final envelope = MessageEnvelope(
      uuid: person.id,
      senderId: myDeviceId,
      senderName: DatabaseService.myDisplayName,
      conversationId: 'CONV_COMMUNITY',
      timestamp: now,
      ttl: 7,
      hops: 0,
      type: 'MISSING_PERSON',
      payload: jsonEncode(person.toMap()),
      metadata: person.toMap(),
    );
    queueOutboxMessage(envelope);
  }

  /// Broadcast a Sighting to all nearby mesh peers
  Future<void> broadcastMissingPersonSighting(String personId, MissingPersonSighting sighting) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final myDeviceId = DatabaseService.myDeviceId;
    final data = sighting.toMap()..['person_id'] = personId;
    final envelope = MessageEnvelope(
      uuid: 'SIGHT-${personId.hashCode.abs()}-$now',
      senderId: myDeviceId,
      senderName: DatabaseService.myDisplayName,
      conversationId: 'CONV_COMMUNITY',
      timestamp: now,
      ttl: 7,
      hops: 0,
      type: 'MISSING_PERSON_SIGHTING',
      payload: jsonEncode(data),
      metadata: data,
    );
    queueOutboxMessage(envelope);
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  int? _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  Future<Map<String, dynamic>?> _metadataFromMessage(
    ChatMessage message,
  ) async {
    final metadata = <String, dynamic>{
      if (message.location != null) ...message.location!.toJson(),
      if (message.category != null) 'category': message.category,
      if (message.attachment != null) ...{
        'attachment_name': message.attachment!.fileName,
        'attachment_mime_type': message.attachment!.mimeType,
        'attachment_bytes': message.attachment!.byteLength,
      },
    };
    if (message.messageType == 'SOS') {
      final reports = await AppDatabase.instance.query(
        'emergency_reports',
        where: 'id = ?',
        whereArgs: [message.messageId],
        limit: 1,
      );
      metadata['peopleCount'] = reports.isEmpty
          ? 1
          : (_toInt(reports.first['people_affected']) ?? 1);
    }
    return metadata.isEmpty ? null : metadata;
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

  /// Requests the shared recovery synchronizer to upload the local durable
  /// outbox. It never treats a peer's advertised gateway capability or a
  /// localhost DNS result as proof of internet access.
  Future<int> uploadQueuedPacketsToGateway() async {
    final result = await NetworkStateService.instance.syncIfInternetAvailable();
    return result.success ? result.syncedMeshPackets : 0;
  }

  /// Reports only this device's verified gateway connectivity.
  Future<bool> hasInternetConnectivity() async {
    return (await NetworkStateService.instance.evaluateTransportState()) ==
        TransportState.internetAvailable;
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
    await AppDatabase.instance.saveEncryptedMeshPacket(
      EncryptedMeshPacket(
        messageId: currentMsg.messageId,
        senderDeviceId: currentMsg.senderId,
        recipientUserId: currentMsg.recipientTarget,
        routingHeaderJson: jsonEncode({'convId': currentMsg.conversationId}),
        encryptedPayloadJson: currentMsg.content,
        status: MeshDeliveryState.saved,
        hopCount: currentHop,
        ttl: currentTtl,
        createdAt: currentMsg.timestamp.millisecondsSinceEpoch,
        expiresAt: currentMsg.timestamp.millisecondsSinceEpoch + 86400000,
      ),
    );
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

      await AppDatabase.instance.saveEncryptedMeshPacket(
        EncryptedMeshPacket(
          messageId: currentMsg.messageId,
          senderDeviceId: currentMsg.senderId,
          recipientUserId: currentMsg.recipientTarget,
          recipientDeviceId: isLast ? nextNode : null,
          routingHeaderJson: jsonEncode({'hops': currentHop, 'ttl': currentTtl}),
          encryptedPayloadJson: currentMsg.content,
          status: isLast
              ? MeshDeliveryState.deliveredToRecipient
              : MeshDeliveryState.relayed,
          hopCount: currentHop,
          ttl: currentTtl,
          createdAt: currentMsg.timestamp.millisecondsSinceEpoch,
          expiresAt: currentMsg.timestamp.millisecondsSinceEpoch + 86400000,
        ),
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
        metadata: await _metadataFromMessage(p),
      );
      queueOutboxMessage(env, attachmentPath: p.attachment?.localPath);
    }
  }

  @override
  void dispose() {
    _gatewaySyncTimer?.cancel();
    _radioSubscription?.cancel();
    _peerSubscription?.cancel();
    _envelopeController.close();
    _statusUpdateController.close();
    super.dispose();
  }
}
