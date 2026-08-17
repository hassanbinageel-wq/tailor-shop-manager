import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import 'expense_form_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _search = TextEditingController();
  bool _showChart = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().load();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openForm({Expense? expense}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExpenseFormScreen(expense: expense)),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.watch<ExpenseProvider>();
    final currency = context.watch<SettingsProvider>().currency;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المصروفات'),
        actions: [
          IconButton(
            tooltip: _showChart ? 'إخفاء الرسم' : 'عرض الرسم البياني',
            icon: Icon(_showChart
                ? Icons.pie_chart_rounded
                : Icons.pie_chart_outline_rounded),
            onPressed: () => setState(() => _showChart = !_showChart),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('إضافة مصروف'),
      ),
      body: Column(
        children: [
          AppSearchField(
            controller: _search,
            hint: 'بحث بالوصف أو المبلغ أو التصنيف...',
            onChanged: provider.setQuery,
          ),
          PeriodFilterBar(
            selected: provider.periodType,
            customStart: provider.customStart,
            customEnd: provider.customEnd,
            onChanged: (t, st, en) => provider.setPeriod(t, start: st, end: en),
          ),
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: ExpenseCategory.all.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (ctx, i) {
                if (i == 0) {
                  return Center(
                    child: ChoiceChip(
                      label: const Text('كل التصنيفات'),
                      selected: provider.category == null,
                      onSelected: (_) => provider.setCategory(null),
                    ),
                  );
                }
                final cat = ExpenseCategory.all[i - 1];
                return Center(
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: provider.category == cat,
                    onSelected: (_) => provider.setCategory(cat),
                  ),
                );
              },
            ),
          ),

          if (provider.busy) const LinearProgressIndicator(minHeight: 2),

          if (_showChart)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: CategoryPieChart(
                  points: provider.categoryBreakdown,
                  currency: currency,
                  height: 190,
                ),
              ),
            ),

          Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: AppTheme.cExpenses.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_rounded,
                    color: AppTheme.cExpenses, size: 21),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'إجمالي المصروفات (${provider.items.length} عملية)',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(Fmt.money(provider.total, currency),
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.cExpenses)),
              ],
            ),
          ),

          Expanded(
            child: provider.items.isEmpty
                ? EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'لا توجد مصروفات',
                    message: 'اضغط على زر الإضافة لتسجيل مصروف جديد',
                    action: FilledButton.icon(
                      onPressed: () => _openForm(),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('إضافة مصروف'),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => provider.load(),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 90),
                      itemCount: provider.items.length,
                      itemBuilder: (ctx, i) {
                        final e = provider.items[i];
                        return Card(
                          child: ListTile(
                            onTap: () => _openForm(expense: e),
                            leading: CircleAvatar(
                              radius: 21,
                              backgroundColor:
                                  AppTheme.cExpenses.withValues(alpha: 0.13),
                              child: Icon(_categoryIcon(e.category),
                                  size: 20, color: AppTheme.cExpenses),
                            ),
                            title: Text(e.category),
                            subtitle: Text(
                              '${Fmt.date(e.date)} • ${Fmt.dayName(e.date)}'
                              '${e.description != null && e.description!.isNotEmpty ? '\n${e.description}' : ''}'
                              '\n${e.refNo}',
                              maxLines: 3,
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(Fmt.money(e.amount, currency),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: AppTheme.cExpenses)),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                                  onSelected: (v) async {
                                    if (v == 'edit') {
                                      _openForm(expense: e);
                                    } else {
                                      final ok = await confirmDialog(
                                        context,
                                        title: 'حذف المصروف',
                                        message:
                                            'سيتم حذف ${e.refNo} (${e.category}) نهائياً.',
                                      );
                                      if (ok && context.mounted) {
                                        await provider.remove(e);
                                        if (context.mounted) {
                                          showSnack(context, 'تم الحذف');
                                        }
                                      }
                                    }
                                  },
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
                                        leading: Icon(Icons.delete_rounded,
                                            color: Colors.red),
                                        title: Text('حذف',
                                            style: TextStyle(color: Colors.red)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

IconData _categoryIcon(String category) => switch (category) {
      ExpenseCategory.rent => Icons.home_work_rounded,
      ExpenseCategory.electricity => Icons.bolt_rounded,
      ExpenseCategory.water => Icons.water_drop_rounded,
      ExpenseCategory.tools => Icons.build_rounded,
      ExpenseCategory.fabric => Icons.layers_rounded,
      ExpenseCategory.threads => Icons.line_weight_rounded,
      ExpenseCategory.maintenance => Icons.handyman_rounded,
      ExpenseCategory.transport => Icons.local_shipping_rounded,
      _ => Icons.more_horiz_rounded,
    };
