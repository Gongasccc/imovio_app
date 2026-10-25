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
      'commissionPct': TextEditingController(text: n(p.commissionPct ?? 5)),
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

  void applyImport(ImportedListing l, String url) {
    if (l.title != null) text['title']!.text = l.title!;
    if (l.price != null) text['price']!.text = l.price.toString();
    if (l.description != null) text['desc']!.text = l.description!;
    if (l.image != null && !images.contains(l.image)) {
      images = [l.image!, ...images];
    }
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
        commissionPct: parseNum(text['commissionPct']!.text),
        commissionVal: parseNum(text['commissionVal']!.text),
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

  Widget _text(String key, String label,
      {String? hint, bool number = false, int maxLines = 1}) {
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
    return FormGrid(children: [
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
        child: _text('caracteristicas', 'Características (separadas por vírgula)',
            hint: 'varanda, garagem, piscina...'),
      ),
      FullWidth(
        child: _text('sourceUrl', 'Fonte original (link do anúncio)',
            hint: 'https://...'),
      ),
    ]);
  }
}
