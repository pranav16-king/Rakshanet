import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../models/chat_group.dart';
import '../models/chat_message.dart';
import '../models/message_envelope.dart';
import 'chat_service.dart';
import 'database_service.dart';
import 'mesh_engine.dart';

class GroupService extends ChangeNotifier {
  static final GroupService _instance = GroupService._internal();
  factory GroupService() => _instance;
  GroupService._internal() {
    _initListener();
    _initializeGroupsAndInvites();
  }

  static const String _prefSeededInvitesKey = 'rakshanet_seeded_mesh_invites_v2';

  final MeshEngine _meshEngine = MeshEngine();
  final DatabaseService _dbService = DatabaseService();
  final Uuid _uuid = const Uuid();

  List<ChatGroup> _groups = [];
  List<GroupInvite> _pendingInvites = [];
  List<GroupInvite> _respondedInvites = [];
  String? _selectedGroupId;
  bool _isLoading = false;

  List<ChatGroup> get groups => List.unmodifiable(_groups);
  List<GroupInvite> get pendingInvites => List.unmodifiable(_pendingInvites);
  List<GroupInvite> get respondedInvites => List.unmodifiable(_respondedInvites);
  int get pendingInviteCount => _pendingInvites.length;
  String? get selectedGroupId => _selectedGroupId;
  bool get isLoading => _isLoading;

  ChatGroup? get selectedGroup {
    if (_selectedGroupId == null) return null;
    try {
      return _groups.firstWhere((g) => g.id == _selectedGroupId);
    } catch (_) {
      return null;
    }
  }

  StreamSubscription<MessageEnvelope>? _envelopeSub;

  Future<void> _initializeGroupsAndInvites() async {
    await _ensureDefaultMeshInvitesSeeded();
    await loadGroups();
    await loadPendingInvites();
  }

  /// Ensures initial mesh responder group invitations exist on first run so
  /// Accept / Reject group invite workflows work even before a second BLE peer pairs.
  Future<void> _ensureDefaultMeshInvitesSeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadySeeded = prefs.getBool(_prefSeededInvitesKey) ?? false;
      final existingAll = await AppDatabase.instance.query('group_invites');
      if (alreadySeeded || existingAll.isNotEmpty) return;

      final now = DateTime.now();
      final myDeviceId = DatabaseService.myDeviceId;

      final seedInvites = [
        GroupInvite(
          id: 'INV-NDRF-SEC4',
          groupId: 'GRP-NDRF04',
          groupName: 'NDRF Sector-4 Relief Squad',
          inviterId: 'SR-NDRF-HQ01',
          inviterName: 'Cmdr. Rajesh Verma (NDRF)',
          inviteeDeviceId: myDeviceId,
          status: GroupMemberStatus.pending,
          sentAt: now.subtract(const Duration(minutes: 12)),
        ),
        GroupInvite(
          id: 'INV-MED-RELAY',
          groupId: 'GRP-MEDRLY',
          groupName: 'Medical & Triage Mesh Relay',
          inviterId: 'SR-MED-0842',
          inviterName: 'Dr. Priya Nair (Field Triage)',
          inviteeDeviceId: myDeviceId,
          status: GroupMemberStatus.pending,
          sentAt: now.subtract(const Duration(minutes: 28)),
        ),
      ];

      for (final inv in seedInvites) {
        await AppDatabase.instance.insert(
          'group_invites',
          inv.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await prefs.setBool(_prefSeededInvitesKey, true);
    } catch (e) {
      debugPrint('[GroupService] Seed mesh invites warning: $e');
    }
  }

  void _initListener() {
    _envelopeSub = _meshEngine.incomingEnvelopes.listen((env) async {
      if (env.type == 'GROUP_INVITE') {
        await _handleIncomingInvite(env);
      } else if (env.type == 'GROUP_INVITE_RESPONSE') {
        await _handleIncomingResponse(env);
      }
    });
  }

