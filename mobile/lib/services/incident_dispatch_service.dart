import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../models/chat_message.dart';
import '../models/emergency_report.dart';
import '../models/user_profile.dart';
import 'chat_service.dart';
import 'crypto/crypto_service.dart';
import 'device_identity_service.dart';
import 'location/location_service.dart';
import 'platform_telemetry_service.dart';

/// Result of an SOS submission. It deliberately describes what was persisted
/// and queued, rather than promising that a peer or cloud gateway received it.
class IncidentDispatchResult {
  const IncidentDispatchResult({
    required this.report,
    required this.senderName,
    required this.deviceId,
    required this.identifierKind,
    required this.locationFix,
    required this.wasQueuedForMesh,
  });

  final EmergencyReport report;
  final String? senderName;
  final String deviceId;
  final String identifierKind;
  final DeviceLocationFix? locationFix;
  final bool wasQueuedForMesh;
}

/// Creates the single durable SOS record used by every emergency entry point.
///
/// The sender's device writes the incident, upload event and optional own
/// location breadcrumb before asking the mesh outbox to transmit it. A relay
/// merely carries this record; it must never manufacture a location for a
/// different phone.
class IncidentDispatchService {
  IncidentDispatchService({
    AppDatabase? database,
    ChatService? chatService,
    PlatformTelemetryService? telemetry,
    LocationService? locationService,
    DeviceIdentityService? identity,
    CryptoService? crypto,
    Uuid? uuid,
  }) : _database = database ?? AppDatabase.instance,
       _chatService = chatService ?? ChatService(),
       _telemetry = telemetry ?? PlatformTelemetryService(),
       _locationService = locationService ?? LocationService.instance,
       _identity = identity ?? DeviceIdentityService.instance,
       _crypto = crypto ?? CryptoService.instance,
       _uuid = uuid ?? const Uuid();

  final AppDatabase _database;
  final ChatService _chatService;
  final PlatformTelemetryService _telemetry;
  final LocationService _locationService;
  final DeviceIdentityService _identity;
  final CryptoService _crypto;
  final Uuid _uuid;

