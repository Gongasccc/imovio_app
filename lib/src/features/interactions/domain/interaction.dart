import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:imovio/src/utils/format.dart';

typedef InteractionID = String;

enum InteractionKind {
  call('call', 'Chamada', Icons.call_outlined),
  whatsapp('whatsapp', 'WhatsApp', Icons.chat_outlined),
  email('email', 'Email', Icons.mail_outline),
  sms('sms', 'SMS', Icons.sms_outlined),
  visit('visit', 'Visita', Icons.event_available_outlined),
  meeting('meeting', 'Reunião', Icons.groups_outlined),
  note('note', 'Nota', Icons.sticky_note_2_outlined);

  const InteractionKind(this.value, this.label, this.icon);
  final String value;
  final String label;
  final IconData icon;

  static InteractionKind from(Object? v) => InteractionKind.values
      .firstWhere((k) => k.value == v, orElse: () => InteractionKind.note);
}

/// Contacto feito com um cliente: chamada, WhatsApp, email, visita ou nota.
/// Guardado em `users/{uid}/interacoes/{id}`. As ações feitas pela app
/// (botões de ligar, WhatsApp, email) ficam registadas automaticamente.
class Interaction extends Equatable {
  const Interaction({
    required this.id,
    required this.contactId,
    required this.kind,
    required this.at,
    this.propertyId,
    this.note,
    this.automatic = false,
    this.taskId,
    this.rating,
    this.priceOpinion,
    this.interested,
  });

  final InteractionID id;
  final String contactId;
  final InteractionKind kind;
  final DateTime at;
  final String? propertyId;
  final String? note;

  /// Registada pela app ao carregar num botão (e não escrita à mão).
  final bool automatic;

  // Opinião depois de uma visita (kind == visit).
  final String? taskId;

  /// 1 a 5 estrelas.
  final int? rating;

  /// 'Caro', 'Justo' ou 'Barato'.
  final String? priceOpinion;
  final bool? interested;

  static const priceOpinions = ['Caro', 'Justo', 'Barato'];

  bool get hasFeedback =>
      rating != null || priceOpinion != null || interested != null;

  factory Interaction.fromMap(Map<String, dynamic> data, String id) => Interaction(
        id: id,
        contactId: data['contactId']?.toString() ?? '',
        kind: InteractionKind.from(data['kind']),
        at: DateTime.fromMillisecondsSinceEpoch(parseMillis(data['at']) ?? 0),
        propertyId: emptyToNull(data['propertyId']?.toString()),
        note: emptyToNull(data['note']?.toString()),
        automatic: data['automatic'] == true,
        taskId: emptyToNull(data['taskId']?.toString()),
        rating: parseInt(data['rating']),
        priceOpinion: emptyToNull(data['priceOpinion']?.toString()),
        interested: data['interested'] is bool ? data['interested'] as bool : null,
      );

  Map<String, dynamic> toMap() => {
        'contactId': contactId,
        'kind': kind.value,
        'at': at.millisecondsSinceEpoch,
        'propertyId': propertyId ?? '',
        'note': note ?? '',
        'automatic': automatic,
        'taskId': taskId ?? '',
        'rating': rating,
        'priceOpinion': priceOpinion ?? '',
        'interested': interested,
      };

  @override
  List<Object?> get props => [
        id,
        contactId,
        kind,
        at,
        propertyId,
        note,
        automatic,
        taskId,
        rating,
        priceOpinion,
        interested,
      ];
}
