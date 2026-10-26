import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Um resultado de pesquisa na web.
class WebResult {
  const WebResult({
    required this.title,
    required this.url,
    required this.content,
    this.rawContent,
  });

  final String title;
  final String url;

  /// Excerto relevante da página.
  final String content;

  /// Texto da página inteira, quando pedido.
  final String? rawContent;
}

class TavilyException implements Exception {
  const TavilyException(this.message, {this.status});
  final String message;
  final int? status;

  @override
  String toString() => message;
}

/// Pesquisa na web com o Tavily (motor de pesquisa para IA). O plano grátis
/// dá 1000 créditos por mês, sem cartão; cada pesquisa avançada gasta 2.
/// A API aceita pedidos do browser, por isso a app chama-a diretamente com a
/// chave do próprio utilizador.
class TavilyClient {
  TavilyClient(this._client, this._apiKey);
  final http.Client _client;
  final String _apiKey;

  static const keyUrl = 'https://app.tavily.com';

  Future<List<WebResult>> search(
    String query, {
    List<String> domains = const [],
    int maxResults = 20,
    bool rawContent = false,
    bool advanced = true,
  }) async {
    final http.Response res;
    try {
      res = await _client
          .post(
            Uri.https('api.tavily.com', '/search'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'query': query,
              'search_depth': advanced ? 'advanced' : 'basic',
              'max_results': maxResults,
              'include_raw_content': rawContent ? 'text' : false,
              if (domains.isNotEmpty) 'include_domains': domains,
              'country': 'portugal',
            }),
          )
          .timeout(const Duration(seconds: 60));
    } on TimeoutException {
      throw const TavilyException(
        'A pesquisa demorou demasiado. Tente outra vez.',
      );
    }
    final data = res.body.isEmpty
        ? const <String, dynamic>{}
        : jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode != 200) throw _error(res.statusCode, data);
    return [
      for (final r in (data as Map)['results'] as List? ?? const [])
        WebResult(
          title: (r['title'] ?? '').toString(),
          url: (r['url'] ?? '').toString(),
          content: (r['content'] ?? '').toString(),
          rawContent: r['raw_content']?.toString(),
        ),
    ];
  }

  /// Confirma a chave com uma pesquisa mínima (gasta 1 crédito).
  Future<void> validateKey() =>
      search('casas à venda Lisboa', maxResults: 1, advanced: false);

  static TavilyException _error(int status, Object? data) {
    final detail = data is Map ? (data['detail'] ?? data['error']) : null;
    final message = detail is Map
        ? (detail['error'] ?? detail).toString()
        : (detail ?? '').toString();
    if (status == 401 || status == 403) {
      return TavilyException(
        'A chave do Tavily não é válida. Copie-a outra vez em app.tavily.com.',
        status: status,
      );
    }
    if (status == 429 || status == 432 || status == 433) {
      return TavilyException(
        'Acabaram as pesquisas grátis do Tavily deste mês '
        '(1000 créditos). Voltam no início do próximo mês.',
        status: status,
      );
    }
    return TavilyException(
      'Erro na pesquisa ($status): $message',
      status: status,
    );
  }
}
