// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_edit_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TaskEditController)
final taskEditControllerProvider = TaskEditControllerProvider._();

final class TaskEditControllerProvider
    extends $AsyncNotifierProvider<TaskEditController, void> {
  TaskEditControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'taskEditControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$taskEditControllerHash();

  @$internal
  @override
  TaskEditController create() => TaskEditController();
}

String _$taskEditControllerHash() =>
    r'36cf667ad450e6bce38cabd2da4ef265639d234f';

abstract class _$TaskEditController extends $AsyncNotifier<void> {
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
