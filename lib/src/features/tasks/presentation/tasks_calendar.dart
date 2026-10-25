import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:imovio/src/constants/app_sizes.dart';
import 'package:imovio/src/features/tasks/domain/task.dart';
import 'package:imovio/src/features/tasks/presentation/task_tile.dart';
import 'package:imovio/src/routing/app_router.dart';
import 'package:imovio/src/utils/format.dart';
import 'package:table_calendar/table_calendar.dart';

/// Calendário mensal de tarefas e visitas, com a lista do dia escolhido.
class TasksCalendar extends StatefulWidget {
  const TasksCalendar({super.key, required this.tasks});
  final List<Task> tasks;

  @override
  State<TasksCalendar> createState() => _TasksCalendarState();
}

class _TasksCalendarState extends State<TasksCalendar> {
  var _focused = DateTime.now();
  var _selected = DateTime.now();

  List<Task> _tasksOn(DateTime day) =>
      widget.tasks.where((t) => t.isOn(day)).toList();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dayTasks = _tasksOn(_selected);
    return LayoutBuilder(builder: (context, constraints) {
      final calendar = Card(
        child: Padding(
          padding: const EdgeInsets.all(Sizes.p8),
          child: TableCalendar<Task>(
            locale: 'pt_PT',
            firstDay: DateTime(2020),
            lastDay: DateTime(2100),
            focusedDay: _focused,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableCalendarFormats: const {CalendarFormat.month: 'Mês'},
            selectedDayPredicate: (d) => isSameDay(d, _selected),
            eventLoader: _tasksOn,
            onDaySelected: (selected, focused) => setState(() {
              _selected = selected;
              _focused = focused;
            }),
            onPageChanged: (f) => _focused = f,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: TextStyle(color: scheme.onPrimary),
              markerDecoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      );
      final list = Card(
        child: Padding(
          padding: const EdgeInsets.all(Sizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      Format.date(_selected),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Tarefa neste dia'),
                    onPressed: () => context.pushNamed(
                      AppRoute.newTask.name,
                      queryParameters: {
                        'date': formatIsoDateTime(DateTime(
                            _selected.year, _selected.month, _selected.day, 10)),
                      },
                    ),
                  ),
                ],
              ),
              if (dayTasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: Sizes.p16),
                  child: Text('Sem tarefas neste dia.'),
                )
              else
                for (final t in dayTasks) TaskTile(task: t, showDelete: true),
            ],
          ),
        ),
      );
      if (constraints.maxWidth >= wideBreakpoint) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: calendar),
            gapW16,
            Expanded(child: list),
          ],
        );
      }
      return Column(children: [calendar, gapH16, list]);
    });
  }
}
