import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:imovio/src/common_widgets/async_value_widget.dart';
import 'package:imovio/src/common_widgets/date_time_field.dart';
import 'package:imovio/src/common_widgets/empty_placeholder.dart';
import 'package:imovio/src/common_widgets/form_fields.dart';
import 'package:imovio/src/common_widgets/record_pickers.dart';
import 'package:imovio/src/common_widgets/responsive_center.dart';
import 'package:imovio/src/constants/app_sizes.dart';
import 'package:imovio/src/features/tasks/data/tasks_repository.dart';
import 'package:imovio/src/features/tasks/domain/task.dart';
import 'package:imovio/src/features/tasks/presentation/task_edit_controller.dart';
import 'package:imovio/src/utils/async_value_ui.dart';
import 'package:imovio/src/utils/dialogs.dart';
import 'package:imovio/src/utils/format.dart';

/// Valores para pré-preencher uma tarefa nova (ex.: "Agendar visita" a partir
/// de um imóvel).
class TaskDraft {
  const TaskDraft({this.contactId, this.propertyId, this.category, this.date});
  final String? contactId;
  final String? propertyId;
  final String? category;
  final DateTime? date;

  factory TaskDraft.fromQuery(Map<String, String> q) => TaskDraft(
        contactId: q['contactId'],
        propertyId: q['propertyId'],
        category: q['category'],
        date: parseDate(q['date']),
      );
}

class TaskEditScreen extends ConsumerWidget {
  const TaskEditScreen({super.key, this.taskId, this.draft = const TaskDraft()});
  final TaskID? taskId;
  final TaskDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (taskId == null) return _TaskForm(task: null, draft: draft);
    return AsyncValueWidget<List<Task>>(
      value: ref.watch(tasksStreamProvider),
      data: (tasks) {
        final task = tasks.where((t) => t.id == taskId).firstOrNull;
        if (task == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyPlaceholder(
              icon: Icons.task_alt,
              message: 'Esta tarefa já não existe.',
            ),
          );
        }
        return _TaskForm(key: ValueKey(task.id), task: task, draft: draft);
      },
    );
  }
}

class _TaskForm extends ConsumerStatefulWidget {
  const _TaskForm({super.key, required this.task, required this.draft});
  final Task? task;
  final TaskDraft draft;

  @override
  ConsumerState<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends ConsumerState<_TaskForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.task?.title);
  late final _notes = TextEditingController(text: widget.task?.notes);
  late String _category = widget.task?.category ??
      widget.draft.category ??
      TaskCategories.all.first;
  late String _status = widget.task?.status ?? TaskStatuses.pending;
  late String? _contactId = widget.task?.contactId ?? widget.draft.contactId;
  late String? _propertyId = widget.task?.propertyId ?? widget.draft.propertyId;
  late DateTime? _date = widget.task?.date ?? widget.draft.date;

  bool get _isNew => widget.task == null;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final task = Task(
      id: widget.task?.id ?? '',
      title: _title.text.trim(),
      category: _category,
      contactId: _contactId,
      propertyId: _propertyId,
      date: _date,
      status: _status,
      notes: emptyToNull(_notes.text),
      createdAt: widget.task?.createdAt,
    );
    final ok = await ref
        .read(taskEditControllerProvider.notifier)
        .submit(task, isNew: _isNew);
    if (ok && mounted) {
      showSnack(context, _isNew ? 'Tarefa criada' : 'Tarefa atualizada');
      context.pop();
    }
  }

  Future<void> _delete() async {
    if (!await showConfirmDialog(context) || !mounted) return;
    final ok = await ref
        .read(taskEditControllerProvider.notifier)
        .delete(widget.task!.id);
    if (ok && mounted) {
      showSnack(context, 'Tarefa eliminada');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(taskEditControllerProvider,
        (_, s) => s.showSnackBarOnError(context));
    final saving = ref.watch(taskEditControllerProvider).isLoading;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Nova Tarefa' : 'Editar Tarefa'),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline),
              onPressed: saving ? null : _delete,
            ),
          gapW8,
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            ResponsiveCenter(
              maxContentWidth: 720,
              padding: const EdgeInsets.all(Sizes.p16),
              child: FormGrid(children: [
                FullWidth(
                  child: TextFormField(
                    controller: _title,
                    decoration: const InputDecoration(
                      labelText: 'Título / Descrição da Tarefa',
                      hintText: 'ex: Escritura – previsão até 5 meses após...',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Indique o título'
                        : null,
                  ),
                ),
                TextDropdown(
                  label: 'Categoria',
                  value: _category,
                  options: TaskCategories.all,
                  onChanged: (v) => setState(() => _category = v ?? _category),
                ),
                TextDropdown(
                  label: 'Estado',
                  value: _status,
                  options: TaskStatuses.all,
                  onChanged: (v) => setState(() => _status = v ?? _status),
                ),
                ContactPicker(
                  label: 'Cliente Associado',
                  value: _contactId,
                  onChanged: (v) => setState(() => _contactId = v),
                ),
                PropertyPicker(
                  label: 'Imóvel Associado',
                  value: _propertyId,
                  onChanged: (v) => setState(() => _propertyId = v),
                ),
                FullWidth(
                  child: DateTimeField(
                    label: 'Data e Hora Prazo',
                    value: _date,
                    onChanged: (v) => setState(() => _date = v),
                  ),
                ),
                FullWidth(
                  child: TextFormField(
                    controller: _notes,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Notas'),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Sizes.p12),
          child: FilledButton(
            onPressed: saving ? null : _save,
            child: Text(_isNew ? 'Criar Tarefa' : 'Guardar alterações'),
          ),
        ),
      ),
    );
  }
}
