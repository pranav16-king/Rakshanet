import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../models/image_chunk.dart';
import 'bluetooth_radio_service.dart';
import 'media_storage_service.dart';

/// Progress information for an active chunked image transfer.
class ImageTransferProgress {
  final String messageId;
  final String attachmentId;
  final int sentChunks;
  final int totalChunks;
  final int currentChunkIndex;
  final double progress;

  const ImageTransferProgress({
    required this.messageId,
    required this.attachmentId,
    required this.sentChunks,
    required this.totalChunks,
    required this.currentChunkIndex,
  }) : progress = totalChunks > 0 ? sentChunks / totalChunks : 0.0;

  @override
  String toString() =>
      'ImageTransferProgress(msg: $messageId, att: $attachmentId, $sentChunks/$totalChunks [${(progress * 100).toStringAsFixed(1)}%])';
}

/// Callback signatures for test injection or custom transport layers.
typedef ChunkTransportSender = Future<bool> Function(
  ImageChunk chunk,
  String targetPeerId,
);
typedef ChunkTransportRelayer = Future<int> Function(ImageChunk chunk);

/// Encrypted Chunked Image Transfer with Resumption Service for RakshaNet.
///
/// Responsibilities:
/// 1. Prepares images by compressing, encrypting (X25519 Diffie-Hellman + AES-256-GCM),
///    chunking into 16 KB packets with SHA-256 checksums, and staging in SQLite outbox.
/// 2. Resilient transmission one chunk at a time over offline mesh radios with state
///    persistence. If a peer walks away at chunk 4, transfer resumes at chunk 4 upon reconnect.
/// 3. Ingestion of incoming chunks: validates SHA-256 integrity, stores durable chunk state,
///    relays encrypted chunks forward along the mesh without decrypting them, and
///    upon receiving all chunks, reassembles and decrypts using the device's private key.
class ImageTransferService {
  ImageTransferService._internal();

  /// Global singleton instance.
  static final ImageTransferService instance = ImageTransferService._internal();
  factory ImageTransferService() => instance;

  static const int defaultChunkSize = 16 * 1024; // 16 KB chunks for low-overhead BLE/WiFi
  static const String _prefPrivateKey = 'rakshanet_x25519_private_key';
  static const String _prefPublicKey = 'rakshanet_x25519_public_key';

  // Cryptography algorithms (Cryptographically hardened X25519 + AES-256-GCM + HKDF)
  final X25519 _x25519 = X25519();
  final AesGcm _aesGcm = AesGcm.with256bits();
  final Hkdf _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  SimpleKeyPair? _deviceKeyPair;

  // Pluggable transport hooks (defaults to BluetoothRadioService)
  ChunkTransportSender? transportSender;
  ChunkTransportRelayer? transportRelayer;

  // Stream controllers for transfer progress and completion events
  final StreamController<ImageTransferProgress> _progressController =
      StreamController<ImageTransferProgress>.broadcast();
  Stream<ImageTransferProgress> get progressStream =>
      _progressController.stream;

  final StreamController<String> _transferCompletedController =
      StreamController<String>.broadcast();
  Stream<String> get transferCompletedStream =>
      _transferCompletedController.stream;

  // =========================================================================
  // Device Cryptographic Keypair Management
  // =========================================================================

