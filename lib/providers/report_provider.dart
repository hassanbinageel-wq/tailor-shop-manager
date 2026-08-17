import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/constants/app_info.dart';
import '../core/db/app_database.dart';
import '../core/utils/formatters.dart';
import '../core/utils/period.dart';
import '../models/enums.dart';
import '../models/person.dart';
import '../models/shop_profile.dart';
import '../repositories/expense_repository.dart';
import '../repositories/person_repository.dart';
import '../repositories/stats_repository.dart';
import '../repositories/txn_repository.dart';
import '../repositories/work_repository.dart';
import '../services/excel_service.dart';
import '../services/pdf_service.dart';

/// أنواع التقارير المتاحة
enum ReportKind {
  tailor,
  cutter,
  worker,
  expenses,
  profit,
  daily,
  weekly,
  monthly,
  yearly,
}

extension ReportKindX on ReportKind {
  String get label => switch (this) {
        ReportKind.tailor => 'تقرير خياط',
        ReportKind.cutter => 'تقرير قصاص',
        ReportKind.worker => 'تقرير عامل',
        ReportKind.expenses => 'تقرير المصروفات',
        ReportKind.profit => 'تقرير الأرباح',
        ReportKind.daily => 'التقرير اليومي',
        ReportKind.weekly => 'التقرير الأسبوعي',
        ReportKind.monthly => 'التقرير الشهري',
        ReportKind.yearly => 'التقرير السنوي',
      };

  IconData get icon => switch (this) {
        ReportKind.tailor => Icons.content_cut_rounded,
        ReportKind.cutter => Icons.straighten_rounded,
        ReportKind.worker => Icons.badge_rounded,
        ReportKind.expenses => Icons.receipt_long_rounded,
        ReportKind.profit => Icons.trending_up_rounded,
        ReportKind.daily => Icons.today_rounded,
        ReportKind.weekly => Icons.date_range_rounded,
        ReportKind.monthly => Icons.calendar_month_rounded,
        ReportKind.yearly => Icons.event_note_rounded,
      };

  bool get needsPerson =>
      this == ReportKind.tailor || this == ReportKind.cutter || this == ReportKind.worker;

  PersonType? get personType => switch (this) {
        ReportKind.tailor => PersonType.tailor,
        ReportKind.cutter => PersonType.cutter,
        ReportKind.worker => PersonType.worker,
        _ => null,
      };
}

/// مزوّد بناء التقارير وتصديرها
class ReportProvider extends ChangeNotifier {
  final WorkRepository _work = WorkRepository();
  final TxnRepository _txns = TxnRepository();
  final ExpenseRepository _expenses = ExpenseRepository();
  final PersonRepository _persons = PersonRepository();
  final StatsRepository _stats = StatsRepository();
  final PdfService pdf = PdfService();
  final ExcelService excel = ExcelService();

  bool busy = false;

  void _setBusy(bool v) {
    busy = v;
    notifyListeners();
  }

  String _periodLabel(PeriodType type, DateRange range) {
    if (type == PeriodType.all) return 'كل الفترات';
    if (type == PeriodType.today) return Fmt.dateWithDay(range.start);
    return 'من ${Fmt.date(range.start)} إلى ${Fmt.date(range.end)}';
  }

  /// بناء بيانات التقرير
  Future<ReportData> build({
    required ReportKind kind,
    required PeriodType periodType,
    required String currency,
    DateTime? customStart,
    DateTime? customEnd,
    Person? person,
    String? note,
  }) async {
    _setBusy(true);
    try {
      final range = Periods.rangeFor(periodType,
          customStart: customStart, customEnd: customEnd);
      final refNo = await AppDatabase.instance.nextRef(AppInfo.refReport);
      final periodLabel = _periodLabel(periodType, range);

      switch (kind) {
        case ReportKind.tailor:
        case ReportKind.cutter:
        case ReportKind.worker:
          return _buildPersonReport(kind, person!, range, refNo, periodLabel, currency,
              note: note);
        case ReportKind.expenses:
          return _buildExpensesReport(range, refNo, periodLabel, currency, note: note);
        case ReportKind.profit:
          return _buildProfitReport(range, refNo, periodLabel, currency, note: note);
        case ReportKind.daily:
        case ReportKind.weekly:
        case ReportKind.monthly:
        case ReportKind.yearly:
          return _buildSummaryReport(
              kind.label, range, refNo, periodLabel, currency, note: note);
      }
    } finally {
      _setBusy(false);
    }
  }