  void selectGroup(String? groupId) {
    _selectedGroupId = groupId;
    final grp = selectedGroup;
    ChatService().setActiveGroupConversation(grp?.conversationId);
    notifyListeners();
  }

  Future<void> loadGroups() async {
    try {
      final rows = await AppDatabase.instance.query(
        'groups',
        orderBy: 'updated_at DESC',
      );
      final loaded = <ChatGroup>[];
      for (final r in rows) {
        final baseGroup = ChatGroup.fromMap(r);
        final memberRows = await AppDatabase.instance.query(
          'group_members',
          where: 'group_id = ?',
          whereArgs: [baseGroup.id],
          orderBy: 'invited_at ASC',
        );
        final members = memberRows.map((m) => GroupMember.fromMap(m)).toList();
        final acceptedCount = members
            .where((m) => m.status == GroupMemberStatus.accepted)
            .length;
        loaded.add(
          ChatGroup(
            id: baseGroup.id,
            name: baseGroup.name,
            description: baseGroup.description,
            creatorId: baseGroup.creatorId,
            createdAt: baseGroup.createdAt,
            updatedAt: baseGroup.updatedAt,
            conversationId: baseGroup.conversationId,
            memberCount: acceptedCount > 0 ? acceptedCount : baseGroup.memberCount,
            members: members,
          ),
        );
      }
      _groups = loaded;

      // Keep selectedGroupId valid and sync with ChatService
      if (_selectedGroupId != null &&
          !_groups.any((g) => g.id == _selectedGroupId)) {
        _selectedGroupId = _groups.isNotEmpty ? _groups.first.id : null;
      }
      ChatService().setActiveGroupConversation(selectedGroup?.conversationId);

      notifyListeners();
    } catch (e) {
      debugPrint('[GroupService] loadGroups error: $e');
    }
  }

