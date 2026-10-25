import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/ai/application/listing_ai_extractor.dart';
import 'package:imovio/src/features/ai/data/gemini_repository.dart';
import 'package:imovio/src/features/geo/data/geo_repository.dart';
import 'package:imovio/src/features/geo/domain/geo_data.dart';
import 'package:imovio/src/features/properties/application/listing_import_service.dart';
import 'package:imovio/src/features/properties/data/properties_repository.dart';
import 'package:imovio/src/features/properties/domain/property.dart';

part 'property_edit_controller.g.dart';

@riverpod
class PropertyEditController extends _$PropertyEditController {
  @override
  FutureOr<void> build() {}

  Future<bool> submit(Property property, {required bool isNew}) async {
    final uid = ref.read(currentUidProvider);
    final repo = ref.read(propertiesRepositoryProvider);
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => isNew
        ? repo.createProperty(uid: uid, property: property)
        : repo.updateProperty(uid: uid, property: property));
    if (ref.mounted) state = result;
    return !result.hasError;
  }

  Future<bool> delete(PropertyID id) async {
    final uid = ref.read(currentUidProvider);
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() =>
        ref.read(propertiesRepositoryProvider).deleteProperty(uid: uid, id: id));
    if (ref.mounted) state = result;
    return !result.hasError;
  }
}

/// Carregamento de fotos para a galeria. Estado separado do de guardar, para
/// o botão de guardar não ficar bloqueado durante o upload.
@riverpod
class PhotoUploadController extends _$PhotoUploadController {
  @override
  FutureOr<void> build() {}

  /// Abre a galeria do dispositivo e devolve os URLs das fotos carregadas.
  Future<List<String>> pickAndUpload(PropertyID propertyId) async {
    final files = await ImagePicker().pickMultiImage(
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (files.isEmpty) return const [];
    final uid = ref.read(currentUidProvider);
    final repo = ref.read(propertiesRepositoryProvider);
    state = const AsyncLoading();
    final urls = <String>[];
    final result = await AsyncValue.guard(() async {
      for (final f in files) {
        urls.add(await repo.uploadPhoto(
          uid: uid,
          propertyId: propertyId,
          bytes: await f.readAsBytes(),
          fileName: f.name,
          contentType: f.mimeType ?? 'image/jpeg',
        ));
      }
    });
    if (ref.mounted) state = result;
    return urls;
  }
}

@riverpod
class ListingImportController extends _$ListingImportController {
  @override
  FutureOr<ImportedListing?> build() => null;

  Future<ImportedListing?> extract(String url) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      // Sem a lista de concelhos a importação funciona na mesma.
      final geo = await ref.read(geoDataProvider.future).catchError(
          (Object _) => GeoData(const {}));
      // Com chave Gemini configurada, o Gemini ajuda a ler o anúncio.
      final gemini = await ref.read(geminiClientProvider.future).catchError(
          (Object _) => null);
      return ref.read(listingImportServiceProvider).extract(
            url,
            geo: geo,
            ai: gemini == null ? null : ListingAiExtractor(gemini),
          );
    });
    if (ref.mounted) state = result;
    return result.value;
  }
}
