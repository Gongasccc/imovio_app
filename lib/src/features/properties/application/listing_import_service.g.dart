// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'listing_import_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(listingImportService)
final listingImportServiceProvider = ListingImportServiceProvider._();

final class ListingImportServiceProvider
    extends
        $FunctionalProvider<
          ListingImportService,
          ListingImportService,
          ListingImportService
        >
    with $Provider<ListingImportService> {
  ListingImportServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'listingImportServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$listingImportServiceHash();

  @$internal
  @override
  $ProviderElement<ListingImportService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ListingImportService create(Ref ref) {
    return listingImportService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ListingImportService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ListingImportService>(value),
    );
  }
}

String _$listingImportServiceHash() =>
    r'ff46efdf7a3f615e27b92ab7e3766d42f7269a87';
