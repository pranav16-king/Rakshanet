import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'location_observation.dart';
import 'message_envelope.dart';

/// Structured decrypted plaintext data payload.
class DecryptedLocationData {
  final double latitude;
  final double longitude;
  final double uncertaintyRadiusMeters;
  final int anchorCount;
  final double residualError;
  final String confidenceRating;
  final bool isExactGps;
  final int timestamp;
  final String? notes;

  const DecryptedLocationData({
    required this.latitude,
    required this.longitude,
    required this.uncertaintyRadiusMeters,
    required this.anchorCount,
    required this.residualError,
    required this.confidenceRating,
    required this.isExactGps,
    required this.timestamp,
    this.notes,
  });

  /// Converts decrypted coordinates into an EstimatedLocation model.
  EstimatedLocation toEstimatedLocation() {
    return EstimatedLocation(
      latitude: latitude,
      longitude: longitude,
      uncertaintyRadiusMeters: uncertaintyRadiusMeters,
      anchorCount: anchorCount,
      residualError: residualError,
      confidenceRating: confidenceRating,
      isExactGps: isExactGps,
      timestamp: timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'lat': latitude,
        'lon': longitude,
        'uncertainty_m': uncertaintyRadiusMeters,
        'anchor_count': anchorCount,
        'residual_error': residualError,
        'confidence': confidenceRating,
        'is_exact_gps': isExactGps,
        'timestamp': timestamp,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };

  factory DecryptedLocationData.fromJson(Map<String, dynamic> json) {
    return DecryptedLocationData(
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lon'] as num).toDouble(),
      uncertaintyRadiusMeters: (json['uncertainty_m'] as num).toDouble(),
      anchorCount: (json['anchor_count'] as num).toInt(),
      residualError: (json['residual_error'] as num?)?.toDouble() ?? 0.0,
      confidenceRating: (json['confidence'] as String?) ?? 'Medium',
      isExactGps: (json['is_exact_gps'] as bool?) ?? false,
      timestamp: (json['timestamp'] as num).toInt(),
      notes: json['notes'] as String?,
    );
  }
}

/// End-to-end encrypted location payload for mesh routing.
///
/// CRITICAL SECURITY GUARANTEE:
/// In delay-tolerant mesh networks, intermediary relay nodes forward messages
/// over Bluetooth LE and Wi-Fi Direct. Relays CAN NEVER see the sender's GPS
/// coordinates, estimated location, or emergency situation notes.
///
/// Intermediary nodes observe only the opaque ciphertext, cryptographic nonce,
/// and routing headers. Only the intended destination holding the shared secret key
/// or private key can authenticate and decrypt the location coordinates.
class EncryptedLocationPayload {
  /// Unique identifier of the node originating the location observation.
  final String senderDeviceId;

  /// Designated recipient node identifier (e.g. rescue team lead or coordinator).
  final String recipientDeviceId;

  /// Creation timestamp in milliseconds since epoch.
  final int timestamp;

  /// Authenticated encryption algorithm used (default: AES-256-GCM).
  final String algorithm;

  /// Base64-encoded encrypted ciphertext containing serialized JSON coordinates.
  final String ciphertext;

  /// Base64-encoded initialization vector / nonce (12 bytes for AES-GCM).
  final String nonce;

  /// Base64-encoded cryptographic MAC / authentication tag (16 bytes for AES-GCM).
  final String mac;

  /// Optional Base64-encoded sender ephemeral public key (for ECDH/X25519 sessions).
  final String? ephemeralPublicKey;

  /// Optional identifier for key rotation or pre-shared key indexing.
  final String? keyId;

  const EncryptedLocationPayload({
    required this.senderDeviceId,
    required this.recipientDeviceId,
    required this.timestamp,
    required this.algorithm,
    required this.ciphertext,
    required this.nonce,
    required this.mac,
    this.ephemeralPublicKey,
    this.keyId,
  });

  static final AesGcm _aesGcm = AesGcm.with256bits();

  /// Derives a 256-bit symmetric key from a shared secret passphrase or shared secret bytes.
  static Future<List<int>> deriveKeyFromSecret(String secret) async {
    final hash = await Sha256().hash(utf8.encode(secret));
    return hash.bytes;
  }

