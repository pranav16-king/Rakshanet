import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Represents an encrypted chunk of an image transferred over the mesh network.
///
/// Designed for low-bandwidth BLE / Wi-Fi Direct transports with resumption
/// support, SHA-256 integrity verification, and binary network serialization.
class ImageChunk {
  final String messageId;
  final String attachmentId;
  final int chunkIndex;
  final int totalChunks;
  final Uint8List encryptedData;
  final String checksum;
  final int byteLength;

  ImageChunk({
    required this.messageId,
    required this.attachmentId,
    required this.chunkIndex,
    required this.totalChunks,
    required this.encryptedData,
    String? checksum,
    int? byteLength,
  })  : checksum = checksum ?? computeChecksum(encryptedData),
        byteLength = byteLength ?? encryptedData.length;

  /// Unique identifier of this chunk within SQLite ($messageId_$chunkIndex).
  String get id => '${messageId}_$chunkIndex';

  /// Computes the SHA-256 checksum string for raw byte data.
  static String computeChecksum(Uint8List data) {
    return sha256.convert(data).toString();
  }

  /// Verifies whether the chunk's payload matches its declared checksum.
  bool isValidChecksum() {
    return computeChecksum(encryptedData).toLowerCase() ==
        checksum.toLowerCase();
  }

  /// Serializes to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'attachmentId': attachmentId,
      'chunkIndex': chunkIndex,
      'totalChunks': totalChunks,
      'encryptedData': base64Encode(encryptedData),
      'checksum': checksum,
      'byteLength': byteLength,
    };
  }

  /// Deserializes from a JSON map.
  factory ImageChunk.fromJson(Map<String, dynamic> json) {
    final rawEncData = json['encryptedData'];
    final Uint8List encData;
    if (rawEncData is Uint8List) {
      encData = rawEncData;
    } else if (rawEncData is List<int>) {
      encData = Uint8List.fromList(rawEncData);
    } else if (rawEncData is String) {
      encData = base64Decode(rawEncData);
    } else {
      encData = Uint8List(0);
    }

    final chunkIndex = (json['chunkIndex'] as num?)?.toInt() ??
        (json['chunk_index'] as num?)?.toInt() ??
        0;
    final totalChunks = (json['totalChunks'] as num?)?.toInt() ??
        (json['total_chunks'] as num?)?.toInt() ??
        1;

    return ImageChunk(
      messageId: json['messageId']?.toString() ??
          json['message_id']?.toString() ??
          '',
      attachmentId: json['attachmentId']?.toString() ??
          json['attachment_id']?.toString() ??
          '',
      chunkIndex: chunkIndex,
      totalChunks: totalChunks,
      encryptedData: encData,
      checksum: json['checksum']?.toString(),
      byteLength: (json['byteLength'] as num?)?.toInt() ??
          (json['byte_length'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() => toJson();
  factory ImageChunk.fromMap(Map<String, dynamic> map) =>
      ImageChunk.fromJson(map);

  /// Compact binary byte serialization for low-overhead mesh radio transmission.
  ///
  /// Format:
  /// - 4 bytes: Magic [0x52, 0x4B, 0x43, 0x48] ("RKCH")
  /// - 1 byte: Version [0x01]
  /// - 2 bytes: messageId length (uint16 big-endian)
  /// - N bytes: messageId (UTF-8)
  /// - 2 bytes: attachmentId length (uint16 big-endian)
  /// - N bytes: attachmentId (UTF-8)
  /// - 4 bytes: chunkIndex (uint32 big-endian)
  /// - 4 bytes: totalChunks (uint32 big-endian)
  /// - 2 bytes: checksum length (uint16 big-endian)
  /// - N bytes: checksum (UTF-8)
  /// - 4 bytes: encryptedData length (uint32 big-endian)
  /// - N bytes: encryptedData
  Uint8List toBytes() {
    final msgBytes = utf8.encode(messageId);
    final attBytes = utf8.encode(attachmentId);
    final chkBytes = utf8.encode(checksum);

    final totalSize = 4 +
        1 +
        2 +
        msgBytes.length +
        2 +
        attBytes.length +
        4 +
        4 +
        2 +
        chkBytes.length +
        4 +
        encryptedData.length;

    final buffer = Uint8List(totalSize);
    final byteData = ByteData.view(buffer.buffer);
    int offset = 0;

    // Magic: "RKCH"
    buffer[offset++] = 0x52;
    buffer[offset++] = 0x4B;
    buffer[offset++] = 0x43;
    buffer[offset++] = 0x48;

    // Version
    buffer[offset++] = 0x01;

    // messageId
    byteData.setUint16(offset, msgBytes.length, Endian.big);
    offset += 2;
    buffer.setRange(offset, offset + msgBytes.length, msgBytes);
    offset += msgBytes.length;

    // attachmentId
    byteData.setUint16(offset, attBytes.length, Endian.big);
    offset += 2;
    buffer.setRange(offset, offset + attBytes.length, attBytes);
    offset += attBytes.length;

    // chunkIndex
    byteData.setUint32(offset, chunkIndex, Endian.big);
    offset += 4;

    // totalChunks
    byteData.setUint32(offset, totalChunks, Endian.big);
    offset += 4;

    // checksum
    byteData.setUint16(offset, chkBytes.length, Endian.big);
    offset += 2;
    buffer.setRange(offset, offset + chkBytes.length, chkBytes);
    offset += chkBytes.length;

    // encryptedData
    byteData.setUint32(offset, encryptedData.length, Endian.big);
    offset += 4;
    buffer.setRange(offset, offset + encryptedData.length, encryptedData);
    offset += encryptedData.length;

    return buffer;
  }

  Uint8List toBinary() => toBytes();

  /// Deserializes an [ImageChunk] from binary bytes.
  factory ImageChunk.fromBytes(Uint8List bytes) {
    if (bytes.length < 23) {
      throw FormatException(
        'Invalid chunk binary data: payload too short (${bytes.length} bytes)',
      );
    }

    if (bytes[0] != 0x52 ||
        bytes[1] != 0x4B ||
        bytes[2] != 0x43 ||
        bytes[3] != 0x48) {
      throw const FormatException('Invalid chunk magic bytes header (expected RKCH)');
    }

    final byteData =
        ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes);
    int offset = 4;

    final version = bytes[offset++];
    if (version != 0x01) {
      throw FormatException('Unsupported chunk protocol version: $version');
    }

    final msgLen = byteData.getUint16(offset, Endian.big);
    offset += 2;
    final msgId = utf8.decode(bytes.sublist(offset, offset + msgLen));
    offset += msgLen;

    final attLen = byteData.getUint16(offset, Endian.big);
    offset += 2;
    final attId = utf8.decode(bytes.sublist(offset, offset + attLen));
    offset += attLen;

    final cIndex = byteData.getUint32(offset, Endian.big);
    offset += 4;

    final totChunks = byteData.getUint32(offset, Endian.big);
    offset += 4;

    final chkLen = byteData.getUint16(offset, Endian.big);
    offset += 2;
    final chksum = utf8.decode(bytes.sublist(offset, offset + chkLen));
    offset += chkLen;

    final dataLen = byteData.getUint32(offset, Endian.big);
    offset += 4;
    final encData = bytes.sublist(offset, offset + dataLen);

    return ImageChunk(
      messageId: msgId,
      attachmentId: attId,
      chunkIndex: cIndex,
      totalChunks: totChunks,
      encryptedData: encData,
      checksum: chksum,
      byteLength: dataLen,
    );
  }

  factory ImageChunk.fromBinary(Uint8List bytes) => ImageChunk.fromBytes(bytes);

  /// Database representation for SQLite `attachment_chunks` table.
  Map<String, dynamic> toDbMap({
    String? chunkPath,
    String status = 'PENDING',
  }) {
    return {
      'id': id,
      'message_id': messageId,
      'attachment_id': attachmentId,
      'chunk_index': chunkIndex,
      'total_chunks': totalChunks,
      'chunk_path': chunkPath,
      'checksum': checksum,
      'status': status,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  ImageChunk copyWith({
    String? messageId,
    String? attachmentId,
    int? chunkIndex,
    int? totalChunks,
    Uint8List? encryptedData,
    String? checksum,
    int? byteLength,
  }) {
    return ImageChunk(
      messageId: messageId ?? this.messageId,
      attachmentId: attachmentId ?? this.attachmentId,
      chunkIndex: chunkIndex ?? this.chunkIndex,
      totalChunks: totalChunks ?? this.totalChunks,
      encryptedData: encryptedData ?? this.encryptedData,
      checksum: checksum ?? this.checksum,
      byteLength: byteLength ?? this.byteLength,
    );
  }

  @override
  String toString() {
    return 'ImageChunk(id: $id, attId: $attachmentId, index: $chunkIndex/$totalChunks, bytes: $byteLength, checksum: ${checksum.length > 8 ? checksum.substring(0, 8) : checksum}...)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImageChunk &&
        other.messageId == messageId &&
        other.attachmentId == attachmentId &&
        other.chunkIndex == chunkIndex &&
        other.totalChunks == totalChunks &&
        other.checksum == checksum &&
        other.byteLength == byteLength;
  }

  @override
  int get hashCode => Object.hash(
        messageId,
        attachmentId,
        chunkIndex,
        totalChunks,
        checksum,
        byteLength,
      );
}
