import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imovio/src/constants/app_sizes.dart';
import 'package:imovio/src/features/ai/data/gemini_repository.dart';
import 'package:imovio/src/features/ai/data/tavily_client.dart';
import 'package:imovio/src/features/ai/data/tavily_repository.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/utils/launcher.dart';

/// Pede a chave do Tavily, testa-a e guarda-a na conta. Devolve true se ficou
/// uma chave válida guardada.
Future<bool> showTavilyKeyDialog(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => const _TavilyKeyDialog(),
    ) ??
    false;

class _TavilyKeyDialog extends ConsumerStatefulWidget {
  const _TavilyKeyDialog();

  @override
  ConsumerState<_TavilyKeyDialog> createState() => _TavilyKeyDialogState();
}

class _TavilyKeyDialogState extends ConsumerState<_TavilyKeyDialog> {
  final _key = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _key.text = ref.read(tavilyKeyProvider).value ?? '';
  }

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    // Aceita o texto copiado da página, desde que tenha a chave "tvly-...".
    final match = RegExp(r'tvly-[A-Za-z0-9_\-]+').firstMatch(text);
    setState(() => _key.text = match?.group(0) ?? text);
  }

  Future<void> _save() async {
    final key = _key.text.trim();
    if (key.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await TavilyClient(ref.read(geminiHttpClientProvider), key).validateKey();
      await ref
          .read(tavilyKeyRepositoryProvider)
          .setKey(uid: ref.read(currentUidProvider), key: key);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pesquisa de preços (grátis)'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'A pesquisa de casas à venda na zona usa o Tavily, um motor de '
                'pesquisa para IA. O plano grátis dá cerca de 500 pesquisas '
                'por mês e não pede cartão.',
              ),
              gapH12,
              const Text(
                '1. Abra app.tavily.com e entre com a sua conta Google.\n'
                '2. Copie a chave que começa por "tvly-".\n'
                '3. Cole-a aqui.',
              ),
              TextButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Abrir Tavily'),
                onPressed: () => openExternalUrl(TavilyClient.keyUrl),
              ),
              TextField(
                controller: _key,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: 'Chave do Tavily',
                  hintText: 'tvly-...',
                  errorText: _error,
                  errorMaxLines: 3,
                  suffixIcon: IconButton(
                    tooltip: 'Colar',
                    icon: const Icon(Icons.content_paste),
                    onPressed: _paste,
                  ),
                ),
                onSubmitted: (_) => _save(),
              ),
              gapH8,
              Text(
                'A chave fica guardada só na sua conta. As pesquisas levam a '
                'zona e o tipo de imóvel, sem dados de clientes.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      actions: [
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
