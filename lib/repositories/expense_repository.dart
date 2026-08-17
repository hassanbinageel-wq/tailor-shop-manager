import 'package:sqflite/sqflite.dart';

import '../core/constants/app_info.dart';
import '../core/db/app_database.dart';
import '../core/utils/period.dart';
import '../models/expense.dart';
import '../models/summaries.dart';

class ExpenseRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<List<Expense>> getAll({DateRange? range, String? category, String? query}) async {
    final db = await _db.database;
    final where = <String>[];
    final args = <Object?>[];

    if (range != null) {
      where.add('date BETWEEN ? AND ?');
      args.addAll([range.startMs, range.endMs]);
    }
    if (category != null && category.isNotEmpty) {
      where.add('category = ?');
      args.add(category);
    }
    if (query != null && query.trim().isNotEmpty) {
      final q = '%${query.trim()}%';
      final numQ = double.tryParse(query.trim());
      if (numQ != null) {
        where.add('(description LIKE ? OR notes LIKE ? OR ref_no LIKE ? OR category LIKE ? OR amount = ?)');
        args.addAll([q, q, q, q, numQ]);
      } else {
        where.add('(description LIKE ? OR notes LIKE ? OR ref_no LIKE ? OR category LIKE ?)');
        args.addAll([q, q, q, q]);
      }
    }

    final rows = await db.query(
      'expenses',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  Future<int> insert(Expense e) async {
    final db = await _db.database;
    final ref = e.refNo.isEmpty ? await _db.nextRef(AppInfo.refExpense) : e.refNo;
    return db.insert('expenses', e.copyWith(refNo: ref).toMap());
  }

  Future<int> update(Expense e) async {
    final db = await _db.database;
    return db.update('expenses', e.toMap(), where: 'id = ?', whereArgs: [e.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> total({DateRange? range, String? category}) async {
    final db = await _db.database;
    final where = <String>[];
    final args = <Object?>[];
    if (range != null) {
      where.add('date BETWEEN ? AND ?');
      args.addAll([range.startMs, range.endMs]);
    }
    if (category != null && category.isNotEmpty) {
      where.add('category = ?');
      args.add(category);
    }
    final clause = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final r = await db
        .rawQuery('SELECT COALESCE(SUM(amount),0) AS s FROM expenses $clause', args);
    return (r.first['s'] as num?)?.toDouble() ?? 0;
  }

  /// توزيع المصروفات حسب التصنيف
  Future<List<ChartPoint>> byCategory({DateRange? range}) async {
    final db = await _db.database;
    final args = <Object?>[];
    var clause = '';
    if (range != null) {
      clause = 'WHERE date BETWEEN ? AND ?';
      args.addAll([range.startMs, range.endMs]);
    }
    final rows = await db.rawQuery(
      'SELECT category, COALESCE(SUM(amount),0) AS s FROM expenses $clause '
      'GROUP BY category ORDER BY s DESC',
      args,
    );
    return rows
        .map((r) => ChartPoint(
            (r['category'] as String?) ?? '-', (r['s'] as num?)?.toDouble() ?? 0))
        .toList();
  }

  Future<int> countInRange(DateRange range) async {
    final db = await _db.database;
    final r = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM expenses WHERE date BETWEEN ? AND ?',
      [range.startMs, range.endMs],
    );
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<int> deleteForRange(DateRange range) async {
    final db = await _db.database;
    return db.delete('expenses',
        where: 'date BETWEEN ? AND ?', whereArgs: [range.startMs, range.endMs]);
  }

  /// السنوات المتوفرة في البيانات (للأرشفة)
  Future<List<int>> availableYears() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT DISTINCT y FROM (
        SELECT CAST(strftime('%Y', date/1000, 'unixepoch') AS INTEGER) AS y FROM expenses
        UNION
        SELECT CAST(strftime('%Y', date/1000, 'unixepoch') AS INTEGER) AS y FROM work_entries
        UNION
        SELECT CAST(strftime('%Y', date/1000, 'unixepoch') AS INTEGER) AS y FROM money_txns
      ) WHERE y IS NOT NULL ORDER BY y DESC
    ''');
    return rows.map((r) => (r['y'] as int?) ?? 0).where((y) => y > 0).toList();
  }
}
