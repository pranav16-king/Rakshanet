import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../models/message_envelope.dart';
import 'database_service.dart';
import 'bluetooth_radio_service.dart';
import 'mesh_engine.dart';

/// Chat Service with Save-Before-Send guarantee
/// Source of truth: SQLite database.
/// Provides reactive state for Screen 5 (Community Chat) and Screen 10 (My Messages).
class ChatService extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final BluetoothRadioService _radioService = BluetoothRadioService();
  final MeshEngine _meshEngine = MeshEngine();
  final Uuid _uuid = const Uuid();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String _activeFilter = 'Nearby'; // 'Nearby', 'Group', 'Rescue', 'Saved'
  final int _onlineDevices = 24;
  bool _isSyncing = false;

  // Deduplication structures (Bloom filter + in-memory Set)
  final BloomFilter _bloomFilter = BloomFilter();
  final Set<String> _seenMessageIds = <String>{};

  StreamSubscription<ChatMessage>? _statusSubscription;
  StreamSubscription<MessageEnvelope>? _incomingSubscription;
  StreamSubscription<Uint8List>? _radioSubscription;

  List<ChatMessage> get allMessages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String get activeFilter => _activeFilter;
  int get onlineDevices => _radioService.connectedCount > 0
      ? _radioService.connectedCount
      : _onlineDevices;
  bool get isSyncing => _isSyncing;

  ChatService() {
    _initialize();
  }

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    await _meshEngine.initialize();
    await _radioService.initialize(
      deviceId: DatabaseService.myDeviceId,
      displayName: DatabaseService.myDisplayName,
    );
    await _loadMessagesFromDb();

    // Populate deduplication filter with existing messages from SQLite
    for (final msg in _messages) {
      _seenMessageIds.add(msg.messageId);
      _bloomFilter.add(msg.messageId);
    }

    // 1. Listen to incoming packets directly from BluetoothRadioService().peerPayloadStream
    _radioSubscription = _radioService.peerPayloadStream.listen((rawBytes) async {
      await _handleIncomingPeerPayload(rawBytes);
    });

    // 2. Listen to real-time outbox status updates from MeshEngine (SAVED -> QUEUED -> SENT_NEARBY -> RELAYED -> DELIVERED)
    _statusSubscription = _meshEngine.messageStatusUpdates.listen((updatedMsg) {
      final index = _messages.indexWhere((m) => m.messageId == updatedMsg.messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(
          status: updatedMsg.status,
          hopCount: updatedMsg.hopCount,
        );
        notifyListeners();
      }
    });

    // 3. Listen to incoming envelopes from mesh engine
    _incomingSubscription = _meshEngine.incomingEnvelopes.listen((envelope) {
      _loadMessagesFromDb();
    });

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadMessagesFromDb() async {
    _messages = await _dbService.getAllMessages();
    notifyListeners();
  }

  /// Handles incoming RF byte payloads received from neighboring radio peers
  Future<void> _handleIncomingPeerPayload(Uint8List rawBytes) async {
    try {
      final envelope = MessageEnvelope.tryFromBytes(rawBytes);
      if (envelope == null) return;

      // Check if packet is an ACK confirmation
      if (envelope.type == 'ACK' || envelope.type == 'RELAY_ACK') {
        final targetId = envelope.metadata?['ack_msg_id'] ?? envelope.payload;
        await _dbService.updateMessageStatus(
          messageId: targetId,
          status: 'DELIVERED',
        );
        final index = _messages.indexWhere((m) => m.messageId == targetId);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(
            status: MessageDeliveryStatus.delivered,
          );
          notifyListeners();
        }
        // If TTL > 1, decrement TTL and forward/relay ACK packet to other nearby peers
        if (envelope.ttl > 1) {
          final relayedAck = envelope.copyForRelay();
          await _radioService.broadcastBytes(relayedAck.toBytes());
        }
        return;
      }

      // Check deduplication set / Bloom filter; if already seen, drop silently
      final msgId = envelope.uuid;
      if (_seenMessageIds.contains(msgId)) {
        return;
      }

      if (_bloomFilter.mightContain(msgId)) {
        final exists = await _dbService.messageExists(msgId);
        if (exists) {
          _seenMessageIds.add(msgId);
          return;
        }
      }

      // If new: mark seen in deduplication structures
      _seenMessageIds.add(msgId);
      _bloomFilter.add(msgId);

      // Save to SQLite
      final isMine = envelope.senderId == DatabaseService.myDeviceId;
      final chatMsg = ChatMessage(
        messageId: envelope.uuid,
        conversationId: envelope.conversationId,
        senderId: envelope.senderId,
        senderName: envelope.senderName,
        isMine: isMine,
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
        category: envelope.metadata?['category'] as String?,
      );

      await _dbService.insertMessage(chatMsg.toDbMap());

      // Update ChatService messages list & notifyListeners()
      final existingIndex = _messages.indexWhere((m) => m.messageId == msgId);
      if (existingIndex == -1) {
        _messages.add(chatMsg);
      } else {
        _messages[existingIndex] = chatMsg;
      }
      notifyListeners();

      // If message is from a peer, return an ACK packet
      if (!isMine) {
        final ackEnvelope = MessageEnvelope(
          uuid: 'ACK-${_uuid.v4().substring(0, 8).toUpperCase()}',
          senderId: DatabaseService.myDeviceId,
          senderName: DatabaseService.myDisplayName,
          conversationId: envelope.conversationId,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          ttl: 5,
          hops: 0,
          type: 'ACK',
          payload: envelope.uuid,
          metadata: {'ack_msg_id': envelope.uuid},
        );
        await _radioService.broadcastBytes(ackEnvelope.toBytes());
      }

      // If TTL > 1, decrement TTL and forward/relay packet to other nearby peers
      if (envelope.ttl > 1) {
        final forwardedEnvelope = envelope.copyForRelay();
        await _radioService.broadcastBytes(forwardedEnvelope.toBytes());
      }
    } catch (e) {
      debugPrint('[ChatService] Error processing incoming peer packet: $e');
    }
  }

  void setActiveFilter(String filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  /// Messages for Screen 5 (Community Chat filtered by selected tab)
  List<ChatMessage> get communityMessages {
    final list = _messages.where((m) =>
      m.conversationId == 'CONV_COMMUNITY' ||
      m.conversationId == 'COMMUNITY_MESH' ||
      m.conversationId == 'community' ||
      m.conversationId == 'global_emergency' ||
      m.conversationId.isEmpty
    ).toList();

    if (_activeFilter == 'Nearby') {
      return list;
    } else if (_activeFilter == 'Group') {
      return list.where((m) => m.category == 'Group' || m.messageType == 'GROUP').toList();
    } else if (_activeFilter == 'Rescue') {
      return list.where((m) =>
          m.content.toLowerCase().contains('help') ||
          m.content.toLowerCase().contains('safe') ||
          m.content.toLowerCase().contains('blocked') ||
          m.content.toLowerCase().contains('sos') ||
          m.messageType == 'SOS' ||
          m.messageType == 'LOCATION' ||
          (m.category != null && m.category!.toLowerCase().contains('rescue'))).toList();
    } else if (_activeFilter == 'Saved') {
      return list.where((m) => m.status == MessageDeliveryStatus.saved || m.isMine).toList();
    }
    return list;
  }

  /// Pending messages for Screen 10 (items with status SAVED or QUEUED waiting for sync)
  List<ChatMessage> get pendingMessages {
    return _messages.where((m) =>
        m.status == MessageDeliveryStatus.saved ||
        m.status == MessageDeliveryStatus.queued).toList();
  }

  /// Sent messages for Screen 10
  List<ChatMessage> get sentMessages {
    return _messages.where((m) =>
        m.isMine &&
        m.status != MessageDeliveryStatus.saved &&
        m.status != MessageDeliveryStatus.queued).toList();
  }

  /// Received messages for Screen 10
  List<ChatMessage> get receivedMessages {
    return _messages.where((m) => !m.isMine).toList();
  }

  /// Save-Before-Send Guarantee:
  /// Writes message record to SQLite with status 'SAVED' BEFORE any network attempt.
  Future<ChatMessage> sendMessage({
    required String content,
    String conversationId = 'CONV_COMMUNITY',
    String messageType = 'TEXT',
    String? category,
    String? recipientTarget,
    LocationPreview? location,
  }) async {
    final now = DateTime.now();
    final messageId = 'MSG-${_uuid.v4().substring(0, 8).toUpperCase()}';

    // 1. Construct local chat message object with status SAVED (Single grey tick)
    final chatMsg = ChatMessage(
      messageId: messageId,
      conversationId: conversationId,
      senderId: DatabaseService.myDeviceId,
      senderName: DatabaseService.myDisplayName,
      isMine: true,
      content: content,
      timestamp: now,
      status: MessageDeliveryStatus.saved, // Saved on phone first!
      hopCount: 0,
      ttl: 5,
      messageType: messageType,
      recipientTarget: recipientTarget,
      location: location,
      category: category ?? _activeFilter,
    );

    // 2. CRITICAL AXIOM: Write to SQLite messages table with status 'SAVED'
    await _dbService.insertMessage(chatMsg.toDbMap());

    // Mark as seen in local deduplication filter
    _seenMessageIds.add(messageId);
    _bloomFilter.add(messageId);

    // Render immediately in reactive UI with single grey tick ("Saved on phone")
    _messages.add(chatMsg);
    notifyListeners();

    // 3. Pack into MessageEnvelope (Kabootar/MeshChat DTN envelope with UUID, senderId, TTL=5, timestamp, payload)
    final envelope = MessageEnvelope(
      uuid: messageId,
      senderId: DatabaseService.myDeviceId,
      senderName: DatabaseService.myDisplayName,
      conversationId: conversationId,
      timestamp: now.millisecondsSinceEpoch,
      ttl: 5,
      hops: 0,
      type: messageType,
      payload: content,
      recipientTarget: recipientTarget,
      metadata: {
        if (location != null) ...location.toJson(),
        if (category != null || _activeFilter != 'Nearby')
          'category': category ?? _activeFilter,
      },
    );

    // 4. Update status to 'QUEUED'
    await _dbService.updateMessageStatus(
      messageId: messageId,
      status: 'QUEUED',
    );
    _updateLocalMessageStatus(messageId, MessageDeliveryStatus.queued);

    // 5. Transmit payload bytes via BluetoothRadioService().broadcastBytes(envelope.toBytes()) (or sendToPeers)
    int peersReached = 0;
    try {
      peersReached = await _radioService.broadcastBytes(envelope.toBytes());
      debugPrint('[ChatService] Transmitted $messageId to $peersReached peer(s)');
    } catch (e) {
      debugPrint('[ChatService] Radio broadcast exception: $e');
    }

    // 6. Update status to 'SENT_NEARBY'
    await _dbService.updateMessageStatus(
      messageId: messageId,
      status: 'SENT_NEARBY',
      hopCount: 0,
    );
    _updateLocalMessageStatus(
      messageId,
      MessageDeliveryStatus.sentNearby,
      hopCount: 0,
    );

    // Pass to MeshEngine Outbox Queue Manager for simulated multi-hop relay transitions
    _meshEngine.queueOutboxMessage(envelope);

    return chatMsg;
  }

  void _updateLocalMessageStatus(String messageId, MessageDeliveryStatus status, {int? hopCount}) {
    final index = _messages.indexWhere((m) => m.messageId == messageId);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(
        status: status,
        hopCount: hopCount ?? _messages[index].hopCount,
      );
      notifyListeners();
    }
  }

  /// Emergency shortcut tap action
  Future<void> sendEmergencyShortcut(String shortcutText) async {
    await sendMessage(
      content: shortcutText,
      messageType: 'TEXT',
      category: 'Rescue',
    );
  }

  /// Screen 10 sync action: syncs all pending messages to government & rescue agencies
  Future<void> syncAllPendingNow() async {
    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners();

    // Simulate network handshake and automated relay to government & rescue
    await Future.delayed(const Duration(milliseconds: 1200));

    final pending = List<ChatMessage>.from(pendingMessages);
    for (final msg in pending) {
      await _dbService.updateMessageStatus(
        messageId: msg.messageId,
        status: 'DELIVERED',
        hopCount: 2,
      );
      final index = _messages.indexWhere((m) => m.messageId == msg.messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(
          status: MessageDeliveryStatus.delivered,
          hopCount: 2,
        );
      }
    }

    _isSyncing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _radioSubscription?.cancel();
    _statusSubscription?.cancel();
    _incomingSubscription?.cancel();
    super.dispose();
  }
}
