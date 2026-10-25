import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:imovio/src/common_widgets/status_badge.dart';
import 'package:imovio/src/constants/app_theme.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/contacts/data/contacts_repository.dart';
import 'package:imovio/src/features/properties/data/properties_repository.dart';
import 'package:imovio/src/features/tasks/data/tasks_repository.dart';
import 'package:imovio/src/features/tasks/domain/task.dart';
import 'package:imovio/src/routing/app_router.dart';
import 'package:imovio/src/utils/format.dart';
import 'package:imovio/src/utils/run_action.dart';

/// Uma tarefa com caixa de concluída, categoria, cliente, imóvel e prazo.
class TaskTile extends ConsumerWidget {
  const TaskTile({super.key, required this.task, this.showDelete = false});
  final Task task;
  final bool showDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contact = ref.watch(contactsByIdProvider)[task.contactId];
    final property = ref.watch(propertiesByIdProvider)[task.propertyId];
    final uid = ref.watch(currentUidProvider);
    final repo = ref.watch(tasksRepositoryProvider);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final overdue = task.isOverdue(DateTime.now());
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => context.pushNamed(
        AppRoute.task.name,
        pathParameters: {'id': task.id},
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: task.isDone,
              onChanged: (v) => runAction(
                context,
                () => repo.setDone(uid: uid, id: task.id, done: v ?? false),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        decoration:
                            task.isDone ? TextDecoration.lineThrough : null,
                        color: task.isDone ? muted : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      StatusBadge(
                        label: task.status,
                        color: task.isDone ? AppColors.green : AppColors.gold,
                      ),
                      StatusBadge(label: task.category, color: muted),
                      if (contact != null)
                        Text('👤 ${contact.name}',
                            style: TextStyle(fontSize: 12, color: muted)),
                      if (property != null)
                        Text('🏠 ${property.title}',
                            style: TextStyle(fontSize: 12, color: muted)),
                      if (task.date != null)
                        Text(
                          Format.dateTime(task.date),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: overdue ? AppColors.red : muted,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (showDelete)
              IconButton(
                tooltip: 'Eliminar',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => confirmAndDelete(
                  context,
                  () => repo.deleteTask(uid: uid, id: task.id),
                  success: 'Tarefa eliminada',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
