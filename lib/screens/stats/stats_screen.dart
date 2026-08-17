import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final currency = context.watch<SettingsProvider>().currency;

    return Scaffold(
      appBar: AppBar(title: const Text('الإحصائيات')),
      body: RefreshIndicator(
        onRefresh: () => dash.load(),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            PeriodFilterBar(
              selected: dash.periodType,
              customStart: dash.customStart,
              customEnd: dash.customEnd,
              onChanged: (t, st, en) => dash.setPeriod(t, start: st, end: en),
            ),
            if (dash.busy) const LinearProgressIndicator(minHeight: 2),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.55,
                children: [
                  StatCard(
                    title: 'الأجور',
                    value: Fmt.money(dash.summary.totalWages, currency),
                    icon: Icons.payments_rounded,
                    color: AppTheme.cWages,
                  ),
                  StatCard(
                    title: 'المصروفات',
                    value: Fmt.money(dash.summary.totalExpenses, currency),
                    icon: Icons.receipt_long_rounded,
                    color: AppTheme.cExpenses,
                  ),
                  StatCard(
                    title: 'الأرباح',
                    value: Fmt.money(dash.profit, currency),
                    icon: Icons.trending_up_rounded,
                    color: dash.profit >= 0 ? AppTheme.cNet : AppTheme.cExpenses,
                  ),
                  StatCard(
                    title: 'المسحوبات',
                    value: Fmt.money(dash.summary.totalWithdrawals, currency),
                    icon: Icons.output_rounded,
                    color: AppTheme.cWithdrawals,
                  ),
                ],
              ),
            ),

            const SectionHeader(
                title: 'عدد العمليات اليومية', icon: Icons.stacked_bar_chart_rounded),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 16, 10, 6),
                child: SimpleBarChart(
                  points: dash.opsPerDay,
                  color: AppTheme.cNet,
                ),
              ),
            ),

            const SectionHeader(
                title: 'الأجور خلال 7 أيام', icon: Icons.bar_chart_rounded),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 16, 10, 6),
                child: SimpleBarChart(
                  points: dash.wagesPerDay,
                  color: AppTheme.cWages,
                ),
              ),
            ),

            const SectionHeader(
                title: 'مقارنة شهرية (آخر 6 أشهر)',
                icon: Icons.compare_arrows_rounded),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 16, 10, 14),
                child: MonthlyComparisonChart(data: dash.monthly),
              ),
            ),

            const SectionHeader(
                title: 'المصروفات حسب التصنيف', icon: Icons.pie_chart_rounded),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: CategoryPieChart(
                  points: dash.expensesByCategory,
                  currency: currency,
                ),
              ),
            ),

            const SectionHeader(
                title: 'أكثر الموظفين إنتاجاً', icon: Icons.emoji_events_rounded),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: TopProducersList(points: dash.topProducers),
              ),
            ),

            const SectionHeader(
                title: 'المقارنة السنوية', icon: Icons.calendar_month_rounded),
            Card(
              child: Column(
                children: dash.monthly
                    .map((m) => Column(
                          children: [
                            ListTile(
                              dense: true,
                              leading: const Icon(Icons.event_rounded),
                              title: Text(Fmt.monthYear(m.month)),
                              subtitle: Text(
                                  'الأجور ${Fmt.num2(m.wages)} • المصروفات ${Fmt.num2(m.expenses)}'),
                              trailing: Text(
                                Fmt.money(m.wages - m.expenses, currency),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  color: (m.wages - m.expenses) >= 0
                                      ? AppTheme.cWages
                                      : AppTheme.cExpenses,
                                ),
                              ),
                            ),
                            if (m != dash.monthly.last)
                              const Divider(height: 1, indent: 16, endIndent: 16),
                          ],
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
