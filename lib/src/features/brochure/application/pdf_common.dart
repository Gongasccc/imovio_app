import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:imovio/src/features/properties/presentation/property_list_tile.dart';

/// Cores e letra da marca nos PDFs.
const pdfGold = PdfColor.fromInt(0xFFC5A059);
const pdfDark = PdfColor.fromInt(0xFF121212);
const pdfMuted = PdfColor.fromInt(0xFF6C757D);
const pdfLine = PdfColor.fromInt(0xFFE9ECEF);

Future<pw.ThemeData> pdfTheme() async => pw.ThemeData.withFont(
      base: pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins-Regular.ttf')),
      bold: pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins-SemiBold.ttf')),
    );

/// Descarrega uma foto para o PDF (na web via images.weserv.nl, por causa
/// do CORS). Devolve null se falhar.
Future<pw.ImageProvider?> pdfNetworkImage(
  http.Client client,
  String url, {
  int width = 1200,
}) async {
  try {
    final uri = Uri.parse(kIsWeb ? PropertyImage.webUrl(url, width, format: 'jpg') : url);
    final res = await client.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200 || res.bodyBytes.isEmpty) return null;
    return pw.MemoryImage(res.bodyBytes);
  } catch (_) {
    return null;
  }
}

String pdfSlug(String s) {
  final slug = s
      .toLowerCase()
      .replaceAll(RegExp('[áàâã]'), 'a')
      .replaceAll(RegExp('[éê]'), 'e')
      .replaceAll('í', 'i')
      .replaceAll(RegExp('[óôõ]'), 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? 'documento' : slug;
}
