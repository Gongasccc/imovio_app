import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/authentication/domain/app_user.dart';
import 'package:imovio/src/features/properties/application/sale_summary.dart';
import 'package:imovio/src/features/properties/data/properties_repository.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
import 'package:imovio/src/features/settings/data/settings_repository.dart';
import 'package:imovio/src/features/team/data/team_repository.dart';
import 'package:imovio/src/features/team/domain/afilhado_sale.dart';
import 'package:imovio/src/features/team/domain/team.dart';
import 'package:imovio/src/features/team/domain/team_listing.dart';

part 'team_sync.g.dart';

typedef DocMap = Map<String, Map<String, dynamic>>;

/// A parte do consultor num imóvel, com as mesmas contas do resumo de venda.
num agentShareOf(Property property, {required num defaultAgentSplitPct}) =>
    computeSaleSummary(
      property,
      const [],
      defaultAgentSplitPct: defaultAgentSplitPct,
    ).agentShare;

/// Imóveis que o membro partilha com a equipa: todos menos os vendidos e os
/// que escondeu.
DocMap desiredListings({
  required UserID uid,
  required String agentName,
  required List<Property> properties,
  required List<String> hidden,
}) => {
  for (final p in properties)
    if (!p.isSold && !hidden.contains(p.id))
      TeamListing.docId(uid, p.id): TeamListing.publicData(
        property: p,
        agentUid: uid,
        agentName: agentName,
      ),
};

/// Números de venda que o afilhado envia ao padrinho. Sem padrinho, nada.
DocMap desiredSales({
  required TeamMember me,
  required List<Property> properties,
  required num defaultAgentSplitPct,
}) {
  final sponsor = me.sponsorUid;
  if (sponsor == null) return {};
  return {
    for (final p in properties)
      if ((p.salePrice ?? p.price) != null)
        AfilhadoSale.docId(me.uid, p.id): AfilhadoSale(
          id: AfilhadoSale.docId(me.uid, p.id),
          afilhadoUid: me.uid,
          afilhadoName: me.name,
          sponsorUid: sponsor,
          propertyId: p.id,
          title: p.title,
          saleStatus: p.saleStatus,
          salePrice: p.salePrice ?? p.price,
          agentShare: agentShareOf(
            p,
            defaultAgentSplitPct: defaultAgentSplitPct,
          ),
          dateEnd: p.dateEnd,
        ).toMap(),
  };
}

/// O que tem de mudar no Firestore para passar de [current] a [desired].
class SyncPlan extends Equatable {
  const SyncPlan({required this.sets, required this.deletes});
  final DocMap sets;
  final List<String> deletes;

  bool get isEmpty => sets.isEmpty && deletes.isEmpty;

  @override
  List<Object?> get props => [sets, deletes];
}

String _canonical(Object? value) => jsonEncode(_sortKeys(value));

Object? _sortKeys(Object? value) => switch (value) {
  Map() => {
    for (final k in value.keys.map((k) => k.toString()).toList()..sort())
      k: _sortKeys(value[k]),
  },
  List() => value.map(_sortKeys).toList(),
  // 5 e 5.0 contam como iguais (o Firestore pode devolver qualquer um).
  num() when value == value.roundToDouble() => value.toInt(),
  _ => value,
};

SyncPlan planSync(DocMap current, DocMap desired) => SyncPlan(
  sets: {
    for (final e in desired.entries)
      if (!current.containsKey(e.key) ||
          _canonical(current[e.key]) != _canonical(e.value))
        e.key: e.value,
  },
  deletes: [
    for (final id in current.keys)
      if (!desired.containsKey(id)) id,
  ],
);

/// Escreve no Firestore só o que mudou. Recebe as funções de leitura e
/// escrita para poder ser testado sem Firebase.
class TeamSyncService {
  TeamSyncService({
    required this.loadListings,
    required this.loadSales,
    required this.apply,
  });

  final Future<DocMap> Function(TeamID teamId, UserID uid) loadListings;
  final Future<DocMap> Function(TeamID teamId, UserID uid) loadSales;
  final Future<void> Function(
    TeamID teamId, {
    required SyncPlan listings,
    required SyncPlan sales,
  })
  apply;

  String? _cacheKey;
  DocMap _listings = {};
  DocMap _sales = {};
  Future<void> _queue = Future.value();

  /// As alterações são aplicadas por ordem, uma de cada vez.
  Future<void> sync({
    required TeamID teamId,
    required TeamMember me,
    required List<Property> properties,
    required List<String> hidden,
    required num defaultAgentSplitPct,
  }) => _queue = _queue.then((_) async {
    try {
      final key = '$teamId/${me.uid}';
      if (_cacheKey != key) {
        _listings = await loadListings(teamId, me.uid);
        _sales = await loadSales(teamId, me.uid);
        _cacheKey = key;
      }
      final listings = desiredListings(
        uid: me.uid,
        agentName: me.name,
        properties: properties,
        hidden: hidden,
      );
      final sales = desiredSales(
        me: me,
        properties: properties,
        defaultAgentSplitPct: defaultAgentSplitPct,
      );
      final listingsPlan = planSync(_listings, listings);
      final salesPlan = planSync(_sales, sales);
      if (listingsPlan.isEmpty && salesPlan.isEmpty) return;
      await apply(teamId, listings: listingsPlan, sales: salesPlan);
      _listings = listings;
      _sales = sales;
    } catch (e) {
      // Sem ligação ou regras ainda por publicar: tenta outra vez na
      // próxima alteração, a partir do que está no Firestore.
      _cacheKey = null;
      debugPrint('Sincronização da equipa falhou: $e');
    }
  });
}

@Riverpod(keepAlive: true)
TeamSyncService teamSyncService(Ref ref) {
  final repo = ref.watch(teamRepositoryProvider);
  return TeamSyncService(
    loadListings: repo.loadOwnListings,
    loadSales: repo.loadOwnSales,
    apply: repo.applySync,
  );
}

/// Mantém a equipa a par dos imóveis do utilizador: sempre que um imóvel é
/// criado ou alterado, atualiza a cópia partilhada e os números de venda que
/// o padrinho vê. Fica ativo enquanto houver sessão iniciada (ver app.dart).
@riverpod
bool teamSync(Ref ref) {
  final uid = ref.watch(currentUidProvider);
  final membership = ref.watch(membershipStreamProvider).value;
  final teamId = membership?.teamId;
  if (teamId == null) return false;
  final me = ref
      .watch(teamMembersStreamProvider)
      .value
      ?.firstWhereOrNull((m) => m.uid == uid);
  final properties = ref.watch(propertiesStreamProvider).value;
  final settings = ref.watch(settingsStreamProvider).value;
  if (me == null || properties == null || settings == null) return false;
  ref.read(teamSyncServiceProvider).sync(
    teamId: teamId,
    me: me,
    properties: properties,
    hidden: membership!.hiddenListings,
    defaultAgentSplitPct: settings.agentSplitPct,
  );
  return true;
}
