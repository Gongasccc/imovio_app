// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property_edit_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PropertyEditController)
final propertyEditControllerProvider = PropertyEditControllerProvider._();

final class PropertyEditControllerProvider
    extends $AsyncNotifierProvider<PropertyEditController, void> {
  PropertyEditControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'propertyEditControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$propertyEditControllerHash();

  @$internal
  @override
  PropertyEditController create() => PropertyEditController();
}

String _$propertyEditControllerHash() =>
    r'a07f5870215271a0cbe3e0ab8cd44d6ab974b73f';

abstract class _$PropertyEditController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Carregamento de fotos para a galeria. Estado separado do de guardar, para
/// o botão de guardar não ficar bloqueado durante o upload.

@ProviderFor(PhotoUploadController)
final photoUploadControllerProvider = PhotoUploadControllerProvider._();

/// Carregamento de fotos para a galeria. Estado separado do de guardar, para
/// o botão de guardar não ficar bloqueado durante o upload.
final class PhotoUploadControllerProvider
    extends $AsyncNotifierProvider<PhotoUploadController, void> {
  /// Carregamento de fotos para a galeria. Estado separado do de guardar, para
  /// o botão de guardar não ficar bloqueado durante o upload.
  PhotoUploadControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'photoUploadControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$photoUploadControllerHash();

  @$internal
  @override
  PhotoUploadController create() => PhotoUploadController();
}

String _$photoUploadControllerHash() =>
    r'68d764787bd43bbad720bd495911eb2e8e4de1cb';

/// Carregamento de fotos para a galeria. Estado separado do de guardar, para
/// o botão de guardar não ficar bloqueado durante o upload.

abstract class _$PhotoUploadController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(ListingImportController)
final listingImportControllerProvider = ListingImportControllerProvider._();

final class ListingImportControllerProvider
    extends $AsyncNotifierProvider<ListingImportController, ImportedListing?> {
  ListingImportControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'listingImportControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$listingImportControllerHash();

  @$internal
  @override
  ListingImportController create() => ListingImportController();
}

String _$listingImportControllerHash() =>
    r'b4d40ee84d7b7dce390b7ed1c11c8ed00f53ffd4';

abstract class _$ListingImportController
    extends $AsyncNotifier<ImportedListing?> {
  FutureOr<ImportedListing?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ImportedListing?>, ImportedListing?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ImportedListing?>, ImportedListing?>,
              AsyncValue<ImportedListing?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
