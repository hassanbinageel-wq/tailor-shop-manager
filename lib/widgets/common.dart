import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../core/utils/period.dart';
import '../models/enums.dart';

/// بطاقة إحصائية صغيرة للوحة التحكم
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!,
                    style: TextStyle(
                        fontSize: 11, color: scheme.onSurfaceVariant)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// عنوان قسم
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.icon, this.trailing});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 19, color: scheme.primary),
            const SizedBox(width: 7),
          ],
          Expanded(
            child: Text(title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// حالة فارغة
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 46, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.5, color: scheme.onSurfaceVariant)),
            ],
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}

/// حوار تأكيد الحذف
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'حذف',
  String cancelLabel = 'إلغاء',
  bool danger = true,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(danger ? Icons.warning_amber_rounded : Icons.help_outline_rounded,
          color: danger ? scheme.error : scheme.primary, size: 34),
      title: Text(title, textAlign: TextAlign.center),
      content: Text(message, textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: danger
              ? FilledButton.styleFrom(backgroundColor: scheme.error)
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return res ?? false;
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  final scheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? scheme.error : null,
      duration: const Duration(seconds: 2),
    ));
}

/// حقل نصي موحّد
class AppField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool required;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? formatters;
  final void Function(String)? onChanged;
  final String? suffixText;
  final bool enabled;

  const AppField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.required = false,
    this.validator,
    this.formatters,
    this.onChanged,
    this.suffixText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        enabled: enabled,
        inputFormatters: formatters,
        onChanged: onChanged,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: hint,
          prefixIcon: icon == null ? null : Icon(icon),
          suffixText: suffixText,
        ),
        validator: validator ??
            (required
                ? (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null
                : null),
      ),
    );
  }
}

/// حقل رقمي للمبالغ
class AmountField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String currency;
  final bool required;
  final IconData icon;
  final void Function(String)? onChanged;

  const AmountField({
    super.key,
    required this.controller,
    required this.label,
    required this.currency,
    this.required = true,
    this.icon = Icons.payments_rounded,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppField(
      controller: controller,
      label: label,
      icon: icon,
      required: required,
      suffixText: currency,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      onChanged: onChanged,
      validator: (v) {
        if (!required && (v == null || v.trim().isEmpty)) return null;
        if (v == null || v.trim().isEmpty) return 'هذا الحقل مطلوب';
        final n = double.tryParse(v.trim());
        if (n == null) return 'أدخل رقماً صحيحاً';
        if (n < 0) return 'لا يمكن أن يكون سالباً';
        return null;
      },
    );
  }
}

/// منتقي تاريخ
class DateField extends StatelessWidget {
  final DateTime value;
  final String label;
  final ValueChanged<DateTime> onChanged;

  const DateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'التاريخ',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value,
            firstDate: DateTime(2015),
            lastDate: DateTime(2100),
            locale: const Locale('ar'),
          );
          if (picked != null) onChanged(picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.calendar_today_rounded),
          ),
          child: Text(
            '${Fmt.date(value)}  •  ${Fmt.dayName(value)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

/// شريط فلترة الفترات الزمنية
class PeriodFilterBar extends StatelessWidget {
  final PeriodType selected;
  final DateTime? customStart;
  final DateTime? customEnd;
  final void Function(PeriodType type, DateTime? start, DateTime? end) onChanged;
  final bool showAll;

  const PeriodFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
    this.customStart,
    this.customEnd,
    this.showAll = true,
  });

  @override
  Widget build(BuildContext context) {
    final types = [
      PeriodType.today,
      PeriodType.week,
      PeriodType.month,
      PeriodType.year,
      if (showAll) PeriodType.all,
      PeriodType.custom,
    ];

    return Column(
      children: [
        SizedBox(
          height: 46,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: types.length,
            separatorBuilder: (_, __) => const SizedBox(width: 7),
            itemBuilder: (ctx, i) {
              final t = types[i];
              return Center(
                child: ChoiceChip(
                  label: Text(t.label),
                  selected: selected == t,
                  onSelected: (_) async {
                    if (t == PeriodType.custom) {
                      final r = await showDateRangePicker(
                        context: ctx,
                        firstDate: DateTime(2015),
                        lastDate: DateTime(2100),
                        locale: const Locale('ar'),
                        initialDateRange: (customStart != null && customEnd != null)
                            ? DateTimeRange(start: customStart!, end: customEnd!)
                            : null,
                        helpText: 'اختر الفترة الزمنية',
                        saveText: 'تم',
                      );
                      if (r != null) onChanged(PeriodType.custom, r.start, r.end);
                    } else {
                      onChanged(t, null, null);
                    }
                  },
                ),
              );
            },
          ),
        ),
        if (selected == PeriodType.custom && customStart != null && customEnd != null)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 4),
            child: Text(
              'من ${Fmt.date(customStart!)} إلى ${Fmt.date(customEnd!)}',
              style: TextStyle(
                  fontSize: 12.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}

/// حقل بحث
class AppSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  const AppSearchField({
    super.key,
    required this.onChanged,
    this.hint = 'بحث...',
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }
}

/// صف في ملخص المجاميع
class SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool bold;
  final IconData? icon;

  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.bold = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 17, color: color ?? scheme.onSurfaceVariant),
            const SizedBox(width: 7),
          ],
          Expanded(
            child: Text(label,
                style: TextStyle(
                  fontSize: bold ? 15.5 : 14,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                )),
          ),
          Text(value,
              style: TextStyle(
                fontSize: bold ? 17 : 14.5,
                fontWeight: FontWeight.w800,
                color: color ?? scheme.onSurface,
              )),
        ],
      ),
    );
  }
}

/// بطاقة المجاميع أسفل الصفحات
class SummaryPanel extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SummaryPanel({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            color: scheme.primaryContainer.withValues(alpha: 0.55),
            child: Row(
              children: [
                Icon(Icons.summarize_rounded, size: 19, color: scheme.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: scheme.onPrimaryContainer)),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

/// شارة ملوّنة صغيرة
class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const Pill({super.key, required this.text, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(text,
              style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

/// لون حسب نوع الشخص
Color personColor(PersonType type) => switch (type) {
      PersonType.tailor => AppTheme.cTailor,
      PersonType.cutter => AppTheme.cCutter,
      PersonType.worker => AppTheme.cWorker,
    };

IconData personIcon(PersonType type) => switch (type) {
      PersonType.tailor => Icons.content_cut_rounded,
      PersonType.cutter => Icons.straighten_rounded,
      PersonType.worker => Icons.badge_rounded,
    };

/// وصف الفترة كنص
String periodLabelOf(PeriodType type, DateRange range) {
  if (type == PeriodType.all) return 'كل الفترات';
  if (type == PeriodType.today) return Fmt.dateWithDay(range.start);
  return 'من ${Fmt.date(range.start)} إلى ${Fmt.date(range.end)}';
}

/// أول حرف من الاسم لعرضه في الصورة الرمزية
String _initialOf(String name) {
  final t = name.trim();
  return t.isEmpty ? '؟' : t.substring(0, 1);
}

String initialOf(String name) => _initialOf(name);
