import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:imovio/src/common_widgets/async_value_widget.dart';
import 'package:imovio/src/common_widgets/date_time_field.dart';
import 'package:imovio/src/common_widgets/empty_placeholder.dart';
import 'package:imovio/src/common_widgets/form_fields.dart';
import 'package:imovio/src/common_widgets/record_pickers.dart';
import 'package:imovio/src/common_widgets/responsive_center.dart';
import 'package:imovio/src/common_widgets/section_card.dart';
import 'package:imovio/src/common_widgets/status_badge.dart';
import 'package:imovio/src/constants/app_sizes.dart';
import 'package:imovio/src/features/contacts/data/contacts_repository.dart';
import 'package:imovio/src/features/pipeline/data/deals_repository.dart';
import 'package:imovio/src/features/pipeline/presentation/deal_tile.dart';
import 'package:imovio/src/features/properties/application/commission.dart';
import 'package:imovio/src/features/properties/application/property_matching.dart';
import 'package:imovio/src/features/properties/data/properties_repository.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
import 'package:imovio/src/features/properties/presentation/gallery_editor.dart';
import 'package:imovio/src/features/properties/presentation/property_edit_controller.dart';
import 'package:imovio/src/features/properties/presentation/property_form_fields.dart';
import 'package:imovio/src/features/properties/presentation/property_list_tile.dart';
import 'package:imovio/src/features/tasks/data/tasks_repository.dart';
import 'package:imovio/src/features/tasks/domain/task.dart';
import 'package:imovio/src/features/tasks/presentation/task_tile.dart';
import 'package:imovio/src/routing/app_router.dart';
import 'package:imovio/src/utils/async_value_ui.dart';
import 'package:imovio/src/utils/dialogs.dart';
import 'package:imovio/src/utils/format.dart';
import 'package:imovio/src/utils/launcher.dart';

/// Página de detalhe do imóvel: capa, e as 3 abas da app original
/// (detalhes, contactos/visitas, detalhes de venda).
class PropertyDetailScreen extends ConsumerWidget {
  const PropertyDetailScreen({super.key, required this.propertyId});
  final PropertyID propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncValueWidget<Property?>(
      value: ref.watch(propertyStreamProvider(propertyId)),
      data: (property) {
        if (property == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyPlaceholder(
              icon: Icons.home_outlined,
              message: 'Este imóvel já não existe.',
            ),
          );
        }
        return _PropertyDetail(key: ValueKey(property.id), property: property);
      },
    );
  }
}

class _PropertyDetail extends ConsumerStatefulWidget {
  const _PropertyDetail({super.key, required this.property});
  final Property property;

  @override
  ConsumerState<_PropertyDetail> createState() => _PropertyDetailState();
}

