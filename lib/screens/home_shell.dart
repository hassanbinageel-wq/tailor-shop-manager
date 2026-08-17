import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/dashboard_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/person_provider.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';
import 'dashboard/dashboard_screen.dart';
import 'expenses/expenses_screen.dart';
import 'lock/lock_screen.dart';
import 'persons/team_screen.dart';
import 'reports/reports_screen.dart';
import 'settings/settings_screen.dart';

/// الهيكل الرئيسي مع شريط التنقل السفلي
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  /// الأقسام المحمية بكلمة المرور (حسب رقم التبويب)
  static const Map<int, String> _protected = {
    2: 'المصروفات',
    3: 'التقارير',
    4: 'الإعدادات',
  };

  late final List<Widget> _pages = [
    DashboardScreen(onNavigate: goTo),
    const TeamScreen(),
    const ExpensesScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkReminders());
  }

  Future<void> _checkReminders() async {
    final notifier = NotificationService.instance;
    await notifier.init();
    await notifier.checkSalaryReminder();
    await notifier.checkBackupReminder();

    if (!mounted) return;
    final dash = context.read<DashboardProvider>();
    final settings = context.read<SettingsProvider>();
    await notifier.checkExpenseAlert(dash.monthExpenses, settings.currency);
  }

  Future<void> goTo(int index) async {
    if (index == _index) return;

    final section = _protected[index];
    if (section != null) {
      final allowed = await LockGate.guard(context, sectionName: section);
      if (!allowed) return;
    }

    if (!mounted) return;
    setState(() => _index = index);
    _refreshFor(index);
  }

  void _refreshFor(int index) {
    switch (index) {
      case 0:
        context.read<DashboardProvider>().load();
      case 1:
        context.read<PersonProvider>().loadAll();
      case 2:
        context.read<ExpenseProvider>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _index != 0) setState(() => _index = 0);
      },
      child: Scaffold(
        body: IndexedStack(index: _index, children: _pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: goTo,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups_rounded),
              label: 'الفريق',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'المصروفات',
            ),
            NavigationDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon: Icon(Icons.description_rounded),
              label: 'التقارير',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'الإعدادات',
            ),
          ],
        ),
      ),
    );
  }
}
