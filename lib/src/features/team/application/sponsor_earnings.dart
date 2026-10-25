import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/authentication/domain/app_user.dart';
import 'package:imovio/src/features/team/data/team_repository.dart';
import 'package:imovio/src/features/team/domain/afilhado_sale.dart';

part 'sponsor_earnings.g.dart';

num _round2(num v) => (v * 100).round() / 100;

/// Estados em que a venda já está encaminhada mas ainda não escriturada.
const _forecastStatuses = {'Reservado', 'CPCV Assinado'};

/// O que o padrinho ganha com um imóvel de um afilhado:
/// parte do afilhado × % do padrinho.
num sponsorCut(AfilhadoSale sale, num? pct) =>
    pct == null || pct <= 0 ? 0 : _round2(sale.agentShare * pct / 100);

/// Ganhos do padrinho com um afilhado, separados por fase da venda.
class AfilhadoEarnings extends Equatable {
  const AfilhadoEarnings({
    required this.afilhadoUid,
    required this.afilhadoName,
    required this.pct,
    required this.sales,
    required this.realized,
    required this.forecast,
    required this.portfolio,
  });

  final UserID afilhadoUid;
  final String afilhadoName;

  /// A % do padrinho sobre a parte do afilhado. Nula até ser definida.
  final num? pct;
  final List<AfilhadoSale> sales;

  /// Imóveis vendidos.
  final num realized;

  /// Reservados e com CPCV assinado.
  final num forecast;

  /// Em angariação: o que renderia se todos se vendessem ao preço atual.
  final num portfolio;

  @override
  List<Object?> get props => [
    afilhadoUid,
    afilhadoName,
    pct,
    sales,
    realized,
    forecast,
    portfolio,
  ];
}

class SponsorEarnings extends Equatable {
  const SponsorEarnings(this.afilhados);
  final List<AfilhadoEarnings> afilhados;

  num get realized => _round2(afilhados.fold(0, (s, a) => s + a.realized));
  num get forecast => _round2(afilhados.fold(0, (s, a) => s + a.forecast));
  num get portfolio => _round2(afilhados.fold(0, (s, a) => s + a.portfolio));

  @override
  List<Object?> get props => [afilhados];
}

/// Junta as vendas por afilhado e aplica a % definida para cada um.
/// [afilhados] (uid → nome) garante que aparecem também os que ainda não
/// têm imóveis.
SponsorEarnings computeSponsorEarnings({
  required Map<UserID, String> afilhados,
  required List<AfilhadoSale> sales,
  required Map<UserID, num> pcts,
}) {
  final byUid = <UserID, List<AfilhadoSale>>{
    for (final uid in afilhados.keys) uid: [],
  };
  for (final s in sales) {
    byUid.putIfAbsent(s.afilhadoUid, () => []).add(s);
  }
  final result = byUid.entries.map((e) {
    final pct = pcts[e.key];
    num realized = 0, forecast = 0, portfolio = 0;
    for (final s in e.value) {
      final cut = sponsorCut(s, pct);
      if (s.isSold) {
        realized += cut;
      } else if (_forecastStatuses.contains(s.saleStatus)) {
        forecast += cut;
      } else {
        portfolio += cut;
      }
    }
    final name = afilhados[e.key] ??
        (e.value.isNotEmpty ? e.value.first.afilhadoName : 'Sem nome');
    return AfilhadoEarnings(
      afilhadoUid: e.key,
      afilhadoName: name,
      pct: pct,
      sales: e.value,
      realized: _round2(realized),
      forecast: _round2(forecast),
      portfolio: _round2(portfolio),
    );
  }).toList()
    ..sort((a, b) => a.afilhadoName.compareTo(b.afilhadoName));
  return SponsorEarnings(result);
}

/// Ganhos do utilizador com os afilhados que o indicaram como padrinho.
@riverpod
SponsorEarnings? sponsorEarnings(Ref ref) {
  final uid = ref.watch(currentUidProvider);
  final members = ref.watch(teamMembersStreamProvider).value;
  final sales = ref.watch(sponsorSalesStreamProvider).value;
  final pcts = ref.watch(afilhadoPctsStreamProvider).value;
  if (members == null || sales == null || pcts == null) return null;
  final afilhados = {
    for (final m in members)
      if (m.sponsorUid == uid) m.uid: m.name,
  };
  // Só conta quem continua a indicar este padrinho.
  return computeSponsorEarnings(
    afilhados: afilhados,
    sales: sales.where((s) => afilhados.containsKey(s.afilhadoUid)).toList(),
    pcts: pcts,
  );
}
