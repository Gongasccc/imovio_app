import 'package:flutter/material.dart';
import 'package:imovio/src/common_widgets/form_fields.dart';
import 'package:imovio/src/features/properties/application/listing_import_service.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
import 'package:imovio/src/utils/format.dart';

/// Estado editável de um imóvel, partilhado pelo ecrã "Novo imóvel" e pela
/// aba de detalhes. Junta os controllers de texto e os valores escolhidos.
class PropertyFormData {
  PropertyFormData(Property p)
    : base = p,
      negocio = p.negocio,
      tipo = p.tipo,
      tipologia = p.tipologia,
      saleStatus = p.saleStatus ?? PropertyOptions.saleStatuses.first,
      ownerId = p.ownerId,
      images = [...p.images] {
    String n(num? v) => v?.toString() ?? '';
    text = {
      'title': TextEditingController(text: p.title),
      'price': TextEditingController(text: n(p.price)),
      'areaBruta': TextEditingController(text: n(p.areaBruta)),
      'areaUtil': TextEditingController(text: n(p.areaUtil)),
      'areaTerreno': TextEditingController(text: n(p.areaTerreno)),
      'quartos': TextEditingController(text: n(p.quartos)),
      'wc': TextEditingController(text: n(p.wc)),
      'cp': TextEditingController(text: p.cp),
      'distrito': TextEditingController(text: p.distrito),
      'concelho': TextEditingController(text: p.concelho),
      'freguesia': TextEditingController(text: p.freguesia),
      'bairro': TextEditingController(text: p.bairro),
      'morada': TextEditingController(text: p.morada),
      'desc': TextEditingController(text: p.desc),
      'caracteristicas': TextEditingController(text: p.caracteristicas),
      'sourceUrl': TextEditingController(text: p.sourceUrl),
      'salePrice': TextEditingController(text: n(p.salePrice)),
      'commissionPct': TextEditingController(text: n(p.commissionPct ?? 5)),
      'agentSplitPct': TextEditingController(text: n(p.agentSplitPct)),
      'commissionVal': TextEditingController(text: n(p.commissionVal)),
      'dateStart': TextEditingController(text: p.dateStart),
      'dateEnd': TextEditingController(text: p.dateEnd),
      'saleNotes': TextEditingController(text: p.saleNotes),
    };
  }

  final Property base;
  late final Map<String, TextEditingController> text;
  String? negocio;
  String? tipo;
  String? tipologia;
  String saleStatus;
  String? ownerId;
  List<String> images;

  TextEditingController operator [](String key) => text[key]!;

  String? _s(String key) => emptyToNull(text[key]!.text);

  /// Preenche os campos com o que foi lido do anúncio. Campos não
  /// encontrados ficam como estavam.
  void applyImport(ImportedListing l, String url) {
    void set(String key, Object? value) {
      if (value != null) text[key]!.text = value.toString();
    }

    set('title', l.title);
    set('price', l.price);
    set('desc', l.description);
    set('areaBruta', l.areaBruta);
    set('areaUtil', l.areaUtil);
    set('areaTerreno', l.areaTerreno);
    set('quartos', l.quartos);
    set('wc', l.wc);
    set('cp', l.cp);
    set('distrito', l.distrito);
    set('concelho', l.concelho);
    set('freguesia', l.freguesia);
    set('morada', l.morada);
    final extras = [
      ...l.caracteristicas,
      if (l.energyCertificate != null)
        'certificado energético ${l.energyCertificate}',
      if (l.year != null) 'construído em ${l.year}',
    ];
    if (extras.isNotEmpty) {
      final current = text['caracteristicas']!.text.trim();
      final merged = {
        ...current.split(',').map((f) => f.trim()).where((f) => f.isNotEmpty),
        ...extras,
      };
      text['caracteristicas']!.text = merged.join(', ');
    }
    images = {...l.images, ...images}.toList();
    negocio = l.negocio ?? negocio;
    tipo = l.tipo ?? tipo;
    tipologia = l.tipologia ?? tipologia;
    text['sourceUrl']!.text = url;
  }