class _PropertyDetailState extends ConsumerState<_PropertyDetail>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 3, vsync: this);
  final _formKey = GlobalKey<FormState>();
  late final _data = PropertyFormData(widget.property);

  @override
  void initState() {
    super.initState();
    _data['price'].addListener(_recalculateCommission);
    _data['commissionPct'].addListener(_recalculateCommission);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _data.dispose();
    super.dispose();
  }

  void _recalculateCommission() {
    final value = commissionValue(
      price: parseNum(_data['price'].text),
      percent: parseNum(_data['commissionPct'].text),
    );
    if (value != null) {
      final text = value.toStringAsFixed(2);
      if (_data['commissionVal'].text != text) {
        _data['commissionVal'].text = text;
      }
    }
  }

  Future<void> _save() async {
    if (_data['title'].text.trim().isEmpty ||
        parseNum(_data['price'].text) == null ||
        !_formKey.currentState!.validate()) {
      _tabs.animateTo(0);
      showSnack(context, 'Preencha pelo menos o título e o preço.',
          error: true);
      return;
    }
    final ok = await ref
        .read(propertyEditControllerProvider.notifier)
        .submit(_data.toProperty(), isNew: false);
    if (ok && mounted) {
      showSnack(context, 'Detalhes do imóvel atualizados com sucesso!');
    }
  }

  Future<void> _delete() async {
    if (!await showConfirmDialog(context,
            message: 'Eliminar o imóvel ${widget.property.title}?') ||
        !mounted) {
      return;
    }
    final ok = await ref
        .read(propertyEditControllerProvider.notifier)
        .delete(widget.property.id);
    if (ok && mounted) {
      showSnack(context, 'Imóvel eliminado');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(propertyEditControllerProvider,
        (_, s) => s.showSnackBarOnError(context));
    final saving = ref.watch(propertyEditControllerProvider).isLoading;
    final p = widget.property;
    return Scaffold(
      body: Form(
        key: _formKey,
        child: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverAppBar(
              pinned: true,
              expandedHeight: 260,
              title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              actions: [
                IconButton(
                  tooltip: 'Estudo de mercado',
                  icon: const Icon(Icons.query_stats),
                  onPressed: () => context.pushNamed(
                    AppRoute.marketStudy.name,
                    pathParameters: {'id': p.id},
                  ),
                ),
                if (p.sourceUrl != null)
                  IconButton(
                    tooltip: 'Fonte original',
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () => openExternalUrl(p.sourceUrl!),
                  ),
                IconButton(
                  tooltip: 'Eliminar imóvel',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: saving ? null : _delete,
                ),
                gapW8,
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    PropertyImage(
                        url: _data.images.isEmpty
                            ? PropertyOptions.defaultImage
                            : _data.images.first),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black54, Colors.transparent, Colors.black87],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      bottom: 16,
                      right: 16,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              '${p.tags} · ${p.concelho ?? 'Local'}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          Text(
                            Format.euros(p.price),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottom: TabBar(
                controller: _tabs,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: const [
                  Tab(text: '1. Detalhes do Imóvel'),
                  Tab(text: '2. Contactos / Visitas'),
                  Tab(text: '3. Detalhes de Venda'),
                ],
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabs,
            children: [
              _tab(Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.query_stats),
                    label: const Text('Estudo de Mercado (PDF)'),
                    onPressed: () => context.pushNamed(
                      AppRoute.marketStudy.name,
                      pathParameters: {'id': p.id},
                    ),
                  ),
                  gapH16,
                  SectionCard(
                    title: 'Caracterização',
                    icon: Icons.home_outlined,
                    child: PropertyFieldsForm(
                      data: _data,
                      onChanged: () => setState(() {}),
                    ),
                  ),
                  gapH16,
                  SectionCard(
                    title: 'Fotografias',
                    icon: Icons.photo_library_outlined,
                    child: GalleryEditor(
                      propertyId: p.id,
                      images: _data.images,
                      onChanged: (imgs) => setState(() => _data.images = imgs),
                    ),
                  ),
                ],
              )),
              _tab(_ContactsTab(
                property: p,
                ownerId: _data.ownerId,
                onOwnerChanged: (id) => setState(() => _data.ownerId = id),
              )),
              _tab(_saleTab()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Sizes.p12),
          child: FilledButton(
            onPressed: saving ? null : _save,
            child: const Text('Guardar Alterações'),
          ),
        ),
      ),
    );
  }

  Widget _tab(Widget child) => ListView(
        padding: EdgeInsets.zero,
        children: [
          ResponsiveCenter(
            maxContentWidth: 900,
            padding: const EdgeInsets.all(Sizes.p16),
            child: child,
          ),
        ],
      );

  Widget _saleTab() {
    DateTime? d(String key) => parseDate(_data[key].text);
    void setDate(String key, DateTime? v) => setState(
        () => _data[key].text = v == null ? '' : formatIsoDate(v));
    return SectionCard(
      title: 'Venda e comissão',
      icon: Icons.euro,
      child: FormGrid(children: [
        TextDropdown(
          label: 'Estado da Angariação / Venda',
          value: _data.saleStatus,
          options: PropertyOptions.saleStatuses,
          optionLabels: PropertyOptions.saleStatusLabels,
          onChanged: (v) =>
              setState(() => _data.saleStatus = v ?? _data.saleStatus),
        ),
        TextFormField(
          controller: _data['price'],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration:
              const InputDecoration(labelText: 'Valor de Venda / Fecho (€)'),
        ),
        TextFormField(
          controller: _data['commissionPct'],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
              labelText: 'Comissão (%)', hintText: '5'),
        ),
        TextFormField(
          controller: _data['commissionVal'],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Valor da Comissão (€)',
            helperText: 'Calculado a partir do valor e da percentagem',
          ),
        ),
        DateTimeField(
          label: 'Data de Angariação',
          withTime: false,
          value: d('dateStart'),
          onChanged: (v) => setDate('dateStart', v),
        ),
        DateTimeField(
          label: 'Data Prevista / Fecho',
          withTime: false,
          value: d('dateEnd'),
          onChanged: (v) => setDate('dateEnd', v),
        ),
        FullWidth(
          child: TextFormField(
            controller: _data['saleNotes'],
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Notas de Negociação e Condições de Venda',
              hintText: 'Condições do CPCV, prazos de financiamento...',
            ),
          ),
        ),
      ]),
    );
  }
}

