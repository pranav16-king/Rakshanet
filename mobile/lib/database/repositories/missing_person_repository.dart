import '../../models/missing_person.dart';
import '../app_database.dart';

/// Repository managing Missing Person reports, search, sightings, and mesh bulletins in SQLite
class MissingPersonRepository {
  final AppDatabase _db;

  MissingPersonRepository([AppDatabase? db]) : _db = db ?? AppDatabase.instance;

  /// Retrieve all missing person reports with optional status and text search
  Future<List<MissingPerson>> getMissingPersons({String? status, String? search}) async {
    return _db.getMissingPersons(status: status, search: search);
  }

  /// Retrieve a specific missing person by ID
  Future<MissingPerson?> getById(String id) async {
    return _db.getMissingPersonById(id);
  }

  /// Save or update a missing person report in SQLite (Save-Before-Send guarantee)
  Future<void> saveReport(MissingPerson report) async {
    await _db.saveMissingPerson(report);
  }

  /// Update search status (e.g. 'MISSING' or 'FOUND')
  Future<void> updateStatus(String id, String status) async {
    await _db.updateMissingPersonStatus(id, status);
  }

  /// Add a citizen sighting
  Future<void> addSighting(String personId, MissingPersonSighting sighting) async {
    await _db.addMissingPersonSighting(personId, sighting);
  }

  /// Count of currently active missing person cases
  Future<int> getActiveCount() async {
    final list = await _db.getMissingPersons(status: 'MISSING');
    return list.length;
  }
}
