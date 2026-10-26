// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goals_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(goalsRepository)
final goalsRepositoryProvider = GoalsRepositoryProvider._();

final class GoalsRepositoryProvider
    extends
        $FunctionalProvider<GoalsRepository, GoalsRepository, GoalsRepository>
    with $Provider<GoalsRepository> {
  GoalsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goalsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goalsRepositoryHash();

  @$internal
  @override
  $ProviderElement<GoalsRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoalsRepository create(Ref ref) {
    return goalsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoalsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoalsRepository>(value),
    );
  }
}

String _$goalsRepositoryHash() => r'215957d69939ee05881ce7222ff143ac90f38cea';

@ProviderFor(goalsStream)
final goalsStreamProvider = GoalsStreamProvider._();

final class GoalsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<MonthlyGoals>,
          MonthlyGoals,
          Stream<MonthlyGoals>
        >
    with $FutureModifier<MonthlyGoals>, $StreamProvider<MonthlyGoals> {
  GoalsStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goalsStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goalsStreamHash();

  @$internal
  @override
  $StreamProviderElement<MonthlyGoals> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<MonthlyGoals> create(Ref ref) {
    return goalsStream(ref);
  }
}

String _$goalsStreamHash() => r'c97f28431ef7458c4ccf98330e3f43d0b9d5cf75';

/// Resultados dos últimos 6 meses (o último é o mês atual).

@ProviderFor(monthlyResults)
final monthlyResultsProvider = MonthlyResultsProvider._();

/// Resultados dos últimos 6 meses (o último é o mês atual).

final class MonthlyResultsProvider
    extends
        $FunctionalProvider<
          List<MonthResults>,
          List<MonthResults>,
          List<MonthResults>
        >
    with $Provider<List<MonthResults>> {
  /// Resultados dos últimos 6 meses (o último é o mês atual).
  MonthlyResultsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'monthlyResultsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monthlyResultsHash();

  @$internal
  @override
  $ProviderElement<List<MonthResults>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<MonthResults> create(Ref ref) {
    return monthlyResults(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<MonthResults> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<MonthResults>>(value),
    );
  }
}

String _$monthlyResultsHash() => r'd2eaa74b37d83cb12e4fcc1e8373e470d919cdff';