  Future<IncidentDispatchResult> dispatchSos({
    required String category,
    required int peopleCount,
    String? notes,
    DeviceLocationFix? initialFix,
    double? latitude,
    double? longitude,
    double? accuracy,
  }) async {
    final cleanedCategory = category.trim().isEmpty ? 'Other' : category.trim();
    final normalizedPeopleCount = peopleCount < 1 ? 1 : peopleCount;
    final cleanedNotes = notes?.trim() ?? '';
    final now = DateTime.now();

    await _identity.initialize();

    // Acquire or fallback location fix using multi-tier hierarchy
    DeviceLocationFix? fix = initialFix;
    if (fix == null && latitude != null && longitude != null) {
      fix = DeviceLocationFix.create(
        latitude: latitude,
        longitude: longitude,
        horizontalAccuracyMeters: accuracy ?? 15.0,
        timestamp: now.millisecondsSinceEpoch,
        source: LocationFixSource.fusedGps,
      );
    }

    try {
      final permStatus = await Permission.location.status;
      if (!permStatus.isGranted && !permStatus.isLimited) {
        await Permission.location.request();
      }
    } catch (_) {}

    await _locationService.initialize();

    // 1. Current fix from location service
    fix ??= _locationService.currentLocation ??
        _locationService.currentFix ??
        _locationService.lastKnownPosition;

    // 2. Proactive refresh with fast timeout
    if (fix == null) {
      try {
        fix = await _locationService
            .refreshLocation(forceFresh: true)
            .timeout(const Duration(milliseconds: 2000), onTimeout: () => null);
      } catch (_) {}
    }

    // 3. Fallback to location service getters
    fix ??= _locationService.currentLocation ??
        _locationService.currentFix ??
        _locationService.lastKnownPosition;

    // 4. Fallback to persisted location_history table in SQLite
    if (fix == null) {
      try {
        final recentLocs = await _database.query(
          'location_history',
          orderBy: 'timestamp DESC',
          limit: 1,
        );
        if (recentLocs.isNotEmpty) {
          final r = recentLocs.first;
          final lat = (r['latitude'] as num?)?.toDouble();
          final lng = (r['longitude'] as num?)?.toDouble();
          if (lat != null && lng != null) {
            fix = DeviceLocationFix.create(
              latitude: lat,
              longitude: lng,
              horizontalAccuracyMeters:
                  (r['horizontal_accuracy'] as num?)?.toDouble() ?? 30.0,
              timestamp: r['timestamp'] as int? ?? now.millisecondsSinceEpoch,
              source: LocationFixSource.lastKnown,
            );
          }
        }
      } catch (_) {}
    }

    // 5. Fallback to previous SOS events in SQLite
    if (fix == null) {
      try {
        final recentSos = await _database.query(
          'sos_events',
          where: 'latitude IS NOT NULL AND longitude IS NOT NULL',
          orderBy: 'created_at DESC',
          limit: 1,
        );
        if (recentSos.isNotEmpty) {
          final r = recentSos.first;
          final lat = (r['latitude'] as num?)?.toDouble();
          final lng = (r['longitude'] as num?)?.toDouble();
          if (lat != null && lng != null) {
            fix = DeviceLocationFix.create(
              latitude: lat,
              longitude: lng,
              horizontalAccuracyMeters:
                  (r['location_accuracy'] as num?)?.toDouble() ?? 50.0,
              timestamp: r['created_at'] as int? ?? now.millisecondsSinceEpoch,
              source: LocationFixSource.lastKnown,
            );
          }
        }
      } catch (_) {}
    }



    final telemetry = await _telemetry.getTelemetry();
    final profile = await _database.getUserProfile();
    final senderName = _resolveSenderName(profile, _identity.displayName);
    final deviceId = _identity.deviceId;
    final identifierKind = _identity.consentedImeiId == null
        ? 'app_device_id'
        : 'consented_device_identifier';
    final reportId = _uuid.v4();

    final report = EmergencyReport.create(
      id: reportId,
      category: cleanedCategory,
      peopleCount: normalizedPeopleCount,
      description: cleanedNotes,
      latitude: fix?.latitude,
      longitude: fix?.longitude,
      location: _locationDescription(fix),
      status: 'QUEUED',
      timestamp: now,
      syncPending: true,
      severity: 'CRITICAL',
    );

    // Save every durable local representation before any radio operation.
    await _database.saveEmergencyReport(report);
    await _database.insert('sos_events', {
      'id': reportId,
      'message_id': reportId,
      'sender_device_id': deviceId,
      'sender_name': senderName,
      'latitude': fix?.latitude,
      'longitude': fix?.longitude,
      'lat': fix?.latitude,
      'lng': fix?.longitude,
      'category': cleanedCategory,
      'people_count': normalizedPeopleCount,
      'notes': cleanedNotes.isEmpty ? null : cleanedNotes,
      'location_accuracy': fix?.horizontalAccuracyMeters,
      'location_source': fix?.source,
      'location_is_stale': fix?.isStale == true ? 1 : 0,
      'urgency': 'CRITICAL',
      'status': 'QUEUED',
      'synced_to_server': 0,
      'created_at': now.millisecondsSinceEpoch,
    });

    if (fix != null) {
      await _database.insert('location_history', {
        'id': 'LOC-$reportId',
        'message_id': reportId,
        'device_id': deviceId,
        'latitude': fix.latitude,
        'longitude': fix.longitude,
        'horizontal_accuracy': fix.horizontalAccuracyMeters,
        'altitude': fix.altitudeMeters,
        'speed': fix.speedMps,
        'bearing': fix.bearingDegrees,
        'timestamp': fix.timestamp,
        'source': fix.source,
        'status': 'QUEUED',
        'synced_to_server': 0,
        'is_live': fix.isLive ? 1 : 0,
        'is_stale': fix.isStale ? 1 : 0,
      });
    }

    try {
      await _crypto.initialize(deviceId: deviceId);
    } catch (_) {
      // A failed local key initialisation must not prevent a life-safety SOS.
      // The packet states exactly when no public key bundle is available.
    }

    final metadata = <String, dynamic>{
      'incident_schema': 'rakshanet_sos_v2',
      'category': cleanedCategory,
      'peopleCount': normalizedPeopleCount,
      'urgency': 'CRITICAL',
      'latitude': fix?.latitude,
      'longitude': fix?.longitude,
      'lat': fix?.latitude,
      'lng': fix?.longitude,
      'accuracy_m': fix?.horizontalAccuracyMeters,
      'location_timestamp': fix?.timestamp,
      'location_source': fix?.source,
      'location_is_stale': fix?.isStale ?? false,
      'battery_percent': telemetry.batteryLevel,
      'origin': {
        'device_id': deviceId,
        'identifier_kind': identifierKind,
        'display_name': senderName,
      },
      'crypto': _crypto.isInitialized
          ? {
              'exchange_public_key': _crypto.x25519PublicKeyBase64,
              'signing_public_key': _crypto.ed25519PublicKeyBase64,
              'encryption': 'recipient-key-required',
            }
          : {'encryption': 'unavailable'},
    };

    var queuedForMesh = false;
    try {
      final location = fix == null
          ? null
          : LocationPreview(
              title: 'Shared location',
              distance:
                  '${fix.formattedAccuracy} ${fix.isStale ? '(last known)' : '(current)'}',
              latitude: fix.latitude,
              longitude: fix.longitude,
            );
      await _chatService.sendMessage(
        messageId: reportId,
        senderName: senderName ?? '',
        content: _sosContent(
          category: cleanedCategory,
          peopleCount: normalizedPeopleCount,
          notes: cleanedNotes,
        ),
        conversationId: 'CONV_COMMUNITY',
        messageType: 'SOS',
        category: cleanedCategory,
        recipientTarget: 'BROADCAST',
        location: location,
        metadata: metadata,
      );
      queuedForMesh = true;
    } catch (_) {
      // The report and event records above remain in SQLite. The interface can
      // accurately say "saved locally" and retry during the next app session.
      await _database.update(
        'emergency_reports',
        {'status': 'SAVED'},
        where: 'id = ?',
        whereArgs: [reportId],
      );
      await _database.update(
        'sos_events',
        {'status': 'SAVED'},
        where: 'id = ?',
        whereArgs: [reportId],
      );
    }

    return IncidentDispatchResult(
      report: queuedForMesh ? report : _copyWithStatus(report, 'SAVED'),
      senderName: senderName,
      deviceId: deviceId,
      identifierKind: identifierKind,
      locationFix: fix,
      wasQueuedForMesh: queuedForMesh,
    );
  }

  static String? _resolveSenderName(UserProfile? profile, String fallbackName) {
    final profileName = profile?.name.trim() ?? '';
    if (profileName.isNotEmpty) return profileName;
    final deviceName = fallbackName.trim();
    if (deviceName.isNotEmpty && deviceName != 'RakshaNet user') {
      return deviceName;
    }
    return null;
  }

  static String _locationDescription(DeviceLocationFix? fix) {
    if (fix == null) return 'No location fix shared';
    final freshness = fix.isStale ? 'last known' : 'current';
    return '$freshness location (${fix.formattedAccuracy})';
  }

  static String _sosContent({
    required String category,
    required int peopleCount,
    required String notes,
  }) {
    final base = 'SOS: $category. People needing help: $peopleCount.';
    return notes.isEmpty ? base : '$base Notes: $notes';
  }

  static EmergencyReport _copyWithStatus(
    EmergencyReport report,
    String status,
  ) {
    return EmergencyReport.create(
      id: report.id,
      type: report.type,
      peopleCount: report.peopleCount,
      notes: report.notes,
      status: status,
      createdAt: report.createdAt,
      latitude: report.latitude,
      longitude: report.longitude,
      location: report.location,
      syncPending: true,
      severity: report.severity,
    );
  }
}
