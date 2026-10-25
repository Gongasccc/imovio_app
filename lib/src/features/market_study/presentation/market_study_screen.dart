import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:imovio/src/common_widgets/async_value_widget.dart';
import 'package:imovio/src/common_widgets/empty_placeholder.dart';
import 'package:imovio/src/common_widgets/responsive_center.dart';
import 'package:imovio/src/common_widgets/section_card.dart';
import 'package:imovio/src/constants/app_sizes.dart';
import 'package:imovio/src/features/ai/data/gemini_repository.dart';
import 'package:imovio/src/features/ai/presentation/gemini_key_dialog.dart';
import 'package:imovio/src/features/market_study/application/market_study_service.dart';
import 'package:imovio/src/features/market_study/domain/comparable_listing.dart';
import 'package:imovio/src/features/market_study/domain/market_study.dart';
import 'package:imovio/src/features/market_study/domain/study_settings.dart';
import 'package:imovio/src/features/market_study/presentation/area_search_dialog.dart';
import 'package:imovio/src/features/market_study/presentation/comparable_form_dialog.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
import 'package:imovio/src/routing/app_router.dart';
import 'package:imovio/src/utils/async_value_ui.dart';
import 'package:imovio/src/utils/dialogs.dart';
import 'package:imovio/src/utils/format.dart';
import 'package:imovio/src/utils/launcher.dart';

/// Estudo de mercado de um imóvel: escolha de comparáveis, ajustes e
/// resultado. O botão "Gerar PDF" abre o relatório para partilhar.
class MarketStudyScreen extends ConsumerWidget {
  const MarketStudyScreen({super.key, required this.propertyId});
  final PropertyID propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(
      marketStudyControllerProvider,
      (_, s) => s.showSnackBarOnError(context),
    );
    final study = ref.watch(marketStudyProvider(propertyId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estudo de Mercado'),
        actions: [
          IconButton(
            tooltip: 'Ligar o Gemini',
            icon: Icon(
              ref.watch(effectiveGeminiKeyProvider).value == null
                  ? Icons.key_off_outlined
                  : Icons.key,
            ),
            onPressed: () => showGeminiKeyDialog(context),
          ),
        ],
      ),
      body: AsyncValueWidget<MarketStudy?>(
        value: study,
        data: (s) => s == null
            ? const EmptyPlaceholder(
                icon: Icons.home_outlined,
                message: 'Este imóvel já não existe.',
              )
            : _StudyBody(study: s),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Sizes.p12),
          child: FilledButton.icon(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Gerar PDF do Estudo'),
            onPressed: study.value?.pricePerM2 == null
                ? null
                : () => context.pushNamed(
                    AppRoute.marketStudyPdf.name,
                    pathParameters: {'id': propertyId},
                  ),
          ),
        ),
      ),
    );
  }
}

class _StudyBody extends ConsumerWidget {
  const _StudyBody({required this.study});
  final MarketStudy study;

  PropertyID get _id => study.subject.property.id;

