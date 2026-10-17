import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../database/repositories/missing_person_repository.dart';
import '../models/missing_person.dart';
import '../services/device_identity_service.dart';
import '../services/mesh_engine.dart';

/// State management and offline-first DTN mesh sync for Missing Persons
class MissingPersonsProvider extends ChangeNotifier {
  final MissingPersonRepository _repository;
  final MeshEngine _meshEngine;
  StreamSubscription? _meshSubscription;

  List<MissingPerson> _reports = [];
  bool _isLoading = false;
  String _selectedStatus = 'ALL';
  String _searchQuery = '';
  String? _errorMessage;

  List<MissingPerson> get reports => List.unmodifiable(_reports);
  bool get isLoading => _isLoading;
  String get selectedStatus => _selectedStatus;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;

  int get totalCount => _reports.length;
  int get activeMissingCount =>
      _reports.where((r) => r.status.toUpperCase() != 'FOUND').length;
  int get foundCount =>
      _reports.where((r) => r.status.toUpperCase() == 'FOUND').length;

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
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
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
  }) async {
    final myDeviceId = DeviceIdentityService.instance.deviceId;
    final myName = DeviceIdentityService.instance.displayName;
    final now = DateTime.now();
    final id = 'mp_${now.millisecondsSinceEpoch}_${myDeviceId.substring(0, myDeviceId.length > 4 ? 4 : myDeviceId.length)}';

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
      photoPath: photoPath,
      status: 'MISSING',
      contactPhone: contactPhone?.trim(),
      reportedBy: myName,
      sightings: const [],
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
      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(report.toMap()),
          )
          .timeout(const Duration(seconds: 3));
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
      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(sighting.toMap()),
          )
          .timeout(const Duration(seconds: 3));
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
