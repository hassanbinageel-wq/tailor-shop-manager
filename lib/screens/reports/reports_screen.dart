import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../models/person.dart';
import '../../providers/person_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/settings_provider.dart';
import '../../repositories/person_repository.dart';
import '../../widgets/common.dart';
import 'report_preview_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with AutomaticKeepAliveClientMixin {
  ReportKind _kind = ReportKind.monthly;
  PeriodType _period = PeriodType.month;
  DateTime? _start;
  DateTime? _end;
  Person? _person;
  List<Person> _persons = [];
  final TextEditingController _note = TextEditingController();
  bool _loading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _loadPersons() async {
    final type = _kind.personType;
    if (type == null) {
      setState(() {
        _persons = [];
        _person = null;
      });
      return;
    }
    final list = await PersonRepository().getByType(type, includeArchived: true);
    if (!mounted) return;
    setState(() {
      _persons = list;
      _person = list.isEmpty ? null : list.first;
    });
  }

  Future<void> _pickPerson() async {
    final chosen = await showModalBottomSheet<Person>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 6, 20, 10),
              child: Text('اختر الاسم',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _persons.length,
                itemBuilder: (c, i) {
                  final p = _persons[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          personColor(p.type).withValues(alpha: 0.15),
                      child: Icon(personIcon(p.type),
                          size: 19, color: personColor(p.type)),
                    ),
                    title: Text(p.name),
                    subtitle: Text([
                      if (p.phone != null && p.phone!.isNotEmpty) p.phone!,
                      p.refNo,
                    ].join(' • ')),
                    selected: _person?.id == p.id,
                    onTap: () => Navigator.pop(ctx, p),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
    if (chosen != null) setState(() => _person = chosen);
  }

  void _applyDefaultPeriod(ReportKind kind) {
    _period = switch (kind) {
      ReportKind.daily => PeriodType.today,
      ReportKind.weekly => PeriodType.week,
      ReportKind.monthly => PeriodType.month,
      ReportKind.yearly => PeriodType.year,
      _ => PeriodType.month,
    };
  }

  Future<void> _generate() async {
    if (_kind.needsPerson && _person == null) {
      showSnack(context, 'اختر ${_kind.personType!.label} أولاً', error: true);
      return;
    }

    setState(() => _loading = true);
    final reports = context.read<ReportProvider>();
    final settings = context.read<SettingsProvider>();

    final data = await reports.build(
      kind: _kind,
      periodType: _period,
      currency: settings.currency,
      customStart: _start,
      customEnd: _end,
      person: _person,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReportPreviewScreen(data: data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    context.watch<PersonProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('التقارير')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const SectionHeader(
              title: 'اختر نوع التقرير', icon: Icons.description_rounded),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.05,
              children: ReportKind.values.map((k) {
                final selected = _kind == k;
                final scheme = Theme.of(context).colorScheme;
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    setState(() {
                      _kind = k;
                      _applyDefaultPeriod(k);
                    });
                    await _loadPersons();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected
                          ? scheme.primaryContainer
                          : scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? scheme.primary
                            : scheme.outlineVariant.withValues(alpha: 0.5),
                        width: selected ? 1.6 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(k.icon,
                            size: 26,
                            color: selected
                                ? scheme.onPrimaryContainer
                                : scheme.onSurfaceVariant),
                        const SizedBox(height: 7),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            k.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? scheme.onPrimaryContainer
                                  : scheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          if (_kind.needsPerson) ...[
            SectionHeader(
                title: 'اختر ${_kind.personType!.label}',
                icon: Icons.person_search_rounded),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: _persons.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Text(
                          'لا يوجد ${_kind.personType!.labelPlural} مسجلون',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      )
                    : ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.person_rounded),
                        title: Text(_person?.name ?? 'اختر الاسم'),
                        subtitle: _person?.phone != null &&
                                _person!.phone!.isNotEmpty
                            ? Text(_person!.phone!)
                            : null,
                        trailing: const Icon(Icons.expand_more_rounded),
                        onTap: _pickPerson,
                      ),
              ),
            ),
          ],

          const SectionHeader(
              title: 'الفترة الزمنية', icon: Icons.date_range_rounded),
          PeriodFilterBar(
            selected: _period,
            customStart: _start,
            customEnd: _end,
            onChanged: (t, st, en) => setState(() {
              _period = t;
              _start = st;
              _end = en;
            }),
          ),

          const SectionHeader(
              title: 'ملاحظة على التقرير (اختياري)', icon: Icons.notes_rounded),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppField(
              controller: _note,
              label: 'ملاحظات تظهر أسفل التقرير',
              icon: Icons.edit_note_rounded,
              maxLines: 3,
            ),
          ),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton.icon(
              onPressed: _loading ? null : _generate,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome_rounded),
              label: const Text('إنشاء التقرير'),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text('سيتم إنشاء تقرير PDF احترافي بشعار وبيانات المحل',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}
