import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';

import 'mesh_transport.dart';

/// Privacy sanitizer ensuring no personal data (email, full name, private GPS)
/// is leaked over the unencrypted BLE advertisement and capability channels.
class PrivacySanitizer {
  static final RegExp _emailRegex =
      RegExp(r'[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+');
  static final RegExp _phoneRegex = RegExp(r'\+?[0-9\s-]{7,15}');
  static final RegExp _coordsRegex = RegExp(
    r'[-+]?([1-8]?\d(\.\d+)?|90(\.0+)?),\s*[-+]?(180(\.0+)?|((1[0-7]\d)|([1-9]?\d))(\.\d+)?)',
  );

  /// Cleanses any personal identifiable data, returning a safe, pseudonymous callsign.
  static String sanitizeDisplayName(String? rawName, String deviceId) {
    final suffix = deviceId.length >= 4
        ? deviceId.substring(deviceId.length - 4)
        : 'Peer';
    final fallback = 'Node-$suffix';

    if (rawName == null || rawName.trim().isEmpty) {
      return fallback;
    }

    var clean = rawName.trim();
    clean = clean.replaceAll(_emailRegex, '');
    clean = clean.replaceAll(_phoneRegex, '');
    clean = clean.replaceAll(_coordsRegex, '');
    clean = clean.trim();

    if (clean.isEmpty) {
      return fallback;
    }

    // Mask surnames to initial only (e.g., "Dr. Anita Roy" -> "Dr. Anita R.")
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length > 2) {
      clean = '${parts[0]} ${parts[1]} ${parts[2][0]}.';
    } else if (parts.length == 2) {
      clean = '${parts[0]} ${parts[1][0]}.';
    }

    if (clean.length > 16) {
      clean = clean.substring(0, 16).trim();
    }
    return clean;
  }
}

/// BLE protocol frame types.
enum BleFrameType {
  data,
  capabilityExchange,
  ack,
  routing,
}

/// Structured frame envelope used for routing, ACKs, and capability exchange over BLE.
class BleFrame {
  final BleFrameType type;
  final String id;
  final String sourceDeviceId;
  final String? destinationDeviceId;
  final bool ackRequested;
  final int hopCount;
  final int ttl;
  final int timestamp;
  final Uint8List? payload;
  final Map<String, dynamic>? capability;
  final String? ackId;
  final Map<String, dynamic>? routingData;

  const BleFrame({
    required this.type,
    required this.id,
    required this.sourceDeviceId,
    this.destinationDeviceId,
    this.ackRequested = false,
    this.hopCount = 0,
    this.ttl = 5,
    required this.timestamp,
    this.payload,
    this.capability,
    this.ackId,
    this.routingData,
  });

  Map<String, dynamic> toMap() {
    return {
      'frame': 'BLE_MESH_V1',
      't': type.name,
      'id': id,
      'src': sourceDeviceId,
      if (destinationDeviceId != null) 'dst': destinationDeviceId,
      'ack_req': ackRequested,
      'hops': hopCount,
      'ttl': ttl,
      'ts': timestamp,
      if (payload != null) 'p_b64': base64Encode(payload!),
      if (capability != null) 'cap': capability,
      if (ackId != null) 'ack_id': ackId,
      if (routingData != null) 'rt': routingData,
    };
  }

  Uint8List toBytes() {
    final str = jsonEncode(toMap());
    return Uint8List.fromList(utf8.encode(str));
  }

