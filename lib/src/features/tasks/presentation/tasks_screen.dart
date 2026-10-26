import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:imovio/src/features/tasks/presentation/swipeable_task_tile.dart';
import 'package:imovio/src/common_widgets/adaptive_fab.dart';
import 'package:imovio/src/features/tasks/presentation/calendar_export_button.dart';
import 'package:imovio/src/common_widgets/async_value_widget.dart';
import 'package:imovio/src/common_widgets/empty_placeholder.dart';
import 'package:imovio/src/common_widgets/page_header.dart';
import 'package:imovio/src/common_widgets/responsive_center.dart';
import 'package:imovio/src/constants/app_sizes.dart';
import 'package:imovio/src/features/settings/data/local_preferences.dart';
import 'package:imovio/src/features/tasks/data/tasks_repository.dart';
import 'package:imovio/src/features/tasks/domain/task.dart';
import 'package:imovio/src/features/tasks/presentation/tasks_calendar.dart';
import 'package:imovio/src/routing/app_router.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String? _status;
  String? _category;
  late var _calendar = ref.read(localPreferencesProvider).tasksCalendarView;

  @override
  Widget build(BuildContext context) {
    final tasksValue = ref.watch(tasksStreamProvider);
    return Scaffold(
      floatingActionButton: AdaptiveFab(
        onPressed: () => context.pushNamed(AppRoute.newTask.name),
        icon: Icons.add_task,
        label: 'Nova tarefa',
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          ResponsiveCenter(
            padding: const EdgeInsets.all(Sizes.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  title: 'Tarefas',
                  subtitle: 'Follow-ups, visitas e tarefas com prazo.',
                  actions: [
                    IconButton.outlined(
                      tooltip: 'Pôr as tarefas no calendário do telemóvel',
                      icon: const Icon(Icons.event_available_outlined),
                      onPressed: () => exportTasksToCalendar(
                        context,
                        ref,
                        ref.read(tasksStreamProvider).value ?? const [],
                      ),
                    ),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                            value: false,
                            icon: Icon(Icons.list),
                            label: Text('Lista')),
                        ButtonSegment(
                            value: true,
                            icon: Icon(Icons.calendar_month),
                            label: Text('Calendário')),
                      ],
                      selected: {_calendar},
                      onSelectionChanged: (s) {
                        setState(() => _calendar = s.first);
                        ref
                            .read(localPreferencesProvider)
                            .setTasksCalendarView(s.first);
                      },
                    ),
                  ],
                ),
                gapH16,
                if (!_calendar)
                  Wrap(
                    spacing: Sizes.p8,
                    runSpacing: Sizes.p8,
                    children: [
                      for (final s in [null, ...TaskStatuses.all])
                        ChoiceChip(
                          label: Text(s ?? 'Todos'),
                          selected: _status == s,
                          onSelected: (_) => setState(() => _status = s),
                        ),
                      const SizedBox(width: Sizes.p16),
                      DropdownMenu<String?>(
                        initialSelection: _category,
                        label: const Text('Categoria'),
                        width: 240,
                        dropdownMenuEntries: [
                          const DropdownMenuEntry(value: null, label: 'Todas'),
                          for (final c in TaskCategories.all)
                            DropdownMenuEntry(value: c, label: c),
                        ],
                        onSelected: (v) => setState(() => _category = v),
                      ),
                    ],
                  ),
                gapH16,
                AsyncValueWidget<List<Task>>(
                  value: tasksValue,
                  data: (tasks) {
                    if (_calendar) return TasksCalendar(tasks: tasks);
                    final filtered = tasks
                        .where((t) =>
                            (_status == null || t.status == _status) &&
                            (_category == null || t.category == _category))
                        .toList();
                    if (filtered.isEmpty) {
                      return const EmptyPlaceholder(
                        icon: Icons.task_alt,
                        message: 'Sem tarefas pendentes.',
                      );
                    }
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: Sizes.p8, vertical: Sizes.p4),
                        child: Column(
                          children: [
                            for (final (i, t) in filtered.indexed) ...[
                              if (i > 0) const Divider(),
                              SwipeableTaskTile(task: t),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
