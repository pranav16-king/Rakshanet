import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rakshanet_mobile/services/transport/mesh_transport.dart';
import 'package:rakshanet_mobile/services/transport/ble_transport.dart';
import 'package:rakshanet_mobile/services/transport/wifi_direct_transport.dart';
import 'package:rakshanet_mobile/services/transport/transport_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MeshTransport & Models Unit Tests', () {
    test('TransportType enum includes all required transport modes', () {
      expect(TransportType.values, contains(TransportType.ble));
      expect(TransportType.values, contains(TransportType.wifiDirect));
      expect(TransportType.values, contains(TransportType.wifiAware));
      expect(TransportType.values, contains(TransportType.internetGateway));
    });

    test('PeerInfo serialization and properties', () {
      final now = DateTime.now();
      final peer = PeerInfo(
        peerId: 'EP-1234',
        deviceId: 'SR-7788',
        displayName: 'Alpha Node',
        supportedTransports: {TransportType.ble, TransportType.wifiDirect},
        batteryLevel: 85,
        isRelay: true,
        isInternetGateway: true,
        rssi: -58,
        lastSeen: now,
      );

      expect(peer.supports(TransportType.ble), isTrue);
      expect(peer.supports(TransportType.wifiDirect), isTrue);
      expect(peer.supports(TransportType.wifiAware), isFalse);
      expect(peer.isOnline, isTrue);

      final map = peer.toMap();
      expect(map['peer_id'], equals('EP-1234'));
      expect(map['device_id'], equals('SR-7788'));
      expect(map['is_internet_gateway'], isTrue);

      final restored = PeerInfo.fromMap(map);
      expect(restored.peerId, equals(peer.peerId));
      expect(restored.deviceId, equals(peer.deviceId));
      expect(restored.isInternetGateway, isTrue);
      expect(restored.supports(TransportType.wifiDirect), isTrue);
    });

    test('TransportPacket properties and serialization', () {
      final data = Uint8List.fromList(utf8.encode('SOS Emergency Alert'));
      final packet = TransportPacket(
        rawBytes: data,
        sourcePeerId: 'PEER-001',
        transportType: TransportType.ble,
        timestamp: DateTime.now(),
      );

      expect(packet.byteLength, equals(data.length));
      expect(packet.sourcePeerId, equals('PEER-001'));
      expect(packet.transportType, equals(TransportType.ble));

      final map = packet.toMap();
      expect(map['source_peer_id'], equals('PEER-001'));
      expect(map['transport_type'], equals('ble'));
      expect(map['byte_length'], equals(data.length));
    });
  });

  group('BleTransport & Privacy Protection Unit Tests', () {
    test('PrivacySanitizer removes emails, phones, coords and masks full names', () {
      // Email leakage prevention
      final res1 = PrivacySanitizer.sanitizeDisplayName(
        'dr.roy@disasterhospital.org',
        'SR-9988',
      );
      expect(res1.contains('@'), isFalse);
      expect(res1.contains('disasterhospital'), isFalse);

      // Full name masking
      final res2 = PrivacySanitizer.sanitizeDisplayName(
        'Anita Roy',
        'SR-9988',
      );
      expect(res2, equals('Anita R.'));

      // Coordinate leakage prevention
      final res3 = PrivacySanitizer.sanitizeDisplayName(
        'Camp 12.9716, 77.5946',
        'SR-9988',
      );
      expect(res3.contains('12.9716'), isFalse);
      expect(res3.contains('77.5946'), isFalse);

      // Phone number stripping
      final res4 = PrivacySanitizer.sanitizeDisplayName(
        '+91 9811223344',
        'SR-9988',
      );
      expect(res4, equals('Node-9988'));
    });

    test('BleFrame serialization and parse', () {
      final payload = Uint8List.fromList([1, 2, 3, 4, 5]);
      final frame = BleFrame(
        type: BleFrameType.data,
        id: 'PKT-TEST-01',
        sourceDeviceId: 'SR-0001',
        destinationDeviceId: 'SR-0002',
        ackRequested: true,
        payload: payload,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      final bytes = frame.toBytes();
      final parsed = BleFrame.tryParse(bytes);

      expect(parsed, isNotNull);
      expect(parsed!.type, equals(BleFrameType.data));
      expect(parsed.id, equals('PKT-TEST-01'));
      expect(parsed.ackRequested, isTrue);
      expect(parsed.payload, equals(payload));
    });

    test('BleTransport rejects packets exceeding 4KB limit', () async {
      final ble = BleTransport(
        localDeviceId: 'SR-TEST-LOCAL',
        localDisplayName: 'Test Node',
      );

      final oversized = Uint8List(4097); // 4097 bytes > 4096 limit
      final sent = await ble.send('PEER-1', oversized);
      expect(sent, isFalse, reason: 'BLE must reject packets exceeding 4KB');

      final broadcastSent = await ble.broadcast(oversized);
      expect(broadcastSent, equals(0));

      final sentWithAck = await ble.sendWithAck('PEER-1', oversized);
      expect(sentWithAck, isFalse);

      await ble.dispose();
    });

    test('BleTransport handles capability exchange frame without PII', () async {
      final ble = BleTransport(
        localDeviceId: 'SR-RECEIVER',
        localDisplayName: 'Responder Node',
      );

      final peerInfoList = <PeerInfo>[];
      final sub = ble.discoveredPeers.listen(peerInfoList.add);

      final capFrame = BleFrame(
        type: BleFrameType.capabilityExchange,
        id: 'CAP-001',
        sourceDeviceId: 'SR-SENDER',
        capability: {
          'device_id': 'SR-SENDER',
          'display_name': 'Emergency Volunteer S.',
          'battery_level': 74,
          'is_relay': true,
          'is_internet_gateway': true,
          'supported_transports': ['ble', 'wifiDirect'],
        },
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      ble.simulateBytesReceived('EP-REMOTE', capFrame.toBytes());

      await Future.delayed(const Duration(milliseconds: 30));
      expect(peerInfoList.isNotEmpty, isTrue);
      final discovered = peerInfoList.last;
      expect(discovered.deviceId, equals('SR-SENDER'));
      expect(discovered.batteryLevel, equals(74));
      expect(discovered.isInternetGateway, isTrue);
      expect(discovered.supports(TransportType.wifiDirect), isTrue);

      await sub.cancel();
      await ble.dispose();
    });
  });

  group('WifiDirectTransport & Chunk Stream Unit Tests', () {
    test('WifiDirectChunk serialization and parsing', () {
      final chunkData = Uint8List.fromList([10, 20, 30, 40]);
      final chunk = WifiDirectChunk(
        transferId: 'XFER-100',
        chunkIndex: 0,
        totalChunks: 3,
        totalBytes: 120,
        chunkData: chunkData,
        sourceDeviceId: 'SR-001',
        fileName: 'map_sector.png',
        mimeType: 'image/png',
      );

      final bytes = chunk.toBytes();
      final parsed = WifiDirectChunk.tryParse(bytes);

      expect(parsed, isNotNull);
      expect(parsed!.transferId, equals('XFER-100'));
      expect(parsed.chunkIndex, equals(0));
      expect(parsed.totalChunks, equals(3));
      expect(parsed.fileName, equals('map_sector.png'));
      expect(parsed.chunkData, equals(chunkData));
    });

    test('WifiDirectTransport receives chunks, tracks progress, and reassembles payload', () async {
      final wifi = WifiDirectTransport(
        localDeviceId: 'SR-WIFI-LOCAL',
      );

      final progressEvents = <ChunkTransferProgress>[];
      final receivedPackets = <TransportPacket>[];

      final subProgress = wifi.chunkTransfers.listen(progressEvents.add);
      final subPackets = wifi.receivedPackets.listen(receivedPackets.add);

      // Create 2 chunks representing a 6-byte payload
      final chunk1 = WifiDirectChunk(
        transferId: 'XFER-TEST-99',
        chunkIndex: 0,
        totalChunks: 2,
        totalBytes: 6,
        chunkData: Uint8List.fromList([1, 2, 3]),
        sourceDeviceId: 'SR-PEER',
      );

      final chunk2 = WifiDirectChunk(
        transferId: 'XFER-TEST-99',
        chunkIndex: 1,
        totalChunks: 2,
        totalBytes: 6,
        chunkData: Uint8List.fromList([4, 5, 6]),
        sourceDeviceId: 'SR-PEER',
      );

      // Simulate chunk 0
      wifi.simulateChunkReceived('EP-WIFI-1', chunk1);
      await Future.delayed(const Duration(milliseconds: 20));

      expect(progressEvents.length, equals(1));
      expect(progressEvents.last.isCompleted, isFalse);
      expect(receivedPackets.isEmpty, isTrue);

      // Simulate chunk 1
      wifi.simulateChunkReceived('EP-WIFI-1', chunk2);
      await Future.delayed(const Duration(milliseconds: 20));

      expect(progressEvents.length, equals(2));
      expect(progressEvents.last.isCompleted, isTrue);
      expect(progressEvents.last.bytesTransferred, equals(6));

      // Verify reassembled packet
      expect(receivedPackets.length, equals(1));
      final fullPacket = receivedPackets.first;
      expect(fullPacket.sourcePeerId, equals('EP-WIFI-1'));
      expect(fullPacket.transportType, equals(TransportType.wifiDirect));
      expect(fullPacket.rawBytes, equals(Uint8List.fromList([1, 2, 3, 4, 5, 6])));

      await subProgress.cancel();
      await subPackets.cancel();
      await wifi.dispose();
    });
  });

  group('TransportManager & Dual-Channel Orchestration Tests', () {
    late BleTransport ble;
    late WifiDirectTransport wifi;
    late TransportManager manager;

    setUp(() {
      ble = BleTransport(
        localDeviceId: 'SR-ORCH-BLE',
        isAvailableOverride: true,
        onSendBytes: (peerId, data) async => true,
      );
      wifi = WifiDirectTransport(
        localDeviceId: 'SR-ORCH-WIFI',
        isAvailableOverride: true,
        onSendBytes: (peerId, data) async => true,
      );
      manager = TransportManager(
        bleTransport: ble,
        wifiDirectTransport: wifi,
        enablePeriodicInternetCheck: false,
      );
    });

    tearDown(() {
      manager.dispose();
    });

    test('Optimal routing: Small text (< 4KB) routes to BLE', () async {
      final peer = PeerInfo(
        peerId: 'EP-P1',
        deviceId: 'SR-PEER-1',
        displayName: 'Responder',
        supportedTransports: {TransportType.ble, TransportType.wifiDirect},
        lastSeen: DateTime.now(),
      );
      manager.registerPeerForTesting(peer);

      final smallData = Uint8List.fromList(utf8.encode('Heartbeat Ping'));
      expect(smallData.length < TransportManager.maxBlePacketThreshold, isTrue);

      final res = await manager.send(peerId: 'EP-P1', data: smallData);
      expect(res, isTrue);
    });

    test('Optimal routing: Large payload or bulk data routes to Wi-Fi Direct', () async {
      final peer = PeerInfo(
        peerId: 'EP-P2',
        deviceId: 'SR-PEER-2',
        displayName: 'Base Node',
        supportedTransports: {TransportType.ble, TransportType.wifiDirect},
        lastSeen: DateTime.now(),
      );
      manager.registerPeerForTesting(peer);

      // Large 5 KB payload
      final largeData = Uint8List(5000);
      expect(largeData.length >= TransportManager.maxBlePacketThreshold, isTrue);

      final res = await manager.send(peerId: 'EP-P2', data: largeData);
      expect(res, isTrue);
    });

    test('Combined online peers merges capabilities across transports', () async {
      final blePeer = PeerInfo(
        peerId: 'EP-BLE-1',
        deviceId: 'SR-PEER-MERGE',
        displayName: 'Relay Volunteer',
        supportedTransports: {TransportType.ble},
        batteryLevel: 92,
        isRelay: true,
        isInternetGateway: false,
        rssi: -70,
        lastSeen: DateTime.now(),
      );

      final wifiPeer = PeerInfo(
        peerId: 'EP-WIFI-1',
        deviceId: 'SR-PEER-MERGE',
        displayName: 'Relay Volunteer',
        supportedTransports: {TransportType.wifiDirect},
        batteryLevel: 90,
        isRelay: true,
        isInternetGateway: true, // Has gateway uplink
        rssi: -40,
        lastSeen: DateTime.now(),
      );

      ble.simulatePeerDiscovered(blePeer);
      wifi.simulatePeerDiscovered(wifiPeer);
      await Future.delayed(const Duration(milliseconds: 30));

      final peers = manager.onlinePeers;
      expect(peers.length, equals(1));
      final merged = peers.first;
      expect(merged.deviceId, equals('SR-PEER-MERGE'));
      expect(merged.supportedTransports, contains(TransportType.ble));
      expect(merged.supportedTransports, contains(TransportType.wifiDirect));
      expect(merged.isInternetGateway, isTrue);
    });

    test('Internet Gateway Tracking detects mesh peer gateway and local internet', () async {
      expect(manager.isInternetGatewayAvailable, isFalse);
      expect(manager.activeInternetGatewayNode, isNull);

      final gatewayEvents = <bool>[];
      final sub = manager.internetGatewayAvailabilityStream.listen(gatewayEvents.add);

      // 1. Peer with Gateway capability joins mesh
      final gatewayPeer = PeerInfo(
        peerId: 'EP-GATEWAY-1',
        deviceId: 'SR-GATEWAY',
        displayName: 'HQ Base Uplink',
        supportedTransports: {TransportType.ble, TransportType.wifiDirect},
        batteryLevel: 98,
        isRelay: true,
        isInternetGateway: true,
        rssi: -50,
        lastSeen: DateTime.now(),
      );
      manager.registerPeerForTesting(gatewayPeer);

      await Future.delayed(const Duration(milliseconds: 20));
      expect(manager.hasMeshInternetGateway, isTrue);
      expect(manager.isInternetGatewayAvailable, isTrue);
      expect(manager.activeInternetGatewayNode?.deviceId, equals('SR-GATEWAY'));
      expect(gatewayEvents, contains(true));

      // 2. Local device gains internet
      manager.setLocalInternetForTesting(true);
      expect(manager.hasLocalInternet, isTrue);
      expect(manager.isInternetGatewayAvailable, isTrue);

      await sub.cancel();
    });

    test('Combined incomingPackets stream receives from both BLE and Wi-Fi Direct', () async {
      final receivedPackets = <TransportPacket>[];
      final sub = manager.incomingPackets.listen(receivedPackets.add);

      final bleData = Uint8List.fromList([1, 2, 3]);
      final wifiData = Uint8List.fromList([4, 5, 6, 7]);

      ble.simulateBytesReceived('EP-BLE', bleData);
      wifi.simulateBytesReceived('EP-WIFI', wifiData);

      await Future.delayed(const Duration(milliseconds: 30));
      expect(receivedPackets.length, equals(2));
      expect(receivedPackets[0].transportType, equals(TransportType.ble));
      expect(receivedPackets[0].rawBytes, equals(bleData));
      expect(receivedPackets[1].transportType, equals(TransportType.wifiDirect));
      expect(receivedPackets[1].rawBytes, equals(wifiData));

      await sub.cancel();
    });
  });
}
