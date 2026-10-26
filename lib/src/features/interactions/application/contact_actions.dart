import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/contacts/domain/contact.dart';
import 'package:imovio/src/features/interactions/data/interactions_repository.dart';
import 'package:imovio/src/features/interactions/domain/interaction.dart';
import 'package:imovio/src/utils/launcher.dart';

/// Ligar, WhatsApp, SMS e email a partir da app, ficando registado na linha
/// do tempo do contacto.
class ContactActions {
  ContactActions(this._ref);
  final WidgetRef _ref;

  Future<void> _log(
    Contact c,
    InteractionKind kind, {
    String? note,
    String? propertyId,
  }) async {
    try {
      await _ref.read(interactionsRepositoryProvider).add(
            uid: _ref.read(currentUidProvider),
            interaction: Interaction(
              id: '',
              contactId: c.id,
              kind: kind,
              at: DateTime.now(),
              note: note,
              propertyId: propertyId,
              automatic: true,
            ),
          );
    } catch (_) {
      // O registo é um extra: a ação em si nunca falha por causa dele.
    }
  }

  Future<void> call(Contact c) async {
    if (c.phone == null) return;
    await callPhone(c.phone!);
    await _log(c, InteractionKind.call);
  }

  Future<void> whatsapp(Contact c, {String? text, String? propertyId}) async {
    if (c.phone == null) return;
    await openWhatsApp(c.phone!, text: text);
    await _log(c, InteractionKind.whatsapp,
        note: text, propertyId: propertyId);
  }

  Future<void> sms(Contact c, {String? text}) async {
    if (c.phone == null) return;
    await sendSms(c.phone!, body: text);
    await _log(c, InteractionKind.sms, note: text);
  }

  Future<void> email(
    Contact c, {
    String? subject,
    String? body,
    String? propertyId,
  }) async {
    if (c.email == null) return;
    await sendEmail(c.email!, subject: subject, body: body);
    await _log(c, InteractionKind.email,
        note: subject ?? body, propertyId: propertyId);
  }
}
