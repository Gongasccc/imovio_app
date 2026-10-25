import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imovio/src/common_widgets/section_card.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/contacts/data/contact_attachments_repository.dart';
import 'package:imovio/src/features/contacts/domain/contact.dart';
import 'package:imovio/src/utils/dialogs.dart';
import 'package:imovio/src/utils/format.dart';
import 'package:imovio/src/utils/launcher.dart';
import 'package:imovio/src/utils/run_action.dart';

/// Documentos do contacto: cartão de cidadão, contratos, comprovativos...
class ContactAttachmentsSection extends ConsumerStatefulWidget {
  const ContactAttachmentsSection({super.key, required this.contact});
  final Contact contact;

  @override
  ConsumerState<ContactAttachmentsSection> createState() =>
      _ContactAttachmentsSectionState();
}

class _ContactAttachmentsSectionState
    extends ConsumerState<ContactAttachmentsSection> {
  var _uploading = 0;

  Future<void> _pick() async {
    final files = await FilePicker.pickFiles();
    if (files.isEmpty || !mounted) return;
    final uid = ref.read(currentUidProvider);
    final repo = ref.read(contactAttachmentsRepositoryProvider);
    setState(() => _uploading += files.length);
    var done = 0;
    for (final f in files) {
      try {
        final bytes = await f.readAsBytes();
        await repo.upload(
          uid: uid,
          contactId: widget.contact.id,
          fileName: f.name,
          bytes: bytes,
          contentType: _contentType(f.extension),
        );
        done++;
      } catch (e) {
        if (mounted) showSnack(context, 'Erro em ${f.name}: $e', error: true);
      } finally {
        if (mounted) setState(() => _uploading--);
      }
    }
    if (mounted && done > 0) showSnack(context, '$done ficheiro(s) anexado(s)');
  }

  static String? _contentType(String? ext) => switch (ext?.toLowerCase()) {
        'pdf' => 'application/pdf',
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        'heic' => 'image/heic',
        'doc' => 'application/msword',
        'docx' =>
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'xls' => 'application/vnd.ms-excel',
        'xlsx' =>
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final files = [...widget.contact.attachments]
      ..sort((a, b) => (b.uploadedAt ?? 0).compareTo(a.uploadedAt ?? 0));
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return SectionCard(
      title: 'Documentos',
      icon: Icons.attach_file,
      trailing: FilledButton.tonalIcon(
        onPressed: _uploading > 0 ? null : _pick,
        icon: _uploading > 0
            ? const SizedBox.square(
                dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.upload_file),
        label: Text(_uploading > 0 ? 'A enviar...' : 'Anexar'),
      ),
      child: files.isEmpty
          ? Text(
              'Sem documentos. Anexe cartão de cidadão, contratos, '
              'comprovativos ou outros ficheiros (até 20 MB cada).',
              style: TextStyle(color: muted),
            )
          : Column(
              children: [
                for (final f in files)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(f.isPdf
                        ? Icons.picture_as_pdf_outlined
                        : f.isImage
                            ? Icons.image_outlined
                            : Icons.insert_drive_file_outlined),
                    title: Text(f.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text([
                      f.sizeLabel,
                      if (f.uploadedAt != null)
                        Format.date(
                            DateTime.fromMillisecondsSinceEpoch(f.uploadedAt!)),
                    ].where((s) => s.isNotEmpty).join(' · ')),
                    onTap: () => openExternalUrl(f.url),
                    trailing: IconButton(
                      tooltip: 'Eliminar',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => confirmAndDelete(
                        context,
                        () => ref
                            .read(contactAttachmentsRepositoryProvider)
                            .delete(
                              uid: ref.read(currentUidProvider),
                              contactId: widget.contact.id,
                              attachment: f,
                            ),
                        message: 'Eliminar o ficheiro ${f.name}?',
                        success: 'Ficheiro eliminado',
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
