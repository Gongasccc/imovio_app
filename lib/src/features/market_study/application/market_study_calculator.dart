import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:imovio/src/features/market_study/domain/comparable_listing.dart';
import 'package:imovio/src/features/market_study/domain/ine_prices.dart';
import 'package:imovio/src/features/market_study/domain/market_study.dart';
import 'package:imovio/src/features/market_study/domain/study_settings.dart';
import 'package:imovio/src/features/properties/domain/property.dart';

/// Método comparativo de mercado: escolhe os comparáveis mais parecidos,
/// homogeneíza o €/m² de cada um (negociação, área, estado, garagem,
/// exterior, elevador e localização) e calcula o intervalo de valor.
class MarketStudyCalculator {
  /// Máximo de comparáveis escolhidos automaticamente.
  static const maxAuto = 8;

  static StudySubject subject(Property p, StudySettings s) {
    final text = '${p.caracteristicas ?? ''} ${p.desc ?? ''}';
    return StudySubject(
      property: p,
      area: p.areaUtil ?? p.areaBruta,
      conservation:
          s.conservation ?? Conservation.guess(text) ?? Conservation.usado,
      garage: s.garage ?? ComparableFeatures.garage(text),
      outdoor: s.outdoor ?? ComparableFeatures.outdoor(text),
      elevator: s.elevator ?? ComparableFeatures.elevator(text),
    );
  }

  static String _norm(String? s) => InePrices.normalize(s ?? '');

  static bool _isRental(String? negocio) => _norm(negocio).startsWith('arrend');

  /// Apartamento compara com apartamento; casa, moradia e terreno entre si
  /// só pelo próprio tipo.
  static String _typeGroup(String? tipo) {
    final t = _norm(tipo);
    if (t.contains('apart')) return 'apartamento';
    if (t.contains('moradia') || t.contains('casa')) return 'moradia';
    return t;
  }

  static int? _rooms(String? tipologia) =>
      int.tryParse(RegExp(r'\d+').firstMatch(tipologia ?? '')?.group(0) ?? '');

  /// Comparável do mesmo negócio e tipo, com preço e área.
  static bool eligible(StudySubject s, ComparableListing c) {
    final p = s.property;
    if (c.price <= 0 || c.area <= 0) return false;
    if (c.id == '${ComparableListing.portfolioPrefix}${p.id}') return false;
    if (_isRental(c.negocio) != _isRental(p.negocio)) return false;
    final a = _typeGroup(p.tipo), b = _typeGroup(c.tipo);
    return a.isEmpty || b.isEmpty || a == b;
  }

  /// 0 a 1: zona (até 0.45), tipologia (até 0.25) e área (até 0.3).
  static double similarity(StudySubject s, ComparableListing c) {
    final p = s.property;
    var score = 0.0;
    final sameMunicipality =
        _norm(p.concelho).isNotEmpty && _norm(p.concelho) == _norm(c.concelho);
    if (sameMunicipality) score += 0.25;
    if (sameMunicipality &&
        _norm(p.freguesia).isNotEmpty &&
        _norm(p.freguesia) == _norm(c.freguesia)) {
      score += 0.2;
    }
    final r1 = _rooms(p.tipologia), r2 = _rooms(c.tipologia);
    if (r1 != null && r2 != null) {
      final diff = (r1 - r2).abs();
      score += diff == 0 ? 0.25 : (diff == 1 ? 0.12 : 0);
    }
    final area = s.area;
    if (area != null && area > 0) {
      final ratio = c.area / area;
      final off = (math.log(ratio)).abs(); // 0 = igual
      score += 0.3 * math.max(0, 1 - off / math.log(2));
    }
    return score;
  }

