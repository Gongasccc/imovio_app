import 'package:imovio/src/features/ai/data/gemini_client.dart';
import 'package:imovio/src/features/ai/data/tavily_client.dart';
import 'package:imovio/src/features/market_study/domain/comparable_listing.dart';
import 'package:imovio/src/features/market_study/domain/market_study.dart';
import 'package:imovio/src/utils/format.dart';

/// Anúncios encontrados numa pesquisa na web, por confirmar.
class AreaSearchResult {
  const AreaSearchResult({
    required this.listings,
    required this.sources,
    required this.queries,
    this.readByAi = false,
  });

  final List<ComparableListing> listings;
  final List<GeminiSource> sources;
  final List<String> queries;

  /// true se o Gemini leu os resultados; false se foram lidos pela app.
  final bool readByAi;
}

/// Portais imobiliários onde procurar.
const _portals = [
  'idealista.pt',
  'imovirtual.com',
  'casa.sapo.pt',
  'supercasa.pt',
  'remax.pt',
  'era.pt',
  'century21.pt',
  'kwportugal.pt',
  'iadportugal.pt',
  'casayes.pt',
];

typedef ListingMaker = ComparableListing Function({
  required String? title,
  required num price,
  required num area,
  String? tipologia,
  String? freguesia,
  String? concelho,
  Conservation? conservation,
  bool garage,
  bool outdoor,
  bool elevator,
  String? url,
});

/// Procura de anúncios na zona e comentário de mercado. A pesquisa é feita
/// pelo Tavily (grátis); o Gemini, se houver chave, lê os resultados. Sem
/// Gemini, ou se ele falhar, a app tira o preço e a área do texto.
class MarketAiService {
  const MarketAiService({this.gemini, this.tavily});
  final GeminiClient? gemini;
  final TavilyClient? tavily;

  Future<AreaSearchResult> searchArea(
    MarketStudy study, {
    required ComparableID Function() newId,
  }) async {
    final tavily = this.tavily;
    if (tavily == null) {
      throw const TavilyException('Falta a chave do Tavily para pesquisar.');
    }
    final p = study.subject.property;
    final rental = study.isRental;
    final what = [p.tipo ?? 'casa', p.tipologia].nonNulls.join(' ');
    final zone = [p.freguesia, p.concelho].nonNulls.join(' ');
    final query =
        '$what ${rental ? 'para arrendar' : 'à venda'} $zone '
                '${p.distrito ?? ''} preço m²'
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
    final results = await tavily.search(
      query,
      domains: _portals,
      rawContent: gemini != null,
    );
    final sources = [
      for (final r in results) GeminiSource(title: r.title, uri: r.url),
    ];
    final today = formatIsoDate(DateTime.now());
    ComparableListing make({
      required String? title,
      required num price,
      required num area,
      String? tipologia,
      String? freguesia,
      String? concelho,
      Conservation? conservation,
      bool garage = false,
      bool outdoor = false,
      bool elevator = false,
      String? url,
    }) => ComparableListing(
      id: newId(),
      title: title ?? '$what em ${p.concelho ?? zone}',
      price: price,
      area: area,
      negocio: p.negocio,
      tipo: p.tipo,
      tipologia: tipologia ?? p.tipologia,
      concelho: concelho ?? p.concelho,
      freguesia: freguesia,
      conservation: conservation,
      garage: garage,
      outdoor: outdoor,
      elevator: elevator,
      sourceUrl: url != null && url.startsWith('http') ? url : null,
      notes: 'Encontrado numa pesquisa na web em $today.',
      date: today,
    );

    if (gemini != null && results.isNotEmpty) {
      try {
        final listings = await _readWithGemini(results, study, make);
        return AreaSearchResult(
          listings: _sane(listings, rental),
          sources: sources,
          queries: [query],
          readByAi: true,
        );
      } on GeminiException {
        // Sem quota ou indisponível: lê os resultados sem IA.
      }
    }
    final fromText = <ComparableListing>[];
    for (final r in results) {
      final c = fromSnippet(r, rental, make);
      if (c != null) fromText.add(c);
    }
    return AreaSearchResult(
      listings: _sane(fromText, rental),
      sources: sources,
      queries: [query],
    );
  }

