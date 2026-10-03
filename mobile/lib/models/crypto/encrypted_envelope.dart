import 'dart:convert';
import 'dart:typed_data';

/// Unencrypted routing header for Delay-Tolerant Mesh forwarding.
///
/// Nodes participating in multi-hop store-and-forward routing can inspect
/// this header to verify TTL, hop counts, destination routing, and packet type,
/// WITHOUT being able to view or decrypt the underlying [EncryptedPayload].
class RoutingHeader {
  final String messageId;
  final int protocolVersion;
  final String senderDeviceId;
  final String? recipientUserId;
  final String? recipientDeviceId;
  final int createdAt;
  final int expiresAt;
  final int ttl;
  final int hopCount;
  final String packetType;
  final int payloadSize;
  final bool isInternetGateway;

  const RoutingHeader({
    required this.messageId,
    this.protocolVersion = 1,
    required this.senderDeviceId,
    this.recipientUserId,
    this.recipientDeviceId,
    required this.createdAt,
    required this.expiresAt,
    this.ttl = 5,
    this.hopCount = 0,
    required this.packetType,
    required this.payloadSize,
    this.isInternetGateway = false,
  });

  /// Factory helper with sensible emergency defaults
  factory RoutingHeader.create({
    required String messageId,
    required String senderDeviceId,
    String? recipientUserId,
    String? recipientDeviceId,
    required String packetType,
    required int payloadSize,
    int protocolVersion = 1,
    int ttl = 5,
    int hopCount = 0,
    int? createdAt,
    int? ttlSeconds,
    bool isInternetGateway = false,
  }) {
    final now = createdAt ?? DateTime.now().millisecondsSinceEpoch;
    final lifetimeMs = (ttlSeconds ?? 86400) * 1000; // default 24hr expiration
    return RoutingHeader(
      messageId: messageId,
      protocolVersion: protocolVersion,
      senderDeviceId: senderDeviceId,
      recipientUserId: recipientUserId,
      recipientDeviceId: recipientDeviceId,
      createdAt: now,
      expiresAt: now + lifetimeMs,
      ttl: ttl,
      hopCount: hopCount,
      packetType: packetType,
      payloadSize: payloadSize,
      isInternetGateway: isInternetGateway,
    );
  }

  /// Creates a copy with decremented TTL and incremented hopCount for relay forwarding
  RoutingHeader copyForRelay() {
    return RoutingHeader(
      messageId: messageId,
      protocolVersion: protocolVersion,
      senderDeviceId: senderDeviceId,
      recipientUserId: recipientUserId,
      recipientDeviceId: recipientDeviceId,
      createdAt: createdAt,
      expiresAt: expiresAt,
      ttl: ttl > 0 ? ttl - 1 : 0,
      hopCount: hopCount + 1,
      packetType: packetType,
      payloadSize: payloadSize,
      isInternetGateway: isInternetGateway,
    );
  }

  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expiresAt;
  bool get isAlive => ttl > 0 && !isExpired;

  RoutingHeader copyWith({
    String? messageId,
    int? protocolVersion,
    String? senderDeviceId,
    String? recipientUserId,
    String? recipientDeviceId,
    int? createdAt,
    int? expiresAt,
    int? ttl,
    int? hopCount,
    String? packetType,
    int? payloadSize,
    bool? isInternetGateway,
  }) {
    return RoutingHeader(
      messageId: messageId ?? this.messageId,
      protocolVersion: protocolVersion ?? this.protocolVersion,
      senderDeviceId: senderDeviceId ?? this.senderDeviceId,
      recipientUserId: recipientUserId ?? this.recipientUserId,
      recipientDeviceId: recipientDeviceId ?? this.recipientDeviceId,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      ttl: ttl ?? this.ttl,
      hopCount: hopCount ?? this.hopCount,
      packetType: packetType ?? this.packetType,
      payloadSize: payloadSize ?? this.payloadSize,
      isInternetGateway: isInternetGateway ?? this.isInternetGateway,
    );
  }

  Map<String, dynamic> toJson() => {
        'msg_id': messageId,
        'ver': protocolVersion,
        'sender_device_id': senderDeviceId,
        if (recipientUserId != null) 'recipient_user_id': recipientUserId,
        if (recipientDeviceId != null) 'recipient_device_id': recipientDeviceId,
        'created_at': createdAt,
        'expires_at': expiresAt,
        'ttl': ttl,
        'hop_count': hopCount,
        'packet_type': packetType,
        'payload_size': payloadSize,
        'is_internet_gateway': isInternetGateway,
      };

