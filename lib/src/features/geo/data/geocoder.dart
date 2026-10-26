import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:imovio/src/features/properties/domain/property.dart';

/// Coordenadas aproximadas de um imóvel, pela GeoAPI.pt (gratuita):
/// 1. código postal (o mais preciso, ao nível da rua);
/// 2. centro da freguesia;
/// 3. centro do concelho.
Future<(double, double)?> geocodeProperty(
  http.Client client,
  Property p,
) async {
  Future<Object?> get(String path, [Map<String, String>? query]) async {
    try {
      final res = await client
          .get(Uri.https('json.geoapi.pt', path, query))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      return jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      return null;
    }
  }

  (double, double)? fromList(Object? v, {required bool latFirst}) {
    if (v is! List || v.length < 2) return null;
    final a = (v[0] as num).toDouble(), b = (v[1] as num).toDouble();
    return latFirst ? (a, b) : (b, a);
  }

  if (p.cp != null && RegExp(r'^\d{4}-\d{3}$').hasMatch(p.cp!)) {
    final data = await get('/cp/${p.cp}');
    // No código postal o centro vem como [lat, lng].
    if (data is Map) {
      final c = fromList(data['centro'], latFirst: true);
      if (c != null) return c;
    }
  }
  if (p.freguesia != null) {
    final data = await get('/freguesia/${p.freguesia}', {
      if (p.concelho != null) 'municipio': p.concelho!,
    });
    // Nas áreas administrativas vem como [lng, lat].
    if (data is Map && data['centros'] is Map) {
      final c = fromList(data['centros']['centro'], latFirst: false);
      if (c != null) return c;
    }
  }
  if (p.concelho != null) {
    final data = await get('/municipio/${p.concelho}');
    final props = data is Map && data['geojson'] is Map
        ? data['geojson']['properties']
        : null;
    if (props is Map && props['centros'] is Map) {
      final c = fromList(props['centros']['centro'], latFirst: false);
      if (c != null) return c;
    }
  }
  return null;
}