  // ---------------- تقرير شخص ----------------

  Future<ReportData> _buildPersonReport(ReportKind kind, Person person, DateRange range,
      String refNo, String periodLabel, String currency,
      {String? note}) async {
    final works = await _work.forPerson(person.id!, range: range);
    final summary = await _stats.personSummary(person.id!, person.type, range: range);
    final sections = <ReportSection>[];

    if (person.type != PersonType.worker) {
      sections.add(ReportSection(
        title: 'سجل ${person.type.unitPluralLabel}',
        headers: ['م', 'الرقم المرجعي', 'التاريخ', 'اليوم', 'العدد', 'الأجرة', 'الإجمالي'],
        columnWidths: const [0.6, 1.5, 1.3, 1.1, 0.8, 1.1, 1.3],
        rows: [
          ...works.asMap().entries.map((e) => ReportRow([
                '${e.key + 1}',
                e.value.refNo,
                Fmt.date(e.value.date),
                Fmt.dayName(e.value.date),
                Fmt.num2(e.value.quantity),
                Fmt.num2(e.value.unitPrice),
                Fmt.num2(e.value.total),
              ])),
          if (works.isNotEmpty)
            ReportRow([
              '',
              '',
              '',
              'الإجمالي',
              Fmt.num2(summary.workCount.toDouble()),
              '',
              Fmt.num2(summary.workTotal),
            ], isTotal: true),
        ],
      ));
    }

    Future<void> addTxnSection(TxnKind kind, String title) async {
      final list = await _txns.forPerson(person.id!, kind: kind, range: range);
      if (list.isEmpty) return;
      sections.add(ReportSection(
        title: title,
        headers: ['م', 'الرقم المرجعي', 'التاريخ', 'المبلغ', 'ملاحظات'],
        columnWidths: const [0.6, 1.5, 1.3, 1.3, 2.5],
        rows: [
          ...list.asMap().entries.map((e) => ReportRow([
                '${e.key + 1}',
                e.value.refNo,
                Fmt.date(e.value.date),
                Fmt.num2(e.value.amount),
                e.value.notes ?? '-',
              ])),
          ReportRow([
            '',
            '',
            'الإجمالي',
            Fmt.num2(list.fold<double>(0, (s, t) => s + t.amount)),
            '',
          ], isTotal: true),
        ],
      ));
    }

    await addTxnSection(TxnKind.withdrawal, 'المسحوبات');
    await addTxnSection(TxnKind.personalExpense, 'المصروفات الشخصية');
    await addTxnSection(TxnKind.familyExpense, 'المصروفات العائلية');
    if (person.type == PersonType.worker) {
      await addTxnSection(TxnKind.salary, 'الرواتب المصروفة');
      await addTxnSection(TxnKind.commission, 'النسب');
      await addTxnSection(TxnKind.bonus, 'المكافآت');
    }

    final money = <String, String>{};
    if (person.type == PersonType.worker) {
      money['الراتب الشهري'] = Fmt.money(person.monthlySalary, currency);
      if (person.hasCommission) {
        money['النسبة (${Fmt.percent(person.commissionRate)})'] =
            Fmt.money(summary.commission, currency);
      }
      money['الرواتب المصروفة'] = Fmt.money(summary.salary, currency);
      if (summary.bonus > 0) money['المكافآت'] = Fmt.money(summary.bonus, currency);
    } else {
      money['عدد ${person.type.unitPluralLabel}'] = Fmt.count(summary.workCount);
      money['إجمالي الأجور'] = Fmt.money(summary.workTotal, currency);
    }
    money['إجمالي المسحوبات'] = Fmt.money(summary.withdrawals, currency);
    if (summary.personalExpenses > 0) {
      money['إجمالي المصروفات الشخصية'] = Fmt.money(summary.personalExpenses, currency);
    }
    if (summary.familyExpenses > 0) {
      money['إجمالي المصروفات العائلية'] = Fmt.money(summary.familyExpenses, currency);
    }
    money['صافي المستحق'] = Fmt.money(summary.netDue, currency);

    final subjectParts = [
      person.name,
      if (person.jobTitle != null && person.jobTitle!.isNotEmpty) person.jobTitle!,
      if (person.phone != null && person.phone!.isNotEmpty) person.phone!,
    ];

    return ReportData(
      title: kind.label,
      reportNo: refNo,
      periodLabel: periodLabel,
      subject: subjectParts.join(' — '),
      sections: sections,
      summary: money,
      note: note ?? person.notes,
    );
  }

