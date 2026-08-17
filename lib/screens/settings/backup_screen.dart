import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;

import '../../core/utils/formatters.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/person_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/backup_service.dart';
import '../../widgets/common.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _service = BackupService();
  List<FileSystemEntity> _backups = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final list = await _service.listBackups();
    if (!mounted) return;
    setState(() => _backups = list);
  }

  Future<void> _reloadAll() async {
    if (!mounted) return;
    await context.read<SettingsProvider>().load();
    if (!mounted) return;
    await context.read<PersonProvider>().loadAll();
    if (!mounted) return;
    await context.read<ExpenseProvider>().load();
    if (!mounted) return;
    await context.read<DashboardProvider>().load();
  }

  Future<void> _run(Future<BackupResult> Function() action,
      {bool reload = false}) async {
    setState(() => _busy = true);
    final res = await action();
    if (!mounted) return;
    setState(() => _busy = false);

    showSnack(context, res.message, error: !res.success);
    if (res.success) {
      await _refresh();
      if (reload) await _reloadAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('النسخ الاحتياطي')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          if (_busy) const LinearProgressIndicator(minHeight: 2),

          if (settings.lastBackupAt != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.schedule_rounded),
                title: const Text('آخر نسخة احتياطية'),
                subtitle: Text(Fmt.dateTime(settings.lastBackupAt!)),
              ),
            ),

          const SectionHeader(title: 'إنشاء نسخة', icon: Icons.backup_rounded),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.save_rounded),
                  title: const Text('إنشاء نسخة احتياطية'),
                  subtitle: const Text('حفظ داخل مجلد التطبيق'),
                  onTap: _busy
                      ? null
                      : () async {
                          await _run(() => _service.createBackup());
                          if (mounted) {
                            await context
                                .read<SettingsProvider>()
                                .markBackupDone();
                          }
                        },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.folder_open_rounded),
                  title: const Text('اختيار مكان الحفظ'),
                  subtitle: const Text('حدد مجلداً على جهازك'),
                  onTap: _busy
                      ? null
                      : () async {
                          final dir = await _service.pickDirectory();
                          if (dir == null) return;
                          await _run(
                              () => _service.createBackup(targetDirectory: dir));
                          if (mounted) {
                            await context
                                .read<SettingsProvider>()
                                .markBackupDone();
                          }
                        },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.storage_rounded),
                  title: const Text('تصدير قاعدة البيانات إلى ملف'),
                  subtitle: const Text('نسخة خام من ملف قاعدة البيانات'),
                  onTap: _busy ? null : () => _run(_service.exportDatabaseFile),
                ),
              ],
            ),
          ),

          const SectionHeader(
              title: 'الاستعادة', icon: Icons.settings_backup_restore_rounded),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.restore_rounded),
                  title: const Text('استعادة نسخة احتياطية'),
                  subtitle: const Text('اختر ملف نسخة (JSON)'),
                  onTap: _busy
                      ? null
                      : () async {
                          final ok = await confirmDialog(
                            context,
                            title: 'استعادة نسخة',
                            message:
                                'سيتم استبدال جميع البيانات الحالية ببيانات النسخة. هل تريد المتابعة؟',
                            confirmLabel: 'استعادة',
                          );
                          if (ok) {
                            await _run(_service.pickAndRestore, reload: true);
                          }
                        },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.upload_file_rounded),
                  title: const Text('استيراد قاعدة البيانات من ملف'),
                  subtitle: const Text('استبدال ملف قاعدة البيانات كاملاً'),
                  onTap: _busy
                      ? null
                      : () async {
                          final ok = await confirmDialog(
                            context,
                            title: 'استيراد قاعدة البيانات',
                            message:
                                'سيتم استبدال قاعدة البيانات الحالية بالكامل. هل تريد المتابعة؟',
                            confirmLabel: 'استيراد',
                          );
                          if (ok) {
                            await _run(_service.importDatabaseFile, reload: true);
                          }
                        },
                ),
              ],
            ),
          ),

          SectionHeader(
            title: 'النسخ المحفوظة (${_backups.length})',
            icon: Icons.folder_rounded,
            trailing: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _refresh,
            ),
          ),
          if (_backups.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: EmptyState(
                icon: Icons.folder_off_rounded,
                title: 'لا توجد نسخ محفوظة',
                message: 'أنشئ نسخة احتياطية لحماية بياناتك',
              ),
            )
          else
            Card(
              child: Column(
                children: _backups.map((f) {
                  final stat = f.statSync();
                  final sizeKb = (stat.size / 1024).toStringAsFixed(1);
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.insert_drive_file_rounded),
                    title: Text(p.basename(f.path),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle:
                        Text('${Fmt.dateTime(stat.modified)} • $sizeKb KB'),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, size: 20),
                      onSelected: (v) async {
                        switch (v) {
                          case 'restore':
                            final ok = await confirmDialog(
                              context,
                              title: 'استعادة النسخة',
                              message:
                                  'سيتم استبدال جميع البيانات الحالية. هل تريد المتابعة؟',
                              confirmLabel: 'استعادة',
                            );
                            if (ok) {
                              await _run(
                                  () => _service.restoreFromFile(f.path),
                                  reload: true);
                            }
                          case 'share':
                            await _service.shareBackup(f.path);
                          case 'delete':
                            final ok = await confirmDialog(
                              context,
                              title: 'حذف النسخة',
                              message: 'سيتم حذف هذا الملف نهائياً.',
                            );
                            if (ok) {
                              await _service.deleteBackup(f.path);
                              await _refresh();
                            }
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'restore',
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.restore_rounded),
                            title: Text('استعادة'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'share',
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.share_rounded),
                            title: Text('مشاركة'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            dense: true,
                            leading:
                                Icon(Icons.delete_rounded, color: Colors.red),
                            title: Text('حذف',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
