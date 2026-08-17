import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/db/app_database.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/period.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/person_provider.dart';
import '../../repositories/expense_repository.dart';
import '../../repositories/txn_repository.dart';
import '../../repositories/work_repository.dart';
import '../../services/backup_service.dart';
import '../../widgets/common.dart';

/// أرشفة البيانات حسب السنوات وتصفير شهر معين
class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  final ExpenseRepository _expenses = ExpenseRepository();
  final WorkRepository _work = WorkRepository();
  final TxnRepository _txns = TxnRepository();
  final BackupService _backup = BackupService();

  List<int> _years = [];
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadYears();
  }

  Future<void> _loadYears() async {
    final y = await _expenses.availableYears();
    if (!mounted) return;
    setState(() => _years = y);
  }

  Future<void> _reload() async {
    if (!mounted) return;
    await context.read<PersonProvider>().loadAll();
    if (!mounted) return;
    await context.read<ExpenseProvider>().load();
    if (!mounted) return;
    await context.read<DashboardProvider>().load();
  }

  Future<void> _clearRange(DateRange range, String label) async {
    setState(() => _busy = true);

    // نسخة احتياطية تلقائية قبل أي تصفير
    final backup = await _backup.createBackup();

    final w = await _work.deleteForRange(range);
    final t = await _txns.deleteForRange(range);
    final e = await _expenses.deleteForRange(range);

    await _reload();
    await _loadYears();
    if (!mounted) return;
    setState(() => _busy = false);

    showSnack(
      context,
      'تم تصفير $label — حُذف ${w + t + e} سجل'
      '${backup.success ? ' (تم حفظ نسخة احتياطية تلقائياً)' : ''}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('الأرشيف وتصفير البيانات')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          if (_busy) const LinearProgressIndicator(minHeight: 2),

          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.errorContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.info_rounded, color: scheme.error),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'يتم إنشاء نسخة احتياطية تلقائياً قبل أي عملية تصفير، ويمكنك استعادتها من قسم النسخ الاحتياطي.',
                    style: TextStyle(
                        fontSize: 12.5, color: scheme.onErrorContainer),
                  ),
                ),
              ],
            ),
          ),

          const SectionHeader(
              title: 'تصفير بيانات شهر معين', icon: Icons.event_busy_rounded),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_month_rounded),
                  title: const Text('الشهر المختار'),
                  subtitle: Text(Fmt.monthYear(_selectedMonth)),
                  trailing: const Icon(Icons.edit_calendar_rounded),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedMonth,
                      firstDate: DateTime(2015),
                      lastDate: DateTime(2100),
                      locale: const Locale('ar'),
                      helpText: 'اختر أي يوم من الشهر المطلوب',
                    );
                    if (picked != null) {
                      setState(() =>
                          _selectedMonth = DateTime(picked.year, picked.month));
                    }
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error,
                      side: BorderSide(color: scheme.error),
                    ),
                    onPressed: _busy
                        ? null
                        : () async {
                            final label = Fmt.monthYear(_selectedMonth);
                            final ok = await confirmDialog(
                              context,
                              title: 'تصفير بيانات $label',
                              message:
                                  'سيتم حذف كل عمليات العمل والحركات المالية والمصروفات في $label. سيتم إنشاء نسخة احتياطية أولاً.',
                              confirmLabel: 'تصفير',
                            );
                            if (ok) {
                              await _clearRange(
                                DateRange(
                                  Periods.startOfMonth(_selectedMonth),
                                  Periods.endOfMonth(_selectedMonth),
                                ),
                                label,
                              );
                            }
                          },
                    icon: const Icon(Icons.delete_sweep_rounded),
                    label: Text('تصفير ${Fmt.monthYear(_selectedMonth)}'),
                  ),
                ),
              ],
            ),
          ),

          const SectionHeader(
              title: 'الأرشفة حسب السنوات', icon: Icons.folder_zip_rounded),
          if (_years.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: EmptyState(
                icon: Icons.folder_off_rounded,
                title: 'لا توجد بيانات مؤرشفة',
                message: 'ستظهر هنا السنوات التي تحتوي على بيانات',
              ),
            )
          else
            Card(
              child: Column(
                children: _years.map((y) {
                  return ListTile(
                    leading: const Icon(Icons.event_note_rounded),
                    title: Text('سنة $y'),
                    subtitle: const Text('تصفير كل بيانات هذه السنة'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_forever_rounded,
                          color: scheme.error),
                      onPressed: _busy
                          ? null
                          : () async {
                              final ok = await confirmDialog(
                                context,
                                title: 'تصفير سنة $y',
                                message:
                                    'سيتم حذف كل بيانات سنة $y. سيتم إنشاء نسخة احتياطية أولاً.',
                                confirmLabel: 'تصفير',
                              );
                              if (ok) {
                                await _clearRange(
                                  DateRange(
                                    DateTime(y, 1, 1),
                                    DateTime(y, 12, 31, 23, 59, 59, 999),
                                  ),
                                  'سنة $y',
                                );
                              }
                            },
                    ),
                  );
                }).toList(),
              ),
            ),

          const SectionHeader(
              title: 'خطر — تصفير كامل', icon: Icons.dangerous_rounded),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.error,
                  side: BorderSide(color: scheme.error),
                ),
                onPressed: _busy
                    ? null
                    : () async {
                        final ok = await confirmDialog(
                          context,
                          title: 'تصفير كل البيانات',
                          message:
                              'سيتم حذف جميع الخياطين والقصاصين والعاملين والمصروفات والعمليات نهائياً. سيتم إنشاء نسخة احتياطية أولاً.',
                          confirmLabel: 'حذف الكل',
                        );
                        if (!ok) return;
                        setState(() => _busy = true);
                        await _backup.createBackup();
                        await AppDatabase.instance.wipeAll();
                        await _reload();
                        await _loadYears();
                        if (!mounted) return;
                        setState(() => _busy = false);
                        showSnack(context, 'تم تصفير كل البيانات');
                      },
                icon: const Icon(Icons.delete_forever_rounded),
                label: const Text('تصفير كل البيانات'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
