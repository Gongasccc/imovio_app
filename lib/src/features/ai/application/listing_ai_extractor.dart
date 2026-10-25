import 'package:imovio/src/features/ai/data/gemini_client.dart';
import 'package:imovio/src/features/properties/application/listing_parser.dart';
import 'package:imovio/src/utils/format.dart';

/// Lê um anúncio com o Gemini: a partir do HTML já descarregado (mais fiável)
/// ou, sem HTML, pedindo ao Gemini que abra o link. Deduz também o distrito,
/// concelho e freguesia a partir da morada ou do texto do anúncio.
class ListingAiExtractor {
  const ListingAiExtractor(this._gemini);
  final GeminiClient _gemini;

  /// Texto visível da página, sem scripts nem estilos, cortado para caber no
  /// pedido.
  static String pageText(String html, {int max = 40000}) {
    final text = html
        .replaceAll(
          RegExp(
            r'<(script|style|noscript)[^>]*>.*?</\1>',
            caseSensitive: false,
            dotAll: true,
          ),
          ' ',
        )
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return text.length > max ? text.substring(0, max) : text;
  }

  static const _fields = '''
{
  "titulo": string,
  "descricao": string (resumo até 600 caracteres),
  "preco": número em euros ou null,
  "negocio": "Venda" | "Arrendamento" | null,
  "tipo": "Apartamento" | "Moradia" | "Casa" | "Terreno" | null,
  "tipologia": "T0".."T5+" | null,
  "areaUtil": número m² | null,
  "areaBruta": número m² | null,
  "areaTerreno": número m² | null,
  "quartos": número | null,
  "wc": número | null,
  "codigoPostal": "0000-000" | null,
  "distrito": string | null,
  "concelho": string | null,
  "freguesia": string | null,
  "morada": string | null,
  "caracteristicas": [string],
  "certificadoEnergetico": string | null,
  "ano": número | null,
  "fotoCapa": url | null
}''';

  Future<ImportedListing?> extract(String url, {String? html}) async {
    final text = html == null ? null : pageText(html);
    final prompt = StringBuffer()
      ..writeln('És um assistente de uma agência imobiliária em Portugal.')
      ..writeln(
        'Extrai os dados do anúncio imobiliário ${text == null ? 'neste link' : 'abaixo'} '
        'e responde APENAS com um objeto JSON neste formato:',
      )
      ..writeln(_fields)
      ..writeln(
        'Regras: usa só informação do anúncio; o que não estiver '
        'lá fica null. Deduz o distrito, o concelho e a freguesia '
        'oficiais de Portugal a partir da morada, código postal ou zona '
        'indicada (por exemplo "Corroios" → concelho Seixal, distrito '
        'Setúbal). Números sem pontos de milhar.',
      )
      ..writeln('Link: $url');
    if (text != null) prompt.writeln('Texto da página:\n$text');
    final res = await _gemini.generate(
      prompt.toString(),
      readUrls: text == null,
      temperature: 0,
    );
    final json = res.json;
    if (json is! Map) return null;
    String? s(String k) =>
        emptyToNull(json[k]?.toString() == 'null' ? null : json[k]?.toString());
    final photo = s('fotoCapa');
    return ImportedListing(
      title: s('titulo'),
      description: s('descricao'),
      price: parseNum(json['preco']),
      negocio: s('negocio'),
      tipo: s('tipo'),
      tipologia: s('tipologia'),
      areaUtil: parseNum(json['areaUtil']),
      areaBruta: parseNum(json['areaBruta']),
      areaTerreno: parseNum(json['areaTerreno']),
      quartos: parseInt(json['quartos']),
      wc: parseInt(json['wc']),
      cp: s('codigoPostal'),
      distrito: s('distrito'),
      concelho: s('concelho'),
      freguesia: s('freguesia'),
      morada: s('morada'),
      caracteristicas: [
        for (final c in json['caracteristicas'] as List? ?? const [])
          c.toString(),
      ],
      energyCertificate: s('certificadoEnergetico'),
      year: parseInt(json['ano']),
      images: [if (photo != null && photo.startsWith('http')) photo],
    );
  }
}
