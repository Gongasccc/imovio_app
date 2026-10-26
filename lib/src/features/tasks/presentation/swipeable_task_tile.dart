import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imovio/src/constants/app_theme.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/tasks/data/tasks_repository.dart';
import 'package:imovio/src/features/tasks/domain/task.dart';
import 'package:imovio/src/features/tasks/presentation/task_tile.dart';
import 'package:imovio/src/utils/dialogs.dart';
import 'package:imovio/src/utils/run_action.dart';

/// Tarefa com gestos de telemóvel: deslizar para a direita conclui (ou
/// reabre), deslizar para a esquerda apaga.
class SwipeableTaskTile extends ConsumerWidget {
  const SwipeableTaskTile({super.key, required this.task});
  final Task task;

  Widget _background(
    BuildContext context, {
    required Color color,
    required IconData icon,
    required String label,
    required Alignment alignment,
  }) =>
      Container(
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey('task-${task.id}-${task.status}'),
      background: _background(
        context,
        color: AppColors.green,
        icon: task.isDone ? Icons.undo : Icons.check,
        label: task.isDone ? 'Reabrir' : 'Concluir',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _background(
        context,
        color: AppColors.red,
        icon: Icons.delete_outline,
        label: 'Apagar',
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        final uid = ref.read(currentUidProvider);
        final repo = ref.read(tasksRepositoryProvider);
        HapticFeedback.mediumImpact();
        if (direction == DismissDirection.startToEnd) {
          await runAction(
            context,
            () => repo.setDone(uid: uid, id: task.id, done: !task.isDone),
            success: task.isDone ? 'Tarefa reaberta' : 'Tarefa concluída',
          );
          // A linha fica; muda só o estado.
          return false;
        }
        final ok = await showConfirmDialog(context,
            message: 'Apagar a tarefa "${task.title}"?');
        if (ok && context.mounted) {
          await runAction(
            context,
            () => repo.deleteTask(uid: uid, id: task.id),
            success: 'Tarefa eliminada',
          );
        }
        return ok;
      },
      child: TaskTile(task: task, showDelete: true),
    );
  }
}
