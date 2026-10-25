import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:imovio/src/features/market_study/application/market_study_calculator.dart';
import 'package:imovio/src/features/market_study/application/market_study_pdf.dart';
import 'package:imovio/src/features/market_study/domain/comparable_listing.dart';
import 'package:imovio/src/features/market_study/domain/ine_prices.dart';
import 'package:imovio/src/features/market_study/domain/market_study.dart';
import 'package:imovio/src/features/market_study/domain/study_settings.dart';
import 'package:imovio/src/features/properties/domain/property.dart';

const _subject = Property(
  id: 'p1',
  title: 'T2 em Braga',
  price: 250000,
  negocio: 'Venda',
  tipo: 'Apartamento',
  tipologia: 'T2',
  areaUtil: 100,
  concelho: 'Braga',
  freguesia: 'São Vicente',
  caracteristicas: 'Garagem, Varanda, Elevador',
);

ComparableListing _c(
  String id,
  num price,
  num area, {
  String concelho = 'Braga',
  String tipo = 'Apartamento',
  String negocio = 'Venda',
  String tipologia = 'T2',
  bool garage = true,
  bool outdoor = true,
  bool elevator = true,
  Conservation? conservation,
  ComparableSource source = ComparableSource.anuncio,
}) => ComparableListing(
  id: id,
  title: id,
  price: price,
  area: area,
  concelho: concelho,
  tipo: tipo,
  negocio: negocio,
  tipologia: tipologia,
  garage: garage,
  outdoor: outdoor,
  elevator: elevator,
  conservation: conservation,
  source: source,
);

MarketStudy _study(
  List<ComparableListing> comps, [
  StudySettings settings = const StudySettings(),
]) => MarketStudyCalculator.compute(
  property: _subject,
  settings: settings,
  comparables: comps,
  date: DateTime(2026, 10, 25),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('homogeneização', () {
    test('comparável igual só leva a margem de negociação', () {
      final s = _study([_c('a', 200000, 100)]);
      final a = s.selected.single;
      expect(a.adjustments, isEmpty);
      expect(a.negotiation, 0.05);
      expect(a.adjustedPricePerM2, closeTo(1900, 0.01));
      expect(s.value, 190000);
    });

    test('venda fechada não leva margem de negociação', () {
      final s = _study([_c('a', 200000, 100, source: ComparableSource.venda)]);
      expect(s.selected.single.adjustedPricePerM2, closeTo(2000, 0.01));
    });

    test('comparável sem garagem e para recuperar sobe o €/m²', () {
      final s = _study([
        _c(
          'a',
          200000,
          100,
          garage: false,
          conservation: Conservation.recuperar,
        ),
      ]);
      final a = s.selected.single;
      expect(a.adjustments['Garagem'], 0.05);
      expect(
        a.adjustments['Estado'],
        closeTo(0.08, 1e-9),
      ); // usado vs recuperar
      expect(a.adjustedPricePerM2, closeTo(2000 * 0.95 * 1.13, 0.01));
    });

    test('comparável maior tem €/m² mais baixo e é ajustado para cima', () {
      final s = _study([_c('a', 300000, 200)]);
      expect(s.selected.single.adjustments['Área'], greaterThan(0.1));
    });

    test('só compara o mesmo negócio e tipo', () {
      final s = _study([
        _c('arrendamento', 1000, 100, negocio: 'Arrendamento'),
        _c('moradia', 400000, 100, tipo: 'Moradia'),
        _c('ok', 200000, 100),
      ]);
      expect(s.candidates.map((c) => c.comparable.id), ['ok']);
    });

    test('outro concelho não entra sozinho, mas pode ser incluído', () {
      final comps = [_c('porto', 300000, 100, concelho: 'Porto')];
      expect(_study(comps).selected, isEmpty);
      expect(
        _study(comps, const StudySettings(included: {'porto'})).selected,
        hasLength(1),
      );
    });

    test('retirar um comparável tira-o do cálculo', () {
      final comps = [_c('a', 200000, 100), _c('b', 260000, 100)];
      final s = _study(
        comps,
        const StudySettings().toggle('b', include: false),
      );
      expect(s.selected.map((c) => c.comparable.id), ['a']);
    });

    test('intervalo pelos quartis e preço pedido face ao mercado', () {
      final s = _study([
        for (var i = 0; i < 6; i++) _c('c$i', 190000 + i * 4000, 100),
      ]);
      expect(s.pricePerM2Low, lessThan(s.pricePerM2!));
      expect(s.pricePerM2High, greaterThan(s.pricePerM2!));
      expect(s.confidence, StudyConfidence.alta);
      expect(s.askingDeviation, greaterThan(0.2));
    });

    test('o imóvel da carteira não se compara consigo próprio', () {
      final self = ComparableListing.fromProperty(_subject)!;
      expect(_study([self]).candidates, isEmpty);
    });
  });

  group('INE', () {
    final ine = InePrices.fromMap(
      jsonDecode(File('assets/market/ine_precos.json').readAsStringSync())
          as Map<String, dynamic>,
    );

    test('encontra o concelho e distingue as ilhas', () {
      expect(ine.lookup(concelho: 'Braga')!.municipality!.code, '1120303');
      expect(
        ine.lookup(concelho: 'Lagoa')!.municipality!.code,
        startsWith('1'),
      );
      expect(
        ine
            .lookup(concelho: 'Lagoa', distrito: 'Ilha de São Miguel (Açores)')!
            .municipality!
            .code,
        startsWith('2'),
      );
      expect(ine.lookup(concelho: 'Concelho que não existe'), isNull);
    });

    test('encontra a freguesia dentro de uma união de freguesias', () {
      final r = ine.lookup(concelho: 'Lagoa', freguesia: 'Lagoa e Carvoeiro');
      expect(r!.parish?.name, contains('Lagoa e Carvoeiro'));
      expect(r.best, r.parish);
    });
  });

  test('gera o PDF', () async {
    await initializeDateFormatting('pt_PT');
    final s = _study([
      _c('a', 200000, 100, garage: false),
      _c('b', 230000, 110, source: ComparableSource.venda),
      _c('c', 210000, 95, conservation: Conservation.renovado),
    ], const StudySettings(notes: 'Zona com muita procura.'));
    final bytes = await MarketStudyPdf.build(s, consultant: 'Teste');
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(5000));
  });
}
