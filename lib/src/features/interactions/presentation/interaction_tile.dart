import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imovio/src/common_widgets/icon_label.dart';
import 'package:imovio/src/constants/app_theme.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/contacts/data/contacts_repository.dart';
import 'package:imovio/src/features/interactions/data/interactions_repository.dart';
import 'package:imovio/src/features/interactions/domain/interaction.dart';
import 'package:imovio/src/features/properties/data/properties_repository.dart';
import 'package:imovio/src/utils/format.dart';
import 'package:imovio/src/utils/run_action.dart';

/// Uma linha da linha do tempo: tipo, quando, nota e (nas visitas) a opinião.
class InteractionTile extends ConsumerWidget {
  const InteractionTile({
    super.key,
    required this.interaction,
    this.showContact = false,
    this.showProperty = true,
  });
  final Interaction interaction;
  final bool showContact;
  final bool showProperty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i = interaction;
    final scheme = Theme.of(context).colorScheme;
    final contact =
        showContact ? ref.watch(contactsByIdProvider)[i.contactId] : null;
    final property =
        showProperty ? ref.watch(propertiesByIdProvider)[i.propertyId] : null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: scheme.primary.withValues(alpha: 0.12),
        child: Icon(i.kind.icon, size: 20, color: scheme.primary),
      ),
      title: Text(
        [i.kind.label, if (contact != null) contact.name].join(' · '),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Format.dateTime(i.at)),
          if (property != null)
            IconLabel(icon: Icons.home_outlined, text: property.title),
          if (i.hasFeedback)
            Wrap(
              spacing: 8,
              children: [
                if (i.rating != null)
                  Text('★' * i.rating! + '☆' * (5 - i.rating!),
                      style: TextStyle(color: scheme.primary)),
                if (i.priceOpinion != null) Text('Preço: ${i.priceOpinion}'),
                if (i.interested != null)
                  Text(
                    i.interested! ? 'Interessado' : 'Sem interesse',
                    style: TextStyle(
                      color: i.interested! ? AppColors.green : AppColors.red,
                    ),
                  ),
              ],
            ),
          if (i.note != null)
            Text(i.note!, maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
      ),
      trailing: IconButton(
        tooltip: 'Apagar registo',
        icon: const Icon(Icons.close, size: 18),
        onPressed: () => confirmAndDelete(
          context,
          () => ref
              .read(interactionsRepositoryProvider)
              .delete(uid: ref.read(currentUidProvider), id: i.id),
          message: 'Apagar este registo da linha do tempo?',
          success: 'Registo apagado',
        ),
      ),
    );
  }
}
