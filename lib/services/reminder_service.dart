import 'package:flutter/material.dart';

import '../core/constants/app_info.dart';
import '../core/utils/formatters.dart';
import '../repositories/settings_repository.dart';

enum ReminderKind { salary, backup, expenses }

/// تنبيه يُعرض داخل التطبيق
class AppReminder {
  final ReminderKind kind;
  final String title;
  final String message;
  final IconData icon;
  final Color color;

  const AppReminder({
    required this.kind,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });
}

/// خدمة التذكيرات — تُفحص عند فتح التطبيق وتُعرض كبطاقات في لوحة التحكم
class ReminderService {
  final SettingsRepository _settings = SettingsRepository();

  Future<List<AppReminder>> pending({
    required double monthExpenses,
    required String currency,
  }) async {
    final all = await _settings.getAll();
    final out = <AppReminder>[];

    // تذكير بصرف الرواتب قرب نهاية الشهر
    if ((all[SettingKeys.notifySalary] ?? '1') == '1') {
      final now = DateTime.now();
      final lastDay = DateTime(now.year, now.month + 1, 0).day;
      if (now.day >= lastDay - 2) {
        out.add(const AppReminder(
          kind: ReminderKind.salary,
          title: 'تذكير بصرف الرواتب',
          message:
              'اقترب نهاية الشهر — راجع مستحقات العاملين وصرف الرواتب.',
          icon: Icons.payments_rounded,
          color: Color(0xFF2E7D32),
        ));
      }
    }

    // تذكير بالنسخ الاحتياطي
    if ((all[SettingKeys.notifyBackup] ?? '1') == '1') {
      final lastMs = int.tryParse(all[SettingKeys.lastBackupAt] ?? '') ?? 0;
      final days = lastMs == 0
          ? -1
          : DateTime.now()
              .difference(DateTime.fromMillisecondsSinceEpoch(lastMs))
              .inDays;
      if (days < 0) {
        out.add(const AppReminder(
          kind: ReminderKind.backup,
          title: 'لم تنشئ نسخة احتياطية بعد',
          message: 'أنشئ نسخة من الإعدادات لحماية بياناتك من الفقدان.',
          icon: Icons.backup_rounded,
          color: Color(0xFF1565C0),
        ));
      } else if (days >= 7) {
        out.add(AppReminder(
          kind: ReminderKind.backup,
          title: 'تذكير بالنسخ الاحتياطي',
          message: 'مرّ $days يوماً على آخر نسخة احتياطية.',
          icon: Icons.backup_rounded,
          color: const Color(0xFF1565C0),
        ));
      }
    }

    // تنبيه عند تجاوز المصروفات الحد المحدد
    if ((all[SettingKeys.notifyExpenseAlert] ?? '0') == '1') {
      final threshold =
          double.tryParse(all[SettingKeys.expenseThreshold] ?? '0') ?? 0;
      if (threshold > 0 && monthExpenses > threshold) {
        out.add(AppReminder(
          kind: ReminderKind.expenses,
          title: 'ارتفاع المصروفات',
          message:
              'مصروفات هذا الشهر ${Fmt.money(monthExpenses, currency)} '
              'تجاوزت الحد المحدد ${Fmt.money(threshold, currency)}.',
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFC62828),
        ));
      }
    }

    return out;
  }
}
