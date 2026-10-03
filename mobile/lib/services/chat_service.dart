import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../models/message_envelope.dart';
import 'bluetooth_radio_service.dart';
import 'database_service.dart';
import 'media_storage_service.dart';
import 'mesh_engine.dart';

/// Chat Service with Save-Before-Send guarantee
/// Source of truth: SQLite database.
/// Provides reactive state for Screen 5 (Community Chat) and Screen 10 (My Messages).
class ChatService extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final BluetoothRadioService _radioService = BluetoothRadioService();
  final MeshEngine _meshEngine = MeshEngine();
  final MediaStorageService _mediaStorage = MediaStorageService();
  final Uuid _uuid = const Uuid();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String _activeFilter = 'Nearby'; // 'Nearby', 'Group', 'Rescue', 'Saved'
  bool _isSyncing = false;

  // Deduplication structures (Bloom filter + in-memory Set)
  final BloomFilter _bloomFilter = BloomFilter();
  final Set<String> _seenMessageIds = <String>{};

  StreamSubscription<ChatMessage>? _statusSubscription;
  StreamSubscription<MessageEnvelope>? _incomingSubscription;
  StreamSubscription<IncomingMediaPayload>? _mediaSubscription;
  late final Future<void> _initialization;

  List<ChatMessage> get allMessages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String get activeFilter => _activeFilter;
  int get onlineDevices => _radioService.connectedCount;
  bool get isSyncing => _isSyncing;

  ChatService() {
    _initialization = _initialize();
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

    // 1. MeshEngine is the only radio consumer. A second listener used to
    // persist and forward every packet twice, creating duplicate broadcasts.
    // Listen only to the durable mesh events here.
    _statusSubscription = _meshEngine.messageStatusUpdates.listen((updatedMsg) {
      final index = _messages.indexWhere(
        (m) => m.messageId == updatedMsg.messageId,
      );
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(
          status: updatedMsg.status,
          hopCount: updatedMsg.hopCount,
        );
        notifyListeners();
      }
    });

    // 2. Listen to incoming envelopes from mesh engine
    _incomingSubscription = _meshEngine.incomingEnvelopes.listen((envelope) {
      _loadMessagesFromDb();
    });
    _mediaSubscription = _radioService.incomingMediaStream.listen(
      _handleIncomingMedia,
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadMessagesFromDb() async {
    _messages = await _dbService.getAllMessages();
    notifyListeners();
  }

  Future<void> _handleIncomingMedia(IncomingMediaPayload incoming) async {
    try {
      final envelope = MessageEnvelope.fromJson(incoming.envelope);
      final destination = await _mediaStorage.createDestination(
        incoming.fileName,
      );
      final copied = await _radioService.persistIncomingMedia(
        incoming.sourceUri,
        destination,
      );
      if (!copied) {
        throw StateError(
          'The received image could not be saved on this phone.',
        );
      }
      await _meshEngine.receiveMediaPacket(
        envelope,
        MediaAttachment(
          localPath: destination,
          fileName: incoming.fileName,
          mimeType: incoming.mimeType,
          byteLength: incoming.byteLength,
        ),
      );
    } catch (error) {
      debugPrint('[ChatService] Incoming media was not saved: $error');
    }
  }

  void setActiveFilter(String filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  /// Messages for Screen 5 (Community Chat filtered by selected tab)
  List<ChatMessage> get communityMessages {
    final list = _messages
        .where(
          (m) =>
              m.conversationId == 'CONV_COMMUNITY' ||
              m.conversationId == 'COMMUNITY_MESH' ||
              m.conversationId == 'community' ||
              m.conversationId == 'global_emergency' ||
              m.conversationId.isEmpty,
        )
        .toList();

    if (_activeFilter == 'Nearby') {
      return list;
    } else if (_activeFilter == 'Group') {
      return list
          .where((m) => m.category == 'Group' || m.messageType == 'GROUP')
          .toList();
    } else if (_activeFilter == 'Rescue') {
      return list
          .where(
            (m) =>
                m.content.toLowerCase().contains('help') ||
                m.content.toLowerCase().contains('safe') ||
                m.content.toLowerCase().contains('blocked') ||
                m.content.toLowerCase().contains('sos') ||
                m.messageType == 'SOS' ||
                m.messageType == 'LOCATION' ||
                (m.category != null &&
                    m.category!.toLowerCase().contains('rescue')),
          )
          .toList();
    } else if (_activeFilter == 'Saved') {
      return list
          .where((m) => m.status == MessageDeliveryStatus.saved || m.isMine)
          .toList();
    }
    return list;
  }

  /// Pending messages for Screen 10 (items with status SAVED or QUEUED waiting for sync)
  List<ChatMessage> get pendingMessages {
    return _messages
        .where(
          (m) =>
              m.status == MessageDeliveryStatus.saved ||
              m.status == MessageDeliveryStatus.queued,
        )
        .toList();
  }

  /// Sent messages for Screen 10
  List<ChatMessage> get sentMessages {
    return _messages
        .where(
          (m) =>
              m.isMine &&
              m.status != MessageDeliveryStatus.saved &&
              m.status != MessageDeliveryStatus.queued,
        )
        .toList();
  }

  /// Received messages for Screen 10
  List<ChatMessage> get receivedMessages {
    return _messages.where((m) => !m.isMine).toList();
  }

  /// Save-Before-Send Guarantee:
  /// Writes message record to SQLite with status 'SAVED' BEFORE any network attempt.
  Future<ChatMessage> sendMessage({
    required String content,
    String? messageId,
    String conversationId = 'CONV_COMMUNITY',
    String messageType = 'TEXT',
    String? category,
    String? recipientTarget,
    LocationPreview? location,
    MediaAttachment? attachment,
    Map<String, dynamic>? metadata,
  }) async {
    await _initialization;
    final now = DateTime.now();
    final resolvedMessageId =
        messageId ?? 'MSG-${_uuid.v4().substring(0, 8).toUpperCase()}';

    // 1. Construct local chat message object with status SAVED (Single grey tick)
    final chatMsg = ChatMessage(
      messageId: resolvedMessageId,
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
      attachment: attachment,
    );

    // 2. CRITICAL AXIOM: Write to SQLite messages table with status 'SAVED'
    await _dbService.insertMessage(chatMsg.toDbMap());

    // Mark as seen in local deduplication filter
    _seenMessageIds.add(resolvedMessageId);
    _bloomFilter.add(resolvedMessageId);

    // Render immediately in reactive UI with single grey tick ("Saved on phone")
    _messages.add(chatMsg);
    notifyListeners();

    // 3. Pack into MessageEnvelope (Kabootar/MeshChat DTN envelope with UUID, senderId, TTL=5, timestamp, payload)
    final envelope = MessageEnvelope(
      uuid: resolvedMessageId,
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
        ...?metadata,
        if (location != null) ...location.toJson(),
        if (attachment != null) ...{
          'attachment_name': attachment.fileName,
          'attachment_mime_type': attachment.mimeType,
          'attachment_bytes': attachment.byteLength,
        },
        if (category != null || _activeFilter != 'Nearby')
          'category': category ?? _activeFilter,
      },
    );

    // 4. Update status to 'QUEUED'
    await _dbService.updateMessageStatus(
      messageId: resolvedMessageId,
      status: 'QUEUED',
    );
    _updateLocalMessageStatus(resolvedMessageId, MessageDeliveryStatus.queued);

    // 5. MeshEngine owns the one physical send path and advances the durable
    // status only after Nearby Connections accepts a peer payload.
    _meshEngine.queueOutboxMessage(
      envelope,
      attachmentPath: attachment?.localPath,
    );

    return chatMsg;
  }

  void _updateLocalMessageStatus(
    String messageId,
    MessageDeliveryStatus status, {
    int? hopCount,
  }) {
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

  Future<ChatMessage> sendImage(String sourcePath) async {
    await _initialization;
    final attachment = await _mediaStorage.stageImage(sourcePath);
    return sendMessage(
      content: 'Image: ${attachment.fileName}',
      messageType: 'IMAGE',
      attachment: attachment,
    );
  }

  /// Retries pending durable outbox items when the user requests a mesh sync.
  Future<void> syncAllPendingNow() async {
    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners();
    try {
      await _initialization;
      await _meshEngine.syncAllPendingMessages();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Stops background mesh timers (for test harness)
  void stopTimers() {
    _meshEngine.stopTimers();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _incomingSubscription?.cancel();
    _mediaSubscription?.cancel();
    super.dispose();
  }
}
