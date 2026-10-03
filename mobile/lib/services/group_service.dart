import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../models/chat_group.dart';
import '../models/message_envelope.dart';
import 'database_service.dart';
import 'mesh_engine.dart';

class GroupService extends ChangeNotifier {
  static final GroupService _instance = GroupService._internal();
  factory GroupService() => _instance;
  GroupService._internal() {
    _initListener();
    loadGroups();
    loadPendingInvites();
  }

  final MeshEngine _meshEngine = MeshEngine();
  final Uuid _uuid = const Uuid();

  List<ChatGroup> _groups = [];
  List<GroupInvite> _pendingInvites = [];
  bool _isLoading = false;

  List<ChatGroup> get groups => List.unmodifiable(_groups);
  List<GroupInvite> get pendingInvites => List.unmodifiable(_pendingInvites);
  int get pendingInviteCount => _pendingInvites.length;
  bool get isLoading => _isLoading;

  StreamSubscription<MessageEnvelope>? _envelopeSub;

  void _initListener() {
    _envelopeSub = _meshEngine.incomingEnvelopes.listen((env) async {
      if (env.type == 'GROUP_INVITE') {
        await _handleIncomingInvite(env);
      } else if (env.type == 'GROUP_INVITE_RESPONSE') {
        await _handleIncomingResponse(env);
      }
    });
  }

