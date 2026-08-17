import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/enums.dart';
import '../../models/money_txn.dart';
import '../../models/person.dart';
import '../../models/work_entry.dart';
import '../../providers/person_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common.dart';
import '../reports/report_preview_screen.dart';
import 'entry_sheets.dart';

/// صفحة تفاصيل الخياط / القصاص / العامل
class PersonDetailScreen extends StatelessWidget {
  final Person person;
  const PersonDetailScreen({super.key, required this.person});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PersonDetailProvider()..init(person),
      child: const _PersonDetailBody(),
    );
  }
}

class _PersonDetailBody extends StatelessWidget {
  const _PersonDetailBody();

  @override
  Widget build(BuildContext context) {
    final detail = context.watch<PersonDetailProvider>();
    final settings = context.watch<SettingsProvider>();
    final person = detail.person;
    if (person == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currency = settings.currency;
    final color = personColor(person.type);
    final isWorker = person.type == PersonType.worker;

    return Scaffold(
      appBar: AppBar(
        title: Text(person.name),
        actions: [
          IconButton(
            tooltip: 'تقرير',
            icon: const Icon(Icons.picture_as_pdf_rounded),
            onPressed: () => _openReport(context, person, detail),
          ),
        ],
      ),
      floatingActionButton: _AddMenu(person: person),
      body: RefreshIndicator(
        onRefresh: () => detail.refresh(),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            _PersonHeader(person: person, color: color, currency: currency),

            PeriodFilterBar(
              selected: detail.periodType,
              customStart: detail.customStart,
              customEnd: detail.customEnd,
              onChanged: (t, st, en) => detail.setPeriod(t, start: st, end: en),
            ),

            if (detail.busy) const LinearProgressIndicator(minHeight: 2),

            // ---------- عمليات العمل ----------
            if (!isWorker) ...[
              SectionHeader(
                title: 'عدد ${person.type.unitPluralLabel} المنجزة',
                icon: Icons.content_cut_rounded,
                trailing: Pill(
                  text: '${Fmt.count(detail.summary.workCount)} ${person.type.unitLabel}',
                  color: color,
                ),
              ),
              _WorkList(entries: detail.workEntries, currency: currency, color: color),
            ],

            // ---------- الرواتب والنسب للعامل ----------
            if (isWorker) ...[
              const SectionHeader(
                  title: 'الرواتب المصروفة', icon: Icons.payments_rounded),
              _TxnList(
                  kind: TxnKind.salary, txns: detail.txns(TxnKind.salary),
                  currency: currency, color: AppTheme.cWages),
              if (person.hasCommission) ...[
                SectionHeader(
                  title: 'النسبة (${Fmt.percent(person.commissionRate)})',
                  icon: Icons.percent_rounded,
                  trailing: Pill(
                    text: 'المحتسبة: ${Fmt.money(detail.autoCommission, currency)}',
                    color: AppTheme.cNet,
                  ),
                ),
                _TxnList(
                    kind: TxnKind.commission, txns: detail.txns(TxnKind.commission),
                    currency: currency, color: AppTheme.cNet),
              ],
            ],

            // ---------- المسحوبات ----------
            const SectionHeader(title: 'المسحوبات', icon: Icons.output_rounded),
            _TxnList(
                kind: TxnKind.withdrawal, txns: detail.txns(TxnKind.withdrawal),
                currency: currency, color: AppTheme.cWithdrawals),

            // ---------- المصروفات الشخصية والعائلية ----------
            if (person.type == PersonType.tailor || isWorker) ...[
              const SectionHeader(
                  title: 'المصروفات الشخصية', icon: Icons.person_rounded),
              _TxnList(
                  kind: TxnKind.personalExpense,
                  txns: detail.txns(TxnKind.personalExpense),
                  currency: currency, color: AppTheme.cExpenses),

              const SectionHeader(
                  title: 'المصروفات العائلية', icon: Icons.family_restroom_rounded),
              _TxnList(
                  kind: TxnKind.familyExpense,
                  txns: detail.txns(TxnKind.familyExpense),
                  currency: currency, color: AppTheme.cExpenses),
            ],

            // ---------- الملاحظات ----------
            if (person.notes != null && person.notes!.isNotEmpty) ...[
              const SectionHeader(title: 'الملاحظات', icon: Icons.notes_rounded),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(person.notes!, style: const TextStyle(height: 1.6)),
                ),
              ),
            ],

            // ---------- المجاميع ----------
            const SizedBox(height: 10),
            _SummarySection(
                person: person, detail: detail, currency: currency),
          ],
        ),
      ),
    );
  }

  Future<void> _openReport(
      BuildContext context, Person person, PersonDetailProvider detail) async {
    final settings = context.read<SettingsProvider>();
    final reports = context.read<ReportProvider>();

    final kind = switch (person.type) {
      PersonType.tailor => ReportKind.tailor,
      PersonType.cutter => ReportKind.cutter,
      PersonType.worker => ReportKind.worker,
    };

    final data = await reports.build(
      kind: kind,
      periodType: detail.periodType,
      currency: settings.currency,
      customStart: detail.customStart,
      customEnd: detail.customEnd,
      person: person,
    );

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReportPreviewScreen(data: data)),
    );
  }
}

