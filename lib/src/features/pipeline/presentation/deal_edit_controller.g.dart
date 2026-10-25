// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deal_edit_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DealEditController)
final dealEditControllerProvider = DealEditControllerProvider._();

final class DealEditControllerProvider
    extends $AsyncNotifierProvider<DealEditController, void> {
  DealEditControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dealEditControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dealEditControllerHash();

  @$internal
  @override
  DealEditController create() => DealEditController();
}

String _$dealEditControllerHash() =>
    r'22426f268aa61ae320ab6abd43a7b69f03c32375';

abstract class _$DealEditController extends $AsyncNotifier<void> {
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