  Property toProperty() => Property(
    id: base.id,
    title: text['title']!.text.trim(),
    price: parseNum(text['price']!.text),
    negocio: negocio,
    tipo: tipo,
    tipologia: tipologia,
    areaBruta: parseNum(text['areaBruta']!.text),
    areaUtil: parseNum(text['areaUtil']!.text),
    areaTerreno: parseNum(text['areaTerreno']!.text),
    quartos: parseInt(text['quartos']!.text),
    wc: parseInt(text['wc']!.text),
    cp: _s('cp'),
    distrito: _s('distrito'),
    concelho: _s('concelho'),
    freguesia: _s('freguesia'),
    bairro: _s('bairro'),
    morada: _s('morada'),
    desc: _s('desc'),
    caracteristicas: _s('caracteristicas'),
    images: images,
    sourceUrl: _s('sourceUrl'),
    ownerId: ownerId,
    saleStatus: saleStatus,
    salePrice: parseNum(text['salePrice']!.text),
    commissionPct: parseNum(text['commissionPct']!.text),
    commissionVal: parseNum(text['commissionVal']!.text),
    agentSplitPct: parseNum(text['agentSplitPct']!.text),
    dateStart: _s('dateStart'),
    dateEnd: _s('dateEnd'),
    saleNotes: _s('saleNotes'),
    createdAt: base.createdAt,
  );

  void dispose() {
    for (final c in text.values) {
      c.dispose();
    }
  }
}

/// Os campos de caracterização do imóvel (formulário "Novo Imóvel" e aba 1
/// do detalhe).
class PropertyFieldsForm extends StatelessWidget {
  const PropertyFieldsForm({
    super.key,
    required this.data,
    required this.onChanged,
  });
  final PropertyFormData data;
  final VoidCallback onChanged;

  Widget _text(
    String key,
    String label, {
    String? hint,
    bool number = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: data[key],
      maxLines: maxLines,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : null,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormGrid(
      children: [
        FullWidth(
          child: TextFormField(
            controller: data['title'],
            decoration: const InputDecoration(labelText: 'Título'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Indique o título' : null,
          ),
        ),
        TextDropdown(
          // A chave recria o campo quando a importação muda o valor.
          key: ValueKey('negocio-${data.negocio}'),
          label: 'Negócio',
          value: data.negocio,
          options: PropertyOptions.negocios,
          allowEmpty: true,
          onChanged: (v) {
            data.negocio = v;
            onChanged();
          },
        ),
        TextDropdown(
          // A chave recria o campo quando a importação muda o valor.
          key: ValueKey('tipo-${data.tipo}'),
          label: 'Tipo de Imóvel',
          value: data.tipo,
          options: PropertyOptions.tipos,
          allowEmpty: true,
          onChanged: (v) {
            data.tipo = v;
            onChanged();
          },
        ),
        TextDropdown(
          // A chave recria o campo quando a importação muda o valor.
          key: ValueKey('tipologia-${data.tipologia}'),
          label: 'Tipologia',
          value: data.tipologia,
          options: PropertyOptions.tipologias,
          optionLabels: const {'T5+': 'T5 ou superior'},
          allowEmpty: true,
          onChanged: (v) {
            data.tipologia = v;
            onChanged();
          },
        ),
        TextFormField(
          controller: data['price'],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Preço (€)'),
          validator: (v) => parseNum(v) == null ? 'Indique o preço' : null,
        ),
        _text('areaBruta', 'Área Bruta (m²)', number: true),
        _text('areaUtil', 'Área Útil (m²)', number: true),
        _text('areaTerreno', 'Terreno (m²)', number: true),
        _text('quartos', 'Quartos', number: true),
        _text('wc', 'WC', number: true),
        _text('cp', 'Código Postal', hint: '0000-000'),
        _text('distrito', 'Distrito', hint: 'Ex.: Setúbal'),
        _text('concelho', 'Concelho', hint: 'Ex.: Palmela'),
        _text('freguesia', 'Freguesia', hint: 'Ex.: Pinhal Novo'),
        _text('bairro', 'Bairro', hint: 'Escreva o bairro'),
        FullWidth(child: _text('morada', 'Morada Completa')),
        FullWidth(child: _text('desc', 'Descrição Completa', maxLines: 5)),
        FullWidth(
          child: _text(
            'caracteristicas',
            'Características (separadas por vírgula)',
            hint: 'varanda, garagem, piscina...',
          ),
        ),
        FullWidth(
          child: _text(
            'sourceUrl',
            'Fonte original (link do anúncio)',
            hint: 'https://...',
          ),
        ),
      ],
    );
  }
}
