import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imovio/src/constants/app_sizes.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
import 'package:imovio/src/features/properties/presentation/property_edit_controller.dart';
import 'package:imovio/src/features/properties/presentation/property_list_tile.dart';
import 'package:imovio/src/utils/async_value_ui.dart';
import 'package:imovio/src/utils/dialogs.dart';

/// Galeria de fotos: carregar do dispositivo, adicionar por URL, escolher a
/// capa (a primeira) e remover.
class GalleryEditor extends ConsumerWidget {
  const GalleryEditor({
    super.key,
    required this.propertyId,
    required this.images,
    required this.onChanged,
  });
  final PropertyID propertyId;
  final List<String> images;
  final ValueChanged<List<String>> onChanged;

  Future<void> _addUrls(BuildContext context) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar fotos por URL'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Um URL por linha\nhttps://images.unsplash.com/...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
    controller.dispose();
    final urls = (text ?? '')
        .split('\n')
        .map((u) => u.trim())
        .where((u) => u.startsWith('http') && !images.contains(u));
    if (urls.isNotEmpty) onChanged([...images, ...urls]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(photoUploadControllerProvider,
        (_, s) => s.showSnackBarOnError(context));
    final uploading = ref.watch(photoUploadControllerProvider).isLoading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: Sizes.p8,
          runSpacing: Sizes.p8,
          children: [
            FilledButton.tonalIcon(
              onPressed: uploading
                  ? null
                  : () async {
                      final urls = await ref
                          .read(photoUploadControllerProvider.notifier)
                          .pickAndUpload(propertyId);
                      if (urls.isNotEmpty) {
                        onChanged([...images, ...urls]);
                        if (context.mounted) {
                          showSnack(context, '${urls.length} foto(s) carregadas');
                        }
                      }
                    },
              icon: uploading
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.upload_outlined),
              label: Text(uploading ? 'A carregar...' : 'Carregar fotos'),
            ),
            OutlinedButton.icon(
              onPressed: () => _addUrls(context),
              icon: const Icon(Icons.link),
              label: const Text('Adicionar por URL'),
            ),
          ],
        ),
        gapH12,
        if (images.isEmpty)
          Text(
            'Sem fotos. A primeira foto que adicionar será a capa.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          )
        else
          Wrap(
            spacing: Sizes.p8,
            runSpacing: Sizes.p8,
            children: [
              for (final (i, url) in images.indexed)
                _Thumb(
                  url: url,
                  isCover: i == 0,
                  onMakeCover: () =>
                      onChanged([url, ...images.where((u) => u != url)]),
                  onRemove: () =>
                      onChanged(images.where((u) => u != url).toList()),
                ),
            ],
          ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.url,
    required this.isCover,
    required this.onMakeCover,
    required this.onRemove,
  });
  final String url;
  final bool isCover;
  final VoidCallback onMakeCover;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 140,
        height: 100,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PropertyImage(url: url),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton.filledTonal(
                visualDensity: VisualDensity.compact,
                tooltip: 'Remover',
                icon: const Icon(Icons.close, size: 16),
                onPressed: onRemove,
              ),
            ),
            Positioned(
              left: 4,
              bottom: 4,
              child: isCover
                  ? Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Capa',
                          style:
                              TextStyle(color: scheme.onPrimary, fontSize: 11)),
                    )
                  : TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.black54,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: onMakeCover,
                      child: const Text('Tornar capa',
                          style: TextStyle(fontSize: 11)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
