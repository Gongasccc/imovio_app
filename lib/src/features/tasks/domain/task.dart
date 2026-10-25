import 'package:equatable/equatable.dart';
import 'package:imovio/src/utils/format.dart';

typedef TaskID = String;

class TaskCategories {
  static const cpcv = 'Assinatura de CPCV';
  static const visit = 'Agendamento de Visita';
  static const general = 'Contacto Geral';
  static const all = [cpcv, visit, general];
}

class TaskStatuses {
  static const pending = 'Pendente';
  static const done = 'Concluída';
  static const all = [pending, done];
}

/// Documento em `users/{uid}/tarefas/{id}`.
class Task extends Equatable {
  const Task({
    required this.id,
    required this.title,
    this.category = TaskCategories.general,
    this.contactId,
    this.propertyId,
    this.date,
    this.status = TaskStatuses.pending,
    this.notes,
    this.createdAt,
  });

  final TaskID id;
  final String title;
  final String category;
  final String? contactId;

  /// Novo: liga visitas ao imóvel (a app original mostrava todas as visitas
  /// em todos os imóveis).
  final String? propertyId;
  final DateTime? date;
  final String status;
  final String? notes;
  final int? createdAt;

  bool get isDone => status == TaskStatuses.done;

  bool isOverdue(DateTime now) =>
      !isDone && date != null && date!.isBefore(now);

  bool isOn(DateTime day) =>
      date != null &&
      date!.year == day.year &&
      date!.month == day.month &&
      date!.day == day.day;

  factory Task.fromMap(Map<String, dynamic> data, String id) {
    String? s(String key) => emptyToNull(data[key]?.toString());
    return Task(
      id: id,
      title: s('title') ?? '(sem título)',
      category: s('category') ?? TaskCategories.general,
      contactId: s('contactId'),
      propertyId: s('propertyId'),
      date: parseDate(data['date']),
      status: s('status') ?? TaskStatuses.pending,
      notes: s('notes'),
      createdAt: parseMillis(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'category': category,
        'contactId': contactId ?? '',
        'propertyId': propertyId ?? '',
        // Mesmo formato do campo datetime-local da app original.
        'date': date == null ? '' : formatIsoDateTime(date!),
        'status': status,
        'notes': notes ?? '',
        'createdAt': ?createdAt,
      };

  Task copyWith({String? status, int? createdAt}) => Task(
        id: id,
        title: title,
        category: category,
        contactId: contactId,
        propertyId: propertyId,
        date: date,
        status: status ?? this.status,
        notes: notes,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props => [
        id,
        title,
        category,
        contactId,
        propertyId,
        date,
        status,
        notes,
        createdAt,
      ];
}
