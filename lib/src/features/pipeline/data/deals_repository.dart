import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/authentication/domain/app_user.dart';
import 'package:imovio/src/features/pipeline/domain/deal.dart';
import 'package:imovio/src/features/settings/data/settings_repository.dart';

part 'deals_repository.g.dart';

class DealsRepository {
  const DealsRepository(this._firestore);
  final FirebaseFirestore _firestore;

  static String dealsPath(UserID uid) => 'users/$uid/pipeline';
  static String dealPath(UserID uid, DealID id) => 'users/$uid/pipeline/$id';

  Stream<List<Deal>> watchDeals({required UserID uid}) => _firestore
          .collection(dealsPath(uid))
          .snapshots()
          .map((snapshot) {
        final deals =
            snapshot.docs.map((d) => Deal.fromMap(d.data(), d.id)).toList();
        deals.sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));
        return deals;
      });

  Future<void> addDeal({required UserID uid, required Deal deal}) =>
      _firestore.collection(dealsPath(uid)).add(
            deal
                .copyWith(createdAt: DateTime.now().millisecondsSinceEpoch)
                .toMap(),
          );

  Future<void> updateDeal({required UserID uid, required Deal deal}) {
    final data = deal.toMap()..remove('createdAt');
    return _firestore
        .doc(dealPath(uid, deal.id))
        .set(data, SetOptions(merge: true));
  }

  Future<void> moveDeal({
    required UserID uid,
    required DealID id,
    required String stage,
  }) =>
      _firestore
          .doc(dealPath(uid, id))
          .set({'stage': stage}, SetOptions(merge: true));

  Future<void> deleteDeal({required UserID uid, required DealID id}) =>
      _firestore.doc(dealPath(uid, id)).delete();
}

@Riverpod(keepAlive: true)
DealsRepository dealsRepository(Ref ref) =>
    DealsRepository(ref.watch(firestoreProvider));

@riverpod
Stream<List<Deal>> dealsStream(Ref ref) {
  final uid = ref.watch(currentUidProvider);
  return ref.watch(dealsRepositoryProvider).watchDeals(uid: uid);
}
