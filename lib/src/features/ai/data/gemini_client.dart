import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Página de onde vem uma resposta com pesquisa Google.
class GeminiSource {
  const GeminiSource({required this.title, required this.uri});
  final String title;
  final String uri;
}

class GeminiResponse {
  const GeminiResponse({
    required this.text,
    this.sources = const [],
    this.searchQueries = const [],
  });

  final String text;

  /// Páginas encontradas pela pesquisa Google (a Google pede que sejam
  /// mostradas junto do resultado).
  final List<GeminiSource> sources;
  final List<String> searchQueries;

  /// O JSON da resposta, mesmo que venha dentro de ```json ... ``` ou com
  /// texto à volta (com pesquisa Google não é possível pedir JSON estrito).
  Object? get json {
    final t = text.trim();
    // O que abrir primeiro: um objeto pode ter listas lá dentro e vice-versa.
    final pairs = [('[', ']'), ('{', '}')]
      ..removeWhere((p) => !t.contains(p.$1))
      ..sort((a, b) => t.indexOf(a.$1).compareTo(t.indexOf(b.$1)));
    for (final (open, close) in pairs) {
      final start = t.indexOf(open);
      final end = t.lastIndexOf(close);
      if (end <= start) continue;
      try {
        return jsonDecode(t.substring(start, end + 1));
      } catch (_) {
        // Tenta o outro formato.
      }
    }
    return null;
  }
}

class GeminiException implements Exception {
  const GeminiException(this.message, {this.status});
  final String message;
  final int? status;

  /// A chave foi recusada (inválida ou sem acesso).
  bool get isKeyProblem => status == 400 || status == 401 || status == 403;

  /// Problema passageiro do lado da Google (sobrecarga ou limite): a chave
  /// em si está boa.
  bool get isTemporary =>
      status == 429 || status == 500 || status == 503 || status == 504;

  @override
  String toString() => message;
}

/// Cliente da API Gemini (Google AI Studio), chamada diretamente da app com a
/// chave do próprio utilizador. O plano gratuito inclui pesquisa Google nos
/// modelos Gemini 2.5 Flash e Flash-Lite (500 pedidos por dia, partilhados).
class GeminiClient {
  GeminiClient(this._client, this._apiKey);
  final http.Client _client;
  final String _apiKey;

  /// Preferidos quando existem. Os "-latest" apontam sempre para o modelo
  /// Flash atual, por isso não deixam de funcionar quando a Google retira
  /// uma versão (foi o que aconteceu ao gemini-2.5-flash-lite).
  static const preferredModels = [
    'gemini-flash-latest',
    'gemini-flash-lite-latest',
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
  ];

  /// Modelos disponíveis para cada chave, descobertos uma vez por sessão.
  static final _modelsByKey = <String, Future<List<String>>>{};

  /// Os modelos Flash que esta chave pode usar, pela ordem a tentar.
  Future<List<String>> models() =>
      _modelsByKey[_apiKey] ??= _discoverModels().catchError((Object _) {
        _modelsByKey.remove(_apiKey);
        return preferredModels;
      });

