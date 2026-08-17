import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/constants/app_info.dart';
import '../repositories/settings_repository.dart';

/// خدمة التذكيرات والتنبيهات المحلية
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final SettingsRepository _settings = SettingsRepository();
  bool _ready = false;

  static const AndroidNotificationDetails _android = AndroidNotificationDetails(
    'tsm_reminders',
    'التذكيرات',
    channelDescription: 'تذكيرات الرواتب والنسخ الاحتياطي وتنبيهات المصروفات',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  static const NotificationDetails _details = NotificationDetails(android: _android);

  Future<void> init() async {
    if (_ready) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    try {
      await _plugin.initialize(settings);
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  Future<void> _show(int id, String title, String body) async {
    if (!_ready) await init();
    if (!_ready) return;
    try {
      await _plugin.show(id, title, body, _details);
    } catch (_) {}
  }

  /// تذكير بصرف الرواتب (يُفحص عند فتح التطبيق قرب نهاية الشهر)
  Future<void> checkSalaryReminder() async {
    if ((await _settings.get(SettingKeys.notifySalary)) != '1') return;
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    if (now.day >= lastDay - 2) {
      await _show(101, 'تذكير بصرف الرواتب',
          'اقترب نهاية الشهر — لا تنسَ صرف رواتب العاملين ومراجعة المستحقات.');
    }
  }

  /// تذكير بالنسخ الاحتياطي إذا مرّ أكثر من 7 أيام
  Future<void> checkBackupReminder() async {
    if ((await _settings.get(SettingKeys.notifyBackup)) != '1') return;
    final last = await _settings.get(SettingKeys.lastBackupAt);
    final lastMs = int.tryParse(last ?? '') ?? 0;
    final days = lastMs == 0
        ? 999
        : DateTime.now()
            .difference(DateTime.fromMillisecondsSinceEpoch(lastMs))
            .inDays;
    if (days >= 7) {
      await _show(102, 'تذكير بالنسخ الاحتياطي',
          'لم يتم إنشاء نسخة احتياطية منذ فترة. أنشئ نسخة الآن لحماية بياناتك.');
    }
  }

  /// تنبيه عند تجاوز المصروفات الحد المحدد
  Future<void> checkExpenseAlert(double monthTotal, String currency) async {
    if ((await _settings.get(SettingKeys.notifyExpenseAlert)) != '1') return;
    final threshold =
        double.tryParse(await _settings.get(SettingKeys.expenseThreshold) ?? '0') ?? 0;
    if (threshold > 0 && monthTotal > threshold) {
      await _show(103, 'تنبيه: ارتفاع المصروفات',
          'تجاوزت مصروفات هذا الشهر الحد المحدد ($threshold $currency).');
    }
  }

  /// تنبيه بالعمليات غير المكتملة (بيانات ناقصة)
  Future<void> notifyIncomplete(int count) async {
    if (count <= 0) return;
    await _show(104, 'عمليات غير مكتملة',
        'يوجد $count عملية بحاجة إلى مراجعة أو استكمال بيانات.');
  }
}
