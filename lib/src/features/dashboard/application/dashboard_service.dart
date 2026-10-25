import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:imovio/src/features/contacts/data/contacts_repository.dart';
import 'package:imovio/src/features/contacts/domain/contact.dart';
import 'package:imovio/src/features/pipeline/data/deals_repository.dart';
import 'package:imovio/src/features/pipeline/domain/deal.dart';
import 'package:imovio/src/features/properties/data/properties_repository.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
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
      ];
}

DashboardKpis computeKpis({
  required List<Contact> contacts,
  required List<Property> properties,
  required List<Deal> deals,
  required List<Task> tasks,
  required DateTime now,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final nextWeek = today.add(const Duration(days: 8));
  final pending = tasks.where((t) => !t.isDone).toList();
  return DashboardKpis(
    contacts: contacts.length,
    properties: properties.length,
    deals: deals.length,
    pendingTasks: pending.length,
    pipelineValue: deals.fold<num>(0, (sum, d) => sum + (d.value ?? 0)),
    overdueTasks:
        pending.where((t) => t.date != null && t.date!.isBefore(today)).toList(),
    todayTasks: pending
        .where((t) =>
            t.date != null &&
            !t.date!.isBefore(today) &&
            t.date!.isBefore(tomorrow))
        .toList(),
    upcomingTasks: pending
        .where((t) =>
            t.date != null &&
            !t.date!.isBefore(tomorrow) &&
            t.date!.isBefore(nextWeek))
        .toList(),
    recentDeals: deals.take(6).toList(),
  );
}

@riverpod
AsyncValue<DashboardKpis> dashboardKpis(Ref ref) {
  final contacts = ref.watch(contactsStreamProvider);
  final properties = ref.watch(propertiesStreamProvider);
  final deals = ref.watch(dealsStreamProvider);
  final tasks = ref.watch(tasksStreamProvider);
  for (final v in [contacts, properties, deals, tasks]) {
    if (v.hasError) return AsyncError(v.error!, v.stackTrace!);
  }
  if (!contacts.hasValue ||
      !properties.hasValue ||
      !deals.hasValue ||
      !tasks.hasValue) {
    return const AsyncLoading();
  }
  return AsyncData(computeKpis(
    contacts: contacts.requireValue,
    properties: properties.requireValue,
    deals: deals.requireValue,
    tasks: tasks.requireValue,
    now: DateTime.now(),
  ));
}
