import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/authentication/domain/app_user.dart';
import 'package:imovio/src/features/market_study/domain/comparable_listing.dart';
import 'package:imovio/src/features/market_study/domain/ine_prices.dart';
import 'package:imovio/src/features/market_study/domain/study_settings.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
import 'package:imovio/src/features/settings/data/settings_repository.dart';

part 'market_study_repository.g.dart';

/// Base de comparáveis (`users/{uid}/comparaveis`) e escolhas de cada estudo
/// (`users/{uid}/estudos/{propertyId}`).
class MarketStudyRepository {
  const MarketStudyRepository(this._firestore);
  final FirebaseFirestore _firestore;

  static String comparablesPath(UserID uid) => 'users/$uid/comparaveis';
  static String settingsPath(UserID uid, PropertyID id) =>
      'users/$uid/estudos/$id';

  Stream<List<ComparableListing>> watchComparables({required UserID uid}) =>
      _firestore
          .collection(comparablesPath(uid))
          .snapshots()
          .map(
            (s) => s.docs
                .map((d) => ComparableListing.fromMap(d.data(), d.id))
                .toList(),
          );

  ComparableID newComparableId(UserID uid) =>
      _firestore.collection(comparablesPath(uid)).doc().id;

  Future<void> saveComparable({
    required UserID uid,
    required ComparableListing comparable,
  }) => _firestore
      .doc('${comparablesPath(uid)}/${comparable.id}')
      .set(comparable.toMap());

  Future<void> deleteComparable({
    required UserID uid,
    required ComparableID id,
  }) => _firestore.doc('${comparablesPath(uid)}/$id').delete();

  Stream<StudySettings> watchSettings({
    required UserID uid,
    required PropertyID propertyId,
  }) => _firestore
      .doc(settingsPath(uid, propertyId))
      .snapshots()
      .map((s) => StudySettings.fromMap(s.data()));

  Future<void> saveSettings({
    required UserID uid,
    required PropertyID propertyId,
    required StudySettings settings,
  }) => _firestore.doc(settingsPath(uid, propertyId)).set(settings.toMap());
}

@Riverpod(keepAlive: true)
MarketStudyRepository marketStudyRepository(Ref ref) =>
    MarketStudyRepository(ref.watch(firestoreProvider));

@riverpod
Stream<List<ComparableListing>> comparablesStream(Ref ref) {
  final uid = ref.watch(currentUidProvider);
  return ref.watch(marketStudyRepositoryProvider).watchComparables(uid: uid);
}

@riverpod
Stream<StudySettings> studySettingsStream(Ref ref, PropertyID propertyId) {
  final uid = ref.watch(currentUidProvider);
  return ref
      .watch(marketStudyRepositoryProvider)
      .watchSettings(uid: uid, propertyId: propertyId);
}

/// Preços do INE incluídos na app (atualizados todos os meses pelo
/// GitHub Actions, ver `tool/update_ine.dart`).
@Riverpod(keepAlive: true)
Future<InePrices> inePrices(Ref ref) async {
  final raw = await rootBundle.loadString('assets/market/ine_precos.json');
  return InePrices.fromMap(jsonDecode(raw) as Map<String, dynamic>);
}