  Future<List<ComparableListing>> _readWithGemini(
    List<WebResult> results,
    MarketStudy study,
    ListingMaker make,
  ) async {
    final p = study.subject.property;
    final pages = StringBuffer();
    for (final r in results) {
      final raw = r.rawContent ?? '';
      pages
        ..writeln('### ${r.title}')
        ..writeln('URL: ${r.url}')
        ..writeln(r.content)
        ..writeln(raw.length > 4000 ? raw.substring(0, 4000) : raw)
        ..writeln();
    }
    final what = [p.tipo, p.tipologia].nonNulls.join(' ');
    final where = [p.freguesia, p.concelho].nonNulls.join(', ');
    final size = study.subject.area == null
        ? ''
        : ', idealmente com área perto de ${Format.number(study.subject.area)} m²';
    final prompt =
        '''
És assistente de uma agência imobiliária em Portugal. Abaixo estão resultados de uma pesquisa em portais imobiliários.
Procura anúncios de $what ${study.isRental ? 'para arrendar' : 'à venda'} em $where$size.
Responde APENAS com um array JSON de até 15 anúncios distintos encontrados no texto, cada um assim:
{"titulo": string, "preco": número em euros${study.isRental ? ' por mês' : ''}, "area": número m² (útil, ou bruta se for a única), "tipologia": "T0".."T5+" ou null, "freguesia": string ou null, "concelho": string ou null, "estado": "novo"|"renovado"|"usado"|"recuperar"|null, "garagem": true/false, "exterior": true/false, "elevador": true/false, "url": link do anúncio (o URL do resultado se não houver outro)}
Regras: só anúncios que aparecem no texto, com preço e área; não inventes; sem repetidos; ignora preços médios da zona, terrenos e lojas. Se não houver nenhum, responde [].

$pages''';
    final res = await gemini!.generate(prompt, temperature: 0);
    final json = res.json;
    final out = <ComparableListing>[];
    for (final item in json is List ? json : const []) {
      if (item is! Map) continue;
      final price = parseNum(item['preco']);
      final area = parseNum(item['area']);
      if (price == null || area == null) continue;
      out.add(
        make(
          title: _str(item, 'titulo'),
          price: price,
          area: area,
          tipologia: _str(item, 'tipologia'),
          freguesia: _str(item, 'freguesia'),
          concelho: _str(item, 'concelho'),
          conservation: Conservation.fromName(_str(item, 'estado')),
          garage: item['garagem'] == true,
          outdoor: item['exterior'] == true,
          elevator: item['elevador'] == true,
          url: _str(item, 'url'),
        ),
      );
    }
    return out;
  }

  static String? _str(Map item, String k) {
    final v = item[k]?.toString();
    return v == null || v == 'null' ? null : emptyToNull(v);
  }

  /// Lê preço e área do excerto de um anúncio individual, sem IA.
  static ComparableListing? fromSnippet(
    WebResult r,
    bool rental,
    ListingMaker make,
  ) {
    if (!isListingUrl(r.url)) return null;
    final text = '${r.title} ${r.content}';
    final price = parsePrice(text, rental: rental);
    final area = parseArea(text);
    if (price == null || area == null) return null;
    final rooms = RegExp(r'\bT\s?(\d)\b').firstMatch(text)?.group(1);
    return make(
      title: r.title,
      price: price,
      area: area,
      tipologia: rooms == null ? null : 'T$rooms',
      url: r.url,
    );
  }

  /// Página de um anúncio (e não de uma lista de resultados).
  static bool isListingUrl(String url) => RegExp(
    r'idealista\.pt/imovel/\d+|imovirtual\.com/pt/anuncio/|'
    r'casa\.sapo\.pt/.*-\w{8}-|supercasa\.pt/.*/i\d+|remax\.pt/.*/\d|'
    r'era\.pt/imoveis/|century21\.pt/.*ref|kwportugal\.pt/.*imovel|'
    r'iadportugal\.pt/.*/\d+',
    caseSensitive: false,
  ).hasMatch(url);

  /// "250.000 €", "€ 250 000", "1 200 €/mês" → número.
  static num? parsePrice(String text, {required bool rental}) {
    final re = RegExp(
      r'(?:€\s?(\d{1,3}(?:[.\s ]\d{3})+|\d{3,7}))|'
      r'(?:(\d{1,3}(?:[.\s ]\d{3})+|\d{3,7})\s?(?:€|eur\b|euros))',
      caseSensitive: false,
    );
    for (final m in re.allMatches(text)) {
      final v = num.tryParse(
        (m.group(1) ?? m.group(2))!.replaceAll(RegExp(r'[.\s ]'), ''),
      );
      if (v == null) continue;
      if (rental ? (v >= 150 && v <= 20000) : (v >= 15000)) return v;
    }
    return null;
  }

