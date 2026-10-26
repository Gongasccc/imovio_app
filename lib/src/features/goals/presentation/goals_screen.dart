import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:imovio/src/common_widgets/form_fields.dart';
import 'package:imovio/src/common_widgets/responsive_center.dart';
import 'package:imovio/src/common_widgets/section_card.dart';
import 'package:imovio/src/constants/app_sizes.dart';
import 'package:imovio/src/constants/app_theme.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/contacts/data/contacts_repository.dart';
import 'package:imovio/src/features/goals/data/goals_repository.dart';
import 'package:imovio/src/features/goals/domain/goals.dart';
import 'package:imovio/src/features/pipeline/data/deals_repository.dart';
import 'package:imovio/src/features/properties/data/properties_repository.dart';
import 'package:imovio/src/features/tasks/data/tasks_repository.dart';
import 'package:imovio/src/features/tasks/domain/task.dart';
import 'package:imovio/src/utils/format.dart';
import 'package:imovio/src/utils/run_action.dart';

/// Objetivos do mês, funil de conversão e evolução dos últimos 6 meses.
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsStreamProvider).value ?? const MonthlyGoals();
    final months = ref.watch(monthlyResultsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Objetivos e funil'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Metas'),
            onPressed: () => editGoals(context, ref, goals),
          ),
          gapW8,
        ],
      ),
      body: ListView(
        children: [
          ResponsiveCenter(
            maxContentWidth: 900,
            padding: const EdgeInsets.all(Sizes.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GoalsProgressCard(goals: goals, month: months.last),
                gapH16,
                const _FunnelCard(),
                gapH16,
                _HistoryCard(months: months),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> editGoals(
    BuildContext context, WidgetRef ref, MonthlyGoals goals) async {
  final result = await showDialog<MonthlyGoals>(
    context: context,
    builder: (_) => _GoalsDialog(goals: goals),
  );
  if (result == null || !context.mounted) return;
  await runAction(
    context,
    () => ref
        .read(goalsRepositoryProvider)
        .save(uid: ref.read(currentUidProvider), goals: result),
    success: 'Metas guardadas',
  );
}

/// Barras de progresso do mês atual face às metas.
class GoalsProgressCard extends ConsumerWidget {
  const GoalsProgressCard({super.key, required this.goals, required this.month});
  final MonthlyGoals goals;
  final MonthResults month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final monthName = toBeginningOfSentenceCase(
        DateFormat('MMMM', 'pt_PT').format(month.month));
    Widget bar(String label, num done, num? goal, {bool money = false}) {
      final pct = goal == null || goal == 0 ? null : (done / goal).clamp(0, 1);
      final reached = goal != null && done >= goal;
      String fmt(num v) => money ? Format.euros(v) : '$v';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(label)),
                Text(
                  goal == null ? fmt(done) : '${fmt(done)} de ${fmt(goal)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: reached ? AppColors.green : null,
                  ),
                ),
              ],
            ),
            gapH4,
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct?.toDouble() ?? 0,
                minHeight: 8,
                backgroundColor: scheme.surfaceContainerHighest,
                color: reached ? AppColors.green : scheme.primary,
              ),
            ),
          ],
        ),
      );
    }

    return SectionCard(
      title: 'Objetivos de $monthName',
      icon: Icons.flag_outlined,
      trailing: goals.isEmpty
          ? TextButton(
              onPressed: () => editGoals(context, ref, goals),
              child: const Text('Definir metas'),
            )
          : null,
      child: Column(
        children: [
          bar('Angariações', month.listings, goals.listings),
          bar('Visitas feitas', month.visits, goals.visits),
          bar('Propostas / negócios', month.proposals, goals.proposals),
          bar('Vendas', month.sales, goals.sales),
          bar('Lucro real', month.profit, goals.profit, money: true),
        ],
      ),
    );
  }
}

