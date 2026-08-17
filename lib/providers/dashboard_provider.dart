import 'package:flutter/material.dart';

import '../core/utils/period.dart';
import '../models/enums.dart';
import '../models/summaries.dart';
import '../repositories/expense_repository.dart';
import '../repositories/person_repository.dart';
import '../repositories/stats_repository.dart';
import '../repositories/txn_repository.dart';
import '../repositories/work_repository.dart';
import '../services/reminder_service.dart';

/// مزوّد لوحة التحكم والإحصائيات
class DashboardProvider extends ChangeNotifier {
  final PersonRepository _persons = PersonRepository();
  final WorkRepository _work = WorkRepository();
  final TxnRepository _txns = TxnRepository();
  final ExpenseRepository _expenses = ExpenseRepository();
  final StatsRepository _stats = StatsRepository();
  final ReminderService _reminders = ReminderService();

  DashboardSummary summary = const DashboardSummary();
  List<RecentOperation> recent = [];
  List<ChartPoint> expensesByCategory = [];
  List<ChartPoint> wagesPerDay = [];
  List<ChartPoint> opsPerDay = [];
  List<ChartPoint> topProducers = [];
  List<({DateTime month, double wages, double expenses})> monthly = [];
  double monthExpenses = 0;
  List<AppReminder> reminders = [];

  /// رمز العملة الحالي (يضبطه SettingsProvider)
  String currency = 'ر.ي';

  PeriodType periodType = PeriodType.all;
  DateTime? customStart;
  DateTime? customEnd;
  bool busy = false;

  DateRange get range =>
      Periods.rangeFor(periodType, customStart: customStart, customEnd: customEnd);

  Future<void> setPeriod(PeriodType type, {DateTime? start, DateTime? end}) async {
    periodType = type;
    customStart = start;
    customEnd = end;
    await load();
  }

  Future<void> load() async {
    busy = true;
    notifyListeners();

    final r = periodType == PeriodType.all ? null : range;
    final today = Periods.rangeFor(PeriodType.today);
    final thisMonth = Periods.rangeFor(PeriodType.month);

    final tailors = await _persons.countByType(PersonType.tailor);
    final cutters = await _persons.countByType(PersonType.cutter);
    final workers = await _persons.countByType(PersonType.worker);

    final wages = await _work.totalWages(range: r);
    final txnTotals = await _txns.totalsByKind(range: r);
    final withdrawals = txnTotals[TxnKind.withdrawal] ?? 0;
    final expensesTotal = await _expenses.total(range: r);
    final netDue = await _stats.globalNetDue(range: r);

    final todayOps = (await _work.countInRange(today)) +
        (await _txns.countInRange(today)) +
        (await _expenses.countInRange(today));

    summary = DashboardSummary(
      tailorsCount: tailors,
      cuttersCount: cutters,
      workersCount: workers,
      totalWages: wages,
      totalWithdrawals: withdrawals,
      totalExpenses: expensesTotal,
      netDue: netDue,
      todayOperations: todayOps,
    );

    recent = await _stats.recentOperations();
    expensesByCategory = await _expenses.byCategory(range: r);
    wagesPerDay = await _stats.wagesPerDay(Periods.lastDays(7));
    opsPerDay = await _stats.operationsPerDay(Periods.lastDays(7));
    topProducers = await _work.topProducers(range: r);
    monthly = await _stats.monthlyComparison(Periods.lastMonths(6));
    monthExpenses = await _expenses.total(range: thisMonth);
    reminders = await _reminders.pending(
      monthExpenses: monthExpenses,
      currency: currency,
    );

    busy = false;
    notifyListeners();
  }

  /// إجمالي الأرباح التقديري = الأجور المحصّلة ناقص المصروفات
  double get profit => summary.totalWages - summary.totalExpenses;

  /// إخفاء تنبيه بعد قراءته
  void dismissReminder(ReminderKind kind) {
    reminders = reminders.where((r) => r.kind != kind).toList();
    notifyListeners();
  }
}
