import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/authentication/domain/app_user.dart';
import 'package:imovio/src/features/expenses/domain/expense.dart';
import 'package:imovio/src/features/settings/data/settings_repository.dart';

part 'expenses_repository.g.dart';

class ExpensesRepository {
  const ExpensesRepository(this._firestore);
  final FirebaseFirestore _firestore;

  static String expensesPath(UserID uid) => 'users/$uid/despesas';
  static String expensePath(UserID uid, ExpenseID id) =>
      'users/$uid/despesas/$id';

  Stream<List<Expense>> watchExpenses({required UserID uid}) =>
      _firestore.collection(expensesPath(uid)).snapshots().map((snapshot) {
        final list = snapshot.docs
            .map((d) => Expense.fromMap(d.data(), d.id))
            .toList();
        list.sort(
          (a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)),
        );
        return list;
      });

  Future<void> addExpense({required UserID uid, required Expense expense}) =>
      _firestore
          .collection(expensesPath(uid))
          .add(
            expense
                .copyWith(createdAt: DateTime.now().millisecondsSinceEpoch)
                .toMap(),
          );

  Future<void> updateExpense({required UserID uid, required Expense expense}) {
    final data = expense.toMap()..remove('createdAt');
    return _firestore
        .doc(expensePath(uid, expense.id))
        .set(data, SetOptions(merge: true));
  }

  Future<void> deleteExpense({required UserID uid, required ExpenseID id}) =>
      _firestore.doc(expensePath(uid, id)).delete();
}

@Riverpod(keepAlive: true)
ExpensesRepository expensesRepository(Ref ref) =>
    ExpensesRepository(ref.watch(firestoreProvider));

@riverpod
Stream<List<Expense>> expensesStream(Ref ref) {
  final uid = ref.watch(currentUidProvider);
  return ref.watch(expensesRepositoryProvider).watchExpenses(uid: uid);
}

/// Despesas agrupadas por imóvel.
@riverpod
Map<String, List<Expense>> expensesByProperty(Ref ref) {
  final all = ref.watch(expensesStreamProvider).value ?? const [];
  final map = <String, List<Expense>>{};
  for (final e in all) {
    (map[e.propertyId] ??= []).add(e);
  }
  return map;
}
