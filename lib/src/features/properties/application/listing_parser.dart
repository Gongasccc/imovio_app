import 'dart:convert';

/// Dados extraídos de um anúncio público. Campos a null não foram encontrados.
class ImportedListing {
  const ImportedListing({
    this.title,
    this.description,
    this.price,
    this.images = const [],
    this.negocio,
    this.tipo,
    this.tipologia,
    this.areaBruta,
    this.areaUtil,
    this.areaTerreno,
    this.quartos,
    this.wc,
    this.cp,
    this.distrito,
    this.concelho,
    this.freguesia,
    this.morada,
    this.caracteristicas = const [],
    this.energyCertificate,
    this.year,
  });

  final String? title;
  final String? description;
  final num? price;
  final List<String> images;
  final String? negocio;
  final String? tipo;
  final String? tipologia;
  final num? areaBruta;
  final num? areaUtil;
  final num? areaTerreno;
  final int? quartos;
  final int? wc;
  final String? cp;
  final String? distrito;
  final String? concelho;
  final String? freguesia;
  final String? morada;
  final List<String> caracteristicas;
  final String? energyCertificate;
  final int? year;

  String? get image => images.isEmpty ? null : images.first;

  bool get isEmpty => title == null && description == null && images.isEmpty;

  /// Quantos campos foram preenchidos, para mostrar ao utilizador.
  int get filledCount => [
        title,
        description,
        price,
        image,
        negocio,
        tipo,
        tipologia,
        areaBruta,
        areaUtil,
        areaTerreno,
        quartos,
        wc,
        cp,
        concelho,
        freguesia,
        morada,
      ].where((v) => v != null).length;

  /// Junta dois resultados: os valores deste ganham, os de [other] completam.
  ImportedListing merge(ImportedListing other) => ImportedListing(
        title: title ?? other.title,
        description: _longer(description, other.description),
        price: price ?? other.price,
        images: {...images, ...other.images}.toList(),
        negocio: negocio ?? other.negocio,
        tipo: tipo ?? other.tipo,
        tipologia: tipologia ?? other.tipologia,
        areaBruta: areaBruta ?? other.areaBruta,
        areaUtil: areaUtil ?? other.areaUtil,
        areaTerreno: areaTerreno ?? other.areaTerreno,
        quartos: quartos ?? other.quartos,
        wc: wc ?? other.wc,
        cp: cp ?? other.cp,
        distrito: distrito ?? other.distrito,
        concelho: concelho ?? other.concelho,
        freguesia: freguesia ?? other.freguesia,
        morada: morada ?? other.morada,
        caracteristicas: {...caracteristicas, ...other.caracteristicas}.toList(),
        energyCertificate: energyCertificate ?? other.energyCertificate,
        year: year ?? other.year,
      );

  static String? _longer(String? a, String? b) {
    if (a == null) return b;
    if (b == null) return a;
    return b.length > a.length ? b : a;
  }
}

/// Lê um anúncio imobiliário a partir do HTML da página, por esta ordem de
/// confiança:
/// 1. dados estruturados JSON-LD (schema.org), que os portais publicam para o
///    Google (preço, áreas, quartos, morada, fotos);
/// 2. meta tags Open Graph (título, descrição, fotos, preço);
/// 3. o texto visível da página (expressões como "Área bruta: 120 m²").
class ListingParser {
  static const maxImages = 15;

  static ImportedListing parse(String html) {
    final jsonLd = _fromJsonLd(html);
    final meta = _fromMeta(html);
    final text = _stripTags(html);
    final fromText = parseText(
      title: meta.title ?? jsonLd.title,
      description: '${meta.description ?? ''} ${jsonLd.description ?? ''}',
      body: text,
    );
    // Fotos soltas no HTML só contam se vierem do mesmo servidor da capa:
    // evita logótipos, bandeiras e ícones do próprio site.
    final coverHost = Uri.tryParse(meta.image ?? jsonLd.image ?? '')?.host;
    final images = _imagesFromHtml(html)
        .where((u) => coverHost == null || Uri.tryParse(u)?.host == coverHost)
        .toList();
    return jsonLd
        .merge(meta)
        .merge(fromText)
        .merge(ImportedListing(images: images))
        // A og:image é a capa escolhida pelo portal: vem primeiro.
        .withImages((all) => dedupeImages([...meta.images, ...all]));
  }