  // ---------------- تقرير المصروفات ----------------

  Future<ReportData> _buildExpensesReport(
      DateRange range, String refNo, String periodLabel, String currency,
      {String? note}) async {
    final items = await _expenses.getAll(range: range);
    final byCat = await _expenses.byCategory(range: range);
    final total = items.fold<double>(0, (s, e) => s + e.amount);

    return ReportData(
      title: 'تقرير المصروفات',
      reportNo: refNo,
      periodLabel: periodLabel,
      sections: [
        ReportSection(
          title: 'تفاصيل المصروفات',
          headers: ['م', 'الرقم المرجعي', 'التاريخ', 'التصنيف', 'الوصف', 'المبلغ'],
          columnWidths: const [0.6, 1.5, 1.2, 1.2, 2.4, 1.2],
          rows: [
            ...items.asMap().entries.map((e) => ReportRow([
                  '${e.key + 1}',
                  e.value.refNo,
                  Fmt.date(e.value.date),
                  e.value.category,
                  e.value.description ?? '-',
                  Fmt.num2(e.value.amount),
                ])),
            if (items.isNotEmpty)
              ReportRow(['', '', '', '', 'الإجمالي', Fmt.num2(total)], isTotal: true),
          ],
        ),
        ReportSection(
          title: 'التوزيع حسب التصنيف',
          headers: ['التصنيف', 'المبلغ', 'النسبة'],
          columnWidths: const [2, 1.4, 1],
          rows: byCat
              .map((c) => ReportRow([
                    c.label,
                    Fmt.num2(c.value),
                    total == 0 ? '0%' : Fmt.percent((c.value / total) * 100),
                  ]))
              .toList(),
        ),
      ],
      summary: {
        'عدد العمليات': Fmt.count(items.length),
        'إجمالي المصروفات': Fmt.money(total, currency),
      },
      note: note,
    );
  }

  // ---------------- تقرير الأرباح ----------------

  Future<ReportData> _buildProfitReport(
      DateRange range, String refNo, String periodLabel, String currency,
      {String? note}) async {
    final tailorWages = await _work.totalWages(type: PersonType.tailor, range: range);
    final cutterWages = await _work.totalWages(type: PersonType.cutter, range: range);
    final workerWages = await _work.totalWages(type: PersonType.worker, range: range);
    final totalWages = tailorWages + cutterWages + workerWages;

    final salaries = await _txns.totalByKind(TxnKind.salary, range: range);
    final commissions = await _txns.totalByKind(TxnKind.commission, range: range);
    final bonuses = await _txns.totalByKind(TxnKind.bonus, range: range);
    final withdrawals = await _txns.totalByKind(TxnKind.withdrawal, range: range);
    final expenses = await _expenses.total(range: range);
    final byCat = await _expenses.byCategory(range: range);

    final totalCost = expenses + salaries + commissions + bonuses;
    final profit = totalWages - totalCost;

    return ReportData(
      title: 'تقرير الأرباح',
      reportNo: refNo,
      periodLabel: periodLabel,
      sections: [
        ReportSection(
          title: 'الإيرادات (أجور الإنتاج)',
          headers: ['البند', 'المبلغ'],
          columnWidths: const [2.4, 1.3],
          rows: [
            ReportRow(['أجور الخياطة', Fmt.num2(tailorWages)]),
            ReportRow(['أجور القص', Fmt.num2(cutterWages)]),
            ReportRow(['أجور العاملين', Fmt.num2(workerWages)]),
            ReportRow(['إجمالي الإيرادات', Fmt.num2(totalWages)], isTotal: true),
          ],
        ),
        ReportSection(
          title: 'التكاليف',
          headers: ['البند', 'المبلغ'],
          columnWidths: const [2.4, 1.3],
          rows: [
            ReportRow(['مصروفات المحل', Fmt.num2(expenses)]),
            ReportRow(['الرواتب المصروفة', Fmt.num2(salaries)]),
            ReportRow(['النسب', Fmt.num2(commissions)]),
            ReportRow(['المكافآت', Fmt.num2(bonuses)]),
            ReportRow(['إجمالي التكاليف', Fmt.num2(totalCost)], isTotal: true),
          ],
        ),
        ReportSection(
          title: 'المصروفات حسب التصنيف',
          headers: ['التصنيف', 'المبلغ'],
          columnWidths: const [2.4, 1.3],
          rows: byCat.map((c) => ReportRow([c.label, Fmt.num2(c.value)])).toList(),
        ),
      ],
      summary: {
        'إجمالي الإيرادات': Fmt.money(totalWages, currency),
        'إجمالي التكاليف': Fmt.money(totalCost, currency),
        'إجمالي المسحوبات': Fmt.money(withdrawals, currency),
        'صافي الربح': Fmt.money(profit, currency),
      },
      note: note,
    );
  }

