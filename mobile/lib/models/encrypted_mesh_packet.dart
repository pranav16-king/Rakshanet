import 'delivery_state.dart';

/// Represents a store-and-forward encrypted mesh packet in SQLite.
class EncryptedMeshPacket {
  final String messageId;
  final String senderDeviceId;
  final String? recipientUserId;
  final String? recipientDeviceId;
  final String routingHeaderJson;
  final String encryptedPayloadJson;
  final MeshDeliveryState status;
  final int hopCount;
  final int ttl;
  final int createdAt;
  final int expiresAt;

  const EncryptedMeshPacket({
    required this.messageId,
    required this.senderDeviceId,
    this.recipientUserId,
    this.recipientDeviceId,
    required this.routingHeaderJson,
    required this.encryptedPayloadJson,
    this.status = MeshDeliveryState.saved,
    this.hopCount = 0,
    this.ttl = 5,
    required this.createdAt,
    required this.expiresAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'message_id': messageId,
      'sender_device_id': senderDeviceId,
      'recipient_user_id': recipientUserId,
      'recipient_device_id': recipientDeviceId,
      'routing_header_json': routingHeaderJson,
      'encrypted_payload_json': encryptedPayloadJson,
      'status': status.toDbString(),
      'hop_count': hopCount,
      'ttl': ttl,
      'created_at': createdAt,
      'expires_at': expiresAt,
    };
  }

  factory EncryptedMeshPacket.fromMap(Map<String, dynamic> map) {
    return EncryptedMeshPacket(
      messageId: (map['message_id'] ?? map['messageId'] ?? '') as String,
      senderDeviceId: (map['sender_device_id'] ?? map['senderDeviceId'] ?? '') as String,
      recipientUserId: (map['recipient_user_id'] ?? map['recipientUserId']) as String?,
      recipientDeviceId: (map['recipient_device_id'] ?? map['recipientDeviceId']) as String?,
      routingHeaderJson: (map['routing_header_json'] ?? map['routingHeaderJson'] ?? '{}') as String,
      encryptedPayloadJson: (map['encrypted_payload_json'] ?? map['encryptedPayloadJson'] ?? '{}') as String,
      status: MeshDeliveryState.fromString(map['status'] as String?),
      hopCount: (map['hop_count'] ?? map['hopCount'] as num?)?.toInt() ?? 0,
      ttl: (map['ttl'] as num?)?.toInt() ?? 5,
      createdAt: (map['created_at'] ?? map['createdAt'] as num?)?.toInt() ?? 0,
      expiresAt: (map['expires_at'] ?? map['expiresAt'] as num?)?.toInt() ?? 0,
    );
  }

  EncryptedMeshPacket copyWith({
    String? messageId,
    String? senderDeviceId,
    String? recipientUserId,
    String? recipientDeviceId,
    String? routingHeaderJson,
    String? encryptedPayloadJson,
    MeshDeliveryState? status,
    int? hopCount,
    int? ttl,
    int? createdAt,
    int? expiresAt,
  }) {
    return EncryptedMeshPacket(
      messageId: messageId ?? this.messageId,
      senderDeviceId: senderDeviceId ?? this.senderDeviceId,
      recipientUserId: recipientUserId ?? this.recipientUserId,
      recipientDeviceId: recipientDeviceId ?? this.recipientDeviceId,
      routingHeaderJson: routingHeaderJson ?? this.routingHeaderJson,
      encryptedPayloadJson: encryptedPayloadJson ?? this.encryptedPayloadJson,
      status: status ?? this.status,
      hopCount: hopCount ?? this.hopCount,
      ttl: ttl ?? this.ttl,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
