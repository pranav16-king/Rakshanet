import 'package:flutter/material.dart';

enum MessageDeliveryStatus {
  saved,
  queued,
  sending,
  sentNearby,
  relayed,
  delivered,
  failed,
}

typedef MessageStatus = MessageDeliveryStatus;

extension MessageDeliveryStatusExtension on MessageDeliveryStatus {
  String get label {
    switch (this) {
      case MessageDeliveryStatus.saved:
        return '✓ Saved on this phone';
      case MessageDeliveryStatus.queued:
      case MessageDeliveryStatus.sending:
        return 'Queued in outbox';
      case MessageDeliveryStatus.sentNearby:
        return 'Sent to nearby';
      case MessageDeliveryStatus.relayed:
        return 'Relayed';
      case MessageDeliveryStatus.delivered:
        return '✓ Reached recipient';
      case MessageDeliveryStatus.failed:
        return 'Failed';
    }
  }

  static MessageDeliveryStatus fromDynamic(dynamic val) {
    if (val is MessageDeliveryStatus) return val;
    if (val == null) return MessageDeliveryStatus.saved;
    final str = val.toString().trim().toUpperCase();
    switch (str) {
      case 'SAVED':
      case 'MESSAGEDELIVERYSTATUS.SAVED':
        return MessageDeliveryStatus.saved;
      case 'QUEUED':
      case 'MESSAGEDELIVERYSTATUS.QUEUED':
        return MessageDeliveryStatus.queued;
      case 'SENDING':
      case 'MESSAGEDELIVERYSTATUS.SENDING':
        return MessageDeliveryStatus.sending;
      case 'SENT_NEARBY':
      case 'SENTNEARBY':
      case 'MESSAGEDELIVERYSTATUS.SENTNEARBY':
        return MessageDeliveryStatus.sentNearby;
      case 'RELAYED':
      case 'MESSAGEDELIVERYSTATUS.RELAYED':
        return MessageDeliveryStatus.relayed;
      case 'DELIVERED':
      case 'MESSAGEDELIVERYSTATUS.DELIVERED':
        return MessageDeliveryStatus.delivered;
      case 'FAILED':
      case 'MESSAGEDELIVERYSTATUS.FAILED':
        return MessageDeliveryStatus.failed;
      default:
        return MessageDeliveryStatus.saved;
    }
  }
}

class LocationPreview {
  final String title;
  final String distance;
  final double? latitude;
  final double? longitude;

  const LocationPreview({
    required this.title,
    required this.distance,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'distance': distance,
    'latitude': latitude,
    'longitude': longitude,
  };

  Map<String, dynamic> toJson() => toMap();

  factory LocationPreview.fromMap(Map<String, dynamic> map) {
    return LocationPreview(
      title: map['title']?.toString() ?? 'Shared Location',
      distance: map['distance']?.toString() ?? '',
      latitude: map['latitude'] is num
          ? (map['latitude'] as num).toDouble()
          : null,
      longitude: map['longitude'] is num
          ? (map['longitude'] as num).toDouble()
          : null,
    );
  }

  factory LocationPreview.fromJson(Map<String, dynamic> json) =>
      LocationPreview.fromMap(json);
}

/// Metadata for an image held in the app's private offline storage.
class MediaAttachment {
  final String localPath;
  final String fileName;
  final String mimeType;
  final int byteLength;

  const MediaAttachment({
    required this.localPath,
    required this.fileName,
    required this.mimeType,
    required this.byteLength,
  });

  Map<String, dynamic> toMap() => {
    'attachment_path': localPath,
    'attachment_name': fileName,
    'attachment_mime_type': mimeType,
    'attachment_bytes': byteLength,
  };

