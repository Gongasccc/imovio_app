import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'listing_import_service.g.dart';

/// Dados extraídos de um anúncio público.
class ImportedListing {
  const ImportedListing({
    this.title,
    this.description,
    this.price,
    this.image,
    this.negocio,
    this.tipo,
    this.tipologia,
  });
  final String? title;
  final String? description;
  final num? price;
  final String? image;
  final String? negocio;
  final String? tipo;
  final String? tipologia;

  bool get isEmpty => title == null && description == null && image == null;
}

/// Lê o título, descrição, imagem e preço de um anúncio, como a função
/// `extrairDadosLink` da app original: primeiro via Microlink, depois lendo
/// as meta tags do HTML via AllOrigins.
///
/// Diferença: quando não encontra preço, deixa-o vazio em vez de inventar
/// 350 000 €.
class ListingImportService {
  ListingImportService(this._client);
  final http.Client _client;

  Future<ImportedListing> extract(String url) async {
    String? title, description, image;

    try {
      final res = await _client.get(Uri.parse(
          'https://api.microlink.io/?url=${Uri.encodeComponent(url)}'));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 'success' && json['data'] is Map) {
          final data = json['data'] as Map<String, dynamic>;
          title = _clean(data['title']);
          description = _clean(data['description']);
          final img = data['image'];
          if (img is Map) image = _clean(img['url']);
        }
      }
    } catch (_) {
      // Tenta a segunda fonte.
    }

    if (title == null || image == null) {
      try {
        final res = await _client.get(Uri.parse(
            'https://api.allorigins.win/get?url=${Uri.encodeComponent(url)}'));
        if (res.statusCode == 200) {
          final json = jsonDecode(res.body) as Map<String, dynamic>;
          final html = json['contents'] as String? ?? '';
          title ??= metaContent(html, 'og:title') ?? _htmlTitle(html);
          image ??= metaContent(html, 'og:image') ??
              metaContent(html, 'twitter:image');
          description ??= metaContent(html, 'og:description');
        }
      } catch (_) {
        // Sem dados extra.
      }
    }

    return fromText(title: title, description: description, image: image);
  }

  /// Deduz preço, negócio, tipo e tipologia a partir do texto do anúncio.
  static ImportedListing fromText({
    String? title,
    String? description,
    String? image,
  }) {
    final text = '${title ?? ''} ${description ?? ''}';
    final lower = text.toLowerCase();
    num? price;
    final match =
        RegExp(r'(\d{1,3}(?:[.\s]\d{3})+|\d{4,})\s*€').firstMatch(text);
    if (match != null) {
      price = num.tryParse(match.group(1)!.replaceAll(RegExp(r'[.\s]'), ''));
    }
    final tipologia =
        RegExp(r'\bT([0-9])\b', caseSensitive: false).firstMatch(text);
    String? tipo;
    if (lower.contains('terreno')) {
      tipo = 'Terreno';
    } else if (lower.contains('moradia')) {
      tipo = 'Moradia';
    } else if (lower.contains('apartamento')) {
      tipo = 'Apartamento';
    } else if (title != null) {
      tipo = 'Casa';
    }
    // A app original cortava o título no primeiro "|" ou "-".
    final shortTitle = title?.split('|').first.split(' - ').first.trim();
    return ImportedListing(
      title: (shortTitle?.isEmpty ?? true) ? title : shortTitle,
      description: description,
      price: price,
      image: image,
      negocio: title == null && description == null
          ? null
          : (lower.contains('arrenda') ? 'Arrendamento' : 'Venda'),
      tipo: tipo,
      tipologia: tipologia == null
          ? null
          : (int.parse(tipologia.group(1)!) >= 5
              ? 'T5+'
              : 'T${tipologia.group(1)}'),
    );
  }

  static String? metaContent(String html, String property) {
    final escaped = RegExp.escape(property);
    final patterns = [
      RegExp('<meta[^>]+(?:property|name)=["\']$escaped["\'][^>]*content=["\']([^"\']*)["\']',
          caseSensitive: false),
      RegExp('<meta[^>]+content=["\']([^"\']*)["\'][^>]*(?:property|name)=["\']$escaped["\']',
          caseSensitive: false),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(html);
      if (m != null) return _clean(_unescape(m.group(1)));
    }
    return null;
  }

  static String? _htmlTitle(String html) {
    final m = RegExp(r'<title[^>]*>([^<]*)</title>', caseSensitive: false)
        .firstMatch(html);
    return _clean(_unescape(m?.group(1)));
  }

  static String? _unescape(String? s) => s
      ?.replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&euro;', '€')
      .replaceAll('&nbsp;', ' ');

  static String? _clean(Object? s) {
    final t = s?.toString().trim();
    return (t == null || t.isEmpty) ? null : t;
  }
}

@Riverpod(keepAlive: true)
ListingImportService listingImportService(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return ListingImportService(client);
}
