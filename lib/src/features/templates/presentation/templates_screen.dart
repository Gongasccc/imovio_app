import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imovio/src/common_widgets/async_value_widget.dart';
import 'package:imovio/src/common_widgets/responsive_center.dart';
import 'package:imovio/src/constants/app_sizes.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/templates/data/templates_repository.dart';
import 'package:imovio/src/features/templates/domain/message_template.dart';
import 'package:imovio/src/utils/run_action.dart';

/// Lista e edição dos modelos de mensagem.
class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref,
      [MessageTemplate? t]) async {
    final result = await showDialog<MessageTemplate>(
      context: context,
      builder: (_) => _TemplateDialog(template: t),
    );
    if (result == null || !context.mounted) return;
    await runAction(
      context,
      () => ref
          .read(templatesRepositoryProvider)
          .save(uid: ref.read(currentUidProvider), t: result),
      success: 'Modelo guardado',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modelos de mensagens')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Novo modelo'),
      ),
      body: AsyncValueWidget<List<MessageTemplate>>(
        value: ref.watch(templatesProvider),
        data: (list) => ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            ResponsiveCenter(
              maxContentWidth: 760,
              padding: const EdgeInsets.all(Sizes.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Use os modelos ao enviar WhatsApp, SMS ou email a um '
                    'contacto. Os campos entre chavetas são preenchidos '
                    'sozinhos. Os modelos da app podem ser copiados e '
                    'alterados.',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  gapH16,
                  for (final t in list)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(t.name),
                        subtitle: Text(t.body,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: t.builtIn
                            ? const Tooltip(
                                message: 'Modelo da app: alterar cria uma cópia',
                                child: Icon(Icons.lock_outline, size: 18),
                              )
                            : IconButton(
                                tooltip: 'Apagar',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => confirmAndDelete(
                                  context,
                                  () => ref
                                      .read(templatesRepositoryProvider)
                                      .delete(
                                          uid: ref.read(currentUidProvider),
                                          id: t.id),
                                  success: 'Modelo apagado',
                                ),
                              ),
                        onTap: () => _edit(context, ref, t),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateDialog extends StatefulWidget {
  const _TemplateDialog({this.template});
  final MessageTemplate? template;

  @override
  State<_TemplateDialog> createState() => _TemplateDialogState();
}

class _TemplateDialogState extends State<_TemplateDialog> {
  late final _name = TextEditingController(
      text: widget.template == null
          ? ''
          : widget.template!.builtIn
              ? '${widget.template!.name} (meu)'
              : widget.template!.name);
  late final _subject = TextEditingController(text: widget.template?.subject);
  late final _body = TextEditingController(text: widget.template?.body);

  @override
  void dispose() {
    _name.dispose();
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  void _insert(String placeholder) {
    final sel = _body.selection;
    final text = _body.text;
    final at = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    _body.value = TextEditingValue(
      text: text.replaceRange(at, end, placeholder),
      selection: TextSelection.collapsed(offset: at + placeholder.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.template == null ? 'Novo modelo' : 'Editar modelo'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              gapH12,
              TextField(
                controller: _subject,
                decoration:
                    const InputDecoration(labelText: 'Assunto (para email)'),
              ),
              gapH12,
              TextField(
                controller: _body,
                minLines: 5,
                maxLines: 12,
                decoration: const InputDecoration(labelText: 'Texto'),
              ),
              gapH12,
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final e in MessageTemplate.placeholders.entries)
                    ActionChip(
                      tooltip: e.value,
                      label: Text(e.key),
                      onPressed: () => _insert(e.key),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (_name.text.trim().isEmpty || _body.text.trim().isEmpty) return;
            Navigator.pop(
              context,
              MessageTemplate(
                id: widget.template?.builtIn == true
                    ? ''
                    : widget.template?.id ?? '',
                name: _name.text.trim(),
                subject:
                    _subject.text.trim().isEmpty ? null : _subject.text.trim(),
                body: _body.text.trim(),
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
