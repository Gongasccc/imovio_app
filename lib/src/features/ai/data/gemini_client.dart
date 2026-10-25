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
  const GeminiException(this.message);
  final String message;

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

  /// Por ordem de preferência; se um deixar de existir, usa o seguinte.
  static const models = ['gemini-2.5-flash', 'gemini-2.5-flash-lite'];

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
    for (final model in models) {
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
      // Modelo descontinuado ou sem quota: tenta o seguinte.
      if (res.statusCode != 404 && res.statusCode != 429) throw last;
    }
    throw last!;
  }

  static GeminiException _error(int status, Map<String, dynamic> data) {
    final message = (data['error'] as Map?)?['message']?.toString() ?? '';
    if (status == 400 && message.contains('API key')) {
      return const GeminiException(
        'A chave do Gemini não é válida. Crie uma nova no Google AI Studio.',
      );
    }
    if (status == 403) {
      return const GeminiException(
        'A chave do Gemini não tem acesso. Confirme-a no Google AI Studio.',
      );
    }
    if (status == 429) {
      return const GeminiException(
        'Atingiu o limite gratuito diário do Gemini. Tente amanhã.',
      );
    }
    return GeminiException('Erro do Gemini ($status): $message');
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