  factory MediaAttachment.fromMap(Map<String, dynamic> map) => MediaAttachment(
    localPath: map['attachment_path']?.toString() ?? '',
    fileName: map['attachment_name']?.toString() ?? 'image',
    mimeType: map['attachment_mime_type']?.toString() ?? 'image/jpeg',
    byteLength: map['attachment_bytes'] is int
        ? map['attachment_bytes'] as int
        : int.tryParse(map['attachment_bytes']?.toString() ?? '0') ?? 0,
  );
}

/// Offline-First Chat / Emergency Message with Save-Before-Send guarantee
class ChatMessage {
  final String messageId;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final MessageDeliveryStatus status;
  final int hopCount;
  final int ttl;
  final bool isLocationShared;
  final double? _latitude;
  final double? _longitude;
  final bool _isOutgoing;
  final String messageType;
  final String? recipientTarget;
  final LocationPreview? location;
  final String? category;
  final String? proximity;
  final MediaAttachment? attachment;

  ChatMessage({
    String? id,
    String? messageId,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    DateTime? timestamp,
    DateTime? createdAt,
    dynamic status = MessageDeliveryStatus.saved,
    this.hopCount = 0,
    this.ttl = 5,
    bool? isOutgoing,
    bool? isMine,
    bool? isLocationShared,
    double? latitude,
    double? longitude,
    this.messageType = 'TEXT',
    this.recipientTarget,
    this.location,
    this.category,
    this.proximity,
    this.attachment,
  }) : messageId = messageId ?? id ?? '',
       timestamp = timestamp ?? createdAt ?? DateTime.now(),
       status = MessageDeliveryStatusExtension.fromDynamic(status),
       _latitude = latitude,
       _longitude = longitude,
       _isOutgoing =
           isOutgoing ??
           isMine ??
           (senderId == 'self' ||
               senderId == 'local_user' ||
               senderName == 'You'),
       isLocationShared =
           isLocationShared ??
           (location != null || latitude != null || longitude != null);

  String get id => messageId;
  DateTime get createdAt => timestamp;
  bool get isOutgoing => _isOutgoing;
  bool get isMine => _isOutgoing;
  double? get latitude => location?.latitude ?? _latitude;
  double? get longitude => location?.longitude ?? _longitude;

  bool get isSaved => status == MessageDeliveryStatus.saved;
  bool get isQueued => status == MessageDeliveryStatus.queued;
  bool get isSentNearby => status == MessageDeliveryStatus.sentNearby;
  bool get isRelayed => status == MessageDeliveryStatus.relayed;
  bool get isDelivered => status == MessageDeliveryStatus.delivered;
  bool get hasImageAttachment =>
      attachment != null && attachment!.mimeType.startsWith('image/');

  String get statusString => status.name.toUpperCase();

  String get formattedTime =>
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

  Widget buildStatusWidget([BuildContext? context]) {
    switch (status) {
      case MessageDeliveryStatus.saved:
      case MessageDeliveryStatus.queued:
      case MessageDeliveryStatus.sending:
        // 1 grey tick (saved locally)
        return const Icon(Icons.check, size: 14, color: Color(0xFF9E9E9E));
      case MessageDeliveryStatus.sentNearby:
      case MessageDeliveryStatus.relayed:
        // 2 teal ticks (sent to mesh)
        return const Icon(Icons.done_all, size: 14, color: Color(0xFF3CC6D0));
      case MessageDeliveryStatus.delivered:
        // 2 green ticks (delivered to rescue team/cloud)
        return const Icon(Icons.done_all, size: 14, color: Color(0xFF4CD08A));
      case MessageDeliveryStatus.failed:
        return const Icon(
          Icons.error_outline,
          size: 14,
          color: Color(0xFFFF5A4E),
        );
    }
  }

