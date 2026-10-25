import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imovio/src/constants/app_sizes.dart';
import 'package:imovio/src/features/ai/data/gemini_client.dart';
import 'package:imovio/src/features/ai/data/gemini_repository.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/utils/dialogs.dart';
import 'package:imovio/src/utils/launcher.dart';

/// Pede a chave do Gemini, testa-a e guarda-a na conta. Devolve true se
/// ficou uma chave válida guardada.
Future<bool> showGeminiKeyDialog(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => const _GeminiKeyDialog(),
    ) ??
    false;

class _GeminiKeyDialog extends ConsumerStatefulWidget {
  const _GeminiKeyDialog();

  @override
  ConsumerState<_GeminiKeyDialog> createState() => _GeminiKeyDialogState();
}

class _GeminiKeyDialogState extends ConsumerState<_GeminiKeyDialog> {
  final _key = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _key.text = ref.read(geminiKeyProvider).value ?? '';
  }

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final key = _key.text.trim();
    if (key.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Pedido mínimo para confirmar que a chave funciona.
      await GeminiClient(
        ref.read(geminiHttpClientProvider),
        key,
      ).generate('Responde só: ok');
      await ref
          .read(geminiKeyRepositoryProvider)
          .setKey(uid: ref.read(currentUidProvider), key: key);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    await ref
        .read(geminiKeyRepositoryProvider)
        .setKey(uid: ref.read(currentUidProvider), key: null);
    if (mounted) {
      showSnack(context, 'Chave do Gemini removida');
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = ref.watch(geminiKeyProvider).value != null;
    return AlertDialog(
      title: const Text('Ligar o Gemini (grátis)'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'O Gemini pesquisa no Google os preços de casas semelhantes na '
              'zona e escreve o comentário de mercado. O plano gratuito da '
              'Google chega para uso normal.',
            ),
            gapH12,
            const Text(
              '1. Abra o Google AI Studio com a sua conta Google.\n'
              '2. Carregue em "Create API key".\n'
              '3. Copie a chave e cole-a aqui.',
            ),
            TextButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir Google AI Studio'),
              onPressed: () => openExternalUrl(GeminiClient.keyUrl),
            ),
            TextField(
              controller: _key,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'Chave da API do Gemini',
                errorText: _error,
                errorMaxLines: 3,
              ),
              onSubmitted: (_) => _save(),
            ),
            gapH8,
            Text(
              'A chave fica guardada só na sua conta. No plano gratuito a '
              'Google pode usar os pedidos para melhorar os produtos dela; '
              'os pedidos levam a zona e as características do imóvel, sem '
              'dados de clientes.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        if (hasKey)
          TextButton(
            onPressed: _busy ? null : _remove,
            child: const Text('Remover'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Testar e guardar'),
        ),
      ],
    );
  }
}
