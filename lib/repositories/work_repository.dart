import 'package:sqflite/sqflite.dart';

import '../core/constants/app_info.dart';
import '../core/db/app_database.dart';
import '../core/utils/period.dart';
import '../models/enums.dart';
import '../models/summaries.dart';
import '../models/work_entry.dart';

class WorkRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<List<WorkEntry>> forPerson(int personId, {DateRange? range}) async {
    final db = await _db.database;
    final where = StringBuffer('person_id = ?');
    final args = <Object?>[personId];
    if (range != null) {
      where.write(' AND date BETWEEN ? AND ?');
      args.addAll([range.startMs, range.endMs]);
    }
    final rows = await db.query('work_entries',
        where: where.toString(), whereArgs: args, orderBy: 'date DESC, id DESC');
    return rows.map(WorkEntry.fromMap).toList();
  }

  Future<int> insert(WorkEntry e) async {
    final db = await _db.database;
    final ref = e.refNo.isEmpty ? await _db.nextRef(AppInfo.refWork) : e.refNo;
    return db.insert('work_entries', e.copyWith(refNo: ref).toMap());
  }

  Future<int> update(WorkEntry e) async {
    final db = await _db.database;
    return db.update('work_entries', e.toMap(), where: 'id = ?', whereArgs: [e.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return db.delete('work_entries', where: 'id = ?', whereArgs: [id]);
  }

  /// إجمالي أجور العمل والكمية لشخص
  Future<({double total, double qty})> totalsForPerson(int personId,
      {DateRange? range}) async {
    final db = await _db.database;
    final where = StringBuffer('person_id = ?');
    final args = <Object?>[personId];
    if (range != null) {
      where.write(' AND date BETWEEN ? AND ?');
      args.addAll([range.startMs, range.endMs]);
    }
    final r = await db.rawQuery(
      'SELECT COALESCE(SUM(total),0) AS t, COALESCE(SUM(quantity),0) AS q '
      'FROM work_entries WHERE ${where.toString()}',
      args,
    );
    final row = r.first;
    return (
      total: (row['t'] as num?)?.toDouble() ?? 0,
      qty: (row['q'] as num?)?.toDouble() ?? 0,
    );
  }

  /// إجمالي الأجور لكل النوع أو للكل
  Future<double> totalWages({PersonType? type, DateRange? range}) async {
    final db = await _db.database;
    final where = <String>[];
    final args = <Object?>[];
    if (type != null) {
      where.add('person_type = ?');
      args.add(type.code);
    }
    if (range != null) {
      where.add('date BETWEEN ? AND ?');
      args.addAll([range.startMs, range.endMs]);
    }
    final clause = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final r = await db
        .rawQuery('SELECT COALESCE(SUM(total),0) AS t FROM work_entries $clause', args);
    return (r.first['t'] as num?)?.toDouble() ?? 0;
  }

  /// إجمالي الكميات (عدد الأثواب/القصات)
  Future<double> totalQuantity({PersonType? type, DateRange? range}) async {
    final db = await _db.database;
    final where = <String>[];
    final args = <Object?>[];
    if (type != null) {
      where.add('person_type = ?');
      args.add(type.code);
    }
    if (range != null) {
      where.add('date BETWEEN ? AND ?');
      args.addAll([range.startMs, range.endMs]);
    }
    final clause = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final r = await db.rawQuery(
        'SELECT COALESCE(SUM(quantity),0) AS q FROM work_entries $clause', args);
    return (r.first['q'] as num?)?.toDouble() ?? 0;
  }

  /// أكثر الموظفين إنتاجاً
  Future<List<ChartPoint>> topProducers({DateRange? range, int limit = 5}) async {
    final db = await _db.database;
    final args = <Object?>[];
    var clause = '';
    if (range != null) {
      clause = 'WHERE w.date BETWEEN ? AND ?';
      args.addAll([range.startMs, range.endMs]);
    }
    final rows = await db.rawQuery('''
      SELECT p.name AS name, COALESCE(SUM(w.quantity),0) AS q
      FROM work_entries w JOIN persons p ON p.id = w.person_id
      $clause
      GROUP BY w.person_id
      ORDER BY q DESC
      LIMIT $limit
    ''', args);
    return rows
        .map((r) => ChartPoint(
            (r['name'] as String?) ?? '-', (r['q'] as num?)?.toDouble() ?? 0))
        .toList();
  }

  /// عدد العمليات في نطاق
  Future<int> countInRange(DateRange range) async {
    final db = await _db.database;
    final r = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM work_entries WHERE date BETWEEN ? AND ?',
      [range.startMs, range.endMs],
    );
    return Sqflite.firstIntValue(r) ?? 0;
  }

  /// بحث في عمليات العمل
  Future<List<Map<String, Object?>>> search(String query) async {
    final db = await _db.database;
    final q = '%${query.trim()}%';
    final numQ = double.tryParse(query.trim());
    final args = <Object?>[q, q, q];
    var extra = '';
    if (numQ != null) {
      extra = ' OR w.total = ? OR w.quantity = ?';
      args.addAll([numQ, numQ]);
    }
    return db.rawQuery('''
      SELECT w.*, p.name AS person_name FROM work_entries w
      JOIN persons p ON p.id = w.person_id
      WHERE p.name LIKE ? OR p.phone LIKE ? OR w.ref_no LIKE ? $extra
      ORDER BY w.date DESC LIMIT 50
    ''', args);
  }

  Future<int> deleteForRange(DateRange range) async {
    final db = await _db.database;
    return db.delete('work_entries',
        where: 'date BETWEEN ? AND ?', whereArgs: [range.startMs, range.endMs]);
  }
}
