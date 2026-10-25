// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'market_study_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(marketStudyRepository)
final marketStudyRepositoryProvider = MarketStudyRepositoryProvider._();

final class MarketStudyRepositoryProvider
    extends
        $FunctionalProvider<
          MarketStudyRepository,
          MarketStudyRepository,
          MarketStudyRepository
        >
    with $Provider<MarketStudyRepository> {
  MarketStudyRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'marketStudyRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$marketStudyRepositoryHash();

  @$internal
  @override
  $ProviderElement<MarketStudyRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MarketStudyRepository create(Ref ref) {
    return marketStudyRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MarketStudyRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MarketStudyRepository>(value),
    );
  }
}

String _$marketStudyRepositoryHash() =>
    r'01417fac814f20e91a318550b7a215db52c0d826';

@ProviderFor(comparablesStream)
final comparablesStreamProvider = ComparablesStreamProvider._();

final class ComparablesStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ComparableListing>>,
          List<ComparableListing>,
          Stream<List<ComparableListing>>
        >
    with
        $FutureModifier<List<ComparableListing>>,
        $StreamProvider<List<ComparableListing>> {
  ComparablesStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'comparablesStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$comparablesStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<ComparableListing>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ComparableListing>> create(Ref ref) {
    return comparablesStream(ref);
  }
}

String _$comparablesStreamHash() => r'd553f6ab383599a4de6d0c91e4424e67b0769ce6';

@ProviderFor(studySettingsStream)
final studySettingsStreamProvider = StudySettingsStreamFamily._();

final class StudySettingsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<StudySettings>,
          StudySettings,
          Stream<StudySettings>
        >
    with $FutureModifier<StudySettings>, $StreamProvider<StudySettings> {
  StudySettingsStreamProvider._({
    required StudySettingsStreamFamily super.from,
    required PropertyID super.argument,
  }) : super(
         retry: null,
         name: r'studySettingsStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$studySettingsStreamHash();

  @override
  String toString() {
    return r'studySettingsStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<StudySettings> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<StudySettings> create(Ref ref) {
    final argument = this.argument as PropertyID;
    return studySettingsStream(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is StudySettingsStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$studySettingsStreamHash() =>
    r'c99c6fa14064d23e2d7db2705ea6dc4f1beea45b';

final class StudySettingsStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<StudySettings>, PropertyID> {
  StudySettingsStreamFamily._()
    : super(
        retry: null,
        name: r'studySettingsStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  StudySettingsStreamProvider call(PropertyID propertyId) =>
      StudySettingsStreamProvider._(argument: propertyId, from: this);

  @override
  String toString() => r'studySettingsStreamProvider';
}

/// Preços do INE incluídos na app (atualizados todos os meses pelo
/// GitHub Actions, ver `tool/update_ine.dart`).

@ProviderFor(inePrices)
final inePricesProvider = InePricesProvider._();

/// Preços do INE incluídos na app (atualizados todos os meses pelo
/// GitHub Actions, ver `tool/update_ine.dart`).

final class InePricesProvider
    extends
        $FunctionalProvider<
          AsyncValue<InePrices>,
          InePrices,
          FutureOr<InePrices>
        >
    with $FutureModifier<InePrices>, $FutureProvider<InePrices> {
  /// Preços do INE incluídos na app (atualizados todos os meses pelo
  /// GitHub Actions, ver `tool/update_ine.dart`).
  InePricesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inePricesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inePricesHash();

  @$internal
  @override
  $FutureProviderElement<InePrices> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<InePrices> create(Ref ref) {
    return inePrices(ref);
  }
}

String _$inePricesHash() => r'958ee4b44e2501459147bfe6d2a8d895fa986251';
