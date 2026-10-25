import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:imovio/src/common_widgets/async_value_widget.dart';
import 'package:imovio/src/common_widgets/empty_placeholder.dart';
import 'package:imovio/src/common_widgets/page_header.dart';
import 'package:imovio/src/common_widgets/responsive_center.dart';
import 'package:imovio/src/common_widgets/status_badge.dart';
import 'package:imovio/src/constants/app_sizes.dart';
import 'package:imovio/src/constants/app_theme.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/contacts/application/contacts_csv.dart';
import 'package:imovio/src/features/contacts/data/contacts_repository.dart';
import 'package:imovio/src/features/contacts/domain/contact.dart';
import 'package:imovio/src/routing/app_router.dart';
import 'package:imovio/src/utils/dialogs.dart';
import 'package:imovio/src/utils/file_saver.dart';
import 'package:imovio/src/utils/run_action.dart';

Color contactTypeColor(String type) => switch (type) {
      ContactTypes.buyer => AppColors.green,
      ContactTypes.tenant => Colors.lightBlue,
      _ => AppColors.gold,
    };

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  var _query = '';
  String? _type;
  String? _origin;

  List<Contact> _filter(List<Contact> contacts) => contacts
      .where((c) =>
          (_query.isEmpty || c.matchesText(_query)) &&
          (_type == null || c.type == _type) &&
          (_origin == null || c.originLabel == _origin))
      .toList();

  void _export(List<Contact> contacts) {
    if (contacts.isEmpty) {
      showSnack(context, 'Sem contactos para exportar.');
      return;
    }
    final csv = contactsToCsv(contacts);
    final saved = saveTextFile(fileName: 'contactos_imovio.csv', content: csv);
    if (!saved) {
      Clipboard.setData(ClipboardData(text: csv));
      showSnack(context, 'CSV copiado para a área de transferência.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactsValue = ref.watch(contactsStreamProvider);
    final all = contactsValue.value ?? const <Contact>[];
    final origins = {for (final c in all) c.originLabel}.toList()..sort();
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(AppRoute.newContact.name),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Novo contacto'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ResponsiveCenter(
              padding: const EdgeInsets.all(Sizes.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PageHeader(
                    title: 'Contactos',
                    subtitle: '${all.length} contactos registados',
                    actions: [
                      OutlinedButton.icon(
                        onPressed: () => _export(all),
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Exportar CSV'),
                      ),
                    ],
                  ),
                  gapH16,
                  Wrap(
                    spacing: Sizes.p12,
                    runSpacing: Sizes.p12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 280,
                        child: TextField(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Pesquisar nome, email, telefone ou NIF',
                          ),
                          onChanged: (v) => setState(() => _query = v.trim()),
                        ),
                      ),
                      _FilterMenu(
                        label: 'Tipo',
                        value: _type,
                        options: ContactTypes.all,
                        onChanged: (v) => setState(() => _type = v),
                      ),
                      _FilterMenu(
                        label: 'Origem',
                        value: _origin,
                        options: origins,
                        onChanged: (v) => setState(() => _origin = v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: true,
            child: AsyncValueWidget<List<Contact>>(
              value: contactsValue,
              data: (contacts) {
                final filtered = _filter(contacts);
                if (filtered.isEmpty) {
                  return const EmptyPlaceholder(
                    icon: Icons.people_outline,
                    message: 'Nenhum contacto encontrado.',
                  );
                }
                return ResponsiveCenter(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  child: _ContactsList(contacts: filtered),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterMenu extends StatelessWidget {
  const _FilterMenu({
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
      onSelected: (v) => onChanged(v.isEmpty ? null : v),
      itemBuilder: (_) => [
        const PopupMenuItem(value: '', child: Text('Todos')),
        for (final o in options) PopupMenuItem(value: o, child: Text(o)),
      ],
      child: Chip(
        avatar: const Icon(Icons.filter_list, size: 18),
        label: Text(value == null ? '$label: Todos' : '$label: $value'),
      ),
    );
  }
}

class _ContactsList extends ConsumerWidget {
  const _ContactsList({required this.contacts});
  final List<Contact> contacts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = MediaQuery.sizeOf(context).width >= wideBreakpoint;
    void open(Contact c) =>
        context.pushNamed(AppRoute.contact.name, pathParameters: {'id': c.id});
    Widget actions(Contact c) => _ContactActions(contact: c);

    if (wide) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: DataTable(
            showCheckboxColumn: false,
            columns: const [
              DataColumn(label: Text('Nome')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Telefone')),
              DataColumn(label: Text('Tipo')),
              DataColumn(label: Text('Origem')),
              DataColumn(label: Text('Ações')),
            ],
            rows: [
              for (final c in contacts)
                DataRow(
                  onSelectChanged: (_) => open(c),
                  cells: [
                    DataCell(Text(c.name,
                        style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text(c.email ?? '—')),
                    DataCell(Text(c.phone ?? '—')),
                    DataCell(StatusBadge(
                        label: c.type, color: contactTypeColor(c.type))),
                    DataCell(Text(c.originLabel)),
                    DataCell(actions(c)),
                  ],
                ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: contacts.length,
      separatorBuilder: (_, _) => gapH8,
      itemBuilder: (context, i) {
        final c = contacts[i];
        return Card(
          child: ListTile(
            onTap: () => open(c),
            leading: CircleAvatar(
              backgroundColor: contactTypeColor(c.type).withValues(alpha: 0.2),
              child: Text(c.name.isEmpty ? '?' : c.name[0].toUpperCase()),
            ),
            title: Text(c.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text([c.phone, c.email, c.originLabel]
                .whereType<String>()
                .join(' · ')),
            trailing: actions(c),
          ),
        );
      },
    );
  }
}

class _ContactActions extends ConsumerWidget {
  const _ContactActions({required this.contact});
  final Contact contact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(contactsRepositoryProvider);
    final uid = ref.read(currentUidProvider);
    return PopupMenuButton<String>(
      tooltip: 'Ações',
      onSelected: (action) {
        switch (action) {
          case 'edit':
            context.pushNamed(AppRoute.contact.name,
                pathParameters: {'id': contact.id});
          case 'duplicate':
            runAction(
              context,
              () => repo.duplicateContact(uid: uid, contact: contact),
              success: 'Contacto duplicado',
            );
          case 'delete':
            confirmAndDelete(
              context,
              () => repo.deleteContact(uid: uid, id: contact.id),
              success: 'Contacto eliminado',
            );
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
            value: 'edit',
            child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Editar'))),
        PopupMenuItem(
            value: 'duplicate',
            child: ListTile(leading: Icon(Icons.copy_outlined), title: Text('Duplicar'))),
        PopupMenuItem(
            value: 'delete',
            child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Eliminar'))),
      ],
    );
  }
}