  Future<void> loadGroups() async {
    try {
      final rows = await AppDatabase.instance.query('groups', orderBy: 'updated_at DESC');
      _groups = rows.map((r) => ChatGroup.fromMap(r)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('[GroupService] loadGroups error: $e');
    }
  }

  Future<void> loadPendingInvites() async {
    try {
      final rows = await AppDatabase.instance.query(
        'group_invites',
        where: 'status = ?',
        whereArgs: ['PENDING'],
        orderBy: 'sent_at DESC',
      );
      _pendingInvites = rows.map((r) => GroupInvite.fromMap(r)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('[GroupService] loadPendingInvites error: $e');
    }
  }

  Future<ChatGroup> createGroup(
    String name, {
    String? description,
    List<String> inviteeDeviceIds = const [],
  }) async {
    _isLoading = true;
    notifyListeners();

    final now = DateTime.now();
    final groupId = 'GRP-${_uuid.v4().substring(0, 8).toUpperCase()}';
    final conversationId = 'CONV_$groupId';
    final myDeviceId = DatabaseService.myDeviceId;
    final myName = DatabaseService.myDisplayName;

    final group = ChatGroup(
      id: groupId,
      name: name.trim(),
      description: description?.trim(),
      creatorId: myDeviceId,
      createdAt: now,
      updatedAt: now,
      conversationId: conversationId,
      memberCount: 1 + inviteeDeviceIds.length,
    );

    // Save group to SQLite
    await AppDatabase.instance.insert('groups', group.toMap());

    // Save self as accepted member
    final selfMember = GroupMember(
      id: 'MEM-${_uuid.v4().substring(0, 8).toUpperCase()}',
      groupId: groupId,
      deviceId: myDeviceId,
      name: myName,
      status: GroupMemberStatus.accepted,
      invitedAt: now,
      joinedAt: now,
    );
    await AppDatabase.instance.insert('group_members', selfMember.toMap());

    // Create conversation entry for group chat
    await AppDatabase.instance.insert('conversations', {
      'id': 'conv_$groupId',
      'conversation_id': conversationId,
      'type': 'GROUP',
      'title': name.trim(),
      'created_at': now.millisecondsSinceEpoch,
      'updated_at': now.millisecondsSinceEpoch,
      'last_message': 'Group created by $myName',
      'unread_count': 0,
    });

    // Send invitations to selected peers over the mesh
    for (final peerId in inviteeDeviceIds) {
      final inviteEnvelope = MessageEnvelope(
        uuid: 'INV-${_uuid.v4().substring(0, 8).toUpperCase()}',
        senderId: myDeviceId,
        senderName: myName,
        conversationId: conversationId,
        timestamp: now.millisecondsSinceEpoch,
        ttl: 5,
        hops: 0,
        type: 'GROUP_INVITE',
        payload: 'Invitation to join ${name.trim()}',
        recipientTarget: peerId,
        metadata: {
          'group_id': groupId,
          'group_name': name.trim(),
          'inviter_id': myDeviceId,
          'inviter_name': myName,
          'invitee_device_id': peerId,
        },
      );
      _meshEngine.queueOutboxMessage(inviteEnvelope);
    }

    await loadGroups();
    _isLoading = false;
    notifyListeners();
    return group;
  }

  Future<void> respondToInvite(GroupInvite invite, bool accept) async {
    final now = DateTime.now();
    final newStatus = accept ? GroupMemberStatus.accepted : GroupMemberStatus.rejected;

    // Update invite status in SQLite
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
      // Add group locally
      final group = ChatGroup(
        id: invite.groupId,
        name: invite.groupName,
        creatorId: invite.inviterId,
        createdAt: now,
        updatedAt: now,
        conversationId: 'CONV_${invite.groupId}',
      );
      await AppDatabase.instance.insert('groups', group.toMap());

      // Add self as member
      final member = GroupMember(
        id: 'MEM-${_uuid.v4().substring(0, 8).toUpperCase()}',
        groupId: invite.groupId,
        deviceId: DatabaseService.myDeviceId,
        name: DatabaseService.myDisplayName,
        status: GroupMemberStatus.accepted,
        invitedAt: invite.sentAt,
        joinedAt: now,
      );
      await AppDatabase.instance.insert('group_members', member.toMap());

      // Add conversation
      await AppDatabase.instance.insert('conversations', {
        'id': 'conv_${invite.groupId}',
        'conversation_id': 'CONV_${invite.groupId}',
        'type': 'GROUP',
        'title': invite.groupName,
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
        'last_message': 'You joined the group',
        'unread_count': 0,
      });
    }

    // Send response packet over the mesh back to the inviter
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
  }

  Future<void> _handleIncomingInvite(MessageEnvelope env) async {
    final meta = env.metadata;
    if (meta == null) return;
    final groupId = meta['group_id']?.toString() ?? '';
    final groupName = meta['group_name']?.toString() ?? 'Emergency Group';
    final inviterId = meta['inviter_id']?.toString() ?? env.senderId;
    final inviterName = meta['inviter_name']?.toString() ?? env.senderName;
    final targetDevice = meta['invitee_device_id']?.toString() ?? '';

    // If invite is specifically for this device or broadcast
    if (targetDevice.isNotEmpty && targetDevice != DatabaseService.myDeviceId) {
      return;
    }

    // Check if invite already saved
    final existing = await AppDatabase.instance.query(
      'group_invites',
      where: 'group_id = ? AND status = ?',
      whereArgs: [groupId, 'PENDING'],
      limit: 1,
    );
    if (existing.isNotEmpty) return;

    final invite = GroupInvite(
      id: env.uuid,
      groupId: groupId,
      groupName: groupName,
      inviterId: inviterId,
      inviterName: inviterName,
      inviteeDeviceId: DatabaseService.myDeviceId,
      status: GroupMemberStatus.pending,
      sentAt: DateTime.fromMillisecondsSinceEpoch(env.timestamp),
    );
    await AppDatabase.instance.insert('group_invites', invite.toMap());
    await loadPendingInvites();
  }

  Future<void> _handleIncomingResponse(MessageEnvelope env) async {
    final meta = env.metadata;
    if (meta == null) return;
    final groupId = meta['group_id']?.toString() ?? '';
    final statusStr = meta['status']?.toString() ?? env.payload;
    final isAccepted = statusStr == 'ACCEPTED';
    final peerId = meta['invitee_device_id']?.toString() ?? env.senderId;
    final peerName = meta['invitee_name']?.toString() ?? env.senderName;

    if (isAccepted) {
      // Upsert member
      await AppDatabase.instance.insert('group_members', {
        'id': 'MEM-${peerId.hashCode.abs()}',
        'group_id': groupId,
        'member_device_id': peerId,
        'member_name': peerName,
        'status': 'ACCEPTED',
        'joined_at': DateTime.now().millisecondsSinceEpoch,
        'invited_at': env.timestamp,
      });

      // Update group member count
      final groups = await AppDatabase.instance.query(
        'groups',
        where: 'id = ?',
        whereArgs: [groupId],
        limit: 1,
      );
      if (groups.isNotEmpty) {
        final currentCount = (groups.first['member_count'] as int?) ?? 1;
        await AppDatabase.instance.update(
          'groups',
          {'member_count': currentCount + 1, 'updated_at': DateTime.now().millisecondsSinceEpoch},
          where: 'id = ?',
          whereArgs: [groupId],
        );
      }
      await loadGroups();
    }
  }

  @override
  void dispose() {
    _envelopeSub?.cancel();
    super.dispose();
  }
}
