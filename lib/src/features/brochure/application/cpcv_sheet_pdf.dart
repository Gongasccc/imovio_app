import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:imovio/src/features/brochure/application/pdf_common.dart';
import 'package:imovio/src/features/contacts/domain/contact.dart';
import 'package:imovio/src/features/pipeline/domain/deal.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
import 'package:imovio/src/utils/format.dart';

/// Ficha com os dados para preparar a minuta do CPCV: partes, imóvel,
/// preço, sinal e prazos. Os campos em falta ficam em branco para completar.
/// Não é a minuta: serve para a enviar ao advogado ou solicitador.
class CpcvSheetPdf {
  static Future<Uint8List> build({
    required Deal deal,
    Contact? buyer,
    Contact? seller,
    Property? property,
    String? consultant,
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    final theme = await pdfTheme();
    final doc = pw.Document(theme: theme, title: 'Ficha CPCV - ${deal.title}');
    final price = property?.salePrice ?? property?.price;
    final sinalPct = buyer?.preferences.sinalCpcv.isNotEmpty == true
        ? buyer!.preferences.sinalCpcv.first
        : null;
    final sinalValue = () {
      final pct = num.tryParse(sinalPct?.replaceAll('%', '') ?? '');
      return price == null || pct == null ? null : price * pct / 100;
    }();

    pw.Widget section(String title, List<(String, String?)> rows) =>
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 14),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: format.width - 72,
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: pdfGold,
                child: pw.Text(title,
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, color: pdfDark)),
              ),
              pw.Table(
                border: const pw.TableBorder(
                  horizontalInside: pw.BorderSide(color: pdfLine),
                  bottom: pw.BorderSide(color: pdfLine),
                ),
                columnWidths: const {
                  0: pw.FixedColumnWidth(170),
                  1: pw.FlexColumnWidth(),
                },
                children: [
                  for (final (label, value) in rows)
                    pw.TableRow(children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(label,
                            style: const pw.TextStyle(
                                fontSize: 10, color: pdfMuted)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          (value == null || value.isEmpty)
                              ? '______________________________'
                              : value,
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ),
                    ]),
                ],
              ),
            ],
          ),
        );

    List<(String, String?)> person(Contact? c) => [
          ('Nome completo', c?.name),
          ('NIF', c?.nif),
          ('Documento', c == null || c.idNum == null
              ? null
              : '${c.idType ?? 'Documento'} n.º ${c.idNum}'),
          ('Data de nascimento', c?.birth),
          ('Morada', [c?.address, c?.numFloor, c?.zip, c?.city]
              .whereType<String>()
              .join(', ')),
          ('Telefone', c?.phone),
          ('Email', c?.email),
          ('Estado civil / regime', null),
        ];

    doc.addPage(pw.MultiPage(
      pageFormat: format,
      margin: const pw.EdgeInsets.all(36),
      build: (_) => [
        pw.Text('Ficha para a minuta do CPCV',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(
          'Negócio: ${deal.title}  ·  Preparada em '
          '${Format.date(DateTime.now())}${consultant == null ? '' : ' por $consultant'}',
          style: const pw.TextStyle(fontSize: 10, color: pdfMuted),
        ),
        pw.SizedBox(height: 16),
        section('Promitente vendedor', person(seller)),
        section('Promitente comprador', person(buyer)),
        section('Imóvel', [
          ('Descrição', property?.title),
          ('Tipo / tipologia',
              [property?.tipo, property?.tipologia].whereType<String>().join(' ')),
          ('Morada', property?.morada),
          ('Código postal', property?.cp),
          ('Freguesia / concelho',
              [property?.freguesia, property?.concelho].whereType<String>().join(', ')),
          ('Área útil / bruta', [
            if (property?.areaUtil != null) '${Format.number(property!.areaUtil)} m² útil',
            if (property?.areaBruta != null) '${Format.number(property!.areaBruta)} m² bruta',
          ].join(' · ')),
          ('Artigo matricial', null),
          ('Descrição predial (CRP)', null),
          ('Licença de utilização', null),
          ('Certificado energético', null),
        ]),
        section('Condições', [
          ('Preço', price == null ? null : Format.euros(price)),
          ('Sinal', [
            ?sinalPct,
            if (sinalValue != null) Format.euros(sinalValue),
          ].join(' · ')),
          ('Reforço de sinal', null),
          ('Financiamento', buyer?.preferences.financiamento.join(', ')),
          ('Prazo para a escritura', property?.dateEnd),
          ('Ónus / hipotecas a distratar', null),
          ('Comissão da mediação',
              property?.commissionPct == null ? null : '${Format.number(property!.commissionPct)} % + IVA'),
        ]),
        pw.SizedBox(height: 8),
        pw.Text(
          'Documento de apoio para preparar a minuta. Não substitui o '
          'contrato redigido e revisto por advogado ou solicitador.',
          style: const pw.TextStyle(fontSize: 9, color: pdfMuted),
        ),
      ],
    ));
    return doc.save();
  }
}
