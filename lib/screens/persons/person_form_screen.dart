import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../models/enums.dart';
import '../../models/person.dart';
import '../../providers/person_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common.dart';

/// نموذج إضافة/تعديل خياط أو قصاص أو عامل
class PersonFormScreen extends StatefulWidget {
  final PersonType type;
  final Person? person;

  const PersonFormScreen({super.key, required this.type, this.person});

  @override
  State<PersonFormScreen> createState() => _PersonFormScreenState();
}

class _PersonFormScreenState extends State<PersonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _notes;
  late final TextEditingController _jobTitle;
  late final TextEditingController _salary;
  late final TextEditingController _rate;
  late final TextEditingController _unitPrice;

  bool _hasCommission = false;
  bool _saving = false;

  bool get isEdit => widget.person != null;

  @override
  void initState() {
    super.initState();
    final p = widget.person;
    _name = TextEditingController(text: p?.name ?? '');
    _phone = TextEditingController(text: p?.phone ?? '');
    _notes = TextEditingController(text: p?.notes ?? '');
    _jobTitle = TextEditingController(text: p?.jobTitle ?? '');
    _salary = TextEditingController(
        text: (p?.monthlySalary ?? 0) == 0 ? '' : Fmt.num2(p!.monthlySalary));
    _rate = TextEditingController(
        text: (p?.commissionRate ?? 0) == 0 ? '' : Fmt.num2(p!.commissionRate));
    _unitPrice = TextEditingController(
        text: (p?.defaultUnitPrice ?? 0) == 0 ? '' : Fmt.num2(p!.defaultUnitPrice));
    _hasCommission = p?.hasCommission ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _notes.dispose();
    _jobTitle.dispose();
    _salary.dispose();
    _rate.dispose();
    _unitPrice.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final provider = context.read<PersonProvider>();
    final person = Person(
      id: widget.person?.id,
      refNo: widget.person?.refNo ?? '',
      name: _name.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      type: widget.type,
      jobTitle: _jobTitle.text.trim().isEmpty ? null : _jobTitle.text.trim(),
      monthlySalary: Fmt.parseNum(_salary.text),
      hasCommission: _hasCommission,
      commissionRate: _hasCommission ? Fmt.parseNum(_rate.text) : 0,
      defaultUnitPrice: Fmt.parseNum(_unitPrice.text),
      isPinned: widget.person?.isPinned ?? false,
      isArchived: widget.person?.isArchived ?? false,
      createdAt: widget.person?.createdAt ?? DateTime.now(),
    );

    if (isEdit) {
      await provider.update(person);
    } else {
      await provider.add(person);
    }

    if (!mounted) return;
    showSnack(context, isEdit ? 'تم حفظ التعديلات' : 'تمت الإضافة بنجاح');
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<SettingsProvider>().currency;
    final isWorker = widget.type == PersonType.worker;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit
            ? 'تعديل بيانات ${widget.type.label}'
            : 'إضافة ${widget.type.label}'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            AppField(
              controller: _name,
              label: 'الاسم',
              icon: Icons.person_rounded,
              required: true,
            ),
            AppField(
              controller: _phone,
              label: 'رقم الجوال',
              hint: 'اختياري',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
              formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]'))],
            ),

            if (isWorker) ...[
              AppField(
                controller: _jobTitle,
                label: 'الوظيفة',
                icon: Icons.work_rounded,
                required: true,
              ),
              AmountField(
                controller: _salary,
                label: 'الراتب الشهري',
                currency: currency,
                required: false,
              ),
              const SizedBox(height: 6),
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      value: _hasCommission,
                      onChanged: (v) => setState(() => _hasCommission = v),
                      title: const Text('هل لديه نسبة؟'),
                      subtitle: Text(_hasCommission ? 'نعم' : 'لا'),
                      secondary: const Icon(Icons.percent_rounded),
                    ),
                    if (_hasCommission)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: AppField(
                          controller: _rate,
                          label: 'نسبة العامل',
                          icon: Icons.percent_rounded,
                          suffixText: '%',
                          required: true,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          formatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                          ],
                          validator: (v) {
                            final n = double.tryParse(v?.trim() ?? '');
                            if (n == null) return 'أدخل نسبة صحيحة';
                            if (n < 0 || n > 100) return 'النسبة بين 0 و 100';
                            return null;
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ] else
              AmountField(
                controller: _unitPrice,
                label: 'أجرة ${widget.type.unitLabel} (افتراضية)',
                currency: currency,
                required: false,
                icon: Icons.local_offer_rounded,
              ),

            AppField(
              controller: _notes,
              label: 'الملاحظات',
              icon: Icons.notes_rounded,
              maxLines: 4,
            ),

            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18, height: 18,
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
