import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:imovio/src/common_widgets/responsive_center.dart';
import 'package:imovio/src/common_widgets/section_card.dart';
import 'package:imovio/src/constants/app_sizes.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/properties/data/properties_repository.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
import 'package:imovio/src/features/properties/presentation/gallery_editor.dart';
import 'package:imovio/src/features/properties/presentation/property_edit_controller.dart';
import 'package:imovio/src/features/properties/presentation/property_form_fields.dart';
import 'package:imovio/src/utils/async_value_ui.dart';
import 'package:imovio/src/utils/dialogs.dart';

/// "Novo Imóvel": importação por link, campos e galeria.
class PropertyNewScreen extends ConsumerStatefulWidget {
  const PropertyNewScreen({super.key});

  @override
  ConsumerState<PropertyNewScreen> createState() => _PropertyNewScreenState();
}

class _PropertyNewScreenState extends ConsumerState<PropertyNewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _importUrl = TextEditingController();
  late final PropertyFormData _data;

  @override
  void initState() {
    super.initState();
    // O id é reservado já, para as fotos carregadas ficarem na pasta certa.
    final uid = ref.read(currentUidProvider);
    final id = ref.read(propertiesRepositoryProvider).newId(uid);
    _data = PropertyFormData(Property(id: id, title: ''));
  }

  @override
  void dispose() {
    _importUrl.dispose();
    _data.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final url = _importUrl.text.trim();
    if (!url.startsWith('http')) {
      showSnack(context, 'Por favor, cole um link de imóvel válido.',
          error: true);
      return;
    }
    final listing =
        await ref.read(listingImportControllerProvider.notifier).extract(url);
    if (!mounted) return;
    if (listing == null || listing.isEmpty) {
      showSnack(context, 'Não foi possível ler dados deste link.', error: true);
      return;
    }
    setState(() => _data.applyImport(listing, url));
    final photos = listing.images.length;
    showSnack(
      context,
      '${listing.filledCount} campos e $photos foto(s) importados.'
      '${listing.price == null ? ' O preço não foi encontrado: preencha-o.' : ' Reveja antes de guardar.'}',
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(propertyEditControllerProvider.notifier)
        .submit(_data.toProperty(), isNew: true);
    if (ok && mounted) {
      showSnack(context, 'Imóvel cadastrado com sucesso!');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(propertyEditControllerProvider,
        (_, s) => s.showSnackBarOnError(context));
    final saving = ref.watch(propertyEditControllerProvider).isLoading;
    final importing = ref.watch(listingImportControllerProvider).isLoading;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Imóvel')),
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            ResponsiveCenter(
              maxContentWidth: 860,
              padding: const EdgeInsets.all(Sizes.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(Sizes.p16),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.08),
                      border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(children: [
                          Icon(Icons.link, size: 18),
                          gapW8,
                          Text('Importar via Link da Internet',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ]),
                        gapH12,
                        Row(children: [
                          Expanded(
                            child: TextField(
                              controller: _importUrl,
                              keyboardType: TextInputType.url,
                              decoration: const InputDecoration(
                                hintText:
                                    'https://www.iadportugal.pt/anuncio/...',
                              ),
                              onSubmitted: (_) => _import(),
                            ),
                          ),
                          gapW8,
                          FilledButton(
                            onPressed: importing ? null : _import,
                            child: Text(importing ? 'A extrair...' : 'Extrair'),
                          ),
                        ]),
                        gapH8,
                        Text(
                          'Lê preço, áreas, quartos, WC, localização, '
                          'características e fotos do anúncio e preenche os '
                          'campos abaixo. Alguns portais bloqueiam a leitura '
                          'automática: nesse caso, preencha o que faltar.',
                          style: TextStyle(
                              fontSize: 12, color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  gapH16,
                  SectionCard(
                    title: 'Dados do imóvel',
                    icon: Icons.home_outlined,
                    child: PropertyFieldsForm(
                      data: _data,
                      onChanged: () => setState(() {}),
                    ),
                  ),
                  gapH16,
                  SectionCard(
                    title: 'Fotografias',
                    icon: Icons.photo_library_outlined,
                    child: GalleryEditor(
                      propertyId: _data.base.id,
                      images: _data.images,
                      onChanged: (imgs) => setState(() => _data.images = imgs),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Sizes.p12),
          child: FilledButton(
            onPressed: saving ? null : _save,
            child: const Text('Guardar imóvel'),
          ),
        ),
      ),
    );
  }
}
