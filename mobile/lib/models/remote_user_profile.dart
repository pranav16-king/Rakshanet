import 'chat_group.dart';
import 'chat_message.dart';
import 'mesh_device.dart';

/// Public, locally observed peer information. It intentionally excludes the
/// hardware identifier, private contacts, medical data, and precise location.
class RemoteUserProfile {
  const RemoteUserProfile({
    required this.userId,
    required this.displayName,
    required this.source,
    this.isNearby = false,
    this.isDirectlyConnected = false,
    this.lastSeen,
  });

  final String userId;
  final String displayName;
  final String source;
  final bool isNearby;
  final bool isDirectlyConnected;
  final DateTime? lastSeen;

  factory RemoteUserProfile.fromMessage(ChatMessage message) =>
      RemoteUserProfile(
        userId: message.senderId,
        displayName: message.senderName.trim().isEmpty
            ? 'RakshaNet user'
            : message.senderName.trim(),
        source: 'Community chat',
      );

  factory RemoteUserProfile.fromGroupMember(GroupMember member) =>
      RemoteUserProfile(
        userId: member.deviceId,
        displayName: _cleanName(member.name),
        source: 'Mesh group',
        lastSeen: member.joinedAt,
      );

  factory RemoteUserProfile.fromMeshDevice(MeshDevice device) =>
      RemoteUserProfile(
        userId: device.deviceId,
        displayName: device.displayName.trim().isEmpty
            ? 'Nearby RakshaNet user'
            : device.displayName.trim(),
        source: 'Nearby mesh',
        isNearby: true,
        isDirectlyConnected: device.isConnected,
        lastSeen: device.lastSeen,
      );

  String get initials {
    final words = displayName.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return '?';
    final first = words.first[0];
    final second = words.length > 1 && words[1].isNotEmpty ? words[1][0] : '';
    return '$first$second'.toUpperCase();
  }

  static String _cleanName(String name) => name
      .replaceAll(RegExp(r'\s*\(.*?\)\s*'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}
