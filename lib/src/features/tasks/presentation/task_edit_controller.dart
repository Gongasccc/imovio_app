import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/tasks/data/tasks_repository.dart';
import 'package:imovio/src/features/tasks/domain/task.dart';

part 'task_edit_controller.g.dart';

@riverpod
class TaskEditController extends _$TaskEditController {
  @override
  FutureOr<void> build() {}

  Future<bool> submit(Task task, {required bool isNew}) async {
    final uid = ref.read(currentUidProvider);
    final repo = ref.read(tasksRepositoryProvider);
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => isNew
        ? repo.addTask(uid: uid, task: task)
        : repo.updateTask(uid: uid, task: task));
    if (ref.mounted) state = result;
    return !result.hasError;
  }

  Future<bool> delete(TaskID id) async {
    final uid = ref.read(currentUidProvider);
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
        () => ref.read(tasksRepositoryProvider).deleteTask(uid: uid, id: id));
    if (ref.mounted) state = result;
    return !result.hasError;
  }
}
