import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:imovio/src/features/authentication/domain/app_user.dart';
import 'package:imovio/src/features/contacts/data/contacts_repository.dart';
import 'package:imovio/src/features/contacts/domain/contact.dart';
import 'package:imovio/src/features/properties/data/properties_repository.dart';
import 'package:imovio/src/features/settings/data/settings_repository.dart';

part 'contact_attachments_repository.g.dart';

/// Ficheiros dos contactos: o conteúdo vai para o Firebase Storage em
/// `users/{uid}/contactos/{id}/...` e a lista fica no campo `attachments`.
class ContactAttachmentsRepository {
  const ContactAttachmentsRepository(this._firestore, this._storage);
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  static const maxBytes = 20 * 1024 * 1024;

  Future<Attachment> upload({
    required UserID uid,
    required ContactID contactId,
    required String fileName,
    required Uint8List bytes,
    String? contentType,
  }) async {
    if (bytes.length > maxBytes) {
      throw StateError('O ficheiro tem mais de 20 MB.');
    }
    final safe = fileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
    final now = DateTime.now().millisecondsSinceEpoch;
    final path = 'users/$uid/contactos/$contactId/${now}_$safe';
    final ref = _storage.ref(path);
    await ref.putData(
      bytes,
      SettableMetadata(contentType: contentType ?? 'application/octet-stream'),
    );
    final attachment = Attachment(
      name: fileName,
      url: await ref.getDownloadURL(),
      path: path,
      size: bytes.length,
      contentType: contentType,
      uploadedAt: now,
    );
    await _firestore.doc(ContactsRepository.contactPath(uid, contactId)).set({
      'attachments': FieldValue.arrayUnion([attachment.toMap()]),
    }, SetOptions(merge: true));
    return attachment;
  }

  Future<void> delete({
    required UserID uid,
    required ContactID contactId,
    required Attachment attachment,
  }) async {
    await _firestore.doc(ContactsRepository.contactPath(uid, contactId)).set({
      'attachments': FieldValue.arrayRemove([attachment.toMap()]),
    }, SetOptions(merge: true));
    try {
      await _storage.ref(attachment.path).delete();
    } on FirebaseException catch (e) {
      // Já não existia: a lista é o que conta.
      if (e.code != 'object-not-found') rethrow;
    }
  }
}

@Riverpod(keepAlive: true)
ContactAttachmentsRepository contactAttachmentsRepository(Ref ref) =>
    ContactAttachmentsRepository(
      ref.watch(firestoreProvider),
      ref.watch(firebaseStorageProvider),
    );
