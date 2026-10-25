import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:imovio/src/common_widgets/status_badge.dart';
import 'package:imovio/src/features/contacts/data/contacts_repository.dart';
import 'package:imovio/src/features/pipeline/domain/deal.dart';
import 'package:imovio/src/features/properties/data/properties_repository.dart';
import 'package:imovio/src/routing/app_router.dart';
import 'package:imovio/src/utils/format.dart';

/// Linha de negócio com cliente, imóvel, fase e valor.
class DealTile extends ConsumerWidget {
  const DealTile({super.key, required this.deal, this.showStage = true});
  final Deal deal;
  final bool showStage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contact = ref.watch(contactsByIdProvider)[deal.contactId];
    final property = ref.watch(propertiesByIdProvider)[deal.propertyId];
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () =>
          context.pushNamed(AppRoute.deal.name, pathParameters: {'id': deal.id}),
      title: Text(deal.title,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text([
        'Cliente: ${contact?.name ?? '—'}',
        if (property != null) property.title,
      ].join(' · ')),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            Format.euros(deal.value),
            style: TextStyle(fontWeight: FontWeight.w700, color: scheme.primary),
          ),
          if (showStage) ...[
            const SizedBox(height: 4),
            StatusBadge(label: deal.stage),
          ],
        ],
      ),
    );
  }
}