/// Funil de sempre: de contactos a vendas, com a taxa entre passos.
class _FunnelCard extends ConsumerWidget {
  const _FunnelCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(contactsStreamProvider).value ?? const [];
    final tasks = ref.watch(tasksStreamProvider).value ?? const [];
    final deals = ref.watch(dealsStreamProvider).value ?? const [];
    final properties = ref.watch(propertiesStreamProvider).value ?? const [];
    final visited = {
      for (final t in tasks)
        if (t.category == TaskCategories.visit && t.isDone && t.contactId != null)
          t.contactId!,
    }.length;
    final steps = [
      ('Contactos', contacts.length),
      ('Com visita feita', visited),
      ('Com negócio', {for (final d in deals) ?d.contactId}.length),
      ('Vendas', properties.where((p) => p.isSold).length),
    ];
    final max = steps.first.$2 == 0 ? 1 : steps.first.$2;
    final scheme = Theme.of(context).colorScheme;
    return SectionCard(
      title: 'Funil de conversão',
      icon: Icons.filter_alt_outlined,
      child: Column(
        children: [
          for (final (i, (label, n)) in steps.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(width: 140, child: Text(label)),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) => Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: 28,
                          width: (c.maxWidth * n / max).clamp(4, c.maxWidth),
                          decoration: BoxDecoration(
                            color: scheme.primary
                                .withValues(alpha: 1 - i * 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Text(
                      i == 0 || steps[i - 1].$2 == 0
                          ? '$n'
                          : '$n (${Format.percent(n / steps[i - 1].$2, decimals: 0)})',
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.months});
  final List<MonthResults> months;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxProfit = months.fold<num>(1, (m, r) => r.profit > m ? r.profit : m);
    return SectionCard(
      title: 'Últimos 6 meses',
      icon: Icons.bar_chart,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final r in months)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(Format.euros(r.profit),
                              style: const TextStyle(fontSize: 10)),
                          gapH4,
                          Container(
                            height: 110 * (r.profit <= 0 ? 0.02 : r.profit / maxProfit),
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6)),
                            ),
                          ),
                          gapH4,
                          Text(DateFormat('MMM', 'pt_PT').format(r.month),
                              style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          gapH12,
          Table(
            columnWidths: const {0: FlexColumnWidth(2)},
            children: [
              TableRow(children: [
                const Text('Mês', style: TextStyle(fontWeight: FontWeight.w600)),
                for (final h in ['Ang.', 'Visitas', 'Neg.', 'Vendas'])
                  Text(h,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
              for (final r in months.reversed)
                TableRow(children: [
                  Text(DateFormat('MMM y', 'pt_PT').format(r.month)),
                  for (final v in [r.listings, r.visits, r.proposals, r.sales])
                    Text('$v', textAlign: TextAlign.right),
                ]),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalsDialog extends StatefulWidget {
  const _GoalsDialog({required this.goals});
  final MonthlyGoals goals;

  @override
  State<_GoalsDialog> createState() => _GoalsDialogState();
}

class _GoalsDialogState extends State<_GoalsDialog> {
  late final _c = {
    'listings': TextEditingController(text: widget.goals.listings?.toString()),
    'visits': TextEditingController(text: widget.goals.visits?.toString()),
    'proposals': TextEditingController(text: widget.goals.proposals?.toString()),
    'sales': TextEditingController(text: widget.goals.sales?.toString()),
    'profit': TextEditingController(text: widget.goals.profit?.toString()),
  };

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _f(String key, String label, {String? suffix}) => TextField(
        controller: _c[key],
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label, suffixText: suffix),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Metas por mês'),
      content: SizedBox(
        width: 480,
        child: FormGrid(children: [
          _f('listings', 'Angariações'),
          _f('visits', 'Visitas'),
          _f('proposals', 'Propostas / negócios'),
          _f('sales', 'Vendas'),
          FullWidth(child: _f('profit', 'Lucro real', suffix: '€')),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            MonthlyGoals(
              listings: parseInt(_c['listings']!.text),
              visits: parseInt(_c['visits']!.text),
              proposals: parseInt(_c['proposals']!.text),
              sales: parseInt(_c['sales']!.text),
              profit: parseNum(_c['profit']!.text),
            ),
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