  Future<void> _save(WidgetRef ref, StudySettings settings) => ref
      .read(marketStudyControllerProvider.notifier)
      .saveSettings(_id, settings);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      children: [
        ResponsiveCenter(
          maxContentWidth: 900,
          padding: const EdgeInsets.all(Sizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ResultCard(study: study),
              gapH16,
              _SubjectCard(study: study, onChanged: (s) => _save(ref, s)),
              gapH16,
              _IneCard(study: study),
              gapH16,
              _ComparablesCard(study: study, onChanged: (s) => _save(ref, s)),
              gapH16,
              _CoefficientsCard(study: study, onChanged: (s) => _save(ref, s)),
              gapH16,
              _NotesCard(study: study, onChanged: (s) => _save(ref, s)),
              gapH16,
              _CommentaryCard(study: study, onChanged: (s) => _save(ref, s)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.study});
  final MarketStudy study;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unit = study.isRental ? '/mês' : '';
    if (study.pricePerM2 == null) {
      return SectionCard(
        title: 'Resultado',
        icon: Icons.insights_outlined,
        child: Text(
          study.subject.area == null
              ? 'Preencha a área útil ou bruta do imóvel para calcular o valor.'
              : 'Adicione pelo menos um comparável (por link ou à mão) para '
                    'calcular o valor de mercado.',
        ),
      );
    }
    final deviation = study.askingDeviation;
    return SectionCard(
      title: 'Resultado',
      icon: Icons.insights_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Valor de mercado provável', style: theme.textTheme.bodySmall),
          Text(
            '${Format.euros(study.value)}$unit',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            'Intervalo: ${Format.euros(study.valueLow)} a '
            '${Format.euros(study.valueHigh)}$unit',
          ),
          gapH8,
          Wrap(
            spacing: Sizes.p8,
            runSpacing: Sizes.p8,
            children: [
              Chip(
                label: Text(
                  '${Format.euros(study.pricePerM2)}/m² homogeneizado',
                ),
              ),
              Chip(label: Text('${study.selected.length} comparáveis')),
              Chip(label: Text('Confiança ${study.confidence.label}')),
            ],
          ),
          if (deviation != null) ...[
            gapH8,
            Text(
              'Preço pedido ${Format.euros(study.subject.property.price)}: '
              '${_deviationLabel(deviation)}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: deviation.abs() <= 0.05
                    ? Colors.green
                    : (deviation > 0 ? Colors.orange : Colors.blue),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _deviationLabel(double d) {
  if (d.abs() <= 0.05) {
    return 'alinhado com o mercado (${Format.percent(d, signed: true)})';
  }
  return d > 0
      ? '${Format.percent(d)} acima do valor provável'
      : '${Format.percent(-d)} abaixo do valor provável';
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.study, required this.onChanged});
  final MarketStudy study;
  final ValueChanged<StudySettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = study.subject;
    final p = s.property;
    final settings = study.settings;
    return SectionCard(
      title: 'Imóvel em estudo',
      icon: Icons.home_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(p.title, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(
            [
              p.tags,
              if (s.area != null) '${Format.number(s.area)} m²',
              p.freguesia,
              p.concelho,
            ].nonNulls.join(' · '),
          ),
          gapH12,
          DropdownButtonFormField<Conservation>(
            initialValue: s.conservation,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Estado de conservação',
            ),
            items: [
              for (final c in Conservation.values)
                DropdownMenuItem(value: c, child: Text(c.label)),
            ],
            onChanged: (v) => onChanged(settings.copyWith(conservation: v)),
          ),
          gapH12,
          Wrap(
            spacing: Sizes.p8,
            runSpacing: Sizes.p8,
            children: [
              FilterChip(
                label: const Text('Garagem / estacionamento'),
                selected: s.garage,
                onSelected: (v) => onChanged(settings.copyWith(garage: v)),
              ),
              FilterChip(
                label: const Text('Varanda / terraço / jardim'),
                selected: s.outdoor,
                onSelected: (v) => onChanged(settings.copyWith(outdoor: v)),
              ),
              if (s.isApartment)
                FilterChip(
                  label: const Text('Elevador'),
                  selected: s.elevator,
                  onSelected: (v) => onChanged(settings.copyWith(elevator: v)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IneCard extends StatelessWidget {
  const _IneCard({required this.study});
  final MarketStudy study;

  @override
  Widget build(BuildContext context) {
    final ine = study.ine;
    final rows = [
      if (ine?.parish != null) ine!.parish!,
      if (ine?.municipality != null) ine!.municipality!,
    ];
    return SectionCard(
      title: 'Preços oficiais (INE)',
      icon: Icons.account_balance_outlined,
      child: rows.isEmpty
          ? Text(
              study.subject.property.concelho == null
                  ? 'Indique o concelho do imóvel para ver o valor mediano do INE.'
                  : 'O INE não publica valores para '
                        '${study.subject.property.concelho}.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final r in rows)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${r.levelLabel}: ${r.name}'),
                    subtitle: Text(
                      'Mediana ${Format.euros(study.ineM2(r))}/m² · '
                      'há um ano ${Format.euros(r.m2PreviousYear)}/m² '
                      '(${Format.percent(r.yearlyChange, signed: true)})',
                    ),
                  ),
                if (study.ineValue != null)
                  Text(
                    'Valor pela mediana do INE: '
                    '${Format.euros(study.ineValue)}',
                  ),
                if (study.isRental)
                  const Text(
                    'Os valores do INE são de vendas; servem só '
                    'como referência da zona.',
                  ),
                gapH4,
                Text(
                  'Vendas dos últimos 12 meses até ao ${ine!.period}. '
                  'Fonte: ${ine.source}.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
    );
  }
}

class _ComparablesCard extends ConsumerWidget {
  const _ComparablesCard({required this.study, required this.onChanged});
  final MarketStudy study;
  final ValueChanged<StudySettings> onChanged;

  Future<void> _addByLink(BuildContext context, WidgetRef ref) async {
    final url = await _askLink(context);
    if (url == null || !context.mounted) return;
    final controller = ref.read(marketStudyControllerProvider.notifier);
    final draft = await controller.importFromLink(url);
    if (draft == null || !context.mounted) return;
    final c = await showComparableForm(
      context,
      draft,
      title: 'Confirmar dados do anúncio',
    );
    if (c == null) return;
    await controller.saveComparable(
      c,
      forStudy: study.subject.property.id,
      settings: study.settings,
    );
  }

  Future<void> _searchArea(BuildContext context, WidgetRef ref) async {
    if (!await _ensureGemini(context, ref) || !context.mounted) return;
    final controller = ref.read(marketStudyControllerProvider.notifier);
    final result = await controller.searchArea(study);
    if (result == null || !context.mounted) return;
    final chosen = await showAreaSearchResults(context, result);
    if (chosen == null || chosen.isEmpty) return;
    await controller.addComparables(
      chosen,
      study.subject.property.id,
      study.settings,
    );
  }

  Future<void> _addManual(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(marketStudyControllerProvider.notifier);
    final p = study.subject.property;
    final base = controller.newManual();
    final c = await showComparableForm(
      context,
      ComparableListing(
        id: base.id,
        title: '',
        price: 0,
        area: 0,
        negocio: p.negocio,
        tipo: p.tipo,
        tipologia: p.tipologia,
        concelho: p.concelho,
        freguesia: p.freguesia,
        date: base.date,
      ),
      title: 'Novo comparável',
    );
    if (c == null) return;
    await controller.saveComparable(
      c,
      forStudy: p.id,
      settings: study.settings,
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    ComparableListing c,
  ) async {
    final edited = await showComparableForm(context, c);
    if (edited == null) return;
    await ref
        .read(marketStudyControllerProvider.notifier)
        .saveComparable(edited);
  }

  Future<void> _location(BuildContext context, ComparableListing c) async {
    final value = await showDialog<double>(
      context: context,
      builder: (_) => _LocationDialog(
        initial: study.settings.location[c.id] ?? 0,
        title: c.title,
      ),
    );
    if (value == null) return;
    onChanged(
      study.settings.copyWith(
        location: {...study.settings.location, c.id: value},
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(marketStudyControllerProvider).isLoading;
    final candidates = study.candidates;
    return SectionCard(
      title: 'Comparáveis',
      icon: Icons.compare_arrows,
      trailing: loading
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Imóveis semelhantes da mesma zona: anúncios que importa e os '
            'imóveis da sua carteira. Os mais parecidos entram '
            'automaticamente; pode tirar ou pôr qualquer um.',
          ),
          gapH12,
          Wrap(
            spacing: Sizes.p8,
            runSpacing: Sizes.p8,
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.travel_explore),
                label: const Text('Pesquisar preços na zona'),
                onPressed: loading ? null : () => _searchArea(context, ref),
              ),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.link),
                label: const Text('Adicionar por link'),
                onPressed: loading ? null : () => _addByLink(context, ref),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_note),
                label: const Text('Adicionar à mão'),
                onPressed: loading ? null : () => _addManual(context, ref),
              ),
            ],
          ),
          gapH12,
          if (candidates.isEmpty)
            const Text(
              'Ainda não há comparáveis do mesmo tipo de negócio e '
              'imóvel. Cole o link de anúncios semelhantes para começar.',
            ),
          for (final a in candidates)
            _ComparableTile(
              item: a,
              onToggle: (v) =>
                  onChanged(study.settings.toggle(a.comparable.id, include: v)),
              onEdit: a.comparable.fromPortfolio
                  ? () => context.pushNamed(
                      AppRoute.property.name,
                      pathParameters: {
                        'id': a.comparable.id.substring(
                          ComparableListing.portfolioPrefix.length,
                        ),
                      },
                    )
                  : () => _edit(context, ref, a.comparable),
              onLocation: () => _location(context, a.comparable),
              onDelete: a.comparable.fromPortfolio
                  ? null
                  : () async {
                      if (await showConfirmDialog(
                        context,
                        message:
                            'Eliminar ${a.comparable.title} da base '
                            'de comparáveis?',
                      )) {
                        await ref
                            .read(marketStudyControllerProvider.notifier)
                            .deleteComparable(a.comparable.id);
                      }
                    },
            ),
        ],
      ),
    );
  }
}

Future<String?> _askLink(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Link do anúncio'),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.url,
        decoration: const InputDecoration(
          hintText: 'https://www.idealista.pt/imovel/...',
        ),
        onSubmitted: (v) => Navigator.of(context).pop(emptyToNull(v)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(emptyToNull(controller.text)),
          child: const Text('Importar'),
        ),
      ],
    ),
  ).whenComplete(controller.dispose);
}

class _ComparableTile extends StatelessWidget {
  const _ComparableTile({
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onLocation,
    required this.onDelete,
  });
  final AdjustedComparable item;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onLocation;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final c = item.comparable;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: Sizes.p4),
      color: item.included ? null : theme.colorScheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(Sizes.p8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(value: item.included, onChanged: (v) => onToggle(v!)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    [
                      Format.euros(c.price),
                      '${Format.number(c.area)} m²',
                      c.tipologia,
                      c.freguesia ?? c.concelho,
                      c.fromPortfolio ? 'Carteira' : c.source.label,
                    ].nonNulls.join(' · '),
                    style: muted,
                  ),
                  gapH4,
                  Text(
                    '${Format.euros(c.pricePerM2)}/m² → '
                    '${Format.euros(item.adjustedPricePerM2)}/m² ajustado',
                  ),
                  if (item.negotiation > 0 || item.adjustments.isNotEmpty)
                    Text(
                      [
                        if (item.negotiation > 0)
                          'Negociação ${Format.percent(-item.negotiation, signed: true)}',
                        for (final e in item.adjustments.entries)
                          '${e.key} ${Format.percent(e.value, signed: true)}',
                      ].join(' · '),
                      style: muted,
                    ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) => switch (v) {
                'edit' => onEdit(),
                'location' => onLocation(),
                'open' => openExternalUrl(c.sourceUrl!),
                'delete' => onDelete?.call(),
                _ => null,
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text(c.fromPortfolio ? 'Abrir imóvel' : 'Editar'),
                ),
                const PopupMenuItem(
                  value: 'location',
                  child: Text('Ajuste de localização'),
                ),
                if (c.sourceUrl != null)
                  const PopupMenuItem(
                    value: 'open',
                    child: Text('Abrir anúncio'),
                  ),
                if (onDelete != null)
                  const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationDialog extends StatefulWidget {
  const _LocationDialog({required this.initial, required this.title});
  final double initial;
  final String title;

  @override
  State<_LocationDialog> createState() => _LocationDialogState();
}

class _LocationDialogState extends State<_LocationDialog> {
  late double _value = widget.initial.clamp(-0.3, 0.3);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajuste de localização'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title),
          gapH12,
          const Text(
            'Positivo se o imóvel em estudo tem melhor localização '
            '(rua, vista, exposição, acessos) do que este comparável.',
          ),
          Slider(
            value: _value,
            min: -0.3,
            max: 0.3,
            divisions: 60,
            label: Format.percent(_value, signed: true, decimals: 0),
            onChanged: (v) => setState(() => _value = v),
          ),
          Center(
            child: Text(Format.percent(_value, signed: true, decimals: 0)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_value),
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}

class _CoefficientsCard extends StatefulWidget {
  const _CoefficientsCard({required this.study, required this.onChanged});
  final MarketStudy study;
  final ValueChanged<StudySettings> onChanged;

  @override
  State<_CoefficientsCard> createState() => _CoefficientsCardState();
}

class _CoefficientsCardState extends State<_CoefficientsCard> {
  /// Valores enquanto o utilizador arrasta; só se guardam no fim.
  StudyCoefficients? _draft;

  void _save(StudyCoefficients k) {
    setState(() => _draft = null);
    widget.onChanged(widget.study.settings.copyWith(coefficients: k));
  }

  @override
  Widget build(BuildContext context) {
    final k = _draft ?? widget.study.settings.coefficients;
    Widget row(
      String label,
      String help,
      double value,
      double max,
      StudyCoefficients Function(double) update,
    ) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              Format.percent(value, decimals: 0),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        if (help.isNotEmpty)
          Text(help, style: Theme.of(context).textTheme.bodySmall),
        Slider(
          value: value.clamp(0, max),
          max: max,
          divisions: (max * 100).round(),
          onChanged: (v) =>
              setState(() => _draft = update((v * 100).roundToDouble() / 100)),
          onChangeEnd: (v) => _save(update((v * 100).roundToDouble() / 100)),
        ),
      ],
    );
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.tune),
        title: const Text('Coeficientes de ajuste'),
        subtitle: const Text('Valores habituais; ajuste à sua zona'),
        childrenPadding: const EdgeInsets.fromLTRB(
          Sizes.p20,
          0,
          Sizes.p20,
          Sizes.p16,
        ),
        children: [
          row(
            'Margem de negociação',
            'Desconto do preço pedido nos anúncios',
            k.negotiation,
            0.2,
            (v) => k.copyWith(negotiation: v),
          ),
          row(
            'Efeito da área',
            'Casas maiores têm €/m² mais baixo (elasticidade)',
            k.areaElasticity,
            0.5,
            (v) => k.copyWith(areaElasticity: v),
          ),
          row(
            'Estado de conservação',
            'Por cada nível de diferença',
            k.conservationStep,
            0.25,
            (v) => k.copyWith(conservationStep: v),
          ),
          row(
            'Garagem / estacionamento',
            '',
            k.garage,
            0.2,
            (v) => k.copyWith(garage: v),
          ),
          row(
            'Varanda / terraço / jardim',
            '',
            k.outdoor,
            0.2,
            (v) => k.copyWith(outdoor: v),
          ),
          row(
            'Elevador',
            'Só em apartamentos',
            k.elevator,
            0.2,
            (v) => k.copyWith(elevator: v),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _save(StudyCoefficients.defaults),
              child: const Text('Repor valores por defeito'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatefulWidget {
  const _NotesCard({required this.study, required this.onChanged});
  final MarketStudy study;
  final ValueChanged<StudySettings> onChanged;

  @override
  State<_NotesCard> createState() => _NotesCardState();
}

class _NotesCardState extends State<_NotesCard> {
  late final _notes = TextEditingController(
    text: widget.study.settings.notes ?? '',
  );

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    if ((widget.study.settings.notes ?? '') == _notes.text.trim()) return;
    widget.onChanged(widget.study.settings.copyWith(notes: _notes.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Notas do consultor',
      icon: Icons.notes,
      child: Focus(
        onFocusChange: (focused) {
          if (!focused) _save();
        },
        child: TextField(
          controller: _notes,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText:
                'Pontos fortes, procura na zona, recomendação de preço...',
          ),
        ),
      ),
    );
  }
}

/// Garante que há chave do Gemini, pedindo-a se for preciso.
Future<bool> _ensureGemini(BuildContext context, WidgetRef ref) async {
  if (await ref.read(effectiveGeminiKeyProvider.future) != null) return true;
  if (!context.mounted) return false;
  return showGeminiKeyDialog(context);
}

class _CommentaryCard extends ConsumerStatefulWidget {
  const _CommentaryCard({required this.study, required this.onChanged});
  final MarketStudy study;
  final ValueChanged<StudySettings> onChanged;

  @override
  ConsumerState<_CommentaryCard> createState() => _CommentaryCardState();
}

class _CommentaryCardState extends ConsumerState<_CommentaryCard> {
  late final _text = TextEditingController(
    text: widget.study.settings.commentary ?? '',
  );
  final _focus = FocusNode();

  @override
  void didUpdateWidget(covariant _CommentaryCard old) {
    super.didUpdateWidget(old);
    // Texto novo escrito pelo Gemini: mostra-o, se não estiver a editar.
    final saved = widget.study.settings.commentary ?? '';
    if (!_focus.hasFocus && _text.text != saved) _text.text = saved;
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _save() {
    if ((widget.study.settings.commentary ?? '') == _text.text.trim()) return;
    widget.onChanged(
      widget.study.settings.copyWith(commentary: _text.text.trim()),
    );
  }

  Future<void> _write() async {
    if (!await _ensureGemini(context, ref) || !mounted) return;
    if (_text.text.trim().isNotEmpty &&
        !await showConfirmDialog(
          context,
          title: 'Escrever de novo',
          message: 'Substituir o comentário atual por um novo do Gemini?',
          confirmLabel: 'Substituir',
        )) {
      return;
    }
    await ref
        .read(marketStudyControllerProvider.notifier)
        .writeCommentary(widget.study);
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(marketStudyControllerProvider).isLoading;
    return SectionCard(
      title: 'Análise de mercado (PDF)',
      icon: Icons.auto_awesome_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Focus(
            onFocusChange: (focused) {
              if (!focused) _save();
            },
            child: TextField(
              controller: _text,
              focusNode: _focus,
              minLines: 3,
              maxLines: 12,
              decoration: const InputDecoration(
                hintText:
                    'Comentário para o proprietário. O Gemini escreve-o com os '
                    'números deste estudo; reveja e edite antes de gerar o PDF.',
              ),
            ),
          ),
          gapH8,
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Escrever com Gemini'),
              onPressed: loading || widget.study.pricePerM2 == null
                  ? null
                  : _write,
            ),
          ),
        ],
      ),
    );
  }
}
