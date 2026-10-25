import 'package:equatable/equatable.dart';
import 'package:imovio/src/features/contacts/domain/attachment.dart';
import 'package:imovio/src/features/contacts/domain/property_preferences.dart';
import 'package:imovio/src/utils/format.dart';

export 'package:imovio/src/features/contacts/domain/attachment.dart';
export 'package:imovio/src/features/contacts/domain/property_preferences.dart';

typedef ContactID = String;

class ContactTypes {
  static const buyer = 'Comprador';
  static const seller = 'Vendedor';
  static const tenant = 'Arrendatário';
  static const all = [buyer, seller, tenant];
}

class IdDocumentTypes {
  static const all = ['Cartão de Cidadão', 'Passaporte', 'Título de Residência'];
}

/// Documento em `users/{uid}/contactos/{id}`. Os nomes dos campos são os da
/// app original para os dados existentes continuarem a funcionar.
class Contact extends Equatable {
  const Contact({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.type = ContactTypes.buyer,
    this.origin,
    this.birth,
    this.nif,
    this.idType,
    this.idNum,
    this.address,
    this.numFloor,
    this.zip,
    this.city,
    this.notes,
    this.preferences = const PropertyPreferences(),
    this.attachments = const [],
    this.createdAt,
    this.updatedAt,
  });

  final ContactID id;
  final String name;
  final String? email;
  final String? phone;
  final String type;
  final String? origin;

  /// "yyyy-MM-dd", como o campo date do HTML.
  final String? birth;
  final String? nif;
  final String? idType;
  final String? idNum;
  final String? address;
  final String? numFloor;
  final String? zip;
  final String? city;
  final String? notes;
  final PropertyPreferences preferences;

  /// Ficheiros anexados (no Firebase Storage). Geridos pelo repositório com
  /// arrayUnion/arrayRemove, por isso não entram em [toMap].
  final List<Attachment> attachments;
  final int? createdAt;
  final int? updatedAt;

  /// Origem mostrada na lista; a app original mostrava "Particular" por omissão.
  String get originLabel => origin ?? 'Particular';

  factory Contact.fromMap(Map<String, dynamic> data, String id) {
    String? s(String key) => emptyToNull(data[key]?.toString());
    return Contact(
      id: id,
      name: s('name') ?? '(sem nome)',
      email: s('email'),
      phone: s('phone'),
      type: s('type') ?? ContactTypes.buyer,
      origin: s('origin'),
      birth: s('birth'),
      nif: s('nif'),
      idType: s('idType'),
      idNum: s('idNum'),
      address: s('address'),
      numFloor: s('numFloor'),
      zip: s('zip'),
      city: s('city'),
      notes: s('notes'),
      preferences: PropertyPreferences.fromContactMap(data),
      attachments: Attachment.listFrom(data['attachments']),
      createdAt: parseMillis(data['createdAt']),
      updatedAt: parseMillis(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email ?? '',
        'phone': phone ?? '',
        'type': type,
        'origin': origin ?? '',
        'birth': birth ?? '',
        'nif': nif ?? '',
        'idType': idType ?? '',
        'idNum': idNum ?? '',
        'address': address ?? '',
        'numFloor': numFloor ?? '',
        'zip': zip ?? '',
        'city': city ?? '',
        'notes': notes ?? '',
        'pref': preferences.toMap(),
        'createdAt': ?createdAt,
        'updatedAt': ?updatedAt,
      };

  Contact copyWith({
    String? name,
    int? createdAt,
    int? updatedAt,
  }) =>
      Contact(
        id: id,
        name: name ?? this.name,
        email: email,
        phone: phone,
        type: type,
        origin: origin,
        birth: birth,
        nif: nif,
        idType: idType,
        idNum: idNum,
        address: address,
        numFloor: numFloor,
        zip: zip,
        city: city,
        notes: notes,
        preferences: preferences,
        attachments: attachments,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  bool matchesText(String query) {
    final q = query.toLowerCase();
    return name.toLowerCase().contains(q) ||
        (email?.toLowerCase().contains(q) ?? false) ||
        (phone?.contains(q) ?? false) ||
        (nif?.contains(q) ?? false);
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        type,
        origin,
        birth,
        nif,
        idType,
        idNum,
        address,
        numFloor,
        zip,
        city,
        notes,
        preferences,
        attachments,
        createdAt,
        updatedAt,
      ];
}
