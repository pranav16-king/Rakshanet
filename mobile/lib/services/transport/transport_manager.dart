import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'ble_transport.dart';
import 'mesh_transport.dart';
import 'wifi_direct_transport.dart';

/// TransportManager: Central Orchestrator & Dual-Channel Mesh Router
///
/// Responsibilities:
/// 1. Manages dual physical transports: BLE (low-power control/SOS) and Wi-Fi Direct (high-bandwidth).
/// 2. Implements automatic optimal transport selection:
///    - Small packets (< 4 KB), control frames, ACKs, SOS pings -> BLE
///    - Encrypted image chunks, attachments, bulk sync -> Wi-Fi Direct (with BLE fallback)
/// 3. Unified stream of incoming packets (`incomingPackets`) from all active transports.
/// 4. Consolidated list of online mesh peers (`onlinePeers`) merging capabilities across channels.
/// 5. Internet Gateway tracking: detects whether this device or any mesh peer has active Internet uplink.
class TransportManager extends ChangeNotifier {
  static TransportManager? _instance;
  static TransportManager get instance => _instance ??= TransportManager();

  static const int maxBlePacketThreshold = 4096; // 4 KB limit

  final BleTransport bleTransport;
  final WifiDirectTransport wifiDirectTransport;
  final bool enablePeriodicInternetCheck;

  // Peer registries
  final Map<String, PeerInfo> _peersByDeviceId = <String, PeerInfo>{};
  final Map<String, PeerInfo> _peersByEndpointId = <String, PeerInfo>{};

  // Stream Controllers
  final StreamController<TransportPacket> _incomingPacketsController =
      StreamController<TransportPacket>.broadcast();
  final StreamController<List<PeerInfo>> _peerUpdatesController =
      StreamController<List<PeerInfo>>.broadcast();
  final StreamController<bool> _gatewayAvailabilityController =
      StreamController<bool>.broadcast();

  // Internal Subscriptions
  StreamSubscription<TransportPacket>? _blePacketSub;
  StreamSubscription<TransportPacket>? _wifiPacketSub;
  StreamSubscription<PeerInfo>? _blePeerSub;
  StreamSubscription<PeerInfo>? _wifiPeerSub;
  Timer? _internetCheckTimer;
  Timer? _peerPruneTimer;

  // Internet Gateway Status
  bool _hasLocalInternet = false;
  bool _lastReportedGatewayStatus = false;

  TransportManager({
    BleTransport? bleTransport,
    WifiDirectTransport? wifiDirectTransport,
    this.enablePeriodicInternetCheck = true,
  })  : bleTransport = bleTransport ?? BleTransport(),
        wifiDirectTransport = wifiDirectTransport ?? WifiDirectTransport() {
    _initStreams();
  }

