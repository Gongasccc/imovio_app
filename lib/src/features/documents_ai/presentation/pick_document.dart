import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:imovio/src/features/ai/data/gemini_client.dart';
import 'package:imovio/src/features/ai/data/gemini_repository.dart';
import 'package:imovio/src/features/ai/presentation/gemini_key_dialog.dart';
import 'package:imovio/src/features/documents_ai/application/document_reader.dart';
import 'package:imovio/src/utils/dialogs.dart';

/// Pede a foto ou PDF de um documento e devolve-o pronto para o Gemini,
/// depois de avisar o que é enviado. Devolve null se o utilizador desistir.
Future<(DocumentReader, GeminiFile)?> pickDocumentForAi(
  BuildContext context,
  WidgetRef ref, {
  required String documentName,
  bool personalData = false,
}) async {
  var gemini = await ref.read(geminiClientProvider.future).catchError((_) => null);
  if (gemini == null) {
    if (!context.mounted) return null;
    final ok = await showGeminiKeyDialog(context);
    if (!ok) return null;
    gemini = await ref.read(geminiClientProvider.future);
    if (gemini == null) return null;
  }
  if (!context.mounted) return null;
  if (personalData) {
    final ok = await showConfirmDialog(
      context,
      title: 'Enviar $documentName ao Gemini?',
      message: 'A foto é enviada à Google para ser lida. No plano gratuito do '
          'Gemini a Google pode guardar e usar os pedidos para melhorar os '
          'produtos dela. Use só com autorização do cliente; em alternativa, '
          'preencha os dados à mão.',
      confirmLabel: 'Enviar',
    );
    if (!ok || !context.mounted) return null;
  }
  final source = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Tirar fotografia'),
            onTap: () => Navigator.pop(context, 'camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Escolher imagem ou PDF'),
            onTap: () => Navigator.pop(context, 'file'),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;
  if (source == 'camera') {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 2000,
      imageQuality: 85,
    );
    if (photo == null) return null;
    return (
      DocumentReader(gemini),
      GeminiFile(await photo.readAsBytes(), photo.mimeType ?? 'image/jpeg'),
    );
  }
  final files = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'heic', 'pdf'],
  );
  if (files.isEmpty) return null;
  final f = files.first;
  final ext = (f.extension ?? '').toLowerCase();
  final mime = switch (ext) {
    'pdf' => 'application/pdf',
    'png' => 'image/png',
    'webp' => 'image/webp',
    'heic' => 'image/heic',
    _ => 'image/jpeg',
  };
  return (DocumentReader(gemini), GeminiFile(await f.readAsBytes(), mime));
}
