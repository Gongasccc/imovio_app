import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:imovio/src/features/ai/application/listing_ai_extractor.dart';
import 'package:imovio/src/features/ai/data/gemini_client.dart';

/// Resposta da API Gemini com [text] e duas fontes da pesquisa Google.
http.Response _reply(String text) => http.Response(
  jsonEncode({
    'candidates': [
      {
        'content': {
          'parts': [
            {'text': text},
          ],
        },
        'groundingMetadata': {
          'webSearchQueries': ['T2 venda Braga'],
          'groundingChunks': [
            {
              'web': {'uri': 'https://exemplo.pt/a', 'title': 'idealista.pt'},
            },
          ],
        },
      },
    ],
  }),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test('lê texto, fontes e JSON dentro de ```json', () async {
    late http.Request sent;
    final client = GeminiClient(
      MockClient((req) async {
        if (req.method == 'GET') return http.Response('{"models": []}', 200);
        sent = req;
        return _reply('Aqui está:\n```json\n[{"a": 1}]\n```');
      }),
      'chave',
    );
    final res = await client.generate('olá', googleSearch: true);
    expect(sent.headers['x-goog-api-key'], 'chave');
    expect(sent.url.path, contains('gemini-flash-latest:generateContent'));
    expect((jsonDecode(sent.body) as Map)['tools'], [
      {'google_search': {}},
    ]);
    expect(res.json, [
      {'a': 1},
    ]);
    expect(res.sources.single.title, 'idealista.pt');
    expect(res.searchQueries, ['T2 venda Braga']);
  });

  test('passa ao modelo seguinte se o primeiro deixar de existir', () async {
    final models = <String>[];
    final client = GeminiClient(
      MockClient((req) async {
        if (req.method == 'GET') return http.Response('{"models": []}', 200);
        models.add(req.url.path);
        return models.length == 1
            ? http.Response('{"error": {"message": "not found"}}', 404)
            : _reply('ok');
      }),
      'chave',
    );
    expect((await client.generate('x')).text, 'ok');
    expect(models.last, contains('gemini-flash-lite-latest'));
  });

  test('chave inválida dá mensagem em português', () async {
    final client = GeminiClient(
      MockClient(
        (_) async => http.Response(
          '{"error": {"message": "API key not valid. Please pass a valid API key."}}',
          400,
        ),
      ),
      'errada',
    );
    expect(
      () => client.generate('x'),
      throwsA(
        isA<GeminiException>().having(
          (e) => e.message,
          'message',
          contains('não é válida'),
        ),
      ),
    );
  });

  test('extrai anúncio e deduz a localização', () async {
    late String prompt;
    final gemini = GeminiClient(
      MockClient((req) async {
        if (req.method == 'GET') return http.Response('{"models": []}', 200);
        prompt =
            ((((jsonDecode(req.body) as Map)['contents'] as List).first
                            as Map)['parts']
                        as List)
                    .first['text']
                as String;
        return _reply(
          jsonEncode({
            'titulo': 'T3 em Corroios',
            'preco': 320000,
            'negocio': 'Venda',
            'tipologia': 'T3',
            'areaUtil': 110,
            'concelho': 'Seixal',
            'freguesia': 'Corroios',
            'distrito': 'Setúbal',
            'caracteristicas': ['Garagem', 'Varanda'],
            'fotoCapa': 'https://img.exemplo.pt/capa.jpg',
          }),
        );
      }),
      'chave',
    );
    final listing = await ListingAiExtractor(gemini).extract(
      'https://exemplo.pt/anuncio',
      html: '<html><script>x()</script><h1>T3 em Corroios</h1></html>',
    );
    expect(prompt, contains('T3 em Corroios'));
    expect(prompt, isNot(contains('x()')));
    expect(listing!.concelho, 'Seixal');
    expect(listing.distrito, 'Setúbal');
    expect(listing.price, 320000);
    expect(listing.images, ['https://img.exemplo.pt/capa.jpg']);
    expect(listing.caracteristicas, ['Garagem', 'Varanda']);
  });
}
