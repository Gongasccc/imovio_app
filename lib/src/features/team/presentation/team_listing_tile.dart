import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imovio/src/common_widgets/section_card.dart';
import 'package:imovio/src/constants/app_sizes.dart';
import 'package:imovio/src/features/contacts/domain/contact.dart';
import 'package:imovio/src/features/properties/application/property_matching.dart';
import 'package:imovio/src/features/properties/presentation/property_list_tile.dart';
import 'package:imovio/src/features/team/data/team_repository.dart';
import 'package:imovio/src/features/team/domain/team_listing.dart';
import 'package:imovio/src/utils/format.dart';

/// Linha de um imóvel de outro membro da equipa. Abre a ficha pública.
class TeamListingTile extends StatelessWidget {
  const TeamListingTile({super.key, required this.listing});
  final TeamListing listing;

  @override
  Widget build(BuildContext context) {
    final p = listing.property;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => showTeamListingSheet(context, listing),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: PropertyImage(url: p.cover, width: 64, height: 48),
      ),
      title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${p.tags} · ${p.concelho ?? 'Local'}\nda equipa · ${listing.agentName}',
      ),
      isThreeLine: true,
      trailing: Text(
        Format.euros(p.price),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

Future<void> showTeamListingSheet(BuildContext context, TeamListing listing) {
  final p = listing.property;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(
          Sizes.p16,
          0,
          Sizes.p16,
          Sizes.p24,
        ),
        children: [
          if (p.images.isNotEmpty)
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: p.images.length,
                separatorBuilder: (_, _) => gapW8,
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: PropertyImage(url: p.images[i], width: 280),
                ),
              ),
            ),
          gapH16,
          Text(p.title, style: Theme.of(context).textTheme.titleLarge),
          gapH8,
          Text(
            Format.euros(p.price),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          gapH8,
          Text(
            [
              p.negocio,
              p.tags,
              if (p.areaUtil != null) '${Format.number(p.areaUtil)} m² úteis',
              p.saleStatus,
            ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
          ),
          Text(
            [p.freguesia, p.concelho, p.distrito]
                .whereType<String>()
                .join(', '),
          ),
          gapH16,
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(listing.agentName),
              subtitle: const Text(
                'Consultor responsável. Fale com ele para visitas e '
                'condições.',
              ),
            ),
          ),
          if (p.desc != null) ...[gapH16, Text(p.desc!)],
          if (p.featureList.isNotEmpty) ...[
            gapH16,
            Wrap(
              spacing: Sizes.p8,
              runSpacing: Sizes.p8,
              children: [for (final f in p.featureList) Chip(label: Text(f))],
            ),
          ],
        ],
      ),
    ),
  );
}

/// Imóveis da equipa compatíveis com as preferências de um contacto.
/// Não mostra nada se o utilizador não estiver numa equipa.
class TeamMatchesSection extends ConsumerWidget {
  const TeamMatchesSection({super.key, required this.contact});
  final Contact contact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(teamListingsStreamProvider).value ?? const [];
    if (listings.isEmpty) return const SizedBox.shrink();
    final byId = {for (final l in listings) l.id: l};
    final matches = matchingProperties(
      contact,
      [for (final l in listings) l.property],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        gapH16,
        SectionCard(
          title: 'Imóveis da equipa compatíveis',
          icon: Icons.groups_outlined,
          child: matches.isEmpty
              ? const Text('Nenhum imóvel dos colegas é compatível.')
              : Column(
                  children: [
                    for (final p in matches)
                      TeamListingTile(listing: byId[p.id]!),
                  ],
                ),
        ),
      ],
    );
  }
}
