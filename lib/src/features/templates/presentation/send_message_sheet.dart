import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imovio/src/constants/app_sizes.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/contacts/domain/contact.dart';
import 'package:imovio/src/features/interactions/application/contact_actions.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
import 'package:imovio/src/features/templates/data/templates_repository.dart';
import 'package:imovio/src/features/templates/domain/message_template.dart';

/// Nome do consultor para os modelos: o nome da conta ou o início do email.
String consultantName(WidgetRef ref) {
  final user = ref.read(authRepositoryProvider).currentUser;
  final name = user?.displayName?.trim();
  if (name != null && name.isNotEmpty) return name;
  return user?.email?.split('@').first ?? '';
}

/// Escolher um modelo, rever o texto e enviar por WhatsApp, SMS ou email.
/// O envio fica registado na linha do tempo do contacto.
Future<void> showSendMessageSheet(
  BuildContext context, {
  required Contact contact,
  Property? property,
  String initialTemplateId = 'builtin-novo-imovel',
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _SendMessageSheet(
        contact: contact,
        property: property,
        initialTemplateId: initialTemplateId,
      ),
    );

class _SendMessageSheet extends ConsumerStatefulWidget {
  const _SendMessageSheet({
    required this.contact,
    required this.property,
    required this.initialTemplateId,
  });
  final Contact contact;
  final Property? property;
  final String initialTemplateId;

  @override
  ConsumerState<_SendMessageSheet> createState() => _SendMessageSheetState();
}

class _SendMessageSheetState extends ConsumerState<_SendMessageSheet> {
  final _text = TextEditingController();
  String? _subject;
  String? _selected;

  void _apply(MessageTemplate t) {
    final consultant = consultantName(ref);
    setState(() {
      _selected = t.id;
      _subject = t.subject == null
          ? null
          : fillTemplate(t.subject!,
              contact: widget.contact,
              property: widget.property,
              consultant: consultant);
      _text.text = fillTemplate(t.body,
          contact: widget.contact,
          property: widget.property,
          consultant: consultant);
    });
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(templatesProvider).value ?? builtInTemplates;
    if (_selected == null && templates.isNotEmpty) {
      final initial = templates.firstWhere(
        (t) => t.id == widget.initialTemplateId,
        orElse: () => templates.first,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => _apply(initial));
    }
    final c = widget.contact;
    final actions = ContactActions(ref);
    Future<void> done(Future<void> Function() send) async {
      await send();
      if (context.mounted) Navigator.pop(context);
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Mensagem para ${c.name}',
                style: Theme.of(context).textTheme.titleMedium),
            gapH12,
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final t in templates)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(t.name),
                        selected: _selected == t.id,
                        onSelected: (_) => _apply(t),
                      ),
                    ),
                ],
              ),
            ),
            gapH12,
            TextField(
              controller: _text,
              minLines: 4,
              maxLines: 10,
              decoration: const InputDecoration(labelText: 'Texto'),
            ),
            gapH16,
            Wrap(
              spacing: Sizes.p8,
              runSpacing: Sizes.p8,
              children: [
                if (c.phone != null)
                  FilledButton.icon(
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text('WhatsApp'),
                    onPressed: () => done(() => actions.whatsapp(c,
                        text: _text.text, propertyId: widget.property?.id)),
                  ),
                if (c.phone != null)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.sms_outlined),
                    label: const Text('SMS'),
                    onPressed: () => done(() => actions.sms(c, text: _text.text)),
                  ),
                if (c.email != null)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.mail_outline),
                    label: const Text('Email'),
                    onPressed: () => done(() => actions.email(c,
                        subject: _subject,
                        body: _text.text,
                        propertyId: widget.property?.id)),
                  ),
                if (c.phone == null && c.email == null)
                  const Text('Este contacto não tem telefone nem email.'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
