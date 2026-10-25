import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:imovio/src/features/market_study/domain/comparable_listing.dart';
import 'package:imovio/src/features/market_study/domain/market_study.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
import 'package:imovio/src/utils/format.dart';

/// Relatório em PDF do estudo de mercado, com a estrutura habitual dos
/// estudos comparativos: resumo, caracterização, enquadramento (INE),
/// comparáveis, homogeneização, conclusão e metodologia.
class MarketStudyPdf {
  static const _accent = PdfColor.fromInt(0xFF1E3A5F);
  static const _accentLight = PdfColor.fromInt(0xFFE8EEF5);
  static const _muted = PdfColor.fromInt(0xFF6B7280);
  static const _border = PdfColor.fromInt(0xFFD1D5DB);

  /// Poppins incluída na app (licença OFL), para os acentos e o € saírem
  /// bem mesmo sem internet.
  static Future<pw.ThemeData> _theme() async => pw.ThemeData.withFont(
    base: pw.Font.ttf(
      await rootBundle.load('assets/fonts/Poppins-Regular.ttf'),
    ),
    bold: pw.Font.ttf(
      await rootBundle.load('assets/fonts/Poppins-SemiBold.ttf'),
    ),
  );

  static Future<pw.ImageProvider?> _image(String? url) async {
    if (url == null) return null;
    try {
      return await networkImage(url);
    } catch (_) {
      return null; // Imagem sem CORS ou indisponível: o PDF segue sem capa.
    }
  }

