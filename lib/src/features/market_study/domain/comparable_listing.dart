import 'package:equatable/equatable.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
import 'package:imovio/src/utils/format.dart';

typedef ComparableID = String;

/// Estado de conservação, do melhor para o pior. A diferença de níveis entre
/// o imóvel e o comparável dá o ajuste de estado.
enum Conservation {
  novo('Novo / Em construção', 3),
  renovado('Renovado', 2),
  usado('Usado', 1),
  recuperar('Para recuperar', 0);

  const Conservation(this.label, this.level);
  final String label;
  final int level;

  static Conservation? fromName(Object? name) =>
      Conservation.values.where((c) => c.name == name).firstOrNull;

  /// Adivinha o estado pelo texto do anúncio ou pelas características.
  static Conservation? guess(String text) {
    final t = text.toLowerCase();
    if (RegExp(r'para recuperar|para restaurar|a precisar de obras|ruína|ruina')
        .hasMatch(t)) {
      return Conservation.recuperar;
    }
    if (RegExp(
      r'\bnovo\b|em construção|em construcao|nunca habitad|empreendimento',
    ).hasMatch(t)) {
      return Conservation.novo;
    }
    if (RegExp(r'renovad|remodelad|restaurad').hasMatch(t)) {
      return Conservation.renovado;
    }
    return null;
  }
}

/// De onde vem o valor do comparável.
enum ComparableSource {
  /// Preço pedido num anúncio: leva a margem de negociação.
  anuncio('Anúncio'),

  /// Valor de uma venda fechada (escritura, CPCV ou informação de colega).
  venda('Venda fechada');

  const ComparableSource(this.label);
  final String label;

  static ComparableSource fromName(Object? name) =>
      name == 'venda' ? ComparableSource.venda : ComparableSource.anuncio;
}

/// Características que entram nos ajustes, lidas do texto das
/// características ou da descrição.
class ComparableFeatures {
  static bool garage(String text) => RegExp(
    r'garagem|estacionamento|parqueamento|lugar de parque|box',
    caseSensitive: false,
  ).hasMatch(text);

  static bool outdoor(String text) => RegExp(
    r'varanda|terraço|terraco|jardim|quintal|logradouro|pátio|patio|marquise',
    caseSensitive: false,
  ).hasMatch(text);

  static bool elevator(String text) =>
      RegExp(r'elevador', caseSensitive: false).hasMatch(text);
}

/// Imóvel usado para comparação no estudo de mercado. Guardado em
/// `users/{uid}/comparaveis/{id}`, para ir formando uma base própria de
/// anúncios e vendas, sempre com os mesmos campos.
class ComparableListing extends Equatable {
  const ComparableListing({
    required this.id,
    required this.title,
    required this.price,
    required this.area,
    this.source = ComparableSource.anuncio,
    this.negocio,
    this.tipo,
    this.tipologia,
    this.concelho,
    this.freguesia,
    this.morada,
    this.conservation,
    this.garage = false,
    this.outdoor = false,
    this.elevator = false,
    this.sourceUrl,
    this.image,
    this.notes,
    this.date,
    this.fromPortfolio = false,
  });

  final ComparableID id;
  final String title;
  final num price;

  /// Área útil (ou bruta, se for a única conhecida), em m².
  final num area;
  final ComparableSource source;
  final String? negocio;
  final String? tipo;
  final String? tipologia;
  final String? concelho;
  final String? freguesia;
  final String? morada;
  final Conservation? conservation;
  final bool garage;
  final bool outdoor;
  final bool elevator;
  final String? sourceUrl;
  final String? image;
  final String? notes;

  /// Data em que o preço foi recolhido ou a venda fechou (yyyy-MM-dd).
  final String? date;

  /// Imóvel da carteira do utilizador, lido de `imoveis` e não guardado aqui.
  final bool fromPortfolio;

  num get pricePerM2 => price / area;

  static const portfolioPrefix = 'imovel:';

  /// Os imóveis da carteira também servem de comparáveis. Um imóvel vendido
  /// conta como venda fechada.
  static ComparableListing? fromProperty(Property p) {
    final area = p.areaUtil ?? p.areaBruta;
    final price = p.price;
    if (area == null || area <= 0 || price == null || price <= 0) return null;
    final text = '${p.caracteristicas ?? ''} ${p.desc ?? ''}';
    return ComparableListing(
      id: '$portfolioPrefix${p.id}',
      title: p.title,
      price: price,
      area: area,
      source: p.saleStatus == 'Vendido'
          ? ComparableSource.venda
          : ComparableSource.anuncio,
      negocio: p.negocio,
      tipo: p.tipo,
      tipologia: p.tipologia,
      concelho: p.concelho,
      freguesia: p.freguesia,
      morada: p.morada,
      conservation: Conservation.guess(text),
      garage: ComparableFeatures.garage(text),
      outdoor: ComparableFeatures.outdoor(text),
      elevator: ComparableFeatures.elevator(text),
      sourceUrl: p.sourceUrl,
      image: p.images.firstOrNull,
      date: p.dateEnd ?? p.dateStart,
      fromPortfolio: true,
    );
  }

  factory ComparableListing.fromMap(Map<String, dynamic> data, String id) {
    String? s(String key) => emptyToNull(data[key]?.toString());
    return ComparableListing(
      id: id,
      title: s('title') ?? '(sem título)',
      price: parseNum(data['price']) ?? 0,
      area: parseNum(data['area']) ?? 0,
      source: ComparableSource.fromName(data['source']),
      negocio: s('negocio'),
      tipo: s('tipo'),
      tipologia: s('tipologia'),
      concelho: s('concelho'),
      freguesia: s('freguesia'),
      morada: s('morada'),
      conservation: Conservation.fromName(data['conservation']),
      garage: data['garage'] == true,
      outdoor: data['outdoor'] == true,
      elevator: data['elevator'] == true,
      sourceUrl: s('sourceUrl'),
      image: s('image'),
      notes: s('notes'),
      date: s('date'),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'price': price,
    'area': area,
    'source': source.name,
    'negocio': negocio ?? '',
    'tipo': tipo ?? '',
    'tipologia': tipologia ?? '',
    'concelho': concelho ?? '',
    'freguesia': freguesia ?? '',
    'morada': morada ?? '',
    'conservation': conservation?.name ?? '',
    'garage': garage,
    'outdoor': outdoor,
    'elevator': elevator,
    'sourceUrl': sourceUrl ?? '',
    'image': image ?? '',
    'notes': notes ?? '',
    'date': date ?? '',
  };

  @override
  List<Object?> get props => [id, fromPortfolio, ...toMap().values];
}