  static BleFrame? tryParse(Uint8List bytes) {
    try {
      final str = utf8.decode(bytes);
      final json = jsonDecode(str);
      if (json is! Map || json['frame'] != 'BLE_MESH_V1') {
        return null;
      }
      final typeStr = json['t']?.toString() ?? 'data';
      final frameType = BleFrameType.values.firstWhere(
        (t) => t.name == typeStr,
        orElse: () => BleFrameType.data,
      );

      Uint8List? payload;
      if (json['p_b64'] != null) {
        payload = base64Decode(json['p_b64'].toString());
      }

      return BleFrame(
        type: frameType,
        id: json['id']?.toString() ?? '',
        sourceDeviceId: json['src']?.toString() ?? '',
        destinationDeviceId: json['dst']?.toString(),
        ackRequested: json['ack_req'] == true,
        hopCount: (json['hops'] as num?)?.toInt() ?? 0,
        ttl: (json['ttl'] as num?)?.toInt() ?? 5,
        timestamp: (json['ts'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
        payload: payload,
        capability: json['cap'] is Map
            ? Map<String, dynamic>.from(json['cap'] as Map)
            : null,
        ackId: json['ack_id']?.toString(),
        routingData: json['rt'] is Map
            ? Map<String, dynamic>.from(json['rt'] as Map)
            : null,
      );
    } catch (_) {
      return null;
    }
  }
}

/// BLE Transport Implementation using Bluetooth Low Energy / Nearby Connections
/// P2P Cluster strategy.
///
/// Features:
/// - Enforces 4 KB packet size limit for emergency bursts.
/// - Performs privacy-preserving capability advertising (no email, full name, or GPS).
/// - Handles discovery, capability exchange, routing headers, and bidirectional ACKs.
class BleTransport implements MeshTransport {
  static const int maxBlePacketSize = 4096; // 4 KB limit
  static const String serviceId = 'org.rakshanet.mesh';

  final Nearby _nearby;
  final Strategy _strategy = Strategy.P2P_CLUSTER;

  String localDeviceId;
  String localDisplayName;
  int localBatteryLevel;
  bool isRelay;
  bool isInternetGateway;
  Set<TransportType> localSupportedTransports;
  final Duration capabilityInterval;

  // Internal State
  bool _isAdvertising = false;
  bool _isDiscovering = false;
  Timer? _capabilityTimer;

  final Map<String, PeerInfo> _peers = <String, PeerInfo>{};
  final Map<String, String> _endpointNames = <String, String>{};
  final Set<String> _pendingConnections = <String>{};
  final Map<String, Completer<bool>> _pendingAcks = <String, Completer<bool>>{};

  // Stream Controllers
  final StreamController<PeerInfo> _discoveredPeersController =
      StreamController<PeerInfo>.broadcast();
  final StreamController<TransportPacket> _receivedPacketsController =
      StreamController<TransportPacket>.broadcast();
  final StreamController<String> _ackEventsController =
      StreamController<String>.broadcast();

  final Future<bool> Function(String peerId, Uint8List data)? onSendBytes;
  bool? isAvailableOverride;

  BleTransport({
    this.localDeviceId = 'SR-NODE-001',
    this.localDisplayName = 'Rescue Node',
    this.localBatteryLevel = 90,
    this.isRelay = true,
    this.isInternetGateway = false,
    this.localSupportedTransports = const {TransportType.ble},
    this.capabilityInterval = const Duration(seconds: 30),
    Nearby? nearby,
    this.onSendBytes,
    this.isAvailableOverride,
  }) : _nearby = nearby ?? Nearby();

  @override
  TransportType get type => TransportType.ble;

  @override
  bool get isAvailable =>
      isAvailableOverride ??
      (_isAdvertising || _isDiscovering || _peers.isNotEmpty);

  @override
  Stream<PeerInfo> get discoveredPeers => _discoveredPeersController.stream;

  @override
  Stream<TransportPacket> get receivedPackets =>
      _receivedPacketsController.stream;

  /// Stream of acknowledged packet IDs.
  Stream<String> get ackEvents => _ackEventsController.stream;

  /// List of actively connected peers on this BLE transport.
  List<PeerInfo> get connectedPeers => _peers.values.toList();

  /// Starts BLE scanning and advertising with sanitized public credentials.
  @override
  Future<void> startDiscovery() async {
    final sanitizedName =
        PrivacySanitizer.sanitizeDisplayName(localDisplayName, localDeviceId);
    final endpointIdentifier = '$localDeviceId|$sanitizedName';

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
      debugPrint('[BleTransport] startAdvertising error: $e');
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
      debugPrint('[BleTransport] startDiscovery error: $e');
    }

    _startCapabilityTimer();
  }

  /// Stops BLE scanning, advertising, and capability broadcasts.
  @override
  Future<void> stopDiscovery() async {
    _capabilityTimer?.cancel();
    _capabilityTimer = null;

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
      debugPrint('[BleTransport] stopDiscovery error: $e');
    }
  }