  static Future<Uint8List> build(
    MarketStudy study, {
    String? consultant,
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    final theme = await _theme();
    final p = study.subject.property;
    // A foto genérica da app não entra no relatório.
    final photo = p.images.firstOrNull;
    final cover = await _image(
      photo == PropertyOptions.defaultImage ? null : photo,
    );
    final doc = pw.Document(
      title: 'Estudo de Mercado - ${p.title}',
      author: consultant,
      creator: 'Imovio',
    );
    final unit = study.isRental ? '/mês' : '';

    doc.addPage(
      pw.MultiPage(
        pageFormat: format,
        theme: theme,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 40),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Estudo de mercado · ${Format.date(study.date)}'
              '${consultant == null ? '' : ' · $consultant'}',
              style: const pw.TextStyle(fontSize: 8, color: _muted),
            ),
            pw.Text(
              '${context.pageNumber}/${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: _muted),
            ),
          ],
        ),
        build: (context) => [
          _header(study, cover),
          pw.SizedBox(height: 14),
          _summary(study, unit),
          _section('1. Caracterização do imóvel'),
          _keyValues([
            ('Tipo / tipologia', p.tags),
            ('Negócio', p.negocio ?? '—'),
            (
              'Área útil',
              p.areaUtil == null ? '—' : '${Format.number(p.areaUtil)} m²',
            ),
            (
              'Área bruta',
              p.areaBruta == null ? '—' : '${Format.number(p.areaBruta)} m²',
            ),
            if (p.areaTerreno != null)
              ('Área de terreno', '${Format.number(p.areaTerreno)} m²'),
            ('Quartos / WC', '${p.quartos ?? '—'} / ${p.wc ?? '—'}'),
            ('Estado de conservação', study.subject.conservation.label),
            (
              'Garagem · Exterior${study.subject.isApartment ? ' · Elevador' : ''}',
              [
                study.subject.garage ? 'Sim' : 'Não',
                study.subject.outdoor ? 'Sim' : 'Não',
                if (study.subject.isApartment)
                  study.subject.elevator ? 'Sim' : 'Não',
              ].join(' · '),
            ),
            (
              'Localização',
              _location(p.morada, p.freguesia, p.concelho, p.distrito),
            ),
            ('Preço pedido', '${Format.euros(p.price)}$unit'),
          ]),
          if (p.featureList.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              'Características: ${p.featureList.join(', ')}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
          _section('2. Enquadramento de mercado (INE)'),
          ..._ine(study),
          _section('3. Comparáveis de mercado'),
          pw.Text(
            'Imóveis semelhantes na zona. Os anúncios estão a preço pedido; as '
            'vendas fechadas contam com mais peso na média.',
            style: const pw.TextStyle(fontSize: 9, color: _muted),
          ),
          pw.SizedBox(height: 6),
          _comparablesTable(study),
          pw.SizedBox(height: 10),
          _chart(study),
          _section('4. Homogeneização'),
          pw.Text(
            'Cada comparável é ajustado às características do imóvel em estudo. '
            'Um ajuste positivo significa que o imóvel é melhor do que o '
            'comparável nesse fator.',
            style: const pw.TextStyle(fontSize: 9, color: _muted),
          ),
          pw.SizedBox(height: 6),
          _adjustmentsTable(study),
          pw.SizedBox(height: 6),
          _coefficients(study),
          _section('5. Conclusão'),
          ..._conclusion(study, unit),
          // Título e texto juntos, para o título não ficar sozinho no fim da página.
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _section('6. Metodologia e limitações'),
              pw.Text(
                'Estudo elaborado pelo método comparativo de mercado: recolha de '
                'imóveis semelhantes, conversão em valor por m², ajuste das '
                'diferenças (negociação, área, estado, garagem, exterior, elevador e '
                'localização) e cálculo de uma média ponderada pela semelhança de '
                'cada comparável. O intervalo corresponde ao 1.º e 3.º quartis dos '
                'valores ajustados (mínimo e máximo com menos de quatro '
                'comparáveis). Os valores do INE são medianas de vendas efetivas '
                'nos últimos 12 meses e servem de referência da zona.\n\n'
                'Este documento é um estudo de mercado para apoio à decisão de '
                'preço e não substitui uma avaliação imobiliária feita por perito '
                'avaliador registado na CMVM.',
                style: const pw.TextStyle(fontSize: 9, lineSpacing: 2),
              ),
            ],
          ),
        ],
      ),
    );
    return doc.save();
  }

  static String _location(
    String? morada,
    String? freguesia,
    String? concelho,
    String? distrito,
  ) => [morada, freguesia, concelho, distrito].nonNulls.join(', ').ifEmpty('—');

  static pw.Widget _header(MarketStudy study, pw.ImageProvider? cover) {
    final p = study.subject.property;
    final title = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ESTUDO DE MERCADO',
          style: pw.TextStyle(
            fontSize: 10,
            color: _accent,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          p.title,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          [p.tags, p.freguesia, p.concelho].nonNulls.join(' · '),
          style: const pw.TextStyle(fontSize: 10, color: _muted),
        ),
        pw.Text(
          Format.date(study.date),
          style: const pw.TextStyle(fontSize: 10, color: _muted),
        ),
      ],
    );
    if (cover == null) return title;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.ClipRRect(
          horizontalRadius: 8,
          verticalRadius: 8,
          child: pw.Image(cover, height: 190, fit: pw.BoxFit.cover),
        ),
        pw.SizedBox(height: 12),
        title,
      ],
    );
  }

  static pw.Widget _summary(MarketStudy study, String unit) {
    pw.Widget box(String label, String value, {bool big = false}) =>
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                label,
                style: const pw.TextStyle(fontSize: 8, color: _muted),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: big ? 18 : 11,
                  color: big ? _accent : PdfColors.black,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        );
    final deviation = study.askingDeviation;
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: const pw.BoxDecoration(
        color: _accentLight,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            children: [
              box(
                'Valor de mercado provável',
                '${Format.euros(study.value)}$unit',
                big: true,
              ),
              box(
                'Intervalo',
                '${Format.euros(study.valueLow)} a ${Format.euros(study.valueHigh)}',
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              box('Valor por m²', '${Format.euros(study.pricePerM2)}/m²'),
              box('Comparáveis', '${study.selected.length}'),
              box('Confiança', study.confidence.label),
              box(
                'Preço pedido',
                deviation == null
                    ? '—'
                    : '${Format.euros(study.subject.property.price)} '
                          '(${Format.percent(deviation, signed: true)})',
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _section(String title) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 18, bottom: 8),
    child: pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _accent, width: 1.5)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 13,
          color: _accent,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    ),
  );

  static pw.Widget _keyValues(List<(String, String)> rows) => pw.Table(
    columnWidths: const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(3)},
    children: [
      for (final (k, v) in rows)
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: _border, width: 0.5),
            ),
          ),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Text(
                k,
                style: const pw.TextStyle(fontSize: 9, color: _muted),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Text(v, style: const pw.TextStyle(fontSize: 9)),
            ),
          ],
        ),
    ],
  );

  static List<pw.Widget> _ine(MarketStudy study) {
    final ine = study.ine;
    final regions = [
      if (ine?.parish != null) ine!.parish!,
      if (ine?.municipality != null) ine!.municipality!,
    ];
    if (regions.isEmpty) {
      return [
        pw.Text(
          'Sem dados do INE para a localização indicada.',
          style: const pw.TextStyle(fontSize: 9, color: _muted),
        ),
      ];
    }
    final newLabel = study.subject.conservation == Conservation.novo
        ? 'Mediana (novos)'
        : 'Mediana (existentes)';
    return [
      _table(
        headers: [
          'Zona',
          'Mediana global',
          newLabel,
          'Há um ano',
          'Variação anual',
        ],
        rows: [
          for (final r in regions)
            [
              '${r.levelLabel}: ${r.name}',
              '${Format.euros(r.m2)}/m²',
              '${Format.euros(study.ineM2(r))}/m²',
              '${Format.euros(r.m2PreviousYear)}/m²',
              Format.percent(r.yearlyChange, signed: true),
            ],
        ],
        flex: const [4, 2, 2, 2, 2],
        textColumns: const {0},
      ),
      pw.SizedBox(height: 6),
      pw.Text(
        [
          'Valor mediano das vendas de alojamentos familiares nos últimos 12 '
              'meses, até ao ${ine!.period}. Fonte: ${ine.source}.',
          if (study.ineValue != null)
            'Aplicada à área do imóvel, a mediana da zona indica '
                '${Format.euros(study.ineValue)}.',
          if (study.isRental)
            'Valores de venda, apresentados só como referência da zona.',
        ].join(' '),
        style: const pw.TextStyle(fontSize: 9),
      ),
    ];
  }

  static pw.Widget _table({
    required List<String> headers,
    required List<List<String>> rows,
    required List<int> flex,
    Set<int> textColumns = const {0, 1},
    double fontSize = 8,
  }) => pw.TableHelper.fromTextArray(
    headers: headers,
    data: rows,
    border: null,
    headerStyle: pw.TextStyle(
      fontSize: fontSize,
      color: PdfColors.white,
      fontWeight: pw.FontWeight.bold,
    ),
    headerDecoration: const pw.BoxDecoration(color: _accent),
    cellStyle: pw.TextStyle(fontSize: fontSize),
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    rowDecoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _border, width: 0.5)),
    ),
    oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
    columnWidths: {
      for (var i = 0; i < flex.length; i++)
        i: pw.FlexColumnWidth(flex[i].toDouble()),
    },
    headerAlignments: {
      for (var i = 0; i < headers.length; i++)
        i: textColumns.contains(i)
            ? pw.Alignment.centerLeft
            : pw.Alignment.centerRight,
    },
    cellAlignments: {
      for (var i = 0; i < headers.length; i++)
        i: textColumns.contains(i)
            ? pw.Alignment.centerLeft
            : pw.Alignment.centerRight,
    },
  );

  static pw.Widget _comparablesTable(MarketStudy study) {
    final list = study.selected;
    return _table(
      headers: ['#', 'Imóvel', 'Origem', 'Preço', 'Área', '€/m²', 'Ajustado'],
      flex: const [1, 7, 3, 3, 2, 2, 2],
      textColumns: const {0, 1, 2},
      rows: [
        for (var i = 0; i < list.length; i++)
          [
            '${i + 1}',
            [
              list[i].comparable.title,
              [
                list[i].comparable.tipologia,
                list[i].comparable.freguesia ?? list[i].comparable.concelho,
              ].nonNulls.join(' · '),
            ].where((s) => s.isNotEmpty).join('\n'),
            list[i].comparable.fromPortfolio
                ? 'Carteira'
                : list[i].comparable.source.label,
            Format.euros(list[i].comparable.price),
            '${Format.number(list[i].comparable.area)} m²',
            Format.euros(list[i].comparable.pricePerM2),
            Format.euros(list[i].adjustedPricePerM2),
          ],
      ],
    );
  }

  /// Barras com o €/m² ajustado de cada comparável e a linha do valor final.
  static pw.Widget _chart(MarketStudy study) {
    final list = study.selected;
    final m2 = study.pricePerM2;
    if (list.isEmpty || m2 == null) return pw.SizedBox();
    final max =
        list.map((c) => c.adjustedPricePerM2).fold<double>(m2, math.max) * 1.1;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '€/m² ajustado por comparável',
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        for (var i = 0; i < list.length; i++)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: 18,
                  child: pw.Text(
                    '${i + 1}',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
                pw.Expanded(
                  child: pw.LayoutBuilder(
                    builder: (context, constraints) => pw.Stack(
                      children: [
                        pw.Container(
                          height: 10,
                          width:
                              constraints!.maxWidth *
                              list[i].adjustedPricePerM2 /
                              max,
                          color:
                              list[i].comparable.source ==
                                  ComparableSource.venda
                              ? _accent
                              : PdfColors.blueGrey300,
                        ),
                        pw.Positioned(
                          left: constraints.maxWidth * m2 / max,
                          top: 0,
                          child: pw.Container(
                            width: 1.2,
                            height: 10,
                            color: PdfColors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(
                  width: 60,
                  child: pw.Text(
                    Format.euros(list[i].adjustedPricePerM2),
                    textAlign: pw.TextAlign.right,
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
              ],
            ),
          ),
        pw.SizedBox(height: 2),
        pw.Text(
          'Linha laranja: valor homogeneizado ${Format.euros(m2)}/m². '
          'Azul escuro: vendas fechadas; cinza: anúncios.',
          style: const pw.TextStyle(fontSize: 7, color: _muted),
        ),
      ],
    );
  }

  static pw.Widget _adjustmentsTable(MarketStudy study) {
    const factors = [
      'Área',
      'Estado',
      'Garagem',
      'Exterior',
      'Elevador',
      'Localização',
    ];
    final used = factors
        .where((f) => study.selected.any((c) => c.adjustments.containsKey(f)))
        .toList();
    String pct(double? v) =>
        v == null || v == 0 ? '—' : Format.percent(v, signed: true);
    final list = study.selected;
    return _table(
      headers: ['#', 'Negociação', ...used, 'Total', 'Peso'],
      flex: [1, 2, ...used.map((_) => 2), 2, 2],
      textColumns: const {0},
      rows: [
        for (var i = 0; i < list.length; i++)
          [
            '${i + 1}',
            pct(-list[i].negotiation),
            for (final f in used) pct(list[i].adjustments[f]),
            pct(list[i].totalAdjustment),
            Format.percent(
              list[i].weight / list.fold<double>(0, (a, c) => a + c.weight),
              decimals: 0,
            ),
          ],
      ],
    );
  }

  static pw.Widget _coefficients(MarketStudy study) {
    final k = study.settings.coefficients;
    return pw.Text(
      'Coeficientes usados: negociação ${Format.percent(k.negotiation, decimals: 0)}, '
      'elasticidade da área ${Format.percent(k.areaElasticity, decimals: 0)}, '
      'estado ${Format.percent(k.conservationStep, decimals: 0)} por nível, '
      'garagem ${Format.percent(k.garage, decimals: 0)}, '
      'exterior ${Format.percent(k.outdoor, decimals: 0)}, '
      'elevador ${Format.percent(k.elevator, decimals: 0)}.',
      style: const pw.TextStyle(fontSize: 8, color: _muted),
    );
  }

  static List<pw.Widget> _conclusion(MarketStudy study, String unit) {
    final deviation = study.askingDeviation;
    final k = study.settings.coefficients;
    // Preço de anúncio que, depois da negociação habitual, fecha no valor
    // provável.
    final listing = study.value == null
        ? null
        : ((study.value! / (1 - k.negotiation)) / (study.isRental ? 10 : 1000))
                  .round() *
              (study.isRental ? 10 : 1000);
    final notes = study.settings.notes;
    final commentary = study.settings.commentary;
    return [
      pw.Bullet(
        text:
            'Valor de mercado provável: ${Format.euros(study.value)}$unit '
            '(${Format.euros(study.pricePerM2)}/m²), num intervalo de '
            '${Format.euros(study.valueLow)} a ${Format.euros(study.valueHigh)}.',
        style: const pw.TextStyle(fontSize: 10),
      ),
      if (listing != null)
        pw.Bullet(
          text:
              'Preço de anúncio sugerido: ${Format.euros(listing)}$unit, '
              'contando com uma margem de negociação de '
              '${Format.percent(k.negotiation, decimals: 0)}.',
          style: const pw.TextStyle(fontSize: 10),
        ),
      if (deviation != null)
        pw.Bullet(
          text:
              'O preço pedido atual '
              '(${Format.euros(study.subject.property.price)}) está '
              '${deviation.abs() <= 0.05
                  ? 'alinhado com o mercado'
                  : deviation > 0
                  ? '${Format.percent(deviation)} acima do valor provável'
                  : '${Format.percent(-deviation)} abaixo do valor provável'}.',
          style: const pw.TextStyle(fontSize: 10),
        ),
      pw.Bullet(
        text:
            'Grau de confiança: ${study.confidence.label} '
            '(${study.selected.length} comparáveis).',
        style: const pw.TextStyle(fontSize: 10),
      ),
      if (notes != null && notes.isNotEmpty) ...[
        pw.SizedBox(height: 6),
        pw.Text(
          'Notas do consultor',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(notes, style: const pw.TextStyle(fontSize: 10)),
      ],
      if (commentary != null && commentary.isNotEmpty) ...[
        pw.SizedBox(height: 8),
        pw.Text(
          'Análise de mercado',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          commentary,
          style: const pw.TextStyle(fontSize: 10, lineSpacing: 2),
        ),
      ],
    ];
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
