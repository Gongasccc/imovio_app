import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imovio/src/features/ai/data/gemini_client.dart';
import 'package:imovio/src/features/documents_ai/application/document_reader.dart';
import 'package:imovio/src/features/documents_ai/presentation/pick_document.dart';
import 'package:imovio/src/utils/dialogs.dart';

/// "Ler caderneta predial": foto ou PDF da caderneta lida pelo Gemini.
class LandRegistryButton extends ConsumerStatefulWidget {
  const LandRegistryButton({super.key, required this.onRead});
  final ValueChanged<LandRegistryData> onRead;

  @override
  ConsumerState<LandRegistryButton> createState() => _LandRegistryButtonState();
}

class _LandRegistryButtonState extends ConsumerState<LandRegistryButton> {
  var _busy = false;

  Future<void> _read() async {
    final picked = await pickDocumentForAi(
      context,
      ref,
      documentName: 'a caderneta predial',
    );
    if (picked == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final data = await picked.$1.readLandRegistry(picked.$2);
      if (!mounted) return;
      if (data.isEmpty) {
        showSnack(context, 'Não consegui ler a caderneta. Tente outra foto.',
            error: true);
        return;
      }
      widget.onRead(data);
      showSnack(context, 'Dados da caderneta preenchidos. Reveja-os antes de guardar.');
    } on GeminiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } catch (e) {
      if (mounted) showSnack(context, 'Erro ao ler: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _busy ? null : _read,
      icon: _busy
          ? const SizedBox.square(
              dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.document_scanner_outlined),
      label: Text(_busy ? 'A ler...' : 'Ler caderneta predial (IA)'),
    );
  }
}
