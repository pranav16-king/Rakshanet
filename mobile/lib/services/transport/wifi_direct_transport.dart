import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';

import 'mesh_transport.dart';

/// Direction of chunked data transmission.
enum ChunkTransferDirection {
  inbound,
  outbound,
}

/// Represents real-time chunk transmission progress for bulk data,
/// encrypted attachments, and image payloads.
class ChunkTransferProgress {
  final String transferId;
  final String peerId;
  final ChunkTransferDirection direction;
  final int chunkIndex;
  final int totalChunks;
  final int bytesTransferred;
  final int totalBytes;
  final bool isCompleted;
  final bool isFailed;
  final String? error;

  const ChunkTransferProgress({
    required this.transferId,
    required this.peerId,
    required this.direction,
    required this.chunkIndex,
    required this.totalChunks,
    required this.bytesTransferred,
    required this.totalBytes,
    this.isCompleted = false,
    this.isFailed = false,
    this.error,
  });

  double get progressFraction =>
      totalBytes > 0 ? (bytesTransferred / totalBytes).clamp(0.0, 1.0) : 0.0;

  @override
  String toString() {
    return 'ChunkTransferProgress(id: $transferId, peer: $peerId, dir: ${direction.name}, '
        'chunk: ${chunkIndex + 1}/$totalChunks, ${(progressFraction * 100).toStringAsFixed(1)}%)';
  }
}

/// A single discrete chunk of high-bandwidth payload.
class WifiDirectChunk {
  final String transferId;
  final int chunkIndex;
  final int totalChunks;
  final int totalBytes;
  final Uint8List chunkData;
  final String sourceDeviceId;
  final String? mimeType;
  final String? fileName;

  const WifiDirectChunk({
    required this.transferId,
    required this.chunkIndex,
    required this.totalChunks,
    required this.totalBytes,
    required this.chunkData,
    required this.sourceDeviceId,
    this.mimeType,
    this.fileName,
  });

  Map<String, dynamic> toMap() {
    return {
      'frame': 'WIFI_DIRECT_CHUNK_V1',
      'transfer_id': transferId,
      'chunk_index': chunkIndex,
      'total_chunks': totalChunks,
      'total_bytes': totalBytes,
      'data_b64': base64Encode(chunkData),
      'src': sourceDeviceId,
      if (mimeType != null) 'mime': mimeType,
      if (fileName != null) 'name': fileName,
    };
  }

  Uint8List toBytes() {
    final jsonStr = jsonEncode(toMap());
    return Uint8List.fromList(utf8.encode(jsonStr));
  }

