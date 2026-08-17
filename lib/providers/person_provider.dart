import 'package:flutter/material.dart';

import '../core/utils/period.dart';
import '../models/enums.dart';
import '../models/money_txn.dart';
import '../models/person.dart';
import '../models/summaries.dart';
import '../models/work_entry.dart';
import '../repositories/log_repository.dart';
import '../repositories/person_repository.dart';
import '../repositories/stats_repository.dart';
import '../repositories/txn_repository.dart';
import '../repositories/work_repository.dart';

/// مزوّد قوائم الأشخاص (خياطين / قصاصين / عاملين)
class PersonProvider extends ChangeNotifier {
  final PersonRepository _repo = PersonRepository();
  final LogRepository _log = LogRepository();

  final Map<PersonType, List<Person>> _cache = {};
  final Map<PersonType, String> _queries = {};
  bool _busy = false;
  bool get busy => _busy;

  List<Person> list(PersonType type) => _cache[type] ?? const [];
  String query(PersonType type) => _queries[type] ?? '';

  Future<void> load(PersonType type) async {
    _busy = true;
    notifyListeners();
    _cache[type] = await _repo.getByType(type, query: _queries[type]);
    _busy = false;
    notifyListeners();
  }

  Future<void> setQuery(PersonType type, String q) async {
    _queries[type] = q;
    await load(type);
  }

  Future<void> loadAll() async {
    for (final t in PersonType.values) {
      _cache[t] = await _repo.getByType(t, query: _queries[t]);
    }
    notifyListeners();
  }

  Future<Person?> getById(int id) => _repo.getById(id);

  Future<void> add(Person person) async {
    final id = await _repo.insert(person);
    await _log.log('إضافة', person.type.label, 'تمت إضافة ${person.name}',
        entityId: id);
    await load(person.type);
  }

  Future<void> update(Person person) async {
    await _repo.update(person);
    await _log.log('تعديل', person.type.label, 'تم تعديل بيانات ${person.name}',
        entityId: person.id);
    await load(person.type);
  }

  Future<void> remove(Person person) async {
    await _repo.delete(person.id!);
    await _log.log('حذف', person.type.label, 'تم حذف ${person.name}',
        entityId: person.id);
    await load(person.type);
  }

  Future<void> togglePin(Person person) async {
    await _repo.setPinned(person.id!, !person.isPinned);
    await load(person.type);
  }

  Future<void> toggleArchive(Person person) async {
    await _repo.setArchived(person.id!, !person.isArchived);
    await _log.log(
        person.isArchived ? 'استعادة' : 'أرشفة', person.type.label, person.name,
        entityId: person.id);
    await load(person.type);
  }
}

/// مزوّد تفاصيل شخص واحد: عمليات العمل + الحركات المالية + الملخص
class PersonDetailProvider extends ChangeNotifier {
  final WorkRepository _work = WorkRepository();
  final TxnRepository _txn = TxnRepository();
  final StatsRepository _stats = StatsRepository();
  final PersonRepository _persons = PersonRepository();
  final LogRepository _log = LogRepository();

  Person? person;
  PeriodType periodType = PeriodType.all;
  DateTime? customStart;
  DateTime? customEnd;

  List<WorkEntry> workEntries = [];
  Map<TxnKind, List<MoneyTxn>> txnsByKind = {};
  PersonSummary summary = const PersonSummary();
  bool busy = false;

  DateRange get range => Periods.rangeFor(periodType,
      customStart: customStart, customEnd: customEnd);

  Future<void> init(Person p) async {
    person = p;
    await refresh();
  }

  Future<void> setPeriod(PeriodType type,
      {DateTime? start, DateTime? end}) async {
    periodType = type;
    customStart = start;
    customEnd = end;
    await refresh();
  }

  Future<void> refresh() async {
    if (person?.id == null) return;
    busy = true;
    notifyListeners();

    final pid = person!.id!;
    final r = periodType == PeriodType.all ? null : range;

    person = await _persons.getById(pid) ?? person;
    workEntries = await _work.forPerson(pid, range: r);

    final map = <TxnKind, List<MoneyTxn>>{};
    for (final k in TxnKind.values) {
      map[k] = await _txn.forPerson(pid, kind: k, range: r);
    }
    txnsByKind = map;
    summary = await _stats.personSummary(pid, person!.type, range: r);

    busy = false;
    notifyListeners();
  }

  List<MoneyTxn> txns(TxnKind kind) => txnsByKind[kind] ?? const [];

  /// النسبة المحتسبة تلقائياً من إنتاج العامل
  double get autoCommission {
    final p = person;
    if (p == null || !p.hasCommission) return 0;
    return summary.workTotal * (p.commissionRate / 100);
  }

  // ---------------- عمليات العمل ----------------

  Future<void> addWork(WorkEntry e) async {
    await _work.insert(e);
    await _log.log('إضافة', 'عملية عمل',
        '${person?.name ?? ''}: ${e.quantity} × ${e.unitPrice}');
    await refresh();
  }

  Future<void> updateWork(WorkEntry e) async {
    await _work.update(e);
    await _log.log('تعديل', 'عملية عمل', '${person?.name ?? ''} - ${e.refNo}');
    await refresh();
  }

  Future<void> deleteWork(WorkEntry e) async {
    await _work.delete(e.id!);
    await _log.log('حذف', 'عملية عمل', '${person?.name ?? ''} - ${e.refNo}');
    await refresh();
  }

  // ---------------- الحركات المالية ----------------

  Future<void> addTxn(MoneyTxn t) async {
    await _txn.insert(t);
    await _log.log('إضافة', t.kind.label, '${person?.name ?? ''}: ${t.amount}');
    await refresh();
  }

  Future<void> updateTxn(MoneyTxn t) async {
    await _txn.update(t);
    await _log.log('تعديل', t.kind.label, '${person?.name ?? ''} - ${t.refNo}');
    await refresh();
  }

  Future<void> deleteTxn(MoneyTxn t) async {
    await _txn.delete(t.id!);
    await _log.log('حذف', t.kind.label, '${person?.name ?? ''} - ${t.refNo}');
    await refresh();
  }
}
