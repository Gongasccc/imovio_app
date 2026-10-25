// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expenses_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(expensesRepository)
final expensesRepositoryProvider = ExpensesRepositoryProvider._();

final class ExpensesRepositoryProvider
    extends
        $FunctionalProvider<
          ExpensesRepository,
          ExpensesRepository,
          ExpensesRepository
        >
    with $Provider<ExpensesRepository> {
  ExpensesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'expensesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expensesRepositoryHash();

  @$internal
  @override
  $ProviderElement<ExpensesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ExpensesRepository create(Ref ref) {
    return expensesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExpensesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExpensesRepository>(value),
    );
  }
}

String _$expensesRepositoryHash() =>
    r'64cd817aecd6595aa4bbd0231fe17311967cfb82';

@ProviderFor(expensesStream)
final expensesStreamProvider = ExpensesStreamProvider._();

final class ExpensesStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Expense>>,
          List<Expense>,
          Stream<List<Expense>>
        >
    with $FutureModifier<List<Expense>>, $StreamProvider<List<Expense>> {
  ExpensesStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'expensesStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expensesStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<Expense>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Expense>> create(Ref ref) {
    return expensesStream(ref);
  }
}

String _$expensesStreamHash() => r'79be96b85a89f2dcb2cb1415f131cc55e89ebe5f';

/// Despesas agrupadas por imóvel.

@ProviderFor(expensesByProperty)
final expensesByPropertyProvider = ExpensesByPropertyProvider._();

/// Despesas agrupadas por imóvel.

final class ExpensesByPropertyProvider
    extends
        $FunctionalProvider<
          Map<String, List<Expense>>,
          Map<String, List<Expense>>,
          Map<String, List<Expense>>
        >
    with $Provider<Map<String, List<Expense>>> {
  /// Despesas agrupadas por imóvel.
  ExpensesByPropertyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'expensesByPropertyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expensesByPropertyHash();

  @$internal
  @override
  $ProviderElement<Map<String, List<Expense>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, List<Expense>> create(Ref ref) {
    return expensesByProperty(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, List<Expense>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, List<Expense>>>(value),
    );
  }
}

String _$expensesByPropertyHash() =>
    r'16385a359268816a9c7dbf15296bba55dfae896c';
