import 'package:equatable/equatable.dart';
import 'package:imovio/src/utils/format.dart';

/// Uma linha de `assets/market/ine_precos.json`: valor mediano das vendas nos
/// últimos 12 meses (€/m²) de uma freguesia, concelho, região ou do país.
class IneRegion extends Equatable {
  const IneRegion({
    required this.code,
    required this.name,
    this.m2,
    this.m2New,
    this.m2Existing,
    this.m2PreviousYear,
  });

  /// Código NUTS do INE: 1 a 3 dígitos para país e regiões, 7 para
  /// concelhos e 9 para freguesias.
  final String code;
  final String name;
  final num? m2;
  final num? m2New;
  final num? m2Existing;
  final num? m2PreviousYear;

  bool get isMunicipality => code.length == 7;
  bool get isParish => code.length == 9;

  String get levelLabel => isParish
      ? 'Freguesia'
      : isMunicipality
      ? 'Concelho'
      : 'Região';

  /// Variação face ao mesmo período do ano anterior (0.12 = +12 %).
  double? get yearlyChange =>
      (m2 != null && m2PreviousYear != null) ? m2! / m2PreviousYear! - 1 : null;

  factory IneRegion.fromMap(Map<String, dynamic> data) => IneRegion(
    code: data['cod'].toString(),
    name: data['nome'].toString(),
    m2: parseNum(data['m2']),
    m2New: parseNum(data['m2Novos']),
    m2Existing: parseNum(data['m2Existentes']),
    m2PreviousYear: parseNum(data['m2Anterior']),
  );

  @override
  List<Object?> get props => [
    code,
    name,
    m2,
    m2New,
    m2Existing,
    m2PreviousYear,
  ];
}

/// Referência do INE para o imóvel: a freguesia, se houver dados, e o
/// concelho.
class IneReference extends Equatable {
  const IneReference({
    required this.period,
    required this.previousPeriod,
    required this.source,
    this.parish,
    this.municipality,
  });

  final String period;
  final String? previousPeriod;
  final String source;
  final IneRegion? parish;
  final IneRegion? municipality;

  /// A região mais próxima do imóvel com valor.
  IneRegion? get best => parish?.m2 != null ? parish : municipality;

  @override
  List<Object?> get props => [
    period,
    previousPeriod,
    source,
    parish,
    municipality,
  ];
}

class InePrices {
  InePrices({
    required this.period,
    required this.previousPeriod,
    required this.source,
    required this.regions,
  });

  final String period;
  final String? previousPeriod;
  final String source;
  final List<IneRegion> regions;

  factory InePrices.fromMap(Map<String, dynamic> data) => InePrices(
    period: data['periodo'].toString(),
    previousPeriod: data['periodoAnterior']?.toString(),
    source: data['fonte'].toString(),
    regions: [
      for (final r in data['regioes'] as List)
        IneRegion.fromMap(r as Map<String, dynamic>),
    ],
  );

  /// "Lagoa (R.A.A.)" → "lagoa"; "Vila Nova de Gaia" → "vila nova de gaia".
  static String normalize(String text) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const to = 'aaaaaeeeeiiiiooooouuuucn';
    final lower = text.toLowerCase().replaceAll(RegExp(r'\(.*?\)'), '');
    final buffer = StringBuffer();
    for (final ch in lower.split('')) {
      final i = from.indexOf(ch);
      buffer.write(i >= 0 ? to[i] : ch);
    }
    return buffer.toString().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  /// Procura o concelho (e a freguesia, quando o INE a publica). O distrito
  /// distingue concelhos com o mesmo nome no continente e nas ilhas
  /// (Calheta, Lagoa).
  IneReference? lookup({
    required String? concelho,
    String? freguesia,
    String? distrito,
  }) {
    if (concelho == null || concelho.trim().isEmpty) return null;
    final name = normalize(concelho);
    final candidates = regions
        .where((r) => r.isMunicipality && normalize(r.name) == name)
        .toList();
    if (candidates.isEmpty) return null;
    // Sem tirar o que está entre parênteses: "Ilha de São Miguel (Açores)".
    final d = normalize((distrito ?? '').replaceAll(RegExp('[()]'), ' '));
    final prefix =
        RegExp(r'acores|ponta delgada|angra do heroismo|horta').hasMatch(d)
        ? '2'
        : RegExp(r'madeira|funchal').hasMatch(d)
        ? '3'
        : '1';
    final municipality = candidates.firstWhere(
      (r) => r.code.startsWith(prefix),
      orElse: () => candidates.first,
    );

    IneRegion? parish;
    final f = normalize(freguesia ?? '');
    if (f.isNotEmpty) {
      final parishes = regions.where(
        (r) => r.isParish && r.code.startsWith(municipality.code),
      );
      parish =
          parishes.where((r) => normalize(r.name) == f).firstOrNull ??
          // "Lagoa e Carvoeiro" dentro de "União das freguesias de ...".
          parishes
              .where((r) => ' ${normalize(r.name)} '.contains(' $f '))
              .firstOrNull;
    }
    return IneReference(
      period: period,
      previousPeriod: previousPeriod,
      source: source,
      parish: parish,
      municipality: municipality,
    );
  }
}