  factory RoutingHeader.fromJson(Map<String, dynamic> json) {
    return RoutingHeader(
      messageId: (json['msg_id'] ?? json['messageId'] ?? '') as String,
      protocolVersion:
          (json['ver'] as num?)?.toInt() ?? (json['protocolVersion'] as num?)?.toInt() ?? 1,
      senderDeviceId:
          (json['sender_device_id'] ?? json['senderDeviceId'] ?? '') as String,
      recipientUserId:
          (json['recipient_user_id'] ?? json['recipientUserId']) as String?,
      recipientDeviceId:
          (json['recipient_device_id'] ?? json['recipientDeviceId']) as String?,
      createdAt: (json['created_at'] as num?)?.toInt() ??
          (json['createdAt'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
      expiresAt: (json['expires_at'] as num?)?.toInt() ??
          (json['expiresAt'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch + 86400000,
      ttl: (json['ttl'] as num?)?.toInt() ?? 5,
      hopCount: (json['hop_count'] as num?)?.toInt() ??
          (json['hopCount'] as num?)?.toInt() ??
          0,
      packetType:
          (json['packet_type'] ?? json['packetType'] ?? 'TEXT') as String,
      payloadSize: (json['payload_size'] as num?)?.toInt() ??
          (json['payloadSize'] as num?)?.toInt() ??
          0,
      isInternetGateway:
          (json['is_internet_gateway'] ?? json['isInternetGateway']) as bool? ??
              false,
    );
  }
}

/// The encrypted message contents, cryptographic nonce, MAC auth tag, and digital signature.
///
/// Strictly unreadable by intermediate relay nodes. Only readable by the intended
/// recipient holding the corresponding private key or shared group key.
class EncryptedPayload {
  final List<int> ephemeralPublicKey;
  final List<int> nonce;
  final List<int> ciphertext;
  final List<int> authTag;
  final List<int> signature;

  const EncryptedPayload({
    required this.ephemeralPublicKey,
    required this.nonce,
    required this.ciphertext,
    required this.authTag,
    required this.signature,
  });

  String get ephemeralPublicKeyBase64 => base64Encode(ephemeralPublicKey);
  String get nonceBase64 => base64Encode(nonce);
  String get ciphertextBase64 => base64Encode(ciphertext);
  String get authTagBase64 => base64Encode(authTag);
  String get signatureBase64 => base64Encode(signature);

  Map<String, dynamic> toJson() => {
        'ephemeral_public_key': ephemeralPublicKeyBase64,
        'nonce': nonceBase64,
        'ciphertext': ciphertextBase64,
        'auth_tag': authTagBase64,
        'signature': signatureBase64,
      };

  factory EncryptedPayload.fromJson(Map<String, dynamic> json) {
    return EncryptedPayload(
      ephemeralPublicKey: base64Decode(
        (json['ephemeral_public_key'] ?? json['ephemeralPublicKey'] ?? '')
            as String,
      ),
      nonce: base64Decode(
        (json['nonce'] ?? '') as String,
      ),
      ciphertext: base64Decode(
        (json['ciphertext'] ?? '') as String,
      ),
      authTag: base64Decode(
        (json['auth_tag'] ?? json['authTag'] ?? '') as String,
      ),
      signature: base64Decode(
        (json['signature'] ?? '') as String,
      ),
    );
  }

  int get totalByteLength =>
      ephemeralPublicKey.length +
      nonce.length +
      ciphertext.length +
      authTag.length +
      signature.length;
}

/// The complete end-to-end encrypted envelope containing a public [RoutingHeader]
/// and an encrypted [EncryptedPayload].
///
/// Provides both JSON and binary serialization for wire transport.
class EncryptedEnvelope {
  final RoutingHeader header;
  final EncryptedPayload payload;

  const EncryptedEnvelope({
    required this.header,
    required this.payload,
  });

  /// Binary format magic bytes: 'RNE\x01' (RakshaNet Encrypted Version 1)
  static const List<int> magicBytes = [0x52, 0x4E, 0x45, 0x01];

  /// Creates a forwarded copy for downstream relay: decrements TTL and increments hop count.
  /// The payload remains untouched and undecryptable by the forwarder.
  EncryptedEnvelope copyForRelay() {
    return EncryptedEnvelope(
      header: header.copyForRelay(),
      payload: payload,
    );
  }

  Map<String, dynamic> toJson() => {
        'header': header.toJson(),
        'payload': payload.toJson(),
      };

  factory EncryptedEnvelope.fromJson(Map<String, dynamic> json) {
    return EncryptedEnvelope(
      header: RoutingHeader.fromJson(
          Map<String, dynamic>.from(json['header'] as Map)),
      payload: EncryptedPayload.fromJson(
          Map<String, dynamic>.from(json['payload'] as Map)),
    );
  }

  /// Encodes to JSON string
  String encode() => jsonEncode(toJson());

  /// Decodes from JSON string
  static EncryptedEnvelope decode(String jsonStr) =>
      EncryptedEnvelope.fromJson(
          jsonDecode(jsonStr) as Map<String, dynamic>);

  /// Serializes envelope to byte array.
  /// Uses raw compact binary framing if [useBinaryFormat] is true (saving ~33% over Base64 JSON),
  /// or UTF-8 encoded JSON if false (default: false for maximum cross-platform compatibility).
  Uint8List toBytes({bool useBinaryFormat = false}) {
    if (useBinaryFormat) {
      return toBinaryBytes();
    }
    return Uint8List.fromList(utf8.encode(encode()));
  }

  /// Compact binary packing:
  /// [4 bytes magic]
  /// [2 bytes header json length] + [header json utf8]
  /// [2 bytes eph pubkey len] + [eph pubkey bytes]
  /// [2 bytes nonce len] + [nonce bytes]
  /// [2 bytes auth tag len] + [auth tag bytes]
  /// [2 bytes signature len] + [signature bytes]
  /// [4 bytes ciphertext len] + [ciphertext bytes]
  Uint8List toBinaryBytes() {
    final headerJsonBytes = utf8.encode(jsonEncode(header.toJson()));
    final ephBytes = payload.ephemeralPublicKey;
    final nonceBytes = payload.nonce;
    final tagBytes = payload.authTag;
    final sigBytes = payload.signature;
    final cipherBytes = payload.ciphertext;


    final bb = BytesBuilder(copy: false);
    bb.add(magicBytes);

    // Header JSON
    final headerLenData = ByteData(2)..setUint16(0, headerJsonBytes.length);
    bb.add(headerLenData.buffer.asUint8List());
    bb.add(headerJsonBytes);

    // Eph pubkey
    final ephLenData = ByteData(2)..setUint16(0, ephBytes.length);
    bb.add(ephLenData.buffer.asUint8List());
    bb.add(ephBytes);

    // Nonce
    final nonceLenData = ByteData(2)..setUint16(0, nonceBytes.length);
    bb.add(nonceLenData.buffer.asUint8List());
    bb.add(nonceBytes);

    // Auth tag
    final tagLenData = ByteData(2)..setUint16(0, tagBytes.length);
    bb.add(tagLenData.buffer.asUint8List());
    bb.add(tagBytes);

    // Signature
    final sigLenData = ByteData(2)..setUint16(0, sigBytes.length);
    bb.add(sigLenData.buffer.asUint8List());
    bb.add(sigBytes);

    // Ciphertext
    final cipherLenData = ByteData(4)..setUint32(0, cipherBytes.length);
    bb.add(cipherLenData.buffer.asUint8List());
    bb.add(cipherBytes);

    return bb.takeBytes();
  }

  /// Deserializes envelope from either compact binary or UTF-8 JSON bytes.
  static EncryptedEnvelope fromBytes(Uint8List bytes) {
    if (_isBinaryFormat(bytes)) {
      return fromBinaryBytes(bytes);
    }
    return EncryptedEnvelope.decode(utf8.decode(bytes));
  }

  /// Attempts to parse from bytes without throwing uncaught exceptions.
  static EncryptedEnvelope? tryFromBytes(Uint8List bytes) {
    try {
      return fromBytes(bytes);
    } catch (_) {
      return null;
    }
  }

  /// Unpacks compact binary format
  static EncryptedEnvelope fromBinaryBytes(Uint8List bytes) {
    if (!_isBinaryFormat(bytes)) {
      throw FormatException('Invalid magic header for binary EncryptedEnvelope');
    }

    final byteData = ByteData.sublistView(bytes);
    var offset = 4;

    // Header JSON
    final headerLen = byteData.getUint16(offset);
    offset += 2;
    final headerBytes = bytes.sublist(offset, offset + headerLen);
    offset += headerLen;
    final headerJson =
        jsonDecode(utf8.decode(headerBytes)) as Map<String, dynamic>;
    final header = RoutingHeader.fromJson(headerJson);

    // Eph pubkey
    final ephLen = byteData.getUint16(offset);
    offset += 2;
    final ephBytes = bytes.sublist(offset, offset + ephLen);
    offset += ephLen;

    // Nonce
    final nonceLen = byteData.getUint16(offset);
    offset += 2;
    final nonceBytes = bytes.sublist(offset, offset + nonceLen);
    offset += nonceLen;

    // Auth tag
    final tagLen = byteData.getUint16(offset);
    offset += 2;
    final tagBytes = bytes.sublist(offset, offset + tagLen);
    offset += tagLen;

    // Signature
    final sigLen = byteData.getUint16(offset);
    offset += 2;
    final sigBytes = bytes.sublist(offset, offset + sigLen);
    offset += sigLen;

    // Ciphertext
    final cipherLen = byteData.getUint32(offset);
    offset += 4;
    final cipherBytes = bytes.sublist(offset, offset + cipherLen);

    return EncryptedEnvelope(
      header: header,
      payload: EncryptedPayload(
        ephemeralPublicKey: ephBytes,
        nonce: nonceBytes,
        ciphertext: cipherBytes,
        authTag: tagBytes,
        signature: sigBytes,
      ),
    );
  }

  static bool _isBinaryFormat(Uint8List bytes) {
    if (bytes.length < 4) return false;
    return bytes[0] == magicBytes[0] &&
        bytes[1] == magicBytes[1] &&
        bytes[2] == magicBytes[2] &&
        bytes[3] == magicBytes[3];
  }

  @override
  String toString() =>
      'EncryptedEnvelope(msgId: ${header.messageId}, sender: ${header.senderDeviceId}, type: ${header.packetType}, ttl: ${header.ttl}, hops: ${header.hopCount}, cipherBytes: ${payload.ciphertext.length})';
}
