/// Conversation Thread / Channel
class Conversation {
  final String id;
  final String conversationId;
  final String type; // 'DIRECT', 'GROUP', 'BROADCAST', 'EMERGENCY'
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastMessage;
  final int unreadCount;

  const Conversation({
    required this.id,
    required this.conversationId,
    required this.type,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.unreadCount = 0,
  });

  Conversation copyWith({
    String? id,
    String? conversationId,
    String? type,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastMessage,
    int? unreadCount,
  }) {
    return Conversation(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      type: type ?? this.type,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'type': type,
      'title': title,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'last_message': lastMessage,
      'unread_count': unreadCount,
    };
  }

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id']?.toString() ?? '',
      conversationId: map['conversation_id']?.toString() ?? map['conversationId']?.toString() ?? map['id']?.toString() ?? '',
      type: map['type']?.toString() ?? 'BROADCAST',
      title: map['title']?.toString() ?? 'Emergency Channel',
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
          : DateTime.now(),
      lastMessage: map['last_message']?.toString(),
      unreadCount: map['unread_count'] is int
          ? map['unread_count'] as int
          : (int.tryParse(map['unread_count']?.toString() ?? '0') ?? 0),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation.fromMap(json);
}
