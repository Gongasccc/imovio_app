import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/authentication/domain/app_user.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
import 'package:imovio/src/features/settings/data/settings_repository.dart';

part 'properties_repository.g.dart';

class PropertiesRepository {
  const PropertiesRepository(this._firestore, this._storage);
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  static String propertiesPath(UserID uid) => 'users/$uid/imoveis';
  static String propertyPath(UserID uid, PropertyID id) =>
      'users/$uid/imoveis/$id';

  Stream<List<Property>> watchProperties({required UserID uid}) => _firestore
          .collection(propertiesPath(uid))
          .snapshots()
          .map((snapshot) {
        final list =
            snapshot.docs.map((d) => Property.fromMap(d.data(), d.id)).toList();
        list.sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));
        return list;
      });

  Stream<Property?> watchProperty({
    required UserID uid,
    required PropertyID id,
  }) =>
      _firestore.doc(propertyPath(uid, id)).snapshots().map(
            (s) => s.exists ? Property.fromMap(s.data()!, s.id) : null,
          );

  /// Reserva um id novo, para poder carregar fotos antes de guardar.
  PropertyID newId(UserID uid) =>
      _firestore.collection(propertiesPath(uid)).doc().id;

  Future<void> createProperty({
    required UserID uid,
    required Property property,
  }) =>
      _firestore.doc(propertyPath(uid, property.id)).set(
            property
                .copyWith(createdAt: DateTime.now().millisecondsSinceEpoch)
                .toMap(),
          );

  Future<void> updateProperty({
    required UserID uid,
    required Property property,
  }) {
    final data = property.toMap()..remove('createdAt');
    return _firestore
        .doc(propertyPath(uid, property.id))
        .set(data, SetOptions(merge: true));
  }

  Future<void> deleteProperty({
    required UserID uid,
    required PropertyID id,
  }) =>
      _firestore.doc(propertyPath(uid, id)).delete();

  /// Carrega uma foto para o Firebase Storage e devolve o URL público.
  Future<String> uploadPhoto({
    required UserID uid,
    required PropertyID propertyId,
    required Uint8List bytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
    final ref = _storage.ref(
      'users/$uid/imoveis/$propertyId/'
      '${DateTime.now().millisecondsSinceEpoch}_$safeName',
    );
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }
}

@Riverpod(keepAlive: true)
FirebaseStorage firebaseStorage(Ref ref) => FirebaseStorage.instance;

@Riverpod(keepAlive: true)
PropertiesRepository propertiesRepository(Ref ref) => PropertiesRepository(
      ref.watch(firestoreProvider),
      ref.watch(firebaseStorageProvider),
    );

@riverpod
Stream<List<Property>> propertiesStream(Ref ref) {
  final uid = ref.watch(currentUidProvider);
  return ref.watch(propertiesRepositoryProvider).watchProperties(uid: uid);
}

@riverpod
Stream<Property?> propertyStream(Ref ref, PropertyID id) {
  final uid = ref.watch(currentUidProvider);
  return ref
      .watch(propertiesRepositoryProvider)
      .watchProperty(uid: uid, id: id);
}

@riverpod
Map<PropertyID, Property> propertiesById(Ref ref) {
  final list = ref.watch(propertiesStreamProvider).value ?? const [];
  return {for (final p in list) p.id: p};
}
