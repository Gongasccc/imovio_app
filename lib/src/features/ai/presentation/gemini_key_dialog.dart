import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imovio/src/common_widgets/responsive_center.dart';
import 'package:imovio/src/common_widgets/section_card.dart';
import 'package:imovio/src/constants/app_sizes.dart';
import 'package:imovio/src/features/ai/data/gemini_client.dart';
import 'package:imovio/src/features/ai/data/gemini_repository.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/utils/dialogs.dart';
import 'package:imovio/src/utils/launcher.dart';

/// Abre a página da chave do Gemini, que a testa e guarda na conta. Devolve
/// true se ficou uma chave válida guardada.
///
/// É uma página inteira (e não um diálogo) para o teclado do telemóvel, o
/// colar e o voltar atrás com o gesto funcionarem como numa app normal.
Future<bool> showGeminiKeyDialog(BuildContext context) async =>
    await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const GeminiKeyScreen())) ??
    false;

class GeminiKeyScreen extends ConsumerStatefulWidget {
  const GeminiKeyScreen({super.key});

  @override
  ConsumerState<GeminiKeyScreen> createState() => _GeminiKeyScreenState();
}

class _GeminiKeyScreenState extends ConsumerState<GeminiKeyScreen> {
  final _key = TextEditingController();
  var _obscure = false;
  var _busy = false;
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

  Future<void> _paste() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      if (text.isEmpty) {
        if (mounted) {
          showSnack(
            context,
            'A área de transferência está vazia. Copie a chave no AI Studio.',
          );
        }
        return;
      }
      setState(() {
        _key.text = text;
        _error = null;
      });
    } catch (_) {
      // Alguns browsers não deixam ler a área de transferência: resta o
      // "colar" do próprio campo (toque longo).
      if (mounted) {
        showSnack(
          context,
          'Não foi possível colar automaticamente. Toque e mantenha no campo e escolha "Colar".',
        );
      }
    }
  }

  Future<void> _save() async {
    final key = _key.text.trim();
    if (key.isEmpty) {
      setState(() => _error = 'Cole a chave primeiro.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final uid = ref.read(currentUidProvider);
    final repo = ref.read(geminiKeyRepositoryProvider);
    try {
      // Confirma a chave pela lista de modelos (rápido, não depende de os
      // modelos estarem ocupados) e nunca espera mais de 20 segundos.
      await GeminiClient(
        ref.read(geminiHttpClientProvider),
        key,
      ).validateKey().timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw const GeminiException(
          'A Google não respondeu a tempo. Verifique a internet e tente '
          'outra vez.',
        ),
      );
      await repo.setKey(uid: uid, key: key);
      if (mounted) {
        showSnack(context, 'Chave do Gemini guardada');
        Navigator.of(context).pop(true);
      }
    } on GeminiException catch (e) {
      if (e.isTemporary) {
        // A Google aceitou a chave mas está ocupada: guarda na mesma.
        await repo.setKey(uid: uid, key: key);
        if (mounted) {
          showSnack(
            context,
            'Chave guardada. O Gemini está muito ocupado agora; as funções '
            'com IA voltam a funcionar daqui a pouco.',
          );
          Navigator.of(context).pop(true);
        }
      } else if (mounted) {
        setState(() => _error = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Não foi possível contactar o Gemini: $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Remover chave',
      message: 'As funções com IA deixam de funcionar até guardar outra chave.',
      confirmLabel: 'Remover',
    );
    if (!ok) return;
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
    final hasKey = (ref.watch(geminiKeyProvider).value ?? '').isNotEmpty;
    final scheme = Theme.of(context).colorScheme;
    Widget step(int n, String text, {Widget? action}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: scheme.primary,
            child: Text(
              '$n',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.onPrimary,
              ),
            ),
          ),
          gapW12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(text),
                ),
                ?action,
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chave do Gemini'),
        actions: [
          if (hasKey)
            IconButton(
              tooltip: 'Remover chave',
              icon: const Icon(Icons.delete_outline),
              onPressed: _busy ? null : _remove,
            ),
          gapW8,
        ],
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          ResponsiveCenter(
            maxContentWidth: 640,
            padding: const EdgeInsets.all(Sizes.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Uma só chave serve toda a app: estudo de mercado e '
                  'importação de anúncios por link. É gratuita.',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                gapH16,
                SectionCard(
                  title: 'Como obter a chave',
                  icon: Icons.help_outline,
                  child: Column(
                    children: [
                      step(
                        1,
                        'Abra o Google AI Studio e entre com a sua conta Google.',
                        action: Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            icon: const Icon(Icons.open_in_new, size: 18),
                            label: const Text('Abrir Google AI Studio'),
                            onPressed: () =>
                                openExternalUrl(GeminiClient.keyUrl),
                          ),
                        ),
                      ),
                      step(2, 'Carregue em "Create API key" (Criar chave).'),
                      step(
                        3,
                        'Copie a chave (pode começar por "AQ." ou por "AIza").',
                      ),
                      step(4, 'Volte aqui e carregue em "Colar".'),
                    ],
                  ),
                ),
                gapH16,
                SectionCard(
                  title: 'A sua chave',
                  icon: Icons.key_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _key,
                        obscureText: _obscure,
                        autocorrect: false,
                        enableSuggestions: false,
                        enableInteractiveSelection: true,
                        keyboardType: TextInputType.visiblePassword,
                        maxLines: 1,
                        style: const TextStyle(fontFamily: 'monospace'),
                        decoration: InputDecoration(
                          hintText: 'Cole aqui a chave',
                          errorText: _error,
                          errorMaxLines: 4,
                          suffixIcon: IconButton(
                            tooltip: _obscure ? 'Mostrar' : 'Esconder',
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        onChanged: (_) => setState(() => _error = null),
                        onSubmitted: (_) => _save(),
                      ),
                      gapH12,
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.content_paste),
                              label: const Text('Colar'),
                              onPressed: _busy ? null : _paste,
                            ),
                          ),
                          gapW8,
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.clear),
                              label: const Text('Limpar'),
                              onPressed: _busy
                                  ? null
                                  : () => setState(() {
                                      _key.clear();
                                      _error = null;
                                    }),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                gapH16,
                Text(
                  'A chave fica guardada só na sua conta. No plano gratuito a '
                  'Google pode usar os pedidos para melhorar os produtos dela; '
                  'os pedidos levam a zona e as características do imóvel, '
                  'sem dados de clientes.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Sizes.p12),
          child: FilledButton(
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Testar e guardar'),
          ),
        ),
      ),
    );
  }
}
