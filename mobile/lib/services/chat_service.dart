import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../models/message_envelope.dart';
import 'bluetooth_radio_service.dart';
import 'database_service.dart';
import 'media_storage_service.dart';
import 'mesh_engine.dart';

/// Chat Service with Save-Before-Send guarantee
/// Source of truth: SQLite database.
/// Provides reactive state for Screen 5 (Community Chat & Mesh Groups) and Screen 10 (My Messages).
class ChatService extends ChangeNotifier {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;

  final DatabaseService _dbService = DatabaseService();
  final BluetoothRadioService _radioService = BluetoothRadioService();
  final MeshEngine _meshEngine = MeshEngine();
  final MediaStorageService _mediaStorage = MediaStorageService();
  final Uuid _uuid = const Uuid();

  static const String _prefBookmarksKey = 'rakshanet_bookmarked_messages';
  static const String _prefBlockedUsersKey = 'blocked_peer_ids';

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String _activeFilter = 'Nearby'; // 'Nearby', 'Group', 'Rescue', 'Saved'
  String? _activeGroupConversationId; // e.g., 'CONV_GRP-XXXX' when a specific group is selected
  String? _activeDirectConversationId; // e.g., 'DIRECT_<peerId>' when in 1:1 chat
  String _searchQuery = '';
  final Set<String> _bookmarkedMessageIds = <String>{};
  final Set<String> _blockedUserIds = <String>{};
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
  String? get activeGroupConversationId => _activeGroupConversationId;
  String? get activeDirectConversationId => _activeDirectConversationId;
  String get searchQuery => _searchQuery;
  Set<String> get bookmarkedMessageIds =>
      Set.unmodifiable(_bookmarkedMessageIds);
  Set<String> get blockedUserIds =>
      Set.unmodifiable(_blockedUserIds);
  int get onlineDevices => _radioService.connectedCount;
  bool get isSyncing => _isSyncing;

  ChatService._internal() {
    _initialization = _initialize();
  }

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    await _loadBookmarks();
    await _loadBlockedUsers();
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

