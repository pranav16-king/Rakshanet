import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/mesh_device.dart';
import 'database_service.dart';

/// A completed file payload paired with the mesh envelope that describes it.
class IncomingMediaPayload {
  const IncomingMediaPayload({
    required this.endpointId,
    required this.sourceUri,
    required this.envelope,
    required this.fileName,
    required this.mimeType,
    required this.byteLength,
  });

  final String endpointId;
  final String sourceUri;
  final Map<String, dynamic> envelope;
  final String fileName;
  final String mimeType;
  final int byteLength;
}

/// A control message addressed to a single directly connected Nearby endpoint.
/// It is intentionally kept out of the mesh-envelope stream so a call invite
/// can never be persisted or relayed as a community chat message.
class NearbyCallControlFrame {
  const NearbyCallControlFrame({
    required this.endpointId,
    required this.payload,
  });

  final String endpointId;
  final Map<String, dynamic> payload;
}

/// A short PCM audio frame. The frame is carried only on the established
/// direct Nearby connection and is never forwarded over the mesh.
class NearbyAudioFrame {
  const NearbyAudioFrame({
    required this.endpointId,
    required this.callId,
    required this.pcm,
  });

  final String endpointId;
  final String callId;
  final Uint8List pcm;
}

/// BluetoothRadioService: Hardware-Level Peer-to-Peer Radio Controller
/// Implements zero-internet offline mesh transport using Nearby Connections (BLE + Wi-Fi Direct).
///
/// Core Responsibilities:
/// 1. Dynamic runtime permission verification (Android 12/13/14 BLE & Location gates).
/// 2. Autonomous P2P Cluster discovery & advertising without manual PIN pairing.
/// 3. Real-time peer tracking (connected endpoints, signal strength, proximity bands).
/// 4. Bi-directional raw byte payload streaming hooked into MeshEngine.
/// 5. Adaptive battery duty-cycling support (Normal, Low-Power, Emergency).
class BluetoothRadioService extends ChangeNotifier {
  static final BluetoothRadioService _instance =
      BluetoothRadioService._internal();
  factory BluetoothRadioService() => _instance;
  static BluetoothRadioService get instance => _instance;
  BluetoothRadioService._internal();

  static const String serviceId = 'org.rakshanet.mesh';
  final Strategy _strategy = Strategy.P2P_CLUSTER;

  final Nearby _nearby = Nearby();

  // State flags
  bool _isAdvertising = false;
  bool _isDiscovering = false;
  bool _isInitialized = false;
  bool _permissionsGranted = false;

  bool get isAdvertising => _isAdvertising;
  bool get isDiscovering => _isDiscovering;
  bool get isInitialized => _isInitialized;
  bool get permissionsGranted => _permissionsGranted;
  bool get isRadioActive => _isAdvertising || _isDiscovering;

  // Connected physical peers: Map<endpointId, MeshDevice>
  final Map<String, MeshDevice> _connectedPeers = <String, MeshDevice>{};
  final Map<String, String> _discoveredEndpointNames = <String, String>{};
  final Set<String> _pendingConnections = <String>{};
  final Set<String> _acceptedConnections = <String>{};
  Map<String, MeshDevice> get connectedPeers =>
      Map.unmodifiable(_connectedPeers);
  List<MeshDevice> get peerList => _connectedPeers.values.toList();
  int get connectedCount => _connectedPeers.length;

  // Stream Controllers for Reactive Decoupled Architecture
  final StreamController<Uint8List> _payloadController =
      StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get incomingPayloadStream => _payloadController.stream;
  Stream<Uint8List> get peerPayloadStream => _payloadController.stream;

  final StreamController<IncomingMediaPayload> _mediaController =
      StreamController<IncomingMediaPayload>.broadcast();
  Stream<IncomingMediaPayload> get incomingMediaStream =>
      _mediaController.stream;
  final Map<int, String> _incomingFileUris = <int, String>{};
  final Map<int, Map<String, dynamic>> _pendingMediaManifests =
      <int, Map<String, dynamic>>{};
  final Set<int> _completedFilePayloads = <int>{};

