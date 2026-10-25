import 'package:imovio/src/features/ai/data/gemini_client.dart';
import 'package:imovio/src/features/market_study/domain/comparable_listing.dart';
import 'package:imovio/src/features/market_study/domain/market_study.dart';
import 'package:imovio/src/utils/format.dart';

/// Anúncios encontrados pelo Gemini numa pesquisa Google, por confirmar.
class AreaSearchResult {
  const AreaSearchResult({
    required this.listings,
    required this.sources,
    required this.queries,
  });

  final List<ComparableListing> listings;
  final List<GeminiSource> sources;
  final List<String> queries;
}

/// Usos do Gemini no estudo de mercado: procurar anúncios semelhantes na zona
/// e escrever o comentário de mercado a partir dos números do estudo.
class MarketAiService {
  const MarketAiService(this._gemini);
  final GeminiClient _gemini;

  Future<AreaSearchResult> searchArea(
    MarketStudy study, {
    required ComparableID Function() newId,
  }) async {
    final s = study.subject;
    final p = s.property;
    final zone = [p.freguesia, p.concelho, p.distrito].nonNulls.join(', ');
    final rental = study.isRental;
    final what = [
      p.tipo ?? 'casa',
      p.tipologia,
    ].nonNulls.join(' ').toLowerCase();
    final prompt =
        '''
Pesquisa no Google anúncios ATUAIS de $what ${rental ? 'para arrendar' : 'à venda'} em $zone, Portugal${s.area == null ? '' : ', com área parecida a ${Format.number(s.area)} m²'}.
Procura em portais imobiliários (Idealista, Imovirtual, Casa Sapo, Supercasa, RE/MAX, ERA, Century 21, KW, iad).
Responde APENAS com um array JSON de até 10 anúncios distintos que encontraste nos resultados, cada um assim:
{"titulo": string, "preco": número em euros${rental ? ' por mês' : ''}, "area": número m² (área útil, ou bruta se for a única), "tipologia": "T0".."T5+" ou null, "freguesia": string ou null, "concelho": string, "estado": "novo"|"renovado"|"usado"|"recuperar"|null, "garagem": true/false, "exterior": true/false (varanda, terraço, jardim), "elevador": true/false, "url": link do anúncio ou null}
Regras: não inventes anúncios nem valores; só anúncios com preço e área; sem repetidos (o mesmo imóvel em vários portais conta uma vez). Se não encontrares nenhum, responde [].''';
    final res = await _gemini.generate(prompt, googleSearch: true);
    final json = res.json;
    final today = formatIsoDate(DateTime.now());
    final listings = <ComparableListing>[];
    for (final item in json is List ? json : const []) {
      if (item is! Map) continue;
      final price = parseNum(item['preco']);
      final area = parseNum(item['area']);
      if (price == null || area == null || price <= 0 || area < 15) continue;
      // Descarta valores sem sentido (erros de leitura do anúncio).
      final m2 = price / area;
      if (rental ? (m2 < 2 || m2 > 100) : (m2 < 150 || m2 > 25000)) continue;
      String? str(String k) {
        final v = item[k]?.toString();
        return v == null || v == 'null' ? null : emptyToNull(v);
      }

      final url = str('url');
      listings.add(
        ComparableListing(
          id: newId(),
          title: str('titulo') ?? '$what em ${p.concelho ?? zone}',
          price: price,
          area: area,
          negocio: p.negocio,
          tipo: p.tipo,
          tipologia: str('tipologia') ?? p.tipologia,
          concelho: str('concelho') ?? p.concelho,
          freguesia: str('freguesia'),
          conservation: Conservation.fromName(str('estado')),
          garage: item['garagem'] == true,
          outdoor: item['exterior'] == true,
          elevator: item['elevador'] == true,
          sourceUrl: url != null && url.startsWith('http') ? url : null,
          notes: 'Encontrado pelo Gemini numa pesquisa Google em $today.',
          date: today,
        ),
      );
    }
    return AreaSearchResult(
      listings: listings,
      sources: res.sources,
      queries: res.searchQueries,
    );
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
    final res = await _gemini.generate(prompt, temperature: 0.4);
    final text = res.text.trim();
    if (text.isEmpty) {
      throw const GeminiException('O Gemini não escreveu o comentário.');
    }
    return text;
  }
}
