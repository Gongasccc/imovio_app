import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:imovio/src/features/ai/data/gemini_repository.dart';
import 'package:imovio/src/features/ai/data/tavily_client.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/authentication/domain/app_user.dart';
import 'package:imovio/src/features/settings/data/settings_repository.dart';

part 'tavily_repository.g.dart';

/// Chave do Tavily (pesquisa na web), no mesmo documento da chave do Gemini:
/// `users/{uid}/settings/ia`, campo `tavilyKey`.
class TavilyKeyRepository {
  const TavilyKeyRepository(this._firestore);
  final FirebaseFirestore _firestore;

  Stream<String?> watchKey({required UserID uid}) =>
      _firestore.doc(GeminiKeyRepository.path(uid)).snapshots().map((s) {
        final key = s.data()?['tavilyKey']?.toString().trim();
        return (key == null || key.isEmpty) ? null : key;
      });

  Future<void> setKey({required UserID uid, required String? key}) => _firestore
      .doc(GeminiKeyRepository.path(uid))
      .set({'tavilyKey': key?.trim() ?? ''}, SetOptions(merge: true));
}

@Riverpod(keepAlive: true)
TavilyKeyRepository tavilyKeyRepository(Ref ref) =>
    TavilyKeyRepository(ref.watch(firestoreProvider));

@riverpod
Stream<String?> tavilyKey(Ref ref) {
  final uid = ref.watch(currentUidProvider);
  return ref.watch(tavilyKeyRepositoryProvider).watchKey(uid: uid);
}

/// Cliente pronto a usar, ou null se o utilizador ainda não pôs a chave.
@riverpod
Future<TavilyClient?> tavilyClient(Ref ref) async {
  final key = await ref.watch(tavilyKeyProvider.future);
  if (key == null) return null;
  return TavilyClient(ref.watch(geminiHttpClientProvider), key);
}
