import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../database/app_database.dart';
import '../models/chat_message.dart';
import '../models/emergency_report.dart';
import '../services/database_service.dart';
import '../services/device_identity_service.dart';
import '../services/location/location_service.dart';
import '../services/mesh_engine.dart';
import '../services/network/network_state_service.dart';
import '../services/sos_alert_service.dart';

/// Provider for managing local emergency SOS triggers and reactive UI state
class SosProvider extends ChangeNotifier {
  static final SosProvider instance = SosProvider._internal();
  factory SosProvider() => instance;

  SosProvider._internal() {
    SosAlertService.instance.activeAlertNotifier.addListener(_onAlertChanged);
    SosAlertService.instance.isSirenPlayingNotifier.addListener(_onSirenChanged);
    SosAlertService.instance.isMutedNotifier.addListener(_onMuteChanged);
  }

  bool _isSosActive = false;
  bool get isSosActive => _isSosActive;

  EmergencyAlertEvent? get activeAlert => SosAlertService.instance.currentAlert;
  bool get isSirenPlaying => SosAlertService.instance.isSirenPlaying;
  bool get isMuted => SosAlertService.instance.isMuted;

  void _onAlertChanged() {
    final alert = SosAlertService.instance.currentAlert;
    _isSosActive = alert != null && alert.isLocal;
    notifyListeners();
  }

  void _onSirenChanged() {
    notifyListeners();
  }

  void _onMuteChanged() {
    notifyListeners();
  }