  /// Encrypts an [EstimatedLocation] (or raw GPS location) for the intended recipient.
  ///
  /// Produces an [EncryptedLocationPayload] containing AES-256-GCM ciphertext,
  /// 96-bit nonce, and 128-bit authentication tag. Relays cannot decrypt this content.
  static Future<EncryptedLocationPayload> encrypt({
    required EstimatedLocation location,
    required String senderDeviceId,
    required String recipientDeviceId,
    required List<int> secretKeyBytes,
    String? emergencyNotes,
    String? ephemeralPublicKey,
    String? keyId,
  }) async {
    // 1. Prepare plaintext payload
    final plainData = DecryptedLocationData(
      latitude: location.latitude,
      longitude: location.longitude,
      uncertaintyRadiusMeters: location.uncertaintyRadiusMeters,
      anchorCount: location.anchorCount,
      residualError: location.residualError,
      confidenceRating: location.confidenceRating,
      isExactGps: location.isExactGps,
      timestamp: location.timestamp,
      notes: emergencyNotes,
    );

    final plainJson = jsonEncode(plainData.toJson());
    final plainBytes = utf8.encode(plainJson);

    // 2. Encrypt using AES-256-GCM
    final secretKey = SecretKey(secretKeyBytes);
    final secretBox = await _aesGcm.encrypt(
      plainBytes,
      secretKey: secretKey,
    );

    // 3. Serialize outputs to Base64
    final ciphertextBase64 = base64Encode(secretBox.cipherText);
    final nonceBase64 = base64Encode(secretBox.nonce);
    final macBase64 = base64Encode(secretBox.mac.bytes);

    return EncryptedLocationPayload(
      senderDeviceId: senderDeviceId,
      recipientDeviceId: recipientDeviceId,
      timestamp: location.timestamp,
      algorithm: 'AES-256-GCM',
      ciphertext: ciphertextBase64,
      nonce: nonceBase64,
      mac: macBase64,
      ephemeralPublicKey: ephemeralPublicKey,
      keyId: keyId,
    );
  }

  /// Decrypts this payload using the recipient's secret key.
  ///
  /// Throws an exception or [SecretBoxAuthenticationError] if ciphertext has been
  /// tampered with, corrupted in mesh transit, or if an invalid key is provided.
  Future<DecryptedLocationData> decrypt({
    required List<int> secretKeyBytes,
  }) async {
    final cipherBytes = base64Decode(ciphertext);
    final nonceBytes = base64Decode(nonce);
    final macBytes = base64Decode(mac);

    final secretBox = SecretBox(
      cipherBytes,
      nonce: nonceBytes,
      mac: Mac(macBytes),
    );

    final secretKey = SecretKey(secretKeyBytes);
    final clearBytes = await _aesGcm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    final clearText = utf8.decode(clearBytes);
    final json = jsonDecode(clearText) as Map<String, dynamic>;
    return DecryptedLocationData.fromJson(json);
  }

  /// Serializes encrypted payload to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'sender_device_id': senderDeviceId,
        'recipient_device_id': recipientDeviceId,
        'timestamp': timestamp,
        'algorithm': algorithm,
        'ciphertext': ciphertext,
        'nonce': nonce,
        'mac': mac,
        if (ephemeralPublicKey != null) 'ephemeral_public_key': ephemeralPublicKey,
        if (keyId != null) 'key_id': keyId,
      };

  factory EncryptedLocationPayload.fromJson(Map<String, dynamic> json) {
    return EncryptedLocationPayload(
      senderDeviceId: (json['sender_device_id'] ?? json['senderDeviceId'] ?? '') as String,
      recipientDeviceId: (json['recipient_device_id'] ?? json['recipientDeviceId'] ?? '') as String,
      timestamp: (json['timestamp'] as num).toInt(),
      algorithm: (json['algorithm'] as String?) ?? 'AES-256-GCM',
      ciphertext: (json['ciphertext'] as String?) ?? '',
      nonce: (json['nonce'] as String?) ?? '',
      mac: (json['mac'] as String?) ?? '',
      ephemeralPublicKey: json['ephemeral_public_key'] as String?,
      keyId: json['key_id'] as String?,
    );
  }

  /// Packages this encrypted location into a mesh network [MessageEnvelope].
  ///
  /// Intermediary mesh relays forward this envelope without knowing the
  /// location content inside the payload string.
  MessageEnvelope toMessageEnvelope({
    required String conversationId,
    String? senderName,
    int ttl = 5,
  }) {
    return MessageEnvelope(
      uuid: 'LOC-${DateTime.now().millisecondsSinceEpoch}-${senderDeviceId.hashCode.toRadixString(16)}',
      senderId: senderDeviceId,
      senderName: senderName ?? 'RakshaNet Node',
      conversationId: conversationId,
      timestamp: timestamp,
      ttl: ttl,
      hops: 0,
      type: 'ENCRYPTED_LOCATION',
      payload: jsonEncode(toJson()),
      recipientTarget: recipientDeviceId,
      metadata: {
        'encrypted': true,
        'algo': algorithm,
        'target': recipientDeviceId,
      },
    );
  }

  /// Parses an [EncryptedLocationPayload] from a received [MessageEnvelope].
  ///
  /// Returns null if envelope does not contain an encrypted location payload.
  static EncryptedLocationPayload? fromMessageEnvelope(MessageEnvelope envelope) {
    if (envelope.type != 'ENCRYPTED_LOCATION' && envelope.type != 'LOCATION') {
      return null;
    }
    try {
      final json = jsonDecode(envelope.payload) as Map<String, dynamic>;
      if (json.containsKey('ciphertext') && json.containsKey('nonce')) {
        return EncryptedLocationPayload.fromJson(json);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
