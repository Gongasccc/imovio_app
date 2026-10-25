import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/authentication/domain/app_user.dart';
import 'package:imovio/src/features/settings/data/settings_repository.dart';
import 'package:imovio/src/features/tasks/domain/task.dart';

part 'tasks_repository.g.dart';

class TasksRepository {
  const TasksRepository(this._firestore);
  final FirebaseFirestore _firestore;

  static String tasksPath(UserID uid) => 'users/$uid/tarefas';
  static String taskPath(UserID uid, TaskID id) => 'users/$uid/tarefas/$id';

  Stream<List<Task>> watchTasks({required UserID uid}) => _firestore
          .collection(tasksPath(uid))
          .snapshots()
          .map((snapshot) {
        final tasks =
            snapshot.docs.map((d) => Task.fromMap(d.data(), d.id)).toList();
        tasks.sort(compareTasks);
        return tasks;
      });

  Future<void> addTask({required UserID uid, required Task task}) =>
      _firestore.collection(tasksPath(uid)).add(
            task
                .copyWith(createdAt: DateTime.now().millisecondsSinceEpoch)
                .toMap(),
          );

  Future<void> updateTask({required UserID uid, required Task task}) {
    final data = task.toMap()..remove('createdAt');
    return _firestore
        .doc(taskPath(uid, task.id))
        .set(data, SetOptions(merge: true));
  }

  Future<void> setDone({
    required UserID uid,
    required TaskID id,
    required bool done,
  }) =>
      _firestore.doc(taskPath(uid, id)).set(
        {'status': done ? TaskStatuses.done : TaskStatuses.pending},
        SetOptions(merge: true),
      );

  Future<void> deleteTask({required UserID uid, required TaskID id}) =>
      _firestore.doc(taskPath(uid, id)).delete();
}

/// Pendentes primeiro, depois por prazo (sem prazo no fim).
int compareTasks(Task a, Task b) {
  if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
  if (a.date == null && b.date == null) return a.title.compareTo(b.title);
  if (a.date == null) return 1;
  if (b.date == null) return -1;
  return a.date!.compareTo(b.date!);
}

@Riverpod(keepAlive: true)
TasksRepository tasksRepository(Ref ref) =>
    TasksRepository(ref.watch(firestoreProvider));

@riverpod
Stream<List<Task>> tasksStream(Ref ref) {
  final uid = ref.watch(currentUidProvider);
  return ref.watch(tasksRepositoryProvider).watchTasks(uid: uid);
}
