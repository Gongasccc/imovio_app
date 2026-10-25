// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_edit_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ContactEditController)
final contactEditControllerProvider = ContactEditControllerProvider._();

final class ContactEditControllerProvider
    extends $AsyncNotifierProvider<ContactEditController, void> {
  ContactEditControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contactEditControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contactEditControllerHash();

  @$internal
  @override
  ContactEditController create() => ContactEditController();
}

String _$contactEditControllerHash() =>
    r'c043db88810391d9ebe07c8f24a11d27437f66d6';

abstract class _$ContactEditController extends $AsyncNotifier<void> {
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
