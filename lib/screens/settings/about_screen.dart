import 'package:flutter/material.dart';

import '../../core/constants/app_info.dart';
import '../../widgets/common.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const List<(IconData, String)> _features = [
    (Icons.groups_rounded, 'إدارة الخياطين والقصاصين والعاملين'),
    (Icons.payments_rounded, 'احتساب الأجور والنسب تلقائياً'),
    (Icons.receipt_long_rounded, 'تسجيل المصروفات بتصنيفات جاهزة'),
    (Icons.picture_as_pdf_rounded, 'تقارير وفواتير PDF احترافية'),
    (Icons.bar_chart_rounded, 'إحصائيات ورسوم بيانية'),
    (Icons.backup_rounded, 'نسخ احتياطي واستعادة كاملة'),
    (Icons.lock_rounded, 'حماية الأقسام المالية بكلمة مرور'),
    (Icons.wifi_off_rounded, 'يعمل بالكامل بدون إنترنت'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('حول التطبيق')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Icon(Icons.content_cut_rounded,
                  size: 52, color: scheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(AppInfo.name,
                style:
                    const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text('الإصدار ${AppInfo.version}',
                style:
                    TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              AppInfo.description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, height: 1.7),
            ),
          ),

          const SectionHeader(title: 'المميزات', icon: Icons.star_rounded),
          Card(
            child: Column(
              children: _features
                  .map((f) => ListTile(
                        dense: true,
                        leading: Icon(f.$1, color: scheme.primary, size: 21),
                        title: Text(f.$2, style: const TextStyle(fontSize: 14)),
                      ))
                  .toList(),
            ),
          ),

          const SectionHeader(title: 'المطور', icon: Icons.code_rounded),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_rounded),
              title: const Text(AppInfo.developer),
              subtitle: const Text('جميع الحقوق محفوظة © 2026'),
            ),
          ),
        ],
      ),
    );
  }
}
