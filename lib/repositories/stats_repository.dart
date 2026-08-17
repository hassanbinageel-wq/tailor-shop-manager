import '../core/db/app_database.dart';
import '../core/utils/period.dart';
import '../models/enums.dart';
import '../models/summaries.dart';

/// استعلامات تجميعية للإحصائيات والرسوم البيانية
class StatsRepository {
  final AppDatabase _db = AppDatabase.instance;

  /// آخر العمليات المضافة من كل الجداول
  Future<List<RecentOperation>> recentOperations({int limit = 12}) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT * FROM (
        SELECT w.ref_no AS ref_no, p.name AS title,
               'أجور ' || (CASE w.person_type WHEN 'tailor' THEN 'خياطة' WHEN 'cutter' THEN 'قص' ELSE 'عمل' END)
               AS subtitle,
               w.total AS amount, w.date AS date, 'work' AS kind, w.created_at AS ca
        FROM work_entries w JOIN persons p ON p.id = w.person_id
        UNION ALL
        SELECT t.ref_no, p.name,
               (CASE t.kind
                  WHEN 'withdrawal' THEN 'مسحوبات'
                  WHEN 'personal_expense' THEN 'مصروفات شخصية'
                  WHEN 'family_expense' THEN 'مصروفات عائلية'
                  WHEN 'commission' THEN 'نسبة'
                  WHEN 'salary' THEN 'راتب'
                  ELSE 'مكافأة' END),
               t.amount, t.date, 'txn', t.created_at
        FROM money_txns t JOIN persons p ON p.id = t.person_id
        UNION ALL
        SELECT e.ref_no, e.category, COALESCE(e.description, 'مصروف'),
               e.amount, e.date, 'expense', e.created_at
        FROM expenses e
      )
      ORDER BY ca DESC, date DESC
      LIMIT $limit
    ''');

    return rows
        .map((r) => RecentOperation(
              refNo: (r['ref_no'] as String?) ?? '',
              title: (r['title'] as String?) ?? '',
              subtitle: (r['subtitle'] as String?) ?? '',
              amount: (r['amount'] as num?)?.toDouble() ?? 0,
              date: DateTime.fromMillisecondsSinceEpoch((r['date'] as int?) ?? 0),
              kind: (r['kind'] as String?) ?? '',
            ))
        .toList();
  }

  /// أجور مجمّعة يومياً خلال نطاق
  Future<List<ChartPoint>> wagesPerDay(List<DateTime> days) async {
    final db = await _db.database;
    final out = <ChartPoint>[];
    for (final d in days) {
      final s = Periods.startOfDay(d).millisecondsSinceEpoch;
      final e = Periods.endOfDay(d).millisecondsSinceEpoch;
      final r = await db.rawQuery(
        'SELECT COALESCE(SUM(total),0) AS s FROM work_entries WHERE date BETWEEN ? AND ?',
        [s, e],
      );
      out.add(ChartPoint('${d.day}', (r.first['s'] as num?)?.toDouble() ?? 0));
    }
    return out;
  }

  /// عدد العمليات اليومية
  Future<List<ChartPoint>> operationsPerDay(List<DateTime> days) async {
    final db = await _db.database;
    final out = <ChartPoint>[];
    for (final d in days) {
      final s = Periods.startOfDay(d).millisecondsSinceEpoch;
      final e = Periods.endOfDay(d).millisecondsSinceEpoch;
      final r = await db.rawQuery('''
        SELECT (
          (SELECT COUNT(*) FROM work_entries WHERE date BETWEEN ? AND ?) +
          (SELECT COUNT(*) FROM money_txns WHERE date BETWEEN ? AND ?) +
          (SELECT COUNT(*) FROM expenses WHERE date BETWEEN ? AND ?)
        ) AS c
      ''', [s, e, s, e, s, e]);
      out.add(ChartPoint('${d.day}', ((r.first['c'] as num?) ?? 0).toDouble()));
    }
    return out;
  }

  /// مقارنة شهرية: أجور / مصروفات / أرباح
  Future<List<({DateTime month, double wages, double expenses})>> monthlyComparison(
      List<DateTime> months) async {
    final db = await _db.database;
    final out = <({DateTime month, double wages, double expenses})>[];
    for (final m in months) {
      final s = Periods.startOfMonth(m).millisecondsSinceEpoch;
      final e = Periods.endOfMonth(m).millisecondsSinceEpoch;
      final w = await db.rawQuery(
        'SELECT COALESCE(SUM(total),0) AS s FROM work_entries WHERE date BETWEEN ? AND ?',
        [s, e],
      );
      final x = await db.rawQuery(
        'SELECT COALESCE(SUM(amount),0) AS s FROM expenses WHERE date BETWEEN ? AND ?',
        [s, e],
      );
      out.add((
        month: m,
        wages: (w.first['s'] as num?)?.toDouble() ?? 0,
        expenses: (x.first['s'] as num?)?.toDouble() ?? 0,
      ));
    }
    return out;
  }

  /// ملخص شامل لشخص واحد
  Future<PersonSummary> personSummary(int personId, PersonType type,
      {DateRange? range}) async {
    final db = await _db.database;
    final args = <Object?>[personId];
    var dateClause = '';
    if (range != null) {
      dateClause = ' AND date BETWEEN ? AND ?';
      args.addAll([range.startMs, range.endMs]);
    }

    final work = await db.rawQuery(
      'SELECT COALESCE(SUM(total),0) AS t, COALESCE(SUM(quantity),0) AS q '
      'FROM work_entries WHERE person_id = ?$dateClause',
      args,
    );

    final txns = await db.rawQuery(
      'SELECT kind, COALESCE(SUM(amount),0) AS s FROM money_txns '
      'WHERE person_id = ?$dateClause GROUP BY kind',
      args,
    );

    double pick(String kind) {
      for (final r in txns) {
        if (r['kind'] == kind) return (r['s'] as num?)?.toDouble() ?? 0;
      }
      return 0;
    }

    return PersonSummary(
      workTotal: (work.first['t'] as num?)?.toDouble() ?? 0,
      workCount: ((work.first['q'] as num?)?.toDouble() ?? 0).round(),
      withdrawals: pick('withdrawal'),
      personalExpenses: pick('personal_expense'),
      familyExpenses: pick('family_expense'),
      commission: pick('commission'),
      salary: pick('salary'),
      bonus: pick('bonus'),
    );
  }

  /// صافي المستحقات لكل الأشخاص
  Future<double> globalNetDue({DateRange? range}) async {
    final db = await _db.database;
    final args = <Object?>[];
    var wClause = '';
    var tClause = '';
    if (range != null) {
      wClause = 'WHERE date BETWEEN ? AND ?';
      tClause = 'WHERE date BETWEEN ? AND ?';
      args.addAll([range.startMs, range.endMs, range.startMs, range.endMs]);
    }
    final r = await db.rawQuery('''
      SELECT
        (SELECT COALESCE(SUM(total),0) FROM work_entries $wClause) AS wages,
        (SELECT COALESCE(SUM(CASE WHEN kind IN ('commission','salary','bonus') THEN amount ELSE 0 END),0)
         - COALESCE(SUM(CASE WHEN kind IN ('withdrawal','personal_expense','family_expense') THEN amount ELSE 0 END),0)
         FROM money_txns $tClause) AS net
    ''', args);
    final wages = (r.first['wages'] as num?)?.toDouble() ?? 0;
    final net = (r.first['net'] as num?)?.toDouble() ?? 0;
    return wages + net;
  }
}
