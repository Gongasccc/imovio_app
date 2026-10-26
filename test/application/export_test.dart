import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imovio/src/features/contacts/domain/contact.dart';
import 'package:imovio/src/features/export/application/export_service.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
import 'package:imovio/src/features/tasks/application/calendar_export.dart';
import 'package:imovio/src/features/tasks/domain/task.dart';

void main() {
  test('Excel com uma folha por tipo e texto escapado', () {
    final bytes = exportAllToXlsx(
      contacts: const [Contact(id: 'c', name: 'Ana & Rui <Silva>')],
      properties: const [Property(id: 'p', title: 'T2', price: 250000)],
      deals: const [],
      tasks: const [],
      expenses: const [],
      interactions: const [],
    );
    final zip = ZipDecoder().decodeBytes(bytes);
    final names = zip.files.map((f) => f.name).toSet();
    expect(names, containsAll([
      '[Content_Types].xml',
      'xl/workbook.xml',
      'xl/worksheets/sheet1.xml',
      'xl/worksheets/sheet6.xml',
    ]));
    final sheet1 = utf8.decode(
        zip.files.firstWhere((f) => f.name == 'xl/worksheets/sheet1.xml').content);
    expect(sheet1, contains('Ana &amp; Rui &lt;Silva&gt;'));
    final sheet2 = utf8.decode(
        zip.files.firstWhere((f) => f.name == 'xl/worksheets/sheet2.xml').content);
    expect(sheet2, contains('<v>250000</v>'));
    // Para conferir à mão no Excel: build/teste.xlsx
    File('build/teste.xlsx')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);
  });

  test('calendário .ics com aviso e só tarefas pendentes', () {
    final ics = tasksToIcs([
      Task(id: 'a', title: 'Visita, T2; Almada', date: DateTime.utc(2026, 11, 3, 15),
          category: TaskCategories.visit),
      Task(id: 'b', title: 'Feita', date: DateTime.utc(2026, 11, 4),
          status: TaskStatuses.done),
    ], now: DateTime.utc(2026, 10, 26));
    expect(ics, startsWith('BEGIN:VCALENDAR'));
    expect('BEGIN:VEVENT'.allMatches(ics).length, 1);
    expect(ics, contains(r'SUMMARY:Visita\, T2\; Almada'));
    expect(ics, contains('DTSTART:20261103T150000Z'));
    expect(ics, contains('DTEND:20261103T160000Z'));
    expect(ics, contains('TRIGGER:-PT30M'));
  });
}
