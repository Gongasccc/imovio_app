import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:imovio/src/common_widgets/async_value_widget.dart';
import 'package:imovio/src/common_widgets/page_header.dart';
import 'package:imovio/src/common_widgets/responsive_center.dart';
import 'package:imovio/src/common_widgets/section_card.dart';
import 'package:imovio/src/constants/app_sizes.dart';
import 'package:imovio/src/constants/app_theme.dart';
import 'package:imovio/src/features/dashboard/application/dashboard_service.dart';
import 'package:imovio/src/features/pipeline/presentation/deal_tile.dart';
import 'package:imovio/src/features/tasks/domain/task.dart';
import 'package:imovio/src/features/tasks/presentation/task_tile.dart';
import 'package:imovio/src/routing/app_router.dart';
import 'package:imovio/src/utils/format.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpis = ref.watch(dashboardKpisProvider);
    return Scaffold(
      body: ListView(
        children: [
          ResponsiveCenter(
            padding: const EdgeInsets.all(Sizes.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  title: 'Dashboard',
                  subtitle: 'Visão geral do seu desempenho.',
                ),
                gapH16,
                AsyncValueWidget<DashboardKpis>(
                  value: kpis,
                  data: (k) => _DashboardBody(kpis: k),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.kpis});
  final DashboardKpis kpis;

  @override
  Widget build(BuildContext context) {
    final k = kpis;
    final reminders = [...k.overdueTasks, ...k.todayTasks];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final columns = c.maxWidth >= 900 ? 4 : 2;
            final width = (c.maxWidth - Sizes.p16 * (columns - 1)) / columns;
            final cards = [
              _KpiCard(
                label: 'Total de contactos',
                value: '${k.contacts}',
                icon: Icons.people_outline,
                onTap: () => context.goNamed(AppRoute.contacts.name),
              ),
              _KpiCard(
                label: 'Negócios em pipeline',
                value: '${k.deals}',
                icon: Icons.handshake_outlined,
                onTap: () => context.goNamed(AppRoute.pipeline.name),
              ),
              _KpiCard(
                label: 'Tarefas pendentes',
                value: '${k.pendingTasks}',
                icon: Icons.task_alt,
                detail: k.overdueTasks.isEmpty
                    ? '${k.todayTasks.length} para hoje'
                    : '${k.overdueTasks.length} em atraso',
                detailColor: k.overdueTasks.isEmpty ? null : AppColors.red,
                onTap: () => context.goNamed(AppRoute.tasks.name),
              ),
              _KpiCard(
                label: 'Valor do pipeline',
                value: Format.euros(k.pipelineValue),
                icon: Icons.euro,
                highlight: true,
                onTap: () => context.goNamed(AppRoute.pipeline.name),
              ),
            ];
            return Wrap(
              spacing: Sizes.p16,
              runSpacing: Sizes.p16,
              children: [
                for (final card in cards) SizedBox(width: width, child: card),
              ],
            );
          },
        ),
        gapH16,
        _SalesCard(kpis: k),
        gapH16,
        LayoutBuilder(
          builder: (context, c) {
            final remindersCard = SectionCard(
              title: 'Lembretes',
              icon: Icons.notifications_active_outlined,
              trailing: TextButton(
                onPressed: () => context.goNamed(AppRoute.tasks.name),
                child: const Text('Ver tarefas'),
              ),
              child: reminders.isEmpty && k.upcomingTasks.isEmpty
                  ? const Text('Sem tarefas em atraso ou para hoje.')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (k.overdueTasks.isNotEmpty)
                          _TaskGroup(
                            'Em atraso',
                            k.overdueTasks,
                            AppColors.red,
                          ),
                        if (k.todayTasks.isNotEmpty)
                          _TaskGroup('Hoje', k.todayTasks, null),
                        if (k.upcomingTasks.isNotEmpty)
                          _TaskGroup('Próximos 7 dias', k.upcomingTasks, null),
                      ],
                    ),
            );
            final dealsCard = SectionCard(
              title: 'Negócios em aberto',
              icon: Icons.trending_up,
              trailing: TextButton(
                onPressed: () => context.goNamed(AppRoute.pipeline.name),
                child: const Text('Ver pipeline'),
              ),
              child: k.recentDeals.isEmpty
                  ? const Text('Nenhum negócio ativo registado.')
                  : Column(
                      children: [
                        for (final d in k.recentDeals) DealTile(deal: d),
                      ],
                    ),
            );
            if (c.maxWidth >= wideBreakpoint) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: dealsCard),
                  gapW16,
                  Expanded(child: remindersCard),
                ],
              );
            }
            return Column(children: [remindersCard, gapH16, dealsCard]);
          },
        ),
      ],
    );
  }
}

class _TaskGroup extends StatelessWidget {
  const _TaskGroup(this.title, this.tasks, this.color);
  final String title;
  final List<Task> tasks;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: Sizes.p8),
          child: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
        ),
        for (final t in tasks.take(5)) TaskTile(task: t),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    this.detail,
    this.detailColor,
    this.highlight = false,
    this.onTap,
  });
  final String label;
  final String value;
  final IconData icon;
  final String? detail;
  final Color? detailColor;
  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Sizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Icon(icon, size: 18, color: scheme.primary),
                ],
              ),
              gapH8,
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: highlight ? scheme.primary : null,
                  ),
                ),
              ),
              if (detail != null)
                Text(
                  detail!,
                  style: TextStyle(
                    fontSize: 12,
                    color: detailColor ?? scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Resultado das vendas: lucro real já ganho e o que está para entrar.
class _SalesCard extends StatelessWidget {
  const _SalesCard({required this.kpis});
  final DashboardKpis kpis;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget item(String label, String value, {Color? color, String? note}) =>
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              gapH4,
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              if (note != null)
                Text(
                  note,
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        );
    return SectionCard(
      title: 'Resultados das vendas',
      icon: Icons.account_balance_wallet_outlined,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          item(
            'Lucro real',
            Format.euros(kpis.realizedProfit),
            color: kpis.realizedProfit >= 0 ? AppColors.green : AppColors.red,
            note: '${kpis.soldCount} imóvel(is) vendido(s)',
          ),
          gapW12,
          item(
            'A receber',
            Format.euros(kpis.expectedShare),
            color: scheme.primary,
            note: 'Reservados e com CPCV',
          ),
          gapW12,
          item(
            'Despesas',
            Format.euros(kpis.expensesTotal),
            note: 'Em todos os imóveis',
          ),
        ],
      ),
    );
  }
}
