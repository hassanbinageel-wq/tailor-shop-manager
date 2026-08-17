import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final TextEditingController _threshold;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsProvider>();
    _threshold = TextEditingController(
        text: s.expenseThreshold == 0 ? '' : Fmt.num2(s.expenseThreshold));
  }

  @override
  void dispose() {
    _threshold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('التذكيرات والتنبيهات')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: settings.notifySalary,
                  onChanged: settings.setNotifySalary,
                  secondary: const Icon(Icons.payments_rounded),
                  title: const Text('تذكير بصرف الرواتب'),
                  subtitle: const Text('تنبيه قرب نهاية كل شهر'),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  value: settings.notifyBackup,
                  onChanged: settings.setNotifyBackup,
                  secondary: const Icon(Icons.backup_rounded),
                  title: const Text('تذكير بالنسخ الاحتياطي'),
                  subtitle: const Text('عند مرور أكثر من 7 أيام'),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  value: settings.notifyExpenseAlert,
                  onChanged: settings.setNotifyExpenseAlert,
                  secondary: const Icon(Icons.warning_amber_rounded),
                  title: const Text('تنبيه عند زيادة المصروفات'),
                  subtitle: const Text('عند تجاوز الحد الشهري المحدد'),
                ),
              ],
            ),
          ),

          if (settings.notifyExpenseAlert) ...[
            const SectionHeader(
                title: 'حد المصروفات الشهري', icon: Icons.speed_rounded),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: AmountField(
                      controller: _threshold,
                      label: 'الحد الأقصى',
                      currency: settings.currency,
                      required: false,
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: () async {
                      await settings
                          .setExpenseThreshold(Fmt.parseNum(_threshold.text));
                      if (context.mounted) showSnack(context, 'تم الحفظ');
                    },
                    child: const Text('حفظ'),
                  ),
                ],
              ),
            ),
          ],

          Padding(
            padding: const EdgeInsets.all(22),
            child: Text(
              'تُفحص التذكيرات عند فتح التطبيق وتظهر كبطاقات في أعلى لوحة التحكم. لا يحتاج التطبيق إلى إنترنت ولا إلى أذونات إشعارات.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
