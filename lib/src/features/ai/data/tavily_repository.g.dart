// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tavily_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tavilyKeyRepository)
final tavilyKeyRepositoryProvider = TavilyKeyRepositoryProvider._();

final class TavilyKeyRepositoryProvider
    extends
        $FunctionalProvider<
          TavilyKeyRepository,
          TavilyKeyRepository,
          TavilyKeyRepository
        >
    with $Provider<TavilyKeyRepository> {
  TavilyKeyRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tavilyKeyRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tavilyKeyRepositoryHash();

  @$internal
  @override
  $ProviderElement<TavilyKeyRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TavilyKeyRepository create(Ref ref) {
    return tavilyKeyRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TavilyKeyRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TavilyKeyRepository>(value),
    );
  }
}

String _$tavilyKeyRepositoryHash() =>
    r'6c2f697472b8434a4addf4de80f2594b9b030ddc';

@ProviderFor(tavilyKey)
final tavilyKeyProvider = TavilyKeyProvider._();

final class TavilyKeyProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, Stream<String?>>
    with $FutureModifier<String?>, $StreamProvider<String?> {
  TavilyKeyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tavilyKeyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tavilyKeyHash();

  @$internal
  @override
  $StreamProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String?> create(Ref ref) {
    return tavilyKey(ref);
  }
}

String _$tavilyKeyHash() => r'f4000c2514df9cca2159bea8d1e59ea9dfe77fcb';

/// Cliente pronto a usar, ou null se o utilizador ainda não pôs a chave.

@ProviderFor(tavilyClient)
final tavilyClientProvider = TavilyClientProvider._();

/// Cliente pronto a usar, ou null se o utilizador ainda não pôs a chave.

final class TavilyClientProvider
    extends
        $FunctionalProvider<
          AsyncValue<TavilyClient?>,
          TavilyClient?,
          FutureOr<TavilyClient?>
        >
    with $FutureModifier<TavilyClient?>, $FutureProvider<TavilyClient?> {
  /// Cliente pronto a usar, ou null se o utilizador ainda não pôs a chave.
  TavilyClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tavilyClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tavilyClientHash();

  @$internal
  @override
  $FutureProviderElement<TavilyClient?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TavilyClient?> create(Ref ref) {
    return tavilyClient(ref);
  }
}

String _$tavilyClientHash() => r'7d1c1c5551396fc9a680356bb9cb6479f0eee02a';