  /// A mesma foto aparece em vários tamanhos (`?width=390`, `?width=1200`):
  /// fica a primeira de cada, que costuma ser a maior (og:image / JSON-LD).
  static List<String> dedupeImages(List<String> urls) {
    final seen = <String>{};
    final out = <String>[];
    for (final raw in urls) {
      // Miniaturas (?width=260) passam a versão grande.
      final url = raw.replaceAll('&amp;', '&').replaceAllMapped(
          RegExp(r'([?&](?:w|width)=)\d{2,3}(?!\d)'), (m) => '${m[1]}1200');
      final key = url.split('?').first.toLowerCase();
      if (seen.add(key)) out.add(url);
      if (out.length == maxImages) break;
    }
    return out;
  }

  /// Deduções a partir de texto livre (título, descrição e corpo da página).
  static ImportedListing parseText({
    String? title,
    String? description,
    String body = '',
  }) {
    final head = '${title ?? ''} ${description ?? ''}';
    final all = '$head $body';
    final lower = all.toLowerCase();
    final headLower = head.toLowerCase();

    String? tipo;
    for (final (word, value) in const [
      ('terreno', 'Terreno'),
      ('moradia', 'Moradia'),
      ('vivenda', 'Moradia'),
      ('apartamento', 'Apartamento'),
      ('casa', 'Casa'),
    ]) {
      if (headLower.contains(word)) {
        tipo = value;
        break;
      }
    }

    final tipologiaMatch =
        RegExp(r'\bT\s?([0-9]{1,2})\b', caseSensitive: false).firstMatch(head) ??
            RegExp(r'\bT\s?([0-9]{1,2})\b').firstMatch(body);
    final quartos = _int(lower, [
      r'(\d{1,2})\s*quartos?\b',
      r'quartos?\s*[:\-]?\s*(\d{1,2})\b',
    ]);
    final tipologia = tipologiaMatch != null
        ? _tipologia(int.parse(tipologiaMatch.group(1)!))
        : (quartos != null ? _tipologia(quartos) : null);

    final cp = RegExp(r'\b(\d{4}-\d{3})\b').firstMatch(all)?.group(1);
    final cert = RegExp(
      r'certifica(?:do|ção)\s+energ[ée]tic[oa]\s*[:\-]?\s*(A\+|[A-F][+-]?)(?=[\s.,;)<]|$)',
      caseSensitive: false,
    ).firstMatch(all)?.group(1)?.toUpperCase();
    final year = _int(lower, [r'ano\s+de\s+constru[çc][ãa]o\s*[:\-]?\s*((?:19|20)\d{2})']);

    return ImportedListing(
      title: _shortTitle(title),
      description: _clean(description),
      price: _price(head) ?? _price(body),
      negocio: headLower.contains('arrend') || headLower.contains('alug')
          ? 'Arrendamento'
          : (head.trim().isEmpty ? null : 'Venda'),
      tipo: tipo,
      tipologia: tipologia,
      areaBruta: _area(lower, ['área bruta', 'area bruta', 'abp']),
      areaUtil: _area(lower, ['área útil', 'area util', 'área habitável']),
      areaTerreno: _area(lower, ['área do terreno', 'área de terreno', 'terreno']),
      quartos: quartos,
      wc: _int(lower, [
        r'(\d{1,2})\s*(?:casas?\s+de\s+banho|wc|w\.c\.|banhos?)\b',
        r'(?:casas?\s+de\s+banho|wc)\s*[:\-]?\s*(\d{1,2})\b',
      ]),
      cp: cp,
      caracteristicas: _features(lower),
      energyCertificate: cert,
      year: year,
    );
  }

  // --- JSON-LD -------------------------------------------------------------

  static ImportedListing _fromJsonLd(String html) {
    final scripts = RegExp(
      r'<script[^>]*type=["' "'" r']application/ld\+json["' "'" r'][^>]*>([\s\S]*?)</script>',
      caseSensitive: false,
    ).allMatches(html);
    var result = const ImportedListing();
    for (final m in scripts) {
      try {
        final decoded = jsonDecode(m.group(1)!.trim());
        for (final node in _nodes(decoded)) {
          result = result.merge(_fromSchemaNode(node));
        }
      } catch (_) {
        // JSON inválido: ignora este bloco.
      }
    }
    return result;
  }

  /// Todos os objetos de um grafo JSON-LD (incluindo @graph e listas).
  static Iterable<Map<String, dynamic>> _nodes(Object? value) sync* {
    if (value is List) {
      for (final v in value) {
        yield* _nodes(v);
      }
    } else if (value is Map<String, dynamic>) {
      yield value;
      for (final key in ['@graph', 'mainEntity', 'itemOffered', 'about']) {
        if (value[key] != null) yield* _nodes(value[key]);
      }
    }
  }

  static const _listingTypes = [
    'product',
    'offer',
    'realestatelisting',
    'residence',
    'house',
    'apartment',
    'singlefamilyresidence',
    'accommodation',
    'place',
    'landform',
  ];

