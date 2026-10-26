// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interactions_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(interactionsRepository)
final interactionsRepositoryProvider = InteractionsRepositoryProvider._();

final class InteractionsRepositoryProvider
    extends
        $FunctionalProvider<
          InteractionsRepository,
          InteractionsRepository,
          InteractionsRepository
        >
    with $Provider<InteractionsRepository> {
  InteractionsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'interactionsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$interactionsRepositoryHash();

  @$internal
  @override
  $ProviderElement<InteractionsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InteractionsRepository create(Ref ref) {
    return interactionsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InteractionsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InteractionsRepository>(value),
    );
  }
}

String _$interactionsRepositoryHash() =>
    r'b899a3a6e0456cbe2ab606dd29fed3e7316f8ca7';

@ProviderFor(interactionsStream)
final interactionsStreamProvider = InteractionsStreamProvider._();

final class InteractionsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Interaction>>,
          List<Interaction>,
          Stream<List<Interaction>>
        >
    with
        $FutureModifier<List<Interaction>>,
        $StreamProvider<List<Interaction>> {
  InteractionsStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'interactionsStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$interactionsStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<Interaction>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Interaction>> create(Ref ref) {
    return interactionsStream(ref);
  }
}

String _$interactionsStreamHash() =>
    r'b2cd0d8789bc71d7c82ecc5035f37a50fc0c4d1b';

@ProviderFor(interactionsByContact)
final interactionsByContactProvider = InteractionsByContactProvider._();

final class InteractionsByContactProvider
    extends
        $FunctionalProvider<
          Map<String, List<Interaction>>,
          Map<String, List<Interaction>>,
          Map<String, List<Interaction>>
        >
    with $Provider<Map<String, List<Interaction>>> {
  InteractionsByContactProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'interactionsByContactProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$interactionsByContactHash();

  @$internal
  @override
  $ProviderElement<Map<String, List<Interaction>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, List<Interaction>> create(Ref ref) {
    return interactionsByContact(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, List<Interaction>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, List<Interaction>>>(
        value,
      ),
    );
  }
}

String _$interactionsByContactHash() =>
    r'77f5eef31b27c4d14c07ed551eca35a026b8149d';
