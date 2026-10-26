import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:imovio/src/features/documents_ai/presentation/pick_document.dart';
import 'package:imovio/src/features/ai/data/gemini_client.dart';
import 'package:imovio/src/features/templates/presentation/send_message_sheet.dart';
import 'package:imovio/src/common_widgets/async_value_widget.dart';
import 'package:imovio/src/common_widgets/empty_placeholder.dart';
import 'package:imovio/src/common_widgets/form_fields.dart';
import 'package:imovio/src/common_widgets/responsive_center.dart';
import 'package:imovio/src/common_widgets/section_card.dart';
import 'package:imovio/src/constants/app_sizes.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/interactions/application/contact_actions.dart';
import 'package:imovio/src/features/interactions/data/interactions_repository.dart';
import 'package:imovio/src/features/interactions/presentation/interaction_dialog.dart';
import 'package:imovio/src/features/interactions/presentation/interaction_tile.dart';
import 'package:imovio/src/utils/run_action.dart';
import 'package:imovio/src/features/contacts/data/contacts_repository.dart';
import 'package:imovio/src/features/contacts/domain/contact.dart';
import 'package:imovio/src/features/contacts/presentation/contact_attachments_section.dart';
import 'package:imovio/src/features/contacts/presentation/contact_edit_controller.dart';
import 'package:imovio/src/features/contacts/presentation/preferences_editor.dart';
import 'package:imovio/src/features/pipeline/data/deals_repository.dart';
import 'package:imovio/src/features/pipeline/presentation/deal_tile.dart';
import 'package:imovio/src/features/properties/application/property_matching.dart';
import 'package:imovio/src/features/properties/data/properties_repository.dart';
import 'package:imovio/src/features/properties/presentation/property_list_tile.dart';
import 'package:imovio/src/features/tasks/data/tasks_repository.dart';
import 'package:imovio/src/features/tasks/presentation/task_tile.dart';
import 'package:imovio/src/features/team/presentation/team_listing_tile.dart';
import 'package:imovio/src/routing/app_router.dart';
import 'package:imovio/src/utils/async_value_ui.dart';
import 'package:imovio/src/utils/dialogs.dart';
import 'package:imovio/src/utils/format.dart';

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
  late final _prefs = PreferencesController(
      widget.contact?.preferences ?? const PropertyPreferences());

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
    };
    _type = c?.type ?? ContactTypes.buyer;
    _idType = c?.idType ?? IdDocumentTypes.all.first;
  }

  @override
  void dispose() {
    _tabs.dispose();
    _prefs.dispose();
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
        preferences: _prefs.value,
        attachments: widget.contact?.attachments ?? const [],
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

  var _readingId = false;

  /// Preenche a identificação a partir de uma foto do CC ou passaporte.
  Future<void> _readIdCard() async {
    final picked = await pickDocumentForAi(
      context,
      ref,
      documentName: 'o documento de identificação',
      personalData: true,
    );
    if (picked == null || !mounted) return;
    setState(() => _readingId = true);
    try {
      final d = await picked.$1.readIdCard(picked.$2);
      if (!mounted) return;
      if (d.isEmpty) {
        showSnack(context, 'Não consegui ler o documento. Tente outra foto.',
            error: true);
        return;
      }
      setState(() {
        void set(String key, String? v) {
          if (v != null) _c[key]!.text = v;
        }

        set('name', d.name);
        set('nif', d.nif);
        set('idNum', d.docNumber);
        set('birth', d.birth);
        if (d.docType != null && IdDocumentTypes.all.contains(d.docType)) {
          _idType = d.docType!;
        }
      });
      showSnack(context, 'Dados preenchidos. Confirme-os antes de guardar.');
    } on GeminiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } catch (e) {
      if (mounted) showSnack(context, 'Erro ao ler: $e', error: true);
    } finally {
      if (mounted) setState(() => _readingId = false);
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
                onPressed: () => ContactActions(ref).call(contact!),
              ),
              IconButton(
                tooltip: 'WhatsApp',
                icon: const Icon(Icons.chat_outlined),
                onPressed: () => ContactActions(ref).whatsapp(contact!),
              ),
            ],
            if (contact != null)
              PopupMenuButton<String>(
                tooltip: 'Mais',
                onSelected: (action) {
                  switch (action) {
                    case 'message':
                      showSendMessageSheet(
                        context,
                        contact: contact,
                        initialTemplateId: 'builtin-seguimento',
                      );
                    case 'email':
                      ContactActions(ref).email(contact);
                    case 'delete':
                      if (!saving) _delete();
                  }
                },
                itemBuilder: (_) => [
                  if (contact.phone != null || contact.email != null)
                    const PopupMenuItem(
                      value: 'message',
                      child: ListTile(
                        leading: Icon(Icons.send_outlined),
                        title: Text('Mensagem com modelo'),
                      ),
                    ),
                  if (contact.email != null)
                    const PopupMenuItem(
                      value: 'email',
                      child: ListTile(
                        leading: Icon(Icons.mail_outline),
                        title: Text('Enviar email'),
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline),
                      title: Text('Eliminar contacto'),
                    ),
                  ),
                ],
              ),
            gapW4,
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
            // Deslizar na página é o gesto de voltar; as abas mudam com toque.
            physics: const NeverScrollableScrollPhysics(),
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
          trailing: TextButton.icon(
            icon: _readingId
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.document_scanner_outlined),
            label: const Text('Ler documento (IA)'),
            onPressed: _readingId ? null : _readIdCard,
          ),
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
        gapH16,
        if (widget.contact != null)
          ContactAttachmentsSection(contact: widget.contact!)
        else
          const SectionCard(
            title: 'Documentos',
            icon: Icons.attach_file,
            child: Text('Guarde o contacto para poder anexar documentos.'),
          ),
      ],
    );
  }

  Widget _preferencesTab() {
    final properties = ref.watch(propertiesStreamProvider).value ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PreferencesEditor(controller: _prefs),
        gapH16,
        // As sugestões atualizam-se enquanto se escolhem as preferências.
        ValueListenableBuilder(
          valueListenable: _prefs,
          builder: (context, prefs, _) {
            final draft = Contact(
              id: widget.contact?.id ?? '',
              name: '',
              type: _type,
              preferences: prefs,
            );
            final matches = rankMatchingProperties(draft, properties);
            return SectionCard(
              title: 'Imóveis compatíveis (${matches.length})',
              icon: Icons.auto_awesome_outlined,
              child: matches.isEmpty
                  ? const Text(
                      'Sem imóveis compatíveis. As sugestões usam o tipo de '
                      'negócio, imóvel, tipologia, zona, preço, área e casas de '
                      'banho; as comodidades servem para ordenar.')
                  : Column(
                      children: [
                        for (final m in matches)
                          PropertyListTile(
                            property: m.property,
                            subtitleExtra: m.extrasWanted == 0
                                ? null
                                : '${m.extrasMatched}/${m.extrasWanted} comodidades',
                          ),
                      ],
                    ),
            );
          },
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
        _Timeline(contact: c),
      ],
    );
  }
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


/// Chamadas, mensagens, visitas e notas, das mais recentes para as mais
/// antigas. As feitas pelos botões da app entram sozinhas.
class _Timeline extends ConsumerWidget {
  const _Timeline({required this.contact});
  final Contact contact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(interactionsByContactProvider)[contact.id] ?? const [];
    final created = contact.createdAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(contact.createdAt!);
    return SectionCard(
      title: 'Linha do tempo',
      icon: Icons.timeline,
      trailing: TextButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('Registar'),
        onPressed: () async {
          final i = await showInteractionDialog(context, contactId: contact.id);
          if (i == null || !context.mounted) return;
          await runAction(
            context,
            () => ref
                .read(interactionsRepositoryProvider)
                .add(uid: ref.read(currentUidProvider), interaction: i),
            success: 'Registado na linha do tempo',
          );
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final i in items) InteractionTile(interaction: i),
          if (items.isEmpty)
            const Text(
              'Sem registos. As chamadas, WhatsApps e emails feitos pelos '
              'botões do contacto aparecem aqui sozinhos.',
            ),
          if (created != null) ...[
            gapH8,
            Text('Contacto criado em ${Format.dateTime(created)}',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}
