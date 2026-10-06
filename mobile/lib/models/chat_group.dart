/// Chat group, group member, and group invite models for RakshaNet mesh groups.
library;

class ChatGroup {
  final String id;
  final String name;
  final String? description;
  final String creatorId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String conversationId;
  final int memberCount;
  final List<GroupMember> members;

  const ChatGroup({
    required this.id,
    required this.name,
    this.description,
    required this.creatorId,
    required this.createdAt,
    required this.updatedAt,
    required this.conversationId,
    this.memberCount = 1,
    this.members = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'creator_id': creatorId,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'conversation_id': conversationId,
        'member_count': memberCount,
      };

  factory ChatGroup.fromMap(Map<String, dynamic> map) => ChatGroup(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        creatorId: map['creator_id'] as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt:
            DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
        conversationId: map['conversation_id'] as String,
        memberCount: (map['member_count'] as int?) ?? 1,
      );
}

enum GroupMemberStatus { pending, accepted, rejected }

class GroupMember {
  final String id;
  final String groupId;
  final String deviceId;
  final String name;
  final GroupMemberStatus status;
  final DateTime invitedAt;
  final DateTime? joinedAt;

  const GroupMember({
    required this.id,
    required this.groupId,
    required this.deviceId,
    required this.name,
    this.status = GroupMemberStatus.pending,
    required this.invitedAt,
    this.joinedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'group_id': groupId,
        'member_device_id': deviceId,
        'member_name': name,
        'status': status.name.toUpperCase(),
        'joined_at': joinedAt?.millisecondsSinceEpoch,
        'invited_at': invitedAt.millisecondsSinceEpoch,
      };

  factory GroupMember.fromMap(Map<String, dynamic> map) => GroupMember(
        id: map['id'] as String,
        groupId: map['group_id'] as String,
        deviceId: map['member_device_id'] as String,
        name: map['member_name'] as String,
        status: GroupMemberStatus.values.firstWhere(
          (s) =>
              s.name.toUpperCase() ==
              (map['status'] as String? ?? 'PENDING'),
          orElse: () => GroupMemberStatus.pending,
        ),
        invitedAt:
            DateTime.fromMillisecondsSinceEpoch(map['invited_at'] as int),
        joinedAt: map['joined_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['joined_at'] as int)
            : null,
      );
}

class GroupInvite {
  final String id;
  final String groupId;
  final String groupName;
  final String inviterId;
  final String inviterName;
  final String inviteeDeviceId;
  final GroupMemberStatus status;
  final DateTime sentAt;
  final DateTime? respondedAt;

  const GroupInvite({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.inviterId,
    required this.inviterName,
    required this.inviteeDeviceId,
    this.status = GroupMemberStatus.pending,
    required this.sentAt,
    this.respondedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'group_id': groupId,
        'group_name': groupName,
        'inviter_id': inviterId,
        'inviter_name': inviterName,
        'invitee_device_id': inviteeDeviceId,
        'status': status.name.toUpperCase(),
        'sent_at': sentAt.millisecondsSinceEpoch,
        'responded_at': respondedAt?.millisecondsSinceEpoch,
      };

  factory GroupInvite.fromMap(Map<String, dynamic> map) => GroupInvite(
        id: map['id'] as String,
        groupId: map['group_id'] as String,
        groupName: map['group_name'] as String,
        inviterId: map['inviter_id'] as String,
        inviterName: map['inviter_name'] as String,
        inviteeDeviceId: map['invitee_device_id'] as String,
        status: GroupMemberStatus.values.firstWhere(
          (s) =>
              s.name.toUpperCase() ==
              (map['status'] as String? ?? 'PENDING'),
          orElse: () => GroupMemberStatus.pending,
        ),
        sentAt: DateTime.fromMillisecondsSinceEpoch(map['sent_at'] as int),
        respondedAt: map['responded_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                map['responded_at'] as int)
            : null,
      );
}
