import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../models/message_envelope.dart';
import 'database_service.dart';
import 'mesh_engine.dart';

/// Chat Service with Save-Before-Send guarantee
/// Source of truth: SQLite database.
/// Provides reactive state for Screen 5 (Community Chat) and Screen 10 (My Messages).
class ChatService extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final MeshEngine _meshEngine = MeshEngine();
  final Uuid _uuid = const Uuid();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String _activeFilter = 'Nearby'; // 'Nearby', 'Group', 'Rescue', 'Saved'
  final int _onlineDevices = 24;
  bool _isSyncing = false;

  StreamSubscription<ChatMessage>? _statusSubscription;
  StreamSubscription<MessageEnvelope>? _incomingSubscription;

  List<ChatMessage> get allMessages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String get activeFilter => _activeFilter;
  int get onlineDevices => _onlineDevices;
  bool get isSyncing => _isSyncing;

  ChatService() {
    _initialize();
  }

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    await _meshEngine.initialize();
    await _loadMessagesFromDb();

    // Listen to real-time outbox status updates (SAVED -> QUEUED -> SENT_NEARBY -> RELAYED -> DELIVERED)
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

    // Listen to incoming packets from mesh
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

  void setActiveFilter(String filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  /// Messages for Screen 5 (Community Chat filtered by selected tab)
  List<ChatMessage> get communityMessages {
    final list = _messages.where((m) => m.conversationId == 'CONV_COMMUNITY').toList();
    if (_activeFilter == 'Nearby') {
      return list;
    } else if (_activeFilter == 'Group') {
      return list.where((m) => m.category == 'Group' || m.messageType == 'GROUP').toList();
    } else if (_activeFilter == 'Rescue') {
      return list.where((m) =>
          m.content.toLowerCase().contains('help') ||
          m.content.toLowerCase().contains('safe') ||
          m.content.toLowerCase().contains('blocked') ||
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

    // 2. CRITICAL AXIOM: Write to SQLite BEFORE any network broadcast attempt!
    await _dbService.insertMessage(chatMsg.toDbMap());

    // 3. Render immediately in reactive UI with single grey tick ("Saved on phone")
    _messages.add(chatMsg);
    notifyListeners();

    // 4. Pass to MeshEngine Outbox Queue Manager for delay-tolerant BLE broadcast
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
      metadata: location?.toJson(),
    );

    _meshEngine.queueOutboxMessage(envelope);

    return chatMsg;
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
    _statusSubscription?.cancel();
    _incomingSubscription?.cancel();
    super.dispose();
  }
}
