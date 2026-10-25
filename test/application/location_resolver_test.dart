import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:imovio/src/features/geo/application/location_resolver.dart';
import 'package:imovio/src/features/geo/data/geo_repository.dart';
import 'package:imovio/src/features/geo/domain/geo_data.dart';

void main() {
  late GeoData geo;
  setUpAll(() {
    final raw = File('assets/geo/portugal.json').readAsStringSync();
    geo = GeoData.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  });

  test('a lista inclui os 308 concelhos', () {
    expect(geo.concelhos().length, 308);
    expect(geo.distritoOf('Seixal'), 'Setúbal');
    expect(geo.distritoOf('palmela'), 'Setúbal');
  });

  test('código postal dá distrito, concelho e freguesia', () {
    final r = resolveLocation(
      geo,
      postal: const PostalLocation(
          distrito: 'Setúbal', concelho: 'Seixal', localidade: 'Corroios'),
    );
    expect(r.distrito, 'Setúbal');
    expect(r.concelho, 'Seixal');
    expect(r.freguesia, 'Corroios');
  });

  test('sem código postal: localidade do anúncio que é uma freguesia', () {
    final r = resolveLocation(geo, places: ['Corroios']);
    expect(r.concelho, 'Seixal');
    expect(r.distrito, 'Setúbal');
    expect(r.freguesia, 'Corroios');
  });

  test('só pelo título encontra concelho e distrito', () {
    final r = resolveLocation(geo,
        texts: ['Moradia T4 com piscina em Palmela, perto do centro']);
    expect(r.concelho, 'Palmela');
    expect(r.distrito, 'Setúbal');
  });

  test('freguesia dentro de uma união de freguesias', () {
    final r = resolveLocation(geo,
        places: ['Almada'], texts: ['Terreno na Charneca de Caparica']);
    expect(r.concelho, 'Almada');
    expect(r.freguesia, contains('Charneca de Caparica'));
  });
}
