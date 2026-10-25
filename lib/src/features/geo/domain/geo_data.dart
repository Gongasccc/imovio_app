/// Distritos, concelhos e freguesias de Portugal (assets/geo/portugal.json,
/// gerado por tool/build_geo.py a partir da GeoAPI.pt).
class GeoData {
  GeoData(this.tree) {
    for (final d in tree.entries) {
      for (final c in d.value.entries) {
        _distritoOfConcelho[normalizeGeo(c.key)] = d.key;
        _concelhoNames[normalizeGeo(c.key)] = c.key;
        for (final f in c.value) {
          (_freguesiaIndex[normalizeGeo(f)] ??= []).add((c.key, f));
          for (final part in _freguesiaParts(f)) {
            (_freguesiaIndex[normalizeGeo(part)] ??= []).add((c.key, f));
          }
        }
      }
    }
  }

  factory GeoData.fromMap(Map<String, dynamic> map) {
    final distritos = map['distritos'] as Map<String, dynamic>;
    return GeoData({
      for (final d in distritos.entries)
        d.key: {
          for (final c in (d.value as Map<String, dynamic>).entries)
            c.key: (c.value as List).cast<String>(),
        },
    });
  }

  /// distrito → concelho → freguesias
  final Map<String, Map<String, List<String>>> tree;
  final _distritoOfConcelho = <String, String>{};
  final _concelhoNames = <String, String>{};
  final _freguesiaIndex = <String, List<(String, String)>>{};

  List<String> get distritos => tree.keys.toList();

  /// Concelhos dos distritos indicados (todos, se a lista estiver vazia).
  List<String> concelhos([List<String> distritos = const []]) => [
        for (final d in tree.entries)
          if (distritos.isEmpty || distritos.contains(d.key)) ...d.value.keys,
      ]..sort();

  /// Freguesias dos concelhos indicados.
  List<String> freguesias(List<String> concelhos) => [
        for (final d in tree.values)
          for (final c in d.entries)
            if (concelhos.contains(c.key)) ...c.value,
      ]..sort();

  String? distritoOf(String concelho) =>
      _distritoOfConcelho[normalizeGeo(concelho)];

  /// Nome oficial de um concelho, ignorando acentos e maiúsculas.
  String? concelhoNamed(String name) => _concelhoNames[normalizeGeo(name)];

  /// (concelho, freguesia) para um nome de freguesia ou localidade. Nas
  /// uniões de freguesias aceita cada uma das partes ("Corroios" e também
  /// "Charneca de Caparica" em "União das freguesias de Charneca de Caparica
  /// e Sobreda"). Com [concelho] desfaz ambiguidades.
  (String, String)? freguesiaNamed(String name, {String? concelho}) {
    final hits = _freguesiaIndex[normalizeGeo(name)];
    if (hits == null || hits.isEmpty) return null;
    if (concelho != null) {
      final c = normalizeGeo(concelho);
      for (final h in hits) {
        if (normalizeGeo(h.$1) == c) return h;
      }
      return null;
    }
    return hits.length == 1 ? hits.first : null;
  }

  static Iterable<String> _freguesiaParts(String name) {
    final m = RegExp(r'^União das freguesias de (.+)$').firstMatch(name);
    if (m == null) return const [];
    return m
        .group(1)!
        .split(RegExp(r',\s*|\s+e\s+'))
        .map((p) => p.replaceAll(RegExp(r'[()]'), '').trim())
        .where((p) => p.length > 2);
  }
}

String normalizeGeo(String s) => s
    .toLowerCase()
    .replaceAll(RegExp('[áàâã]'), 'a')
    .replaceAll(RegExp('[éèê]'), 'e')
    .replaceAll(RegExp('[íì]'), 'i')
    .replaceAll(RegExp('[óòôõ]'), 'o')
    .replaceAll(RegExp('[úù]'), 'u')
    .replaceAll('ç', 'c')
    .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
