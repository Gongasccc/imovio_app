import 'package:imovio/src/features/ai/data/gemini_client.dart';
import 'package:imovio/src/utils/format.dart';

/// Dados lidos do Cartão de Cidadão (ou passaporte / título de residência).
class IdCardData {
  const IdCardData({
    this.name,
    this.nif,
    this.docNumber,
    this.docType,
    this.birth,
    this.validUntil,
  });
  final String? name;
  final String? nif;
  final String? docNumber;
  final String? docType;

  /// yyyy-MM-dd
  final String? birth;
  final String? validUntil;

  bool get isEmpty => name == null && nif == null && docNumber == null;
}

/// Dados lidos da caderneta predial.
class LandRegistryData {
  const LandRegistryData({
    this.article,
    this.distrito,
    this.concelho,
    this.freguesia,
    this.morada,
    this.tipologia,
    this.areaBruta,
    this.areaUtil,
    this.areaTerreno,
    this.patrimonialValue,
    this.year,
  });
  final String? article;
  final String? distrito;
  final String? concelho;
  final String? freguesia;
  final String? morada;
  final String? tipologia;
  final num? areaBruta;
  final num? areaUtil;
  final num? areaTerreno;
  final num? patrimonialValue;
  final int? year;

  bool get isEmpty => article == null && morada == null && areaBruta == null;
}

/// Lê documentos com o Gemini (visão): devolve só o que conseguir ler.
class DocumentReader {
  const DocumentReader(this._gemini);
  final GeminiClient _gemini;

  static String? _s(Object? v) => emptyToNull(v?.toString());

  static String? _isoDate(Object? v) {
    final s = _s(v);
    if (s == null) return null;
    final dmy = RegExp(r'^(\d{2})[ ./-](\d{2})[ ./-](\d{4})$').firstMatch(s);
    if (dmy != null) return '${dmy[3]}-${dmy[2]}-${dmy[1]}';
    return DateTime.tryParse(s) == null ? null : s.substring(0, 10);
  }

  Future<Map<String, dynamic>> _ask(String prompt, GeminiFile file) async {
    final res = await _gemini.generate(prompt, files: [file], temperature: 0);
    final json = res.json;
    if (json is Map<String, dynamic>) return json;
    if (json is List && json.isNotEmpty && json.first is Map<String, dynamic>) {
      return json.first as Map<String, dynamic>;
    }
    throw const GeminiException(
        'Não foi possível ler o documento. Tente uma foto mais nítida.');
  }

  Future<IdCardData> readIdCard(GeminiFile file) async {
    final m = await _ask(
      'Lê este documento de identificação português (Cartão de Cidadão, '
      'passaporte ou título de residência). Responde só com JSON:\n'
      '{"nome": nome completo, "nif": número de identificação fiscal (9 '
      'dígitos) ou null, "numeroDocumento": número do documento (no CC o '
      'número de identificação civil com os dígitos de controlo), '
      '"tipo": "Cartão de Cidadão" | "Passaporte" | "Título de Residência", '
      '"dataNascimento": "AAAA-MM-DD", "validade": "AAAA-MM-DD"}.\n'
      'Usa null no que não for legível. Não inventes dados.',
      file,
    );
    final nif = _s(m['nif'])?.replaceAll(RegExp(r'\D'), '');
    return IdCardData(
      name: _s(m['nome']),
      nif: nif != null && nif.length == 9 ? nif : null,
      docNumber: _s(m['numeroDocumento']),
      docType: _s(m['tipo']),
      birth: _isoDate(m['dataNascimento']),
      validUntil: _isoDate(m['validade']),
    );
  }

  Future<LandRegistryData> readLandRegistry(GeminiFile file) async {
    final m = await _ask(
      'Lê esta caderneta predial portuguesa (urbana ou rústica). Responde só '
      'com JSON:\n'
      '{"artigo": artigo matricial, "distrito": string, "concelho": string, '
      '"freguesia": string, "morada": localização do prédio, '
      '"tipologia": "T0".."T5+" ou null, "areaBruta": m² (área bruta '
      'privativa), "areaUtil": m² ou null, "areaTerreno": m² (área total do '
      'terreno), "valorPatrimonial": euros, "ano": ano de inscrição na '
      'matriz}.\nUsa null no que não for legível. Não inventes dados.',
      file,
    );
    final tip = _s(m['tipologia'])?.toUpperCase();
    return LandRegistryData(
      article: _s(m['artigo']),
      distrito: _s(m['distrito']),
      concelho: _s(m['concelho']),
      freguesia: _s(m['freguesia']),
      morada: _s(m['morada']),
      tipologia: tip == null
          ? null
          : (RegExp(r'^T[0-4]$').hasMatch(tip)
              ? tip
              : (RegExp(r'^T\d+').hasMatch(tip) ? 'T5+' : null)),
      areaBruta: parseNum(m['areaBruta']),
      areaUtil: parseNum(m['areaUtil']),
      areaTerreno: parseNum(m['areaTerreno']),
      patrimonialValue: parseNum(m['valorPatrimonial']),
      year: parseInt(m['ano']),
    );
  }
}
