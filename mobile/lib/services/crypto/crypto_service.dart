import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../models/crypto/device_keypair.dart';
import '../../models/crypto/encrypted_envelope.dart';
import '../device_identity_service.dart';

/// Exception thrown when cryptographic signature validation fails.
class CryptoSignatureException implements Exception {
  final String message;
  const CryptoSignatureException(this.message);

  @override
  String toString() => 'CryptoSignatureException: $message';
}

/// Exception thrown when decryption or authentication tag verification fails.
class CryptoDecryptionException implements Exception {
  final String message;
  const CryptoDecryptionException(this.message);

  @override
  String toString() => 'CryptoDecryptionException: $message';
}

/// End-to-End Encryption (E2EE) & Device Keypair Service for RakshaNet.
///
/// Implements a complete zero-trust cryptographic engine:
/// - Asymmetric Keypairs: X25519 for ECDH key agreements, Ed25519 for identity signing.
/// - Authenticated Encryption: AES-256-GCM with 128-bit authentication tags and unique nonces.
/// - Key Derivation: HKDF-SHA256 with domain separation salts.
/// - Group Encryption: High-throughput symmetric AES-256-GCM for disaster triage groups.
/// - Delay-Tolerant Envelopes: Clean separation of unencrypted [RoutingHeader] and [EncryptedPayload].
///
/// Security Guarantees:
/// - Private keys NEVER leave device memory or secure local persistence.
/// - Relays cannot decrypt payloads, alter ciphertexts, or forge sender identity.
class CryptoService {
  CryptoService._();

  static final CryptoService instance = CryptoService._();

  static const String _storageKey = 'rakshanet_secure_device_keypair_v1';
  static const List<int> _hkdfPeerSalt = [
    0x52, 0x61, 0x6B, 0x73, 0x68, 0x61, 0x4E, 0x65, 0x74, 0x2D, 0x45, 0x32, 0x45, 0x45
  ]; // 'RakshaNet-E2EE'
  static const List<int> _hkdfPeerInfo = [
    0x50, 0x65, 0x65, 0x72, 0x2D, 0x4B, 0x65, 0x79
  ]; // 'Peer-Key'

  final X25519 _x25519 = X25519();
  final Ed25519 _ed25519 = Ed25519();
  final Hkdf _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  final AesGcm _aesGcm = AesGcm.with256bits();
  final Uuid _uuid = const Uuid();

  DeviceKeypair? _deviceKeypair;
  bool _initialized = false;

  bool get isInitialized => _initialized && _deviceKeypair != null;

  /// Returns the current device asymmetric keypair. Throws if not initialized.
  DeviceKeypair get deviceKeypair {
    if (_deviceKeypair == null) {
      throw StateError(
          'CryptoService has not been initialized. Call initialize() first.');
    }
    return _deviceKeypair!;
  }

  /// Returns the public keys bundle of this node.
  DevicePublicKeys get publicKeys => deviceKeypair.toPublicKeys();

  /// Convenience getter for local X25519 public key bytes (32 bytes).
  List<int> get x25519PublicKey => deviceKeypair.x25519PublicKey;

  /// Convenience getter for local Ed25519 public key bytes (32 bytes).
  List<int> get ed25519PublicKey => deviceKeypair.ed25519PublicKey;

  /// Convenience getter for Base64 encoded local X25519 public key.
  String get x25519PublicKeyBase64 => deviceKeypair.x25519PublicKeyBase64;

  /// Convenience getter for Base64 encoded local Ed25519 public key.
  String get ed25519PublicKeyBase64 => deviceKeypair.ed25519PublicKeyBase64;

  /// Loads existing device keypair from SharedPreferences or generates a new pair.
  ///
  /// Private keys are stored strictly in local device storage and NEVER
  /// broadcasted over mesh or transmitted over network.
  Future<void> initialize({String? deviceId, bool forceReload = false}) async {
    if (_initialized && _deviceKeypair != null && !forceReload) return;

    final prefs = await SharedPreferences.getInstance();
    final storedKeypairStr = prefs.getString(_storageKey);

    if (storedKeypairStr != null && storedKeypairStr.isNotEmpty) {
      try {
        _deviceKeypair = DeviceKeypair.fromSecureString(storedKeypairStr);
        _initialized = true;
        return;
      } catch (_) {
        // Corrupted storage; fall through to regenerate
      }
    }

    // Resolve or generate device ID
    String targetId = deviceId ?? '';
    if (targetId.isEmpty) {
      try {
        if (!DeviceIdentityService.instance.isInitialized) {
          await DeviceIdentityService.instance.initialize();
        }
        targetId = DeviceIdentityService.instance.deviceId;
      } catch (_) {
        targetId = 'SR-NODE-${_uuid.v4().substring(0, 8).toUpperCase()}';
      }
    }

    final newKeypair = await DeviceKeypair.generate(deviceId: targetId);
    await prefs.setString(_storageKey, newKeypair.toSecureString());
    _deviceKeypair = newKeypair;
    _initialized = true;
  }

