import 'package:equatable/equatable.dart';
import 'package:imovio/src/utils/format.dart';

/// Opções da ficha "Imóvel" do contacto (as mesmas da app anterior).
class PreferenceOptions {
  // Estruturais
  static const negocios = ['Comprar', 'Vender', 'Arrendar', 'Trespassar', 'Permuta'];
  static const tipos = [
    'Casa',
    'Prédio',
    'Apartamento',
    'Terreno',
    'Moradia',
    'Loja',
    'Armazém',
  ];
  static const tipologias = ['T0', 'T1', 'T2', 'T3', 'T4', 'T5+'];
  static const tipologiaLabels = {'T5+': 'T5 ou superior'};
  static const financiamento = ['Crédito Habitação', 'Pronto Pagamento'];
  static const sinalCpcv = ['10%', '15%', '20%', 'Mais de 20%'];

  // Físicas
  static const casasDeBanho = ['1', '2', '3', '4 ou mais'];
  static const estados = [
    'Novo',
    'Usado',
    'Em Construção',
    'Renovado',
    'Para Recuperar',
  ];
  static const pisos = [
    'Rés-do-chão',
    'Andar Intermédio',
    'Último Andar / Recuado',
  ];
  static const estacionamento = [
    'Garagem Box',
    'Lugar de Garagem',
    'Estacionamento Exterior',
  ];

  // Comodidades
  static const exterior = ['Varanda', 'Terraço', 'Quintal / Jardim', 'Pátio'];
  static const acessibilidade = ['Com Elevador', 'Acesso Mobilidade Reduzida'];
  static const climatizacao = [
    'Ar Condicionado',
    'Aquecimento Central',
    'Lareira',
  ];
  static const lazer = [
    'Piscina Privada',
    'Piscina Comum',
    'Ginásio',
    'Campo de Ténis',
  ];
}

/// O que o contacto procura (ou o que quer vender). Guardado no campo
/// `pref` do contacto. Os campos antigos (`prefDistrito`, `prefConcelho`,
/// `prefTipo`, `prefTipologia`, `prefMaxPrice`) continuam a ser lidos.
class PropertyPreferences extends Equatable {
  const PropertyPreferences({
    this.negocios = const [],
    this.tipos = const [],
    this.tipologias = const [],
    this.distritos = const [],
    this.concelhos = const [],
    this.freguesias = const [],
    this.bairros = const [],
    this.minPrice,
    this.maxPrice,
    this.financiamento = const [],
    this.sinalCpcv = const [],
    this.minArea,
    this.maxArea,
    this.casasDeBanho = const [],
    this.estados = const [],
    this.pisos = const [],
    this.areaTerreno,
    this.areaBruta,
    this.areaUtil,
    this.estacionamento = const [],
    this.exterior = const [],
    this.acessibilidade = const [],
    this.climatizacao = const [],
    this.lazer = const [],
  });

  final List<String> negocios;
  final List<String> tipos;
  final List<String> tipologias;
  final List<String> distritos;
  final List<String> concelhos;
  final List<String> freguesias;
  final List<String> bairros;
  final num? minPrice;
  final num? maxPrice;
  final List<String> financiamento;
  final List<String> sinalCpcv;
  final num? minArea;
  final num? maxArea;
  final List<String> casasDeBanho;
  final List<String> estados;
  final List<String> pisos;
  final num? areaTerreno;
  final num? areaBruta;
  final num? areaUtil;
  final List<String> estacionamento;
  final List<String> exterior;
  final List<String> acessibilidade;
  final List<String> climatizacao;
  final List<String> lazer;

  bool get isEmpty => props.every(
      (v) => v == null || (v is List && v.isEmpty));

  /// Número mínimo de casas de banho pedido ("4 ou mais" conta como 4).
  int? get minWc {
    final values = casasDeBanho
        .map((v) => int.tryParse(v.split(' ').first))
        .whereType<int>();
    return values.isEmpty ? null : values.reduce((a, b) => a < b ? a : b);
  }

  /// Comodidades que contam como "extras" na pontuação das sugestões.
  List<String> get extras => [
        ...estacionamento,
        ...exterior,
        ...acessibilidade,
        ...climatizacao,
        ...lazer,
      ];

  static List<String> _list(Object? v) => v is List
      ? v.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
      : <String>[];

  static List<String> _legacy(Object? v) {
    final s = emptyToNull(v?.toString());
    return s == null ? const [] : [s];
  }

  factory PropertyPreferences.fromContactMap(Map<String, dynamic> data) {
    final p = data['pref'];
    if (p is Map<String, dynamic>) {
      return PropertyPreferences(
        negocios: _list(p['negocios']),
        tipos: _list(p['tipos']),
        tipologias: _list(p['tipologias']),
        distritos: _list(p['distritos']),
        concelhos: _list(p['concelhos']),
        freguesias: _list(p['freguesias']),
        bairros: _list(p['bairros']),
        minPrice: parseNum(p['minPrice']),
        maxPrice: parseNum(p['maxPrice']),
        financiamento: _list(p['financiamento']),
        sinalCpcv: _list(p['sinalCpcv']),
        minArea: parseNum(p['minArea']),
        maxArea: parseNum(p['maxArea']),
        casasDeBanho: _list(p['casasDeBanho']),
        estados: _list(p['estados']),
        pisos: _list(p['pisos']),
        areaTerreno: parseNum(p['areaTerreno']),
        areaBruta: parseNum(p['areaBruta']),
        areaUtil: parseNum(p['areaUtil']),
        estacionamento: _list(p['estacionamento']),
        exterior: _list(p['exterior']),
        acessibilidade: _list(p['acessibilidade']),
        climatizacao: _list(p['climatizacao']),
        lazer: _list(p['lazer']),
      );
    }
    // Contactos guardados antes desta versão.
    return PropertyPreferences(
      distritos: _legacy(data['prefDistrito']),
      concelhos: _legacy(data['prefConcelho']),
      tipos: _legacy(data['prefTipo']),
      tipologias: _legacy(data['prefTipologia']),
      maxPrice: parseNum(data['prefMaxPrice']),
    );
  }

  Map<String, dynamic> toMap() => {
        'negocios': negocios,
        'tipos': tipos,
        'tipologias': tipologias,
        'distritos': distritos,
        'concelhos': concelhos,
        'freguesias': freguesias,
        'bairros': bairros,
        'minPrice': minPrice,
        'maxPrice': maxPrice,
        'financiamento': financiamento,
        'sinalCpcv': sinalCpcv,
        'minArea': minArea,
        'maxArea': maxArea,
        'casasDeBanho': casasDeBanho,
        'estados': estados,
        'pisos': pisos,
        'areaTerreno': areaTerreno,
        'areaBruta': areaBruta,
        'areaUtil': areaUtil,
        'estacionamento': estacionamento,
        'exterior': exterior,
        'acessibilidade': acessibilidade,
        'climatizacao': climatizacao,
        'lazer': lazer,
      };

  @override
  List<Object?> get props => [
        negocios,
        tipos,
        tipologias,
        distritos,
        concelhos,
        freguesias,
        bairros,
        minPrice,
        maxPrice,
        financiamento,
        sinalCpcv,
        minArea,
        maxArea,
        casasDeBanho,
        estados,
        pisos,
        areaTerreno,
        areaBruta,
        areaUtil,
        estacionamento,
        exterior,
        acessibilidade,
        climatizacao,
        lazer,
      ];
}