  /// Retrieves or lazily initializes the stable device X25519 keypair.
  Future<SimpleKeyPair> getDeviceKeyPair() async {
    if (_deviceKeyPair != null) {
      return _deviceKeyPair!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedPriv = prefs.getString(_prefPrivateKey);
      final storedPub = prefs.getString(_prefPublicKey);

      if (storedPriv != null && storedPub != null) {
        final privBytes = base64Decode(storedPriv);
        final pubBytes = base64Decode(storedPub);
        _deviceKeyPair = SimpleKeyPairData(
          privBytes,
          publicKey: SimplePublicKey(pubBytes, type: KeyPairType.x25519),
          type: KeyPairType.x25519,
        );
        return _deviceKeyPair!;
      }

      // Generate new keypair if not found
      final newPair = await _x25519.newKeyPair();
      final keyData = await newPair.extract();
      final pubKey = await newPair.extractPublicKey();

      await prefs.setString(_prefPrivateKey, base64Encode(keyData.bytes));
      await prefs.setString(_prefPublicKey, base64Encode(pubKey.bytes));

      _deviceKeyPair = SimpleKeyPairData(
        keyData.bytes,
        publicKey: pubKey,
        type: KeyPairType.x25519,
      );
      return _deviceKeyPair!;
    } catch (e) {
      debugPrint('[ImageTransferService] SharedPreferences error ($e). Using in-memory keypair.');
      _deviceKeyPair ??= await _x25519.newKeyPair();
      return _deviceKeyPair!;
    }
  }

  /// Returns the 32-byte public key of this device node.
  Future<List<int>> getDevicePublicKey() async {
    final keyPair = await getDeviceKeyPair();
    final pubKey = await keyPair.extractPublicKey();
    return pubKey.bytes;
  }

  /// Sets or overrides the device keypair (useful for unit testing and simulations).
  void setDeviceKeyPair(SimpleKeyPair keyPair) {
    _deviceKeyPair = keyPair;
  }

  /// Resets the cached in-memory keypair.
  void resetDeviceKeyPair() {
    _deviceKeyPair = null;
  }

  // =========================================================================
  // Image Preparation & Chunking (Sender)
  // =========================================================================

  /// Reads image bytes from [localFilePath], compresses if necessary, encrypts
  /// using [recipientPublicKey] via ephemeral X25519 + AES-256-GCM, splits into
  /// chunks (default 16 KB), computes SHA-256 checksums, stages them into
  /// SQLite `attachment_chunks` table, and returns the list of [ImageChunk].
  Future<List<ImageChunk>> prepareImageForTransfer(
    String localFilePath,
    String messageId, {
    required List<int> recipientPublicKey,
    int chunkSize = defaultChunkSize,
  }) async {
    final file = File(localFilePath);
    if (!await file.exists()) {
      throw ArgumentError('Source image file not found at $localFilePath');
    }

    final rawBytes = await file.readAsBytes();
    if (rawBytes.isEmpty) {
      throw ArgumentError('The selected image file is empty.');
    }

    // 1. Compress image bytes if gzip provides savings
    final compressedBytes = gzip.encode(rawBytes);
    final bool useCompression = compressedBytes.length < rawBytes.length;
    final payloadBuilder = BytesBuilder();
    // Prefix 1-byte compression flag: 0x01 = gzip compressed, 0x00 = raw
    payloadBuilder.addByte(useCompression ? 0x01 : 0x00);
    payloadBuilder.add(useCompression ? compressedBytes : rawBytes);
    final payloadToEncrypt = payloadBuilder.takeBytes();

    // 2. Encrypt using Recipient Public Key via X25519 DH + AES-256-GCM
    final fullEncryptedData = await _encryptPayload(
      payloadToEncrypt,
      recipientPublicKey: recipientPublicKey,
    );

    // 3. Split into 16 KB chunks with SHA-256 checksums
    final attachmentId =
        'ATT-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(999999)}';
    final totalChunks = (fullEncryptedData.isEmpty)
        ? 1
        : ((fullEncryptedData.length + chunkSize - 1) ~/ chunkSize);

    final appDocDir = await _getSafeStorageDirectory();
    final chunksDir = Directory(
      p.join(appDocDir.path, 'transfer_chunks', attachmentId),
    );
    if (!await chunksDir.exists()) {
      await chunksDir.create(recursive: true);
    }

    final List<ImageChunk> chunks = [];
    final db = AppDatabase.instance;

    for (int i = 0; i < totalChunks; i++) {
      final start = i * chunkSize;
      final end = min(start + chunkSize, fullEncryptedData.length);
      final chunkData = Uint8List.fromList(
        fullEncryptedData.sublist(start, end),
      );
      final checksum = ImageChunk.computeChecksum(chunkData);

      // Persist chunk to disk
      final chunkFile = File(p.join(chunksDir.path, '$i.chk'));
      await chunkFile.writeAsBytes(chunkData);

      final chunk = ImageChunk(
        messageId: messageId,
        attachmentId: attachmentId,
        chunkIndex: i,
        totalChunks: totalChunks,
        encryptedData: chunkData,
        checksum: checksum,
        byteLength: chunkData.length,
      );
      chunks.add(chunk);

      // Persist chunk record in SQLite `attachment_chunks` table
      await db.insert(
        'attachment_chunks',
        chunk.toDbMap(
          chunkPath: chunkFile.path,
          status: 'PENDING',
        ),
      );
    }

    debugPrint(
      '[ImageTransferService] Prepared ${chunks.length} chunks (${fullEncryptedData.length} encrypted bytes) for message $messageId',
    );
    return chunks;
  }

