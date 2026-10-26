import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:imovio/src/features/brochure/application/cpcv_sheet_pdf.dart';
import 'package:imovio/src/features/brochure/application/property_brochure_pdf.dart';
import 'package:imovio/src/features/contacts/domain/contact.dart';
import 'package:imovio/src/features/pipeline/domain/deal.dart';
import 'package:imovio/src/features/properties/domain/property.dart';

// PNG 1x1 para simular as fotos.
const _png = [
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, //
  0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 13, 73, 68, 65, 84, //
  120, 156, 99, 248, 207, 192, 240, 31, 0, 5, 0, 1, 255, 137, 153, 61, 29, 0, //
  0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('pt_PT'));

  const property = Property(
    id: 'p',
    title: 'Moradia T4 com piscina',
    price: 495000,
    tipologia: 'T4',
    areaUtil: 210,
    concelho: 'Palmela',
    desc: 'Moradia com jardim.',
    caracteristicas: 'piscina, garagem',
    images: ['https://x/1.jpg', 'https://x/2.jpg', 'https://x/3.jpg'],
  );

  test('ficha do imóvel gera o PDF com fotos (sem erro de Infinity)',
      () async {
    final client = MockClient(
        (_) async => http.Response.bytes(_png, 200));
    final bytes = await PropertyBrochurePdf.build(property, client: client);
    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('ficha para o CPCV gera o PDF', () async {
    final bytes = await CpcvSheetPdf.build(
      deal: const Deal(id: 'd', title: 'Venda moradia'),
      buyer: const Contact(id: 'b', name: 'Comprador'),
      property: property,
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
