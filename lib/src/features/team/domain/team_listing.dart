import 'package:equatable/equatable.dart';
import 'package:imovio/src/features/authentication/domain/app_user.dart';
import 'package:imovio/src/features/properties/domain/property.dart';

/// Campos de um imóvel que a equipa pode ver. Ficam de fora o proprietário,
/// a morada exata, comissões, notas e o link do anúncio.
const publicListingFields = [
  'title',
  'price',
  'negocio',
  'tipo',
  'tipologia',
  'areaBruta',
  'areaUtil',
  'areaTerreno',
  'quartos',
  'wc',
  'distrito',
  'concelho',
  'freguesia',
  'bairro',
  'desc',
  'caracteristicas',
  'tags',
  'img',
  'images',
  'saleStatus',
];

/// Documento `teams/{teamId}/listings/{agentUid}_{propertyId}`: cópia
/// pública de um imóvel de um membro da equipa.
class TeamListing extends Equatable {
  const TeamListing({
    required this.id,
    required this.agentUid,
    required this.agentName,
    required this.property,
  });

  final String id;
  final UserID agentUid;
  final String agentName;

  /// Só com os [publicListingFields] preenchidos.
  final Property property;

  static String docId(UserID agentUid, PropertyID propertyId) =>
      '${agentUid}_$propertyId';

  /// O que se escreve no Firestore para partilhar [property].
  static Map<String, dynamic> publicData({
    required Property property,
    required UserID agentUid,
    required String agentName,
  }) {
    final full = property.toMap();
    return {
      for (final key in publicListingFields) key: full[key],
      'propertyId': property.id,
      'agentUid': agentUid,
      'agentName': agentName,
    };
  }

  factory TeamListing.fromMap(Map<String, dynamic> data, String id) =>
      TeamListing(
        id: id,
        agentUid: data['agentUid']?.toString() ?? '',
        agentName: data['agentName']?.toString() ?? '',
        property: Property.fromMap({
          for (final key in publicListingFields) key: data[key],
        }, id),
      );

  @override
  List<Object?> get props => [id, agentUid, agentName, property];
}