  // =========================================================================
  // Chunk Transmission with Resumption (Sender)
  // =========================================================================

  /// Transmits chunks for [messageId] to [targetPeerId] one-by-one.
  ///
  /// Resilient Resumption:
  /// - Queries unsent chunks (`status != 'SENT'`).
  /// - If the peer disconnects at chunk 4, previous chunks remain marked 'SENT'.
  /// - When the peer reconnects, calling [sendChunks] resumes from chunk 4
  ///   without restarting from chunk 0!
  Future<void> sendChunks(String messageId, String targetPeerId) async {
    final db = AppDatabase.instance;

    // Fetch all chunks for this message to accurately calculate total and sent count
    final allRows = await db.query(
      'attachment_chunks',
      where: 'message_id = ?',
      whereArgs: [messageId],
      orderBy: 'chunk_index ASC',
    );

    if (allRows.isEmpty) {
      debugPrint(
        '[ImageTransferService] No staged chunks found for message $messageId',
      );
      return;
    }

    final totalChunks = (allRows.first['total_chunks'] as num).toInt();
    int sentCount = allRows.where((r) => r['status'] == 'SENT').length;

    // Fetch only un-sent chunks (PENDING / not yet SENT)
    final pendingRows = await db.query(
      'attachment_chunks',
      where: 'message_id = ? AND status != ?',
      whereArgs: [messageId, 'SENT'],
      orderBy: 'chunk_index ASC',
    );

    if (pendingRows.isEmpty) {
      debugPrint(
        '[ImageTransferService] All $totalChunks chunks for message $messageId are already SENT.',
      );
      return;
    }

    debugPrint(
      '[ImageTransferService] Transmitting message $messageId: $sentCount/$totalChunks already sent. Resuming from chunk ${pendingRows.first['chunk_index']}...',
    );

    for (final row in pendingRows) {
      final chunkIndex = (row['chunk_index'] as num).toInt();
      final chunkPath = row['chunk_path'] as String?;
      final attachmentId = row['attachment_id'] as String;
      final checksum = row['checksum'] as String;

      Uint8List encryptedData;
      if (chunkPath != null && await File(chunkPath).exists()) {
        encryptedData = await File(chunkPath).readAsBytes();
      } else {
        debugPrint(
          '[ImageTransferService] Error: Missing chunk file at $chunkPath. Skipping chunk $chunkIndex.',
        );
        continue;
      }

      final chunk = ImageChunk(
        messageId: messageId,
        attachmentId: attachmentId,
        chunkIndex: chunkIndex,
        totalChunks: totalChunks,
        encryptedData: encryptedData,
        checksum: checksum,
        byteLength: encryptedData.length,
      );

      // Transmit single chunk across transport
      bool success = false;
      try {
        if (transportSender != null) {
          success = await transportSender!(chunk, targetPeerId);
        } else {
          success = await BluetoothRadioService.instance.sendBytesToEndpoint(
            targetPeerId,
            chunk.toBytes(),
          );
        }
      } catch (e) {
        debugPrint(
          '[ImageTransferService] Transport transmission error on chunk $chunkIndex: $e',
        );
        success = false;
      }

      if (success) {
        sentCount++;
        // Durably mark chunk as SENT in SQLite
        await db.update(
          'attachment_chunks',
          {
            'status': 'SENT',
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [row['id']],
        );

        final progress = ImageTransferProgress(
          messageId: messageId,
          attachmentId: attachmentId,
          sentChunks: sentCount,
          totalChunks: totalChunks,
          currentChunkIndex: chunkIndex,
        );
        _progressController.add(progress);
        debugPrint(
          '[ImageTransferService] Transmitted chunk $chunkIndex. Progress: $sentCount/$totalChunks',
        );
      } else {
        // Peer disconnected or link failed:
        // Chunk remains PENDING in SQLite. Do NOT restart on next attempt!
        debugPrint(
          '[ImageTransferService] Peer $targetPeerId disconnected at chunk $chunkIndex. '
          'Saved transfer state ($sentCount/$totalChunks sent). Will resume from chunk $chunkIndex upon reconnect.',
        );
        break; // Exit sending loop to allow resumption later
      }
    }
  }

  // =========================================================================
  // Chunk Ingestion, Validation, Reassembly & Forwarding (Receiver / Relay)
  // =========================================================================

  /// Handles an incoming [ImageChunk] over the mesh network.
  ///
  /// Flow:
  /// 1. Validates SHA-256 checksum integrity.
  /// 2. Saves chunk data to local storage and marks status 'RECEIVED' in SQLite.
  /// 3. Relays forward chunk without decrypting (store-and-forward mesh routing).
  /// 4. Checks if all [totalChunks] have been received for [attachmentId].
  /// 5. If all chunks arrived: reassembles chunks in order -> decrypts using
  ///    device private key -> saves reassembled file to app media directory ->
  ///    marks transfer complete!
  Future<bool> handleIncomingChunk(ImageChunk chunk) async {
    // 1. Validate SHA-256 checksum integrity
    if (!chunk.isValidChecksum()) {
      debugPrint(
        '[ImageTransferService] Integrity failure: Checksum mismatch for chunk ${chunk.chunkIndex} of attachment ${chunk.attachmentId}. Dropping packet.',
      );
      return false;
    }

    // 2. Persist chunk bytes to private app storage
    final appDocDir = await _getSafeStorageDirectory();
    final incomingDir = Directory(
      p.join(appDocDir.path, 'received_chunks', chunk.attachmentId),
    );
    if (!await incomingDir.exists()) {
      await incomingDir.create(recursive: true);
    }

    final chunkFile = File(p.join(incomingDir.path, '${chunk.chunkIndex}.chk'));
    await chunkFile.writeAsBytes(chunk.encryptedData);

    // Save record to SQLite
    final db = AppDatabase.instance;
    await db.insert(
      'attachment_chunks',
      chunk.toDbMap(
        chunkPath: chunkFile.path,
        status: 'RECEIVED',
      ),
    );

    // 3. Relay forward chunk without decrypting!
    await relayChunk(chunk);

    // 4. Check if all chunks have been received for this attachment
    final allAttachmentRows = await db.query(
      'attachment_chunks',
      where: 'attachment_id = ?',
      whereArgs: [chunk.attachmentId],
      orderBy: 'chunk_index ASC',
    );

    // If already reassembled and completed, no need to re-run
    if (allAttachmentRows.any((r) => r['status'] == 'COMPLETED')) {
      return true;
    }

    final receivedRows = allAttachmentRows
        .where((r) => r['status'] == 'RECEIVED')
        .toList();
    final receivedIndices =
        receivedRows.map((r) => (r['chunk_index'] as num).toInt()).toSet();
    final bool isAllReceived = receivedIndices.length >= chunk.totalChunks;

    if (!isAllReceived) {
      debugPrint(
        '[ImageTransferService] Received chunk ${chunk.chunkIndex}/${chunk.totalChunks} for ${chunk.attachmentId} (${receivedIndices.length}/${chunk.totalChunks} total received).',
      );
      return true;
    }

    // 5. All chunks received! Reassemble and decrypt
    debugPrint(
      '[ImageTransferService] All ${chunk.totalChunks} chunks received for ${chunk.attachmentId}. Starting reassembly...',
    );

    final fullEncryptedBuilder = BytesBuilder();
    for (int i = 0; i < chunk.totalChunks; i++) {
      final rowMatch = receivedRows.where(
        (r) => (r['chunk_index'] as num).toInt() == i,
      );
      if (rowMatch.isEmpty) {
        debugPrint('[ImageTransferService] Missing chunk $i during reassembly.');
        return false;
      }
      final path = rowMatch.first['chunk_path'] as String?;
      if (path == null || !await File(path).exists()) {
        debugPrint('[ImageTransferService] Missing chunk file $path on disk.');
        return false;
      }
      fullEncryptedBuilder.add(await File(path).readAsBytes());
    }

    final fullEncryptedBytes = fullEncryptedBuilder.takeBytes();

    // Decrypt using device private key
    Uint8List? decryptedBytes;
    try {
      decryptedBytes = await _decryptPayload(fullEncryptedBytes);
    } catch (e) {
      debugPrint(
        '[ImageTransferService] Notice: Could not decrypt payload with local device key ($e). '
        'This node is acting as an encrypted intermediate relay.',
      );
    }

    if (decryptedBytes != null) {
      // Save reassembled decrypted image into app media directory
      final mediaStorage = MediaStorageService();
      final destinationPath = await mediaStorage.createDestination(
        'img_${chunk.attachmentId}.jpg',
      );
      await File(destinationPath).writeAsBytes(decryptedBytes);

      // Mark transfer complete in SQLite
      await db.update(
        'attachment_chunks',
        {
          'status': 'COMPLETED',
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'attachment_id = ?',
        whereArgs: [chunk.attachmentId],
      );

      // Update message record if present
      await db.update(
        'messages',
        {
          'attachment_path': destinationPath,
          'status': 'DELIVERED',
        },
        where: 'message_id = ?',
        whereArgs: [chunk.messageId],
      );

      _transferCompletedController.add(destinationPath);
      debugPrint(
        '[ImageTransferService] Image transfer complete! Saved to $destinationPath',
      );
    }

    return true;
  }

  /// Relays an encrypted chunk to neighboring mesh peers without decrypting.
  Future<int> relayChunk(ImageChunk chunk) async {
    try {
      if (transportRelayer != null) {
        return await transportRelayer!(chunk);
      }
      return await BluetoothRadioService.instance.broadcastBytes(
        chunk.toBytes(),
      );
    } catch (e) {
      debugPrint('[ImageTransferService] Relay forward error: $e');
      return 0;
    }
  }

  // =========================================================================
  // Internal Cryptographic Primitives (X25519 DH + AES-256-GCM + HKDF)
  // =========================================================================

  /// Encrypts raw bytes using the recipient's public key.
  ///
  /// Output format:
  /// - 4 bytes: Header Magic [0x52, 0x4B, 0x45, 0x31] ("RKE1")
  /// - 32 bytes: Sender's Ephemeral X25519 Public Key
  /// - 12 bytes: AES-GCM Nonce
  /// - 16 bytes: AES-GCM MAC tag
  /// - N bytes: Ciphertext
  Future<Uint8List> _encryptPayload(
    Uint8List plaintext, {
    required List<int> recipientPublicKey,
  }) async {
    // 1. Generate ephemeral X25519 keypair for Perfect Forward Secrecy
    final ephemeralKeyPair = await _x25519.newKeyPair();
    final ephemeralPubKey = await ephemeralKeyPair.extractPublicKey();

    final remotePubKey = SimplePublicKey(
      recipientPublicKey,
      type: KeyPairType.x25519,
    );

    // 2. Compute shared secret
    final sharedSecret = await _x25519.sharedSecretKey(
      keyPair: ephemeralKeyPair,
      remotePublicKey: remotePubKey,
    );

    // 3. Derive AES-256 key via HKDF
    final sessionKey = await _hkdf.deriveKey(
      secretKey: sharedSecret,
      nonce: utf8.encode('RakshaNet-Image-Salt'),
      info: utf8.encode('RakshaNet-Image-Session-Key'),
    );

    // 4. Encrypt with AES-GCM 256-bit
    final secretBox = await _aesGcm.encrypt(
      plaintext,
      secretKey: sessionKey,
    );

    final outBuilder = BytesBuilder();
    // Magic "RKE1"
    outBuilder.add([0x52, 0x4B, 0x45, 0x31]);
    outBuilder.add(ephemeralPubKey.bytes); // 32 bytes
    outBuilder.add(secretBox.nonce); // 12 bytes
    outBuilder.add(secretBox.mac.bytes); // 16 bytes
    outBuilder.add(secretBox.cipherText); // N bytes

    return outBuilder.takeBytes();
  }

  /// Decrypts encrypted payload using the local device's private key.
  Future<Uint8List> _decryptPayload(Uint8List encryptedPayload) async {
    if (encryptedPayload.length < 64) {
      throw const FormatException('Encrypted payload too short to contain RKE1 header.');
    }

    // Verify "RKE1" magic
    if (encryptedPayload[0] != 0x52 ||
        encryptedPayload[1] != 0x4B ||
        encryptedPayload[2] != 0x45 ||
        encryptedPayload[3] != 0x31) {
      throw const FormatException('Unsupported image encryption format header.');
    }

    final ephemeralPubBytes = encryptedPayload.sublist(4, 36);
    final nonce = encryptedPayload.sublist(36, 48);
    final macBytes = encryptedPayload.sublist(48, 64);
    final cipherText = encryptedPayload.sublist(64);

    final deviceKey = await getDeviceKeyPair();
    final remoteEphemeralKey = SimplePublicKey(
      ephemeralPubBytes,
      type: KeyPairType.x25519,
    );

    // Compute shared secret
    final sharedSecret = await _x25519.sharedSecretKey(
      keyPair: deviceKey,
      remotePublicKey: remoteEphemeralKey,
    );

    // Derive same session key via HKDF
    final sessionKey = await _hkdf.deriveKey(
      secretKey: sharedSecret,
      nonce: utf8.encode('RakshaNet-Image-Salt'),
      info: utf8.encode('RakshaNet-Image-Session-Key'),
    );

    // Decrypt AES-GCM
    final decrypted = await _aesGcm.decrypt(
      SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes)),
      secretKey: sessionKey,
    );

    if (decrypted.isEmpty) {
      return Uint8List(0);
    }

    // Check compression flag: 0x01 = gzip compressed, 0x00 = raw
    final isCompressed = decrypted[0] == 0x01;
    final payloadBytes = decrypted.sublist(1);

    if (isCompressed) {
      return Uint8List.fromList(gzip.decode(payloadBytes));
    } else {
      return Uint8List.fromList(payloadBytes);
    }
  }

  /// Safe documents directory getter that falls back gracefully in headless tests.
  Future<Directory> _getSafeStorageDirectory() async {
    try {
      return await getApplicationDocumentsDirectory();
    } catch (_) {
      final tmp = Directory(p.join(Directory.systemTemp.path, 'rakshanet_test'));
      if (!await tmp.exists()) {
        await tmp.create(recursive: true);
      }
      return tmp;
    }
  }

  void dispose() {
    _progressController.close();
    _transferCompletedController.close();
  }
}
