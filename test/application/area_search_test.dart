import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:imovio/src/features/ai/data/gemini_client.dart';
import 'package:imovio/src/features/ai/data/tavily_client.dart';
import 'package:imovio/src/features/market_study/application/market_ai_service.dart';
import 'package:imovio/src/features/market_study/application/market_study_calculator.dart';
import 'package:imovio/src/features/market_study/domain/market_study.dart';
import 'package:imovio/src/features/market_study/domain/study_settings.dart';
import 'package:imovio/src/features/properties/domain/property.dart';

const _property = Property(
  id: 'p',
  title: 'T2',
  price: 250000,
  negocio: 'Venda',
  tipo: 'Apartamento',
  tipologia: 'T2',
  areaUtil: 98,
  concelho: 'Braga',
  freguesia: 'São Vicente',
);

MarketStudy _study() => MarketStudyCalculator.compute(
  property: _property,
  settings: const StudySettings(),
  comparables: const [],
);

/// Resposta do Tavily com um anúncio individual e uma página de lista.
http.Response _tavily() => http.Response(
  jsonEncode({
    'query': 'x',
    'results': [
      {
        'title': 'Apartamento T2 à venda em São Vicente, Braga',
        'url': 'https://www.idealista.pt/imovel/12345678/',
        'content':
            'Apartamento T2 com 92 m² úteis, 2.º andar com elevador. '
            '235.000 € · garagem',
        'raw_content': 'Apartamento T2 ... 235.000 € ... 92 m²',
      },
      {
        'title': 'Apartamentos T2 à venda em Braga — Imovirtual',
        'url': 'https://www.imovirtual.com/pt/resultados/comprar/apartamento/braga',
        'content': 'Preço médio 2.300 €/m². 120 anúncios.',
        'raw_content':
            'T2 Maximinos 210 000 € 95 m2 ... T2 Lamaçães 260 000 € 100 m2',
      },
    ],
  }),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

http.Response _gemini(String text) => http.Response(
  jsonEncode({
    'candidates': [
      {
        'content': {
          'parts': [
            {'text': text},
          ],
        },
      },
    ],
  }),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  setUp(() => GeminiClient.retryDelay = Duration.zero);

  var n = 0;
  String newId() => 'id${n++}';

  test('pesquisa no Tavily nos portais e o Gemini lê a lista', () async {
    late Map<String, dynamic> tavilyBody;
    final client = MockClient((req) async {
      if (req.url.host == 'api.tavily.com') {
        expect(req.headers['authorization'], 'Bearer tvly-teste');
        tavilyBody = jsonDecode(req.body) as Map<String, dynamic>;
        return _tavily();
      }
      if (req.url.path.endsWith('/models')) {
        return http.Response(
          jsonEncode({
            'models': [
              {
                'name': 'models/gemini-flash-latest',
                'supportedGenerationMethods': ['generateContent'],
              },
            ],
          }),
          200,
        );
      }
      // O Gemini recebe o texto da página de lista, sem pesquisa Google.
      final body = jsonDecode(req.body) as Map;
      expect(body['tools'], isEmpty);
      expect(req.body, contains('T2 Lamaçães'));
      return _gemini(
        jsonEncode([
          {'titulo': 'T2 Maximinos', 'preco': 210000, 'area': 95},
          {'titulo': 'T2 Lamaçães', 'preco': 260000, 'area': 100},
          {'titulo': 'Preço médio', 'preco': 2300, 'area': 1},
        ]),
      );
    });
    final res = await MarketAiService(
      gemini: GeminiClient(client, 'g'),
      tavily: TavilyClient(client, 'tvly-teste'),
    ).searchArea(_study(), newId: newId);
    expect(
      tavilyBody['query'],
      contains('Apartamento T2 à venda São Vicente Braga'),
    );
    expect(tavilyBody['include_domains'], contains('idealista.pt'));
    expect(res.readByAi, isTrue);
    expect(res.listings.map((c) => c.title), ['T2 Maximinos', 'T2 Lamaçães']);
    expect(res.sources, hasLength(2));
  });

  test('sem quota do Gemini, lê os anúncios sem IA', () async {
    final client = MockClient((req) async {
      if (req.url.host == 'api.tavily.com') return _tavily();
      if (req.url.path.endsWith('/models')) {
        return http.Response(
          jsonEncode({
            'models': [
              {
                'name': 'models/gemini-flash-latest',
                'supportedGenerationMethods': ['generateContent'],
              },
            ],
          }),
          200,
        );
      }
      return http.Response(
        '{"error": {"message": "Quota exceeded, limit: 0"}}',
        429,
      );
    });
    final res = await MarketAiService(
      gemini: GeminiClient(client, 'g'),
      tavily: TavilyClient(client, 'tvly-teste'),
    ).searchArea(_study(), newId: newId);
    expect(res.readByAi, isFalse);
    // Só o anúncio individual; a página de lista não tem um preço só.
    final c = res.listings.single;
    expect(c.price, 235000);
    expect(c.area, 92);
    expect(c.tipologia, 'T2');
    expect(c.sourceUrl, 'https://www.idealista.pt/imovel/12345678/');
  });

  test('Gemini lento: a app lê os anúncios sozinha', () async {
    MarketAiService.geminiTimeout = const Duration(milliseconds: 200);
    addTearDown(
      () => MarketAiService.geminiTimeout = const Duration(seconds: 40),
    );
    final client = MockClient((req) async {
      if (req.url.host == 'api.tavily.com') return _tavily();
      await Future<void>.delayed(const Duration(seconds: 2));
      return _gemini('[]');
    });
    final res = await MarketAiService(
      gemini: GeminiClient(client, 'g'),
      tavily: TavilyClient(client, 'tvly-teste'),
    ).searchArea(_study(), newId: newId);
    expect(res.readByAi, isFalse);
    expect(res.listings.single.price, 235000);
  });

  test('sem chave do Tavily dá mensagem clara', () {
    expect(
      () => const MarketAiService().searchArea(_study(), newId: newId),
      throwsA(isA<TavilyException>()),
    );
  });

  test('chave do Tavily inválida', () async {
    final tavily = TavilyClient(
      MockClient(
        (_) async => http.Response('{"detail": {"error": "bad"}}', 401),
      ),
      'tvly-errada',
    );
    expect(
      () => tavily.search('x'),
      throwsA(
        isA<TavilyException>().having(
          (e) => e.message,
          'message',
          contains('não é válida'),
        ),
      ),
    );
  });

  test('preço e área no texto', () {
    expect(
      MarketAiService.parsePrice('T2 por 235.000 €', rental: false),
      235000,
    );
    expect(MarketAiService.parsePrice('€ 1 200 /mês', rental: true), 1200);
    expect(MarketAiService.parsePrice('2.300 €/m²', rental: false), isNull);
    expect(MarketAiService.parseArea('com 92 m² úteis'), 92);
    expect(MarketAiService.parseArea('85,5m2'), 85.5);
    expect(
      MarketAiService.isListingUrl('https://www.idealista.pt/imovel/1234/'),
      isTrue,
    );
    expect(
      MarketAiService.isListingUrl(
        'https://www.imovirtual.com/pt/resultados/comprar/apartamento/braga',
      ),
      isFalse,
    );
  });
}
