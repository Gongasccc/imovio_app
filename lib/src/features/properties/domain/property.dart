import 'package:equatable/equatable.dart';
import 'package:imovio/src/utils/format.dart';

typedef PropertyID = String;

class PropertyOptions {
  static const negocios = ['Venda', 'Arrendamento'];
  static const tipos = ['Casa', 'Apartamento', 'Terreno', 'Moradia'];
  static const tipologias = ['T0', 'T1', 'T2', 'T3', 'T4', 'T5+'];
  static const saleStatuses = [
    'Em Angariação',
    'Reservado',
    'CPCV Assinado',
    'Vendido',
  ];
  static const saleStatusLabels = {
    'Em Angariação': 'Em Angariação / Ativo',
    'Reservado': 'Reservado',
    'CPCV Assinado': 'CPCV Assinado',
    'Vendido': 'Vendido / Escriturado',
  };
  static const defaultImage =
      'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?auto=format&fit=crop&w=600&q=80';
}

/// Documento em `users/{uid}/imoveis/{id}`, com os campos da app original.
class Property extends Equatable {
  const Property({
    required this.id,
    required this.title,
    this.price,
    this.negocio,
    this.tipo,
    this.tipologia,
    this.areaBruta,
    this.areaUtil,
    this.areaTerreno,
    this.quartos,
    this.wc,
    this.cp,
    this.distrito,
    this.concelho,
    this.freguesia,
    this.bairro,
    this.morada,
    this.desc,
    this.caracteristicas,
    this.images = const [],
    this.sourceUrl,
    this.ownerId,
    this.saleStatus,
    this.commissionPct,
    this.commissionVal,
    this.dateStart,
    this.dateEnd,
    this.saleNotes,
    this.createdAt,
  });

  final PropertyID id;
  final String title;
  final num? price;
  final String? negocio;
  final String? tipo;
  final String? tipologia;
  final num? areaBruta;
  final num? areaUtil;
  final num? areaTerreno;
  final int? quartos;
  final int? wc;
  final String? cp;
  final String? distrito;
  final String? concelho;
  final String? freguesia;
  final String? bairro;
  final String? morada;
  final String? desc;

  /// Separadas por vírgula, como no formulário original.
  final String? caracteristicas;

  /// Galeria. O primeiro elemento é a capa e é também guardado em `img`.
  final List<String> images;

  /// Link do anúncio original (importação por link).
  final String? sourceUrl;

  /// Contacto proprietário/vendedor.
  final String? ownerId;
  final String? saleStatus;
  final num? commissionPct;
  final num? commissionVal;
  final String? dateStart;
  final String? dateEnd;
  final String? saleNotes;
  final int? createdAt;

  String get cover => images.isNotEmpty ? images.first : PropertyOptions.defaultImage;

  /// "Apartamento · T2", como o campo `tags` da app original.
  String get tags => '${tipo ?? 'Casa'} · ${tipologia ?? 'T2'}';

  List<String> get featureList => (caracteristicas ?? '')
      .split(',')
      .map((f) => f.trim())
      .where((f) => f.isNotEmpty)
      .toList();

  factory Property.fromMap(Map<String, dynamic> data, String id) {
    String? s(String key) => emptyToNull(data[key]?.toString());
    final rawImages = data['images'];
    final images = rawImages is List
        ? rawImages.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : <String>[];
    final img = s('img');
    if (images.isEmpty && img != null) images.add(img);
    return Property(
      id: id,
      title: s('title') ?? '(sem título)',
      price: parseNum(data['price']),
      negocio: s('negocio'),
      tipo: s('tipo'),
      tipologia: s('tipologia'),
      areaBruta: parseNum(data['areaBruta']),
      areaUtil: parseNum(data['areaUtil']),
      areaTerreno: parseNum(data['areaTerreno']),
      quartos: parseInt(data['quartos']),
      wc: parseInt(data['wc']),
      cp: s('cp'),
      distrito: s('distrito'),
      concelho: s('concelho'),
      freguesia: s('freguesia'),
      bairro: s('bairro'),
      morada: s('morada'),
      desc: s('desc'),
      caracteristicas: s('caracteristicas'),
      images: images,
      sourceUrl: s('sourceUrl'),
      ownerId: s('ownerId'),
      saleStatus: s('saleStatus'),
      commissionPct: parseNum(data['commissionPct']),
      commissionVal: parseNum(data['commissionVal']),
      dateStart: s('dateStart'),
      dateEnd: s('dateEnd'),
      saleNotes: s('saleNotes'),
      createdAt: parseMillis(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'price': price,
        'negocio': negocio ?? '',
        'tipo': tipo ?? '',
        'tipologia': tipologia ?? '',
        'areaBruta': areaBruta,
        'areaUtil': areaUtil,
        'areaTerreno': areaTerreno,
        'quartos': quartos,
        'wc': wc,
        'cp': cp ?? '',
        'distrito': distrito ?? '',
        'concelho': concelho ?? '',
        'freguesia': freguesia ?? '',
        'bairro': bairro ?? '',
        'morada': morada ?? '',
        'desc': desc ?? '',
        'caracteristicas': caracteristicas ?? '',
        'tags': tags,
        'img': images.isNotEmpty ? images.first : PropertyOptions.defaultImage,
        'images': images,
        'sourceUrl': sourceUrl ?? '',
        'ownerId': ownerId ?? '',
        'saleStatus': saleStatus ?? '',
        'commissionPct': commissionPct,
        'commissionVal': commissionVal,
        'dateStart': dateStart ?? '',
        'dateEnd': dateEnd ?? '',
        'saleNotes': saleNotes ?? '',
        'createdAt': ?createdAt,
      };

  Property copyWith({List<String>? images, int? createdAt}) => Property(
        id: id,
        title: title,
        price: price,
        negocio: negocio,
        tipo: tipo,
        tipologia: tipologia,
        areaBruta: areaBruta,
        areaUtil: areaUtil,
        areaTerreno: areaTerreno,
        quartos: quartos,
        wc: wc,
        cp: cp,
        distrito: distrito,
        concelho: concelho,
        freguesia: freguesia,
        bairro: bairro,
        morada: morada,
        desc: desc,
        caracteristicas: caracteristicas,
        images: images ?? this.images,
        sourceUrl: sourceUrl,
        ownerId: ownerId,
        saleStatus: saleStatus,
        commissionPct: commissionPct,
        commissionVal: commissionVal,
        dateStart: dateStart,
        dateEnd: dateEnd,
        saleNotes: saleNotes,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props => [id, ...toMap().values];
}
