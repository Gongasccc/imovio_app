// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geo_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(geoData)
final geoDataProvider = GeoDataProvider._();

final class GeoDataProvider
    extends $FunctionalProvider<AsyncValue<GeoData>, GeoData, FutureOr<GeoData>>
    with $FutureModifier<GeoData>, $FutureProvider<GeoData> {
  GeoDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'geoDataProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$geoDataHash();

  @$internal
  @override
  $FutureProviderElement<GeoData> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<GeoData> create(Ref ref) {
    return geoData(ref);
  }
}

String _$geoDataHash() => r'd69f2948ed86c615535d3f3088da1e20b1771491';