class _ContactsTab extends ConsumerWidget {
  const _ContactsTab({
    required this.property,
    required this.ownerId,
    required this.onOwnerChanged,
  });
  final Property property;
  final String? ownerId;
  final ValueChanged<String?> onOwnerChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owner = ref.watch(contactsByIdProvider)[ownerId];
    final contacts = ref.watch(contactsStreamProvider).value ?? const [];
    final visits = (ref.watch(tasksStreamProvider).value ?? const <Task>[])
        .where((t) =>
            t.propertyId == property.id &&
            t.category == TaskCategories.visit)
        .toList();
    final deals = (ref.watch(dealsStreamProvider).value ?? const [])
        .where((d) => d.propertyId == property.id)
        .toList();
    final interested = contacts
        .where((c) => matchingProperties(c, [property]).isNotEmpty)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'Proprietário / Vendedor',
          icon: Icons.person_outline,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ContactPicker(
                label: 'Contacto',
                value: ownerId,
                emptyLabel: 'Sem proprietário associado',
                onChanged: onOwnerChanged,
              ),
              if (owner != null) ...[
                gapH12,
                Text([owner.phone, owner.email]
                    .whereType<String>()
                    .join(' · ')),
                TextButton(
                  onPressed: () => context.pushNamed(AppRoute.contact.name,
                      pathParameters: {'id': owner.id}),
                  child: const Text('Abrir ficha do contacto'),
                ),
              ],
            ],
          ),
        ),
        gapH16,
        SectionCard(
          title: 'Visitas',
          icon: Icons.event_outlined,
          trailing: TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Agendar Visita'),
            onPressed: () => context.pushNamed(
              AppRoute.newTask.name,
              queryParameters: {
                'propertyId': property.id,
                'category': TaskCategories.visit,
              },
            ),
          ),
          child: visits.isEmpty
              ? const Text('Sem visitas agendadas para este imóvel.')
              : Column(children: [for (final v in visits) TaskTile(task: v)]),
        ),
        gapH16,
        SectionCard(
          title: 'Negócios com este imóvel',
          icon: Icons.handshake_outlined,
          child: deals.isEmpty
              ? const Text('Sem negócios associados.')
              : Column(children: [for (final d in deals) DealTile(deal: d)]),
        ),
        gapH16,
        SectionCard(
          title: 'Interessados compatíveis',
          icon: Icons.auto_awesome_outlined,
          child: interested.isEmpty
              ? const Text(
                  'Nenhum contacto tem preferências compatíveis com este imóvel.')
              : Column(
                  children: [
                    for (final c in interested)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(c.name),
                        subtitle: Text(c.phone ?? c.email ?? ''),
                        trailing: StatusBadge(label: c.type),
                        onTap: () => context.pushNamed(AppRoute.contact.name,
                            pathParameters: {'id': c.id}),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
