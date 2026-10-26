import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imovio/src/features/contacts/data/contacts_repository.dart';
import 'package:imovio/src/features/properties/data/properties_repository.dart';
import 'package:imovio/src/features/tasks/application/calendar_export.dart';
import 'package:imovio/src/features/tasks/domain/task.dart';
import 'package:imovio/src/utils/dialogs.dart';
import 'package:imovio/src/utils/file_saver.dart';

/// Descarrega um .ics com as tarefas pendentes com data. Ao abrir o
/// ficheiro, o telemóvel junta-as ao calendário dele, com aviso 30 minutos
/// antes. Assim os lembretes funcionam mesmo com a app fechada.
void exportTasksToCalendar(
  BuildContext context,
  WidgetRef ref,
  List<Task> tasks,
) {
  final upcoming = tasks
      .where((t) => !t.isDone && t.date != null && t.date!.isAfter(DateTime.now()))
      .toList();
  if (upcoming.isEmpty) {
    showSnack(context, 'Não há tarefas futuras com data e hora.');
    return;
  }
  final ics = tasksToIcs(
    upcoming,
    contacts: ref.read(contactsByIdProvider),
    properties: ref.read(propertiesByIdProvider),
  );
  final saved = saveTextFile(
    fileName: upcoming.length == 1 ? 'tarefa.ics' : 'tarefas-imovio.ics',
    content: ics,
    mimeType: 'text/calendar;charset=utf-8',
    withBom: false,
  );
  if (!saved) {
    Clipboard.setData(ClipboardData(text: ics));
  }
  showSnack(
    context,
    saved
        ? '${upcoming.length} tarefa(s) no ficheiro. Abra-o para as juntar ao '
            'calendário do telemóvel (com aviso 30 min antes).'
        : 'Calendário copiado para a área de transferência.',
  );
}
