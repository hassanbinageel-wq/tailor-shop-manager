import '../core/db/app_database.dart';
import '../core/utils/period.dart';
import '../models/activity_log.dart';

class LogRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<void> log(String action, String entity, String description,
      {int? entityId}) async {
    final db = await _db.database;
    await db.insert(
      'activity_logs',
      ActivityLog(
        action: action,
        entity: entity,
        entityId: entityId,
        description: description,
        timestamp: DateTime.now(),
      ).toMap(),
    );
  }

  Future<List<ActivityLog>> getAll({DateRange? range, int limit = 300}) async {
    final db = await _db.database;
    final rows = await db.query(
      'activity_logs',
      where: range == null ? null : 'timestamp BETWEEN ? AND ?',
      whereArgs: range == null ? null : [range.startMs, range.endMs],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return rows.map(ActivityLog.fromMap).toList();
  }

  Future<void> clear() async {
    final db = await _db.database;
    await db.delete('activity_logs');
  }
}
