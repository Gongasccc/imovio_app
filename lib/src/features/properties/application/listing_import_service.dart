import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:imovio/src/features/properties/application/listing_parser.dart';

export 'package:imovio/src/features/properties/application/listing_parser.dart'
    show ImportedListing;

part 'listing_import_service.g.dart';

/// Importa um anúncio a partir do link. A página é lida através de serviços
/// públicos (o browser não pode ler outros sites diretamente): primeiro o
/// Microlink, depois o AllOrigins e o CodeTabs. O [ListingParser] analisa o
/// HTML e os metadados do Microlink completam o que faltar.
///
/// Quando o preço não aparece no anúncio, fica vazio (a app original
/// inventava 350 000 €).
class ListingImportService {
  ListingImportService(this._client);
  final http.Client _client;

  static const _timeout = Duration(seconds: 15);

  Future<ImportedListing> extract(String url) async {
    final html = await _fetchHtml(url);
    if (html != null) return ListingParser.parse(html);
    // Sem HTML: pelo menos título, descrição e capa via metadados.
    return _microlink(url);
  }

  /// Tenta vários proxies até um devolver a página.
  Future<String?> _fetchHtml(String url) async {
    final encoded = Uri.encodeComponent(url);
    final attempts = <Future<String?> Function()>[
      // Microlink devolve o HTML completo da página (inclui o JSON-LD).
      () async {
        final res = await _client
            .get(Uri.parse('https://api.microlink.io/?url=$encoded'
                '&data.html.selector=html&data.html.attr=html&meta=false'))
            .timeout(const Duration(seconds: 30));
        if (res.statusCode != 200) return null;
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final data = json['data'];
        return data is Map ? data['html'] as String? : null;
      },
      () async {
        final res = await _client
            .get(Uri.parse('https://api.allorigins.win/get?url=$encoded'))
            .timeout(_timeout);
        if (res.statusCode != 200) return null;
        return (jsonDecode(res.body) as Map<String, dynamic>)['contents']
            as String?;
      },
      () async {
        final res = await _client
            .get(Uri.parse('https://api.codetabs.com/v1/proxy?quest=$encoded'))
            .timeout(_timeout);
        return res.statusCode == 200 ? utf8.decode(res.bodyBytes) : null;
      },
    ];
    for (final attempt in attempts) {
      try {
        final html = await attempt();
        // Páginas de captcha ou bloqueio são curtas e sem meta tags.
        if (html != null && html.length > 2000 && html.contains('<meta')) {
          return html;
        }
      } catch (_) {
        // Tenta o seguinte.
      }
    }
    return null;
  }

  Future<ImportedListing> _microlink(String url) async {
    try {
      final res = await _client
          .get(Uri.parse(
              'https://api.microlink.io/?url=${Uri.encodeComponent(url)}'))
          .timeout(_timeout);
      if (res.statusCode != 200) return const ImportedListing();
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (json['status'] != 'success' || json['data'] is! Map) {
        return const ImportedListing();
      }
      final data = json['data'] as Map<String, dynamic>;
      final img = data['image'];
      final title = data['title'] as String?;
      final description = data['description'] as String?;
      return ListingParser.parseText(title: title, description: description)
          .merge(ImportedListing(
        images: [
          if (img is Map && img['url'] is String) img['url'] as String,
        ],
      ));
    } catch (_) {
      return const ImportedListing();
    }
  }
}

@Riverpod(keepAlive: true)
ListingImportService listingImportService(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return ListingImportService(client);
}