  static ImportedListing _fromSchemaNode(Map<String, dynamic> n) {
    final types = [n['@type']].expand((t) => t is List ? t : [t]);
    final isListing = types
        .whereType<String>()
        .any((t) => _listingTypes.contains(t.toLowerCase()));
    if (!isListing) return const ImportedListing();

    num? price;
    final offers = n['offers'];
    for (final o in [offers].expand((o) => o is List ? o : [o])) {
      if (o is Map) price ??= _num(o['price'] ?? o['lowPrice']);
    }
    price ??= _num(n['price']);

    final address = n['address'] ?? (n['location'] is Map ? n['location']['address'] : null);
    String? locality, region, postal, street;
    if (address is Map) {
      locality = _clean(address['addressLocality']);
      region = _clean(address['addressRegion']);
      postal = _clean(address['postalCode']);
      street = _clean(address['streetAddress']);
    }

    final floor = n['floorSize'];
    return ImportedListing(
      title: _shortTitle(_clean(n['name'])),
      description: _clean(n['description']),
      price: price,
      images: _schemaImages(n['image'] ?? n['photo']),
      areaUtil: floor is Map ? _num(floor['value']) : _num(floor),
      quartos: _toInt(n['numberOfBedrooms'] ?? n['numberOfRooms']),
      wc: _toInt(n['numberOfBathroomsTotal'] ?? n['numberOfFullBathrooms']),
      cp: postal != null && RegExp(r'^\d{4}-\d{3}$').hasMatch(postal) ? postal : null,
      concelho: locality,
      distrito: region,
      morada: street,
    );
  }

  static List<String> _schemaImages(Object? value) {
    final out = <String>[];
    void add(Object? v) {
      if (v is String && v.startsWith('http')) out.add(v);
      if (v is Map) add(v['url'] ?? v['contentUrl']);
      if (v is List) v.forEach(add);
    }

    add(value);
    return out;
  }

  // --- Meta tags -----------------------------------------------------------

  static ImportedListing _fromMeta(String html) {
    final images = [
      ...metaContents(html, 'og:image'),
      ...metaContents(html, 'og:image:secure_url'),
      ...metaContents(html, 'twitter:image'),
    ].where((u) => u.startsWith('http')).toList();
    final price = _num(metaContent(html, 'product:price:amount') ??
        metaContent(html, 'og:price:amount'));
    return ImportedListing(
      title: _shortTitle(metaContent(html, 'og:title') ?? _htmlTitle(html)),
      description: metaContent(html, 'og:description') ??
          metaContent(html, 'description'),
      price: price,
      images: images,
    );
  }

  static String? metaContent(String html, String property) {
    final all = metaContents(html, property);
    return all.isEmpty ? null : all.first;
  }

  static List<String> metaContents(String html, String property) {
    final p = RegExp.escape(property);
    const q = '["\']';
    final patterns = [
      RegExp('<meta[^>]+(?:property|name)=$q$p$q[^>]*content=$q([^"\']*)$q',
          caseSensitive: false),
      RegExp('<meta[^>]+content=$q([^"\']*)$q[^>]*(?:property|name)=$q$p$q',
          caseSensitive: false),
    ];
    return [
      for (final pattern in patterns)
        for (final m in pattern.allMatches(html))
          ?_clean(_unescape(m.group(1))),
    ];
  }

  static String? _htmlTitle(String html) => _clean(_unescape(
      RegExp(r'<title[^>]*>([^<]*)</title>', caseSensitive: false)
          .firstMatch(html)
          ?.group(1)));

  // --- Imagens no corpo ----------------------------------------------------

  static List<String> _imagesFromHtml(String html) {
    final urls = RegExp(
      r'https?:\/\/[^"' "'" r'\s()<>]+?\.(?:jpe?g|webp)(?:\?[^"' "'" r'\s<>]*)?',
      caseSensitive: false,
    ).allMatches(html).map((m) => m.group(0)!.replaceAll(r'\/', '/'));
    const skip = ['/_nuxt/', '/static/', '/assets/', 'flag', 'logo', 'icon', 'sprite', 'avatar', 'banner', 'favicon', 'placeholder', 'agent', 'agente'];
    return urls
        .where((u) => !skip.any(u.toLowerCase().contains))
        .toSet()
        .toList();
  }

  // --- Ajudantes -----------------------------------------------------------

