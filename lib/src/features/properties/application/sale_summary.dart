import 'package:equatable/equatable.dart';
import 'package:imovio/src/features/expenses/domain/expense.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
import 'package:imovio/src/utils/format.dart';

/// Contas de um imóvel vendido (ou a previsão, se ainda não foi):
///
///   comissão da agência  = valor de venda × comissão %
///   a sua parte          = comissão da agência × a sua %
///   lucro real           = a sua parte − despesas do imóvel
class SaleSummary extends Equatable {
  const SaleSummary({
    required this.listedPrice,
    required this.salePrice,
    required this.commissionPct,
    required this.agencyCommission,
    required this.agentSplitPct,
    required this.agentShare,
    required this.expensesTotal,
    required this.expensesCount,
    required this.profit,
    required this.isSold,
    this.daysOnMarket,
  });

  final num? listedPrice;
  final num? salePrice;
  final num? commissionPct;
  final num agencyCommission;
  final num agentSplitPct;
  final num agentShare;
  final num expensesTotal;
  final int expensesCount;
  final num profit;
  final bool isSold;
  final int? daysOnMarket;

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
    agencyCommission,
    agentSplitPct,
    agentShare,
    expensesTotal,
    expensesCount,
    profit,
    isSold,
    daysOnMarket,
  ];
}

num _round2(num v) => (v * 100).round() / 100;

SaleSummary computeSaleSummary(
  Property property,
  List<Expense> expenses, {
  required num defaultAgentSplitPct,
}) {
  final sale = property.salePrice ?? property.price;
  final pct = property.commissionPct;
  final agency = (sale != null && pct != null)
      ? sale * pct / 100
      : (property.commissionVal ?? 0);
  final split = property.agentSplitPct ?? defaultAgentSplitPct;
  final share = agency * split / 100;
  final spent = expenses.fold<num>(0, (sum, e) => sum + e.amount);
  final start = parseDate(property.dateStart);
  final end = parseDate(property.dateEnd);
  return SaleSummary(
    listedPrice: property.price,
    salePrice: sale,
    commissionPct: pct,
    agencyCommission: _round2(agency),
    agentSplitPct: split,
    agentShare: _round2(share),
    expensesTotal: _round2(spent),
    expensesCount: expenses.length,
    profit: _round2(share - spent),
    isSold: property.isSold,
    daysOnMarket: start != null && end != null
        ? end.difference(start).inDays
        : null,
  );
}
