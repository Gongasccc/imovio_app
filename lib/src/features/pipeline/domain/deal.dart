import 'package:equatable/equatable.dart';
import 'package:imovio/src/utils/format.dart';

typedef DealID = String;

class DealStages {
  static const open = 'Negócios em aberto';
  static const qualification = 'Qualificação';
  static const proposal = 'Proposta Apresentada';
  static const cpcv = 'CPCV Assinado';
  static const all = [open, qualification, proposal, cpcv];
}

/// Documento em `users/{uid}/pipeline/{id}`.
class Deal extends Equatable {
  const Deal({
    required this.id,
    required this.title,
    this.contactId,
    this.propertyId,
    this.value,
    this.stage = DealStages.open,
    this.notes,
    this.createdAt,
  });

  final DealID id;
  final String title;
  final String? contactId;
  final String? propertyId;
  final num? value;
  final String stage;
  final String? notes;
  final int? createdAt;

  factory Deal.fromMap(Map<String, dynamic> data, String id) {
    String? s(String key) => emptyToNull(data[key]?.toString());
    return Deal(
      id: id,
      title: s('title') ?? '(sem título)',
      contactId: s('contactId'),
      propertyId: s('propertyId'),
      value: parseNum(data['value']),
      stage: s('stage') ?? DealStages.open,
      notes: s('notes'),
      createdAt: parseMillis(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'contactId': contactId ?? '',
        'propertyId': propertyId ?? '',
        'value': value,
        'stage': stage,
        'notes': notes ?? '',
        'createdAt': ?createdAt,
      };

  Deal copyWith({String? stage, int? createdAt}) => Deal(
        id: id,
        title: title,
        contactId: contactId,
        propertyId: propertyId,
        value: value,
        stage: stage ?? this.stage,
        notes: notes,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props =>
      [id, title, contactId, propertyId, value, stage, notes, createdAt];
}