  /// "85 m²", "85m2", "85,5 m2" → número.
  static num? parseArea(String text) {
    for (final m in RegExp(
      r'(\d{2,4}(?:[.,]\d{1,2})?)\s?m(?:²|2)(?![0-9])',
      caseSensitive: false,
    ).allMatches(text)) {
      final v = num.tryParse(m.group(1)!.replaceAll(',', '.'));
      if (v != null && v >= 15 && v <= 2000) return v;
    }
    return null;
  }

  /// Tira valores sem sentido e repetidos (mesmo preço e área).
  static List<ComparableListing> _sane(
    List<ComparableListing> list,
    bool rental,
  ) {
    final seen = <String>{};
    return [
      for (final c in list)
        if (c.price > 0 &&
            c.area >= 15 &&
            (rental
                ? c.pricePerM2 >= 2 && c.pricePerM2 <= 100
                : c.pricePerM2 >= 150 && c.pricePerM2 <= 25000) &&
            seen.add('${c.price}|${c.area}'))
          c,
    ];
  }

  /// Comentário de mercado para o PDF, só com os números do estudo.
  Future<String> writeCommentary(MarketStudy study) async {
    final s = study.subject;
    final p = s.property;
    final unit = study.isRental ? ' por mês' : '';
    final ine = study.ine;
    final lines = <String>[
      'Imóvel: ${p.title}; ${p.tags}; ${[p.freguesia, p.concelho].nonNulls.join(', ')}.',
      'Área: ${Format.number(s.area)} m²; estado ${s.conservation.label}; '
          'garagem ${s.garage ? 'sim' : 'não'}; exterior ${s.outdoor ? 'sim' : 'não'}'
          '${s.isApartment ? '; elevador ${s.elevator ? 'sim' : 'não'}' : ''}.',
      'Preço pedido: ${Format.euros(p.price)}$unit.',
      if (p.featureList.isNotEmpty)
        'Características: ${p.featureList.join(', ')}.',
      for (final r in [ine?.parish, ine?.municipality].nonNulls)
        'INE ${r.levelLabel.toLowerCase()} ${r.name}: mediana de vendas '
            '${Format.euros(study.ineM2(r))}/m² nos últimos 12 meses até ao '
            '${ine!.period}; há um ano ${Format.euros(r.m2PreviousYear)}/m² '
            '(${Format.percent(r.yearlyChange, signed: true)}).',
      'Comparáveis usados:',
      for (final c in study.selected)
        '- ${c.comparable.title}: ${Format.euros(c.comparable.price)}, '
            '${Format.number(c.comparable.area)} m², '
            '${c.comparable.fromPortfolio ? 'carteira' : c.comparable.source.label.toLowerCase()}, '
            '${Format.euros(c.comparable.pricePerM2)}/m² → ajustado '
            '${Format.euros(c.adjustedPricePerM2)}/m² '
            '(${[if (c.negotiation > 0) 'negociação ${Format.percent(-c.negotiation, signed: true)}', for (final e in c.adjustments.entries) '${e.key.toLowerCase()} ${Format.percent(e.value, signed: true)}'].join(', ')}).',
      'Resultado: valor provável ${Format.euros(study.value)}$unit '
          '(${Format.euros(study.pricePerM2)}/m²), intervalo '
          '${Format.euros(study.valueLow)} a ${Format.euros(study.valueHigh)}; '
          'confiança ${study.confidence.label.toLowerCase()}.',
      if (study.askingDeviation != null)
        'Preço pedido face ao valor provável: '
            '${Format.percent(study.askingDeviation, signed: true)}.',
      if ((study.settings.notes ?? '').isNotEmpty)
        'Notas do consultor: ${study.settings.notes}',
    ];
    final prompt =
        '''
És consultor imobiliário em Portugal. Escreve o comentário de mercado de um estudo comparativo, em português de Portugal, para o proprietário ler.
Usa APENAS os dados abaixo; não acrescentes factos, preços ou tendências que não estejam aqui. Cita os números do estudo.
Escreve 3 ou 4 parágrafos curtos, sem títulos nem listas: (1) a zona e a evolução dos preços segundo o INE; (2) o que os comparáveis mostram e porque o imóvel vale mais ou menos do que eles; (3) a recomendação de preço de anúncio e de estratégia${study.selected.length < 3 ? '; (4) avisa que há poucos comparáveis e que o valor deve ser confirmado' : ''}.

Dados do estudo:
${lines.join('\n')}''';
    final gemini = this.gemini;
    if (gemini == null) {
      throw const GeminiException('Falta a chave do Gemini para escrever.');
    }
    final res = await gemini.generate(prompt, temperature: 0.4);
    final text = res.text.trim();
    if (text.isEmpty) {
      throw const GeminiException('O Gemini não escreveu o comentário.');
    }
    return text;
  }
}
