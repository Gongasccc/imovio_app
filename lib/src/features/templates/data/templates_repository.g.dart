// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'templates_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(templatesRepository)
final templatesRepositoryProvider = TemplatesRepositoryProvider._();

final class TemplatesRepositoryProvider
    extends
        $FunctionalProvider<
          TemplatesRepository,
          TemplatesRepository,
          TemplatesRepository
        >
    with $Provider<TemplatesRepository> {
  TemplatesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'templatesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$templatesRepositoryHash();

  @$internal
  @override
  $ProviderElement<TemplatesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TemplatesRepository create(Ref ref) {
    return templatesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TemplatesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TemplatesRepository>(value),
    );
  }
}

String _$templatesRepositoryHash() =>
    r'8b5e466b923c2d66ee4c8a3863576cbbe6c68e18';

/// Os modelos do utilizador seguidos dos que vêm com a app.

@ProviderFor(templates)
final templatesProvider = TemplatesProvider._();

/// Os modelos do utilizador seguidos dos que vêm com a app.

final class TemplatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MessageTemplate>>,
          List<MessageTemplate>,
          Stream<List<MessageTemplate>>
        >
    with
        $FutureModifier<List<MessageTemplate>>,
        $StreamProvider<List<MessageTemplate>> {
  /// Os modelos do utilizador seguidos dos que vêm com a app.
  TemplatesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'templatesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$templatesHash();

  @$internal
  @override
  $StreamProviderElement<List<MessageTemplate>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MessageTemplate>> create(Ref ref) {
    return templates(ref);
  }
}

String _$templatesHash() => r'a6c2614755cf8fc4c673e99da043e8169965c543';
