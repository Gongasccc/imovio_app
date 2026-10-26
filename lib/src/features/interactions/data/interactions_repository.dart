import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/authentication/domain/app_user.dart';
import 'package:imovio/src/features/interactions/domain/interaction.dart';
import 'package:imovio/src/features/settings/data/settings_repository.dart';

part 'interactions_repository.g.dart';

class InteractionsRepository {
  const InteractionsRepository(this._firestore);
  final FirebaseFirestore _firestore;

  static String path(UserID uid) => 'users/$uid/interacoes';

  Stream<List<Interaction>> watchInteractions({required UserID uid}) =>
      _firestore.collection(path(uid)).snapshots().map((s) {
        final list =
            s.docs.map((d) => Interaction.fromMap(d.data(), d.id)).toList();
        list.sort((a, b) => b.at.compareTo(a.at));
        return list;
      });

  Future<void> add({required UserID uid, required Interaction interaction}) =>
      _firestore.collection(path(uid)).add(interaction.toMap());

  Future<void> delete({required UserID uid, required InteractionID id}) =>
      _firestore.doc('${path(uid)}/$id').delete();
}

@Riverpod(keepAlive: true)
InteractionsRepository interactionsRepository(Ref ref) =>
    InteractionsRepository(ref.watch(firestoreProvider));

@riverpod
Stream<List<Interaction>> interactionsStream(Ref ref) {
  final uid = ref.watch(currentUidProvider);
  return ref.watch(interactionsRepositoryProvider).watchInteractions(uid: uid);
}

@riverpod
Map<String, List<Interaction>> interactionsByContact(Ref ref) {
  final map = <String, List<Interaction>>{};
  for (final i in ref.watch(interactionsStreamProvider).value ?? const []) {
    (map[i.contactId] ??= []).add(i);
  }
  return map;
}
