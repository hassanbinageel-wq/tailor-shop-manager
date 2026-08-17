import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/enums.dart';
import '../../models/expense.dart';
import '../../models/person.dart';
import '../../providers/settings_provider.dart';
import '../../repositories/expense_repository.dart';
import '../../repositories/person_repository.dart';
import '../../repositories/txn_repository.dart';
import '../../repositories/work_repository.dart';
import '../../widgets/common.dart';
import '../persons/person_detail_screen.dart';

/// بحث سريع في جميع الأقسام: الاسم، التاريخ، المبلغ، رقم الجوال
class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final PersonRepository _persons = PersonRepository();
  final WorkRepository _work = WorkRepository();
  final TxnRepository _txns = TxnRepository();
  final ExpenseRepository _expenses = ExpenseRepository();

  List<Person> _personResults = [];
  List<Map<String, Object?>> _workResults = [];
  List<Map<String, Object?>> _txnResults = [];
  List<Expense> _expenseResults = [];
  bool _busy = false;
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    setState(() {
      _query = q;
      _busy = q.trim().isNotEmpty;
    });
    if (q.trim().isEmpty) {
      setState(() {
        _personResults = [];
        _workResults = [];
        _txnResults = [];
        _expenseResults = [];
        _busy = false;
      });
      return;
    }

    final p = await _persons.search(q);
    final w = await _work.search(q);
    final t = await _txns.search(q);
    final e = await _expenses.getAll(query: q);

    if (!mounted) return;
    setState(() {
      _personResults = p;
      _workResults = w;
      _txnResults = t;
      _expenseResults = e;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<SettingsProvider>().currency;
    final hasResults = _personResults.isNotEmpty ||
        _workResults.isNotEmpty ||
        _txnResults.isNotEmpty ||
        _expenseResults.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('البحث')),
      body: Column(
        children: [
          AppSearchField(
            controller: _controller,
            hint: 'ابحث بالاسم، رقم الجوال، المبلغ، أو الرقم المرجعي...',
            onChanged: _search,
          ),
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _query.trim().isEmpty
                ? const EmptyState(
                    icon: Icons.search_rounded,
                    title: 'ابحث في كل الأقسام',
                    message:
                        'يمكنك البحث بالاسم، التاريخ، المبلغ، أو رقم الجوال داخل الخياطين والقصاصين والعاملين والمصروفات',
                  )
                : !hasResults && !_busy
                    ? const EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'لا توجد نتائج',
                        message: 'جرّب كلمات بحث أخرى',
                      )
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          if (_personResults.isNotEmpty) ...[
                            SectionHeader(
                              title: 'الأشخاص (${_personResults.length})',
                              icon: Icons.people_rounded,
                            ),
                            Card(
                              child: Column(
                                children: _personResults
                                    .map((p) => ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: personColor(p.type)
                                                .withValues(alpha: 0.15),
                                            child: Icon(personIcon(p.type),
                                                size: 19,
                                                color: personColor(p.type)),
                                          ),
                                          title: Text(p.name),
                                          subtitle: Text([
                                            p.type.label,
                                            if (p.phone != null &&
                                                p.phone!.isNotEmpty)
                                              p.phone!,
                                            p.refNo,
                                          ].join(' • ')),
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  PersonDetailScreen(person: p),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ],

                          if (_workResults.isNotEmpty) ...[
                            SectionHeader(
                              title: 'عمليات العمل (${_workResults.length})',
                              icon: Icons.content_cut_rounded,
                            ),
                            Card(
                              child: Column(
                                children: _workResults.map((r) {
                                  final date = DateTime.fromMillisecondsSinceEpoch(
                                      (r['date'] as int?) ?? 0);
                                  return ListTile(
                                    dense: true,
                                    leading: const CircleAvatar(
                                      backgroundColor: Color(0x222E7D32),
                                      child: Icon(Icons.content_cut_rounded,
                                          size: 18, color: AppTheme.cWages),
                                    ),
                                    title: Text(
                                        (r['person_name'] as String?) ?? '-'),
                                    subtitle: Text(
                                        '${Fmt.date(date)} • ${r['ref_no']}'),
                                    trailing: Text(
                                      Fmt.money(
                                          (r['total'] as num?)?.toDouble() ?? 0,
                                          currency),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.cWages,
                                          fontSize: 13),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],

                          if (_txnResults.isNotEmpty) ...[
                            SectionHeader(
                              title: 'الحركات المالية (${_txnResults.length})',
                              icon: Icons.swap_horiz_rounded,
                            ),
                            Card(
                              child: Column(
                                children: _txnResults.map((r) {
                                  final date = DateTime.fromMillisecondsSinceEpoch(
                                      (r['date'] as int?) ?? 0);
                                  final kind = TxnKindX.fromCode(
                                      (r['kind'] as String?) ?? '');
                                  return ListTile(
                                    dense: true,
                                    leading: const CircleAvatar(
                                      backgroundColor: Color(0x22EF6C00),
                                      child: Icon(Icons.swap_horiz_rounded,
                                          size: 18, color: AppTheme.cWithdrawals),
                                    ),
                                    title: Text(
                                        (r['person_name'] as String?) ?? '-'),
                                    subtitle: Text(
                                        '${kind.label} • ${Fmt.date(date)} • ${r['ref_no']}'),
                                    trailing: Text(
                                      Fmt.money(
                                          (r['amount'] as num?)?.toDouble() ?? 0,
                                          currency),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.cWithdrawals,
                                          fontSize: 13),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],

                          if (_expenseResults.isNotEmpty) ...[
                            SectionHeader(
                              title: 'المصروفات (${_expenseResults.length})',
                              icon: Icons.receipt_long_rounded,
                            ),
                            Card(
                              child: Column(
                                children: _expenseResults.map((e) {
                                  return ListTile(
                                    dense: true,
                                    leading: const CircleAvatar(
                                      backgroundColor: Color(0x22C62828),
                                      child: Icon(Icons.receipt_long_rounded,
                                          size: 18, color: AppTheme.cExpenses),
                                    ),
                                    title: Text(e.category),
                                    subtitle: Text(
                                        '${Fmt.date(e.date)} • ${e.description ?? '-'} • ${e.refNo}'),
                                    trailing: Text(
                                      Fmt.money(e.amount, currency),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.cExpenses,
                                          fontSize: 13),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
