import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../config/app_config.dart';
import '../database/repositories/missing_person_repository.dart';
import '../models/message_envelope.dart';
import '../models/missing_person.dart';
import '../services/device_identity_service.dart';
import '../services/mesh_engine.dart';
import '../services/network/network_state_service.dart';

/// State management and offline-first DTN mesh sync for Missing Persons
class MissingPersonsProvider extends ChangeNotifier {
  final MissingPersonRepository _repository;
  final MeshEngine _meshEngine;
  StreamSubscription? _meshSubscription;

  List<MissingPerson> _reports = [];
  List<MissingPerson> _photoSearchResults = [];
  bool _isPhotoSearchActive = false;
  String? _photoSearchQuery;
  bool _isLoading = false;
  String _selectedStatus = 'ALL';
  String _searchQuery = '';
  String? _errorMessage;

  List<MissingPerson> get reports => _isPhotoSearchActive
      ? List.unmodifiable(_photoSearchResults)
      : List.unmodifiable(_reports);
  List<MissingPerson> get photoSearchResults => List.unmodifiable(_photoSearchResults);
  bool get isPhotoSearchActive => _isPhotoSearchActive;
  String? get photoSearchQuery => _photoSearchQuery;
  bool get isLoading => _isLoading;
  String get selectedStatus => _selectedStatus;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;

  int get totalCount => reports.length;
  int get activeMissingCount =>
      reports.where((r) => r.status.toUpperCase() != 'FOUND').length;
  int get foundCount =>
      reports.where((r) => r.status.toUpperCase() == 'FOUND').length;

  MissingPersonsProvider({
    MissingPersonRepository? repository,
    MeshEngine? meshEngine,
  })  : _repository = repository ?? MissingPersonRepository(),
        _meshEngine = meshEngine ?? MeshEngine() {
    _init();
  }

