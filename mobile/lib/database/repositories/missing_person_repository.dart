import 'package:sqflite/sqflite.dart';
import '../../models/missing_person.dart';
import '../app_database.dart';

/// Repository managing Missing Person reports and mesh bulletins in SQLite
class MissingPersonRepository {
  final AppDatabase _db;
  static const String _tableName = 'missing_persons';

  MissingPersonRepository([AppDatabase? db]) : _db = db ?? AppDatabase.instance;

  /// Retrieve all missing person reports ordered by last seen time
  Future<List<MissingPerson>> getMissingPersons() async {
    final rows = await _db.query(
      _tableName,
      orderBy: 'last_seen_time DESC',
    );
    return rows.map((r) => MissingPerson.fromMap(r)).toList();
  }

  /// Retrieve a specific missing person by ID
  Future<MissingPerson?> getById(String id) async {
    final rows = await _db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return MissingPerson.fromMap(rows.first);
  }

  /// Save or update a missing person report in SQLite (Save-Before-Send guarantee)
  Future<void> saveReport(MissingPerson report) async {
    await _db.insert(
      _tableName,
      report.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update the search status (SEARCHING, SIGHTED, FOUND)
  Future<void> updateStatus(String id, String status) async {
    await _db.update(
      _tableName,
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Count of currently active missing person cases
  Future<int> getActiveCount() async {
    final rows = await _db.query(
      _tableName,
      where: 'status != ?',
      whereArgs: ['FOUND'],
    );
    return rows.length;
  }
}
