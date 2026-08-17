import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_info.dart';
import '../../models/enums.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common.dart';
import '../lock/lock_screen.dart';
import '../logs/activity_log_screen.dart';
import 'about_screen.dart';
import 'archive_screen.dart';
import 'backup_screen.dart';
import 'notifications_screen.dart';
import 'security_screen.dart';
import 'shop_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          // ---------- بيانات المحل ----------
          const SectionHeader(title: 'المحل', icon: Icons.storefront_rounded),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.storefront_rounded),
                  title: const Text('تخصيص التقارير والفواتير'),
                  subtitle: Text(settings.shop.shopName),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ShopProfileScreen()),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.attach_money_rounded),
                  title: const Text('العملة'),
                  subtitle: Text(settings.currency),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () => _pickCurrency(context, settings),
                ),
              ],
            ),
          ),

          // ---------- المظهر ----------
          const SectionHeader(title: 'المظهر', icon: Icons.palette_rounded),
          Card(
            child: Column(
              children: AppThemeMode.values.map((m) {
                final selected = settings.themeMode == m;
                return ListTile(
                  onTap: () => settings.setThemeMode(m),
                  leading: Icon(switch (m) {
                    AppThemeMode.light => Icons.light_mode_rounded,
                    AppThemeMode.dark => Icons.dark_mode_rounded,
                    AppThemeMode.system => Icons.brightness_auto_rounded,
                  }),
                  title: Text(m.label),
                  trailing: selected
                      ? Icon(Icons.check_circle_rounded,
                          color: Theme.of(context).colorScheme.primary)
                      : const Icon(Icons.circle_outlined),
                );
              }).toList(),
            ),
          ),

          // ---------- البيانات والحماية ----------
          const SectionHeader(
              title: 'البيانات والحماية', icon: Icons.shield_rounded),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.backup_rounded),
                  title: const Text('النسخ الاحتياطي'),
                  subtitle: const Text('إنشاء واستعادة نسخة من بياناتك'),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () async {
                    if (await LockGate.guard(context,
                        sectionName: 'النسخ الاحتياطي')) {
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const BackupScreen()),
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.lock_rounded),
                  title: const Text('كلمة المرور'),
                  subtitle: Text(settings.lockEnabled
                      ? 'الحماية مفعّلة (${settings.pinLength} أرقام)'
                      : 'الحماية معطّلة'),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SecurityScreen()),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.archive_rounded),
                  title: const Text('الأرشيف وتصفير البيانات'),
                  subtitle: const Text('أرشفة حسب السنوات وتصفير شهر معين'),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () async {
                    if (await LockGate.guard(context, sectionName: 'الأرشيف')) {
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ArchiveScreen()),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),

          // ---------- الإشعارات والسجل ----------
          const SectionHeader(
              title: 'الإشعارات والسجل', icon: Icons.notifications_rounded),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_active_rounded),
                  title: const Text('التذكيرات والتنبيهات'),
                  subtitle: const Text('الرواتب، النسخ الاحتياطي، المصروفات'),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen()),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.history_rounded),
                  title: const Text('سجل النشاط'),
                  subtitle: const Text('كل العمليات التي تمت في التطبيق'),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ActivityLogScreen()),
                  ),
                ),
              ],
            ),
          ),

          // ---------- حول ----------
          const SectionHeader(title: 'أخرى', icon: Icons.info_rounded),
          Card(
            child: Column(
              children: [
                if (settings.lockEnabled)
                  ListTile(
                    leading: const Icon(Icons.lock_clock_rounded),
                    title: const Text('قفل الجلسة الآن'),
                    subtitle: const Text('سيُطلب إدخال كلمة المرور مجدداً'),
                    onTap: () {
                      settings.lockSession();
                      showSnack(context, 'تم قفل الجلسة');
                    },
                  ),
                if (settings.lockEnabled)
                  const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('حول التطبيق'),
                  subtitle: const Text('الإصدار ${AppInfo.version}'),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCurrency(
      BuildContext context, SettingsProvider settings) async {
    const options = ['ر.ي', 'ر.س', 'ر.ع', 'د.إ', 'ج.م', 'د.أ', 'د.ك', '\$', '€'];
    final custom = TextEditingController(text: settings.currency);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 6, 20, 12),
                child: Text('اختر العملة',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: options
                      .map((c) => ChoiceChip(
                            label: Text(c),
                            selected: settings.currency == c,
                            onSelected: (_) {
                              settings.setCurrency(c);
                              Navigator.pop(ctx);
                            },
                          ))
                      .toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: custom,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          labelText: 'عملة مخصصة',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: () {
                        final v = custom.text.trim();
                        if (v.isNotEmpty) settings.setCurrency(v);
                        Navigator.pop(ctx);
                      },
                      child: const Text('حفظ'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
