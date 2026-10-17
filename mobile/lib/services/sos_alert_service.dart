import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:latlong2/latlong.dart';

import '../models/message_envelope.dart';
import 'database_service.dart';
import 'map/offline_map_service.dart';
import 'mesh_engine.dart';

/// Represents an active or historical SOS emergency alert event
class EmergencyAlertEvent {
  final String messageId;
  final String senderDeviceId;
  final String senderName;
  final double? lat;
  final double? lng;
  final String urgency;
  final DateTime timestamp;
  final String? medicalNotes;
  final int casualties;
  final String category;
  final bool isLocal;
  final Map<String, dynamic>? rawMetadata;

  const EmergencyAlertEvent({
    required this.messageId,
    required this.senderDeviceId,
    required this.senderName,
    this.lat,
    this.lng,
    this.urgency = 'CRITICAL',
    required this.timestamp,
    this.medicalNotes,
    this.casualties = 1,
    this.category = 'Emergency SOS',
    this.isLocal = false,
    this.rawMetadata,
  });

  /// Formatted coordinates e.g. "13.045° N, 80.230° E"
  String get formattedCoordinates {
    if (lat == null || lng == null) {
      return 'Location Coordinates Unavailable';
    }
    final latDir = lat! >= 0 ? 'N' : 'S';
    final lngDir = lng! >= 0 ? 'E' : 'W';
    return '${lat!.abs().toStringAsFixed(4)}° $latDir, ${lng!.abs().toStringAsFixed(4)}° $lngDir';
  }

  /// Compact formatted sender identity e.g. "Priya Sharma • SR-9A1C"
  String get formattedSender {
    if (isLocal) {
      return 'You (This Device)';
    }
    final cleanDevice = senderDeviceId.replaceAll('DEVICE-', '').replaceAll('NODE-', '');
    final shortId = cleanDevice.length > 6 ? cleanDevice.substring(0, 6).toUpperCase() : cleanDevice.toUpperCase();
    if (senderName.trim().isNotEmpty && senderName != senderDeviceId) {
      return '$senderName • SR-$shortId';
    }
    return 'SR-$shortId';
  }

  /// Human-friendly relative timestamp
  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 15) return 'Just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// Calculates human-readable distance from user's current coordinates
  String formatDistanceFrom(double? userLat, double? userLng) {
    if (userLat == null || userLng == null || lat == null || lng == null) {
      return 'Distance unknown';
    }
    final distMeters = OfflineMapService.distanceMeters(
      LatLng(userLat, userLng),
      LatLng(lat!, lng!),
    );
    return OfflineMapService.formatDistance(distMeters);
  }
}

/// Global SOS Alert, Siren Sound & Emergency Notification Service
///
/// Features:
/// 1. Singleton pattern `SosAlertService.instance`
/// 2. Reactive streams and ValueNotifiers for UI overlay integration
/// 3. Emergency Siren playback via `audioplayers` with automatic fallback
///    to `SystemSound.play(SystemSoundType.alert)` and continuous rhythmic haptics
/// 4. Auto-mute safety timer after 60 seconds (prevents indefinite blaring)
/// 5. Mesh delivery acknowledgement dispatch upon response
class SosAlertService {
  static final SosAlertService instance = SosAlertService._internal();
  factory SosAlertService() => instance;
  SosAlertService._internal();

  // Reactive state notifiers
  final ValueNotifier<EmergencyAlertEvent?> activeAlertNotifier =
      ValueNotifier<EmergencyAlertEvent?>(null);
  final ValueNotifier<bool> isSirenPlayingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isMutedNotifier = ValueNotifier<bool>(false);

  // Stream controller for subscribers
  final StreamController<EmergencyAlertEvent> _alertStreamController =
      StreamController<EmergencyAlertEvent>.broadcast();
  Stream<EmergencyAlertEvent> get alertStream => _alertStreamController.stream;

  // Alert history log
  final List<EmergencyAlertEvent> _alertHistory = [];
  List<EmergencyAlertEvent> get alertHistory => List.unmodifiable(_alertHistory);

  EmergencyAlertEvent? get currentAlert => activeAlertNotifier.value;
  bool get isSirenPlaying => isSirenPlayingNotifier.value;
  bool get isMuted => isMutedNotifier.value;

  // Audio and vibration managers
  AudioPlayer? _audioPlayer;
  Timer? _vibrationTimer;
  Timer? _autoMuteTimer;
  bool _audioPlayerInitialized = false;

  /// Initializes the AudioPlayer with emergency loop configuration
  Future<void> _ensureAudioPlayer() async {
    if (_audioPlayerInitialized && _audioPlayer != null) return;
    try {
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer!.setVolume(1.0);
      _audioPlayerInitialized = true;
    } catch (e) {
      debugPrint('[SosAlertService] AudioPlayer initialization notice: $e');
    }
  }

