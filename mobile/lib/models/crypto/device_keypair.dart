import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';

/// Exportable public key bundle of a device.
///
/// Contains ONLY public cryptographic components:
/// - X25519 public key (32 bytes) for Elliptic-Curve Diffie-Hellman (ECDH) key agreement.
/// - Ed25519 public key (32 bytes) for digital signature verification.
///
/// Safe to broadcast over mesh, publish to server registry, or exchange via QR code.
class DevicePublicKeys {
  final String deviceId;
  final List<int> x25519PublicKey;
  final List<int> ed25519PublicKey;
  final DateTime createdAt;

  const DevicePublicKeys({
    required this.deviceId,
    required this.x25519PublicKey,
    required this.ed25519PublicKey,
    required this.createdAt,
  });

  /// Base64 representation of X25519 ECDH public key (32 bytes)
  String get x25519PublicKeyBase64 => base64Encode(x25519PublicKey);

  /// Base64 representation of Ed25519 signing public key (32 bytes)
  String get ed25519PublicKeyBase64 => base64Encode(ed25519PublicKey);

  /// Cryptographic SimplePublicKey wrapper for X25519 operations
  SimplePublicKey get x25519Key => SimplePublicKey(
        x25519PublicKey,
        type: KeyPairType.x25519,
      );

  /// Cryptographic SimplePublicKey wrapper for Ed25519 operations
  SimplePublicKey get ed25519Key => SimplePublicKey(
        ed25519PublicKey,
        type: KeyPairType.ed25519,
      );

  /// Computes a human-verifiable 60-digit or 12-byte fingerprint (Safety Number)
  /// using SHA-256 over both public keys, for peer-to-peer visual verification.
  String get fingerprint {
    final combined = <int>[
      ...x25519PublicKey,
      ...ed25519PublicKey,
      ...utf8.encode(deviceId),
    ];
    final digest = crypto.sha256.convert(combined);
    final hexStr = digest.toString().toUpperCase();
    // Format into 8 readable 4-character blocks: XXXX-XXXX-...
    final chunks = <String>[];
    for (var i = 0; i < 32; i += 4) {
      chunks.add(hexStr.substring(i, i + 4));
    }
    return chunks.join('-');
  }

  /// Compact hex fingerprint (first 16 hex chars)
  String get shortFingerprint => fingerprint.substring(0, 19);

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'x25519_public': x25519PublicKeyBase64,
        'ed25519_public': ed25519PublicKeyBase64,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory DevicePublicKeys.fromJson(Map<String, dynamic> json) {
    return DevicePublicKeys(
      deviceId: (json['device_id'] ?? json['deviceId'] ?? '') as String,
      x25519PublicKey: base64Decode(
          (json['x25519_public'] ?? json['x25519PublicKey'] ?? '') as String),
      ed25519PublicKey: base64Decode(
          (json['ed25519_public'] ?? json['ed25519PublicKey'] ?? '') as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['created_at'] ?? json['createdAt'] ?? 0) as int,
      ),
    );
  }

  @override
  String toString() =>
      'DevicePublicKeys(deviceId: $deviceId, fingerprint: $shortFingerprint)';
}

/// Represents the local node's asymmetric device keypair.
///
/// Combines:
/// 1. Curve25519 / X25519 keypair for ephemeral-static Diffie-Hellman (ECDH) key exchange.
/// 2. Edwards-curve Ed25519 keypair for cryptographic identity signing and authenticity.
///
/// Security constraints:
/// - Private keys MUST NEVER be broadcast over the mesh or transmitted to peers.
/// - Serialized locally to base64 JSON strictly for SharedPreferences encrypted/private persistence.
class DeviceKeypair {
  final String deviceId;
  final List<int> x25519PrivateKey;
  final List<int> x25519PublicKey;
  final List<int> ed25519PrivateKey;
  final List<int> ed25519PublicKey;
  final DateTime createdAt;

  const DeviceKeypair({
    required this.deviceId,
    required this.x25519PrivateKey,
    required this.x25519PublicKey,
    required this.ed25519PrivateKey,
    required this.ed25519PublicKey,
    required this.createdAt,
  });

  /// Base64 encoded public key for X25519 key exchange
  String get x25519PublicKeyBase64 => base64Encode(x25519PublicKey);

