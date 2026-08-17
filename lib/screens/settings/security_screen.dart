import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import '../../widgets/common.dart';
import '../lock/lock_screen.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  static const List<String> protectedSections = [
    'المصروفات',
    'التقارير',
    'الأرباح',
    'الأجور',
    'النسخ الاحتياطي',
    'إعدادات التطبيق',
  ];

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('حماية البيانات')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          Card(
            child: SwitchListTile(
              value: settings.lockEnabled,
              secondary: Icon(
                settings.lockEnabled
                    ? Icons.lock_rounded
                    : Icons.lock_open_rounded,
                color: settings.lockEnabled ? scheme.primary : null,
              ),
              title: const Text('تفعيل كلمة المرور للأمور المالية'),
              subtitle: Text(settings.lockEnabled
                  ? 'الحماية مفعّلة — ${settings.pinLength} أرقام'
                  : 'الحماية معطّلة'),
              onChanged: (v) async {
                if (v) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LockScreen(isSetup: true),
                    ),
                  );
                } else {
                  final confirmed = await _verifyCurrent(context);
                  if (confirmed && context.mounted) {
                    await settings.disableLock();
                    if (context.mounted) {
                      showSnack(context, 'تم تعطيل الحماية');
                    }
                  }
                }
              },
            ),
          ),

          if (settings.lockEnabled) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.password_rounded),
                title: const Text('تغيير كلمة المرور'),
                subtitle: const Text('اختر رقماً سرياً جديداً'),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () => _changePin(context),
              ),
            ),
          ],

          const SectionHeader(
              title: 'الأقسام المحمية', icon: Icons.shield_rounded),
          Card(
            child: Column(
              children: protectedSections
                  .map((s) => ListTile(
                        dense: true,
                        leading: Icon(
                          settings.lockEnabled
                              ? Icons.lock_rounded
                              : Icons.lock_open_rounded,
                          size: 19,
                          color: settings.lockEnabled
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                        title: Text(s),
                      ))
                  .toList(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(22),
            child: Text(
              'عند تفعيل الحماية سيُطلب إدخال كلمة المرور مرة واحدة عند الدخول إلى أي قسم مالي في كل تشغيل للتطبيق. يمكنك قفل الجلسة يدوياً من الإعدادات.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _verifyCurrent(BuildContext context) async {
    final controller = TextEditingController();
    final settings = context.read<SettingsProvider>();
    var obscure = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('تأكيد كلمة المرور'),
          content: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            autofocus: true,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 6),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'كلمة المرور الحالية',
              suffixIcon: IconButton(
                icon: Icon(obscure
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded),
                onPressed: () => setState(() => obscure = !obscure),
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء')),
            FilledButton(
              onPressed: () async {
                final ok = await settings.verifyPin(controller.text.trim());
                if (ctx.mounted) Navigator.pop(ctx, ok);
              },
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );

    if (result == false && context.mounted) {
      showSnack(context, 'كلمة المرور غير صحيحة', error: true);
    }
    return result ?? false;
  }

  Future<void> _changePin(BuildContext context) async {
    final ok = await _verifyCurrent(context);
    if (!ok || !context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LockScreen(isSetup: true)),
    );
    if (context.mounted) showSnack(context, 'تم تغيير كلمة المرور');
  }
}
