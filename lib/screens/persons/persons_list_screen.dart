import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../models/enums.dart';
import '../../models/person.dart';
import '../../providers/person_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common.dart';
import 'person_detail_screen.dart';
import 'person_form_screen.dart';

/// قائمة الخياطين / القصاصين / العاملين
class PersonsListScreen extends StatefulWidget {
  final PersonType type;
  final bool embedded;
  const PersonsListScreen(
      {super.key, required this.type, this.embedded = false});

  @override
  State<PersonsListScreen> createState() => _PersonsListScreenState();
}

class _PersonsListScreenState extends State<PersonsListScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _search = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PersonProvider>().load(widget.type);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openForm({Person? person}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PersonFormScreen(type: widget.type, person: person),
      ),
    );
    if (saved == true && mounted) {
      context.read<PersonProvider>().load(widget.type);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.watch<PersonProvider>();
    final settings = context.watch<SettingsProvider>();
    final items = provider.list(widget.type);
    final color = personColor(widget.type);

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(title: Text(widget.type.labelPlural)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text('إضافة ${widget.type.label}'),
      ),
      body: Column(
        children: [
          AppSearchField(
            controller: _search,
            hint: 'بحث بالاسم أو رقم الجوال...',
            onChanged: (q) => provider.setQuery(widget.type, q),
          ),
          if (provider.busy) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: items.isEmpty
                ? EmptyState(
                    icon: personIcon(widget.type),
                    title: 'لا يوجد ${widget.type.labelPlural.replaceAll('ال', '')}',
                    message: 'اضغط على زر الإضافة لتسجيل ${widget.type.label} جديد',
                    action: FilledButton.icon(
                      onPressed: () => _openForm(),
                      icon: const Icon(Icons.add_rounded),
                      label: Text('إضافة ${widget.type.label}'),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => provider.load(widget.type),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 90, top: 4),
                      itemCount: items.length,
                      itemBuilder: (ctx, i) => _PersonTile(
                        person: items[i],
                        color: color,
                        currency: settings.currency,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PersonDetailScreen(person: items[i]),
                            ),
                          );
                          if (mounted) provider.load(widget.type);
                        },
                        onEdit: () => _openForm(person: items[i]),
                        onPin: () => provider.togglePin(items[i]),
                        onArchive: () => provider.toggleArchive(items[i]),
                        onDelete: () async {
                          final ok = await confirmDialog(
                            context,
                            title: 'تأكيد الحذف',
                            message:
                                'سيتم حذف ${items[i].name} وجميع العمليات المرتبطة به نهائياً. هل أنت متأكد؟',
                          );
                          if (ok && context.mounted) {
                            await provider.remove(items[i]);
                            if (context.mounted) {
                              showSnack(context, 'تم الحذف بنجاح');
                            }
                          }
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  final Person person;
  final Color color;
  final String currency;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onPin;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const _PersonTile({
    required this.person,
    required this.color,
    required this.currency,
    required this.onTap,
    required this.onEdit,
    required this.onPin,
    required this.onArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitleParts = <String>[
      if (person.jobTitle != null && person.jobTitle!.isNotEmpty) person.jobTitle!,
      if (person.phone != null && person.phone!.isNotEmpty) person.phone!,
      person.refNo,
    ];

    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(
            initialOf(person.name),
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 19),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(person.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            if (person.isPinned) ...[
              const SizedBox(width: 6),
              Icon(Icons.push_pin_rounded, size: 15, color: scheme.primary),
            ],
            if (person.isArchived) ...[
              const SizedBox(width: 6),
              const Pill(text: 'مؤرشف', color: Colors.grey),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(subtitleParts.join('  •  '),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (person.type == PersonType.worker && person.monthlySalary > 0)
              Pill(
                text: Fmt.money(person.monthlySalary, currency),
                color: color,
                icon: Icons.payments_rounded,
              )
            else if (person.defaultUnitPrice > 0)
              Pill(
                text: Fmt.money(person.defaultUnitPrice, currency),
                color: color,
              ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (v) {
                switch (v) {
                  case 'edit':
                    onEdit();
                  case 'pin':
                    onPin();
                  case 'archive':
                    onArchive();
                  case 'delete':
                    onDelete();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.edit_rounded),
                    title: Text('تعديل'),
                  ),
                ),
                PopupMenuItem(
                  value: 'pin',
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.push_pin_rounded),
                    title: Text(person.isPinned ? 'إلغاء التثبيت' : 'تثبيت'),
                  ),
                ),
                PopupMenuItem(
                  value: 'archive',
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.archive_rounded),
                    title: Text(person.isArchived ? 'إلغاء الأرشفة' : 'أرشفة'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.delete_rounded, color: Colors.red),
                    title: Text('حذف', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