  /// Base64 encoded public key for Ed25519 signatures
  String get ed25519PublicKeyBase64 => base64Encode(ed25519PublicKey);

  /// Wraps private and public X25519 keys into a cryptography [SimpleKeyPair]
  SimpleKeyPair get x25519KeyPair => SimpleKeyPairData(
        x25519PrivateKey,
        publicKey: SimplePublicKey(x25519PublicKey, type: KeyPairType.x25519),
        type: KeyPairType.x25519,
      );

  /// Wraps private and public Ed25519 keys into a cryptography [SimpleKeyPair]
  SimpleKeyPair get ed25519KeyPair => SimpleKeyPairData(
        ed25519PrivateKey,
        publicKey: SimplePublicKey(ed25519PublicKey, type: KeyPairType.ed25519),
        type: KeyPairType.ed25519,
      );

  /// Exports the public-only key bundle for broadcasting or registering
  DevicePublicKeys toPublicKeys() => DevicePublicKeys(
        deviceId: deviceId,
        x25519PublicKey: x25519PublicKey,
        ed25519PublicKey: ed25519PublicKey,
        createdAt: createdAt,
      );

  /// Generates a brand new asymmetric device keypair using cryptographically secure random sources.
  static Future<DeviceKeypair> generate({required String deviceId}) async {
    final x25519 = X25519();
    final ed25519 = Ed25519();

    // 1. Generate X25519 Diffie-Hellman keypair
    final xKp = await x25519.newKeyPair();
    final xPub = await xKp.extractPublicKey();
    final xData = await xKp.extract();

    // 2. Generate Ed25519 Signing keypair
    final edKp = await ed25519.newKeyPair();
    final edPub = await edKp.extractPublicKey();
    final edData = await edKp.extract();

    return DeviceKeypair(
      deviceId: deviceId,
      x25519PrivateKey: xData.bytes,
      x25519PublicKey: xPub.bytes,
      ed25519PrivateKey: edData.bytes,
      ed25519PublicKey: edPub.bytes,
      createdAt: DateTime.now(),
    );
  }

  /// Serializes the entire keypair (including private keys) to a secure local JSON format.
  /// Intended ONLY for private local SharedPreferences / Keystore storage.
  Map<String, dynamic> toSecureJson() => {
        'version': 1,
        'device_id': deviceId,
        'x25519_private': base64Encode(x25519PrivateKey),
        'x25519_public': base64Encode(x25519PublicKey),
        'ed25519_private': base64Encode(ed25519PrivateKey),
        'ed25519_public': base64Encode(ed25519PublicKey),
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  /// Serializes the secure local JSON to a compact string.
  String toSecureString() => jsonEncode(toSecureJson());

  /// Restores a device keypair from secure local storage format.
  factory DeviceKeypair.fromSecureJson(Map<String, dynamic> json) {
    return DeviceKeypair(
      deviceId: (json['device_id'] ?? json['deviceId'] ?? '') as String,
      x25519PrivateKey: base64Decode(
          (json['x25519_private'] ?? json['x25519PrivateKey'] ?? '') as String),
      x25519PublicKey: base64Decode(
          (json['x25519_public'] ?? json['x25519PublicKey'] ?? '') as String),
      ed25519PrivateKey: base64Decode(
          (json['ed25519_private'] ?? json['ed25519PrivateKey'] ?? '') as String),
      ed25519PublicKey: base64Decode(
          (json['ed25519_public'] ?? json['ed25519PublicKey'] ?? '') as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['created_at'] ?? json['createdAt'] ?? 0) as int,
      ),
    );
  }

  /// Restores a device keypair from secure JSON string.
  factory DeviceKeypair.fromSecureString(String jsonStr) =>
      DeviceKeypair.fromSecureJson(
          jsonDecode(jsonStr) as Map<String, dynamic>);

  /// Redacts private keys in debug string representation to avoid leakage in console logs.
  @override
  String toString() =>
      'DeviceKeypair(deviceId: $deviceId, x25519Pub: ${x25519PublicKeyBase64.substring(0, 8)}..., ed25519Pub: ${ed25519PublicKeyBase64.substring(0, 8)}..., [PRIVATE KEYS REDACTED])';
}