  /// Sends a data packet to a peer endpoint over BLE.
  /// Enforces maximum 4 KB constraint for short emergency mesh packets.
  @override
  Future<bool> send(String peerId, Uint8List data) async {
    if (data.length > maxBlePacketSize) {
      debugPrint(
        '[BleTransport] Rejected packet: size ${data.length}B exceeds 4KB limit',
      );
      return false;
    }

    Uint8List wireBytes;
    final parsed = BleFrame.tryParse(data);
    if (parsed != null) {
      wireBytes = data;
    } else {
      // Wrap raw data in a BleFrame envelope
      final frame = BleFrame(
        type: BleFrameType.data,
        id: 'PKT-${DateTime.now().microsecondsSinceEpoch}',
        sourceDeviceId: localDeviceId,
        destinationDeviceId: peerId,
        payload: data,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      final framedBytes = frame.toBytes();
      wireBytes = framedBytes.length <= maxBlePacketSize ? framedBytes : data;
    }

    try {
      if (onSendBytes != null) {
        return await onSendBytes!(peerId, wireBytes);
      }
      await _nearby.sendBytesPayload(peerId, wireBytes);
      return true;
    } catch (e) {
      debugPrint('[BleTransport] sendBytesPayload failed for $peerId: $e');
      return false;
    }
  }

  /// Sends a packet requiring acknowledgment from the destination peer.
  Future<bool> sendWithAck(
    String peerId,
    Uint8List data, {
    String? packetId,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (data.length > maxBlePacketSize) {
      debugPrint(
        '[BleTransport] sendWithAck: size ${data.length}B exceeds 4KB limit',
      );
      return false;
    }

    final id = packetId ?? 'ACK-PKT-${DateTime.now().microsecondsSinceEpoch}';
    final frame = BleFrame(
      type: BleFrameType.data,
      id: id,
      sourceDeviceId: localDeviceId,
      destinationDeviceId: peerId,
      ackRequested: true,
      payload: data,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    final completer = Completer<bool>();
    _pendingAcks[id] = completer;

    final wireBytes = frame.toBytes();
    try {
      if (onSendBytes != null) {
        final ok = await onSendBytes!(peerId, wireBytes);
        if (!ok) {
          _pendingAcks.remove(id);
          return false;
        }
      } else {
        await _nearby.sendBytesPayload(peerId, wireBytes);
      }
    } catch (e) {
      _pendingAcks.remove(id);
      return false;
    }

    try {
      return await completer.future.timeout(
        timeout,
        onTimeout: () {
          _pendingAcks.remove(id);
          return false;
        },
      );
    } catch (_) {
      _pendingAcks.remove(id);
      return false;
    }
  }

  /// Broadcasts a data packet to all connected BLE peers (< 4KB).
  @override
  Future<int> broadcast(Uint8List data) async {
    if (data.length > maxBlePacketSize) {
      debugPrint(
        '[BleTransport] broadcast: size ${data.length}B exceeds 4KB limit',
      );
      return 0;
    }

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

  /// Broadcasts capability advertisement without leaking personal data.
  Future<int> broadcastCapabilities() async {
    final sanitizedName =
        PrivacySanitizer.sanitizeDisplayName(localDisplayName, localDeviceId);
    final capPayload = {
      'device_id': localDeviceId,
      'display_name': sanitizedName,
      'battery_level': localBatteryLevel,
      'is_relay': isRelay,
      'is_internet_gateway': isInternetGateway,
      'supported_transports':
          localSupportedTransports.map((t) => t.name).toList(),
      // Explicitly NO email, NO private GPS, NO phone number
    };

    final frame = BleFrame(
      type: BleFrameType.capabilityExchange,
      id: 'CAP-${DateTime.now().microsecondsSinceEpoch}',
      sourceDeviceId: localDeviceId,
      capability: capPayload,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    final bytes = frame.toBytes();
    int success = 0;
    for (final peerId in _peers.keys.toList()) {
      try {
        await _nearby.sendBytesPayload(peerId, bytes);
        success++;
      } catch (e) {
        debugPrint('[BleTransport] Failed to send capabilities to $peerId: $e');
      }
    }
    return success;
  }

  /// Sends a routing header packet to inform peers of topological paths.
  Future<bool> sendRoutingAnnouncement({
    required String peerId,
    required Map<String, dynamic> routingData,
  }) async {
    final frame = BleFrame(
      type: BleFrameType.routing,
      id: 'RT-${DateTime.now().microsecondsSinceEpoch}',
      sourceDeviceId: localDeviceId,
      routingData: routingData,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    return await send(peerId, frame.toBytes());
  }

  // ---------------------------------------------------------------------------
  // Internal Event Handlers & Callbacks
  // ---------------------------------------------------------------------------

  void _startCapabilityTimer() {
    _capabilityTimer?.cancel();
    _capabilityTimer = Timer.periodic(capabilityInterval, (_) {
      broadcastCapabilities();
    });
  }

  void _onEndpointFound(
    String endpointId,
    String endpointName,
    String localEndpoint,
  ) {
    if (_peers.containsKey(endpointId) ||
        _pendingConnections.contains(endpointId)) {
      return;
    }

    _endpointNames[endpointId] = endpointName;

    // Lexicographical collision tie-breaker
    if (localEndpoint.isNotEmpty && endpointName.isNotEmpty) {
      if (localEndpoint.compareTo(endpointName) < 0) {
        return;
      }
    }

    _pendingConnections.add(endpointId);
    try {
      _nearby.requestConnection(
        localEndpoint,
        endpointId,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
    } catch (e) {
      _pendingConnections.remove(endpointId);
    }
  }

  void _onConnectionInitiated(
    String endpointId,
    ConnectionInfo connectionInfo,
  ) {
    if (connectionInfo.endpointName.isNotEmpty) {
      _endpointNames[endpointId] = connectionInfo.endpointName;
    }
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
      debugPrint('[BleTransport] acceptConnection error on $endpointId: $e');
    }
  }

  void _onConnectionResult(String endpointId, Status status) {
    _pendingConnections.remove(endpointId);
    if (status == Status.CONNECTED) {
      final rawName = _endpointNames[endpointId] ?? '';
      String peerDeviceId = 'SR-PEER-${endpointId.hashCode.abs() % 10000}';
      String peerName = 'Rescue Responder';

      if (rawName.contains('|')) {
        final parts = rawName.split('|');
        if (parts.isNotEmpty && parts[0].trim().isNotEmpty) {
          peerDeviceId = parts[0].trim();
        }
        if (parts.length > 1 && parts[1].trim().isNotEmpty) {
          peerName = PrivacySanitizer.sanitizeDisplayName(
            parts[1].trim(),
            peerDeviceId,
          );
        }
      }

      final peer = PeerInfo(
        peerId: endpointId,
        deviceId: peerDeviceId,
        displayName: peerName,
        supportedTransports: {TransportType.ble},
        batteryLevel: 80,
        isRelay: true,
        isInternetGateway: false,
        rssi: -65,
        lastSeen: DateTime.now(),
      );

      _peers[endpointId] = peer;
      _discoveredPeersController.add(peer);

      // Exchange capabilities immediately with newly connected peer
      broadcastCapabilities();
    } else {
      _peers.remove(endpointId);
      _endpointNames.remove(endpointId);
    }
  }

  void _onDisconnected(String endpointId) {
    _peers.remove(endpointId);
    _endpointNames.remove(endpointId);
    _pendingConnections.remove(endpointId);
  }

  void _onEndpointLost(String? endpointId) {
    if (endpointId == null) return;
    _pendingConnections.remove(endpointId);
    if (!_peers.containsKey(endpointId)) {
      _endpointNames.remove(endpointId);
    }
  }

  void _onBytesReceived(String endpointId, Uint8List rawBytes) {
    // Update peer lastSeen
    if (_peers.containsKey(endpointId)) {
      _peers[endpointId] = _peers[endpointId]!.copyWith(
        lastSeen: DateTime.now(),
      );
      _discoveredPeersController.add(_peers[endpointId]!);
    }

    final frame = BleFrame.tryParse(rawBytes);
    if (frame == null) {
      // Direct raw packet fallback
      _receivedPacketsController.add(
        TransportPacket(
          rawBytes: rawBytes,
          sourcePeerId: endpointId,
          transportType: TransportType.ble,
          timestamp: DateTime.now(),
        ),
      );
      return;
    }

    switch (frame.type) {
      case BleFrameType.capabilityExchange:
        _handleCapabilityPacket(endpointId, frame);
        break;

      case BleFrameType.ack:
        if (frame.ackId != null) {
          _pendingAcks.remove(frame.ackId)?.complete(true);
          _ackEventsController.add(frame.ackId!);
        }
        break;

      case BleFrameType.data:
        // Reply with ACK if requested
        if (frame.ackRequested) {
          _sendAck(endpointId, frame.id);
        }
        final payload = frame.payload ?? rawBytes;
        _receivedPacketsController.add(
          TransportPacket(
            rawBytes: payload,
            sourcePeerId: endpointId,
            transportType: TransportType.ble,
            timestamp: DateTime.fromMillisecondsSinceEpoch(frame.timestamp),
          ),
        );
        break;

      case BleFrameType.routing:
        // Routing announcement frame
        break;
    }
  }

  void _handleCapabilityPacket(String endpointId, BleFrame frame) {
    final cap = frame.capability;
    if (cap == null) return;

    final peerDeviceId = cap['device_id']?.toString() ??
        _peers[endpointId]?.deviceId ??
        'SR-${endpointId.hashCode.abs() % 10000}';

    final safeName = PrivacySanitizer.sanitizeDisplayName(
      cap['display_name']?.toString(),
      peerDeviceId,
    );

    final rawTransports = cap['supported_transports'];
    final Set<TransportType> transports = {TransportType.ble};
    if (rawTransports is Iterable) {
      for (final item in rawTransports) {
        for (final t in TransportType.values) {
          if (t.name == item.toString()) {
            transports.add(t);
            break;
          }
        }
      }
    }

    final updatedPeer = PeerInfo(
      peerId: endpointId,
      deviceId: peerDeviceId,
      displayName: safeName,
      supportedTransports: transports,
      batteryLevel: (cap['battery_level'] as num?)?.toInt() ?? 80,
      isRelay: cap['is_relay'] == true,
      isInternetGateway: cap['is_internet_gateway'] == true,
      rssi: _peers[endpointId]?.rssi ?? -65,
      lastSeen: DateTime.now(),
    );

    _peers[endpointId] = updatedPeer;
    _discoveredPeersController.add(updatedPeer);
  }

  Future<void> _sendAck(String endpointId, String packetId) async {
    final ackFrame = BleFrame(
      type: BleFrameType.ack,
      id: 'ACK-${DateTime.now().microsecondsSinceEpoch}',
      sourceDeviceId: localDeviceId,
      destinationDeviceId: endpointId,
      ackId: packetId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    try {
      await _nearby.sendBytesPayload(endpointId, ackFrame.toBytes());
    } catch (e) {
      debugPrint('[BleTransport] Failed to send ACK: $e');
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
  void simulatePeerDisconnected(String peerId) {
    _peers.remove(peerId);
  }

  @override
  Future<void> dispose() async {
    await stopDiscovery();
    await _discoveredPeersController.close();
    await _receivedPacketsController.close();
    await _ackEventsController.close();
  }
}
