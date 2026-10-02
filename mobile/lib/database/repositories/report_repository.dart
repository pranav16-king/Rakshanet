import 'package:sqflite/sqflite.dart';

import '../../models/emergency_report.dart';
import '../../models/missing_person.dart';
import '../../models/shelter_resource.dart';
import '../app_database.dart';

/// Repository handling Emergency Incidents, Relief Shelters, and Missing Person reports
class ReportRepository {
  final AppDatabase _db;
  static const String _reportsTable = 'emergency_reports';
  static const String _sheltersTable = 'shelters';
  static const String _missingPersonsTable = 'missing_persons';

  ReportRepository([AppDatabase? db]) : _db = db ?? AppDatabase.instance;

  // =========================================================================
  // Emergency Incident Reports
  // =========================================================================

  /// Fetch all filed emergency reports
  Future<List<EmergencyReport>> getReports() async {
    final rows = await _db.query(
      _reportsTable,
      orderBy: 'timestamp DESC',
    );
    return rows.map((r) => EmergencyReport.fromMap(r)).toList();
  }

  /// Fetch report by ID
  Future<EmergencyReport?> getReportById(String id) async {
    final rows = await _db.query(
      _reportsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return EmergencyReport.fromMap(rows.first);
  }

  /// Save or replace emergency incident report (Medical, Trapped, Fire, etc.)
  Future<void> saveReport(EmergencyReport report) async {
    await _db.insert(
      _reportsTable,
      report.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update status of report (e.g. 'PENDING', 'SENT', 'ACKNOWLEDGED', 'RESOLVED')
  Future<void> updateReportStatus(String id, String status) async {
    await _db.update(
      _reportsTable,
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Fetch reports pending transmission or acknowledgment
  Future<List<EmergencyReport>> getPendingReports() async {
    final rows = await _db.query(
      _reportsTable,
      where: 'status = ? OR status = ?',
      whereArgs: ['PENDING', 'QUEUED'],
      orderBy: 'timestamp ASC',
    );
    return rows.map((r) => EmergencyReport.fromMap(r)).toList();
  }

  /// Delete report by ID
  Future<void> deleteReport(String id) async {
    await _db.delete(
      _reportsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =========================================================================
  // Disaster Shelter Resources
  // =========================================================================

  /// Fetch all available shelters and relief hubs
  Future<List<ShelterResource>> getShelters() async {
    final rows = await _db.query(
      _sheltersTable,
      orderBy: 'distance ASC',
    );
    return rows.map((r) => ShelterResource.fromMap(r)).toList();
  }

  /// Fetch specific shelter by ID
  Future<ShelterResource?> getShelterById(String id) async {
    final rows = await _db.query(
      _sheltersTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ShelterResource.fromMap(rows.first);
  }

  /// Save or update a shelter resource
  Future<void> saveShelter(ShelterResource shelter) async {
    await _db.insert(
      _sheltersTable,
      shelter.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Bulk upsert shelters received via mesh broadcast
  Future<void> saveShelters(List<ShelterResource> shelters) async {
    for (final shelter in shelters) {
      await saveShelter(shelter);
    }
  }

  // =========================================================================
  // Missing Person Bulletins
  // =========================================================================

  /// Fetch all missing person bulletins
  Future<List<MissingPerson>> getMissingPersons() async {
    final rows = await _db.query(
      _missingPersonsTable,
      orderBy: 'last_seen_time DESC',
    );
    return rows.map((r) => MissingPerson.fromMap(r)).toList();
  }

  /// Fetch missing person by ID
  Future<MissingPerson?> getMissingPersonById(String id) async {
    final rows = await _db.query(
      _missingPersonsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return MissingPerson.fromMap(rows.first);
  }

  /// Save or update missing person bulletin
  Future<void> saveMissingPerson(MissingPerson person) async {
    await _db.insert(
      _missingPersonsTable,
      person.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update search status (e.g. 'SEARCHING', 'SIGHTED', 'FOUND')
  Future<void> updateMissingPersonStatus(String id, String status) async {
    await _db.update(
      _missingPersonsTable,
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
