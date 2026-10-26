import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:imovio/src/features/ai/data/gemini_client.dart';
import 'package:imovio/src/features/documents_ai/application/document_reader.dart';

GeminiClient _gemini(String answer, {void Function(Map body)? onBody}) =>
    GeminiClient(
      MockClient((req) async {
        if (req.method == 'GET') return http.Response('{"models": []}', 200);
        onBody?.call(jsonDecode(req.body) as Map);
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': answer},
                  ],
                },
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
      'chave-doc-${answer.hashCode}',
    );

void main() {
  test('Cartão de Cidadão: envia a imagem e normaliza datas e NIF', () async {
    Map? sent;
    final reader = DocumentReader(_gemini(
      '```json\n{"nome":"Ana Maria Silva","nif":"123 456 789",'
      '"numeroDocumento":"12345678 9 ZZ1","tipo":"Cartão de Cidadão",'
      '"dataNascimento":"07/03/1990","validade":null}\n```',
      onBody: (b) => sent = b,
    ));
    final d = await reader.readIdCard(const GeminiFile([1, 2, 3], 'image/jpeg'));
    expect(d.name, 'Ana Maria Silva');
    expect(d.nif, '123456789');
    expect(d.birth, '1990-03-07');
    expect(d.docType, 'Cartão de Cidadão');
    final parts = (sent!['contents'] as List).first['parts'] as List;
    expect(parts.first['inline_data']['mime_type'], 'image/jpeg');
    expect(parts.first['inline_data']['data'], base64Encode([1, 2, 3]));
  });

  test('caderneta predial: áreas, tipologia e artigo', () async {
    final reader = DocumentReader(_gemini(
      '{"artigo":"U-1234","concelho":"Seixal","freguesia":"Corroios",'
      '"tipologia":"t6","areaBruta":"92,5","areaUtil":null,'
      '"areaTerreno":null,"valorPatrimonial":"85.430","ano":1999}',
    ));
    final d = await reader
        .readLandRegistry(const GeminiFile([0], 'application/pdf'));
    expect(d.article, 'U-1234');
    expect(d.tipologia, 'T5+');
    expect(d.areaBruta, 92.5);
    expect(d.year, 1999);
    expect(d.isEmpty, isFalse);
  });
}