    // 1. MeshEngine is the only radio consumer.
    _statusSubscription = _meshEngine.statusUpdates.listen((updatedMsg) {
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

  Future<void> _loadBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_prefBookmarksKey) ?? const <String>[];
      _bookmarkedMessageIds
        ..clear()
        ..addAll(saved);
    } catch (e) {
      debugPrint('[ChatService] Failed to load bookmarks: $e');
    }
  }

  Future<void> _loadBlockedUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_prefBlockedUsersKey) ?? const <String>[];
      _blockedUserIds
        ..clear()
        ..addAll(saved);
    } catch (e) {
      debugPrint('[ChatService] Failed to load blocked users: $e');
    }
  }

  Future<void> reloadBlockedUsers() async {
    await _loadBlockedUsers();
    notifyListeners();
  }

  bool isUserBlocked(String userId) => _blockedUserIds.contains(userId);

  Future<bool> toggleBlockUser(String userId) async {
    final bool blocked;
    if (_blockedUserIds.contains(userId)) {
      _blockedUserIds.remove(userId);
      blocked = false;
    } else {
      _blockedUserIds.add(userId);
      blocked = true;
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _prefBlockedUsersKey,
        _blockedUserIds.toList(),
      );
    } catch (e) {
      debugPrint('[ChatService] Failed to persist blocked users: $e');
    }
    return blocked;
  }

  Future<void> _persistBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _prefBookmarksKey,
        _bookmarkedMessageIds.toList(),
      );
    } catch (e) {
      debugPrint('[ChatService] Failed to persist bookmarks: $e');
    }
  }

  bool isBookmarked(String messageId) =>
      _bookmarkedMessageIds.contains(messageId);

  Future<bool> toggleBookmark(String messageId) async {
    final bool added;
    if (_bookmarkedMessageIds.contains(messageId)) {
      _bookmarkedMessageIds.remove(messageId);
      added = false;
    } else {
      _bookmarkedMessageIds.add(messageId);
      added = true;
    }
    notifyListeners();
    await _persistBookmarks();
    return added;
  }

  Future<void> _loadMessagesFromDb() async {
    _messages = await _dbService.getAllMessages();
    notifyListeners();
  }

  /// Public reload helper for GroupService / external updates
  Future<void> reloadMessages() async {
    await _loadMessagesFromDb();
  }

  Future<void> deleteMessage(String messageId) async {
    await _dbService.deleteMessage(messageId);
    _messages.removeWhere((m) => m.messageId == messageId);
    _bookmarkedMessageIds.remove(messageId);
    notifyListeners();
    await _persistBookmarks();
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

  void setActiveGroupConversation(String? conversationId) {
    _activeGroupConversationId = conversationId;
    notifyListeners();
  }

  void setActiveDirectConversation(String? conversationId) {
    _activeDirectConversationId = conversationId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  bool _matchesSearch(ChatMessage m) {
    if (_searchQuery.isEmpty) return true;
    final q = _searchQuery.toLowerCase();
    return m.content.toLowerCase().contains(q) ||
        m.senderName.toLowerCase().contains(q) ||
        (m.location?.title.toLowerCase().contains(q) ?? false) ||
        (m.category?.toLowerCase().contains(q) ?? false);
  }

  /// Messages for Screen 5 (Community Chat filtered by selected tab & search query)
  List<ChatMessage> get communityMessages {
    List<ChatMessage> filtered;

    if (_activeDirectConversationId != null &&
        _activeDirectConversationId!.isNotEmpty) {
      final peerId = _activeDirectConversationId!.startsWith('DIRECT_')
          ? _activeDirectConversationId!.substring(7)
          : _activeDirectConversationId!;
      filtered = _messages
          .where(
            (m) =>
                !_blockedUserIds.contains(m.senderId) &&
                (m.conversationId == _activeDirectConversationId ||
                    (m.recipientTarget == peerId && m.isMine) ||
                    (m.senderId == peerId &&
                        (m.recipientTarget == DatabaseService.myDeviceId ||
                            m.recipientTarget == null))),
          )
          .toList();
    } else if (_activeFilter == 'Group') {
      if (_activeGroupConversationId != null &&
          _activeGroupConversationId!.isNotEmpty) {
        filtered = _messages
            .where(
              (m) =>
                  !_blockedUserIds.contains(m.senderId) &&
                  m.conversationId == _activeGroupConversationId,
            )
            .toList();
      } else {
        filtered = _messages
            .where(
              (m) =>
                  !_blockedUserIds.contains(m.senderId) &&
                  (m.conversationId.startsWith('CONV_GRP-') ||
                      m.category == 'Group' ||
                      m.messageType == 'GROUP'),
            )
            .toList();
      }
    } else if (_activeFilter == 'Rescue') {
      filtered = _messages
          .where(
            (m) =>
                !_blockedUserIds.contains(m.senderId) &&
                (m.content.toLowerCase().contains('help') ||
                    m.content.toLowerCase().contains('safe') ||
                    m.content.toLowerCase().contains('blocked') ||
                    m.content.toLowerCase().contains('water') ||
                    m.content.toLowerCase().contains('trapped') ||
                    m.content.toLowerCase().contains('sos') ||
                    m.messageType == 'SOS' ||
                    m.messageType == 'LOCATION' ||
                    (m.category != null &&
                        m.category!.toLowerCase().contains('rescue'))),
          )
          .toList();
    } else if (_activeFilter == 'Saved') {
      filtered = _messages
          .where(
            (m) =>
                !_blockedUserIds.contains(m.senderId) &&
                (_bookmarkedMessageIds.contains(m.messageId) ||
                    m.status == MessageDeliveryStatus.saved),
          )
          .toList();
    } else {
      // 'Nearby' tab: community broadcast + general mesh messages (excluding direct chat messages)
      filtered = _messages
          .where(
            (m) =>
                !_blockedUserIds.contains(m.senderId) &&
                !m.conversationId.startsWith('DIRECT_') &&
                (m.conversationId == 'CONV_COMMUNITY' ||
                    m.conversationId == 'COMMUNITY_MESH' ||
                    m.conversationId == 'community' ||
                    m.conversationId == 'global_emergency' ||
                    m.conversationId.isEmpty),
          )
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where(_matchesSearch).toList();
    }
    return filtered;
  }

  /// Resolves the target conversationId based on the current tab & selected group
  String get currentTargetConversationId {
    if (_activeDirectConversationId != null &&
        _activeDirectConversationId!.isNotEmpty) {
      return _activeDirectConversationId!;
    }
    if (_activeFilter == 'Group' &&
        _activeGroupConversationId != null &&
        _activeGroupConversationId!.isNotEmpty) {
      return _activeGroupConversationId!;
    }
    return 'CONV_COMMUNITY';
  }

  /// Pending messages for Screen 10 (items with status SAVED or QUEUED waiting for sync)
  List<ChatMessage> get pendingMessages {
    return _messages
        .where(
          (m) =>
              !_blockedUserIds.contains(m.senderId) &&
              (m.status == MessageDeliveryStatus.saved ||
                  m.status == MessageDeliveryStatus.queued),
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
    return _messages
        .where((m) => !m.isMine && !_blockedUserIds.contains(m.senderId))
        .toList();
  }

  /// Save-Before-Send Guarantee:
  /// Writes message record to SQLite with status 'SAVED' BEFORE any network attempt.
  Future<ChatMessage> sendMessage({
    required String content,
    String? messageId,
    String? senderName,
    String? conversationId,
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
    final resolvedConversationId =
        conversationId ?? currentTargetConversationId;
    final resolvedSenderName = senderName ?? DatabaseService.myDisplayName;
    final isDirect = resolvedConversationId.startsWith('DIRECT_');
    final directPeer = isDirect ? resolvedConversationId.substring(7) : null;
    final resolvedRecipientTarget = recipientTarget ?? directPeer;
    final resolvedCategory =
        category ??
        (isDirect
            ? 'Nearby'
            : (resolvedConversationId.startsWith('CONV_GRP-')
                ? 'Group'
                : _activeFilter));

    // 1. Construct local chat message object with status SAVED (Single grey tick)
    final chatMsg = ChatMessage(
      messageId: resolvedMessageId,
      conversationId: resolvedConversationId,
      senderId: DatabaseService.myDeviceId,
      senderName: resolvedSenderName,
      isMine: true,
      content: content,
      timestamp: now,
      status: MessageDeliveryStatus.saved, // Saved on phone first!
      hopCount: 0,
      ttl: 5,
      messageType: messageType,
      recipientTarget: resolvedRecipientTarget,
      location: location,
      category: resolvedCategory,
      attachment: attachment,
    );

    // 2. CRITICAL AXIOM: Write to SQLite messages table with status 'SAVED'
    await _dbService.insertMessage(chatMsg.toDbMap());

    // If user is on the 'Saved' tab when sending, also bookmark it automatically
    if (_activeFilter == 'Saved') {
      _bookmarkedMessageIds.add(resolvedMessageId);
      _persistBookmarks().ignore();
    }

    // Mark as seen in local deduplication filter
    _seenMessageIds.add(resolvedMessageId);
    _bloomFilter.add(resolvedMessageId);

    // Render immediately in reactive UI with single grey tick ("Saved on phone")
    _messages.add(chatMsg);
    notifyListeners();

    // 3. Pack into MessageEnvelope
    final envelope = MessageEnvelope(
      uuid: resolvedMessageId,
      senderId: DatabaseService.myDeviceId,
      senderName: resolvedSenderName,
      conversationId: resolvedConversationId,
      timestamp: now.millisecondsSinceEpoch,
      ttl: 5,
      hops: 0,
      type: messageType,
      payload: content,
      recipientTarget: resolvedRecipientTarget,
      metadata: {
        ...?metadata,
        if (location != null) ...location.toJson(),
        if (attachment != null) ...{
          'attachment_name': attachment.fileName,
          'attachment_mime_type': attachment.mimeType,
          'attachment_bytes': attachment.byteLength,
        },
        'category': resolvedCategory,
      },
    );

    // 4. Update status to 'QUEUED'
    await _dbService.updateMessageStatus(
      messageId: resolvedMessageId,
      status: 'QUEUED',
    );
    _updateLocalMessageStatus(resolvedMessageId, MessageDeliveryStatus.queued);

    // 5. MeshEngine owns the one physical send path
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
      category: _activeFilter == 'Group' ? 'Group' : 'Rescue',
    );
  }

  /// Sends an offline voice note message with duration metadata
  Future<ChatMessage> sendVoiceNote(
    int durationSeconds, {
    String? conversationId,
    String? recipientTarget,
    String? category,
  }) async {
    final mins = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (durationSeconds % 60).toString().padLeft(2, '0');
    return sendMessage(
      content: '🎤 Offline Voice Note ($mins:$secs)',
      messageType: 'VOICE',
      conversationId: conversationId,
      recipientTarget: recipientTarget,
      category: category,
      metadata: {'voice_duration_sec': durationSeconds},
    );
  }

  Future<ChatMessage> sendImage(String sourcePath) async {
    await _initialization;
    final attachment = await _mediaStorage.stageImage(sourcePath);
    return sendMessage(
      content: '📷 Image: ${attachment.fileName}',
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
      await _meshEngine.uploadQueuedPacketsToGateway();
      await _loadMessagesFromDb();
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