  // ---------------- التقارير الدورية ----------------

  Future<ReportData> _buildSummaryReport(String title, DateRange range, String refNo,
      String periodLabel, String currency,
      {String? note}) async {
    final sections = <ReportSection>[];

    for (final type in PersonType.values) {
      final persons = await _persons.getByType(type);
      final rows = <ReportRow>[];
      double sumWages = 0, sumWd = 0, sumNet = 0;
      double sumQty = 0;

      for (final p in persons) {
        final s = await _stats.personSummary(p.id!, type, range: range);
        if (s.workTotal == 0 && s.deductions == 0 && s.grossDue == 0) continue;
        rows.add(ReportRow([
          p.name,
          Fmt.num2(s.workCount.toDouble()),
          Fmt.num2(s.workTotal),
          Fmt.num2(s.withdrawals),
          Fmt.num2(s.deductions - s.withdrawals),
          Fmt.num2(s.netDue),
        ]));
        sumWages += s.workTotal;
        sumWd += s.withdrawals;
        sumNet += s.netDue;
        sumQty += s.workCount;
      }

      if (rows.isEmpty) continue;
      rows.add(ReportRow([
        'الإجمالي',
        Fmt.num2(sumQty),
        Fmt.num2(sumWages),
        Fmt.num2(sumWd),
        '',
        Fmt.num2(sumNet),
      ], isTotal: true));

      sections.add(ReportSection(
        title: type.labelPlural,
        headers: [
          'الاسم',
          'العدد',
          'الأجور',
          'المسحوبات',
          'مصروفات أخرى',
          'صافي المستحق'
        ],
        columnWidths: const [2, 0.9, 1.3, 1.3, 1.4, 1.4],
        rows: rows,
      ));
    }

    final expenses = await _expenses.getAll(range: range);
    final expTotal = expenses.fold<double>(0, (s, e) => s + e.amount);
    final byCat = await _expenses.byCategory(range: range);
    if (byCat.isNotEmpty) {
      sections.add(ReportSection(
        title: 'المصروفات',
        headers: ['التصنيف', 'المبلغ'],
        columnWidths: const [2.4, 1.3],
        rows: [
          ...byCat.map((c) => ReportRow([c.label, Fmt.num2(c.value)])),
          ReportRow(['الإجمالي', Fmt.num2(expTotal)], isTotal: true),
        ],
      ));
    }

    final totalWages = await _work.totalWages(range: range);
    final withdrawals = await _txns.totalByKind(TxnKind.withdrawal, range: range);
    final netDue = await _stats.globalNetDue(range: range);

    return ReportData(
      title: title,
      reportNo: refNo,
      periodLabel: periodLabel,
      sections: sections,
      summary: {
        'إجمالي الأجور': Fmt.money(totalWages, currency),
        'إجمالي المسحوبات': Fmt.money(withdrawals, currency),
        'إجمالي المصروفات': Fmt.money(expTotal, currency),
        'صافي المستحقات': Fmt.money(netDue, currency),
        'صافي الربح التقديري': Fmt.money(totalWages - expTotal, currency),
      },
      note: note,
    );
  }

  // ---------------- التصدير ----------------

  Future<Uint8List> renderPdf(ReportData data, ShopProfile shop) =>
      pdf.build(data, shop);

  String fileName(ReportData data, String ext) {
    final t = data.title.replaceAll(' ', '_');
    return '${t}_${data.reportNo}.$ext';
  }

  Future<void> sharePdf(ReportData data, ShopProfile shop) async {
    final bytes = await pdf.build(data, shop);
    await pdf.share(bytes, fileName(data, 'pdf'));
  }

  Future<void> printPdf(ReportData data, ShopProfile shop) async {
    final bytes = await pdf.build(data, shop);
    await pdf.printDocument(bytes, data.title);
  }

  Future<void> shareExcel(ReportData data) async {
    await excel.exportAndShare(data, fileName: fileName(data, 'xlsx'));
  }
}
