class MeshPacket {
  final int ver;
  final String msgId;
  final String convId;
  final String senderId;
  final String senderName;
  final int ts;
  final int ttl;
  final int hops;
  final String payload;
  final String? recipientUserId;
  final String? recipientDeviceId;

  const MeshPacket({
    this.ver = 1,
    required this.msgId,
    required this.convId,
    required this.senderId,
    required this.senderName,
    required this.ts,
    required this.ttl,
    required this.hops,
    required this.payload,
    this.recipientUserId,
    this.recipientDeviceId,
  });

  MeshPacket copyWith({
    int? ver,
    String? msgId,
    String? convId,
    String? senderId,
    String? senderName,
    int? ts,
    int? ttl,
    int? hops,
    String? payload,
    String? recipientUserId,
    String? recipientDeviceId,
  }) {
    return MeshPacket(
      ver: ver ?? this.ver,
      msgId: msgId ?? this.msgId,
      convId: convId ?? this.convId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      ts: ts ?? this.ts,
      ttl: ttl ?? this.ttl,
      hops: hops ?? this.hops,
      payload: payload ?? this.payload,
      recipientUserId: recipientUserId ?? this.recipientUserId,
      recipientDeviceId: recipientDeviceId ?? this.recipientDeviceId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ver': ver,
      'msg_id': msgId,
      'conv_id': convId,
      'sender_id': senderId,
      'sender_name': senderName,
      'ts': ts,
      'ttl': ttl,
      'hops': hops,
      'payload': payload,
      if (recipientUserId != null) 'recipient_user_id': recipientUserId,
      if (recipientDeviceId != null) 'recipient_device_id': recipientDeviceId,
    };
  }

  factory MeshPacket.fromMap(Map<String, dynamic> map) {
    return MeshPacket(
      ver: (map['ver'] as num?)?.toInt() ?? 1,
      msgId: (map['msg_id'] ?? map['msgId']) as String? ?? '',
      convId: (map['conv_id'] ?? map['convId']) as String? ?? '',
      senderId: (map['sender_id'] ?? map['senderId']) as String? ?? '',
      senderName: (map['sender_name'] ?? map['senderName']) as String? ?? '',
      ts: (map['ts'] as num?)?.toInt() ?? 0,
      ttl: (map['ttl'] as num?)?.toInt() ?? 5,
      hops: (map['hops'] as num?)?.toInt() ?? 0,
      payload: (map['payload'] ?? map['content']) as String? ?? '',
      recipientUserId:
          (map['recipient_user_id'] ?? map['recipientUserId']) as String?,
      recipientDeviceId:
          (map['recipient_device_id'] ?? map['recipientDeviceId']) as String?,
    );
  }
}
