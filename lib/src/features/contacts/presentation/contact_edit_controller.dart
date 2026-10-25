import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/contacts/data/contacts_repository.dart';
import 'package:imovio/src/features/contacts/domain/contact.dart';

part 'contact_edit_controller.g.dart';

@riverpod
class ContactEditController extends _$ContactEditController {
  @override
  FutureOr<void> build() {}

  /// Cria ou atualiza. Devolve o id do contacto, ou null em caso de erro.
  Future<ContactID?> submit(Contact contact, {required bool isNew}) async {
    final uid = ref.read(currentUidProvider);
    final repo = ref.read(contactsRepositoryProvider);
    state = const AsyncLoading();
    ContactID? id;
    final result = await AsyncValue.guard(() async {
      if (isNew) {
        id = await repo.addContact(uid: uid, contact: contact);
      } else {
        await repo.updateContact(uid: uid, contact: contact);
        id = contact.id;
      }
    });
    if (!ref.mounted) return id;
    state = result;
    return result.hasError ? null : id;
  }

  Future<bool> delete(ContactID id) async {
    final uid = ref.read(currentUidProvider);
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(contactsRepositoryProvider).deleteContact(uid: uid, id: id),
    );
    if (ref.mounted) state = result;
    return !result.hasError;
  }
}
