import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:imovio/src/common_widgets/async_value_widget.dart';
import 'package:imovio/src/common_widgets/empty_placeholder.dart';
import 'package:imovio/src/common_widgets/form_fields.dart';
import 'package:imovio/src/common_widgets/responsive_center.dart';
import 'package:imovio/src/common_widgets/section_card.dart';
import 'package:imovio/src/constants/app_sizes.dart';
import 'package:imovio/src/features/contacts/data/contacts_repository.dart';
import 'package:imovio/src/features/contacts/domain/contact.dart';
import 'package:imovio/src/features/contacts/presentation/contact_edit_controller.dart';
import 'package:imovio/src/features/pipeline/data/deals_repository.dart';
import 'package:imovio/src/features/pipeline/presentation/deal_tile.dart';
import 'package:imovio/src/features/properties/application/property_matching.dart';
import 'package:imovio/src/features/properties/data/properties_repository.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
import 'package:imovio/src/features/properties/presentation/property_list_tile.dart';
import 'package:imovio/src/features/tasks/data/tasks_repository.dart';
import 'package:imovio/src/features/tasks/presentation/task_tile.dart';
import 'package:imovio/src/features/team/presentation/team_listing_tile.dart';
import 'package:imovio/src/routing/app_router.dart';
import 'package:imovio/src/utils/async_value_ui.dart';
import 'package:imovio/src/utils/dialogs.dart';
import 'package:imovio/src/utils/format.dart';
import 'package:imovio/src/utils/launcher.dart';

/// Ficha do contacto (novo quando [contactId] é null), com as 3 abas da app
/// original: dados gerais, imóvel e histórico.
class ContactEditScreen extends ConsumerWidget {
  const ContactEditScreen({super.key, this.contactId});
  final ContactID? contactId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (contactId == null) return const _ContactForm(contact: null);
    final contacts = ref.watch(contactsStreamProvider);
    return AsyncValueWidget<List<Contact>>(
      value: contacts,
      data: (list) {
        final contact = list.where((c) => c.id == contactId).firstOrNull;
        if (contact == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyPlaceholder(
              icon: Icons.person_off_outlined,
              message: 'Este contacto já não existe.',
            ),
          );
        }
        return _ContactForm(key: ValueKey(contact.id), contact: contact);
      },
    );
  }
}

class _ContactForm extends ConsumerStatefulWidget {
  const _ContactForm({super.key, required this.contact});
  final Contact? contact;