  /// Confirma a chave pedindo a lista de modelos: é rápido e não depende de
  /// os modelos estarem ocupados. Devolve os modelos Flash disponíveis.
  Future<List<String>> validateKey({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final http.Response res;
    try {
      res = await _client
          .get(
            Uri.https('generativelanguage.googleapis.com', '/v1beta/models', {
              'pageSize': '1000',
            }),
            headers: {'x-goog-api-key': _apiKey},
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const GeminiException(
        'A Google não respondeu a tempo. Verifique a internet e tente outra vez.',
      );
    }
    final data = res.body.isEmpty
        ? const <String, dynamic>{}
        : jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) throw _error(res.statusCode, data);
    final ranked = rankModels([
      for (final m in data['models'] as List? ?? const [])
        if ((m['supportedGenerationMethods'] as List? ?? const []).contains(
          'generateContent',
        ))
          (m['name'] as String).replaceFirst('models/', ''),
    ]);
    _modelsByKey[_apiKey] = Future.value(
      ranked.isEmpty ? preferredModels : ranked,
    );
    return ranked;
  }

  Future<List<String>> _discoverModels() async {
    final res = await _client
        .get(
          Uri.https('generativelanguage.googleapis.com', '/v1beta/models', {
            'pageSize': '1000',
          }),
          headers: {'x-goog-api-key': _apiKey},
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      _modelsByKey.remove(_apiKey);
      final data = res.body.isEmpty
          ? const <String, dynamic>{}
          : jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      throw _error(res.statusCode, data);
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final ranked = rankModels([
      for (final m in data['models'] as List? ?? const [])
        if ((m['supportedGenerationMethods'] as List? ?? const []).contains(
          'generateContent',
        ))
          (m['name'] as String).replaceFirst('models/', ''),
    ]);
    // Lista vazia ou estranha: tenta os nomes conhecidos.
    return ranked.isEmpty ? preferredModels : ranked;
  }

  /// Fica só com modelos Flash de texto: primeiro os preferidos, depois os
  /// outros do mais recente para o mais antigo.
  static List<String> rankModels(List<String> available) {
    const skip = [
      'image',
      'tts',
      'audio',
      'live',
      'embedding',
      'vision',
      'thinking',
    ];
    final flash = available
        .where((m) => m.contains('flash') && !skip.any(m.contains))
        .toList();
    double version(String m) =>
        double.tryParse(
          RegExp(r'gemini-(\d+(?:\.\d+)?)').firstMatch(m)?.group(1) ?? '',
        ) ??
        0;
    final rest = flash.where((m) => !preferredModels.contains(m)).toList()
      ..sort((a, b) {
        final v = version(b).compareTo(version(a));
        if (v != 0) return v;
        // Estáveis antes de "preview"/"exp", e Flash antes de Flash-Lite.
        int rank(String m) =>
            (m.contains('preview') || m.contains('exp') ? 2 : 0) +
            (m.contains('lite') ? 1 : 0);
        return rank(a).compareTo(rank(b));
      });
    return [...preferredModels.where(flash.contains), ...rest];
  }

  static const keyUrl = 'https://aistudio.google.com/apikey';

  Future<GeminiResponse> generate(
    String prompt, {
    bool googleSearch = false,
    bool readUrls = false,
    double temperature = 0.2,
  }) async {
    final body = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'tools': [
        if (googleSearch) {'google_search': <String, Object>{}},
        if (readUrls) {'url_context': <String, Object>{}},
      ],
      'generationConfig': {'temperature': temperature},
    });
    GeminiException? last;
    final candidates = await models();
    for (final model in candidates) {
      // Com o modelo sobrecarregado (503), espera um pouco e tenta outra vez
      // antes de passar ao modelo seguinte.
      for (var attempt = 0; attempt < 2; attempt++) {
        if (attempt > 0) await Future<void>.delayed(retryDelay);
        final res = await _client
            .post(
              Uri.https(
                'generativelanguage.googleapis.com',
                '/v1beta/models/$model:generateContent',
              ),
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': _apiKey,
              },
              body: body,
            )
            .timeout(const Duration(seconds: 90));
        final data = res.body.isEmpty
            ? const <String, dynamic>{}
            : jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        if (res.statusCode == 200) return _parse(data);
        last = _error(res.statusCode, data);
        if (res.statusCode == 503 || res.statusCode == 500) continue;
        break;
      }
      // Modelo descontinuado, sem quota ou sobrecarregado: tenta o seguinte.
      if (!(last!.isTemporary || last.status == 404)) throw last;
    }
    // Todos falharam: na próxima vez volta a perguntar à Google a lista.
    _modelsByKey.remove(_apiKey);
    throw last!;
  }

  /// Espera entre tentativas quando o modelo está sobrecarregado.
  static Duration retryDelay = const Duration(seconds: 2);

  static GeminiException _error(int status, Map<String, dynamic> data) {
    final message = (data['error'] as Map?)?['message']?.toString() ?? '';
    if ((status == 400 && message.contains('API key')) || status == 401) {
      return GeminiException(
        'A chave do Gemini não é válida. Confirme que a copiou inteira, '
        'ou crie uma nova no Google AI Studio.',
        status: status,
      );
    }
    if (status == 403) {
      return GeminiException(
        'A chave do Gemini não tem acesso. Confirme-a no Google AI Studio.',
        status: status,
      );
    }
    if (status == 429) {
      return GeminiException(
        'Atingiu o limite gratuito do Gemini por agora. Tente mais tarde.',
        status: status,
      );
    }
    if (status == 503 || status == 500 || status == 504) {
      return GeminiException(
        'O Gemini da Google está com muitos pedidos neste momento (não é '
        'problema da sua chave). Tente daqui a um ou dois minutos.',
        status: status,
      );
    }
    return GeminiException(
      'Erro do Gemini ($status): $message',
      status: status,
    );
  }

  static GeminiResponse _parse(Map<String, dynamic> data) {
    final candidates = data['candidates'] as List? ?? const [];
    if (candidates.isEmpty) {
      throw const GeminiException('O Gemini não devolveu resposta.');
    }
    final c = candidates.first as Map<String, dynamic>;
    final parts = (c['content'] as Map?)?['parts'] as List? ?? const [];
    final text = parts
        .map((p) => (p as Map)['text'])
        .whereType<String>()
        .join();
    final grounding = c['groundingMetadata'] as Map?;
    final sources = <GeminiSource>[
      for (final chunk in grounding?['groundingChunks'] as List? ?? const [])
        if ((chunk as Map)['web'] is Map)
          GeminiSource(
            title: (chunk['web']['title'] ?? chunk['web']['uri']).toString(),
            uri: chunk['web']['uri'].toString(),
          ),
    ];
    return GeminiResponse(
      text: text,
      sources: sources,
      searchQueries: [
        for (final q in grounding?['webSearchQueries'] as List? ?? const [])
          q.toString(),
      ],
    );
  }
}
