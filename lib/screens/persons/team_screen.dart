import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../widgets/common.dart';
import 'persons_list_screen.dart';

/// شاشة فريق العمل: الخياطون / القصاصون / العاملون في تبويبات
class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: PersonType.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('فريق العمل'),
          bottom: TabBar(
            labelColor: scheme.primary,
            unselectedLabelColor: scheme.onSurfaceVariant,
            indicatorColor: scheme.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            tabs: PersonType.values
                .map((t) => Tab(
                      icon: Icon(personIcon(t), size: 20),
                      text: t.labelPlural,
                    ))
                .toList(),
          ),
        ),
        body: TabBarView(
          children: PersonType.values
              .map((t) => PersonsListScreen(type: t, embedded: true))
              .toList(),
        ),
      ),
    );
  }
}
