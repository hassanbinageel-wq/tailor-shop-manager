import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/summaries.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../search/global_search_screen.dart';
import '../stats/stats_screen.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int index)? onNavigate;
  const DashboardScreen({super.key, this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
    final settings = context.watch<SettingsProvider>();
    final currency = settings.currency;
    final s = dash.summary;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(settings.shop.shopName,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            Text(Fmt.dateWithDay(DateTime.now()),
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'بحث',
            icon: const Icon(Icons.search_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GlobalSearchScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => dash.load(),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            PeriodFilterBar(
              selected: dash.periodType,
              customStart: dash.customStart,
              customEnd: dash.customEnd,
              onChanged: (t, st, en) => dash.setPeriod(t, start: st, end: en),
            ),

            if (dash.busy)
              const Padding(
                padding: EdgeInsets.all(6),
                child: LinearProgressIndicator(minHeight: 2),
              ),

            // ----- بطاقات الفريق -----
            const SectionHeader(title: 'فريق العمل', icon: Icons.groups_rounded),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'الخياطون',
                      value: Fmt.count(s.tailorsCount),
                      icon: Icons.content_cut_rounded,
                      color: AppTheme.cTailor,
                      onTap: () => widget.onNavigate?.call(1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      title: 'القصاصون',
                      value: Fmt.count(s.cuttersCount),
                      icon: Icons.straighten_rounded,
                      color: AppTheme.cCutter,
                      onTap: () => widget.onNavigate?.call(1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      title: 'العاملون',
                      value: Fmt.count(s.workersCount),
                      icon: Icons.badge_rounded,
                      color: AppTheme.cWorker,
                      onTap: () => widget.onNavigate?.call(1),
                    ),
                  ),
                ],
              ),
            ),

            // ----- البطاقات المالية -----
            const SectionHeader(
                title: 'الملخص المالي', icon: Icons.account_balance_wallet_rounded),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.55,
                children: [
                  StatCard(
                    title: 'إجمالي الأجور',
                    value: Fmt.money(s.totalWages, currency),
                    icon: Icons.payments_rounded,
                    color: AppTheme.cWages,
                  ),
                  StatCard(
                    title: 'إجمالي المسحوبات',
                    value: Fmt.money(s.totalWithdrawals, currency),
                    icon: Icons.output_rounded,
                    color: AppTheme.cWithdrawals,
                  ),
                  StatCard(
                    title: 'إجمالي المصروفات',
                    value: Fmt.money(s.totalExpenses, currency),
                    icon: Icons.receipt_long_rounded,
                    color: AppTheme.cExpenses,
                    onTap: () => widget.onNavigate?.call(2),
                  ),
                  StatCard(
                    title: 'صافي المستحقات',
                    value: Fmt.money(s.netDue, currency),
                    icon: Icons.account_balance_rounded,
                    color: AppTheme.cNet,
                  ),
                ],
              ),
            ),

            // ----- مؤشرات سريعة -----
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      SummaryRow(
                        label: 'عمليات اليوم',
                        value: Fmt.count(s.todayOperations),
                        icon: Icons.today_rounded,
                        color: AppTheme.cNet,
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      SummaryRow(
                        label: 'صافي الربح التقديري',
                        value: Fmt.money(dash.profit, currency),
                        icon: Icons.trending_up_rounded,
                        color: dash.profit >= 0 ? AppTheme.cWages : AppTheme.cExpenses,
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ----- الرسوم البيانية -----
            SectionHeader(
              title: 'الأجور خلال 7 أيام',
              icon: Icons.bar_chart_rounded,
              trailing: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StatsScreen()),
                ),
                child: const Text('كل الإحصائيات'),
              ),
            ),
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

            // ----- آخر العمليات -----
            const SectionHeader(title: 'آخر العمليات', icon: Icons.history_rounded),
            if (dash.recent.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: EmptyState(
                  icon: Icons.inbox_rounded,
                  title: 'لا توجد عمليات بعد',
                  message: 'ابدأ بإضافة خياط أو عملية عمل جديدة',
                ),
              )
            else
              Card(
                child: Column(
                  children: dash.recent
                      .map((op) => _RecentTile(op: op, currency: currency))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  final RecentOperation op;
  final String currency;

  const _RecentTile({required this.op, required this.currency});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (op.kind) {
      'work' => (AppTheme.cWages, Icons.content_cut_rounded),
      'txn' => (AppTheme.cWithdrawals, Icons.swap_horiz_rounded),
      _ => (AppTheme.cExpenses, Icons.receipt_long_rounded),
    };

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 19,
        backgroundColor: color.withValues(alpha: 0.14),
        child: Icon(icon, size: 19, color: color),
      ),
      title: Text(op.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${op.subtitle} • ${Fmt.date(op.date)} • ${op.refNo}',
          maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(
        Fmt.money(op.amount, currency),
        style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 13.5),
      ),
    );
  }
}
