import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/authentication/domain/app_user.dart';
import 'package:imovio/src/features/contacts/domain/contact.dart';
import 'package:imovio/src/features/settings/data/settings_repository.dart';

part 'contacts_repository.g.dart';

class ContactsRepository {
  const ContactsRepository(this._firestore);
  final FirebaseFirestore _firestore;

  static String contactsPath(UserID uid) => 'users/$uid/contactos';
  static String contactPath(UserID uid, ContactID id) =>
      'users/$uid/contactos/$id';

  CollectionReference<Contact> _collection(UserID uid) =>
      _firestore.collection(contactsPath(uid)).withConverter(
            fromFirestore: (snapshot, _) =>
                Contact.fromMap(snapshot.data()!, snapshot.id),
            toFirestore: (contact, _) => contact.toMap(),
          );

  Stream<List<Contact>> watchContacts({required UserID uid}) =>
      _collection(uid).snapshots().map((snapshot) {
        final contacts = snapshot.docs.map((d) => d.data()).toList();
        contacts.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return contacts;
      });

  /// Cria o contacto e devolve o id novo.
  Future<ContactID> addContact({
    required UserID uid,
    required Contact contact,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final ref = await _firestore
        .collection(contactsPath(uid))
        .add(contact.copyWith(createdAt: now, updatedAt: now).toMap());
    return ref.id;
  }

  /// Atualiza sem tocar no `createdAt` (a app original reescrevia-o).
  Future<void> updateContact({
    required UserID uid,
    required Contact contact,
  }) {
    final data = contact.toMap()
      ..remove('createdAt')
      ..['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
    return _firestore
        .doc(contactPath(uid, contact.id))
        .set(data, SetOptions(merge: true));
  }

  Future<void> duplicateContact({
    required UserID uid,
    required Contact contact,
  }) =>
      addContact(
        uid: uid,
        contact: contact.copyWith(name: '${contact.name} (Cópia)'),
      );

  Future<void> deleteContact({required UserID uid, required ContactID id}) =>
      _firestore.doc(contactPath(uid, id)).delete();
}

@Riverpod(keepAlive: true)
ContactsRepository contactsRepository(Ref ref) =>
    ContactsRepository(ref.watch(firestoreProvider));

@riverpod
Stream<List<Contact>> contactsStream(Ref ref) {
  final uid = ref.watch(currentUidProvider);
  return ref.watch(contactsRepositoryProvider).watchContacts(uid: uid);
}

/// Contactos indexados por id, para mostrar nomes em negócios e tarefas.
@riverpod
Map<ContactID, Contact> contactsById(Ref ref) {
  final contacts = ref.watch(contactsStreamProvider).value ?? const [];
  return {for (final c in contacts) c.id: c};
}