  @override
  ConsumerState<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends ConsumerState<_ContactForm>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 3, vsync: this);
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;
  late String _type;
  late String _idType;
  String? _prefTipo;
  String? _prefTipologia;

  bool get _isNew => widget.contact == null;

  @override
  void initState() {
    super.initState();
    final c = widget.contact;
    TextEditingController t(String? v) => TextEditingController(text: v ?? '');
    _c = {
      'name': t(c?.name),
      'email': t(c?.email),
      'phone': t(c?.phone),
      'origin': t(c?.origin),
      'birth': t(c?.birth),
      'nif': t(c?.nif),
      'idNum': t(c?.idNum),
      'address': t(c?.address),
      'numFloor': t(c?.numFloor),
      'zip': t(c?.zip),
      'city': t(c?.city),
      'notes': t(c?.notes),
      'prefDistrito': t(c?.preferences.distrito),
      'prefConcelho': t(c?.preferences.concelho),
      'prefMaxPrice': t(c?.preferences.maxPrice?.toString()),
    };
    _type = c?.type ?? ContactTypes.buyer;
    _idType = c?.idType ?? IdDocumentTypes.all.first;
    _prefTipo = c?.preferences.tipo;
    _prefTipologia = c?.preferences.tipologia;
  }

  @override
  void dispose() {
    _tabs.dispose();
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  String? _v(String key) => emptyToNull(_c[key]!.text);

  Contact _buildContact() => Contact(
        id: widget.contact?.id ?? '',
        name: _c['name']!.text.trim(),
        email: _v('email'),
        phone: _v('phone'),
        type: _type,
        origin: _v('origin'),
        birth: _v('birth'),
        nif: _v('nif'),
        idType: _idType,
        idNum: _v('idNum'),
        address: _v('address'),
        numFloor: _v('numFloor'),
        zip: _v('zip'),
        city: _v('city'),
        notes: _v('notes'),
        preferences: PropertyPreferences(
          distrito: _v('prefDistrito'),
          concelho: _v('prefConcelho'),
          tipo: _prefTipo,
          tipologia: _prefTipologia,
          maxPrice: parseNum(_c['prefMaxPrice']!.text),
        ),
        createdAt: widget.contact?.createdAt,
      );

  Future<void> _save() async {
    // Os campos de abas não visíveis não são validados pelo Form.
    if (_c['name']!.text.trim().isEmpty ||
        !_formKey.currentState!.validate()) {
      _tabs.animateTo(0);
      showSnack(context, 'Por favor insira um nome.', error: true);
      return;
    }
    final id = await ref
        .read(contactEditControllerProvider.notifier)
        .submit(_buildContact(), isNew: _isNew);
    if (id != null && mounted) {
      showSnack(context, _isNew ? 'Contacto criado' : 'Alterações guardadas');
      context.pop();
    }
  }

  Future<void> _delete() async {
    final ok = await showConfirmDialog(context,
        message: 'Eliminar o contacto ${widget.contact!.name}?');
    if (!ok || !mounted) return;
    final deleted = await ref
        .read(contactEditControllerProvider.notifier)
        .delete(widget.contact!.id);
    if (deleted && mounted) {
      showSnack(context, 'Contacto eliminado');
      context.pop();
    }
  }

  Widget _field(String key, String label,
      {String? hint,
      TextInputType? keyboard,
      int maxLines = 1,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: _c[key],
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(contactEditControllerProvider,
        (_, state) => state.showSnackBarOnError(context));
    final saving = ref.watch(contactEditControllerProvider).isLoading;
    final contact = widget.contact;
    return Scaffold(
        appBar: AppBar(
          title: Text(_isNew ? 'Novo contacto' : 'Editar contacto'),
          actions: [
            if (contact?.phone != null) ...[
              IconButton(
                tooltip: 'Ligar',
                icon: const Icon(Icons.call_outlined),
                onPressed: () => callPhone(contact!.phone!),
              ),
              IconButton(
                tooltip: 'WhatsApp',
                icon: const Icon(Icons.chat_outlined),
                onPressed: () => openWhatsApp(contact!.phone!),
              ),
            ],
            if (contact?.email != null)
              IconButton(
                tooltip: 'Enviar email',
                icon: const Icon(Icons.mail_outline),
                onPressed: () => sendEmail(contact!.email!),
              ),
            if (!_isNew)
              IconButton(
                tooltip: 'Eliminar contacto',
                icon: const Icon(Icons.delete_outline),
                onPressed: saving ? null : _delete,
              ),
            gapW8,
          ],
          bottom: TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: '1. Dados Gerais'),
              Tab(text: '2. Imóvel'),
              Tab(text: '3. Histórico e Tarefas'),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Sizes.p12),
            child: FilledButton.icon(
              onPressed: saving ? null : _save,
              icon: saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check),
              label: Text(_isNew ? 'Criar contacto' : 'Guardar alterações'),
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: TabBarView(
            controller: _tabs,
            children: [
              _tab(_generalTab()),
              _tab(_preferencesTab()),
              _tab(_HistoryTab(contact: contact)),
            ],
          ),
        ),
    );
  }

  Widget _tab(Widget child) => ListView(
        children: [
          ResponsiveCenter(
            maxContentWidth: 820,
            padding: const EdgeInsets.all(Sizes.p16),
            child: child,
          ),
        ],
      );

  Widget _generalTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'Identificação',
          icon: Icons.badge_outlined,
          child: FormGrid(children: [
            FullWidth(
              child: _field('name', 'Nome',
                  hint: 'Manuel José Bento Palma',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Por favor insira um nome.'
                      : null),
            ),
            _field('email', 'Email', keyboard: TextInputType.emailAddress),
            _field('phone', 'Telefone',
                hint: '351918515243', keyboard: TextInputType.phone),
            TextDropdown(
              label: 'Tipo',
              value: _type,
              options: ContactTypes.all,
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            _field('origin', 'Origem', hint: 'amigo, idealista'),
            _DateField(controller: _c['birth']!, label: 'Data de nascimento'),
            _field('nif', 'NIF', hint: '179552015', keyboard: TextInputType.number),
            TextDropdown(
              label: 'Tipo de Identificação',
              value: _idType,
              options: IdDocumentTypes.all,
              onChanged: (v) => setState(() => _idType = v ?? _idType),
            ),
            _field('idNum', 'Nº do Documento', hint: '07410819'),
          ]),
        ),
        gapH16,
        SectionCard(
          title: 'Morada',
          icon: Icons.location_on_outlined,
          child: FormGrid(children: [
            FullWidth(child: _field('address', 'Rua / Morada')),
            _field('numFloor', 'Nº / Andar'),
            _field('zip', 'Código Postal', hint: '0000-000'),
            FullWidth(child: _field('city', 'Localidade')),
          ]),
        ),
        gapH16,
        SectionCard(
          title: 'Observações',
          icon: Icons.notes_outlined,
          child: _field('notes', 'Observações Gerais do Contacto', maxLines: 4),
        ),
      ],
    );
  }

  Widget _preferencesTab() {
    final properties = ref.watch(propertiesStreamProvider).value ?? const [];
    final matches = widget.contact == null
        ? const <Property>[]
        : matchingProperties(widget.contact!, properties);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'O que procura',
          icon: Icons.search,
          child: FormGrid(children: [
            _field('prefDistrito', 'Distrito', hint: 'Ex.: Setúbal'),
            _field('prefConcelho', 'Concelho', hint: 'Ex.: Almada'),
            TextDropdown(
              label: 'Tipo de imóvel',
              value: _prefTipo,
              options: PropertyOptions.tipos,
              allowEmpty: true,
              onChanged: (v) => setState(() => _prefTipo = v),
            ),
            TextDropdown(
              label: 'Tipologia',
              value: _prefTipologia,
              options: PropertyOptions.tipologias,
              allowEmpty: true,
              onChanged: (v) => setState(() => _prefTipologia = v),
            ),
            _field('prefMaxPrice', 'Preço máximo (€)',
                keyboard: TextInputType.number),
          ]),
        ),
        gapH16,
        SectionCard(
          title: 'Imóveis compatíveis',
          icon: Icons.auto_awesome_outlined,
          child: widget.contact == null
              ? const Text('Guarde o contacto para ver sugestões.')
              : matches.isEmpty
                  ? const Text(
                      'Sem imóveis compatíveis. As sugestões usam as '
                      'preferências guardadas e o tipo de contacto.')
                  : Column(
                      children: [
                        for (final p in matches) PropertyListTile(property: p),
                      ],
                    ),
        ),
        if (widget.contact != null)
          TeamMatchesSection(contact: widget.contact!),
      ],
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab({required this.contact});
  final Contact? contact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = contact;
    if (c == null) {
      return const SectionCard(
        child: Text('Sem registos ainda. Guarde o contacto para adicionar '
            'tarefas e negócios.'),
      );
    }
    final tasks = (ref.watch(tasksStreamProvider).value ?? const [])
        .where((t) => t.contactId == c.id)
        .toList();
    final deals = (ref.watch(dealsStreamProvider).value ?? const [])
        .where((d) => d.contactId == c.id)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'Tarefas',
          icon: Icons.task_alt,
          trailing: TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Nova tarefa'),
            onPressed: () => context.pushNamed(
              AppRoute.newTask.name,
              queryParameters: {'contactId': c.id},
            ),
          ),
          child: tasks.isEmpty
              ? const Text('Sem tarefas para este contacto.')
              : Column(children: [for (final t in tasks) TaskTile(task: t)]),
        ),
        gapH16,
        SectionCard(
          title: 'Negócios',
          icon: Icons.handshake_outlined,
          trailing: TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Novo negócio'),
            onPressed: () => context.pushNamed(
              AppRoute.newDeal.name,
              queryParameters: {'contactId': c.id},
            ),
          ),
          child: deals.isEmpty
              ? const Text('Sem negócios para este contacto.')
              : Column(children: [for (final d in deals) DealTile(deal: d)]),
        ),
        gapH16,
        SectionCard(
          title: 'Linha do tempo',
          icon: Icons.timeline,
          child: Text(
            [
              if (c.createdAt != null)
                'Criado em ${Format.dateTime(DateTime.fromMillisecondsSinceEpoch(c.createdAt!))}',
              if (c.updatedAt != null)
                'Última alteração em ${Format.dateTime(DateTime.fromMillisecondsSinceEpoch(c.updatedAt!))}',
            ].join('\n').ifEmpty('Sem registos ainda.'),
          ),
        ),
      ],
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

/// Campo de data que guarda "yyyy-MM-dd", como o input date do HTML.
class _DateField extends StatelessWidget {
  const _DateField({required this.controller, required this.label});
  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
      ),
      onTap: () async {
        final initial = parseDate(controller.text) ?? DateTime(1980);
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (picked != null) controller.text = formatIsoDate(picked);
      },
    );
  }
}