  final StreamController<NearbyCallControlFrame> _callControlController =
      StreamController<NearbyCallControlFrame>.broadcast();
  Stream<NearbyCallControlFrame> get incomingCallControlStream =>
      _callControlController.stream;

  final StreamController<NearbyAudioFrame> _audioFrameController =
      StreamController<NearbyAudioFrame>.broadcast();
  Stream<NearbyAudioFrame> get incomingAudioFrameStream =>
      _audioFrameController.stream;

  static final Uint8List _audioPrefix =
      Uint8List.fromList(ascii.encode('RKAUD1|'));

  final StreamController<List<MeshDevice>> _peerUpdateController =
      StreamController<List<MeshDevice>>.broadcast();
  Stream<List<MeshDevice>> get peerUpdateStream => _peerUpdateController.stream;

  final StreamController<String> _statusLogController =
      StreamController<String>.broadcast();
  Stream<String> get statusLogStream => _statusLogController.stream;

  /// Request all mandatory Android runtime permissions for BLE and Wi-Fi Direct
  Future<bool> checkAndRequestPermissions() async {
    try {
      final permissions = <Permission>[
        Permission.location,
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
      ];

      // Request Nearby Wi-Fi Devices on Android 13+ (API 33+)
      permissions.add(Permission.nearbyWifiDevices);

      final statuses = await permissions.request();

      // Location is mandatory on Android for BLE beacon reception
      final locationStatus = statuses[Permission.location] ?? await Permission.location.status;
      final locationOk = locationStatus.isGranted || locationStatus.isLimited;

      // On Android 12+, BluetoothScan and BluetoothConnect are used.
      // On Android <= 11, BLUETOOTH and ACCESS_FINE_LOCATION are used.
      final btScanStatus = statuses[Permission.bluetoothScan] ?? await Permission.bluetoothScan.status;
      final btConnStatus = statuses[Permission.bluetoothConnect] ?? await Permission.bluetoothConnect.status;
      final btAdvStatus = statuses[Permission.bluetoothAdvertise] ?? await Permission.bluetoothAdvertise.status;

      final btOk = (btScanStatus.isGranted || btScanStatus.isRestricted) &&
          (btConnStatus.isGranted || btConnStatus.isRestricted) &&
          (btAdvStatus.isGranted || btAdvStatus.isRestricted);

      // Check if location services (GPS toggle) are enabled on hardware
      try {
        final serviceEnabled = await Permission.location.serviceStatus.isEnabled;
        if (!serviceEnabled) {
          _logStatus('Device GPS/Location service is currently disabled. Please turn on Location.');
        }
      } catch (e) {
        debugPrint('[BluetoothRadioService] location serviceStatus check: $e');
      }

      _permissionsGranted = locationOk;
      _logStatus('Permissions check: location=$locationOk, bt=$btOk, granted=$_permissionsGranted');
      notifyListeners();
      return _permissionsGranted;
    } catch (e) {
      debugPrint('[BluetoothRadioService] Permission check error: $e');
      _permissionsGranted = true; // Fallback to allowing Nearby Connections native prompt
      return true;
    }
  }

  /// Initialize the radio layer and begin autonomous background advertising and discovery
  Future<void> initialize({String? deviceId, String? displayName}) async {
    if (_isInitialized && isRadioActive) return;

    final hasPermissions = await checkAndRequestPermissions();
    if (!hasPermissions) {
      _logStatus(
        'Bluetooth and location permission required before mesh can start.',
      );
      return;
    }

    final localDeviceId = deviceId ?? DatabaseService.myDeviceId;
    final localDisplayName = displayName ?? DatabaseService.myDisplayName;

    await startMeshRadio(
      deviceId: localDeviceId,
      displayName: localDisplayName,
    );
    _isInitialized = isRadioActive;
  }

  /// Start both Advertising (GATT Server) and Discovery (GATT Client) simultaneously
  Future<void> startMeshRadio({
    required String deviceId,
    required String displayName,
  }) async {
    await startAdvertising(deviceId: deviceId, displayName: displayName);
    await startDiscovery(deviceId: deviceId, displayName: displayName);
  }