  /// Triggers a full emergency SOS distress sequence.
  /// 1. 100% Offline-First: Commits SOS to local SQLite (emergency_reports, sos_events, messages).
  /// 2. Mesh Broadcast: Broadcasts packet over Bluetooth/RF mesh via MeshEngine.instance.broadcastSos().
  /// 3. Cloud Uplink on Network:
  ///    - If mobile network/internet available, posts immediately to /api/v1/telemetry/sync with GPS details.
  ///    - If offline, keeps queued in SQLite outbox; auto-recovery syncs once network is found.
  Future<void> triggerSos({
    String category = 'SOS',
    int peopleCount = 1,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? notes,
    String? messageId,
  }) async {
    _isSosActive = true;
    notifyListeners();

    // 0. Ensure audio siren and reactive alert are active
    SosAlertService.instance.triggerLocalAlert(
      category: category,
      peopleCount: peopleCount,
      lat: latitude,
      lng: longitude,
      notes: notes,
      messageId: messageId,
    );

    // Acquire GPS fix if missing with multi-tier fallback
    DeviceLocationFix? fix = LocationService.instance.currentLocation ??
        LocationService.instance.currentFix ??
        LocationService.instance.lastKnownPosition;
    double? lat = latitude ?? fix?.latitude;
    double? lng = longitude ?? fix?.longitude;
    double? acc = accuracy ?? fix?.horizontalAccuracyMeters;
    if (lat == null || lng == null) {
      try {
        fix = await LocationService.instance
            .refreshLocation(forceFresh: true)
            .timeout(const Duration(milliseconds: 2000), onTimeout: () => null);
        lat ??= fix?.latitude;
        lng ??= fix?.longitude;
        acc ??= fix?.horizontalAccuracyMeters;
      } catch (_) {}
    }
    if (lat == null || lng == null) {
      try {
        final recentLocs = await AppDatabase.instance.query(
          'location_history',
          orderBy: 'timestamp DESC',
          limit: 1,
        );
        if (recentLocs.isNotEmpty) {
          lat = (recentLocs.first['latitude'] as num?)?.toDouble();
          lng = (recentLocs.first['longitude'] as num?)?.toDouble();
          acc = (recentLocs.first['horizontal_accuracy'] as num?)?.toDouble() ?? 30.0;
        }
      } catch (_) {}
    }
    if (lat == null || lng == null) {
      try {
        final recentSos = await AppDatabase.instance.query(
          'sos_events',
          where: 'latitude IS NOT NULL AND longitude IS NOT NULL',
          orderBy: 'created_at DESC',
          limit: 1,
        );
        if (recentSos.isNotEmpty) {
          lat = (recentSos.first['latitude'] as num?)?.toDouble();
          lng = (recentSos.first['longitude'] as num?)?.toDouble();
          acc = (recentSos.first['location_accuracy'] as num?)?.toDouble() ?? 50.0;
        }
      } catch (_) {}
    }

    final id = messageId ?? 'SOS-${DateTime.now().millisecondsSinceEpoch}';
    final myDeviceId = DeviceIdentityService.instance.deviceId;
    final myDisplayName = DeviceIdentityService.instance.displayName;
    final now = DateTime.now();

    // 1. First: commit SOS to local SQLite emergency_reports and sos_events (100% offline-first)
    final report = EmergencyReport.create(
      id: id,
      category: category,
      peopleCount: peopleCount,
      notes: notes ?? 'Emergency SOS Distress Beacon',
      latitude: lat,
      longitude: lng,
      location: lat != null && lng != null ? '$lat, $lng' : 'Location unavailable',
      status: 'QUEUED',
      timestamp: now,
      syncPending: true,
      severity: 'CRITICAL',
      senderDeviceId: myDeviceId,
      isLocal: true,
    );

    try {
      await AppDatabase.instance.saveEmergencyReport(report);
      await AppDatabase.instance.insert('sos_events', {
        'id': id,
        'message_id': id,
        'sender_device_id': myDeviceId,
        'sender_name': myDisplayName,
        'latitude': lat,
        'longitude': lng,
        'category': category,
        'people_count': peopleCount,
        'notes': notes,
        'location_accuracy': acc,
        'location_source': fix?.source ?? 'LIVE_GPS',
        'location_is_stale': fix?.isStale == true ? 1 : 0,
        'urgency': 'CRITICAL',
        'status': 'QUEUED',
        'synced_to_server': 0,
        'created_at': now.millisecondsSinceEpoch,
      });

      if (lat != null && lng != null) {
        await AppDatabase.instance.insert('location_history', {
          'id': 'LOC-$id',
          'message_id': id,
          'device_id': myDeviceId,
          'latitude': lat,
          'longitude': lng,
          'horizontal_accuracy': acc,
          'timestamp': now.millisecondsSinceEpoch,
          'source': fix?.source ?? 'LIVE_GPS',
          'status': 'QUEUED',
          'synced_to_server': 0,
          'is_live': 1,
          'is_stale': 0,
        });
      }

      // Also persist to chat messages so it appears in outbox UI
      final chatMessage = ChatMessage(
        messageId: id,
        conversationId: 'CONV_COMMUNITY',
        senderId: myDeviceId,
        senderName: myDisplayName,
        content:
            'SOS: $category. People needing help: $peopleCount.${notes != null && notes.isNotEmpty ? " Notes: $notes" : ""}',
        timestamp: now,
        status: MessageDeliveryStatus.queued,
        messageType: 'SOS',
        category: category,
        recipientTarget: 'BROADCAST',
        latitude: lat,
        longitude: lng,
      );
      await DatabaseService().insertMessage(chatMessage.toDbMap());
    } catch (e) {
      debugPrint('[SosProvider] Error committing offline SOS to SQLite: $e');
    }

    // 2. Second: broadcast emergency SOS packet over BLE/RF mesh via MeshEngine.instance.broadcastSos()
    try {
      await MeshEngine.instance.broadcastSos(
        messageId: id,
        category: category,
        peopleCount: peopleCount,
        latitude: lat,
        longitude: lng,
        accuracy: acc,
        notes: notes,
        report: report,
      );
    } catch (e) {
      debugPrint('[SosProvider] Error broadcasting SOS over mesh: $e');
    }

    // 3. Third: Cloud Uplink on Network:
    // Check if mobile network/internet is available.
    final bool isOnline = NetworkStateService.instance.isInternetAvailable;

    if (isOnline) {
      try {
        final packet = <String, dynamic>{
          'ver': 1,
          'msg_id': id,
          'message_id': id,
          'sender_id': myDeviceId,
          'sender_name': myDisplayName,
          'conv_id': 'CONV_COMMUNITY',
          'ts': now.millisecondsSinceEpoch,
          'ttl': 5,
          'hops': 0,
          'type': 'SOS',
          'payload': jsonEncode({
            'category': category,
            'people_count': peopleCount,
            'notes': notes,
          }),
          'meta': {
            'urgency': 'CRITICAL',
            'category': category,
            'peopleCount': peopleCount,
            'synced_via': 'immediate_sos_uplink',
          },
        };

        if (lat != null && lng != null) {
          packet['location'] = {
            'lat': lat,
            'lng': lng,
            'accuracy': ?acc,
            'fix_type': fix?.source ?? 'LIVE_GPS',
          };
        }

        final syncBatch = {
          'device_id': myDeviceId,
          'sync_timestamp': now.millisecondsSinceEpoch,
          if (lat != null && lng != null) ...{
            'lat': lat,
            'lng': lng,
            'accuracy': ?acc,
          },
          'packets': [packet],
        };

        final syncUri = Uri.parse(
          '${AppConfig.backendBaseUrl}/api/v1/telemetry/sync',
        );
        final response = await http
            .post(
              syncUri,
              headers: {
                'Content-Type': 'application/json',
                'X-Idempotency-Key': id,
              },
              body: jsonEncode(syncBatch),
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          await AppDatabase.instance.update(
            'emergency_reports',
            {'status': 'SYNCED'},
            where: 'id = ?',
            whereArgs: [id],
          );
          await AppDatabase.instance.update(
            'sos_events',
            {'status': 'syncedToServer', 'synced_to_server': 1},
            where: 'message_id = ? OR id = ?',
            whereArgs: [id, id],
          );
          await AppDatabase.instance.update(
            'encrypted_mesh_packets',
            {'status': 'syncedToServer'},
            where: 'message_id = ?',
            whereArgs: [id],
          );
          await DatabaseService().updateMessageStatus(
            messageId: id,
            status: 'SYNCED',
          );
          MeshEngine.instance.notifyPacketSynced(id);
          debugPrint(
            '[SosProvider] Immediate SOS cloud uplink succeeded for $id',
          );
        }
      } catch (e) {
        debugPrint(
          '[SosProvider] Immediate SOS upload exception (remains queued in SQLite outbox): $e',
        );
      }
    } else {
      debugPrint(
        '[SosProvider] Offline: SOS $id queued in SQLite outbox. NetworkStateService will auto-sync when network returns.',
      );
    }
  }

