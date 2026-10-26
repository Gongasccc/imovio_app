import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:imovio/src/common_widgets/adaptive_fab.dart';
import 'package:imovio/src/common_widgets/async_value_widget.dart';
import 'package:imovio/src/common_widgets/page_header.dart';
import 'package:imovio/src/constants/app_sizes.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/contacts/data/contacts_repository.dart';
import 'package:imovio/src/features/pipeline/data/deals_repository.dart';
import 'package:imovio/src/features/pipeline/domain/deal.dart';
import 'package:imovio/src/features/properties/data/properties_repository.dart';
import 'package:imovio/src/routing/app_router.dart';
import 'package:imovio/src/utils/format.dart';
import 'package:imovio/src/utils/run_action.dart';
import 'package:imovio/src/common_widgets/icon_label.dart';

/// Pipeline em quadro Kanban: uma coluna por fase. Arrastar um cartão para
/// outra coluna muda a fase do negócio.
class PipelineScreen extends ConsumerWidget {
  const PipelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealsValue = ref.watch(dealsStreamProvider);
    final deals = dealsValue.value ?? const <Deal>[];
    final total = deals.fold<num>(0, (sum, d) => sum + (d.value ?? 0));
    return Scaffold(
      floatingActionButton: AdaptiveFab(
        onPressed: () => context.pushNamed(AppRoute.newDeal.name),
        icon: Icons.add,
        label: 'Novo Negócio',
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(Sizes.p16),
            child: PageHeader(
              title: 'Pipeline de Negócios',
              subtitle:
                  '${deals.length} negócios · ${Format.euros(total)} '
                  'em pipeline. Arraste os cartões para mudar de fase.',
            ),
          ),
          Expanded(
            child: AsyncValueWidget<List<Deal>>(
              value: dealsValue,
              data: (deals) => LayoutBuilder(
                builder: (context, constraints) {
                  final columnWidth = constraints.maxWidth >= 1200
                      ? (constraints.maxWidth - 16 * 5) / 4
                      : 280.0;
                  final stages = [
                    ...DealStages.all,
                    // Fases antigas que não estejam na lista continuam visíveis.
                    ...{for (final d in deals) d.stage}
                        .where((s) => !DealStages.all.contains(s)),
                  ];
                  return ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    children: [
                      for (final stage in stages) ...[
                        SizedBox(
                          width: columnWidth,
                          child: _StageColumn(
                            stage: stage,
                            deals: deals
                                .where((d) => d.stage == stage)
                                .toList(),
                          ),
                        ),
                        gapW16,
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StageColumn extends ConsumerWidget {
  const _StageColumn({required this.stage, required this.deals});
  final String stage;
  final List<Deal> deals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final total = deals.fold<num>(0, (sum, d) => sum + (d.value ?? 0));
    return DragTarget<Deal>(
      onWillAcceptWithDetails: (details) => details.data.stage != stage,
      onAcceptWithDetails: (details) {
        final uid = ref.read(currentUidProvider);
        runAction(
          context,
          () => ref
              .read(dealsRepositoryProvider)
              .moveDeal(uid: uid, id: details.data.id, stage: stage),
          success: 'Movido para "$stage"',
        );
      },
      builder: (context, candidates, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: candidates.isNotEmpty
              ? scheme.primary.withValues(alpha: 0.1)
              : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: candidates.isNotEmpty
                ? scheme.primary
                : scheme.outlineVariant,
          ),
        ),
        padding: const EdgeInsets.all(Sizes.p12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    stage,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${deals.length}',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
            Text(
              Format.euros(total),
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            gapH12,
            Expanded(
              child: deals.isEmpty
                  ? Center(
                      child: Text(
                        'Sem negócios',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.separated(
                      itemCount: deals.length,
                      separatorBuilder: (_, _) => gapH8,
                      itemBuilder: (context, i) =>
                          _DraggableDealCard(deal: deals[i], width: 256),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraggableDealCard extends StatelessWidget {
  const _DraggableDealCard({required this.deal, required this.width});
  final Deal deal;
  final double width;

  @override
  Widget build(BuildContext context) {
    final card = _DealCard(deal: deal);
    return LongPressDraggable<Deal>(
      data: deal,
      delay: const Duration(milliseconds: 250),
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: width,
          child: Opacity(opacity: 0.9, child: card),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: card),
      child: card,
    );
  }
}

class _DealCard extends ConsumerWidget {
  const _DealCard({required this.deal});
  final Deal deal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contact = ref.watch(contactsByIdProvider)[deal.contactId];
    final property = ref.watch(propertiesByIdProvider)[deal.propertyId];
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.pushNamed(
          AppRoute.deal.name,
          pathParameters: {'id': deal.id},
        ),
        child: Padding(
          padding: const EdgeInsets.all(Sizes.p12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                deal.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              gapH4,
              IconLabel(icon: Icons.person_outline, text: contact?.name ?? '—'),
              if (property != null)
                IconLabel(icon: Icons.home_outlined, text: property.title),
              gapH8,
              Text(
                Format.euros(deal.value),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
