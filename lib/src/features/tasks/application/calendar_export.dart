import 'package:imovio/src/features/contacts/domain/contact.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
import 'package:imovio/src/features/tasks/domain/task.dart';

/// Ficheiro de calendário (.ics) com as tarefas: ao abri-lo, o telemóvel
/// junta-as ao calendário dele, com um aviso antes de cada uma.
String tasksToIcs(
  List<Task> tasks, {
  Map<String, Contact> contacts = const {},
  Map<String, Property> properties = const {},
  int alarmMinutes = 30,
  DateTime? now,
}) {
  String stamp(DateTime d) {
    final u = d.toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${u.year}${two(u.month)}${two(u.day)}T'
        '${two(u.hour)}${two(u.minute)}${two(u.second)}Z';
  }

  String esc(String s) => s
      .replaceAll(r'\', r'\\')
      .replaceAll(';', r'\;')
      .replaceAll(',', r'\,')
      .replaceAll('\n', r'\n');

  // Linhas com mais de 75 caracteres são dobradas (regra do formato).
  String fold(String line) {
    final out = StringBuffer();
    var rest = line;
    while (rest.length > 74) {
      out.write('${rest.substring(0, 74)}\r\n ');
      rest = rest.substring(74);
    }
    out.write(rest);
    return out.toString();
  }

  final lines = <String>[
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//Imovio//Tarefas//PT',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
  ];
  for (final t in tasks.where((t) => t.date != null && !t.isDone)) {
    final contact = contacts[t.contactId];
    final property = properties[t.propertyId];
    final start = t.date!;
    final end = start.add(Duration(
        minutes: t.category == TaskCategories.visit ? 60 : 30));
    final details = [
      t.category,
      if (contact != null) 'Cliente: ${contact.name}${contact.phone == null ? '' : ' (${contact.phone})'}',
      if (property != null) 'Imóvel: ${property.title}',
      ?t.notes,
    ].join('\n');
    lines.addAll([
      'BEGIN:VEVENT',
      'UID:${t.id}@imovio',
      'DTSTAMP:${stamp(now ?? DateTime.now())}',
      'DTSTART:${stamp(start)}',
      'DTEND:${stamp(end)}',
      'SUMMARY:${esc(t.title)}',
      'DESCRIPTION:${esc(details)}',
      if (property?.morada != null || property?.concelho != null)
        'LOCATION:${esc([property?.morada, property?.freguesia, property?.concelho].whereType<String>().join(', '))}',
      'BEGIN:VALARM',
      'ACTION:DISPLAY',
      'DESCRIPTION:${esc(t.title)}',
      'TRIGGER:-PT${alarmMinutes}M',
      'END:VALARM',
      'END:VEVENT',
    ]);
  }
  lines.add('END:VCALENDAR');
  return '${lines.map(fold).join('\r\n')}\r\n';
}