  void _init() {
    loadReports();

    // Listen to real-time incoming mesh packets (peer-to-peer radio deliveries)
    _meshSubscription = _meshEngine.incomingEnvelopes.listen((envelope) {
      if (envelope.type == 'MISSING_PERSON' ||
          envelope.type == 'MISSING_PERSON_SIGHTING') {
        debugPrint('[MissingPersonsProvider] Incoming mesh bulletin received: ${envelope.uuid}');
        loadReports(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _meshSubscription?.cancel();
    super.dispose();
  }

  String _getGatewayBaseUrl() {
    return AppConfig.backendUrl;
  }

  /// Sets status filter ('ALL', 'MISSING', 'FOUND')
  void setStatusFilter(String status) {
    _selectedStatus = status.toUpperCase();
    loadReports();
  }

  /// Sets text search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    loadReports();
  }

  /// Searches missing person bulletins by photo reference, file path, URL, or image content
  Future<List<MissingPerson>> searchByPhoto({
    String? photoPath,
    String? photoUrl,
    String? base64Data,
    Uint8List? imageBytes,
  }) async {
    _isLoading = true;
    _isPhotoSearchActive = true;
    notifyListeners();

    try {
      final query = (photoPath ??
              photoUrl ??
              base64Data ??
              (imageBytes != null ? base64Encode(imageBytes) : ''))
          .trim();
      _photoSearchQuery = query;

      if (query.isEmpty) {
        // Return all registered individuals with an attached photo
        _photoSearchResults = _reports.where((r) {
          final pPath = r.photoPath?.trim() ?? '';
          final pUrl = r.photoUrl?.trim() ?? '';
          return pPath.isNotEmpty || pUrl.isNotEmpty;
        }).toList();
      } else {
        _photoSearchResults = _reports.where((r) {
          final pPath = r.photoPath?.trim() ?? '';
          final pUrl = r.photoUrl?.trim() ?? '';

          if (pPath == query || pUrl == query) return true;

          // Check filename matching (e.g., photo_123.jpg)
          final qName = query.split(RegExp(r'[/\\]')).last;
          if (qName.isNotEmpty) {
            final pName1 = pPath.split(RegExp(r'[/\\]')).last;
            final pName2 = pUrl.split(RegExp(r'[/\\]')).last;
            if (pName1 == qName || pName2 == qName) return true;
          }

          // Check base64 content matching
          if (query.length > 20) {
            final qPayload =
                query.contains(',') ? query.split(',').last.trim() : query;
            final pathPayload =
                pPath.contains(',') ? pPath.split(',').last.trim() : pPath;
            final urlPayload =
                pUrl.contains(',') ? pUrl.split(',').last.trim() : pUrl;
            if ((pathPayload.isNotEmpty && pathPayload == qPayload) ||
                (urlPayload.isNotEmpty && urlPayload == qPayload)) {
              return true;
            }
          }

          return false;
        }).toList();
      }

      return _photoSearchResults;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears active photo search filter and restores regular reports view
  void clearPhotoSearch() {
    _isPhotoSearchActive = false;
    _photoSearchResults.clear();
    _photoSearchQuery = null;
    notifyListeners();
  }

  /// Visual Recognition: Search for a found individual by photo
  /// Checks network availability (`NetworkStateService.instance.isInternetAvailable`).
  /// If online: posts multipart/form-data to cloud gateway search endpoint.
  /// If offline: buffers query into SQLite `mesh_photo_queries` & `encrypted_mesh_packets`
  /// with IMEI, GPS coordinates, timestamp, and photo path; performs local comparison against cache.
  Future<Map<String, dynamic>> searchFoundPersonByPhoto(
    File photoFile, {
    double? lat,
    double? lng,
  }) async {
    final bool isOnline = NetworkStateService.instance.isInternetAvailable;

    if (isOnline) {
      try {
        final uri = Uri.parse(
          '${AppConfig.backendBaseUrl}/api/v1/missing-persons/search-by-photo',
        );
        final request = http.MultipartRequest('POST', uri);
        request.files.add(
          await http.MultipartFile.fromPath('photo', photoFile.path),
        );
        if (lat != null) request.fields['lat'] = lat.toString();
        if (lng != null) request.fields['lng'] = lng.toString();
        request.fields['device_id'] = DeviceIdentityService.instance.deviceId;

        final streamed = await request.send().timeout(const Duration(seconds: 12));
        final response = await http.Response.fromStream(streamed);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final dynamic decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            final bool matchFound = decoded['match_found'] == true;
            final dynamic rawMatches = decoded['matches'];
            final List<dynamic> matches = rawMatches is List ? rawMatches : [];
            final dynamic topMatch = decoded['top_match'] ?? (matches.isNotEmpty ? matches.first : null);

            final localReports = _reports.isNotEmpty ? _reports : await _repository.getMissingPersons();

            // Enrich all matches with local photoPath and standardized full photoUrl
            final List<Map<String, dynamic>> enrichedMatches = [];
            for (final m in matches) {
              if (m is Map<String, dynamic>) {
                final enriched = Map<String, dynamic>.from(m);
                final pid = (enriched['person_id'] ?? enriched['id'])?.toString();
                final pname = enriched['name']?.toString();
                final localMatch = localReports.cast<MissingPerson?>().firstWhere(
                  (r) => (pid != null && pid.isNotEmpty && r?.id == pid) ||
                         (pname != null && pname.isNotEmpty && r?.name.toLowerCase() == pname.toLowerCase()),
                  orElse: () => null,
                );
                if (localMatch != null) {
                  if ((enriched['photo_path'] == null || enriched['photo_path'].toString().isEmpty) && localMatch.photoPath != null) {
                    enriched['photo_path'] = localMatch.photoPath;
                  }
                  if ((enriched['photo_url'] == null || enriched['photo_url'].toString().isEmpty) && localMatch.photoUrl != null) {
                    enriched['photo_url'] = localMatch.photoUrl;
                  }
                }
                final pUrl = enriched['photo_url']?.toString();
                if (pUrl != null && pUrl.startsWith('/')) {
                  enriched['photo_url'] = '${AppConfig.backendBaseUrl}$pUrl';
                } else if ((pUrl == null || pUrl.isEmpty) && pid != null && pid.isNotEmpty) {
                  enriched['photo_url'] = '${AppConfig.backendBaseUrl}/api/v1/missing-persons/$pid/photo';
                }
                enrichedMatches.add(enriched);
              }
            }

            Map<String, dynamic>? enrichedTopMatch;
            if (topMatch is Map<String, dynamic>) {
              enrichedTopMatch = Map<String, dynamic>.from(topMatch);
              final pid = (enrichedTopMatch['person_id'] ?? enrichedTopMatch['id'])?.toString();
              final pname = enrichedTopMatch['name']?.toString();
              final localMatch = localReports.cast<MissingPerson?>().firstWhere(
                (r) => (pid != null && pid.isNotEmpty && r?.id == pid) ||
                       (pname != null && pname.isNotEmpty && r?.name.toLowerCase() == pname.toLowerCase()),
                orElse: () => null,
              );
              if (localMatch != null) {
                if ((enrichedTopMatch['photo_path'] == null || enrichedTopMatch['photo_path'].toString().isEmpty) && localMatch.photoPath != null) {
                  enrichedTopMatch['photo_path'] = localMatch.photoPath;
                }
                if ((enrichedTopMatch['photo_url'] == null || enrichedTopMatch['photo_url'].toString().isEmpty) && localMatch.photoUrl != null) {
                  enrichedTopMatch['photo_url'] = localMatch.photoUrl;
                }
              }
              final pUrl = enrichedTopMatch['photo_url']?.toString();
              if (pUrl != null && pUrl.startsWith('/')) {
                enrichedTopMatch['photo_url'] = '${AppConfig.backendBaseUrl}$pUrl';
              } else if ((pUrl == null || pUrl.isEmpty) && pid != null && pid.isNotEmpty) {
                enrichedTopMatch['photo_url'] = '${AppConfig.backendBaseUrl}/api/v1/missing-persons/$pid/photo';
              }
            }

            return {
              'offline': false,
              'queued_for_mesh': false,
              'match_found': matchFound,
              'matches': enrichedMatches.isNotEmpty ? enrichedMatches : matches,
              'top_match': enrichedTopMatch ?? topMatch,
              ...decoded,
            };
          }
        }
      } catch (e) {
        debugPrint(
          '[MissingPersonsProvider] Online photo match failed ($e), falling back to offline DTN buffer.',
        );
      }
    }

    // Offline workflow
    return await _bufferOfflinePhotoSearch(photoFile, lat: lat, lng: lng);
  }

  Future<Map<String, dynamic>> _bufferOfflinePhotoSearch(
    File photoFile, {
    double? lat,
    double? lng,
  }) async {
    final now = DateTime.now();
    final deviceId = DeviceIdentityService.instance.deviceId;
    final queryId = 'mpq_${now.millisecondsSinceEpoch}_${deviceId.substring(0, deviceId.length > 4 ? 4 : deviceId.length)}';

    // 1. Buffer the search query into SQLite table mesh_photo_queries
    final queryData = {
      'id': queryId,
      'device_id': deviceId,
      'photo_path': photoFile.path,
      'latitude': lat,
      'longitude': lng,
      'timestamp': now.millisecondsSinceEpoch,
      'status': 'QUEUED',
      'payload_json': jsonEncode({
        'query_id': queryId,
        'device_id': deviceId,
        'photo_path': photoFile.path,
        'lat': lat,
        'lng': lng,
        'timestamp': now.toIso8601String(),
      }),
    };

    try {
      await _repository.savePhotoQuery(queryData);
    } catch (e) {
      debugPrint('[MissingPersonsProvider] Error saving mesh photo query: $e');
    }

    // 2. Buffer into encrypted_mesh_packets with type FOUND_PERSON_PHOTO_QUERY
    final envelope = MessageEnvelope(
      uuid: queryId,
      senderId: deviceId,
      senderName: DeviceIdentityService.instance.displayName,
      conversationId: 'CONV_COMMUNITY',
      timestamp: now.millisecondsSinceEpoch,
      ttl: 7,
      hops: 0,
      type: 'FOUND_PERSON_PHOTO_QUERY',
      payload: jsonEncode({
        'query_id': queryId,
        'device_id': deviceId,
        'photo_path': photoFile.path,
        'lat': lat,
        'lng': lng,
        'timestamp': now.millisecondsSinceEpoch,
      }),
      metadata: {
        'query_id': queryId,
        'photo_path': photoFile.path,
        'lat': lat,
        'lng': lng,
      },
    );
    _meshEngine.queueOutboxMessage(envelope, attachmentPath: photoFile.path);

    // 3. Local comparison against locally cached missing persons if available
    final localMatch = await _findLocalMatch(photoFile);

    return {
      'offline': true,
      'queued_for_mesh': true,
      'match_found': localMatch != null,
      'top_match': localMatch,
      'matches': localMatch != null ? [localMatch] : <Map<String, dynamic>>[],
    };
  }

  Future<Map<String, dynamic>?> _findLocalMatch(File photoFile) async {
    if (!photoFile.existsSync()) return null;

    final localReports = _reports.isNotEmpty
        ? _reports
        : await _repository.getMissingPersons();

    final activeReports = localReports
        .where((r) => r.status.toUpperCase() != 'FOUND')
        .toList();

    if (activeReports.isEmpty) return null;

    MissingPerson? bestPerson;
    double highestSimilarity = 0.0;

    try {
      final candidateBytes = await photoFile.readAsBytes();
      if (candidateBytes.isEmpty) return null;

      for (final person in activeReports) {
        if (person.photoPath != null && person.photoPath!.isNotEmpty) {
          final cachedFile = File(person.photoPath!);
          if (cachedFile.existsSync()) {
            final cachedBytes = await cachedFile.readAsBytes();
            final similarity = _calculateImageSimilarity(candidateBytes, cachedBytes);
            if (similarity > highestSimilarity) {
              highestSimilarity = similarity;
              bestPerson = person;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[MissingPersonsProvider] Local photo comparison error: $e');
    }

    if (bestPerson != null && highestSimilarity >= 0.70) {
      return {
        'person_id': bestPerson.id,
        'id': bestPerson.id,
        'name': bestPerson.name,
        'age': bestPerson.age,
        'gender': bestPerson.gender,
        'description': bestPerson.description,
        'last_seen_location': bestPerson.lastSeenLocation,
        'contact_phone': bestPerson.contactPhone,
        'photo_path': bestPerson.photoPath,
        'photo_url': bestPerson.photoUrl,
        'similarity': highestSimilarity,
        'similarity_percent': (highestSimilarity * 100).toInt(),
        'medical_notes': '',
      };
    }

    return null;
  }

  double _calculateImageSimilarity(Uint8List a, Uint8List b) {
    if (listEquals(a, b)) return 1.0;

    final histA = List<double>.filled(32, 0.0);
    final histB = List<double>.filled(32, 0.0);

    final stepA = (a.length / 512).clamp(1, 1000).toInt();
    int countA = 0;
    for (int i = 0; i < a.length; i += stepA) {
      final bin = (a[i] ~/ 8).clamp(0, 31);
      histA[bin]++;
      countA++;
    }
    if (countA > 0) {
      for (int i = 0; i < 32; i++) {
        histA[i] /= countA;
      }
    }

    final stepB = (b.length / 512).clamp(1, 1000).toInt();
    int countB = 0;
    for (int i = 0; i < b.length; i += stepB) {
      final bin = (b[i] ~/ 8).clamp(0, 31);
      histB[bin]++;
      countB++;
    }
    if (countB > 0) {
      for (int i = 0; i < 32; i++) {
        histB[i] /= countB;
      }
    }

    double dot = 0.0;
    double magA = 0.0;
    double magB = 0.0;
    for (int i = 0; i < 32; i++) {
      dot += histA[i] * histB[i];
      magA += histA[i] * histA[i];
      magB += histB[i] * histB[i];
    }
    if (magA <= 0 || magB <= 0) return 0.0;
    return (dot / (math.sqrt(magA) * math.sqrt(magB))).clamp(0.0, 1.0);
  }

  /// Loads reports from SQLite, then attempts opportunistically to sync with Gateway API
  Future<void> loadReports({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      // 1. Instant local read from SQLite (Offline-First source of truth)
      final localReports = await _repository.getMissingPersons(
        status: _selectedStatus == 'ALL' ? null : _selectedStatus,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      _reports = localReports;
      notifyListeners();

      // 2. Opportunistic Gateway Fetch if online
      _syncWithGateway();
    } catch (e) {
      debugPrint('[MissingPersonsProvider] Load error: $e');
      _errorMessage = 'Failed to load missing persons: $e';
    } finally {
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _syncWithGateway() async {
    try {
      final baseUrl = _getGatewayBaseUrl();
      final uri = Uri.parse('$baseUrl/api/v1/missing-persons');
      final resp = await http.get(uri).timeout(const Duration(seconds: 3));

      if (resp.statusCode == 200) {
        final List<dynamic> data = jsonDecode(resp.body);
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            final person = MissingPerson.fromMap(item);
            await _repository.saveReport(person);
          }
        }
        // Refresh local cache after sync
        final updatedReports = await _repository.getMissingPersons(
          status: _selectedStatus == 'ALL' ? null : _selectedStatus,
          search: _searchQuery.isEmpty ? null : _searchQuery,
        );
        _reports = updatedReports;
        notifyListeners();
      }
    } catch (e) {
      // Gateway unreachable; graceful offline degradation
      debugPrint('[MissingPersonsProvider] Gateway sync skipped: $e');
    }
  }

  /// Save-Before-Send Guarantee: Persist new report to SQLite, then broadcast via BLE mesh
  Future<MissingPerson> reportMissingPerson({
    required String name,
    required int age,
    String gender = 'Unspecified',
    required String lastSeenLocation,
    double? lat,
    double? lng,
    required String description,
    String? contactPhone,
    String? photoPath,
    String? incidentId,
    String? incidentTitle,
    String? clothingLastSeen,
    double? heightCm,
    String? identifyingMarks,
    String? medicalNeeds,
    String? bloodGroup,
    String priority = 'HIGH',
    String? assignedTeam,
  }) async {
    final myDeviceId = DeviceIdentityService.instance.deviceId;
    final myName = DeviceIdentityService.instance.displayName;
    final now = DateTime.now();
    final id = 'mp_${now.millisecondsSinceEpoch}_${myDeviceId.substring(0, myDeviceId.length > 4 ? 4 : myDeviceId.length)}';

    // Persist photo to permanent application documents directory so Android cache purge won't delete it
    String? permanentPhotoPath = photoPath;
    if (photoPath != null && photoPath.isNotEmpty) {
      try {
        final src = File(photoPath);
        if (await src.exists()) {
          Directory docsDir;
          try {
            docsDir = await getApplicationDocumentsDirectory();
          } catch (_) {
            docsDir = Directory.systemTemp;
          }
          final photosDir = Directory('${docsDir.path}/missing_persons_photos');
          if (!await photosDir.exists()) {
            await photosDir.create(recursive: true);
          }
          final ext = photoPath.contains('.') ? photoPath.split('.').last : 'jpg';
          final destPath = '${photosDir.path}/$id.$ext';
          final dest = await src.copy(destPath);
          permanentPhotoPath = dest.path;
        }
      } catch (e) {
        debugPrint('[MissingPersonsProvider] Error caching photo permanently: $e');
      }
    }

    final report = MissingPerson(
      id: id,
      name: name.trim(),
      age: age,
      gender: gender,
      description: description.trim(),
      lastSeenLocation: lastSeenLocation.trim(),
      lat: lat,
      lng: lng,
      lastSeenTime: now,
      reportedAt: now,
      photoUrl: '/api/v1/missing-persons/$id/photo',
      photoPath: permanentPhotoPath,
      status: 'MISSING',
      contactPhone: contactPhone?.trim(),
      reportedBy: myName,
      sightings: const [],
      incidentId: incidentId,
      incidentTitle: incidentTitle,
      clothingLastSeen: clothingLastSeen,
      heightCm: heightCm,
      identifyingMarks: identifyingMarks,
      medicalNeeds: medicalNeeds,
      bloodGroup: bloodGroup,
      priority: priority,
      assignedTeam: assignedTeam,
      biometricIndexed: false,
    );

    // 1. Transactional SQLite persistence
    await _repository.saveReport(report);

    // 2. Broadcast over local Bluetooth DTN mesh
    await _meshEngine.broadcastMissingPerson(report);

    // 3. Opportunistic cloud ingestion if online
    _postToGateway(report);

    await loadReports(silent: true);
    return report;
  }

  void _postToGateway(MissingPerson report) async {
    try {
      final baseUrl = _getGatewayBaseUrl();
      final uri = Uri.parse('$baseUrl/api/v1/missing-persons');
      final map = report.toMap();
      map['photo_url'] = '/api/v1/missing-persons/${report.id}/photo';

      if (report.photoPath != null && report.photoPath!.isNotEmpty) {
        final f = File(report.photoPath!);
        if (f.existsSync()) {
          final bytes = await f.readAsBytes();
          map['photo_base64'] = base64Encode(bytes);
        }
      }

      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(map),
          )
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('[MissingPersonsProvider] Cloud post queued offline: $e');
    }
  }

  /// Record a citizen sighting of a missing individual
  Future<void> recordSighting({
    required String personId,
    required String location,
    double? lat,
    double? lng,
    String? notes,
    String? photoPath,
    String? photoUrl,
  }) async {
    final myName = DeviceIdentityService.instance.displayName;
    final now = DateTime.now();

    final sighting = MissingPersonSighting(
      reportedBy: myName,
      location: location.trim(),
      timestamp: now,
      notes: notes?.trim(),
      lat: lat,
      lng: lng,
      photoPath: photoPath,
      photoUrl: photoUrl,
    );

    // 1. Save to SQLite
    await _repository.addSighting(personId, sighting);

    // 2. Broadcast sighting over BLE mesh
    await _meshEngine.broadcastMissingPersonSighting(personId, sighting);

    // 3. Opportunistic cloud update
    _postSightingToGateway(personId, sighting);

    await loadReports(silent: true);
  }

  void _postSightingToGateway(String personId, MissingPersonSighting sighting) async {
    try {
      final baseUrl = _getGatewayBaseUrl();
      final uri = Uri.parse('$baseUrl/api/v1/missing-persons/$personId/sightings');
      final map = sighting.toMap();

      if (sighting.photoPath != null && sighting.photoPath!.isNotEmpty) {
        final f = File(sighting.photoPath!);
        if (f.existsSync()) {
          final bytes = await f.readAsBytes();
          map['photo_base64'] = base64Encode(bytes);
        }
      }

      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(map),
          )
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('[MissingPersonsProvider] Cloud sighting queued offline: $e');
    }
  }

  /// Mark individual as found / reunited
  Future<void> markAsFound(String personId) async {
    await _repository.updateStatus(personId, 'FOUND');

    try {
      final baseUrl = _getGatewayBaseUrl();
      final uri = Uri.parse('$baseUrl/api/v1/missing-persons/$personId/status');
      await http
          .patch(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'status': 'FOUND'}),
          )
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('[MissingPersonsProvider] Mark found cloud sync deferred: $e');
    }

    await loadReports(silent: true);
  }
}
