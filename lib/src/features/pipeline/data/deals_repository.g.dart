// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deals_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(dealsRepository)
final dealsRepositoryProvider = DealsRepositoryProvider._();

final class DealsRepositoryProvider
    extends
        $FunctionalProvider<DealsRepository, DealsRepository, DealsRepository>
    with $Provider<DealsRepository> {
  DealsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dealsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dealsRepositoryHash();

  @$internal
  @override
  $ProviderElement<DealsRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DealsRepository create(Ref ref) {
    return dealsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DealsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DealsRepository>(value),
    );
  }
}

String _$dealsRepositoryHash() => r'fd69cef519759c96095ae3975e6208ca423e3b74';

@ProviderFor(dealsStream)
final dealsStreamProvider = DealsStreamProvider._();

final class DealsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Deal>>,
          List<Deal>,
          Stream<List<Deal>>
        >
    with $FutureModifier<List<Deal>>, $StreamProvider<List<Deal>> {
  DealsStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dealsStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dealsStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<Deal>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Deal>> create(Ref ref) {
    return dealsStream(ref);
  }
}

String _$dealsStreamHash() => r'64932b93aba83eb61ff0496142548ac63ed0e9b3';
