import 'package:imovio/src/features/market_study/domain/comparable_listing.dart';
import 'package:imovio/src/features/market_study/domain/ine_prices.dart';
import 'package:imovio/src/features/market_study/domain/study_settings.dart';
import 'package:imovio/src/features/properties/domain/property.dart';

/// Características do imóvel em estudo que entram nos ajustes.
class StudySubject {
  const StudySubject({
    required this.property,
    required this.area,
    required this.conservation,
    required this.garage,
    required this.outdoor,
    required this.elevator,
  });

  final Property property;
  final num? area;
  final Conservation conservation;
  final bool garage;
  final bool outdoor;
  final bool elevator;

  bool get isApartment =>
      (property.tipo ?? '').toLowerCase().contains('apartamento');
}

/// Um comparável depois da homogeneização.
class AdjustedComparable {
  const AdjustedComparable({
    required this.comparable,
    required this.included,
    required this.similarity,
    required this.negotiation,
    required this.adjustments,
    required this.adjustedPricePerM2,
    required this.weight,
  });

  final ComparableListing comparable;
  final bool included;

  /// 0 a 1: quão parecido é com o imóvel (zona, tipologia, área).
  final double similarity;

  /// Desconto aplicado ao preço pedido (0 em vendas fechadas).
  final double negotiation;

  /// Ajustes em fração, por fator ("Área", "Estado", ...). Positivo quando o
  /// imóvel em estudo é melhor do que o comparável nesse fator.
  final Map<String, double> adjustments;

  final double adjustedPricePerM2;

  /// Peso na média: comparáveis que precisam de menos ajustes contam mais.
  final double weight;

  double get totalAdjustment =>
      adjustments.values.fold(0.0, (sum, v) => sum + v);
}

enum StudyConfidence {
  alta('Alta'),
  media('Média'),
  baixa('Baixa');

  const StudyConfidence(this.label);
  final String label;
}

/// Resultado do estudo de mercado de um imóvel.
class MarketStudy {
  const MarketStudy({
    required this.subject,
    required this.settings,
    required this.candidates,
    required this.ine,
    required this.pricePerM2,
    required this.pricePerM2Low,
    required this.pricePerM2High,
    required this.confidence,
    required this.date,
  });

  final StudySubject subject;
  final StudySettings settings;

  /// Todos os comparáveis possíveis, com os escolhidos primeiro.
  final List<AdjustedComparable> candidates;
  final IneReference? ine;

  /// €/m² homogeneizado (média ponderada) e intervalo.
  final double? pricePerM2;
  final double? pricePerM2Low;
  final double? pricePerM2High;
  final StudyConfidence confidence;
  final DateTime date;

  List<AdjustedComparable> get selected =>
      candidates.where((c) => c.included).toList();

  num? get _area => subject.area;

  /// Valores arredondados aos mil euros (centenas no arrendamento).
  double? _value(double? m2) {
    if (m2 == null || _area == null) return null;
    final v = m2 * _area!;
    final step = isRental ? 10 : 1000;
    return (v / step).round() * step.toDouble();
  }

  double? get value => _value(pricePerM2);
  double? get valueLow => _value(pricePerM2Low);
  double? get valueHigh => _value(pricePerM2High);

  bool get isRental =>
      (subject.property.negocio ?? '').toLowerCase().startsWith('arrend');

  /// Preço pedido face ao valor provável (0.08 = 8 % acima).
  double? get askingDeviation {
    final asking = subject.property.price;
    final v = value;
    if (asking == null || v == null || v == 0) return null;
    return asking / v - 1;
  }

  /// Valor implícito pela mediana do INE (só venda).
  double? get ineValue {
    final region = ine?.best;
    final m2 = region == null ? null : ineM2(region);
    if (m2 == null || _area == null || isRental) return null;
    return (m2 * _area! / 1000).round() * 1000.0;
  }

  /// Mediana do INE mais adequada ao estado do imóvel (novo ou existente).
  num? ineM2(IneRegion region) =>
      (subject.conservation == Conservation.novo
          ? region.m2New
          : region.m2Existing) ??
      region.m2;
}