  static num? _price(String text) {
    final patterns = [
      RegExp(r'(\d{1,3}(?:[.\s ]\d{3})+|\d{4,})(?:,\d{2})?\s*(?:€|eur\b|euros?)',
          caseSensitive: false),
      RegExp(r'€\s*(\d{1,3}(?:[.\s ]\d{3})+|\d{4,})'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        final v = num.tryParse(m.group(1)!.replaceAll(RegExp(r'[.\s ]'), ''));
        if (v != null && v >= 100) return v;
      }
    }
    return null;
  }

  static num? _area(String lower, List<String> labels) {
    for (final label in labels) {
      final m = RegExp(
        '${RegExp.escape(label)}\\s*(?:\\([^)]*\\))?\\s*[:\\-]?\\s*(\\d{1,6}(?:[.,]\\d{1,2})?)\\s*m(?:²|2|\\b)',
      ).firstMatch(lower);
      if (m != null) return num.tryParse(m.group(1)!.replaceAll(',', '.'));
    }
    return null;
  }

  static int? _int(String lower, List<String> patterns) {
    for (final p in patterns) {
      final m = RegExp(p).firstMatch(lower);
      if (m != null) return int.tryParse(m.group(1)!);
    }
    return null;
  }

  static String _tipologia(int n) => n >= 5 ? 'T5+' : 'T$n';

  static const _featureWords = {
    'garagem': 'garagem',
    'estacionamento': 'estacionamento',
    'piscina': 'piscina',
    'varanda': 'varanda',
    'terraço': 'terraço',
    'jardim': 'jardim',
    'elevador': 'elevador',
    'arrecadação': 'arrecadação',
    'ar condicionado': 'ar condicionado',
    'aquecimento central': 'aquecimento central',
    'lareira': 'lareira',
    'painéis solares': 'painéis solares',
    'vista mar': 'vista mar',
    'vista rio': 'vista rio',
    'condomínio fechado': 'condomínio fechado',
    'cozinha equipada': 'cozinha equipada',
    'mobilado': 'mobilado',
    'suite': 'suite',
    'suíte': 'suite',
    'sótão': 'sótão',
    'porteiro': 'porteiro',
  };

  static List<String> _features(String lower) => {
        for (final e in _featureWords.entries)
          if (lower.contains(e.key)) e.value,
      }.toList();

  /// A app original cortava o título no primeiro "|" ou " - ".
  static String? _shortTitle(String? title) {
    final t = _clean(title);
    if (t == null) return null;
    final short = t.split('|').first.split(' - ').first.trim();
    return short.isEmpty ? t : short;
  }

  static String _stripTags(String html) => _unescape(html
          .replaceAll(RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), ' ')
          .replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), ' ')
          .replaceAll(RegExp(r'<[^>]+>'), ' '))!
      .replaceAll(RegExp(r'\s+'), ' ');

  static String? _unescape(String? s) => s
      ?.replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&#x27;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&euro;', '€')
      .replaceAll('&#8364;', '€')
      .replaceAll('&sup2;', '²')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&aacute;', 'á')
      .replaceAll('&eacute;', 'é')
      .replaceAll('&iacute;', 'í')
      .replaceAll('&oacute;', 'ó')
      .replaceAll('&uacute;', 'ú')
      .replaceAll('&atilde;', 'ã')
      .replaceAll('&otilde;', 'õ')
      .replaceAll('&ccedil;', 'ç')
      .replaceAll('&ecirc;', 'ê')
      .replaceAll('&ocirc;', 'ô');

  static String? _clean(Object? s) {
    final t = s?.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  static num? _num(Object? v) {
    if (v is num) return v;
    if (v == null) return null;
    final s = v.toString().replaceAll(RegExp(r'[^\d.,]'), '');
    if (s.isEmpty) return null;
    // "350.000" ou "350,000" (milhares) vs "85.5" (decimal)
    if (RegExp(r'^\d{1,3}([.,]\d{3})+$').hasMatch(s)) {
      return num.tryParse(s.replaceAll(RegExp('[.,]'), ''));
    }
    return num.tryParse(s.replaceAll(',', '.'));
  }

  static int? _toInt(Object? v) => _num(v)?.round();
}

extension ImportedListingImages on ImportedListing {
  ImportedListing withImages(List<String> Function(List<String>) f) =>
      ImportedListing(
          title: title,
          description: description,
          price: price,
          images: f(images),
          negocio: negocio,
          tipo: tipo,
          tipologia: tipologia,
          areaBruta: areaBruta,
          areaUtil: areaUtil,
          areaTerreno: areaTerreno,
          quartos: quartos,
          wc: wc,
          cp: cp,
          distrito: distrito,
          concelho: concelho,
          freguesia: freguesia,
          morada: morada,
          caracteristicas: caracteristicas,
          energyCertificate: energyCertificate,
          year: year,
        );
}