  static WifiDirectChunk? tryParse(Uint8List bytes) {
    try {
      final jsonStr = utf8.decode(bytes);
      final map = jsonDecode(jsonStr);
      if (map is! Map || map['frame'] != 'WIFI_DIRECT_CHUNK_V1') {
        return null;
      }
      return WifiDirectChunk(
        transferId: map['transfer_id']?.toString() ?? '',
        chunkIndex: (map['chunk_index'] as num?)?.toInt() ?? 0,
        totalChunks: (map['total_chunks'] as num?)?.toInt() ?? 1,
        totalBytes: (map['total_bytes'] as num?)?.toInt() ?? 0,
        chunkData: base64Decode(map['data_b64']?.toString() ?? ''),
        sourceDeviceId: map['src']?.toString() ?? '',
        mimeType: map['mime']?.toString(),
        fileName: map['name']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Helper tracking reassembly of inbound chunks for a specific transfer.
class _InboundTransferAssembly {
  final String transferId;
  final int totalChunks;
  final int totalBytes;
  final String sourcePeerId;
  final String sourceDeviceId;
  final String? mimeType;
  final String? fileName;
  final List<Uint8List?> receivedChunks;
  int receivedBytesCount = 0;

  _InboundTransferAssembly({
    required this.transferId,
    required this.totalChunks,
    required this.totalBytes,
    required this.sourcePeerId,
    required this.sourceDeviceId,
    this.mimeType,
    this.fileName,
  }) : receivedChunks = List<Uint8List?>.filled(totalChunks, null);

  bool get isComplete =>
      receivedChunks.every((chunk) => chunk != null && chunk.isNotEmpty);

  Uint8List assemble() {
    final total = receivedChunks.fold<int>(
      0,
      (sum, chunk) => sum + (chunk?.length ?? 0),
    );
    final buffer = Uint8List(total);
    int offset = 0;
    for (final chunk in receivedChunks) {
      if (chunk != null) {
        buffer.setRange(offset, offset + chunk.length, chunk);
        offset += chunk.length;
      }
    }
    return buffer;
  }
}

/// Wi-Fi Direct Transport Implementation for high-throughput device-to-device transfers.
///
/// Features:
/// - Designed for high-volume payloads: images, bulk attachments, telemetry syncs.
/// - Splits large payloads into discrete chunks (default 32 KB).
/// - Exposes a dedicated `chunkTransfers` stream for tracking transfer progress.
/// - Performs transparent reassembly of inbound chunks into full `TransportPacket` events.
class WifiDirectTransport implements MeshTransport {
  static const int defaultChunkSize = 32 * 1024; // 32 KB per chunk
  static const String serviceId = 'org.rakshanet.wifidirect';

  final Nearby _nearby;
  final Strategy _strategy = Strategy.P2P_STAR; // High-bandwidth star/cluster

  String localDeviceId;
  String localDisplayName;

  // Active state
  bool _isAdvertising = false;
  bool _isDiscovering = false;
  final Map<String, PeerInfo> _peers = <String, PeerInfo>{};
  final Map<String, _InboundTransferAssembly> _inboundAssemblies =
      <String, _InboundTransferAssembly>{};

  // Stream Controllers
  final StreamController<PeerInfo> _discoveredPeersController =
      StreamController<PeerInfo>.broadcast();
  final StreamController<TransportPacket> _receivedPacketsController =
      StreamController<TransportPacket>.broadcast();
  final StreamController<ChunkTransferProgress> _chunkProgressController =
      StreamController<ChunkTransferProgress>.broadcast();

  final Future<bool> Function(String peerId, Uint8List data)? onSendBytes;
  bool? isAvailableOverride;

  WifiDirectTransport({
    this.localDeviceId = 'SR-NODE-001',
    this.localDisplayName = 'Rescue Node (High-Throughput)',
    Nearby? nearby,
    this.onSendBytes,
    this.isAvailableOverride,
  }) : _nearby = nearby ?? Nearby();

  @override
  TransportType get type => TransportType.wifiDirect;

  @override
  bool get isAvailable =>
      isAvailableOverride ??
      (_isAdvertising || _isDiscovering || _peers.isNotEmpty);

  @override
  Stream<PeerInfo> get discoveredPeers => _discoveredPeersController.stream;

  @override
  Stream<TransportPacket> get receivedPackets =>
      _receivedPacketsController.stream;

  /// Dedicated stream exposing real-time chunk transmission progress
  /// (both outbound sending and inbound receiving).
  Stream<ChunkTransferProgress> get chunkTransfers =>
      _chunkProgressController.stream;

  /// Alias for `chunkTransfers` stream.
  Stream<ChunkTransferProgress> get chunkProgressStream =>
      _chunkProgressController.stream;

  /// Currently connected Wi-Fi Direct peers.
  List<PeerInfo> get connectedPeers => _peers.values.toList();

  @override
  Future<void> startDiscovery() async {
    final endpointIdentifier = '$localDeviceId|$localDisplayName';

    try {
      if (!_isAdvertising) {
        final advSuccess = await _nearby.startAdvertising(
          endpointIdentifier,
          _strategy,
          serviceId: serviceId,
          onConnectionInitiated: _onConnectionInitiated,
          onConnectionResult: _onConnectionResult,
          onDisconnected: _onDisconnected,
        );
        _isAdvertising = advSuccess;
      }
    } catch (e) {
      debugPrint('[WifiDirectTransport] startAdvertising error: $e');
    }

    try {
      if (!_isDiscovering) {
        final discSuccess = await _nearby.startDiscovery(
          endpointIdentifier,
          _strategy,
          serviceId: serviceId,
          onEndpointFound: (endpointId, endpointName, serviceId) {
            _onEndpointFound(endpointId, endpointName, endpointIdentifier);
          },
          onEndpointLost: _onEndpointLost,
        );
        _isDiscovering = discSuccess;
      }
    } catch (e) {
      debugPrint('[WifiDirectTransport] startDiscovery error: $e');
    }
  }

  @override
  Future<void> stopDiscovery() async {
    try {
      if (_isAdvertising) {
        await _nearby.stopAdvertising();
        _isAdvertising = false;
      }
      if (_isDiscovering) {
        await _nearby.stopDiscovery();
        _isDiscovering = false;
      }
    } catch (e) {
      debugPrint('[WifiDirectTransport] stopDiscovery error: $e');
    }
  }

  /// Sends arbitrary byte payload to target peer. If payload exceeds `chunkSize`,
  /// it is chunked and streamed with progress reporting.
  @override
  Future<bool> send(
    String peerId,
    Uint8List data, {
    int chunkSize = defaultChunkSize,
  }) async {
    return await sendChunkedStream(
      peerId,
      data,
      chunkSize: chunkSize,
    );
  }

  /// Sends a data stream broken down into sequenced chunks, publishing progress
  /// to `chunkTransfers` and invoking optional `onProgress` callback.
  Future<bool> sendChunkedStream(
    String peerId,
    Uint8List data, {
    String? transferId,
    int chunkSize = defaultChunkSize,
    String? mimeType,
    String? fileName,
    void Function(double progress)? onProgress,
  }) async {
    final id = transferId ?? 'XFER-${DateTime.now().microsecondsSinceEpoch}';
    final totalBytes = data.length;
    final totalChunks = (totalBytes / chunkSize).ceil().clamp(1, 999999);

    int bytesSentSoFar = 0;

    for (int index = 0; index < totalChunks; index++) {
      final start = index * chunkSize;
      final end = (start + chunkSize < totalBytes) ? start + chunkSize : totalBytes;
      final chunkBytes = data.sublist(start, end);

      final chunk = WifiDirectChunk(
        transferId: id,
        chunkIndex: index,
        totalChunks: totalChunks,
        totalBytes: totalBytes,
        chunkData: chunkBytes,
        sourceDeviceId: localDeviceId,
        mimeType: mimeType,
        fileName: fileName,
      );

      final wirePayload = chunk.toBytes();

      try {
        if (onSendBytes != null) {
          final ok = await onSendBytes!(peerId, wirePayload);
          if (!ok) throw Exception('onSendBytes returned false');
        } else {
          await _nearby.sendBytesPayload(peerId, wirePayload);
        }
      } catch (e) {
        debugPrint(
          '[WifiDirectTransport] Error sending chunk $index for $id: $e',
        );
        _chunkProgressController.add(
          ChunkTransferProgress(
            transferId: id,
            peerId: peerId,
            direction: ChunkTransferDirection.outbound,
            chunkIndex: index,
            totalChunks: totalChunks,
            bytesTransferred: bytesSentSoFar,
            totalBytes: totalBytes,
            isFailed: true,
            error: e.toString(),
          ),
        );
        return false;
      }

      bytesSentSoFar += chunkBytes.length;
      final isComplete = (index == totalChunks - 1);

      final progressEvent = ChunkTransferProgress(
        transferId: id,
        peerId: peerId,
        direction: ChunkTransferDirection.outbound,
        chunkIndex: index,
        totalChunks: totalChunks,
        bytesTransferred: bytesSentSoFar,
        totalBytes: totalBytes,
        isCompleted: isComplete,
      );

      _chunkProgressController.add(progressEvent);
      onProgress?.call(progressEvent.progressFraction);
    }

    return true;
  }

  /// Streams a local file over Wi-Fi Direct chunk by chunk.
  Future<bool> sendFile(
    String peerId,
    String filePath, {
    String? mimeType,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('[WifiDirectTransport] File not found: $filePath');
        return false;
      }

      final data = await file.readAsBytes();
      final fileName = filePath.split(Platform.pathSeparator).last;

      return await sendChunkedStream(
        peerId,
        data,
        fileName: fileName,
        mimeType: mimeType,
        onProgress: onProgress,
      );
    } catch (e) {
      debugPrint('[WifiDirectTransport] sendFile error: $e');
      return false;
    }
  }

  /// Broadcasts data across all connected Wi-Fi Direct peer nodes.
  @override
  Future<int> broadcast(Uint8List data) async {
    final targets = _peers.keys.isNotEmpty
        ? _peers.keys.toList()
        : (onSendBytes != null ? ['simulated_peer'] : <String>[]);
    if (targets.isEmpty) return 0;

    int successCount = 0;
    for (final peerId in targets) {
      final success = await send(peerId, data);
      if (success) successCount++;
    }
    return successCount;
  }

  // ---------------------------------------------------------------------------
  // Internal Event Handlers & Callbacks
  // ---------------------------------------------------------------------------

  void _onEndpointFound(
    String endpointId,
    String endpointName,
    String localEndpoint,
  ) {
    if (_peers.containsKey(endpointId)) return;

    try {
      _nearby.requestConnection(
        localEndpoint,
        endpointId,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
    } catch (e) {
      debugPrint(
        '[WifiDirectTransport] requestConnection failed on $endpointId: $e',
      );
    }
  }

  void _onConnectionInitiated(
    String endpointId,
    ConnectionInfo connectionInfo,
  ) {
    try {
      _nearby.acceptConnection(
        endpointId,
        onPayLoadRecieved: (epId, payload) {
          if (payload.type == PayloadType.BYTES && payload.bytes != null) {
            _onBytesReceived(epId, payload.bytes!);
          }
        },
        onPayloadTransferUpdate: (epId, update) {},
      );
    } catch (e) {
      debugPrint(
        '[WifiDirectTransport] acceptConnection error on $endpointId: $e',
      );
    }
  }

  void _onConnectionResult(String endpointId, Status status) {
    if (status == Status.CONNECTED) {
      final peer = PeerInfo(
        peerId: endpointId,
        deviceId: 'SR-WD-${endpointId.hashCode.abs() % 10000}',
        displayName: 'Wi-Fi Direct Peer',
        supportedTransports: {TransportType.ble, TransportType.wifiDirect},
        batteryLevel: 90,
        isRelay: true,
        isInternetGateway: false,
        rssi: -45, // Wi-Fi Direct typically has stronger RSSI
        lastSeen: DateTime.now(),
      );

      _peers[endpointId] = peer;
      _discoveredPeersController.add(peer);
    } else {
      _peers.remove(endpointId);
    }
  }

  void _onDisconnected(String endpointId) {
    _peers.remove(endpointId);
  }

  void _onEndpointLost(String? endpointId) {
    if (endpointId == null) return;
    _peers.remove(endpointId);
  }

  void _onBytesReceived(String endpointId, Uint8List rawBytes) {
    // Update peer last-seen
    if (_peers.containsKey(endpointId)) {
      _peers[endpointId] = _peers[endpointId]!.copyWith(
        lastSeen: DateTime.now(),
      );
      _discoveredPeersController.add(_peers[endpointId]!);
    }

    final chunk = WifiDirectChunk.tryParse(rawBytes);
    if (chunk == null) {
      // Direct raw packet fallback
      _receivedPacketsController.add(
        TransportPacket(
          rawBytes: rawBytes,
          sourcePeerId: endpointId,
          transportType: TransportType.wifiDirect,
          timestamp: DateTime.now(),
        ),
      );
      return;
    }

    _handleIncomingChunk(endpointId, chunk);
  }

  void _handleIncomingChunk(String endpointId, WifiDirectChunk chunk) {
    var assembly = _inboundAssemblies[chunk.transferId];
    if (assembly == null) {
      assembly = _InboundTransferAssembly(
        transferId: chunk.transferId,
        totalChunks: chunk.totalChunks,
        totalBytes: chunk.totalBytes,
        sourcePeerId: endpointId,
        sourceDeviceId: chunk.sourceDeviceId,
        mimeType: chunk.mimeType,
        fileName: chunk.fileName,
      );
      _inboundAssemblies[chunk.transferId] = assembly;
    }

    if (chunk.chunkIndex < assembly.receivedChunks.length) {
      if (assembly.receivedChunks[chunk.chunkIndex] == null) {
        assembly.receivedChunks[chunk.chunkIndex] = chunk.chunkData;
        assembly.receivedBytesCount += chunk.chunkData.length;
      }
    }

    final isComplete = assembly.isComplete;

    // Emit chunk progress event
    _chunkProgressController.add(
      ChunkTransferProgress(
        transferId: chunk.transferId,
        peerId: endpointId,
        direction: ChunkTransferDirection.inbound,
        chunkIndex: chunk.chunkIndex,
        totalChunks: chunk.totalChunks,
        bytesTransferred: assembly.receivedBytesCount,
        totalBytes: chunk.totalBytes,
        isCompleted: isComplete,
      ),
    );

    // If all chunks received, reconstruct the full payload and emit packet
    if (isComplete) {
      final completePayload = assembly.assemble();
      _inboundAssemblies.remove(chunk.transferId);

      _receivedPacketsController.add(
        TransportPacket(
          rawBytes: completePayload,
          sourcePeerId: endpointId,
          transportType: TransportType.wifiDirect,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Testing & Simulation Hooks
  // ---------------------------------------------------------------------------

  @visibleForTesting
  void simulatePeerDiscovered(PeerInfo peer) {
    _peers[peer.peerId] = peer;
    _discoveredPeersController.add(peer);
  }

  @visibleForTesting
  void simulateBytesReceived(String endpointId, Uint8List bytes) {
    _onBytesReceived(endpointId, bytes);
  }

  @visibleForTesting
  void simulateChunkReceived(String endpointId, WifiDirectChunk chunk) {
    _handleIncomingChunk(endpointId, chunk);
  }

  @override
  Future<void> dispose() async {
    await stopDiscovery();
    await _discoveredPeersController.close();
    await _receivedPacketsController.close();
    await _chunkProgressController.close();
  }
}
