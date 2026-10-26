import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:imovio/src/features/ai/data/gemini_client.dart';

void main() {
  test('usa os aliases -latest e ignora modelos retirados ou não Flash', () {
    final ranked = GeminiClient.rankModels([
      'gemini-3-flash-preview',
      'gemini-flash-lite-latest',
      'gemini-3-pro',
      'gemini-flash-latest',
      'gemini-2.5-flash-image',
      'gemini-3-flash',
      'text-embedding-004',
      'gemini-3-flash-lite',
    ]);
    expect(ranked.take(2), ['gemini-flash-latest', 'gemini-flash-lite-latest']);
    expect(ranked, isNot(contains('gemini-3-pro')));
    expect(ranked, isNot(contains('gemini-2.5-flash-image')));
    expect(
      ranked.indexOf('gemini-3-flash'),
      lessThan(ranked.indexOf('gemini-3-flash-preview')),
    );
    expect(
      ranked.indexOf('gemini-3-flash'),
      lessThan(ranked.indexOf('gemini-3-flash-lite')),
    );
  });

  test('sem os aliases, escolhe o Flash mais recente', () {
    final ranked = GeminiClient.rankModels([
      'gemini-2.0-flash',
      'gemini-3-flash',
    ]);
    expect(ranked, ['gemini-3-flash', 'gemini-2.0-flash']);
  });

  group('sobrecarga (503)', () {
    setUp(() => GeminiClient.retryDelay = Duration.zero);

    http.Response ok() => http.Response(
          '{"candidates":[{"content":{"parts":[{"text":"ok"}]}}]}',
          200,
        );
    http.Response busy() => http.Response(
          '{"error":{"message":"This model is currently experiencing high demand."}}',
          503,
        );

    test('tenta outra vez e passa ao modelo seguinte', () async {
      final calls = <String>[];
      final client = GeminiClient(
        MockClient((req) async {
          if (req.method == 'GET') return http.Response('{"models": []}', 200);
          calls.add(req.url.path);
          return calls.length < 3 ? busy() : ok();
        }),
        'chave-503-a',
      );
      expect((await client.generate('x')).text, 'ok');
      expect(calls.first, contains('gemini-flash-latest'));
      expect(calls.last, contains('gemini-flash-lite-latest'));
    });

    test('se todos estiverem ocupados, o erro é temporário e não da chave',
        () async {
      final client = GeminiClient(
        MockClient((req) async => req.method == 'GET'
            ? http.Response('{"models": []}', 200)
            : busy()),
        'chave-503-b',
      );
      await expectLater(
        client.generate('x'),
        throwsA(isA<GeminiException>()
            .having((e) => e.isTemporary, 'isTemporary', isTrue)
            .having((e) => e.isKeyProblem, 'isKeyProblem', isFalse)
            .having((e) => e.message, 'message', contains('não é problema'))),
      );
    });
  });

  test('validar a chave usa só a lista de modelos e é rápido', () async {
    final valid = GeminiClient(
      MockClient((req) async {
        expect(req.method, 'GET');
        return http.Response(
          '{"models":[{"name":"models/gemini-flash-latest",'
          '"supportedGenerationMethods":["generateContent"]}]}',
          200,
        );
      }),
      'chave-valida',
    );
    expect(await valid.validateKey(), ['gemini-flash-latest']);

    final invalid = GeminiClient(
      MockClient((_) async => http.Response(
            '{"error":{"message":"API key not valid."}}',
            400,
          )),
      'chave-errada',
    );
    await expectLater(
      invalid.validateKey(),
      throwsA(isA<GeminiException>()
          .having((e) => e.isKeyProblem, 'isKeyProblem', isTrue)),
    );
  });
}
