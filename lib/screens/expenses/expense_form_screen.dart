import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common.dart';

class ExpenseFormScreen extends StatefulWidget {
  final Expense? expense;
  const ExpenseFormScreen({super.key, this.expense});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _description;
  late final TextEditingController _notes;
  late DateTime _date;
  late String _category;
  bool _saving = false;

  bool get isEdit => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _amount = TextEditingController(text: e == null ? '' : Fmt.num2(e.amount));
    _description = TextEditingController(text: e?.description ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _date = e?.date ?? DateTime.now();
    _category = e?.category ?? ExpenseCategory.rent;
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final provider = context.read<ExpenseProvider>();
    final e = Expense(
      id: widget.expense?.id,
      refNo: widget.expense?.refNo ?? '',
      date: _date,
      amount: Fmt.parseNum(_amount.text),
      category: _category,
      description:
          _description.text.trim().isEmpty ? null : _description.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      createdAt: widget.expense?.createdAt ?? DateTime.now(),
    );

    if (isEdit) {
      await provider.update(e);
    } else {
      await provider.add(e);
    }

    if (!mounted) return;
    showSnack(context, isEdit ? 'تم حفظ التعديلات' : 'تمت الإضافة بنجاح');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<SettingsProvider>().currency;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'تعديل مصروف' : 'إضافة مصروف جديد')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            DateField(value: _date, onChanged: (d) => setState(() => _date = d)),

            AmountField(
              controller: _amount,
              label: 'المبلغ',
              currency: currency,
            ),

            const SizedBox(height: 8),
            Text('التصنيف',
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ExpenseCategory.all
                  .map((c) => ChoiceChip(
                        label: Text(c),
                        selected: _category == c,
                        onSelected: (_) => setState(() => _category = c),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),

            AppField(
              controller: _description,
              label: 'الوصف',
              icon: Icons.description_rounded,
              maxLines: 2,
            ),
            AppField(
              controller: _notes,
              label: 'الملاحظات',
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),

            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_rounded),
              label: Text(isEdit ? 'حفظ التعديلات' : 'حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}