// ------------------- الترويسة -------------------

class _PersonHeader extends StatelessWidget {
  final Person person;
  final Color color;
  final String currency;

  const _PersonHeader({
    required this.person,
    required this.color,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Text(
                initialOf(person.name),
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w800, fontSize: 24),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(person.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(
                    [
                      person.type.label,
                      if (person.jobTitle != null && person.jobTitle!.isNotEmpty)
                        person.jobTitle!,
                      person.refNo,
                    ].join('  •  '),
                    style: TextStyle(
                        fontSize: 12.5, color: scheme.onSurfaceVariant),
                  ),
                  if (person.phone != null && person.phone!.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.phone_rounded,
                            size: 14, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 5),
                        Text(person.phone!,
                            style: TextStyle(
                                fontSize: 12.5, color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 7,
                    runSpacing: 6,
                    children: [
                      if (person.type == PersonType.worker) ...[
                        Pill(
                          text: 'الراتب: ${Fmt.money(person.monthlySalary, currency)}',
                          color: AppTheme.cWages,
                        ),
                        if (person.hasCommission)
                          Pill(
                            text: 'نسبة ${Fmt.percent(person.commissionRate)}',
                            color: AppTheme.cNet,
                          ),
                      ] else if (person.defaultUnitPrice > 0)
                        Pill(
                          text:
                              'أجرة ${person.type.unitLabel}: ${Fmt.money(person.defaultUnitPrice, currency)}',
                          color: color,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------- قوائم العمليات -------------------

class _WorkList extends StatelessWidget {
  final List<WorkEntry> entries;
  final String currency;
  final Color color;

  const _WorkList({
    required this.entries,
    required this.currency,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const _EmptyCard(message: 'لا توجد عمليات مسجلة في هذه الفترة');
    }
    final detail = context.read<PersonDetailProvider>();

    return Card(
      child: Column(
        children: entries.map((e) {
          return Column(
            children: [
              ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withValues(alpha: 0.13),
                  child: Text(Fmt.num2(e.quantity),
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: color)),
                ),
                title: Text('${Fmt.date(e.date)}  •  ${Fmt.dayName(e.date)}'),
                subtitle: Text(
                  '${Fmt.num2(e.quantity)} × ${Fmt.num2(e.unitPrice)}'
                  '${e.notes != null && e.notes!.isNotEmpty ? '  •  ${e.notes}' : ''}'
                  '\n${e.refNo}',
                  maxLines: 2,
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(Fmt.money(e.total, currency),
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: color)),
                    _RowMenu(
                      onEdit: () => showWorkEntrySheet(context,
                          person: detail.person!, entry: e),
                      onDelete: () async {
                        final ok = await confirmDialog(
                          context,
                          title: 'حذف العملية',
                          message: 'سيتم حذف العملية ${e.refNo} نهائياً.',
                        );
                        if (ok && context.mounted) {
                          await detail.deleteWork(e);
                          if (context.mounted) showSnack(context, 'تم الحذف');
                        }
                      },
                    ),
                  ],
                ),
              ),
              if (e != entries.last)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _TxnList extends StatelessWidget {
  final TxnKind kind;
  final List<MoneyTxn> txns;
  final String currency;
  final Color color;

  const _TxnList({
    required this.kind,
    required this.txns,
    required this.currency,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (txns.isEmpty) {
      return _EmptyCard(message: 'لا توجد ${kind.label} في هذه الفترة');
    }
    final detail = context.read<PersonDetailProvider>();

    return Card(
      child: Column(
        children: txns.map((t) {
          return Column(
            children: [
              ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withValues(alpha: 0.13),
                  child: Icon(Icons.receipt_rounded, size: 17, color: color),
                ),
                title: Text('${Fmt.date(t.date)}  •  ${Fmt.dayName(t.date)}'),
                subtitle: Text(
                  '${t.notes != null && t.notes!.isNotEmpty ? '${t.notes}\n' : ''}${t.refNo}',
                  maxLines: 2,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(Fmt.money(t.amount, currency),
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: color)),
                    _RowMenu(
                      onEdit: () => showTxnSheet(context,
                          person: detail.person!, kind: kind, txn: t),
                      onDelete: () async {
                        final ok = await confirmDialog(
                          context,
                          title: 'حذف العملية',
                          message: 'سيتم حذف ${t.refNo} نهائياً.',
                        );
                        if (ok && context.mounted) {
                          await detail.deleteTxn(t);
                          if (context.mounted) showSnack(context, 'تم الحذف');
                        }
                      },
                    ),
                  ],
                ),
              ),
              if (t != txns.last)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _RowMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _RowMenu({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert_rounded, size: 20),
        padding: EdgeInsets.zero,
        onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: 'edit',
            child: ListTile(
              dense: true,
              leading: Icon(Icons.edit_rounded),
              title: Text('تعديل'),
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              dense: true,
              leading: Icon(Icons.delete_rounded, color: Colors.red),
              title: Text('حذف', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      );
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
          child: Center(
            child: Text(message,
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        ),
      );
}

// ------------------- المجاميع -------------------

class _SummarySection extends StatelessWidget {
  final Person person;
  final PersonDetailProvider detail;
  final String currency;

  const _SummarySection({
    required this.person,
    required this.detail,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final s = detail.summary;
    final isWorker = person.type == PersonType.worker;
    final rows = <Widget>[];

    if (isWorker) {
      rows.add(SummaryRow(
        label: 'الراتب الشهري',
        value: Fmt.money(person.monthlySalary, currency),
        icon: Icons.payments_rounded,
        color: AppTheme.cWages,
      ));
      if (person.hasCommission) {
        rows.add(SummaryRow(
          label: 'مجموع النسبة',
          value: Fmt.money(s.commission, currency),
          icon: Icons.percent_rounded,
          color: AppTheme.cNet,
        ));
      }
      if (s.salary > 0) {
        rows.add(SummaryRow(
          label: 'الرواتب المصروفة',
          value: Fmt.money(s.salary, currency),
          icon: Icons.check_circle_rounded,
        ));
      }
      rows.add(SummaryRow(
        label: 'مجموع المسحوبات',
        value: Fmt.money(s.withdrawals, currency),
        icon: Icons.output_rounded,
        color: AppTheme.cWithdrawals,
      ));
      if (s.personalExpenses > 0) {
        rows.add(SummaryRow(
          label: 'المصروفات الشخصية',
          value: Fmt.money(s.personalExpenses, currency),
          icon: Icons.person_rounded,
          color: AppTheme.cExpenses,
        ));
      }
      if (s.familyExpenses > 0) {
        rows.add(SummaryRow(
          label: 'المصروفات العائلية',
          value: Fmt.money(s.familyExpenses, currency),
          icon: Icons.family_restroom_rounded,
          color: AppTheme.cExpenses,
        ));
      }
    } else {
      rows.add(SummaryRow(
        label: 'عدد ${person.type.unitPluralLabel}',
        value: '${Fmt.count(s.workCount)} ${person.type.unitLabel}',
        icon: Icons.numbers_rounded,
      ));
      rows.add(SummaryRow(
        label: person.type == PersonType.tailor
            ? 'إجمالي أجور الخياطة'
            : 'إجمالي أجور القص',
        value: Fmt.money(s.workTotal, currency),
        icon: Icons.payments_rounded,
        color: AppTheme.cWages,
      ));
      rows.add(SummaryRow(
        label: 'إجمالي المسحوبات',
        value: Fmt.money(s.withdrawals, currency),
        icon: Icons.output_rounded,
        color: AppTheme.cWithdrawals,
      ));
      if (person.type == PersonType.tailor) {
        rows.add(SummaryRow(
          label: 'إجمالي المصروفات الشخصية',
          value: Fmt.money(s.personalExpenses, currency),
          icon: Icons.person_rounded,
          color: AppTheme.cExpenses,
        ));
        rows.add(SummaryRow(
          label: 'إجمالي المصروفات العائلية',
          value: Fmt.money(s.familyExpenses, currency),
          icon: Icons.family_restroom_rounded,
          color: AppTheme.cExpenses,
        ));
      }
    }

    rows.add(const Divider(height: 12, indent: 16, endIndent: 16));
    rows.add(SummaryRow(
      label: person.type == PersonType.cutter ? 'المتبقي' : 'صافي المستحق',
      value: Fmt.money(s.netDue, currency),
      icon: Icons.account_balance_wallet_rounded,
      color: s.netDue >= 0 ? AppTheme.cNet : AppTheme.cExpenses,
      bold: true,
    ));

    return SummaryPanel(title: 'المجاميع', children: rows);
  }
}

// ------------------- زر الإضافة -------------------

class _AddMenu extends StatelessWidget {
  final Person person;
  const _AddMenu({required this.person});

  @override
  Widget build(BuildContext context) {
    final isWorker = person.type == PersonType.worker;

    return FloatingActionButton.extended(
      onPressed: () => showModalBottomSheet(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 6, 20, 10),
                child: Text('إضافة عملية جديدة',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ),
              if (!isWorker)
                ListTile(
                  leading: const Icon(Icons.add_task_rounded),
                  title: Text('تسجيل ${person.type.unitPluralLabel}'),
                  subtitle: Text('عدد ${person.type.unitPluralLabel} وأجرة ${person.type.unitLabel}'),
                  onTap: () {
                    Navigator.pop(ctx);
                    showWorkEntrySheet(context, person: person);
                  },
                ),
              if (isWorker) ...[
                ListTile(
                  leading: const Icon(Icons.payments_rounded),
                  title: const Text('صرف راتب'),
                  onTap: () {
                    Navigator.pop(ctx);
                    showTxnSheet(context, person: person, kind: TxnKind.salary);
                  },
                ),
                if (person.hasCommission)
                  ListTile(
                    leading: const Icon(Icons.percent_rounded),
                    title: const Text('إضافة نسبة'),
                    onTap: () {
                      Navigator.pop(ctx);
                      showTxnSheet(context, person: person, kind: TxnKind.commission);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.card_giftcard_rounded),
                  title: const Text('إضافة مكافأة'),
                  onTap: () {
                    Navigator.pop(ctx);
                    showTxnSheet(context, person: person, kind: TxnKind.bonus);
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.output_rounded),
                title: const Text('تسجيل مسحوبات'),
                onTap: () {
                  Navigator.pop(ctx);
                  showTxnSheet(context, person: person, kind: TxnKind.withdrawal);
                },
              ),
              if (person.type == PersonType.tailor || isWorker) ...[
                ListTile(
                  leading: const Icon(Icons.person_rounded),
                  title: const Text('مصروفات شخصية'),
                  onTap: () {
                    Navigator.pop(ctx);
                    showTxnSheet(context,
                        person: person, kind: TxnKind.personalExpense);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.family_restroom_rounded),
                  title: const Text('مصروفات عائلية'),
                  onTap: () {
                    Navigator.pop(ctx);
                    showTxnSheet(context,
                        person: person, kind: TxnKind.familyExpense);
                  },
                ),
              ],
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      icon: const Icon(Icons.add_rounded),
      label: const Text('إضافة'),
    );
  }
}
