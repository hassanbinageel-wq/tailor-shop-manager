import 'package:sqflite/sqflite.dart';

import '../core/db/app_database.dart';

/// مستودع الإعدادات — يخزّن أزواج مفتاح/قيمة في قاعدة البيانات
class SettingsRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<Map<String, String>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('app_settings');
    return {
      for (final r in rows)
        (r['key'] as String? ?? ''): (r['value'] as String? ?? ''),
    };
  }

  Future<String?> get(String key) async {
    final db = await _db.database;
    final rows =
        await db.query('app_settings', where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> set(String key, String value) async {
    final db = await _db.database;
    await db.insert('app_settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> setMany(Map<String, String> values) async {
    final db = await _db.database;
    final batch = db.batch();
    values.forEach((k, v) {
      batch.insert('app_settings', {'key': k, 'value': v},
          conflictAlgorithm: ConflictAlgorithm.replace);
    });
    await batch.commit(noResult: true);
  }

  Future<void> remove(String key) async {
    final db = await _db.database;
    await db.delete('app_settings', where: 'key = ?', whereArgs: [key]);
  }
}
