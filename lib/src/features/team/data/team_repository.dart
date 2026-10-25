import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/authentication/domain/app_user.dart';
import 'package:imovio/src/features/settings/data/settings_repository.dart';
import 'package:imovio/src/features/team/application/team_sync.dart';
import 'package:imovio/src/features/team/domain/afilhado_sale.dart';
import 'package:imovio/src/features/team/domain/team.dart';
import 'package:imovio/src/features/team/domain/team_listing.dart';
import 'package:imovio/src/utils/format.dart';

part 'team_repository.g.dart';

/// Erro mostrado ao utilizador quando o código não corresponde a nenhuma
/// equipa.
class TeamCodeNotFound implements Exception {
  @override
  String toString() => 'Não existe nenhuma equipa com esse código.';
}

class TeamRepository {
  const TeamRepository(this._firestore);
  final FirebaseFirestore _firestore;

  static String membershipPath(UserID uid) => 'users/$uid/team/membership';
  static String afilhadoPctsPath(UserID uid) => 'users/$uid/afilhados';
  static String teamPath(TeamID id) => 'teams/$id';
  static String codePath(String code) => 'teamCodes/$code';
  static String membersPath(TeamID id) => 'teams/$id/members';
  static String listingsPath(TeamID id) => 'teams/$id/listings';
  static String salesPath(TeamID id) => 'teams/$id/sales';

  // Sem letras e números que se confundem (O/0, I/1).
  static const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static String newCode([Random? random]) {
    final r = random ?? Random.secure();
    return List.generate(6, (_) => _codeChars[r.nextInt(_codeChars.length)])
        .join();
  }

  Stream<Membership> watchMembership({required UserID uid}) => _firestore
      .doc(membershipPath(uid))
      .snapshots()
      .map((s) => Membership.fromMap(s.data()));

  Stream<Team?> watchTeam({required TeamID teamId}) => _firestore
      .doc(teamPath(teamId))
      .snapshots()
      .map((s) => s.exists ? Team.fromMap(s.data()!, s.id) : null);

  Stream<List<TeamMember>> watchMembers({required TeamID teamId}) =>
      _firestore.collection(membersPath(teamId)).snapshots().map((snapshot) {
        final list = snapshot.docs
            .map((d) => TeamMember.fromMap(d.data(), d.id))
            .toList();
        list.sort((a, b) => a.name.compareTo(b.name));
        return list;
      });

  Stream<List<TeamListing>> watchListings({required TeamID teamId}) =>
      _firestore.collection(listingsPath(teamId)).snapshots().map(
        (snapshot) => snapshot.docs
            .map((d) => TeamListing.fromMap(d.data(), d.id))
            .toList(),
      );