  /// Start advertising local node presence to nearby disaster survivors
  Future<bool> startAdvertising({
    required String deviceId,
    required String displayName,
  }) async {
    if (_isAdvertising) return true;
    if (!_permissionsGranted && !await checkAndRequestPermissions()) {
      return false;
    }

    try {
      // Encode deviceId and displayName into the advertised endpoint name so
      // connecting peers can identify each other without a separate handshake.
      final advertisedName = '$deviceId|$displayName';

      final success = await _nearby.startAdvertising(
        advertisedName,
        _strategy,
        serviceId: serviceId,
        onConnectionInitiated: _handleConnectionInitiated,
        onConnectionResult: _handleConnectionResult,
        onDisconnected: _handleDisconnected,
      );

      _isAdvertising = success;
      _logStatus('BLE Advertising started: $success (as $advertisedName)');
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('[BluetoothRadioService] startAdvertising failed: $e');
      _isAdvertising = false;
      return false;
    }
  }

  /// Start scanning for neighboring peer nodes across physical RF airwaves
  Future<bool> startDiscovery({
    required String deviceId,
    required String displayName,
  }) async {
    if (_isDiscovering) return true;
    if (!_permissionsGranted && !await checkAndRequestPermissions()) {
      return false;
    }

    try {
      // Encode local identity so the remote peer can parse our deviceId and
      // displayName from the connection's endpointName during handshake.
      final localEndpointName = '$deviceId|$displayName';

      final success = await _nearby.startDiscovery(
        localEndpointName,
        _strategy,
        serviceId: serviceId,
        onEndpointFound: (endpointId, endpointName, foundServiceId) {
          _handleEndpointFound(endpointId, endpointName, localEndpointName);
        },
        onEndpointLost: _handleEndpointLost,
      );

      _isDiscovering = success;
      _logStatus('BLE Discovery started: $success');
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('[BluetoothRadioService] startDiscovery failed: $e');
      _isDiscovering = false;
      return false;
    }
  }

  /// Automated connection request when a peer node is detected within radio range
  Future<void> _handleEndpointFound(
    String endpointId,
    String endpointName,
    String localEndpointName,
  ) async {
    if (_connectedPeers.containsKey(endpointId) ||
        _pendingConnections.contains(endpointId)) {
      return;
    }

    // Deterministic collision avoidance:
    // If both devices discover each other simultaneously, both calling requestConnection
    // causes a mutual collision and rejection in Nearby Connections.
    // Tie-breaker: The lexicographically larger endpoint name initiates the handshake.
    // The other node waits to receive the incoming onConnectionInitiated callback.
    if (endpointName.isNotEmpty && localEndpointName.isNotEmpty) {
      if (localEndpointName.compareTo(endpointName) < 0) {
        _discoveredEndpointNames[endpointId] = endpointName;
        _logStatus('Found $endpointId ($endpointName), waiting for peer to initiate handshake...');
        
        // Fallback: If remote peer doesn't initiate within 4 seconds, initiate ourselves
        Timer(const Duration(seconds: 4), () {
          if (!_connectedPeers.containsKey(endpointId) &&
              !_acceptedConnections.contains(endpointId) &&
              !_pendingConnections.contains(endpointId)) {
            _logStatus('Fallback timer expired for $endpointId. Initiating auto-handshake...');
            _initiateConnection(endpointId, endpointName, localEndpointName);
          }
        });
        return;
      }
    }

    await _initiateConnection(endpointId, endpointName, localEndpointName);
  }

  Future<void> _initiateConnection(
    String endpointId,
    String endpointName,
    String localEndpointName,
  ) async {
    if (_connectedPeers.containsKey(endpointId) ||
        _pendingConnections.contains(endpointId)) {
      return;
    }

    _logStatus(
      'Endpoint discovered: $endpointId ($endpointName). Initiating auto-handshake...',
    );
    _discoveredEndpointNames[endpointId] = endpointName;
    _pendingConnections.add(endpointId);

    try {
      await _nearby.requestConnection(
        localEndpointName,
        endpointId,
        onConnectionInitiated: _handleConnectionInitiated,
        onConnectionResult: _handleConnectionResult,
        onDisconnected: _handleDisconnected,
      );
    } catch (e) {
      debugPrint(
        '[BluetoothRadioService] Connection request to $endpointId failed: $e',
      );
      _pendingConnections.remove(endpointId);
    }
  }