  void _initStreams() {
    // 1. Pipeline BLE Packets
    _blePacketSub = bleTransport.receivedPackets.listen((packet) {
      _incomingPacketsController.add(packet);
      _touchPeer(packet.sourcePeerId);
    });

    // 2. Pipeline Wi-Fi Direct Packets
    _wifiPacketSub = wifiDirectTransport.receivedPackets.listen((packet) {
      _incomingPacketsController.add(packet);
      _touchPeer(packet.sourcePeerId);
    });

    // 3. Pipeline BLE Discovered Peers
    _blePeerSub = bleTransport.discoveredPeers.listen((peer) {
      _mergePeer(peer, TransportType.ble);
    });

    // 4. Pipeline Wi-Fi Direct Discovered Peers
    _wifiPeerSub = wifiDirectTransport.discoveredPeers.listen((peer) {
      _mergePeer(peer, TransportType.wifiDirect);
    });

    // 5. Periodic Internet Gateway Check
    if (enablePeriodicInternetCheck) {
      _checkInternetStatus();
      _internetCheckTimer = Timer.periodic(
        const Duration(seconds: 25),
        (_) => _checkInternetStatus(),
      );
    }

    // 6. Prune stale peers every 45 seconds
    _peerPruneTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => _pruneStalePeers(),
    );
  }

  /// Unified stream of incoming packets from all physical transports.
  Stream<TransportPacket> get incomingPackets =>
      _incomingPacketsController.stream;

  /// Stream of consolidated online peer updates.
  Stream<List<PeerInfo>> get peerUpdates => _peerUpdatesController.stream;

  /// Stream of Internet Gateway availability status changes.
  Stream<bool> get internetGatewayAvailabilityStream =>
      _gatewayAvailabilityController.stream;

  /// Consolidated list of currently active and online peers.
  List<PeerInfo> get onlinePeers {
    return _peersByDeviceId.values
        .where((peer) => peer.isOnline)
        .toList(growable: false);
  }

  /// Whether this local device currently has active Internet uplink connectivity.
  bool get hasLocalInternet => _hasLocalInternet;

  /// Whether any connected mesh peer in radio range acts as an Internet Gateway.
  bool get hasMeshInternetGateway =>
      onlinePeers.any((peer) => peer.isInternetGateway);

  /// Whether Internet Gateway access is available anywhere across the local device or mesh.
  bool get isInternetGatewayAvailable =>
      _hasLocalInternet || hasMeshInternetGateway;

  /// Returns the optimal peer acting as Internet Gateway, or null if none available.
  PeerInfo? get activeInternetGatewayNode {
    final gateways =
        onlinePeers.where((p) => p.isInternetGateway).toList();
    if (gateways.isEmpty) return null;

    // Pick gateway with highest RSSI and battery
    gateways.sort((a, b) {
      final scoreA = a.rssi + (a.batteryLevel ~/ 2);
      final scoreB = b.rssi + (b.batteryLevel ~/ 2);
      return scoreB.compareTo(scoreA);
    });
    return gateways.first;
  }

  /// Starts discovery on all managed physical transports.
  Future<void> startDiscovery() async {
    await Future.wait([
      bleTransport.startDiscovery(),
      wifiDirectTransport.startDiscovery(),
    ]);
  }

  /// Stops discovery on all managed physical transports.
  Future<void> stopDiscovery() async {
    await Future.wait([
      bleTransport.stopDiscovery(),
      wifiDirectTransport.stopDiscovery(),
    ]);
  }

  /// Automatically selects the optimal transport channel and transmits data.
  ///
  /// Routing Rules:
  /// - Small packets (< 4 KB), control frames, ACKs, SOS pings -> `BleTransport`
  /// - Encrypted image chunks, bulk data -> `WifiDirectTransport` if peer supports it, with `BleTransport` fallback.
  Future<bool> send({
    required String peerId,
    required Uint8List data,
    bool isBulkOrMedia = false,
  }) async {
    final peer = getPeer(peerId);

    // Decision Logic:
    // Small text, control, ACK, SOS ping (< 4 KB) -> BleTransport
    if (data.length < maxBlePacketThreshold && !isBulkOrMedia) {
      if (bleTransport.isAvailable) {
        final success = await bleTransport.send(peerId, data);
        if (success) return true;
      }

      // If BLE is unavailable or failed, fallback to Wi-Fi Direct
      if (wifiDirectTransport.isAvailable &&
          (peer == null || peer.supports(TransportType.wifiDirect))) {
        return await wifiDirectTransport.send(peerId, data);
      }
      return false;
    }

    // High-volume bulk data, images, attachments -> WifiDirectTransport
    final peerSupportsWifi =
        peer?.supports(TransportType.wifiDirect) ?? true;

    if (peerSupportsWifi && wifiDirectTransport.isAvailable) {
      final success = await wifiDirectTransport.send(peerId, data);
      if (success) return true;
      debugPrint(
        '[TransportManager] Wi-Fi Direct send failed, falling back to BLE',
      );
    }

    // Fallback: BleTransport
    if (bleTransport.isAvailable) {
      if (data.length <= maxBlePacketThreshold) {
        return await bleTransport.send(peerId, data);
      } else {
        // Chunk fallback for larger payloads over BLE
        return await _sendChunkedBleFallback(peerId, data);
      }
    }

    return false;
  }

  /// Broadcasts a data packet across the mesh using the optimal transport.
  Future<int> broadcast(
    Uint8List data, {
    bool isBulkOrMedia = false,
  }) async {
    if (data.length < maxBlePacketThreshold && !isBulkOrMedia) {
      // Emergency bursts / SOS / small messages broadcast over BLE
      if (bleTransport.isAvailable) {
        final count = await bleTransport.broadcast(data);
        if (count > 0) return count;
      }
      if (wifiDirectTransport.isAvailable) {
        return await wifiDirectTransport.broadcast(data);
      }
      return 0;
    } else {
      // Bulk broadcast
      if (wifiDirectTransport.isAvailable) {
        final count = await wifiDirectTransport.broadcast(data);
        if (count > 0) return count;
      }
      if (bleTransport.isAvailable && data.length <= maxBlePacketThreshold) {
        return await bleTransport.broadcast(data);
      }
      return 0;
    }
  }

  /// Look up peer by endpoint ID or device ID.
  PeerInfo? getPeer(String peerOrDeviceId) {
    return _peersByEndpointId[peerOrDeviceId] ??
        _peersByDeviceId[peerOrDeviceId];
  }

  // ---------------------------------------------------------------------------
  // Internal Helpers & Peer Merging
  // ---------------------------------------------------------------------------

  void _mergePeer(PeerInfo incoming, TransportType originTransport) {
    final existing = _peersByDeviceId[incoming.deviceId] ??
        _peersByEndpointId[incoming.peerId];

    final Set<TransportType> mergedTransports = {
      originTransport,
      ...?existing?.supportedTransports,
      ...incoming.supportedTransports,
    };

    final merged = (existing == null)
        ? incoming.copyWith(supportedTransports: mergedTransports)
        : existing.copyWith(
            peerId: incoming.peerId.isNotEmpty
                ? incoming.peerId
                : existing.peerId,
            displayName: incoming.displayName.isNotEmpty
                ? incoming.displayName
                : existing.displayName,
            supportedTransports: mergedTransports,
            batteryLevel: incoming.batteryLevel,
            isRelay: incoming.isRelay || existing.isRelay,
            isInternetGateway:
                incoming.isInternetGateway || existing.isInternetGateway,
            rssi: incoming.rssi != 0 ? incoming.rssi : existing.rssi,
            lastSeen: incoming.lastSeen.isAfter(existing.lastSeen)
                ? incoming.lastSeen
                : existing.lastSeen,
          );

    _peersByDeviceId[merged.deviceId] = merged;
    if (merged.peerId.isNotEmpty) {
      _peersByEndpointId[merged.peerId] = merged;
    }

    _peerUpdatesController.add(onlinePeers);
    _checkGatewayStatusChanged();
    notifyListeners();
  }

  void _touchPeer(String peerId) {
    final peer = _peersByEndpointId[peerId];
    if (peer != null) {
      final updated = peer.copyWith(lastSeen: DateTime.now());
      _peersByDeviceId[updated.deviceId] = updated;
      _peersByEndpointId[peerId] = updated;
      _peerUpdatesController.add(onlinePeers);
      notifyListeners();
    }
  }

  void _pruneStalePeers() {
    final now = DateTime.now();
    _peersByDeviceId.removeWhere((_, peer) =>
        now.difference(peer.lastSeen).inMinutes > 5);
    _peersByEndpointId.removeWhere((_, peer) =>
        now.difference(peer.lastSeen).inMinutes > 5);

    _peerUpdatesController.add(onlinePeers);
    _checkGatewayStatusChanged();
    notifyListeners();
  }

  /// Splits larger payload into small < 4KB segments when falling back to BLE.
  Future<bool> _sendChunkedBleFallback(String peerId, Uint8List data) async {
    const int chunkSize = 3000; // Safe threshold well under 4096
    final totalChunks = (data.length / chunkSize).ceil();

    for (int i = 0; i < totalChunks; i++) {
      final start = i * chunkSize;
      final end = (start + chunkSize < data.length) ? start + chunkSize : data.length;
      final chunkData = data.sublist(start, end);

      final ok = await bleTransport.send(peerId, chunkData);
      if (!ok) return false;
    }
    return true;
  }

  /// Verifies active Internet connectivity using DNS lookup.
  Future<bool> _checkInternetStatus() async {
    try {
      final result = await InternetAddress.lookup('dns.google')
          .timeout(const Duration(seconds: 3));
      final isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      _hasLocalInternet = isOnline;
    } catch (_) {
      _hasLocalInternet = false;
    }

    _checkGatewayStatusChanged();
    return _hasLocalInternet;
  }

  void _checkGatewayStatusChanged() {
    final currentStatus = isInternetGatewayAvailable;
    if (_lastReportedGatewayStatus != currentStatus) {
      _lastReportedGatewayStatus = currentStatus;
      _gatewayAvailabilityController.add(currentStatus);
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Testing Hooks
  // ---------------------------------------------------------------------------

  @visibleForTesting
  void registerPeerForTesting(PeerInfo peer) {
    _mergePeer(peer, peer.supportedTransports.first);
  }

  @visibleForTesting
  void setLocalInternetForTesting(bool isOnline) {
    _hasLocalInternet = isOnline;
    _checkGatewayStatusChanged();
  }

  @override
  void dispose() {
    _blePacketSub?.cancel();
    _wifiPacketSub?.cancel();
    _blePeerSub?.cancel();
    _wifiPeerSub?.cancel();
    _internetCheckTimer?.cancel();
    _peerPruneTimer?.cancel();

    _incomingPacketsController.close();
    _peerUpdatesController.close();
    _gatewayAvailabilityController.close();

    bleTransport.dispose();
    wifiDirectTransport.dispose();
    super.dispose();
  }
}
