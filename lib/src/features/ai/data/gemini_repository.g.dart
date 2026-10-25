// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gemini_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(geminiKeyRepository)
final geminiKeyRepositoryProvider = GeminiKeyRepositoryProvider._();

final class GeminiKeyRepositoryProvider
    extends
        $FunctionalProvider<
          GeminiKeyRepository,
          GeminiKeyRepository,
          GeminiKeyRepository
        >
    with $Provider<GeminiKeyRepository> {
  GeminiKeyRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'geminiKeyRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$geminiKeyRepositoryHash();

  @$internal
  @override
  $ProviderElement<GeminiKeyRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GeminiKeyRepository create(Ref ref) {
    return geminiKeyRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GeminiKeyRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GeminiKeyRepository>(value),
    );
  }
}

String _$geminiKeyRepositoryHash() =>
    r'3d3c32bb42b76855ae581614dfe2aef9a9fee7d7';

@ProviderFor(geminiKey)
final geminiKeyProvider = GeminiKeyProvider._();

final class GeminiKeyProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, Stream<String?>>
    with $FutureModifier<String?>, $StreamProvider<String?> {
  GeminiKeyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'geminiKeyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$geminiKeyHash();

  @$internal
  @override
  $StreamProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String?> create(Ref ref) {
    return geminiKey(ref);
  }
}

String _$geminiKeyHash() => r'c35b85c3ef845f377db5ddc65b200f8e3ee28917';

@ProviderFor(geminiHttpClient)
final geminiHttpClientProvider = GeminiHttpClientProvider._();

final class GeminiHttpClientProvider
    extends $FunctionalProvider<http.Client, http.Client, http.Client>
    with $Provider<http.Client> {
  GeminiHttpClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'geminiHttpClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$geminiHttpClientHash();

  @$internal
  @override
  $ProviderElement<http.Client> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  http.Client create(Ref ref) {
    return geminiHttpClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(http.Client value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<http.Client>(value),
    );
  }
}

String _$geminiHttpClientHash() => r'00d9e81f1724f4a772e546edd0106c9865abdbd2';

/// A chave a usar: a do próprio utilizador ou, se não tiver, a da equipa.

@ProviderFor(effectiveGeminiKey)
final effectiveGeminiKeyProvider = EffectiveGeminiKeyProvider._();

/// A chave a usar: a do próprio utilizador ou, se não tiver, a da equipa.

final class EffectiveGeminiKeyProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// A chave a usar: a do próprio utilizador ou, se não tiver, a da equipa.
  EffectiveGeminiKeyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'effectiveGeminiKeyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$effectiveGeminiKeyHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return effectiveGeminiKey(ref);
  }
}

String _$effectiveGeminiKeyHash() =>
    r'db7bd4f8e807ec4a7ac8c2187791a43085a1b975';

/// Cliente pronto a usar, ou null se não houver chave (própria ou da equipa).

@ProviderFor(geminiClient)
final geminiClientProvider = GeminiClientProvider._();

/// Cliente pronto a usar, ou null se não houver chave (própria ou da equipa).

final class GeminiClientProvider
    extends
        $FunctionalProvider<
          AsyncValue<GeminiClient?>,
          GeminiClient?,
          FutureOr<GeminiClient?>
        >
    with $FutureModifier<GeminiClient?>, $FutureProvider<GeminiClient?> {
  /// Cliente pronto a usar, ou null se não houver chave (própria ou da equipa).
  GeminiClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'geminiClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$geminiClientHash();

  @$internal
  @override
  $FutureProviderElement<GeminiClient?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<GeminiClient?> create(Ref ref) {
    return geminiClient(ref);
  }
}

String _$geminiClientHash() => r'87e04a594e45995c2f25ea5b79c5d005abfe5819';
