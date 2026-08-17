import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../models/enums.dart';
import '../../models/money_txn.dart';
import '../../models/person.dart';
import '../../models/work_entry.dart';
import '../../providers/person_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common.dart';

/// نافذة تسجيل/تعديل عملية عمل (عدد الأثواب × أجرة الثوب)
Future<void> showWorkEntrySheet(
  BuildContext context, {
  required Person person,
  WorkEntry? entry,
}) async {
  final detail = context.read<PersonDetailProvider>();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => ChangeNotifierProvider.value(
      value: detail,
      child: _WorkEntrySheet(person: person, entry: entry),
    ),
  );
}

class _WorkEntrySheet extends StatefulWidget {
  final Person person;
  final WorkEntry? entry;
  const _WorkEntrySheet({required this.person, this.entry});

  @override
  State<_WorkEntrySheet> createState() => _WorkEntrySheetState();
}

class _WorkEntrySheetState extends State<_WorkEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _qty;
  late final TextEditingController _price;
  late final TextEditingController _notes;
  late DateTime _date;
  bool _saving = false;

  bool get isEdit => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _qty = TextEditingController(text: e == null ? '1' : Fmt.num2(e.quantity));
    _price = TextEditingController(
      text: e != null
          ? Fmt.num2(e.unitPrice)
          : (widget.person.defaultUnitPrice > 0
              ? Fmt.num2(widget.person.defaultUnitPrice)
              : ''),
    );
    _notes = TextEditingController(text: e?.notes ?? '');
    _date = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _qty.dispose();
    _price.dispose();
    _notes.dispose();
    super.dispose();
  }

  double get _total => Fmt.parseNum(_qty.text) * Fmt.parseNum(_price.text);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final detail = context.read<PersonDetailProvider>();
    final e = WorkEntry(
      id: widget.entry?.id,
      refNo: widget.entry?.refNo ?? '',
      personId: widget.person.id!,
      personType: widget.person.type,
      date: _date,
      quantity: Fmt.parseNum(_qty.text),
      unitPrice: Fmt.parseNum(_price.text),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      createdAt: widget.entry?.createdAt ?? DateTime.now(),
    );

    if (isEdit) {
      await detail.updateWork(e);
    } else {
      await detail.addWork(e);
    }

    if (!mounted) return;
    Navigator.pop(context);
    showSnack(context, isEdit ? 'تم حفظ التعديلات' : 'تمت الإضافة بنجاح');
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<SettingsProvider>().currency;
    final scheme = Theme.of(context).colorScheme;
    final unit = widget.person.type.unitLabel;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEdit
                      ? 'تعديل العملية'
                      : 'تسجيل ${widget.person.type.unitPluralLabel}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(widget.person.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, color: scheme.onSurfaceVariant)),
                const SizedBox(height: 12),

                DateField(
                  value: _date,
                  onChanged: (d) => setState(() => _date = d),
                ),

                Row(
                  children: [
                    Expanded(
                      child: AppField(
                        controller: _qty,
                        label: 'عدد ${widget.person.type.unitPluralLabel}',
                        icon: Icons.numbers_rounded,
                        required: true,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        formatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                        ],
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          final n = double.tryParse(v?.trim() ?? '');
                          if (n == null || n <= 0) return 'أدخل عدداً صحيحاً';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AmountField(
                        controller: _price,
                        label: 'أجرة $unit',
                        currency: currency,
                        icon: Icons.local_offer_rounded,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.functions_rounded, color: scheme.primary),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('الإجمالي المحتسب',
                            style: TextStyle(
                                fontSize: 14.5, fontWeight: FontWeight.w700)),
                      ),
                      Text(Fmt.money(_total, currency),
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: scheme.primary)),
                    ],
                  ),
                ),

                AppField(
                  controller: _notes,
                  label: 'ملاحظات',
                  icon: Icons.notes_rounded,
                  maxLines: 3,
                ),

                const SizedBox(height: 14),
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
        ),
      ),
    );
  }
}

/// نافذة تسجيل/تعديل حركة مالية
Future<void> showTxnSheet(
  BuildContext context, {
  required Person person,
  required TxnKind kind,
  MoneyTxn? txn,
}) async {
  final detail = context.read<PersonDetailProvider>();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => ChangeNotifierProvider.value(
      value: detail,
      child: _TxnSheet(person: person, kind: kind, txn: txn),
    ),
  );
}

class _TxnSheet extends StatefulWidget {
  final Person person;
  final TxnKind kind;
  final MoneyTxn? txn;
  const _TxnSheet({required this.person, required this.kind, this.txn});

  @override
  State<_TxnSheet> createState() => _TxnSheetState();
}

class _TxnSheetState extends State<_TxnSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _notes;
  late DateTime _date;
  bool _saving = false;

  bool get isEdit => widget.txn != null;

  @override
  void initState() {
    super.initState();
    final t = widget.txn;
    _amount = TextEditingController(text: t == null ? '' : Fmt.num2(t.amount));
    _notes = TextEditingController(text: t?.notes ?? '');
    _date = t?.date ?? DateTime.now();

    // اقتراحات تلقائية
    if (t == null) {
      if (widget.kind == TxnKind.salary && widget.person.monthlySalary > 0) {
        _amount.text = Fmt.num2(widget.person.monthlySalary);
      }
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final detail = context.read<PersonDetailProvider>();
    final t = MoneyTxn(
      id: widget.txn?.id,
      refNo: widget.txn?.refNo ?? '',
      personId: widget.person.id!,
      personType: widget.person.type,
      kind: widget.kind,
      date: _date,
      amount: Fmt.parseNum(_amount.text),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      createdAt: widget.txn?.createdAt ?? DateTime.now(),
    );

    if (isEdit) {
      await detail.updateTxn(t);
    } else {
      await detail.addTxn(t);
    }

    if (!mounted) return;
    Navigator.pop(context);
    showSnack(context, isEdit ? 'تم حفظ التعديلات' : 'تمت الإضافة بنجاح');
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<SettingsProvider>().currency;
    final detail = context.watch<PersonDetailProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEdit ? 'تعديل ${widget.kind.label}' : 'إضافة ${widget.kind.label}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(widget.person.name,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
                const SizedBox(height: 12),

                DateField(value: _date, onChanged: (d) => setState(() => _date = d)),

                AmountField(
                  controller: _amount,
                  label: 'المبلغ',
                  currency: currency,
                ),

                if (widget.kind == TxnKind.commission &&
                    widget.person.hasCommission) ...[
                  const SizedBox(height: 4),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(
                        () => _amount.text = Fmt.num2(detail.autoCommission)),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              size: 18, color: scheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'النسبة المحتسبة تلقائياً '
                              '(${Fmt.percent(widget.person.commissionRate)}): '
                              '${Fmt.money(detail.autoCommission, currency)}',
                              style: const TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const Icon(Icons.touch_app_rounded, size: 17),
                        ],
                      ),
                    ),
                  ),
                ],

                AppField(
                  controller: _notes,
                  label: 'ملاحظات',
                  icon: Icons.notes_rounded,
                  maxLines: 3,
                ),

                const SizedBox(height: 14),
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
        ),
      ),
    );
  }
}
