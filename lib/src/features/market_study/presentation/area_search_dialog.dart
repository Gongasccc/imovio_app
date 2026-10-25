import 'package:flutter/material.dart';
import 'package:imovio/src/constants/app_sizes.dart';
import 'package:imovio/src/features/market_study/application/market_ai_service.dart';
import 'package:imovio/src/features/market_study/domain/comparable_listing.dart';
import 'package:imovio/src/utils/format.dart';
import 'package:imovio/src/utils/launcher.dart';

/// Mostra os anúncios que o Gemini encontrou e devolve os escolhidos.
Future<List<ComparableListing>?> showAreaSearchResults(
  BuildContext context,
  AreaSearchResult result,
) => showDialog<List<ComparableListing>>(
  context: context,
  builder: (_) => _AreaSearchDialog(result: result),
);

class _AreaSearchDialog extends StatefulWidget {
  const _AreaSearchDialog({required this.result});
  final AreaSearchResult result;

  @override
  State<_AreaSearchDialog> createState() => _AreaSearchDialogState();
}

class _AreaSearchDialogState extends State<_AreaSearchDialog> {
  late final Set<ComparableID> _chosen = {
    for (final c in widget.result.listings) c.id,
  };

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final muted = Theme.of(context).textTheme.bodySmall;
    return AlertDialog(
      title: const Text('Anúncios encontrados na zona'),
      content: SizedBox(
        width: 640,
        child: ListView(
          shrinkWrap: true,
          children: [
            if (r.listings.isEmpty)
              const Text(
                'O Gemini não encontrou anúncios semelhantes com '
                'preço e área. Tente mais tarde ou adicione por link.',
              )
            else
              const Text(
                'Confirme os que são mesmo comparáveis. Pode '
                'corrigir qualquer um depois em "Editar".',
              ),
            gapH8,
            for (final c in r.listings)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _chosen.contains(c.id),
                onChanged: (v) => setState(
                  () => v! ? _chosen.add(c.id) : _chosen.remove(c.id),
                ),
                title: Text(
                  c.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  [
                    Format.euros(c.price),
                    '${Format.number(c.area)} m²',
                    '${Format.euros(c.pricePerM2)}/m²',
                    c.tipologia,
                    c.freguesia ?? c.concelho,
                  ].nonNulls.join(' · '),
                ),
                secondary: c.sourceUrl == null
                    ? null
                    : IconButton(
                        tooltip: 'Abrir anúncio',
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () => openExternalUrl(c.sourceUrl!),
                      ),
              ),
            if (r.sources.isNotEmpty || r.queries.isNotEmpty) ...[
              const Divider(),
              Text('Fontes da pesquisa Google', style: muted),
              Wrap(
                spacing: Sizes.p4,
                children: [
                  for (final q in r.queries)
                    ActionChip(
                      avatar: const Icon(Icons.search, size: 16),
                      label: Text(q),
                      onPressed: () => openExternalUrl(
                        Uri.https('www.google.com', '/search', {
                          'q': q,
                        }).toString(),
                      ),
                    ),
                  for (final s in r.sources)
                    ActionChip(
                      label: Text(s.title),
                      onPressed: () => openExternalUrl(s.uri),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _chosen.isEmpty
              ? null
              : () => Navigator.of(context).pop([
                  for (final c in r.listings)
                    if (_chosen.contains(c.id)) c,
                ]),
          child: Text('Adicionar ${_chosen.length}'),
        ),
      ],
    );
  }
}
