class MeshMessage {
  final String messageId;
  final String conversationId;
  final String senderDeviceId;
  final String senderName;
  final String content;
  final int createdAt;
  final String status; // 'SAVED', 'SENT_TO_NEARBY', 'RELAYED', 'DELIVERED', 'FAILED'
  final int hopCount;
  final int ttl;

  const MeshMessage({
    required this.messageId,
    required this.conversationId,
    required this.senderDeviceId,
    required this.senderName,
    required this.content,
    required this.createdAt,
    this.status = 'SAVED',
    this.hopCount = 0,
    this.ttl = 5,
  });

  MeshMessage copyWith({
    String? messageId,
    String? conversationId,
    String? senderDeviceId,
    String? senderName,
    String? content,
    int? createdAt,
    String? status,
    int? hopCount,
    int? ttl,
  }) {
    return MeshMessage(
      messageId: messageId ?? this.messageId,
      conversationId: conversationId ?? this.conversationId,
      senderDeviceId: senderDeviceId ?? this.senderDeviceId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      hopCount: hopCount ?? this.hopCount,
      ttl: ttl ?? this.ttl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'conversationId': conversationId,
      'senderDeviceId': senderDeviceId,
      'senderName': senderName,
      'content': content,
      'createdAt': createdAt,
      'status': status,
      'hopCount': hopCount,
      'ttl': ttl,
    };
  }

  factory MeshMessage.fromMap(Map<String, dynamic> map) {
    return MeshMessage(
      messageId: map['messageId'] as String? ?? '',
      conversationId: map['conversationId'] as String? ?? '',
      senderDeviceId: map['senderDeviceId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? '',
      content: map['content'] as String? ?? '',
      createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
      status: map['status'] as String? ?? 'SAVED',
      hopCount: (map['hopCount'] as num?)?.toInt() ?? 0,
      ttl: (map['ttl'] as num?)?.toInt() ?? 5,
    );
  }
}