  /// Vendas dos afilhados de [sponsorUid]. As regras só deixam o padrinho
  /// ler as que lhe dizem respeito, por isso a consulta tem de filtrar.
  Stream<List<AfilhadoSale>> watchSponsorSales({
    required TeamID teamId,
    required UserID sponsorUid,
  }) => _firestore
      .collection(salesPath(teamId))
      .where('sponsorUid', isEqualTo: sponsorUid)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((d) => AfilhadoSale.fromMap(d.data(), d.id))
            .toList(),
      );

  /// A % do padrinho para cada afilhado (privado do padrinho).
  Stream<Map<UserID, num>> watchAfilhadoPcts({required UserID uid}) =>
      _firestore.collection(afilhadoPctsPath(uid)).snapshots().map(
        (snapshot) => {
          for (final d in snapshot.docs) d.id: ?parseNum(d.data()['pct']),
        },
      );

  Future<void> setAfilhadoPct({
    required UserID uid,
    required UserID afilhadoUid,
    required num? pct,
  }) {
    final doc = _firestore.doc('${afilhadoPctsPath(uid)}/$afilhadoUid');
    return pct == null ? doc.delete() : doc.set({'pct': pct});
  }

  Future<void> createTeam({
    required UserID uid,
    required String teamName,
    required String myName,
  }) async {
    final teamRef = _firestore.collection('teams').doc();
    final code = newCode();
    final batch = _firestore.batch()
      ..set(teamRef, Team(
        id: teamRef.id,
        name: teamName,
        code: code,
        ownerUid: uid,
      ).toMap())
      ..set(_firestore.doc(codePath(code)), {'teamId': teamRef.id})
      ..set(_firestore.doc('${membersPath(teamRef.id)}/$uid'), {
        'name': myName,
        'code': code,
        'joinedAt': DateTime.now().millisecondsSinceEpoch,
      })
      ..set(_firestore.doc(membershipPath(uid)), {'teamId': teamRef.id});
    await batch.commit();
  }

  Future<void> joinTeam({
    required UserID uid,
    required String code,
    required String myName,
  }) async {
    final clean = code.trim().toUpperCase();
    final snap = await _firestore.doc(codePath(clean)).get();
    final teamId = snap.data()?['teamId']?.toString();
    if (teamId == null) throw TeamCodeNotFound();
    await _firestore.doc('${membersPath(teamId)}/$uid').set({
      'name': myName,
      'code': clean,
      'joinedAt': DateTime.now().millisecondsSinceEpoch,
    });
    await _firestore.doc(membershipPath(uid)).set({'teamId': teamId});
  }

  Future<void> setSponsor({
    required TeamID teamId,
    required UserID uid,
    required UserID? sponsorUid,
  }) => _firestore.doc('${membersPath(teamId)}/$uid').update({
    'sponsorUid': sponsorUid ?? '',
  });

  Future<void> setMyName({
    required TeamID teamId,
    required UserID uid,
    required String name,
  }) => _firestore.doc('${membersPath(teamId)}/$uid').update({'name': name});

  Future<void> setHiddenListings({
    required UserID uid,
    required List<String> hidden,
  }) => _firestore.doc(membershipPath(uid)).set({
    'hiddenListings': hidden,
  }, SetOptions(merge: true));

  /// Os documentos que este membro escreveu na equipa.
  Future<DocMap> loadOwnListings(TeamID teamId, UserID uid) async {
    final snap = await _firestore
        .collection(listingsPath(teamId))
        .where('agentUid', isEqualTo: uid)
        .get();
    return {for (final d in snap.docs) d.id: d.data()};
  }

  Future<DocMap> loadOwnSales(TeamID teamId, UserID uid) async {
    final snap = await _firestore
        .collection(salesPath(teamId))
        .where('afilhadoUid', isEqualTo: uid)
        .get();
    return {for (final d in snap.docs) d.id: d.data()};
  }

  Future<void> applySync(
    TeamID teamId, {
    required SyncPlan listings,
    required SyncPlan sales,
  }) async {
    final ops = <void Function(WriteBatch)>[
      for (final e in listings.sets.entries)
        (b) => b.set(
          _firestore.doc('${listingsPath(teamId)}/${e.key}'),
          {...e.value, 'updatedAt': FieldValue.serverTimestamp()},
        ),
      for (final id in listings.deletes)
        (b) => b.delete(_firestore.doc('${listingsPath(teamId)}/$id')),
      for (final e in sales.sets.entries)
        (b) => b.set(
          _firestore.doc('${salesPath(teamId)}/${e.key}'),
          {...e.value, 'updatedAt': FieldValue.serverTimestamp()},
        ),
      for (final id in sales.deletes)
        (b) => b.delete(_firestore.doc('${salesPath(teamId)}/$id')),
    ];
    // Um batch aceita no máximo 500 operações.
    for (var i = 0; i < ops.length; i += 400) {
      final batch = _firestore.batch();
      for (final op in ops.skip(i).take(400)) {
        op(batch);
      }
      await batch.commit();
    }
  }

  /// Sai da equipa: apaga o que partilhou e depois a ficha de membro.
  Future<void> leaveTeam({required TeamID teamId, required UserID uid}) async {
    final listings = await loadOwnListings(teamId, uid);
    final sales = await loadOwnSales(teamId, uid);
    await applySync(
      teamId,
      listings: SyncPlan(sets: const {}, deletes: listings.keys.toList()),
      sales: SyncPlan(sets: const {}, deletes: sales.keys.toList()),
    );
    await _firestore.doc('${membersPath(teamId)}/$uid').delete();
    await _firestore.doc(membershipPath(uid)).delete();
  }
}

@Riverpod(keepAlive: true)
TeamRepository teamRepository(Ref ref) =>
    TeamRepository(ref.watch(firestoreProvider));

@riverpod
Stream<Membership> membershipStream(Ref ref) {
  final uid = ref.watch(currentUidProvider);
  return ref.watch(teamRepositoryProvider).watchMembership(uid: uid);
}

/// A equipa atual, ou null se o utilizador não pertence a nenhuma.
@riverpod
Stream<Team?> teamStream(Ref ref) {
  final teamId = ref.watch(membershipStreamProvider).value?.teamId;
  if (teamId == null) return Stream.value(null);
  return ref.watch(teamRepositoryProvider).watchTeam(teamId: teamId);
}

@riverpod
Stream<List<TeamMember>> teamMembersStream(Ref ref) {
  final teamId = ref.watch(membershipStreamProvider).value?.teamId;
  if (teamId == null) return Stream.value(const []);
  return ref.watch(teamRepositoryProvider).watchMembers(teamId: teamId);
}

/// Imóveis partilhados pelos outros membros (os próprios ficam de fora).
@riverpod
Stream<List<TeamListing>> teamListingsStream(Ref ref) {
  final uid = ref.watch(currentUidProvider);
  final teamId = ref.watch(membershipStreamProvider).value?.teamId;
  if (teamId == null) return Stream.value(const []);
  return ref
      .watch(teamRepositoryProvider)
      .watchListings(teamId: teamId)
      .map((list) => list.where((l) => l.agentUid != uid).toList());
}

@riverpod
Stream<List<AfilhadoSale>> sponsorSalesStream(Ref ref) {
  final uid = ref.watch(currentUidProvider);
  final teamId = ref.watch(membershipStreamProvider).value?.teamId;
  if (teamId == null) return Stream.value(const []);
  return ref
      .watch(teamRepositoryProvider)
      .watchSponsorSales(teamId: teamId, sponsorUid: uid);
}

@riverpod
Stream<Map<UserID, num>> afilhadoPctsStream(Ref ref) {
  final uid = ref.watch(currentUidProvider);
  return ref.watch(teamRepositoryProvider).watchAfilhadoPcts(uid: uid);
}
