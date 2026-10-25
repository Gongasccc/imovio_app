import 'package:equatable/equatable.dart';
import 'package:imovio/src/features/authentication/domain/app_user.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
import 'package:imovio/src/utils/format.dart';

/// Documento `teams/{teamId}/sales/{afilhadoUid}_{propertyId}`: os números
/// de venda de um imóvel de um afilhado, que só ele e o padrinho leem.
/// O afilhado escreve-o sempre que altera o imóvel.
class AfilhadoSale extends Equatable {
  const AfilhadoSale({
    required this.id,
    required this.afilhadoUid,
    required this.afilhadoName,
    required this.sponsorUid,
    required this.propertyId,
    required this.title,
    this.saleStatus,
    this.salePrice,
    required this.agentShare,
    this.dateEnd,
  });

  final String id;
  final UserID afilhadoUid;
  final String afilhadoName;
  final UserID sponsorUid;
  final PropertyID propertyId;
  final String title;
  final String? saleStatus;

  /// Valor de venda (ou o anunciado, enquanto não há venda).
  final num? salePrice;

  /// A parte do afilhado na comissão, já calculada pela app dele.
  final num agentShare;
  final String? dateEnd;

  bool get isSold => saleStatus == 'Vendido';

  static String docId(UserID afilhadoUid, PropertyID propertyId) =>
      '${afilhadoUid}_$propertyId';

  factory AfilhadoSale.fromMap(Map<String, dynamic> data, String id) =>
      AfilhadoSale(
        id: id,
        afilhadoUid: data['afilhadoUid']?.toString() ?? '',
        afilhadoName: data['afilhadoName']?.toString() ?? '',
        sponsorUid: data['sponsorUid']?.toString() ?? '',
        propertyId: data['propertyId']?.toString() ?? '',
        title: emptyToNull(data['title']?.toString()) ?? '(sem título)',
        saleStatus: emptyToNull(data['saleStatus']?.toString()),
        salePrice: parseNum(data['salePrice']),
        agentShare: parseNum(data['agentShare']) ?? 0,
        dateEnd: emptyToNull(data['dateEnd']?.toString()),
      );

  Map<String, dynamic> toMap() => {
    'afilhadoUid': afilhadoUid,
    'afilhadoName': afilhadoName,
    'sponsorUid': sponsorUid,
    'propertyId': propertyId,
    'title': title,
    'saleStatus': saleStatus ?? '',
    'salePrice': salePrice,
    'agentShare': agentShare,
    'dateEnd': dateEnd ?? '',
  };

  @override
  List<Object?> get props => [id, ...toMap().values];
}
