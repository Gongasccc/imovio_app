import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:imovio/src/features/ai/data/gemini_client.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/authentication/domain/app_user.dart';
import 'package:imovio/src/features/settings/data/settings_repository.dart';
import 'package:imovio/src/features/team/data/team_repository.dart';

part 'gemini_repository.g.dart';

/// Chave do Gemini do utilizador, em `users/{uid}/settings/ia`. Fica na conta
/// (só o próprio a lê, pelas regras do Firestore) e nunca no código
/// publicado.
class GeminiKeyRepository {
  const GeminiKeyRepository(this._firestore);
  final FirebaseFirestore _firestore;

  static String path(UserID uid) => 'users/$uid/settings/ia';

  Stream<String?> watchKey({required UserID uid}) =>
      _firestore.doc(path(uid)).snapshots().map((s) {
        final key = s.data()?['geminiKey']?.toString().trim();
        return (key == null || key.isEmpty) ? null : key;
      });

  Future<void> setKey({required UserID uid, required String? key}) => _firestore
      .doc(path(uid))
      .set({'geminiKey': key?.trim() ?? ''}, SetOptions(merge: true));
}

@Riverpod(keepAlive: true)
GeminiKeyRepository geminiKeyRepository(Ref ref) =>
    GeminiKeyRepository(ref.watch(firestoreProvider));

@riverpod
Stream<String?> geminiKey(Ref ref) {
  final uid = ref.watch(currentUidProvider);
  return ref.watch(geminiKeyRepositoryProvider).watchKey(uid: uid);
}

@Riverpod(keepAlive: true)
http.Client geminiHttpClient(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
}

/// A chave a usar: a do próprio utilizador ou, se não tiver, a da equipa.
@riverpod
Future<String?> effectiveGeminiKey(Ref ref) async {
  final own = await ref.watch(geminiKeyProvider.future);
  if (own != null) return own;
  return ref.watch(teamGeminiKeyProvider.future);
}

/// Cliente pronto a usar, ou null se não houver chave (própria ou da equipa).
@riverpod
Future<GeminiClient?> geminiClient(Ref ref) async {
  final key = await ref.watch(effectiveGeminiKeyProvider.future);
  if (key == null) return null;
  return GeminiClient(ref.watch(geminiHttpClientProvider), key);
}
