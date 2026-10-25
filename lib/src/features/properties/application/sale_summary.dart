import 'package:equatable/equatable.dart';
import 'package:imovio/src/features/expenses/domain/expense.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
import 'package:imovio/src/utils/format.dart';

/// Contas de um imóvel vendido (ou a previsão, se ainda não foi):
///
///   comissão total       = valor de venda × comissão %
///   comissão da agência  = comissão total × (partilha ? % da partilha : 100 %)
///   IVA                  = comissão da agência × IVA % (pago pelo cliente,
///                          entregue ao Estado; não entra no lucro)
///   a sua parte          = comissão da agência (sem IVA) × a sua %
///   lucro real           = a sua parte − despesas do imóvel
class SaleSummary extends Equatable {
  const SaleSummary({
    required this.listedPrice,
    required this.salePrice,
    required this.commissionPct,
    required this.totalCommission,
    required this.isShared,
    required this.sharePct,
    required this.agencyCommission,
    required this.vatPct,
    required this.vat,
    required this.agentSplitPct,
    required this.agentShare,
    required this.expensesTotal,
    required this.expensesCount,
    required this.profit,
    required this.isSold,
    this.contractType,
    this.daysOnMarket,
  });

  final num? listedPrice;
  final num? salePrice;
  final num? commissionPct;

  /// Comissão sobre o valor de venda, antes da partilha.
  final num totalCommission;
  final bool isShared;
  final num sharePct;

  /// A comissão que fica para a nossa agência (sem IVA).
  final num agencyCommission;
  final num vatPct;
  final num vat;
  final num agentSplitPct;
  final num agentShare;
  final num expensesTotal;
  final int expensesCount;
  final num profit;
  final bool isSold;
  final String? contractType;
  final int? daysOnMarket;

  num get agencyCommissionWithVat => agencyCommission + vat;

  /// Diferença entre o anunciado e o vendido (positivo = desconto).
  num? get discount => listedPrice == null || salePrice == null
      ? null
      : listedPrice! - salePrice!;

  num? get discountPct =>
      discount == null || listedPrice == 0 ? null : discount! / listedPrice!;

  /// Lucro real em % do valor de venda.
  num? get profitOnSalePct =>
      salePrice == null || salePrice == 0 ? null : profit / salePrice!;

  @override
  List<Object?> get props => [
    listedPrice,
    salePrice,
    commissionPct,
    totalCommission,
    isShared,
    sharePct,
    agencyCommission,
    vatPct,
    vat,
    agentSplitPct,
    agentShare,
    expensesTotal,
    expensesCount,
    profit,
    isSold,
    contractType,
    daysOnMarket,
  ];
}

num _round2(num v) => (v * 100).round() / 100;

/// [defaultAgentSplitPct] só se usa em imóveis que ainda não têm a sua %.
SaleSummary computeSaleSummary(
  Property property,
  List<Expense> expenses, {
  num defaultAgentSplitPct = 50,
}) {
  final sale = property.salePrice ?? property.price;
  final pct = property.commissionPct;
  final total = (sale != null && pct != null)
      ? sale * pct / 100
      : (property.commissionVal ?? 0);
  final sharePct = property.isShared
      ? (property.sharePct ?? PropertyOptions.defaultSharePct)
      : 100;
  final agency = total * sharePct / 100;
  final vatPct = property.vatPct ?? PropertyOptions.defaultVatPct;
  final split = property.agentSplitPct ?? defaultAgentSplitPct;
  final share = agency * split / 100;
  final spent = expenses.fold<num>(0, (sum, e) => sum + e.amount);
  final start = parseDate(property.dateStart);
  final end = parseDate(property.dateEnd);
  return SaleSummary(
    listedPrice: property.price,
    salePrice: sale,
    commissionPct: pct,
    totalCommission: _round2(total),
    isShared: property.isShared,
    sharePct: sharePct,
    agencyCommission: _round2(agency),
    vatPct: vatPct,
    vat: _round2(agency * vatPct / 100),
    agentSplitPct: split,
    agentShare: _round2(share),
    expensesTotal: _round2(spent),
    expensesCount: expenses.length,
    profit: _round2(share - spent),
    isSold: property.isSold,
    contractType: property.contractType,
    daysOnMarket: start != null && end != null
        ? end.difference(start).inDays
        : null,
  );
}
