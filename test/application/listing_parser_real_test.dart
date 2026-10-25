@Tags(['manual'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:imovio/src/features/properties/application/listing_parser.dart';

/// Corre com `flutter test --run-skipped -t manual --dart-define=LISTING_HTML=<ficheiro>`
/// para ver o que o parser extrai de uma página guardada.
void main() {
  const path = String.fromEnvironment('LISTING_HTML');
  test('parser numa página real', () {
    final l = ListingParser.parse(File(path).readAsStringSync());
    // ignore: avoid_print
    print({
      'title': l.title,
      'price': l.price,
      'negocio': l.negocio,
      'tipo': l.tipo,
      'tipologia': l.tipologia,
      'areaBruta': l.areaBruta,
      'areaUtil': l.areaUtil,
      'areaTerreno': l.areaTerreno,
      'quartos': l.quartos,
      'wc': l.wc,
      'cp': l.cp,
      'distrito': l.distrito,
      'concelho': l.concelho,
      'freguesia': l.freguesia,
      'morada': l.morada,
      'features': l.caracteristicas,
      'cert': l.energyCertificate,
      'year': l.year,
      'images': l.images.length,
      'firstImages': l.images.take(3).toList(),
      'desc': l.description?.substring(0, (l.description!.length).clamp(0, 120)),
    });
  }, skip: path.isEmpty);
}