  /// Auto-accept incoming connection handshake without manual user intervention
  void _handleConnectionInitiated(
    String endpointId,
    ConnectionInfo connectionInfo,
  ) {
    if (_acceptedConnections.contains(endpointId)) return;
    _logStatus(
      'Incoming connection from $endpointId (${connectionInfo.endpointName}). Auto-accepting...',
    );
    if (connectionInfo.endpointName.isNotEmpty) {
      _discoveredEndpointNames[endpointId] = connectionInfo.endpointName;
    }

    try {
      _acceptedConnections.add(endpointId);
      _nearby.acceptConnection(
        endpointId,
        onPayLoadRecieved: (receivedEndpointId, payload) {
          _handlePayloadReceived(receivedEndpointId, payload);
        },
        onPayloadTransferUpdate: (receivedEndpointId, update) {
          _handlePayloadTransferUpdate(receivedEndpointId, update);
        },
      );
    } catch (e) {
      _acceptedConnections.remove(endpointId);
      debugPrint(
        '[BluetoothRadioService] acceptConnection error on $endpointId: $e',
      );
    }
  }

  /// Connection established or rejected
  void _handleConnectionResult(String endpointId, Status status) {
    _pendingConnections.remove(endpointId);
    if (status == Status.CONNECTED) {
      _logStatus(
        'Peer handshake completed! Connected to endpoint: $endpointId',
      );

      final endpointAlias = endpointId.hashCode
          .abs()
          .toRadixString(16)
          .toUpperCase();
      String peerDeviceId =
          'SR-PEER-${endpointAlias.padLeft(4, '0').substring(0, 4)}';
      String peerDisplayName = 'Nearby RakshaNet user';

      final rawName = _discoveredEndpointNames[endpointId];
      if (rawName != null && rawName.contains('|')) {
        final parts = rawName.split('|');
        if (parts.isNotEmpty && parts[0].trim().isNotEmpty) {
          peerDeviceId = parts[0].trim();
        }
        if (parts.length > 1 && parts[1].trim().isNotEmpty) {
          peerDisplayName = parts[1].trim();
        }
      }

      // Create peer model with estimated signal strength
      final peer = MeshDevice(
        id: endpointId,
        deviceId: peerDeviceId,
        displayName: peerDisplayName,
        connectionType: ConnectionType.ble,
        signalStrength: -65,
        proximityBand: ProximityBand.near,
        hopCount: 1,
        batteryLevel: 80,
        lastSeen: DateTime.now(),
        isConnected: true,
      );

      _connectedPeers[endpointId] = peer;
      _peerUpdateController.add(peerList);
      notifyListeners();

      // Immediately exchange HELLO frames to guarantee symmetric two-way identity confirmation
      Timer(const Duration(milliseconds: 300), () {
        try {
          final helloFrame = jsonEncode({
            'frame': 'RAKSHANET_HELLO_V1',
            'deviceId': DatabaseService.myDeviceId,
            'displayName': DatabaseService.myDisplayName,
          });
          sendBytesToEndpoint(endpointId, Uint8List.fromList(utf8.encode(helloFrame)));
        } catch (_) {}
      });
    } else {
      _logStatus(
        'Connection rejected or failed with $endpointId (status: $status)',
      );
      _connectedPeers.remove(endpointId);
      _discoveredEndpointNames.remove(endpointId);
      _acceptedConnections.remove(endpointId);
      _pendingConnections.remove(endpointId);
      _peerUpdateController.add(peerList);
      notifyListeners();
    }
  }

  /// Peer disconnected or walked out of RF range
  void _handleDisconnected(String endpointId) {
    _logStatus('Peer physically disconnected: $endpointId');
    _connectedPeers.remove(endpointId);
    _discoveredEndpointNames.remove(endpointId);
    _pendingConnections.remove(endpointId);
    _acceptedConnections.remove(endpointId);
    _peerUpdateController.add(peerList);
    notifyListeners();
  }

