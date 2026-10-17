import 'dart:convert';
import 'dart:typed_data';

/// RakshaNet Delay-Tolerant Message Envelope
///
/// Encapsulates delay-tolerant mesh network packets based on Kabootar & MeshChat specs:
/// - UUID: Globally unique packet identifier.
/// - Sender details: senderId, senderName.
/// - Routing: conversationId, TTL (Time-To-Live default 5), hops (hop count default 0).
/// - Payload: message content / structured payload.
/// - Checksum: integrity verification for radio packet payload.
class MessageEnvelope {
  final String uuid;
  final String senderId;
  final String senderName;
  final String conversationId;
  final int timestamp; // Milliseconds since epoch
  final int ttl; // Default 10 (configurable max hop limit)
  final int hops; // Default 0
  final String type; // 'TEXT', 'LOCATION', 'SOS', 'REPORT', 'RELAY_ACK', 'DELIVERY_ACK'
  final String payload;
  final String? recipientTarget; // 'Nearby devices', 'Rescue Team', 'Government'
  final String? recipientUserId; // Recipient user email for targeted delivery
  final String? recipientDeviceId; // Recipient device ID for targeted delivery
  final Map<String, dynamic>? metadata;
  final String? checksum;

  static int defaultMaxHops = 10;

  const MessageEnvelope({
    required this.uuid,
    required this.senderId,
    required this.senderName,
    required this.conversationId,
    required this.timestamp,
    this.ttl = 10,
    this.hops = 0,
    this.type = 'TEXT',
    required this.payload,
    this.recipientTarget,
    this.recipientUserId,
    this.recipientDeviceId,
    this.metadata,
    this.checksum,
  });

  String get messageId => uuid;
  int get hopCount => hops;

  /// Serializes envelope to JSON map (supporting compact protocol keys ver, msg_id, conv_id, etc.)
  Map<String, dynamic> toJson() {
    return {
      'ver': 1,
      'msg_id': uuid,
      'sender_id': senderId,
      'sender_name': senderName,
      'conv_id': conversationId,
      'ts': timestamp,
      'ttl': ttl,
      'hops': hops,
      'type': type,
      'payload': payload,
      if (recipientTarget != null) 'recipient_target': recipientTarget,
      if (recipientUserId != null) 'recipient_user_id': recipientUserId,
      if (recipientDeviceId != null) 'recipient_device_id': recipientDeviceId,
      if (metadata != null) 'meta': metadata,
      if (checksum != null) 'chk': checksum,
    };
  }

  /// Deserializes envelope from JSON map
  factory MessageEnvelope.fromJson(Map<String, dynamic> json) {
    return MessageEnvelope(
      uuid: (json['msg_id'] ?? json['uuid'] ?? json['id'] ?? '') as String,
      senderId: (json['sender_id'] ?? json['senderId'] ?? '') as String,
      senderName:
          (json['sender_name'] ?? json['senderName'] ?? 'Unknown') as String,
      conversationId:
          (json['conv_id'] ?? json['conversationId'] ?? 'CONV_COMMUNITY')
              as String,
      timestamp:
          (json['ts'] ?? json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch)
              as int,
      ttl: (json['ttl'] as num?)?.toInt() ?? 10,
      hops: (json['hops'] as num?)?.toInt() ?? 0,
      type: (json['type'] ?? 'TEXT') as String,
      payload: (json['payload'] ?? json['content'] ?? '') as String,
      recipientTarget:
          (json['recipient_target'] ?? json['recipientTarget']) as String?,
      recipientUserId:
          (json['recipient_user_id'] ??
                  json['recipientUserId'] ??
                  json['meta']?['recipient_user_id'])
              as String?,
      recipientDeviceId:
          (json['recipient_device_id'] ??
                  json['recipientDeviceId'] ??
                  json['meta']?['recipient_device_id'])
              as String?,
      metadata: json['meta'] != null
          ? Map<String, dynamic>.from(json['meta'] as Map)
          : null,
      checksum: (json['chk'] ?? json['checksum']) as String?,
    );
  }

  /// Creates a copy with decremented TTL and incremented hops for downstream relay
  MessageEnvelope copyForRelay() {
    return MessageEnvelope(
      uuid: uuid,
      senderId: senderId,
      senderName: senderName,
      conversationId: conversationId,
      timestamp: timestamp,
      ttl: ttl - 1,
      hops: hops + 1,
      type: type,
      payload: payload,
      recipientTarget: recipientTarget,
      recipientUserId: recipientUserId,
      recipientDeviceId: recipientDeviceId,
      metadata: metadata != null ? Map<String, dynamic>.from(metadata!) : null,
      checksum: checksum,
    );
  }

  MessageEnvelope copyWith({
    String? uuid,
    String? senderId,
    String? senderName,
    String? conversationId,
    int? timestamp,
    int? ttl,
    int? hops,
    String? type,
    String? payload,
    String? recipientTarget,
    String? recipientUserId,
    String? recipientDeviceId,
    Map<String, dynamic>? metadata,
    String? checksum,
  }) {
    return MessageEnvelope(
      uuid: uuid ?? this.uuid,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      conversationId: conversationId ?? this.conversationId,
      timestamp: timestamp ?? this.timestamp,
      ttl: ttl ?? this.ttl,
      hops: hops ?? this.hops,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      recipientTarget: recipientTarget ?? this.recipientTarget,
      recipientUserId: recipientUserId ?? this.recipientUserId,
      recipientDeviceId: recipientDeviceId ?? this.recipientDeviceId,
      metadata: metadata ?? this.metadata,
      checksum: checksum ?? this.checksum,
    );
  }

  String encode() => jsonEncode(toJson());

  static MessageEnvelope decode(String jsonStr) =>
      MessageEnvelope.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);

  Uint8List toBytes() => Uint8List.fromList(utf8.encode(encode()));

  static MessageEnvelope fromBytes(Uint8List bytes) =>
      MessageEnvelope.decode(utf8.decode(bytes));

  static MessageEnvelope? tryFromBytes(Uint8List bytes) {
    try {
      return MessageEnvelope.fromBytes(bytes);
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() =>
      'MessageEnvelope(uuid: $uuid, hops: $hops, ttl: $ttl, sender: $senderName, payload: "$payload")';
}
