import 'package:equatable/equatable.dart';
import 'package:imovio/src/features/contacts/domain/contact.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
import 'package:imovio/src/utils/format.dart';

typedef TemplateID = String;

/// Modelo de mensagem com campos que a app preenche:
/// {nome}, {primeiro_nome}, {imovel}, {preco}, {tipologia}, {concelho},
/// {freguesia}, {area}, {link}, {consultor}.
class MessageTemplate extends Equatable {
  const MessageTemplate({
    required this.id,
    required this.name,
    required this.body,
    this.subject,
    this.builtIn = false,
  });

  final TemplateID id;
  final String name;
  final String? subject;
  final String body;

  /// Modelos que vêm com a app (podem ser copiados e alterados).
  final bool builtIn;

  static const placeholders = {
    '{nome}': 'Nome do contacto',
    '{primeiro_nome}': 'Primeiro nome do contacto',
    '{imovel}': 'Título do imóvel',
    '{preco}': 'Preço do imóvel',
    '{tipologia}': 'Tipologia',
    '{concelho}': 'Concelho',
    '{freguesia}': 'Freguesia',
    '{area}': 'Área útil',
    '{link}': 'Link do anúncio',
    '{consultor}': 'O seu nome',
  };

  factory MessageTemplate.fromMap(Map<String, dynamic> m, String id) =>
      MessageTemplate(
        id: id,
        name: m['name']?.toString() ?? 'Modelo',
        subject: emptyToNull(m['subject']?.toString()),
        body: m['body']?.toString() ?? '',
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'subject': subject ?? '',
        'body': body,
      };

  @override
  List<Object?> get props => [id, name, subject, body, builtIn];
}

/// Preenche os campos do modelo. Os que não têm valor desaparecem.
String fillTemplate(
  String text, {
  Contact? contact,
  Property? property,
  String? consultant,
}) {
  final first = contact?.name.trim().split(RegExp(r'\s+')).first;
  final values = {
    '{nome}': contact?.name,
    '{primeiro_nome}': first,
    '{imovel}': property?.title,
    '{preco}': property?.price == null ? null : Format.euros(property!.price),
    '{tipologia}': property?.tipologia,
    '{concelho}': property?.concelho,
    '{freguesia}': property?.freguesia,
    '{area}': property?.areaUtil == null
        ? null
        : '${Format.number(property!.areaUtil)} m²',
    '{link}': property?.sourceUrl,
    '{consultor}': consultant,
  };
  var out = text;
  values.forEach((k, v) => out = out.replaceAll(k, v ?? ''));
  // Limpa espaços e linhas que ficaram vazias.
  return out
      .split('\n')
      .map((l) => l.replaceAll(RegExp(r' {2,}'), ' ').trimRight())
      .join('\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

const builtInTemplates = [
  MessageTemplate(
    id: 'builtin-novo-imovel',
    name: 'Novo imóvel compatível',
    builtIn: true,
    subject: 'Imóvel que pode interessar: {imovel}',
    body: 'Olá {primeiro_nome}! Tenho um imóvel que encaixa no que procura: '
        '{imovel}, {tipologia} em {freguesia} {concelho}, por {preco}.\n'
        '{link}\n'
        'Quer marcar uma visita? {consultor}',
  ),
  MessageTemplate(
    id: 'builtin-confirmar-visita',
    name: 'Confirmar visita',
    builtIn: true,
    subject: 'Visita ao imóvel {imovel}',
    body: 'Olá {primeiro_nome}, confirmo a nossa visita ao imóvel {imovel} '
        '({freguesia}). Qualquer imprevisto diga-me. {consultor}',
  ),
  MessageTemplate(
    id: 'builtin-seguimento',
    name: 'Seguimento depois da visita',
    builtIn: true,
    subject: 'O que achou do {imovel}?',
    body: 'Olá {primeiro_nome}, obrigado pela visita ao {imovel}. O que achou? '
        'Se quiser, posso preparar uma proposta ou mostrar outras opções '
        'parecidas. {consultor}',
  ),
  MessageTemplate(
    id: 'builtin-angariacao',
    name: 'Apresentação a proprietário',
    builtIn: true,
    subject: 'Venda do seu imóvel',
    body: 'Olá {primeiro_nome}, sou {consultor}, consultor imobiliário. Tenho '
        'clientes à procura de imóveis na sua zona e gostava de lhe '
        'apresentar um estudo de mercado gratuito do seu imóvel. Podemos '
        'falar?',
  ),
  MessageTemplate(
    id: 'builtin-aniversario',
    name: 'Parabéns',
    builtIn: true,
    subject: 'Parabéns!',
    body: 'Olá {primeiro_nome}, muitos parabéns! Desejo-lhe um excelente dia. '
        '{consultor}',
  ),
];