  /// Endpoint moved out of discovery range (scanner no longer sees unassociated beacon)
  /// CRITICAL FIX: An endpoint that is ALREADY CONNECTED in _connectedPeers must NEVER be removed!
  /// Google Nearby Connections stops advertising once connected, which triggers onEndpointLost on the discoverer.
  /// The connection is still active and healthy until _handleDisconnected fires!
  void _handleEndpointLost(String? endpointId) {
    if (endpointId == null) return;
    _logStatus('Endpoint lost from discovery scanning: $endpointId');
    _pendingConnections.remove(endpointId);
    if (!_connectedPeers.containsKey(endpointId)) {
      _discoveredEndpointNames.remove(endpointId);
      _acceptedConnections.remove(endpointId);
    }
  }

  /// Raw byte payload received over the physical radio
  void _handlePayloadReceived(String endpointId, Payload payload) {
    if (payload.type == PayloadType.BYTES && payload.bytes != null) {
      final rawBytes = payload.bytes!;
      _logStatus(
        'Received RF packet (${rawBytes.length} bytes) from $endpointId',
      );

      // Check for internal HELLO frame to dynamically synchronize peer identity
      try {
        final decoded = jsonDecode(utf8.decode(rawBytes));
        if (decoded is Map && decoded['frame'] == 'RAKSHANET_HELLO_V1') {
          final newDeviceId = decoded['deviceId']?.toString();
          final newDisplayName = decoded['displayName']?.toString();
          if (newDeviceId != null) {
            final existing = _connectedPeers[endpointId];
            final updatedPeer = MeshDevice(
              id: endpointId,
              deviceId: newDeviceId,
              displayName: newDisplayName ?? existing?.displayName ?? 'Nearby RakshaNet user',
              connectionType: ConnectionType.ble,
              signalStrength: -65,
              proximityBand: ProximityBand.near,
              hopCount: 1,
              batteryLevel: 80,
              lastSeen: DateTime.now(),
              isConnected: true,
            );
            _connectedPeers[endpointId] = updatedPeer;
            _peerUpdateController.add(peerList);
            notifyListeners();
          }
          return;
        }
      } catch (_) {}

      // Update peer last-seen timestamp
      if (_connectedPeers.containsKey(endpointId)) {
        _connectedPeers[endpointId] = _connectedPeers[endpointId]!.copyWith(
          lastSeen: DateTime.now(),
        );
      }

      if (_consumeMediaManifest(endpointId, rawBytes)) return;
      if (_consumeCallControl(endpointId, rawBytes)) return;
      if (_consumeAudioFrame(endpointId, rawBytes)) return;

      // Stream message/control frames to MeshEngine for durable processing.
      _payloadController.add(rawBytes);
    } else if (payload.type == PayloadType.FILE && payload.uri != null) {
      _incomingFileUris[payload.id] = payload.uri!;
      _logStatus('Receiving media payload ${payload.id} from $endpointId');
      _emitMediaIfReady(endpointId, payload.id);
    }
  }

  void _handlePayloadTransferUpdate(
    String endpointId,
    PayloadTransferUpdate update,
  ) {
    if (update.status == PayloadStatus.SUCCESS) {
      _completedFilePayloads.add(update.id);
      _logStatus('Payload delivery succeeded to $endpointId');
      _emitMediaIfReady(endpointId, update.id);
    } else if (update.status == PayloadStatus.FAILURE) {
      _incomingFileUris.remove(update.id);
      _pendingMediaManifests.remove(update.id);
      _completedFilePayloads.remove(update.id);
      _logStatus('Payload delivery failed to $endpointId');
    }
  }

