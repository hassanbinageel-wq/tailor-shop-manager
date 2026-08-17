import 'package:sqflite/sqflite.dart';

import '../core/constants/app_info.dart';
import '../core/db/app_database.dart';
import '../core/utils/period.dart';
import '../models/enums.dart';
import '../models/money_txn.dart';

class TxnRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<List<MoneyTxn>> forPerson(int personId,
      {TxnKind? kind, DateRange? range}) async {
    final db = await _db.database;
    final where = StringBuffer('person_id = ?');
    final args = <Object?>[personId];
    if (kind != null) {
      where.write(' AND kind = ?');
      args.add(kind.code);
    }
    if (range != null) {
      where.write(' AND date BETWEEN ? AND ?');
      args.addAll([range.startMs, range.endMs]);
    }
    final rows = await db.query('money_txns',
        where: where.toString(), whereArgs: args, orderBy: 'date DESC, id DESC');
    return rows.map(MoneyTxn.fromMap).toList();
  }

  Future<int> insert(MoneyTxn t) async {
    final db = await _db.database;
    final ref = t.refNo.isEmpty ? await _db.nextRef(AppInfo.refTxn) : t.refNo;
    return db.insert('money_txns', t.copyWith(refNo: ref).toMap());
  }

  Future<int> update(MoneyTxn t) async {
    final db = await _db.database;
    return db.update('money_txns', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return db.delete('money_txns', where: 'id = ?', whereArgs: [id]);
  }

  /// مجاميع كل أنواع الحركات لشخص واحد في استعلام واحد
  Future<Map<TxnKind, double>> totalsByKindForPerson(int personId,
      {DateRange? range}) async {
    final db = await _db.database;
    final where = StringBuffer('person_id = ?');
    final args = <Object?>[personId];
    if (range != null) {
      where.write(' AND date BETWEEN ? AND ?');
      args.addAll([range.startMs, range.endMs]);
    }
    final rows = await db.rawQuery(
      'SELECT kind, COALESCE(SUM(amount),0) AS s FROM money_txns '
      'WHERE ${where.toString()} GROUP BY kind',
      args,
    );
    final map = <TxnKind, double>{};
    for (final r in rows) {
      map[TxnKindX.fromCode((r['kind'] as String?) ?? '')] =
          (r['s'] as num?)?.toDouble() ?? 0;
    }
    return map;
  }

  /// إجمالي نوع حركة عبر كل الأشخاص
  Future<double> totalByKind(TxnKind kind,
      {PersonType? personType, DateRange? range}) async {
    final db = await _db.database;
    final where = <String>['kind = ?'];
    final args = <Object?>[kind.code];
    if (personType != null) {
      where.add('person_type = ?');
      args.add(personType.code);
    }
    if (range != null) {
      where.add('date BETWEEN ? AND ?');
      args.addAll([range.startMs, range.endMs]);
    }
    final r = await db.rawQuery(
      'SELECT COALESCE(SUM(amount),0) AS s FROM money_txns WHERE ${where.join(' AND ')}',
      args,
    );
    return (r.first['s'] as num?)?.toDouble() ?? 0;
  }

  /// مجاميع كل الأنواع دفعة واحدة (للوحة التحكم)
  Future<Map<TxnKind, double>> totalsByKind({DateRange? range}) async {
    final db = await _db.database;
    final args = <Object?>[];
    var clause = '';
    if (range != null) {
      clause = 'WHERE date BETWEEN ? AND ?';
      args.addAll([range.startMs, range.endMs]);
    }
    final rows = await db.rawQuery(
        'SELECT kind, COALESCE(SUM(amount),0) AS s FROM money_txns $clause GROUP BY kind',
        args);
    final map = <TxnKind, double>{};
    for (final r in rows) {
      map[TxnKindX.fromCode((r['kind'] as String?) ?? '')] =
          (r['s'] as num?)?.toDouble() ?? 0;
    }
    return map;
  }

  Future<int> countInRange(DateRange range) async {
    final db = await _db.database;
    final r = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM money_txns WHERE date BETWEEN ? AND ?',
      [range.startMs, range.endMs],
    );
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<List<Map<String, Object?>>> search(String query) async {
    final db = await _db.database;
    final q = '%${query.trim()}%';
    final numQ = double.tryParse(query.trim());
    final args = <Object?>[q, q, q];
    var extra = '';
    if (numQ != null) {
      extra = ' OR t.amount = ?';
      args.add(numQ);
    }
    return db.rawQuery('''
      SELECT t.*, p.name AS person_name FROM money_txns t
      JOIN persons p ON p.id = t.person_id
      WHERE p.name LIKE ? OR p.phone LIKE ? OR t.ref_no LIKE ? $extra
      ORDER BY t.date DESC LIMIT 50
    ''', args);
  }

  Future<int> deleteForRange(DateRange range) async {
    final db = await _db.database;
    return db.delete('money_txns',
        where: 'date BETWEEN ? AND ?', whereArgs: [range.startMs, range.endMs]);
  }
}
