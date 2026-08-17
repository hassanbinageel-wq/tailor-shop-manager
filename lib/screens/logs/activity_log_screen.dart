import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../providers/log_provider.dart';
import '../../widgets/common.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LogProvider>().load();
    });
  }

  IconData _iconFor(String action) => switch (action) {
        'إضافة' => Icons.add_circle_rounded,
        'تعديل' => Icons.edit_rounded,
        'حذف' => Icons.delete_rounded,
        'أرشفة' => Icons.archive_rounded,
        'استعادة' => Icons.unarchive_rounded,
        _ => Icons.info_rounded,
      };

  Color _colorFor(String action) => switch (action) {
        'إضافة' => Colors.green,
        'تعديل' => Colors.blue,
        'حذف' => Colors.red,
        _ => Colors.orange,
      };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LogProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل النشاط'),
        actions: [
          IconButton(
            tooltip: 'مسح السجل',
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: () async {
              final ok = await confirmDialog(
                context,
                title: 'مسح سجل النشاط',
                message: 'سيتم حذف كل سجلات النشاط. البيانات الأخرى لن تتأثر.',
                confirmLabel: 'مسح',
              );
              if (ok && context.mounted) {
                await provider.clear();
                if (context.mounted) showSnack(context, 'تم مسح السجل');
              }
            },
          ),
        ],
      ),
      body: provider.busy
          ? const Center(child: CircularProgressIndicator())
          : provider.items.isEmpty
              ? const EmptyState(
                  icon: Icons.history_rounded,
                  title: 'السجل فارغ',
                  message: 'ستظهر هنا كل العمليات التي تتم داخل التطبيق',
                )
              : RefreshIndicator(
                  onRefresh: () => provider.load(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24, top: 6),
                    itemCount: provider.items.length,
                    itemBuilder: (ctx, i) {
                      final log = provider.items[i];
                      final color = _colorFor(log.action);
                      return Card(
                        child: ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 19,
                            backgroundColor: color.withValues(alpha: 0.13),
                            child: Icon(_iconFor(log.action),
                                size: 19, color: color),
                          ),
                          title: Text('${log.action} — ${log.entity}'),
                          subtitle: Text(
                              '${log.description}\n${Fmt.dateTime(log.timestamp)}'),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
