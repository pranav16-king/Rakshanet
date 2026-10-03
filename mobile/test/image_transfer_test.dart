import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:rakshanet_mobile/database/app_database.dart';
import 'package:rakshanet_mobile/models/image_chunk.dart';
import 'package:rakshanet_mobile/services/image_transfer_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('rakshanet_img_test_');
    await AppDatabase.instance.ensureInitialized();
  });

  tearDownAll(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('ImageChunk Model Tests', () {
    test('JSON serialization and deserialization roundtrip', () {
      final rawData = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
      final chunk = ImageChunk(
        messageId: 'MSG-001',
        attachmentId: 'ATT-999',
        chunkIndex: 2,
        totalChunks: 5,
        encryptedData: rawData,
      );

      expect(chunk.isValidChecksum(), isTrue);
      expect(chunk.byteLength, 10);

      final json = chunk.toJson();
      final restored = ImageChunk.fromJson(json);

      expect(restored.messageId, chunk.messageId);
      expect(restored.attachmentId, chunk.attachmentId);
      expect(restored.chunkIndex, chunk.chunkIndex);
      expect(restored.totalChunks, chunk.totalChunks);
      expect(restored.encryptedData, chunk.encryptedData);
      expect(restored.checksum, chunk.checksum);
      expect(restored.byteLength, chunk.byteLength);
      expect(restored.isValidChecksum(), isTrue);
    });

    test('Binary network byte serialization and deserialization roundtrip', () {
      final rawData = Uint8List.fromList(List.generate(256, (i) => i % 256));
      final chunk = ImageChunk(
        messageId: 'MSG-TEST-BINARY-1234',
        attachmentId: 'ATT-ATTACH-5678',
        chunkIndex: 3,
        totalChunks: 8,
        encryptedData: rawData,
      );

      final binaryBytes = chunk.toBytes();
      expect(binaryBytes.length, greaterThan(23));

      final restored = ImageChunk.fromBytes(binaryBytes);
      expect(restored.messageId, chunk.messageId);
      expect(restored.attachmentId, chunk.attachmentId);
      expect(restored.chunkIndex, chunk.chunkIndex);
      expect(restored.totalChunks, chunk.totalChunks);
      expect(restored.encryptedData, chunk.encryptedData);
      expect(restored.checksum, chunk.checksum);
      expect(restored.byteLength, chunk.byteLength);
      expect(restored.isValidChecksum(), isTrue);
    });

    test('Checksum detects payload tampering', () {
      final rawData = Uint8List.fromList([10, 20, 30, 40]);
      final chunk = ImageChunk(
        messageId: 'MSG-CORRUPT',
        attachmentId: 'ATT-CORRUPT',
        chunkIndex: 0,
        totalChunks: 1,
        encryptedData: rawData,
      );
      expect(chunk.isValidChecksum(), isTrue);

      // Corrupt payload
      final corruptedChunk = ImageChunk(
        messageId: chunk.messageId,
        attachmentId: chunk.attachmentId,
        chunkIndex: chunk.chunkIndex,
        totalChunks: chunk.totalChunks,
        encryptedData: Uint8List.fromList([99, 99, 99, 99]),
        checksum: chunk.checksum, // Keep old checksum
      );
      expect(corruptedChunk.isValidChecksum(), isFalse);
    });
  });

  group('ImageTransferService - End-to-End Encrypted Transfer & Resumption', () {
    test('prepareImageForTransfer, sendChunks with resumption, and handleIncomingChunk', () async {
      final transferService = ImageTransferService.instance;

      // 1. Setup Alice (Sender) and Bob (Receiver) keypairs
      final x25519 = X25519();
      final bobKeyPair = await x25519.newKeyPair();
      final bobPublicKey = (await bobKeyPair.extractPublicKey()).bytes;

      // 2. Create a test image file (~45 KB to produce at least 3 chunks of 16 KB each)
      final sampleImageFile = File(p.join(tempDir.path, 'sample_disaster_photo.jpg'));
      final random = Random(42);
      final originalImageBytes = Uint8List.fromList(
        List.generate(45 * 1024, (_) => random.nextInt(256)),
      );
      await sampleImageFile.writeAsBytes(originalImageBytes);

      final messageId = 'MSG-RESCUE-${DateTime.now().millisecondsSinceEpoch}';

      // 3. Prepare Image for Transfer (Sender side)
      final chunks = await transferService.prepareImageForTransfer(
        sampleImageFile.path,
        messageId,
        recipientPublicKey: bobPublicKey,
        chunkSize: 16 * 1024, // 16 KB chunks
      );

      expect(chunks.length, greaterThanOrEqualTo(3));
      for (final chunk in chunks) {
        expect(chunk.isValidChecksum(), isTrue);
        expect(chunk.messageId, messageId);
      }

      // 4. Verify SQLite tracking rows created in attachment_chunks table with status PENDING
      final unsentRows = await AppDatabase.instance.getUnsentChunks(messageId);
      expect(unsentRows.length, chunks.length);
      for (final row in unsentRows) {
        expect(row['status'], 'PENDING');
      }

      // 5. Test sendChunks with SIMULATED PEER DISCONNECT at chunk index 2
      final transmittedChunks = <ImageChunk>[];
      int attemptsCount = 0;
      bool simulateDisconnect = true;

      transferService.transportSender = (chunk, targetPeerId) async {
        attemptsCount++;
        if (simulateDisconnect && chunk.chunkIndex == 2) {
          // Simulate peer walked out of range / radio dropped at chunk 2!
          return false;
        }
        transmittedChunks.add(chunk);
        return true;
      };

      // Listen to progress updates
      final progressEvents = <ImageTransferProgress>[];
      final progressSub = transferService.progressStream.listen(progressEvents.add);

      // Attempt 1: Peer disconnects at chunk 2
      await transferService.sendChunks(messageId, 'peer-bob-endpoint');

      // Chunks 0 and 1 were successfully sent
      expect(transmittedChunks.length, 2);
      expect(transmittedChunks[0].chunkIndex, 0);
      expect(transmittedChunks[1].chunkIndex, 1);

      // Verify SQLite state: Chunks 0 and 1 are SENT; Chunks >= 2 are still PENDING
      final remainingUnsent = await AppDatabase.instance.getUnsentChunks(messageId);
      expect(remainingUnsent.length, chunks.length - 2);
      expect(remainingUnsent.first['chunk_index'], 2);

      // 6. Test RESUMPTION upon peer reconnect:
      // Peer reconnects! simulateDisconnect is now false
      simulateDisconnect = false;
      transmittedChunks.clear();

      await transferService.sendChunks(messageId, 'peer-bob-endpoint');

      // Verification: sendChunks resumed from chunk 2 WITHOUT restarting chunk 0 or 1!
      expect(transmittedChunks.length, chunks.length - 2);
      expect(transmittedChunks.first.chunkIndex, 2);

      final finalUnsent = await AppDatabase.instance.getUnsentChunks(messageId);
      expect(finalUnsent, isEmpty); // All chunks are now SENT!

      progressSub.cancel();

      // 7. Receiver ingestion (Bob receives chunks)
      // Set Bob's device keypair on receiver
      transferService.setDeviceKeyPair(bobKeyPair);

      final relayedChunks = <ImageChunk>[];
      transferService.transportRelayer = (chunk) async {
        relayedChunks.add(chunk);
        return 1;
      };

      String? completedFilePath;
      final completedSub = transferService.transferCompletedStream.listen((path) {
        completedFilePath = path;
      });

      // Feed chunks to receiver (simulating mesh arrival)
      for (final chunk in chunks) {
        final handled = await transferService.handleIncomingChunk(chunk);
        expect(handled, isTrue);
      }

      // Allow stream event delivery
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify that every chunk was relayed forward without decrypting!
      expect(relayedChunks.length, chunks.length);

      // Verify completion event fired
      expect(completedFilePath, isNotNull);
      final receivedFile = File(completedFilePath!);
      expect(await receivedFile.exists(), isTrue);

      // Verify decrypted image matches original image bytes perfectly!
      final reassembledDecryptedBytes = await receivedFile.readAsBytes();
      expect(reassembledDecryptedBytes, equals(originalImageBytes));

      completedSub.cancel();
    });

    test('handleIncomingChunk rejects corrupted chunks', () async {
      final transferService = ImageTransferService.instance;
      final corruptChunk = ImageChunk(
        messageId: 'MSG-BAD',
        attachmentId: 'ATT-BAD',
        chunkIndex: 0,
        totalChunks: 1,
        encryptedData: Uint8List.fromList([1, 2, 3]),
        checksum: 'invalid-checksum-hash',
      );

      final handled = await transferService.handleIncomingChunk(corruptChunk);
      expect(handled, isFalse);
    });
  });
}