  ChatMessage copyWith({
    String? id,
    String? messageId,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? content,
    DateTime? timestamp,
    DateTime? createdAt,
    dynamic status,
    int? hopCount,
    int? ttl,
    bool? isOutgoing,
    bool? isMine,
    bool? isLocationShared,
    double? latitude,
    double? longitude,
    String? messageType,
    String? recipientTarget,
    LocationPreview? location,
    String? category,
    String? proximity,
    MediaAttachment? attachment,
  }) {
    return ChatMessage(
      id: id ?? messageId ?? this.messageId,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      timestamp: timestamp ?? createdAt ?? this.timestamp,
      status: status ?? this.status,
      hopCount: hopCount ?? this.hopCount,
      ttl: ttl ?? this.ttl,
      isOutgoing: isOutgoing ?? isMine ?? _isOutgoing,
      isLocationShared: isLocationShared ?? this.isLocationShared,
      latitude: latitude ?? _latitude,
      longitude: longitude ?? _longitude,
      messageType: messageType ?? this.messageType,
      recipientTarget: recipientTarget ?? this.recipientTarget,
      location: location ?? this.location,
      category: category ?? this.category,
      proximity: proximity ?? this.proximity,
      attachment: attachment ?? this.attachment,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message_id': messageId,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_name': senderName,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'created_at': timestamp.millisecondsSinceEpoch,
      'status': status.name.toUpperCase(),
      'hop_count': hopCount,
      'ttl': ttl,
      'is_location_shared': isLocationShared ? 1 : 0,
      'latitude': latitude,
      'longitude': longitude,
      'message_type': messageType,
      'recipient_target': recipientTarget,
      'category': category,
      'proximity': proximity,
      'location_title': location?.title,
      'location_distance': location?.distance,
      ...?attachment?.toMap(),
    };
  }

  Map<String, dynamic> toDbMap() => toMap();

  factory ChatMessage.fromMap(Map<String, dynamic> map, {String? myDeviceId}) {
    final sId =
        map['sender_id']?.toString() ?? map['senderId']?.toString() ?? '';
    final sName =
        map['sender_name']?.toString() ??
        map['senderName']?.toString() ??
        'Unknown';
    final isMine = myDeviceId != null
        ? (sId == myDeviceId)
        : (sId == 'self' || sId == 'local_user' || sName == 'You');

    LocationPreview? loc;
    if (map['location_title'] != null) {
      loc = LocationPreview(
        title: map['location_title'].toString(),
        distance: map['location_distance']?.toString() ?? '',
        latitude: map['latitude'] is num
            ? (map['latitude'] as num).toDouble()
            : null,
        longitude: map['longitude'] is num
            ? (map['longitude'] as num).toDouble()
            : null,
      );
    }
    final hasAttachment = map['attachment_path']?.toString().isNotEmpty == true;

    return ChatMessage(
      id:
          map['message_id']?.toString() ??
          map['messageId']?.toString() ??
          map['id']?.toString() ??
          '',
      conversationId:
          map['conversation_id']?.toString() ??
          map['conversationId']?.toString() ??
          'global_emergency',
      senderId: sId,
      senderName: sName,
      content: map['content']?.toString() ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
          : (map['created_at'] != null
                ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
                : DateTime.now()),
      status: MessageDeliveryStatusExtension.fromDynamic(map['status']),
      hopCount: map['hop_count'] is int
          ? map['hop_count'] as int
          : int.tryParse(map['hopCount']?.toString() ?? '0') ?? 0,
      ttl: map['ttl'] is int
          ? map['ttl'] as int
          : int.tryParse(map['ttl']?.toString() ?? '5') ?? 5,
      isOutgoing: isMine,
      isMine: isMine,
      isLocationShared:
          map['is_location_shared'] == 1 || map['is_location_shared'] == true,
      latitude: map['latitude'] is num
          ? (map['latitude'] as num).toDouble()
          : null,
      longitude: map['longitude'] is num
          ? (map['longitude'] as num).toDouble()
          : null,
      messageType:
          map['message_type']?.toString() ??
          map['messageType']?.toString() ??
          'TEXT',
      recipientTarget:
          map['recipient_target']?.toString() ??
          map['recipientTarget']?.toString(),
      location: loc,
      category: map['category']?.toString(),
      proximity: map['proximity']?.toString(),
      attachment: hasAttachment ? MediaAttachment.fromMap(map) : null,
    );
  }

  factory ChatMessage.fromDbMap(
    Map<String, dynamic> map, {
    String? myDeviceId,
  }) => ChatMessage.fromMap(map, myDeviceId: myDeviceId);
}
