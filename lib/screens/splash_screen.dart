import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_info.dart';
import '../providers/dashboard_provider.dart';
import '../providers/person_provider.dart';
import '../providers/settings_provider.dart';
import 'home_shell.dart';

/// شاشة البداية — تحميل الإعدادات والبيانات الأولية
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    try {
      await context.read<SettingsProvider>().load();
      if (!mounted) return;
      await context.read<PersonProvider>().loadAll();
      if (!mounted) return;
      await context.read<DashboardProvider>().load();
      if (!mounted) return;

      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (_, a, __) =>
              FadeTransition(opacity: a, child: const HomeShell()),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(Icons.content_cut_rounded,
                    size: 60, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(height: 22),
              Text(AppInfo.name,
                  style: const TextStyle(
                      fontSize: 23, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('الإصدار ${AppInfo.version}',
                  style:
                      TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
              const SizedBox(height: 34),
              if (_error == null)
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.6),
                )
              else ...[
                Icon(Icons.error_outline_rounded, color: scheme.error, size: 34),
                const SizedBox(height: 10),
                Text('تعذّر بدء التطبيق\n$_error',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: scheme.error)),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () {
                    setState(() => _error = null);
                    _boot();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