  /// Encrypts plaintext bytes for a recipient peer using Ephemeral Diffie-Hellman + AES-256-GCM.
  ///
  /// Process:
  /// 1. Generates ephemeral X25519 keypair.
  /// 2. Computes shared secret via Diffie-Hellman: `X25519().sharedSecretKey(...)`.
  /// 3. Derives 256-bit symmetric encryption key via `Hkdf(hmac: Hmac.sha256())`.
  /// 4. Encrypts plaintext via `AesGcm.with256bits()`.
  /// 5. Signs ciphertext with local device Ed25519 private key.
  /// 6. Returns `EncryptedPayload(ephemeralPublicKey, nonce, ciphertext, authTag, signature)`.
  Future<EncryptedPayload> encryptForPeer({
    required Uint8List plaintext,
    required List<int> recipientPublicKeyBytes,
  }) async {
    if (!_initialized || _deviceKeypair == null) {
      await initialize();
    }
    final keypair = deviceKeypair;

    if (recipientPublicKeyBytes.length != 32) {
      throw ArgumentError(
          'Recipient X25519 public key must be 32 bytes (got ${recipientPublicKeyBytes.length})');
    }

    // 1. Generates ephemeral X25519 keypair
    final ephemeralKeyPair = await _x25519.newKeyPair();
    final ephemeralPublicKey = await ephemeralKeyPair.extractPublicKey();

    // 2. Computes shared secret via Diffie-Hellman
    final recipientKey = SimplePublicKey(
      recipientPublicKeyBytes,
      type: KeyPairType.x25519,
    );
    final sharedSecret = await _x25519.sharedSecretKey(
      keyPair: ephemeralKeyPair,
      remotePublicKey: recipientKey,
    );

    // 3. Derives 256-bit symmetric encryption key via HKDF
    final derivedKey = await _hkdf.deriveKey(
      secretKey: sharedSecret,
      nonce: _hkdfPeerSalt,
      info: _hkdfPeerInfo,
    );

    // 4. Encrypts plaintext via AES-GCM 256-bit
    final secretBox = await _aesGcm.encrypt(
      plaintext,
      secretKey: derivedKey,
    );

    // 5. Signs ciphertext with device Ed25519 private key
    final signature = await _ed25519.sign(
      secretBox.cipherText,
      keyPair: keypair.ed25519KeyPair,
    );

    // 6. Returns EncryptedPayload
    return EncryptedPayload(
      ephemeralPublicKey: ephemeralPublicKey.bytes,
      nonce: secretBox.nonce,
      ciphertext: secretBox.cipherText,
      authTag: secretBox.mac.bytes,
      signature: signature.bytes,
    );
  }

