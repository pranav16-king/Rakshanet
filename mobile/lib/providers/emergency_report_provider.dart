import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/emergency_report.dart';

class EmergencyReportProvider extends ChangeNotifier {
  final List<EmergencyReport> _reports = [];
  bool _isBroadcasting = false;
  EmergencyReport? _latestReport;

  List<EmergencyReport> get reports => List.unmodifiable(_reports);
  bool get isBroadcasting => _isBroadcasting;
  EmergencyReport? get latestReport => _latestReport;
  int get pendingCount => _reports.where((r) => r.syncPending).length;

  EmergencyReportProvider() {
    loadReports();
  }

  Future<void> loadReports() async {
    try {
      final loaded = await AppDatabase.instance.getEmergencyReports();
      _reports.clear();
      _reports.addAll(loaded);
      if (_reports.isNotEmpty) {
        _latestReport = _reports.first;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading emergency reports: $e');
    }
  }

  /// Save-Before-Send Guarantee: Persist to SQLite first, then initiate broadcast
  Future<EmergencyReport> sendEmergencyReport({
    required String category,
    String? description,
    int peopleCount = 1,
    double? latitude,
    double? longitude,
  }) async {
    _isBroadcasting = true;
    notifyListeners();

    final report = EmergencyReport.create(
      id: const Uuid().v4(),
      category: category,
      description: description,
      peopleCount: peopleCount,
      latitude: latitude,
      longitude: longitude,
      status: 'relayed', // simulated initial mesh broadcast
      timestamp: DateTime.now(),
      syncPending: true,
    );

    // 1. Save to SQLite database (Source of Truth)
    await AppDatabase.instance.saveEmergencyReport(report);

    // 2. Update memory state
    _reports.insert(0, report);
    _latestReport = report;
    _isBroadcasting = false;
    notifyListeners();

    return report;
  }
}
