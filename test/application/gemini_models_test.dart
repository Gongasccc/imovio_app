import 'package:flutter_test/flutter_test.dart';
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
}
