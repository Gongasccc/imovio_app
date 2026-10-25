import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:imovio/src/features/contacts/data/contacts_repository.dart';
import 'package:imovio/src/features/contacts/domain/contact.dart';
import 'package:imovio/src/features/expenses/data/expenses_repository.dart';
import 'package:imovio/src/features/expenses/domain/expense.dart';
import 'package:imovio/src/features/pipeline/data/deals_repository.dart';
import 'package:imovio/src/features/pipeline/domain/deal.dart';
import 'package:imovio/src/features/properties/data/properties_repository.dart';
import 'package:imovio/src/features/properties/application/sale_summary.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
import 'package:imovio/src/features/settings/data/settings_repository.dart';
import 'package:imovio/src/features/settings/domain/user_settings.dart';
import 'package:imovio/src/features/tasks/data/tasks_repository.dart';
import 'package:imovio/src/features/tasks/domain/task.dart';

part 'dashboard_service.g.dart';

class DashboardKpis extends Equatable {
  const DashboardKpis({
    required this.contacts,
    required this.properties,
    required this.deals,
    required this.pendingTasks,
    required this.pipelineValue,
    required this.overdueTasks,
    required this.todayTasks,
    required this.upcomingTasks,
    required this.recentDeals,
    this.soldCount = 0,
    this.realizedProfit = 0,
    this.expectedShare = 0,
    this.expensesTotal = 0,
  });

  final int contacts;
  final int properties;
  final int deals;
  final int pendingTasks;
  final num pipelineValue;

  /// Lembretes: tarefas pendentes em atraso, de hoje e dos próximos 7 dias.
  final List<Task> overdueTasks;
  final List<Task> todayTasks;
  final List<Task> upcomingTasks;
  final List<Deal> recentDeals;

  /// Imóveis vendidos e o lucro real somado (a sua parte − despesas).
  final int soldCount;
  final num realizedProfit;

  /// A sua parte prevista nos imóveis ainda por vender (reservados e com CPCV).
  final num expectedShare;

  /// Total de despesas registadas em todos os imóveis.
  final num expensesTotal;

  @override
  List<Object?> get props => [
    contacts,
    properties,
    deals,
    pendingTasks,
    pipelineValue,
    overdueTasks,
    todayTasks,
    upcomingTasks,
    recentDeals,
    soldCount,
    realizedProfit,
    expectedShare,
    expensesTotal,
  ];
}

DashboardKpis computeKpis({
  required List<Contact> contacts,
  required List<Property> properties,
  required List<Deal> deals,
  required List<Task> tasks,
  required DateTime now,
  List<Expense> expenses = const [],
  num defaultAgentSplitPct = UserSettings.fallbackAgentSplitPct,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final nextWeek = today.add(const Duration(days: 8));
  final pending = tasks.where((t) => !t.isDone).toList();
  final byProperty = <String, List<Expense>>{};
  for (final e in expenses) {
    (byProperty[e.propertyId] ??= []).add(e);
  }
  SaleSummary summary(Property p) => computeSaleSummary(
    p,
    byProperty[p.id] ?? const [],
    defaultAgentSplitPct: defaultAgentSplitPct,
  );
  final sold = properties.where((p) => p.isSold).toList();
  final closing = properties.where(
    (p) => p.saleStatus == 'Reservado' || p.saleStatus == 'CPCV Assinado',
  );
  return DashboardKpis(
    contacts: contacts.length,
    properties: properties.length,
    deals: deals.length,
    pendingTasks: pending.length,
    pipelineValue: deals.fold<num>(0, (sum, d) => sum + (d.value ?? 0)),
    overdueTasks: pending
        .where((t) => t.date != null && t.date!.isBefore(today))
        .toList(),
    todayTasks: pending
        .where(
          (t) =>
              t.date != null &&
              !t.date!.isBefore(today) &&
              t.date!.isBefore(tomorrow),
        )
        .toList(),
    upcomingTasks: pending
        .where(
          (t) =>
              t.date != null &&
              !t.date!.isBefore(tomorrow) &&
              t.date!.isBefore(nextWeek),
        )
        .toList(),
    recentDeals: deals.take(6).toList(),
    soldCount: sold.length,
    realizedProfit: sold.fold<num>(0, (s, p) => s + summary(p).profit),
    expectedShare: closing.fold<num>(0, (s, p) => s + summary(p).agentShare),
    expensesTotal: expenses.fold<num>(0, (s, e) => s + e.amount),
  );
}

@riverpod
AsyncValue<DashboardKpis> dashboardKpis(Ref ref) {
  final contacts = ref.watch(contactsStreamProvider);
  final properties = ref.watch(propertiesStreamProvider);
  final deals = ref.watch(dealsStreamProvider);
  final tasks = ref.watch(tasksStreamProvider);
  final expenses = ref.watch(expensesStreamProvider).value ?? const [];
  final settings =
      ref.watch(settingsStreamProvider).value ?? const UserSettings();
  for (final v in [contacts, properties, deals, tasks]) {
    if (v.hasError) return AsyncError(v.error!, v.stackTrace!);
  }
  if (!contacts.hasValue ||
      !properties.hasValue ||
      !deals.hasValue ||
      !tasks.hasValue) {
    return const AsyncLoading();
  }
  return AsyncData(
    computeKpis(
      contacts: contacts.requireValue,
      properties: properties.requireValue,
      deals: deals.requireValue,
      tasks: tasks.requireValue,
      now: DateTime.now(),
      expenses: expenses,
      defaultAgentSplitPct: settings.agentSplitPct,
    ),
  );
}
