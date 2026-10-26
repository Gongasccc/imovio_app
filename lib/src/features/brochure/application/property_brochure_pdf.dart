import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:imovio/src/features/brochure/application/pdf_common.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
import 'package:imovio/src/utils/format.dart';

/// Ficha do imóvel para enviar ao cliente: capa, preço, características,
/// descrição, até 4 fotos e o contacto do consultor.
class PropertyBrochurePdf {
  static Future<Uint8List> build(
    Property p, {
    required http.Client client,
    String? consultant,
    String? consultantEmail,
    String? consultantPhone,
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    final theme = await pdfTheme();
    final photos = <pw.ImageProvider>[];
    for (final url in p.images.take(5)) {
      final img = await pdfNetworkImage(client, url,
          width: photos.isEmpty ? 1400 : 700);
      if (img != null) photos.add(img);
    }
    final doc = pw.Document(theme: theme, title: p.title);

    String? area(num? v) => v == null ? null : '${Format.number(v)} m²';
    final specs = <(String, String?)>[
      ('Negócio', p.negocio),
      ('Tipo', p.tipo),
      ('Tipologia', p.tipologia),
      ('Área útil', area(p.areaUtil)),
      ('Área bruta', area(p.areaBruta)),
      ('Terreno', area(p.areaTerreno)),
      ('Quartos', p.quartos?.toString()),
      ('Casas de banho', p.wc?.toString()),
      ('Freguesia', p.freguesia),
      ('Concelho', p.concelho),
      ('Distrito', p.distrito),
    ].where((e) => e.$2 != null).toList();
    final features = p.featureList;

    doc.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: pdfLine)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                [consultant, consultantPhone, consultantEmail]
                    .whereType<String>()
                    .where((s) => s.isNotEmpty)
                    .join('  ·  '),
                style: const pw.TextStyle(fontSize: 9, color: pdfMuted),
              ),
              pw.Text('${context.pageNumber}/${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 9, color: pdfMuted)),
            ],
          ),
        ),
        build: (context) => [
          if (photos.isNotEmpty)
            pw.ClipRRect(
              horizontalRadius: 8,
              verticalRadius: 8,
              child: pw.Image(photos.first,
                  height: 280, width: double.infinity, fit: pw.BoxFit.cover),
            ),
          pw.SizedBox(height: 16),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(p.title,
                        style: pw.TextStyle(
                            fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      [p.freguesia, p.concelho].whereType<String>().join(', '),
                      style: const pw.TextStyle(color: pdfMuted),
                    ),
                  ],
                ),
              ),
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: pdfGold,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  Format.euros(p.price),
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: pdfDark,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (label, value) in specs)
                pw.Container(
                  width: 160,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: pdfLine),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(label,
                          style:
                              const pw.TextStyle(fontSize: 9, color: pdfMuted)),
                      pw.Text(value!,
                          style: pw.TextStyle(
                              fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
          if (p.desc != null) ...[
            pw.SizedBox(height: 18),
            pw.Text('Descrição',
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text(p.desc!, style: const pw.TextStyle(lineSpacing: 2)),
          ],
          if (features.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            pw.Text('Características',
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final f in features)
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0x22C5A059),
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Text(f, style: const pw.TextStyle(fontSize: 10)),
                  ),
              ],
            ),
          ],
          if (photos.length > 1) ...[
            pw.SizedBox(height: 18),
            pw.GridView(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.66,
              children: [
                for (final img in photos.skip(1))
                  pw.ClipRRect(
                    horizontalRadius: 6,
                    verticalRadius: 6,
                    child: pw.Image(img, fit: pw.BoxFit.cover),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
    return doc.save();
  }
}