  /// Triggers an incoming SOS alert received via MeshEngine packet
  void triggerIncomingAlert(MessageEnvelope envelope) {
    final metadata = envelope.metadata ?? const <String, dynamic>{};
    final lat = _toDouble(metadata['latitude']) ?? _toDouble(metadata['lat']);
    final lng = _toDouble(metadata['longitude']) ?? _toDouble(metadata['lng']);
    final casualties = _toInt(metadata['peopleCount']) ?? _toInt(metadata['casualties']) ?? 1;
    final category = metadata['category']?.toString() ?? 'Emergency SOS';
    final notes = envelope.payload.trim().isNotEmpty ? envelope.payload.trim() : null;
    final urgency = metadata['urgency']?.toString().toUpperCase() ?? 'CRITICAL';

    final event = EmergencyAlertEvent(
      messageId: envelope.uuid,
      senderDeviceId: envelope.senderId,
      senderName: envelope.senderName.trim().isNotEmpty
          ? envelope.senderName
          : envelope.senderId,
      lat: lat,
      lng: lng,
      urgency: urgency,
      timestamp: DateTime.fromMillisecondsSinceEpoch(envelope.timestamp),
      medicalNotes: notes,
      casualties: casualties,
      category: category,
      isLocal: false,
      rawMetadata: metadata,
    );

    _publishAlert(event);
  }

  /// Triggers a local SOS alert initiated by the user on this phone
  void triggerLocalAlert({
    required String category,
    int peopleCount = 1,
    double? lat,
    double? lng,
    String? notes,
    String? messageId,
  }) {
    final event = EmergencyAlertEvent(
      messageId: messageId ?? 'SOS-LOCAL-${DateTime.now().millisecondsSinceEpoch}',
      senderDeviceId: DatabaseService.myDeviceId,
      senderName: DatabaseService.myDisplayName,
      lat: lat,
      lng: lng,
      urgency: 'CRITICAL',
      timestamp: DateTime.now(),
      medicalNotes: notes,
      casualties: peopleCount,
      category: category,
      isLocal: true,
    );

    _publishAlert(event);
  }

  void _publishAlert(EmergencyAlertEvent event) {
    activeAlertNotifier.value = event;
    _alertHistory.insert(0, event);
    _alertStreamController.add(event);

    // Play high-visibility siren alarm and rhythmic vibration
    playSiren();
  }

  /// Plays the emergency alarm siren sound & continuous rhythmic vibration
  Future<void> playSiren() async {
    isMutedNotifier.value = false;
    isSirenPlayingNotifier.value = true;

    // 1. Play siren sound with audioplayers or fallback to system alert sound
    try {
      await _ensureAudioPlayer();
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
        await _audioPlayer!.play(AssetSource('audio/emergency_siren.wav'));
      } else {
        await SystemSound.play(SystemSoundType.alert);
      }
    } catch (e) {
      debugPrint('[SosAlertService] Audio playback notice (using fallback): $e');
      await SystemSound.play(SystemSoundType.alert);
    }

    // 2. Start continuous emergency vibration cadence (cadence: 2 heavy pulses every 800ms)
    _startVibrationSequence();

    // 3. Safety auto-mute after 60 seconds to conserve battery in prolonged emergencies
    _autoMuteTimer?.cancel();
    _autoMuteTimer = Timer(const Duration(seconds: 60), () {
      if (isSirenPlaying) {
        debugPrint('[SosAlertService] 60s auto-mute safety triggered');
        muteSiren();
      }
    });
  }

  /// Continuous rhythmic emergency vibration
  void _startVibrationSequence() {
    _vibrationTimer?.cancel();
    HapticFeedback.heavyImpact();

    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) async {
      if (!isSirenPlayingNotifier.value) {
        timer.cancel();
        return;
      }
      try {
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 120));
        await HapticFeedback.heavyImpact();
      } catch (_) {}
    });
  }

  /// Mutes audio and vibration without dismissing the alert overlay banner
  Future<void> muteSiren() async {
    isMutedNotifier.value = true;
    isSirenPlayingNotifier.value = false;
    _autoMuteTimer?.cancel();
    _vibrationTimer?.cancel();

    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
      }
    } catch (_) {}
  }

  /// Un-mutes and resumes the siren alarm sound
  Future<void> unmuteSiren() async {
    if (activeAlertNotifier.value != null) {
      await playSiren();
    }
  }

  /// Acknowledges the emergency distress call, dispatches a mesh delivery ACK,
  /// stops the siren, and dismisses the alert
  Future<void> acknowledgeAndRespond(EmergencyAlertEvent alert) async {
    await muteSiren();
    activeAlertNotifier.value = null;

    if (!alert.isLocal && alert.senderDeviceId.isNotEmpty) {
      try {
        await MeshEngine().sendSosResponseAck(
          sosMessageId: alert.messageId,
          targetDeviceId: alert.senderDeviceId,
          note: 'Distress acknowledged by responder. Stay calm, help is on the way.',
        );
      } catch (e) {
        debugPrint('[SosAlertService] Error sending mesh ACK response: $e');
      }
    }
  }

  /// Dismisses the alert overlay and silences the siren
  Future<void> dismissAlert() async {
    await muteSiren();
    activeAlertNotifier.value = null;
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  int? _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  void dispose() {
    _autoMuteTimer?.cancel();
    _vibrationTimer?.cancel();
    _audioPlayer?.dispose();
    _alertStreamController.close();
  }
}
