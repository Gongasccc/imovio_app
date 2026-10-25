// Atualiza assets/market/ine_precos.json com o valor mediano das vendas de
// alojamentos familiares nos últimos 12 meses (€/m²) por freguesia, concelho,
// região e país, do INE (indicador 0012234, trimestral, grátis). Corre todos
// os meses no GitHub Actions (.github/workflows/update-ine.yml) e pode
// correr-se à mão:
//
//   dart run tool/update_ine.dart
//
// A app não chama o INE diretamente porque a API não permite pedidos do
// browser (sem CORS).
import 'dart:convert';
import 'dart:io';

const _indicator = '0012234';
const _output = 'assets/market/ine_precos.json';

/// Categoria do alojamento familiar (dimensão 3 do indicador).
const _categories = {'H1': 'm2', 'H11': 'm2Novos', 'H12': 'm2Existentes'};

Future<List<dynamic>> _get(Map<String, String> params) async {
  final uri = Uri.https('www.ine.pt', '/ine/json_indicador/pindica.jsp', {
    'op': '2',
    'varcd': _indicator,
    'lang': 'PT',
    ...params,
  });
  // O servidor do INE às vezes não responde à primeira.
  for (var attempt = 1; ; attempt++) {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    try {
      final req = await client.getUrl(uri);
      final res = await req.close().timeout(const Duration(seconds: 90));
      if (res.statusCode != 200) {
        throw HttpException('INE respondeu ${res.statusCode}', uri: uri);
      }
      return jsonDecode(await res.transform(utf8.decoder).join())
          as List<dynamic>;
    } catch (e) {
      if (attempt == 4) rethrow;
      stderr.writeln('Tentativa $attempt falhou ($e); a repetir.');
      await Future<void>.delayed(Duration(seconds: 5 * attempt));
    } finally {
      client.close();
    }
  }
}

/// "2.º Trimestre de 2026" → código do mesmo trimestre do ano anterior
/// ("S5A20252") e a respetiva designação.
(String, String)? _previousYear(String period) {
  final m = RegExp(r'(\d)\.º Trimestre de (\d{4})').firstMatch(period);
  if (m == null) return null;
  final q = m.group(1)!;
  final y = int.parse(m.group(2)!) - 1;
  return ('S5A$y$q', '$q.º Trimestre de $y');
}

/// geocod → {nome, m2, m2Novos, m2Existentes}.
Map<String, Map<String, dynamic>> _rows(List<dynamic> json) {
  final data = (json.first as Map<String, dynamic>)['Dados'] as Map;
  final rows = <String, Map<String, dynamic>>{};
  for (final list in data.values) {
    for (final r in list as List) {
      final row = r as Map<String, dynamic>;
      final key = _categories[row['dim_3']];
      final value = num.tryParse('${row['valor']}');
      if (key == null || value == null) continue;
      rows.putIfAbsent(
        row['geocod'] as String,
        () => {'nome': row['geodsg']},
      )[key] = value;
    }
  }
  return rows;
}

Future<void> main() async {
  final latest = await _get({});
  final meta = latest.first as Map<String, dynamic>;
  final period = meta['UltimoPref'] as String;
  final current = _rows(latest);
  final prev = _previousYear(period);
  final previous = prev == null
      ? const <String, Map<String, dynamic>>{}
      : _rows(await _get({'Dim1': prev.$1, 'Dim3': 'H1'}));

  final regions = [
    for (final e in current.entries)
      {
        'cod': e.key,
        ...e.value,
        if (previous[e.key]?['m2'] != null)
          'm2Anterior': previous[e.key]!['m2'],
      },
  ]..sort((a, b) => (a['cod'] as String).compareTo(b['cod'] as String));

  final out = {
    'fonte': 'INE, Estatísticas de preços da habitação ao nível local',
    'indicador': _indicator,
    'descricao':
        'Valor mediano das vendas de alojamentos familiares nos '
        'últimos 12 meses (€/m²)',
    'periodo': period,
    'periodoAnterior': prev?.$2,
    'atualizadoINE': meta['DataUltimoAtualizacao'],
    'regioes': regions,
  };
  // Uma região por linha: o ficheiro fica pequeno e o diff legível.
  final buffer = StringBuffer('{\n');
  for (final e in out.entries.where((e) => e.key != 'regioes')) {
    buffer.writeln(' ${jsonEncode(e.key)}: ${jsonEncode(e.value)},');
  }
  buffer.writeln(' "regioes": [');
  buffer.write(regions.map((r) => '  ${jsonEncode(r)}').join(',\n'));
  buffer.writeln('\n ]\n}');
  await File(_output).writeAsString(buffer.toString());
  stdout.writeln('$period: ${regions.length} regiões em $_output');
}
