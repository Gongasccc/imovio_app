import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/authentication/domain/app_user.dart';
import 'package:imovio/src/features/expenses/data/expenses_repository.dart';
import 'package:imovio/src/features/goals/domain/goals.dart';
import 'package:imovio/src/features/pipeline/data/deals_repository.dart';
import 'package:imovio/src/features/properties/data/properties_repository.dart';
import 'package:imovio/src/features/settings/data/settings_repository.dart';
import 'package:imovio/src/features/tasks/data/tasks_repository.dart';

part 'goals_repository.g.dart';

class GoalsRepository {
  const GoalsRepository(this._firestore);
  final FirebaseFirestore _firestore;

  static String path(UserID uid) => 'users/$uid/settings/goals';

  Stream<MonthlyGoals> watch({required UserID uid}) => _firestore
      .doc(path(uid))
      .snapshots()
      .map((s) => MonthlyGoals.fromMap(s.data()));

  Future<void> save({required UserID uid, required MonthlyGoals goals}) =>
      _firestore.doc(path(uid)).set(goals.toMap());
}

@Riverpod(keepAlive: true)
GoalsRepository goalsRepository(Ref ref) =>
    GoalsRepository(ref.watch(firestoreProvider));

@riverpod
Stream<MonthlyGoals> goalsStream(Ref ref) =>
    ref.watch(goalsRepositoryProvider).watch(uid: ref.watch(currentUidProvider));

/// Resultados dos últimos 6 meses (o último é o mês atual).
@riverpod
List<MonthResults> monthlyResults(Ref ref) => lastMonths(
      DateTime.now(),
      properties: ref.watch(propertiesStreamProvider).value ?? const [],
      tasks: ref.watch(tasksStreamProvider).value ?? const [],
      deals: ref.watch(dealsStreamProvider).value ?? const [],
      expenses: ref.watch(expensesStreamProvider).value ?? const [],
    );