  /// Decrypts ciphertext from a peer, verifying the Ed25519 digital signature first.
  ///
  /// Process:
  /// 1. Verifies Ed25519 signature using `senderPublicKeyBytes` (sender's Ed25519 public key).
  /// 2. Computes shared secret using device X25519 private key + payload ephemeral public key.
  /// 3. Derives symmetric key via HKDF.
  /// 4. Decrypts ciphertext via AES-GCM and verifies 128-bit authentication tag.
  /// 5. Returns decrypted plaintext bytes.
  Future<Uint8List> decryptFromPeer({
    required EncryptedPayload payload,
    required List<int> senderPublicKeyBytes,
  }) async {
    if (!_initialized || _deviceKeypair == null) {
      await initialize();
    }
    final keypair = deviceKeypair;

    if (senderPublicKeyBytes.length != 32) {
      throw ArgumentError(
          'Sender Ed25519 public key must be 32 bytes (got ${senderPublicKeyBytes.length})');
    }
    if (payload.ephemeralPublicKey.length != 32) {
      throw ArgumentError(
          'Payload ephemeral X25519 public key must be 32 bytes (got ${payload.ephemeralPublicKey.length})');
    }

    // 1. Verifies Ed25519 signature
    final senderSigningKey = SimplePublicKey(
      senderPublicKeyBytes,
      type: KeyPairType.ed25519,
    );
    final isValidSig = await _ed25519.verify(
      payload.ciphertext,
      signature: Signature(
        payload.signature,
        publicKey: senderSigningKey,
      ),
    );

    if (!isValidSig) {
      throw const CryptoSignatureException(
        'Ed25519 digital signature verification failed. Message may be forged or tampered.',
      );
    }

    // 2. Computes shared secret using device X25519 private key + payload ephemeral public key
    final ephemeralKey = SimplePublicKey(
      payload.ephemeralPublicKey,
      type: KeyPairType.x25519,
    );
    final sharedSecret = await _x25519.sharedSecretKey(
      keyPair: keypair.x25519KeyPair,
      remotePublicKey: ephemeralKey,
    );

    // 3. Derives symmetric key via HKDF
    final derivedKey = await _hkdf.deriveKey(
      secretKey: sharedSecret,
      nonce: _hkdfPeerSalt,
      info: _hkdfPeerInfo,
    );

    // 4. Decrypts ciphertext via AES-GCM and verifies 128-bit authentication tag
    try {
      final decrypted = await _aesGcm.decrypt(
        SecretBox(
          payload.ciphertext,
          nonce: payload.nonce,
          mac: Mac(payload.authTag),
        ),
        secretKey: derivedKey,
      );
      return Uint8List.fromList(decrypted);
    } catch (e) {
      throw CryptoDecryptionException(
          'AES-GCM decryption failed or authentication tag mismatch: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // GROUP ENCRYPTION SUPPORT
  // ---------------------------------------------------------------------------

  /// Generates a cryptographically secure 256-bit (32 bytes) symmetric key for shared group channels.
  Future<List<int>> generateGroupKey() async {
    final secretKey = await _aesGcm.newSecretKey();
    return await secretKey.extractBytes();
  }

  /// Encrypts plaintext for a group using the shared 256-bit symmetric group key.
  /// Also signs ciphertext with local Ed25519 private key for sender authenticity.
  Future<EncryptedPayload> encryptForGroup({
    required Uint8List plaintext,
    required List<int> groupKeyBytes,
  }) async {
    if (!_initialized || _deviceKeypair == null) {
      await initialize();
    }
    final keypair = deviceKeypair;

    if (groupKeyBytes.length != 32) {
      throw ArgumentError(
          'Group key must be 32 bytes (got ${groupKeyBytes.length})');
    }

    final secretKey = SecretKey(groupKeyBytes);
    final secretBox = await _aesGcm.encrypt(
      plaintext,
      secretKey: secretKey,
    );

    // Sign ciphertext with device Ed25519 key so group members know who originated it
    final signature = await _ed25519.sign(
      secretBox.cipherText,
      keyPair: keypair.ed25519KeyPair,
    );

    // Ephemeral public key is empty for group symmetric messages, or can store key identifier
    return EncryptedPayload(
      ephemeralPublicKey: const <int>[],
      nonce: secretBox.nonce,
      ciphertext: secretBox.cipherText,
      authTag: secretBox.mac.bytes,
      signature: signature.bytes,
    );
  }

  /// Decrypts ciphertext from a group channel using the shared 256-bit symmetric group key.
  /// If [senderEd25519PublicKeyBytes] is provided, verifies sender authenticity.
  Future<Uint8List> decryptFromGroup({
    required EncryptedPayload payload,
    required List<int> groupKeyBytes,
    List<int>? senderEd25519PublicKeyBytes,
  }) async {
    if (groupKeyBytes.length != 32) {
      throw ArgumentError(
          'Group key must be 32 bytes (got ${groupKeyBytes.length})');
    }

    // Optional sender verification
    if (senderEd25519PublicKeyBytes != null &&
        senderEd25519PublicKeyBytes.length == 32 &&
        payload.signature.isNotEmpty) {
      final senderKey = SimplePublicKey(
        senderEd25519PublicKeyBytes,
        type: KeyPairType.ed25519,
      );
      final isValid = await _ed25519.verify(
        payload.ciphertext,
        signature: Signature(payload.signature, publicKey: senderKey),
      );
      if (!isValid) {
        throw const CryptoSignatureException(
          'Group message Ed25519 signature verification failed.',
        );
      }
    }

    try {
      final secretKey = SecretKey(groupKeyBytes);
      final decrypted = await _aesGcm.decrypt(
        SecretBox(
          payload.ciphertext,
          nonce: payload.nonce,
          mac: Mac(payload.authTag),
        ),
        secretKey: secretKey,
      );
      return Uint8List.fromList(decrypted);
    } catch (e) {
      throw CryptoDecryptionException(
          'AES-GCM group decryption failed or auth tag mismatch: $e');
    }
  }

  /// Distributes a shared group key to a specific peer encrypted with peer's X25519 public key.
  Future<EncryptedPayload> encryptGroupKeyForPeer({
    required List<int> groupKeyBytes,
    required List<int> recipientX25519PublicKeyBytes,
  }) {
    return encryptForPeer(
      plaintext: Uint8List.fromList(groupKeyBytes),
      recipientPublicKeyBytes: recipientX25519PublicKeyBytes,
    );
  }

  /// Decrypts a shared group key received from a peer.
  Future<List<int>> decryptGroupKeyFromPeer({
    required EncryptedPayload payload,
    required List<int> senderEd25519PublicKeyBytes,
  }) {
    return decryptFromPeer(
      payload: payload,
      senderPublicKeyBytes: senderEd25519PublicKeyBytes,
    );
  }

  // ---------------------------------------------------------------------------
  // COMPLETE ENVELOPE WRAPPERS (RoutingHeader + EncryptedPayload)
  // ---------------------------------------------------------------------------

  /// Creates a ready-to-broadcast [EncryptedEnvelope] addressed to a specific peer.
  Future<EncryptedEnvelope> createEnvelopeForPeer({
    required Uint8List plaintext,
    required List<int> recipientX25519PublicKeyBytes,
    required String packetType,
    String? recipientUserId,
    String? recipientDeviceId,
    int ttl = 5,
    int? ttlSeconds,
    bool isInternetGateway = false,
    String? messageId,
  }) async {
    final payload = await encryptForPeer(
      plaintext: plaintext,
      recipientPublicKeyBytes: recipientX25519PublicKeyBytes,
    );

    final msgId = messageId ?? _uuid.v4();
    final header = RoutingHeader.create(
      messageId: msgId,
      senderDeviceId: deviceKeypair.deviceId,
      recipientUserId: recipientUserId,
      recipientDeviceId: recipientDeviceId,
      packetType: packetType,
      payloadSize: payload.ciphertext.length,
      ttl: ttl,
      ttlSeconds: ttlSeconds,
      isInternetGateway: isInternetGateway,
    );

    return EncryptedEnvelope(
      header: header,
      payload: payload,
    );
  }

  /// Decrypts an [EncryptedEnvelope] received from a peer.
  Future<Uint8List> decryptEnvelopeFromPeer({
    required EncryptedEnvelope envelope,
    required List<int> senderEd25519PublicKeyBytes,
  }) {
    return decryptFromPeer(
      payload: envelope.payload,
      senderPublicKeyBytes: senderEd25519PublicKeyBytes,
    );
  }

  /// Creates an [EncryptedEnvelope] addressed to a group channel.
  Future<EncryptedEnvelope> createEnvelopeForGroup({
    required Uint8List plaintext,
    required List<int> groupKeyBytes,
    required String packetType,
    String? groupId,
    int ttl = 5,
    int? ttlSeconds,
    bool isInternetGateway = false,
    String? messageId,
  }) async {
    final payload = await encryptForGroup(
      plaintext: plaintext,
      groupKeyBytes: groupKeyBytes,
    );

    final msgId = messageId ?? _uuid.v4();
    final header = RoutingHeader.create(
      messageId: msgId,
      senderDeviceId: deviceKeypair.deviceId,
      recipientUserId: groupId, // Group channel identifier
      packetType: packetType,
      payloadSize: payload.ciphertext.length,
      ttl: ttl,
      ttlSeconds: ttlSeconds,
      isInternetGateway: isInternetGateway,
    );

    return EncryptedEnvelope(
      header: header,
      payload: payload,
    );
  }

  /// Decrypts an [EncryptedEnvelope] received on a group channel.
  Future<Uint8List> decryptEnvelopeFromGroup({
    required EncryptedEnvelope envelope,
    required List<int> groupKeyBytes,
    List<int>? senderEd25519PublicKeyBytes,
  }) {
    return decryptFromGroup(
      payload: envelope.payload,
      groupKeyBytes: groupKeyBytes,
      senderEd25519PublicKeyBytes: senderEd25519PublicKeyBytes,
    );
  }

  // ---------------------------------------------------------------------------
  // CRYPTOGRAPHIC UTILITIES (using package:crypto/crypto.dart)
  // ---------------------------------------------------------------------------

  /// Computes SHA-256 digest in lowercase hexadecimal format.
  String computeSha256Hex(List<int> data) {
    return crypto.sha256.convert(data).toString();
  }

  /// Computes a peer safety number / verification fingerprint from public key bytes.
  String computeFingerprint(List<int> publicKeyBytes) {
    final digest = crypto.sha256.convert(publicKeyBytes);
    final hexStr = digest.toString().toUpperCase();
    final chunks = <String>[];
    for (var i = 0; i < 32; i += 4) {
      chunks.add(hexStr.substring(i, i + 4));
    }
    return chunks.join('-');
  }
}