  Future<void> loadPendingInvites() async {
    try {
      final pendingRows = await AppDatabase.instance.query(
        'group_invites',
        where: 'status = ?',
        whereArgs: ['PENDING'],
        orderBy: 'sent_at DESC',
      );
      _pendingInvites = pendingRows.map((r) => GroupInvite.fromMap(r)).toList();

      final allRows = await AppDatabase.instance.query(
        'group_invites',
        orderBy: 'sent_at DESC',
      );
      _respondedInvites = allRows
          .map((r) => GroupInvite.fromMap(r))
          .where((inv) => inv.status != GroupMemberStatus.pending)
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('[GroupService] loadPendingInvites error: $e');
    }
  }

  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    final rows = await AppDatabase.instance.query(
      'group_members',
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'invited_at ASC',
    );
    return rows.map((r) => GroupMember.fromMap(r)).toList();
  }

  /// Creates a new mesh group, adds self as ACCEPTED, adds any invited peers as PENDING,
  /// writes a welcome message into the group's chat, and broadcasts GROUP_INVITE packets.
  Future<ChatGroup> createGroup(
    String name, {
    String? description,
    List<String> inviteeDeviceIds = const [],
    Map<String, String> inviteeNamesById = const {},
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final groupId = 'GRP-${_uuid.v4().substring(0, 8).toUpperCase()}';
      final conversationId = 'CONV_$groupId';
      final myDeviceId = DatabaseService.myDeviceId;
      final myName = DatabaseService.myDisplayName;
      final cleanName = name.trim();
      final cleanDesc = description?.trim();

      final group = ChatGroup(
        id: groupId,
        name: cleanName,
        description: cleanDesc,
        creatorId: myDeviceId,
        createdAt: now,
        updatedAt: now,
        conversationId: conversationId,
        memberCount: 1,
      );

      // 1. Save group to SQLite
      await AppDatabase.instance.insert(
        'groups',
        group.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Save self as accepted member
      final selfMember = GroupMember(
        id: 'MEM-${groupId}_SELF',
        groupId: groupId,
        deviceId: myDeviceId,
        name: '$myName (You • Admin)',
        status: GroupMemberStatus.accepted,
        invitedAt: now,
        joinedAt: now,
      );
      await AppDatabase.instance.insert(
        'group_members',
        selfMember.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 3. Save invited peers as PENDING members in group_members so creator can see & manage them
      for (final peerId in inviteeDeviceIds) {
        final peerName = inviteeNamesById[peerId] ?? peerId;
        final pendingMember = GroupMember(
          id: 'MEM-${groupId}_${peerId.hashCode.abs()}',
          groupId: groupId,
          deviceId: peerId,
          name: peerName,
          status: GroupMemberStatus.pending,
          invitedAt: now,
        );
        await AppDatabase.instance.insert(
          'group_members',
          pendingMember.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // 4. Create conversation entry for group chat
      await AppDatabase.instance.insert(
        'conversations',
        {
          'id': 'conv_$groupId',
          'conversation_id': conversationId,
          'type': 'GROUP',
          'title': cleanName,
          'created_at': now.millisecondsSinceEpoch,
          'updated_at': now.millisecondsSinceEpoch,
          'last_message': 'Group "$cleanName" created by $myName',
          'unread_count': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 5. Insert welcome system message into group's conversation so chat is ready
      final welcomeMsg = ChatMessage(
        messageId: 'MSG-WELCOME-$groupId',
        conversationId: conversationId,
        senderId: myDeviceId,
        senderName: myName,
        isMine: true,
        content: cleanDesc != null && cleanDesc.isNotEmpty
            ? '🛡️ Created mesh group "$cleanName" ($groupId) — $cleanDesc'
            : '🛡️ Created mesh group "$cleanName" ($groupId). Share group code $groupId or invite nearby peers.',
        timestamp: now,
        status: MessageDeliveryStatus.saved,
        hopCount: 0,
        ttl: 5,
        messageType: 'GROUP',
        category: 'Group',
      );
      await _dbService.insertMessage(welcomeMsg.toDbMap());

      // 6. Send invitations to selected peers over the mesh (or broadcast if none specified)
      final targets = inviteeDeviceIds.isNotEmpty ? inviteeDeviceIds : ['ALL'];
      for (final peerId in targets) {
        final inviteEnvelope = MessageEnvelope(
          uuid: 'INV-${_uuid.v4().substring(0, 8).toUpperCase()}',
          senderId: myDeviceId,
          senderName: myName,
          conversationId: conversationId,
          timestamp: now.millisecondsSinceEpoch,
          ttl: 5,
          hops: 0,
          type: 'GROUP_INVITE',
          payload: 'Invitation to join $cleanName',
          recipientTarget: peerId,
          recipientDeviceId: peerId == 'ALL' ? null : peerId,
          metadata: {
            'group_id': groupId,
            'group_name': cleanName,
            'group_description': cleanDesc ?? '',
            'inviter_id': myDeviceId,
            'inviter_name': myName,
            'invitee_device_id': peerId,
          },
        );
        _meshEngine.queueOutboxMessage(inviteEnvelope);
      }

      await loadGroups();
      selectGroup(groupId);
      await ChatService().reloadMessages();

      _isLoading = false;
      notifyListeners();
      return selectedGroup ?? group;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Accept or Reject (Decline) a group invitation.
  /// Works for pending invites AND allows re-accepting a previously declined invite.
  Future<void> respondToInvite(GroupInvite invite, bool accept) async {
    final now = DateTime.now();
    final newStatus =
        accept ? GroupMemberStatus.accepted : GroupMemberStatus.rejected;

    // 1. Update invite status in SQLite
    await AppDatabase.instance.update(
      'group_invites',
      {
        'status': newStatus.name.toUpperCase(),
        'responded_at': now.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [invite.id],
    );

    if (accept) {
      final conversationId = 'CONV_${invite.groupId}';
      final myDeviceId = DatabaseService.myDeviceId;
      final myName = DatabaseService.myDisplayName;

      // 2. Add/update group locally with ConflictAlgorithm.replace
      final group = ChatGroup(
        id: invite.groupId,
        name: invite.groupName,
        description: 'Invited by ${invite.inviterName}',
        creatorId: invite.inviterId,
        createdAt: invite.sentAt,
        updatedAt: now,
        conversationId: conversationId,
        memberCount: 2,
      );
      await AppDatabase.instance.insert(
        'groups',
        group.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 3. Add inviter as accepted member
      final inviterMember = GroupMember(
        id: 'MEM-${invite.groupId}_INVITER',
        groupId: invite.groupId,
        deviceId: invite.inviterId,
        name: '${invite.inviterName} (Admin)',
        status: GroupMemberStatus.accepted,
        invitedAt: invite.sentAt,
        joinedAt: invite.sentAt,
      );
      await AppDatabase.instance.insert(
        'group_members',
        inviterMember.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 4. Add self as accepted member
      final selfMember = GroupMember(
        id: 'MEM-${invite.groupId}_SELF',
        groupId: invite.groupId,
        deviceId: myDeviceId,
        name: '$myName (You)',
        status: GroupMemberStatus.accepted,
        invitedAt: invite.sentAt,
        joinedAt: now,
      );
      await AppDatabase.instance.insert(
        'group_members',
        selfMember.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 5. Add conversation with ConflictAlgorithm.replace
      await AppDatabase.instance.insert(
        'conversations',
        {
          'id': 'conv_${invite.groupId}',
          'conversation_id': conversationId,
          'type': 'GROUP',
          'title': invite.groupName,
          'created_at': now.millisecondsSinceEpoch,
          'updated_at': now.millisecondsSinceEpoch,
          'last_message': 'You accepted the invite and joined ${invite.groupName}',
          'unread_count': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 6. Add join confirmation message into the group's chat feed
      final joinMsg = ChatMessage(
        messageId: 'MSG-JOIN-${invite.groupId}-${now.millisecondsSinceEpoch}',
        conversationId: conversationId,
        senderId: invite.inviterId,
        senderName: invite.inviterName,
        isMine: false,
        content:
            '✅ $myName accepted the invitation and joined "${invite.groupName}". Mesh group channel is active.',
        timestamp: now,
        status: MessageDeliveryStatus.delivered,
        hopCount: 1,
        ttl: 5,
        messageType: 'GROUP',
        category: 'Group',
      );
      await _dbService.insertMessage(joinMsg.toDbMap());
    }

    // 7. Send response packet over the mesh back to the inviter
    final responseEnvelope = MessageEnvelope(
      uuid: 'RSP-${_uuid.v4().substring(0, 8).toUpperCase()}',
      senderId: DatabaseService.myDeviceId,
      senderName: DatabaseService.myDisplayName,
      conversationId: 'CONV_${invite.groupId}',
      timestamp: now.millisecondsSinceEpoch,
      ttl: 5,
      hops: 0,
      type: 'GROUP_INVITE_RESPONSE',
      payload: accept ? 'ACCEPTED' : 'REJECTED',
      recipientTarget: invite.inviterId,
      recipientDeviceId: invite.inviterId,
      metadata: {
        'group_id': invite.groupId,
        'invitee_device_id': DatabaseService.myDeviceId,
        'invitee_name': DatabaseService.myDisplayName,
        'status': accept ? 'ACCEPTED' : 'REJECTED',
      },
    );
    _meshEngine.queueOutboxMessage(responseEnvelope);

    await loadPendingInvites();
    await loadGroups();
    if (accept) {
      selectGroup(invite.groupId);
      ChatService().setActiveFilter('Group');
      await ChatService().reloadMessages();
    }
  }

  /// Adds/invites a member to an existing group (or simulates a join request)
  Future<void> addMemberToGroup({
    required String groupId,
    required String peerId,
    required String peerName,
    bool asPendingRequest = false,
  }) async {
    final now = DateTime.now();
    final status =
        asPendingRequest ? GroupMemberStatus.pending : GroupMemberStatus.accepted;
    final member = GroupMember(
      id: 'MEM-${groupId}_${peerId.hashCode.abs()}',
      groupId: groupId,
      deviceId: peerId,
      name: peerName.trim().isNotEmpty ? peerName.trim() : peerId,
      status: status,
      invitedAt: now,
      joinedAt: asPendingRequest ? null : now,
    );
    await AppDatabase.instance.insert(
      'group_members',
      member.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final grp = _groups.where((g) => g.id == groupId).firstOrNull;
    if (grp != null) {
      final inviteEnvelope = MessageEnvelope(
        uuid: 'INV-${_uuid.v4().substring(0, 8).toUpperCase()}',
        senderId: DatabaseService.myDeviceId,
        senderName: DatabaseService.myDisplayName,
        conversationId: grp.conversationId,
        timestamp: now.millisecondsSinceEpoch,
        ttl: 5,
        hops: 0,
        type: 'GROUP_INVITE',
        payload: 'Invitation to join ${grp.name}',
        recipientTarget: peerId,
        recipientDeviceId: peerId,
        metadata: {
          'group_id': groupId,
          'group_name': grp.name,
          'inviter_id': DatabaseService.myDeviceId,
          'inviter_name': DatabaseService.myDisplayName,
          'invitee_device_id': peerId,
        },
      );
      _meshEngine.queueOutboxMessage(inviteEnvelope);
    }

    await _recalculateGroupMemberCount(groupId);
    await loadGroups();
  }

  /// Accept or Reject a pending member inside a group's Member Management sheet
  Future<void> updateMemberStatus({
    required String memberId,
    required String groupId,
    required bool accept,
  }) async {
    final now = DateTime.now();
    if (accept) {
      await AppDatabase.instance.update(
        'group_members',
        {
          'status': 'ACCEPTED',
          'joined_at': now.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [memberId],
      );
    } else {
      await AppDatabase.instance.update(
        'group_members',
        {
          'status': 'REJECTED',
        },
        where: 'id = ?',
        whereArgs: [memberId],
      );
    }
    await _recalculateGroupMemberCount(groupId);
    await loadGroups();
  }

  Future<void> _recalculateGroupMemberCount(String groupId) async {
    final members = await getGroupMembers(groupId);
    final acceptedCount = members
        .where((m) => m.status == GroupMemberStatus.accepted)
        .length;
    await AppDatabase.instance.update(
      'groups',
      {
        'member_count': acceptedCount > 0 ? acceptedCount : 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [groupId],
    );
  }

  /// Join a group directly using a Group Code / Name
  Future<ChatGroup> joinGroupByCode({
    required String groupCodeOrName,
    String? inviterName,
  }) async {
    final clean = groupCodeOrName.trim();
    final now = DateTime.now();
    final isCode = clean.toUpperCase().startsWith('GRP-');
    final groupId = isCode
        ? clean.toUpperCase()
        : 'GRP-${clean.hashCode.abs().toString().padLeft(6, '0').substring(0, 6)}';
    final groupName = isCode ? 'Mesh Group ($groupId)' : clean;

    final syntheticInvite = GroupInvite(
      id: 'INV-CODE-${groupId.hashCode.abs()}',
      groupId: groupId,
      groupName: groupName,
      inviterId: 'MESH-BEACON',
      inviterName: inviterName ?? 'Mesh Relay Coordinator',
      inviteeDeviceId: DatabaseService.myDeviceId,
      status: GroupMemberStatus.pending,
      sentAt: now,
    );

    await AppDatabase.instance.insert(
      'group_invites',
      syntheticInvite.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await respondToInvite(syntheticInvite, true);
    return _groups.firstWhere((g) => g.id == groupId);
  }

  /// Creates/discovers a new incoming group invitation so the user can test
  /// accepting or rejecting mesh group invitations at any time.
  Future<GroupInvite> createIncomingMeshInvite({
    String? groupName,
    String? inviterName,
  }) async {
    final now = DateTime.now();
    final shortCode = _uuid.v4().substring(0, 6).toUpperCase();
    final groupId = 'GRP-$shortCode';
    final resolvedGroupName =
        (groupName != null && groupName.trim().isNotEmpty)
            ? groupName.trim()
            : 'Rescue Coordination Unit #$shortCode';
    final resolvedInviter =
        (inviterName != null && inviterName.trim().isNotEmpty)
            ? inviterName.trim()
            : 'Field Responder Relay ($shortCode)';

    final invite = GroupInvite(
      id: 'INV-$shortCode',
      groupId: groupId,
      groupName: resolvedGroupName,
      inviterId: 'SR-$shortCode',
      inviterName: resolvedInviter,
      inviteeDeviceId: DatabaseService.myDeviceId,
      status: GroupMemberStatus.pending,
      sentAt: now,
    );

    await AppDatabase.instance.insert(
      'group_invites',
      invite.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await loadPendingInvites();
    return invite;
  }

  /// Leaves or deletes a group and cleans up its membership records
  Future<void> deleteOrLeaveGroup(String groupId) async {
    await AppDatabase.instance.delete(
      'groups',
      where: 'id = ?',
      whereArgs: [groupId],
    );
    await AppDatabase.instance.delete(
      'group_members',
      where: 'group_id = ?',
      whereArgs: [groupId],
    );
    if (_selectedGroupId == groupId) {
      _selectedGroupId = null;
    }
    await loadGroups();
  }

  Future<void> _handleIncomingInvite(MessageEnvelope env) async {
    final meta = env.metadata;
    if (meta == null) return;
    final groupId = meta['group_id']?.toString() ?? '';
    if (groupId.isEmpty) return;
    final groupName = meta['group_name']?.toString() ?? 'Emergency Group';
    final inviterId = meta['inviter_id']?.toString() ?? env.senderId;
    final inviterName = meta['inviter_name']?.toString() ?? env.senderName;
    final targetDevice = meta['invitee_device_id']?.toString() ?? '';

    // Ignore our own outgoing invites
    if (inviterId == DatabaseService.myDeviceId) return;

    // Accept if broadcast ('ALL' or empty) or targeted to this device
    if (targetDevice.isNotEmpty &&
        targetDevice != 'ALL' &&
        targetDevice != DatabaseService.myDeviceId) {
      return;
    }

    final invite = GroupInvite(
      id: env.uuid.isNotEmpty
          ? env.uuid
          : 'INV-${_uuid.v4().substring(0, 8).toUpperCase()}',
      groupId: groupId,
      groupName: groupName,
      inviterId: inviterId,
      inviterName: inviterName,
      inviteeDeviceId: DatabaseService.myDeviceId,
      status: GroupMemberStatus.pending,
      sentAt: DateTime.fromMillisecondsSinceEpoch(env.timestamp),
    );
    await AppDatabase.instance.insert(
      'group_invites',
      invite.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await loadPendingInvites();
  }

  Future<void> _handleIncomingResponse(MessageEnvelope env) async {
    final meta = env.metadata;
    if (meta == null) return;
    final groupId = meta['group_id']?.toString() ?? '';
    if (groupId.isEmpty) return;
    final statusStr = (meta['status']?.toString() ?? env.payload).toUpperCase();
    final isAccepted = statusStr == 'ACCEPTED';
    final peerId = meta['invitee_device_id']?.toString() ?? env.senderId;
    final peerName = meta['invitee_name']?.toString() ?? env.senderName;

    await AppDatabase.instance.insert(
      'group_members',
      {
        'id': 'MEM-${groupId}_${peerId.hashCode.abs()}',
        'group_id': groupId,
        'member_device_id': peerId,
        'member_name': peerName,
        'status': isAccepted ? 'ACCEPTED' : 'REJECTED',
        'joined_at': isAccepted ? DateTime.now().millisecondsSinceEpoch : null,
        'invited_at': env.timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await _recalculateGroupMemberCount(groupId);
    await loadGroups();
  }

  @override
  void dispose() {
    _envelopeSub?.cancel();
    super.dispose();
  }
}
