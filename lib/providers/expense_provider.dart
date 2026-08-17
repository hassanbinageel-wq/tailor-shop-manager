import 'package:flutter/material.dart';

import '../core/utils/period.dart';
import '../models/enums.dart';
import '../models/expense.dart';
import '../models/summaries.dart';
import '../repositories/expense_repository.dart';
import '../repositories/log_repository.dart';

class ExpenseProvider extends ChangeNotifier {
  final ExpenseRepository _repo = ExpenseRepository();
  final LogRepository _log = LogRepository();

  List<Expense> items = [];
  List<ChartPoint> categoryBreakdown = [];
  double total = 0;
  bool busy = false;

  PeriodType periodType = PeriodType.month;
  DateTime? customStart;
  DateTime? customEnd;
  String? category;
  String query = '';

  DateRange get range =>
      Periods.rangeFor(periodType, customStart: customStart, customEnd: customEnd);

  Future<void> load() async {
    busy = true;
    notifyListeners();
    final r = periodType == PeriodType.all ? null : range;
    items = await _repo.getAll(range: r, category: category, query: query);
    total = await _repo.total(range: r, category: category);
    categoryBreakdown = await _repo.byCategory(range: r);
    busy = false;
    notifyListeners();
  }

  Future<void> setPeriod(PeriodType type, {DateTime? start, DateTime? end}) async {
    periodType = type;
    customStart = start;
    customEnd = end;
    await load();
  }

  Future<void> setCategory(String? c) async {
    category = c;
    await load();
  }

  Future<void> setQuery(String q) async {
    query = q;
    await load();
  }

  Future<void> add(Expense e) async {
    await _repo.insert(e);
    await _log.log('إضافة', 'مصروف', '${e.category}: ${e.amount}');
    await load();
  }

  Future<void> update(Expense e) async {
    await _repo.update(e);
    await _log.log('تعديل', 'مصروف', '${e.refNo} - ${e.category}');
    await load();
  }

  Future<void> remove(Expense e) async {
    await _repo.delete(e.id!);
    await _log.log('حذف', 'مصروف', '${e.refNo} - ${e.category}');
    await load();
  }
}