  static AdjustedComparable adjust(
    StudySubject s,
    ComparableListing c,
    StudySettings settings, {
    required bool included,
    required double similarity,
  }) {
    final k = settings.coefficients;
    final adjustments = <String, double>{};
    final area = s.area;
    if (area != null && area > 0) {
      // Comparável maior → €/m² mais baixo → o imóvel vale mais por m².
      final f = math.pow(c.area / area, k.areaElasticity).toDouble() - 1;
      if (f.abs() >= 0.001) adjustments['Área'] = f;
    }
    final levels =
        s.conservation.level - (c.conservation ?? Conservation.usado).level;
    if (levels != 0) adjustments['Estado'] = levels * k.conservationStep;
    int diff(bool a, bool b) => (a ? 1 : 0) - (b ? 1 : 0);
    if (diff(s.garage, c.garage) != 0) {
      adjustments['Garagem'] = diff(s.garage, c.garage) * k.garage;
    }
    if (diff(s.outdoor, c.outdoor) != 0) {
      adjustments['Exterior'] = diff(s.outdoor, c.outdoor) * k.outdoor;
    }
    if (s.isApartment && diff(s.elevator, c.elevator) != 0) {
      adjustments['Elevador'] = diff(s.elevator, c.elevator) * k.elevator;
    }
    final location = settings.location[c.id] ?? 0;
    if (location != 0) adjustments['Localização'] = location;

    final negotiation = c.source == ComparableSource.anuncio
        ? k.negotiation
        : 0.0;
    final total = adjustments.values.fold(0.0, (a, b) => a + b);
    final adjusted = c.pricePerM2 * (1 - negotiation) * (1 + total);
    final gross = adjustments.values.fold(0.0, (a, b) => a + b.abs());
    return AdjustedComparable(
      comparable: c,
      included: included,
      similarity: similarity,
      negotiation: negotiation,
      adjustments: adjustments,
      adjustedPricePerM2: adjusted.toDouble(),
      // Vendas fechadas valem mais do que preços pedidos.
      weight:
          (c.source == ComparableSource.venda ? 1.5 : 1.0) /
          (1 + 2 * gross) *
          (0.5 + similarity),
    );
  }

  static double _percentile(List<double> sorted, double p) {
    if (sorted.length == 1) return sorted.first;
    final pos = (sorted.length - 1) * p;
    final lo = pos.floor(), hi = pos.ceil();
    return sorted[lo] + (sorted[hi] - sorted[lo]) * (pos - lo);
  }

  static MarketStudy compute({
    required Property property,
    required StudySettings settings,
    required List<ComparableListing> comparables,
    IneReference? ine,
    DateTime? date,
  }) {
    final s = subject(property, settings);
    final pool = comparables
        .where((c) => eligible(s, c))
        .map((c) => (c, similarity(s, c)))
        .sortedBy<num>((e) => -e.$2);

    // Escolha automática: os mais parecidos da mesma zona (ou de qualquer
    // zona se não houver concelho), sem os retirados à mão.
    final auto = pool
        .where(
          (e) =>
              !settings.excluded.contains(e.$1.id) &&
              (_norm(property.concelho).isEmpty ||
                  _norm(property.concelho) == _norm(e.$1.concelho)),
        )
        .take(maxAuto)
        .map((e) => e.$1.id)
        .toSet();
    final chosen = {...auto, ...settings.included}
      ..removeAll(settings.excluded);

    final candidates = [
      for (final e in pool)
        adjust(
          s,
          e.$1,
          settings,
          included: chosen.contains(e.$1.id),
          similarity: e.$2,
        ),
    ].sortedBy<num>((a) => a.included ? 0 : 1);

    final selected = candidates.where((c) => c.included).toList();
    double? m2, low, high;
    var confidence = StudyConfidence.baixa;
    if (selected.isNotEmpty) {
      final totalWeight = selected.fold(0.0, (a, c) => a + c.weight);
      m2 =
          selected.fold(0.0, (a, c) => a + c.adjustedPricePerM2 * c.weight) /
          totalWeight;
      final values = selected.map((c) => c.adjustedPricePerM2).toList()..sort();
      // Com poucos comparáveis o intervalo vai do mínimo ao máximo; com mais,
      // do 1.º ao 3.º quartil, para não depender de um anúncio fora da curva.
      low = values.length >= 4 ? _percentile(values, 0.25) : values.first;
      high = values.length >= 4 ? _percentile(values, 0.75) : values.last;
      final mean = values.average;
      final sd = math.sqrt(
        values.map((v) => math.pow(v - mean, 2)).average.toDouble(),
      );
      final cv = mean == 0 ? 1 : sd / mean;
      confidence = selected.length >= 6 && cv < 0.15
          ? StudyConfidence.alta
          : selected.length >= 3 && cv < 0.25
          ? StudyConfidence.media
          : StudyConfidence.baixa;
    }
    return MarketStudy(
      subject: s,
      settings: settings,
      candidates: candidates,
      ine: ine,
      pricePerM2: m2,
      pricePerM2Low: low,
      pricePerM2High: high,
      confidence: confidence,
      date: date ?? DateTime.now(),
    );
  }
}