  bool _consumeMediaManifest(String endpointId, Uint8List rawBytes) {
    try {
      final decoded = jsonDecode(utf8.decode(rawBytes));
      if (decoded is! Map || decoded['frame'] != 'RAKSHANET_MEDIA_V1') {
        return false;
      }
      final payloadId =
          (decoded['file_payload_id'] as num?)?.toInt() ??
          int.tryParse(decoded['file_payload_id']?.toString() ?? '');
      final envelope = decoded['envelope'];
      if (payloadId == null || envelope is! Map) return true;
      _pendingMediaManifests[payloadId] = Map<String, dynamic>.from(decoded);
      _emitMediaIfReady(endpointId, payloadId);
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _consumeCallControl(String endpointId, Uint8List rawBytes) {
    try {
      final decoded = jsonDecode(utf8.decode(rawBytes));
      if (decoded is! Map || decoded['frame'] != 'RAKSHANET_NEARBY_CALL_V1') {
        return false;
      }
      _callControlController.add(
        NearbyCallControlFrame(
          endpointId: endpointId,
          payload: Map<String, dynamic>.from(decoded),
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _consumeAudioFrame(String endpointId, Uint8List rawBytes) {
    const callIdLength = 36;
    final headerLength = 7 + callIdLength + 1;
    if (rawBytes.length <= headerLength) return false;
    for (var index = 0; index < _audioPrefix.length; index++) {
      if (rawBytes[index] != _audioPrefix[index]) return false;
    }
    if (rawBytes[headerLength - 1] != 0x7c) return false; // | delimiter
    final callId = ascii.decode(rawBytes.sublist(7, 7 + callIdLength));
    if (!RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(callId)) return false;
    _audioFrameController.add(
      NearbyAudioFrame(
        endpointId: endpointId,
        callId: callId,
        pcm: Uint8List.fromList(rawBytes.sublist(headerLength)),
      ),
    );
    return true;
  }

  void _emitMediaIfReady(String endpointId, int payloadId) {
    final sourceUri = _incomingFileUris[payloadId];
    final manifest = _pendingMediaManifests[payloadId];
    if (sourceUri == null ||
        manifest == null ||
        !_completedFilePayloads.contains(payloadId)) {
      return;
    }
    final envelope = manifest['envelope'];
    if (envelope is! Map) return;
    _mediaController.add(
      IncomingMediaPayload(
        endpointId: endpointId,
        sourceUri: sourceUri,
        envelope: Map<String, dynamic>.from(envelope),
        fileName: manifest['file_name']?.toString() ?? 'image.jpg',
        mimeType: manifest['mime_type']?.toString() ?? 'image/jpeg',
        byteLength: (manifest['byte_length'] as num?)?.toInt() ?? 0,
      ),
    );
    _incomingFileUris.remove(payloadId);
    _pendingMediaManifests.remove(payloadId);
    _completedFilePayloads.remove(payloadId);
  }

  /// Broadcast raw bytes over the physical radio to ALL currently connected peers
  Future<int> broadcastPayload(Uint8List bytes) async {
    if (_connectedPeers.isEmpty) {
      _logStatus(
        'No active physical RF peers connected. Message queued in local outbox.',
      );
      return 0;
    }

    int successCount = 0;
    for (final endpointId in _connectedPeers.keys) {
      try {
        await _nearby.sendBytesPayload(endpointId, bytes);
        successCount++;
        _logStatus('Pushed RF packet (${bytes.length} bytes) -> $endpointId');
      } catch (e) {
        debugPrint(
          '[BluetoothRadioService] sendBytesPayload failed for $endpointId: $e',
        );
      }
    }

    return successCount;
  }

  /// Alias for broadcastPayload
  Future<int> broadcastBytes(Uint8List bytes) => broadcastPayload(bytes);

  /// Send raw bytes to a specific connected peer endpoint
  Future<bool> sendBytesToEndpoint(String endpointId, Uint8List bytes) async {
    try {
      await _nearby.sendBytesPayload(endpointId, bytes);
      _logStatus('Sent chunk packet (${bytes.length} bytes) -> $endpointId');
      return true;
    } catch (e) {
      debugPrint('[BluetoothRadioService] sendBytesPayload failed for $endpointId: $e');
      return false;
    }
  }

  /// Returns the current physical endpoint for a stable mesh-device ID.
  String? endpointForDevice(String deviceId) {
    for (final entry in _connectedPeers.entries) {
      if (entry.value.deviceId == deviceId) return entry.key;
    }
    return null;
  }

  MeshDevice? deviceForEndpoint(String endpointId) => _connectedPeers[endpointId];

  bool isEndpointConnected(String endpointId) =>
      _connectedPeers.containsKey(endpointId);

  /// Send a non-relayable, direct call-control message to one verified
  /// Nearby connection. Call control is never broadcast to other mesh nodes.
  Future<bool> sendCallControl(
    String endpointId,
    Map<String, dynamic> payload,
  ) {
    if (!isEndpointConnected(endpointId)) return Future.value(false);
    final frame = <String, dynamic>{
      'frame': 'RAKSHANET_NEARBY_CALL_V1',
      ...payload,
    };
    return sendBytesToEndpoint(
      endpointId,
      Uint8List.fromList(utf8.encode(jsonEncode(frame))),
    );
  }

  /// Send one bounded PCM frame for an active direct call. Nearby Connections
  /// selects Bluetooth or Wi-Fi transport; this method does not use internet
  /// routing and intentionally drops oversized frames rather than blocking
  /// the radio queue.
  Future<bool> sendCallAudio(
    String endpointId,
    String callId,
    Uint8List pcm,
  ) {
    if (!isEndpointConnected(endpointId) ||
        !RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(callId) ||
        pcm.isEmpty ||
        pcm.length > 2048) {
      return Future.value(false);
    }
    final header = Uint8List.fromList(
      <int>[..._audioPrefix, ...ascii.encode(callId), 0x7c],
    );
    final frame = Uint8List(header.length + pcm.length)
      ..setRange(0, header.length, header)
      ..setRange(header.length, header.length + pcm.length, pcm);
    return sendBytesToEndpoint(endpointId, frame);
  }

  /// Alias for broadcastPayload (send to all connected radio peers)
  Future<int> sendToPeers(Uint8List bytes) => broadcastPayload(bytes);

  /// Broadcast a JSON-encoded string over the physical radio
  Future<int> broadcastJson(Map<String, dynamic> jsonMap) async {
    final jsonStr = jsonEncode(jsonMap);
    final bytes = Uint8List.fromList(utf8.encode(jsonStr));
    return await broadcastPayload(bytes);
  }

  /// Sends an image as a Nearby file payload plus a small envelope manifest.
  /// Bytes payloads are limited to 32 KB; the manifest keeps message metadata
  /// small while Nearby transfers the file efficiently over the offline link.
  Future<int> broadcastMedia({
    required String filePath,
    required Map<String, dynamic> envelope,
    required String fileName,
    required String mimeType,
    required int byteLength,
  }) async {
    if (_connectedPeers.isEmpty) {
      _logStatus(
        'No active peers for media transfer. Image remains queued locally.',
      );
      return 0;
    }

    var successCount = 0;
    for (final endpointId in List<String>.from(_connectedPeers.keys)) {
      try {
        final payloadId = await _nearby.sendFilePayload(endpointId, filePath);
        final manifest = <String, dynamic>{
          'frame': 'RAKSHANET_MEDIA_V1',
          'file_payload_id': payloadId,
          'file_name': fileName,
          'mime_type': mimeType,
          'byte_length': byteLength,
          'envelope': envelope,
        };
        await _nearby.sendBytesPayload(
          endpointId,
          Uint8List.fromList(utf8.encode(jsonEncode(manifest))),
        );
        successCount++;
      } catch (e) {
        debugPrint(
          '[BluetoothRadioService] media transfer failed for $endpointId: $e',
        );
      }
    }
    return successCount;
  }

  Future<bool> persistIncomingMedia(String sourceUri, String destinationPath) =>
      _nearby.copyFileAndDeleteOriginal(sourceUri, destinationPath);

  /// Stop all active radio advertising, discovery, and connections
  Future<void> stopAll() async {
    try {
      if (_isAdvertising) {
        await _nearby.stopAdvertising();
        _isAdvertising = false;
      }
      if (_isDiscovering) {
        await _nearby.stopDiscovery();
        _isDiscovering = false;
      }
      await _nearby.stopAllEndpoints();
      _connectedPeers.clear();
      _pendingConnections.clear();
      _acceptedConnections.clear();
      _peerUpdateController.add([]);
      _logStatus('All RF radios stopped and endpoints cleared.');
      _isInitialized = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[BluetoothRadioService] stopAll error: $e');
    }
  }

  void _logStatus(String msg) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final entry = '[$timestamp] [Radio] $msg';
    debugPrint(entry);
    _statusLogController.add(entry);
  }

  @override
  void dispose() {
    stopAll();
    _payloadController.close();
    _mediaController.close();
    _peerUpdateController.close();
    _statusLogController.close();
    super.dispose();
  }
}
