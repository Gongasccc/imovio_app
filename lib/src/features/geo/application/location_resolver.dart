import 'package:imovio/src/features/geo/data/geo_repository.dart';
import 'package:imovio/src/features/geo/domain/geo_data.dart';

/// Distrito, concelho e freguesia oficiais de um imóvel.
class ResolvedLocation {
  const ResolvedLocation({this.distrito, this.concelho, this.freguesia});
  final String? distrito;
  final String? concelho;
  final String? freguesia;
}

/// Descobre a localização a partir do que o anúncio diz, por esta ordem:
/// 1. o código postal (resposta da GeoAPI.pt);
/// 2. os campos de localidade do anúncio (que podem ser concelho ou
///    freguesia, conforme o portal);
/// 3. nomes de concelhos e freguesias no título, descrição e morada.
ResolvedLocation resolveLocation(
  GeoData geo, {
  PostalLocation? postal,
  List<String?> places = const [],
  List<String?> texts = const [],
}) {
  String? concelho;
  String? freguesia;

  if (postal?.concelho != null) {
    concelho = geo.concelhoNamed(postal!.concelho!) ?? postal.concelho;
    final f = postal.localidade == null
        ? null
        : geo.freguesiaNamed(postal.localidade!, concelho: concelho);
    freguesia = f?.$2;
  }

  for (final place in places.whereType<String>()) {
    if (concelho == null) {
      final c = geo.concelhoNamed(place);
      if (c != null) {
        concelho = c;
        continue;
      }
    }
    if (freguesia == null) {
      final f = geo.freguesiaNamed(place, concelho: concelho);
      if (f != null) {
        concelho ??= f.$1;
        freguesia = f.$2;
      }
    }
  }

  if (concelho == null || freguesia == null) {
    for (final phrase in _phrases(texts.whereType<String>().join(' . '))) {
      if (concelho == null) {
        final c = geo.concelhoNamed(phrase);
        if (c != null) concelho = c;
      }
      if (freguesia == null) {
        final f = geo.freguesiaNamed(phrase, concelho: concelho);
        if (f != null) {
          concelho ??= f.$1;
          freguesia = f.$2;
        }
      }
      if (concelho != null && freguesia != null) break;
    }
  }

  final distrito =
      (concelho == null ? null : geo.distritoOf(concelho)) ?? postal?.distrito;
  return ResolvedLocation(
    distrito: distrito,
    concelho: concelho,
    freguesia: freguesia,
  );
}

/// Sequências de 1 a 5 palavras do texto, das mais longas para as mais
/// curtas ("Charneca de Caparica" antes de "Caparica").
Iterable<String> _phrases(String text) sync* {
  final words = normalizeGeo(text).split(' ').where((w) => w.isNotEmpty).toList();
  const stop = {'de', 'da', 'do', 'dos', 'das', 'e', 'em', 'a', 'o'};
  for (var len = 5; len >= 1; len--) {
    for (var i = 0; i + len <= words.length; i++) {
      final slice = words.sublist(i, i + len);
      if (stop.contains(slice.first) || stop.contains(slice.last)) continue;
      // Palavras soltas muito curtas dão falsos positivos ("Sé", "Luz").
      if (len == 1 && slice.first.length < 5) continue;
      yield slice.join(' ');
    }
  }
}
