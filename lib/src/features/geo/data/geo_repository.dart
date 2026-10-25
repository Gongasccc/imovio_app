import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:imovio/src/features/geo/domain/geo_data.dart';

part 'geo_repository.g.dart';

/// Localização devolvida pelo código postal.
class PostalLocation {
  const PostalLocation({this.distrito, this.concelho, this.localidade});
  final String? distrito;
  final String? concelho;
  final String? localidade;
}

/// Consulta um código postal na GeoAPI.pt (gratuita, sem chave).
Future<PostalLocation?> lookupPostalCode(http.Client client, String cp) async {
  try {
    final res = await client
        .get(Uri.parse('https://json.geoapi.pt/cp/$cp'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return null;
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (data is! Map) return null;
    return PostalLocation(
      distrito: data['Distrito'] as String?,
      concelho: data['Concelho'] as String?,
      localidade: data['Localidade'] as String?,
    );
  } catch (_) {
    return null;
  }
}

@Riverpod(keepAlive: true)
Future<GeoData> geoData(Ref ref) async {
  final raw = await rootBundle.loadString('assets/geo/portugal.json');
  return GeoData.fromMap(jsonDecode(raw) as Map<String, dynamic>);
}
