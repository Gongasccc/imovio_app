import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/authentication/domain/app_user.dart';
import 'package:imovio/src/features/settings/data/settings_repository.dart';
import 'package:imovio/src/features/templates/domain/message_template.dart';

part 'templates_repository.g.dart';

/// Modelos de mensagem do utilizador, em `users/{uid}/modelos`.
class TemplatesRepository {
  const TemplatesRepository(this._firestore);
  final FirebaseFirestore _firestore;

  static String path(UserID uid) => 'users/$uid/modelos';

  Stream<List<MessageTemplate>> watch({required UserID uid}) =>
      _firestore.collection(path(uid)).snapshots().map((s) => s.docs
          .map((d) => MessageTemplate.fromMap(d.data(), d.id))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name)));

  Future<void> save({required UserID uid, required MessageTemplate t}) =>
      t.id.isEmpty || t.builtIn
          ? _firestore.collection(path(uid)).add(t.toMap())
          : _firestore.doc('${path(uid)}/${t.id}').set(t.toMap());

  Future<void> delete({required UserID uid, required TemplateID id}) =>
      _firestore.doc('${path(uid)}/$id').delete();
}

@Riverpod(keepAlive: true)
TemplatesRepository templatesRepository(Ref ref) =>
    TemplatesRepository(ref.watch(firestoreProvider));

/// Os modelos do utilizador seguidos dos que vêm com a app.
@riverpod
Stream<List<MessageTemplate>> templates(Ref ref) {
  final uid = ref.watch(currentUidProvider);
  return ref
      .watch(templatesRepositoryProvider)
      .watch(uid: uid)
      .map((own) => [...own, ...builtInTemplates]);
}