  /// Triggers a quick single-action SOS beacon
  Future<void> triggerQuickSos({
    String category = 'SOS',
    double? latitude,
    double? longitude,
    double? accuracy,
  }) async {
    await triggerSos(
      category: category,
      peopleCount: 1,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      notes: 'Quick SOS distress beacon triggered',
    );
  }

  /// Initiates a local SOS distress broadcast from this device
  void triggerLocalSos({
    required String category,
    int peopleCount = 1,
    double? latitude,
    double? longitude,
    String? notes,
    String? messageId,
  }) {
    unawaited(
      triggerSos(
        category: category,
        peopleCount: peopleCount,
        latitude: latitude,
        longitude: longitude,
        notes: notes,
        messageId: messageId,
      ),
    );
  }

  /// Cancels or disarms the active local distress beacon
  void cancelLocalSos() {
    _isSosActive = false;
    SosAlertService.instance.dismissAlert();
    notifyListeners();
  }

  /// Mutes audio siren without dismissing the emergency banner
  void muteSiren() {
    SosAlertService.instance.muteSiren();
    notifyListeners();
  }

  /// Unmutes audio siren
  void unmuteSiren() {
    SosAlertService.instance.unmuteSiren();
    notifyListeners();
  }

  @override
  void dispose() {
    SosAlertService.instance.activeAlertNotifier.removeListener(_onAlertChanged);
    SosAlertService.instance.isSirenPlayingNotifier.removeListener(
      _onSirenChanged,
    );
    SosAlertService.instance.isMutedNotifier.removeListener(_onMuteChanged);
    super.dispose();
  }
}
