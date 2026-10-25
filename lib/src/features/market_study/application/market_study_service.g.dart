// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'market_study_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Estudo de mercado de um imóvel: junta a ficha, a base de comparáveis, os
/// imóveis da carteira e o INE, e recalcula sempre que algum muda.

@ProviderFor(marketStudy)
final marketStudyProvider = MarketStudyFamily._();

/// Estudo de mercado de um imóvel: junta a ficha, a base de comparáveis, os
/// imóveis da carteira e o INE, e recalcula sempre que algum muda.

final class MarketStudyProvider
    extends
        $FunctionalProvider<
          AsyncValue<MarketStudy?>,
          MarketStudy?,
          FutureOr<MarketStudy?>
        >
    with $FutureModifier<MarketStudy?>, $FutureProvider<MarketStudy?> {
  /// Estudo de mercado de um imóvel: junta a ficha, a base de comparáveis, os
  /// imóveis da carteira e o INE, e recalcula sempre que algum muda.
  MarketStudyProvider._({
    required MarketStudyFamily super.from,
    required PropertyID super.argument,
  }) : super(
         retry: null,
         name: r'marketStudyProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$marketStudyHash();

  @override
  String toString() {
    return r'marketStudyProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<MarketStudy?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MarketStudy?> create(Ref ref) {
    final argument = this.argument as PropertyID;
    return marketStudy(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MarketStudyProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$marketStudyHash() => r'8e535a5c7d983104e51165e63c269c14e8f9ee05';

/// Estudo de mercado de um imóvel: junta a ficha, a base de comparáveis, os
/// imóveis da carteira e o INE, e recalcula sempre que algum muda.

final class MarketStudyFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<MarketStudy?>, PropertyID> {
  MarketStudyFamily._()
    : super(
        retry: null,
        name: r'marketStudyProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Estudo de mercado de um imóvel: junta a ficha, a base de comparáveis, os
  /// imóveis da carteira e o INE, e recalcula sempre que algum muda.

  MarketStudyProvider call(PropertyID propertyId) =>
      MarketStudyProvider._(argument: propertyId, from: this);

  @override
  String toString() => r'marketStudyProvider';
}

@ProviderFor(MarketStudyController)
final marketStudyControllerProvider = MarketStudyControllerProvider._();

final class MarketStudyControllerProvider
    extends $AsyncNotifierProvider<MarketStudyController, void> {
  MarketStudyControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'marketStudyControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$marketStudyControllerHash();

  @$internal
  @override
  MarketStudyController create() => MarketStudyController();
}

String _$marketStudyControllerHash() =>
    r'84a8f18708e4d38ee9cd930682286905dafdcf1d';

abstract class _$MarketStudyController extends $AsyncNotifier<void> {
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
