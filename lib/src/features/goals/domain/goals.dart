import 'package:equatable/equatable.dart';
import 'package:imovio/src/features/expenses/domain/expense.dart';
import 'package:imovio/src/features/pipeline/domain/deal.dart';
import 'package:imovio/src/features/properties/application/sale_summary.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
import 'package:imovio/src/features/tasks/domain/task.dart';
import 'package:imovio/src/utils/format.dart';

/// Metas mensais, em `users/{uid}/settings/goals`.
class MonthlyGoals extends Equatable {
  const MonthlyGoals({
    this.listings,
    this.visits,
    this.proposals,
    this.sales,
    this.profit,
  });

  final int? listings;
  final int? visits;
  final int? proposals;
  final int? sales;
  final num? profit;

  bool get isEmpty =>
      [listings, visits, proposals, sales, profit].every((v) => v == null);

  factory MonthlyGoals.fromMap(Map<String, dynamic>? m) => MonthlyGoals(
        listings: parseInt(m?['angariacoes']),
        visits: parseInt(m?['visitas']),
        proposals: parseInt(m?['propostas']),
        sales: parseInt(m?['vendas']),
        profit: parseNum(m?['lucro']),
      );

  Map<String, dynamic> toMap() => {
        'angariacoes': listings,
        'visitas': visits,
        'propostas': proposals,
        'vendas': sales,
        'lucro': profit,
      };

  @override
  List<Object?> get props => [listings, visits, proposals, sales, profit];
}

/// O que foi feito num mês.
class MonthResults extends Equatable {
  const MonthResults({
    required this.month,
    required this.listings,
    required this.visits,
    required this.proposals,
    required this.sales,
    required this.profit,
  });

  /// Primeiro dia do mês.
  final DateTime month;
  final int listings;
  final int visits;
  final int proposals;
  final int sales;
  final num profit;

  @override
  List<Object?> get props =>
      [month, listings, visits, proposals, sales, profit];
}

bool _inMonth(DateTime? d, DateTime month) =>
    d != null && d.year == month.year && d.month == month.month;

DateTime? _millis(int? ms) =>
    ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);

/// Conta, para o mês de [month]:
/// - angariações: imóveis com data de angariação (ou criados) no mês;
/// - visitas: tarefas de visita concluídas com data no mês;
/// - propostas: negócios criados no mês;
/// - vendas e lucro real: imóveis vendidos com data de fecho no mês.
MonthResults resultsFor(
  DateTime month, {
  required List<Property> properties,
  required List<Task> tasks,
  required List<Deal> deals,
  required List<Expense> expenses,
  num defaultAgentSplitPct = 50,
}) {
  final m = DateTime(month.year, month.month);
  final sold = properties.where(
    (p) => p.isSold && _inMonth(parseDate(p.dateEnd), m),
  );
  num profit = 0;
  for (final p in sold) {
    profit += computeSaleSummary(
      p,
      expenses.where((e) => e.propertyId == p.id).toList(),
      defaultAgentSplitPct: defaultAgentSplitPct,
    ).profit;
  }
  return MonthResults(
    month: m,
    listings: properties
        .where((p) =>
            _inMonth(parseDate(p.dateStart) ?? _millis(p.createdAt), m))
        .length,
    visits: tasks
        .where((t) =>
            t.category == TaskCategories.visit && t.isDone && _inMonth(t.date, m))
        .length,
    proposals: deals.where((d) => _inMonth(_millis(d.createdAt), m)).length,
    sales: sold.length,
    profit: profit,
  );
}

/// Os últimos [count] meses, do mais antigo para o atual.
List<MonthResults> lastMonths(
  DateTime now, {
  int count = 6,
  required List<Property> properties,
  required List<Task> tasks,
  required List<Deal> deals,
  required List<Expense> expenses,
}) =>
    [
      for (var i = count - 1; i >= 0; i--)
        resultsFor(
          DateTime(now.year, now.month - i),
          properties: properties,
          tasks: tasks,
          deals: deals,
          expenses: expenses,
        ),
    ];
