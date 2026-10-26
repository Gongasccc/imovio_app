import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:imovio/src/common_widgets/empty_placeholder.dart';
import 'package:imovio/src/common_widgets/page_header.dart';
import 'package:imovio/src/constants/app_sizes.dart';
import 'package:imovio/src/constants/app_theme.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/properties/data/properties_repository.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
import 'package:imovio/src/features/properties/presentation/property_list_tile.dart';
import 'package:imovio/src/routing/app_router.dart';
import 'package:imovio/src/utils/format.dart';
import 'package:imovio/src/utils/launcher.dart';
import 'package:imovio/src/utils/run_action.dart';

class PropertiesScreen extends ConsumerStatefulWidget {
  const PropertiesScreen({super.key});

  @override
  ConsumerState<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends ConsumerState<PropertiesScreen> {
  var _query = '';
  String? _negocio;
  String? _distrito;
  String? _concelho;
  String? _freguesia;

  List<Property> _filter(List<Property> list) => list.where((p) {
    final q = _query.toLowerCase();
    return (q.isEmpty ||
            p.title.toLowerCase().contains(q) ||
            (p.morada?.toLowerCase().contains(q) ?? false)) &&
        (_negocio == null || p.negocio == _negocio) &&
        (_distrito == null || p.distrito == _distrito) &&
        (_concelho == null || p.concelho == _concelho) &&
        (_freguesia == null || p.freguesia == _freguesia);
  }).toList();

  List<String> _values(Iterable<String?> values) =>
      ({...values.whereType<String>()}.toList()..sort());

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(propertiesStreamProvider);
    final all = value.value ?? const <Property>[];
    // Cada filtro só mostra opções compatíveis com os filtros acima dele.
    final inDistrito = all.where(
      (p) => _distrito == null || p.distrito == _distrito,
    );
    final inConcelho = inDistrito.where(
      (p) => _concelho == null || p.concelho == _concelho,
    );
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(AppRoute.newProperty.name),
        icon: const Icon(Icons.add_home_outlined),
        label: const Text('Cadastrar Novo Imóvel'),
      ),
      // Lista "preguiçosa": só desenha os cartões que estão no ecrã, para
      // continuar rápida com centenas de imóveis.
      body: LayoutBuilder(
        builder: (context, constraints) {
          final side =
              ((constraints.maxWidth - 1200) / 2).clamp(0.0, double.infinity) +
              Sizes.p16;
          final filtered = _filter(value.value ?? const <Property>[]);
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(side, Sizes.p16, side, Sizes.p16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PageHeader(
                        title: 'Imóveis',
                        subtitle:
                            '${all.length} imóveis em carteira. Cadastro, '
                            'importação por link e galeria de fotos.',
                      ),
                      gapH16,
                      Wrap(
                        spacing: Sizes.p12,
                        runSpacing: Sizes.p12,
                        children: [
                          SizedBox(
                            width: 260,
                            child: TextField(
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.search),
                                hintText: 'Pesquisar título ou morada',
                              ),
                              onChanged: (v) =>
                                  setState(() => _query = v.trim()),
                            ),
                          ),
                          _Filter(
                            label: 'Negócio',
                            value: _negocio,
                            options: PropertyOptions.negocios,
                            onChanged: (v) => setState(() => _negocio = v),
                          ),
                          _Filter(
                            label: 'Distrito',
                            value: _distrito,
                            options: _values(all.map((p) => p.distrito)),
                            onChanged: (v) => setState(() {
                              _distrito = v;
                              _concelho = null;
                              _freguesia = null;
                            }),
                          ),
                          _Filter(
                            label: 'Concelho',
                            value: _concelho,
                            options: _values(inDistrito.map((p) => p.concelho)),
                            onChanged: (v) => setState(() {
                              _concelho = v;
                              _freguesia = null;
                            }),
                          ),
                          _Filter(
                            label: 'Freguesia',
                            value: _freguesia,
                            options: _values(
                              inConcelho.map((p) => p.freguesia),
                            ),
                            onChanged: (v) => setState(() => _freguesia = v),
                          ),
                        ],
                      ),
                      gapH16,
                    ],
                  ),
                ),
              ),
              if (value.hasError && !value.hasValue)
                SliverToBoxAdapter(
                  child: EmptyPlaceholder(
                    icon: Icons.error_outline,
                    message: 'Ocorreu um erro: ${value.error}',
                  ),
                )
              else if (value.isLoading && !value.hasValue)
                const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (filtered.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyPlaceholder(
                    icon: Icons.home_outlined,
                    message: all.isEmpty
                        ? 'Nenhum imóvel cadastrado.'
                        : 'Nenhum imóvel corresponde aos filtros.',
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(side, 0, side, 96),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 340,
                          mainAxisExtent: 345,
                          crossAxisSpacing: Sizes.p16,
                          mainAxisSpacing: Sizes.p16,
                        ),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _PropertyCard(property: filtered[i]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Filter extends StatelessWidget {
  const _Filter({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      enabled: options.isNotEmpty,
      onSelected: (v) => onChanged(v.isEmpty ? null : v),
      itemBuilder: (_) => [
        const PopupMenuItem(value: '', child: Text('Todos')),
        for (final o in options) PopupMenuItem(value: o, child: Text(o)),
      ],
      child: Chip(
        avatar: const Icon(Icons.place_outlined, size: 18),
        label: Text('$label: ${value ?? 'Todos'}'),
        backgroundColor: value == null
            ? null
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
      ),
    );
  }
}

class _PropertyCard extends ConsumerWidget {
  const _PropertyCard({required this.property});
  final Property property;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = property;
    final scheme = Theme.of(context).colorScheme;
    final meta = [
      if (p.areaBruta != null) 'Bruta ${p.areaBruta} m²',
      if (p.quartos != null) '${p.quartos} quartos',
      if (p.wc != null) '${p.wc} WC',
    ].join(' · ');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushNamed(
          AppRoute.property.name,
          pathParameters: {'id': p.id},
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 160,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PropertyImage(url: p.cover),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Wrap(
                      spacing: 6,
                      children: [
                        if (p.negocio != null) _ImageBadge(label: p.negocio!),
                        if (p.saleStatus != null &&
                            p.saleStatus != 'Em Angariação')
                          _ImageBadge(
                            label:
                                PropertyOptions.saleStatusLabels[p
                                    .saleStatus] ??
                                p.saleStatus!,
                            color: p.isSold ? AppColors.green : AppColors.gold,
                          ),
                      ],
                    ),
                  ),
                  if (p.images.length > 1)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Chip(
                        visualDensity: VisualDensity.compact,
                        avatar: const Icon(
                          Icons.photo_library_outlined,
                          size: 14,
                        ),
                        label: Text('${p.images.length}'),
                      ),
                    ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: IconButton.filledTonal(
                      tooltip: 'Eliminar',
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: () => confirmAndDelete(
                        context,
                        () => ref
                            .read(propertiesRepositoryProvider)
                            .deleteProperty(
                              uid: ref.read(currentUidProvider),
                              id: p.id,
                            ),
                        success: 'Imóvel eliminado',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(Sizes.p12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    gapH4,
                    Text(
                      '${p.tags} • ${p.concelho ?? 'Local'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    gapH8,
                    Text(
                      Format.euros(p.price),
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
                    if (meta.isNotEmpty)
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    const Spacer(),
                    if (p.sourceUrl != null)
                      InkWell(
                        onTap: () => openExternalUrl(p.sourceUrl!),
                        child: Text(
                          'Fonte original',
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Etiqueta legível por cima de uma foto.
class _ImageBadge extends StatelessWidget {
  const _ImageBadge({required this.label, this.color});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color ?? Colors.black.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color == AppColors.gold ? AppColors.darkBg : Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
