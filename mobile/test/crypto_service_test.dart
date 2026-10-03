import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rakshanet_mobile/models/crypto/device_keypair.dart';
import 'package:rakshanet_mobile/models/crypto/encrypted_envelope.dart';
import 'package:rakshanet_mobile/services/crypto/crypto_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DeviceKeypair & DevicePublicKeys Tests', () {
    test('generate creates valid 32-byte keypairs and non-empty IDs', () async {
      final keypair = await DeviceKeypair.generate(deviceId: 'SR-TEST-0001');

      expect(keypair.deviceId, 'SR-TEST-0001');
      expect(keypair.x25519PrivateKey.length, 32);
      expect(keypair.x25519PublicKey.length, 32);
      expect(keypair.ed25519PrivateKey.length, 32);
      expect(keypair.ed25519PublicKey.length, 32);
      expect(keypair.x25519PublicKeyBase64.isNotEmpty, isTrue);
      expect(keypair.ed25519PublicKeyBase64.isNotEmpty, isTrue);

      // Verify toString() does not reveal private key bytes
      final str = keypair.toString();
      expect(str, contains('[PRIVATE KEYS REDACTED]'));
      expect(str, isNot(contains(base64Encode(keypair.x25519PrivateKey))));
      expect(str, isNot(contains(base64Encode(keypair.ed25519PrivateKey))));
    });

    test('secure serialization round-trip succeeds', () async {
      final original = await DeviceKeypair.generate(deviceId: 'SR-TEST-0002');
      final secureStr = original.toSecureString();

      final restored = DeviceKeypair.fromSecureString(secureStr);
      expect(restored.deviceId, original.deviceId);
      expect(restored.x25519PrivateKey, equals(original.x25519PrivateKey));
      expect(restored.x25519PublicKey, equals(original.x25519PublicKey));
      expect(restored.ed25519PrivateKey, equals(original.ed25519PrivateKey));
      expect(restored.ed25519PublicKey, equals(original.ed25519PublicKey));
      expect(restored.createdAt.millisecondsSinceEpoch,
          original.createdAt.millisecondsSinceEpoch);
    });

    test('DevicePublicKeys serialization and fingerprint work', () async {
      final keypair = await DeviceKeypair.generate(deviceId: 'SR-NODE-A');
      final publicKeys = keypair.toPublicKeys();

      expect(publicKeys.deviceId, 'SR-NODE-A');
      expect(publicKeys.x25519PublicKey, equals(keypair.x25519PublicKey));
      expect(publicKeys.ed25519PublicKey, equals(keypair.ed25519PublicKey));
      expect(publicKeys.fingerprint.isNotEmpty, isTrue);
      expect(publicKeys.fingerprint, contains('-'));
      expect(publicKeys.shortFingerprint.length, lessThanOrEqualTo(publicKeys.fingerprint.length));

      // JSON roundtrip
      final json = publicKeys.toJson();
      final fromJson = DevicePublicKeys.fromJson(json);
      expect(fromJson.deviceId, publicKeys.deviceId);
      expect(fromJson.x25519PublicKey, equals(publicKeys.x25519PublicKey));
      expect(fromJson.ed25519PublicKey, equals(publicKeys.ed25519PublicKey));
      expect(fromJson.fingerprint, equals(publicKeys.fingerprint));
    });
  });

  group('CryptoService E2EE Peer Tests', () {
    test('Alice can encrypt for Bob and Bob can decrypt with signature verification', () async {
      // 1. Initialize Alice and Bob keypairs
      final aliceKeypair = await DeviceKeypair.generate(deviceId: 'SR-ALICE');
      final bobKeypair = await DeviceKeypair.generate(deviceId: 'SR-BOB');

      // Setup CryptoService as Alice
      SharedPreferences.setMockInitialValues({
        'rakshanet_secure_device_keypair_v1': aliceKeypair.toSecureString(),
      });
      final aliceService = CryptoService.instance;
      await aliceService.initialize();

      // Alice encrypts for Bob
      final message = 'CRITICAL SOS: Injured hiker at coordinate 12.9716, 77.5946';
      final plaintext = Uint8List.fromList(utf8.encode(message));

      final encryptedPayload = await aliceService.encryptForPeer(
        plaintext: plaintext,
        recipientPublicKeyBytes: bobKeypair.x25519PublicKey,
      );

      expect(encryptedPayload.ephemeralPublicKey.length, 32);
      expect(encryptedPayload.nonce.length, 12);
      expect(encryptedPayload.authTag.length, 16);
      expect(encryptedPayload.signature.length, 64);
      expect(encryptedPayload.ciphertext, isNot(equals(plaintext)));

      // 2. Bob receives encrypted payload and decrypts it
      SharedPreferences.setMockInitialValues({
        'rakshanet_secure_device_keypair_v1': bobKeypair.toSecureString(),
      });
      final bobService = CryptoService.instance;
      await bobService.initialize(forceReload: true);

      final decryptedBytes = await bobService.decryptFromPeer(
        payload: encryptedPayload,
        senderPublicKeyBytes: aliceKeypair.ed25519PublicKey,
      );

      expect(utf8.decode(decryptedBytes), equals(message));

      // 3. Bob replies back to Alice
      final replyText = 'ROGER: Search and rescue team dispatched to coordinates.';
      final replyEnvelope = await bobService.createEnvelopeForPeer(
        plaintext: Uint8List.fromList(utf8.encode(replyText)),
        recipientX25519PublicKeyBytes: aliceKeypair.x25519PublicKey,
        packetType: 'SOS_ACK',
        recipientDeviceId: aliceKeypair.deviceId,
      );

      expect(replyEnvelope.header.packetType, 'SOS_ACK');
      expect(replyEnvelope.header.recipientDeviceId, 'SR-ALICE');

      // Alice receives reply and decrypts
      SharedPreferences.setMockInitialValues({
        'rakshanet_secure_device_keypair_v1': aliceKeypair.toSecureString(),
      });
      await aliceService.initialize(forceReload: true);

      final decryptedReply = await aliceService.decryptEnvelopeFromPeer(
        envelope: replyEnvelope,
        senderEd25519PublicKeyBytes: bobKeypair.ed25519PublicKey,
      );
      expect(utf8.decode(decryptedReply), equals(replyText));
    });

    test('Each message uses fresh ephemeral keypair and unique nonce (Forward Secrecy property)', () async {
      final keypair = await DeviceKeypair.generate(deviceId: 'SR-FS-TEST');
      final peer = await DeviceKeypair.generate(deviceId: 'SR-PEER');

      SharedPreferences.setMockInitialValues({
        'rakshanet_secure_device_keypair_v1': keypair.toSecureString(),
      });
      await CryptoService.instance.initialize(forceReload: true);

      final msg = Uint8List.fromList(utf8.encode('Same message repeated'));
      final p1 = await CryptoService.instance.encryptForPeer(
        plaintext: msg,
        recipientPublicKeyBytes: peer.x25519PublicKey,
      );
      final p2 = await CryptoService.instance.encryptForPeer(
        plaintext: msg,
        recipientPublicKeyBytes: peer.x25519PublicKey,
      );

      // Ephemeral public keys must be distinct
      expect(p1.ephemeralPublicKey, isNot(equals(p2.ephemeralPublicKey)));
      // Nonces must be distinct
      expect(p1.nonce, isNot(equals(p2.nonce)));
      // Ciphertexts must be distinct
      expect(p1.ciphertext, isNot(equals(p2.ciphertext)));
    });
  });

  group('Cryptographic Tamper and Forgery Resistance Tests', () {
    test('Tampered ciphertext causes decryption failure', () async {
      final aliceKey = await DeviceKeypair.generate(deviceId: 'SR-ALICE-1');
      final bobKey = await DeviceKeypair.generate(deviceId: 'SR-BOB-1');

      SharedPreferences.setMockInitialValues({
        'rakshanet_secure_device_keypair_v1': aliceKey.toSecureString(),
      });
      await CryptoService.instance.initialize();

      final payload = await CryptoService.instance.encryptForPeer(
        plaintext: Uint8List.fromList(utf8.encode('Secret evacuation plan')),
        recipientPublicKeyBytes: bobKey.x25519PublicKey,
      );

      // Tamper with ciphertext
      final tamperedCiphertext = List<int>.from(payload.ciphertext);
      tamperedCiphertext[0] ^= 0xFF;

      final tamperedPayload = EncryptedPayload(
        ephemeralPublicKey: payload.ephemeralPublicKey,
        nonce: payload.nonce,
        ciphertext: tamperedCiphertext,
        authTag: payload.authTag,
        signature: payload.signature,
      );

      // Signature verification should fail because Ed25519 signed the original ciphertext
      expect(
        () async => await CryptoService.instance.decryptFromPeer(
          payload: tamperedPayload,
          senderPublicKeyBytes: aliceKey.ed25519PublicKey,
        ),
        throwsA(isA<CryptoSignatureException>()),
      );
    });

    test('Wrong sender public key causes signature verification failure', () async {
      final aliceKey = await DeviceKeypair.generate(deviceId: 'SR-ALICE-2');
      final eveKey = await DeviceKeypair.generate(deviceId: 'SR-EVE-ATTACKER');
      final bobKey = await DeviceKeypair.generate(deviceId: 'SR-BOB-2');

      SharedPreferences.setMockInitialValues({
        'rakshanet_secure_device_keypair_v1': aliceKey.toSecureString(),
      });
      await CryptoService.instance.initialize();

      final payload = await CryptoService.instance.encryptForPeer(
        plaintext: Uint8List.fromList(utf8.encode('Legitimate SOS message')),
        recipientPublicKeyBytes: bobKey.x25519PublicKey,
      );

      // Bob tries to verify using Eve's public key instead of Alice's
      expect(
        () async => await CryptoService.instance.decryptFromPeer(
          payload: payload,
          senderPublicKeyBytes: eveKey.ed25519PublicKey,
        ),
        throwsA(isA<CryptoSignatureException>()),
      );
    });
  });

  group('Group Encryption Tests', () {
    test('Group key generation and symmetric AES-256-GCM encryption/decryption', () async {
      final service = CryptoService.instance;
      final groupKey = await service.generateGroupKey();

      expect(groupKey.length, 32); // 256 bits

      final groupMsg = 'TRIAGE_TEAM_UPDATE: Zone C evacuated';
      final plaintext = Uint8List.fromList(utf8.encode(groupMsg));

      final payload = await service.encryptForGroup(
        plaintext: plaintext,
        groupKeyBytes: groupKey,
      );

      expect(payload.nonce.length, 12);
      expect(payload.authTag.length, 16);
      expect(payload.signature.length, 64);

      // Decrypt with valid key
      final decrypted = await service.decryptFromGroup(
        payload: payload,
        groupKeyBytes: groupKey,
        senderEd25519PublicKeyBytes: service.ed25519PublicKey,
      );

      expect(utf8.decode(decrypted), equals(groupMsg));

      // Decrypt with incorrect key should fail
      final invalidKey = List<int>.filled(32, 0xAA);
      expect(
        () async => await service.decryptFromGroup(
          payload: payload,
          groupKeyBytes: invalidKey,
        ),
        throwsA(isA<CryptoDecryptionException>()),
      );
    });
  });

  group('EncryptedEnvelope & RoutingHeader Serialization Tests', () {
    test('JSON serialization roundtrip works accurately', () {
      final header = RoutingHeader.create(
        messageId: 'MSG-001',
        senderDeviceId: 'SR-DEV-A',
        recipientUserId: 'commander@rescue.org',
        recipientDeviceId: 'SR-DEV-B',
        packetType: 'SOS',
        payloadSize: 128,
        ttl: 4,
        hopCount: 1,
      );

      final payload = EncryptedPayload(
        ephemeralPublicKey: List.filled(32, 1),
        nonce: List.filled(12, 2),
        ciphertext: List.filled(64, 3),
        authTag: List.filled(16, 4),
        signature: List.filled(64, 5),
      );

      final envelope = EncryptedEnvelope(header: header, payload: payload);
      final json = envelope.toJson();

      final restored = EncryptedEnvelope.fromJson(json);
      expect(restored.header.messageId, 'MSG-001');
      expect(restored.header.senderDeviceId, 'SR-DEV-A');
      expect(restored.header.recipientUserId, 'commander@rescue.org');
      expect(restored.header.recipientDeviceId, 'SR-DEV-B');
      expect(restored.header.packetType, 'SOS');
      expect(restored.header.payloadSize, 128);
      expect(restored.header.ttl, 4);
      expect(restored.header.hopCount, 1);

      expect(restored.payload.ephemeralPublicKey, equals(payload.ephemeralPublicKey));
      expect(restored.payload.nonce, equals(payload.nonce));
      expect(restored.payload.ciphertext, equals(payload.ciphertext));
      expect(restored.payload.authTag, equals(payload.authTag));
      expect(restored.payload.signature, equals(payload.signature));
    });

    test('Compact binary serialization roundtrip works accurately', () {
      final header = RoutingHeader.create(
        messageId: 'MSG-BIN-002',
        senderDeviceId: 'SR-DEV-RELAY-1',
        recipientUserId: 'victim@rakshanet.in',
        packetType: 'CHAT',
        payloadSize: 32,
        ttl: 5,
        hopCount: 0,
      );

      final payload = EncryptedPayload(
        ephemeralPublicKey: List.generate(32, (i) => i),
        nonce: List.generate(12, (i) => i * 2),
        ciphertext: List.generate(48, (i) => 255 - i),
        authTag: List.generate(16, (i) => i + 10),
        signature: List.generate(64, (i) => (i * 3) % 256),
      );

      final envelope = EncryptedEnvelope(header: header, payload: payload);
      final binaryBytes = envelope.toBytes(useBinaryFormat: true);

      // Must start with magic bytes 'RNE\x01'
      expect(binaryBytes.length, greaterThan(4));
      expect(binaryBytes.sublist(0, 4), equals(EncryptedEnvelope.magicBytes));

      final restored = EncryptedEnvelope.fromBytes(binaryBytes);
      expect(restored.header.messageId, 'MSG-BIN-002');
      expect(restored.header.senderDeviceId, 'SR-DEV-RELAY-1');
      expect(restored.header.recipientUserId, 'victim@rakshanet.in');
      expect(restored.payload.ciphertext, equals(payload.ciphertext));
      expect(restored.payload.ephemeralPublicKey, equals(payload.ephemeralPublicKey));
      expect(restored.payload.nonce, equals(payload.nonce));
      expect(restored.payload.authTag, equals(payload.authTag));
      expect(restored.payload.signature, equals(payload.signature));
    });

    test('copyForRelay decrements TTL and increments hop count while preserving payload', () {
      final header = RoutingHeader.create(
        messageId: 'RELAY-TEST-1',
        senderDeviceId: 'SR-SENDER',
        packetType: 'TEXT',
        payloadSize: 50,
        ttl: 5,
        hopCount: 0,
      );

      final payload = EncryptedPayload(
        ephemeralPublicKey: [1, 2, 3],
        nonce: [4, 5, 6],
        ciphertext: [7, 8, 9],
        authTag: [10, 11, 12],
        signature: [13, 14, 15],
      );

      final envelope = EncryptedEnvelope(header: header, payload: payload);
      final hop1 = envelope.copyForRelay();

      expect(hop1.header.ttl, 4);
      expect(hop1.header.hopCount, 1);
      expect(hop1.payload.ciphertext, equals(payload.ciphertext));

      final hop2 = hop1.copyForRelay();
      expect(hop2.header.ttl, 3);
      expect(hop2.header.hopCount, 2);
      expect(hop2.payload.ciphertext, equals(payload.ciphertext));
    });
  });

  group('Cryptographic Utilities Tests', () {
    test('computeSha256Hex and computeFingerprint format properly', () {
      final service = CryptoService.instance;
      final hash = service.computeSha256Hex(utf8.encode('RakshaNet-Zero-Trust'));
      expect(hash.length, 64);

      final dummyKey = List.generate(32, (i) => i);
      final fingerprint = service.computeFingerprint(dummyKey);
      expect(fingerprint.length, 39); // 8 groups of 4 hex chars + 7 hyphens
      expect(fingerprint, matches(r'^[0-9A-F]{4}(-[0-9A-F]{4}){7}$'));
    });
  });
}
