import 'package:flutter/material.dart';
import 'package:imovio/src/common_widgets/form_fields.dart';
import 'package:imovio/src/constants/app_sizes.dart';
import 'package:imovio/src/features/market_study/domain/comparable_listing.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
import 'package:imovio/src/utils/format.dart';

/// Formulário de um comparável (novo, importado por link ou a editar).
/// Devolve o comparável preenchido, ou null se o utilizador cancelar.
Future<ComparableListing?> showComparableForm(
  BuildContext context,
  ComparableListing initial, {
  String title = 'Comparável',
}) => showDialog<ComparableListing>(
  context: context,
  builder: (_) => _ComparableFormDialog(initial: initial, title: title),
);

class _ComparableFormDialog extends StatefulWidget {
  const _ComparableFormDialog({required this.initial, required this.title});
  final ComparableListing initial;
  final String title;

  @override
  State<_ComparableFormDialog> createState() => _ComparableFormDialogState();
}

class _ComparableFormDialogState extends State<_ComparableFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final c = widget.initial;
  late final _title = TextEditingController(text: c.title);
  late final _price = TextEditingController(
    text: c.price > 0 ? '${c.price}' : '',
  );
  late final _area = TextEditingController(text: c.area > 0 ? '${c.area}' : '');
  late final _concelho = TextEditingController(text: c.concelho ?? '');
  late final _freguesia = TextEditingController(text: c.freguesia ?? '');
  late final _url = TextEditingController(text: c.sourceUrl ?? '');
  late final _notes = TextEditingController(text: c.notes ?? '');
  late final _date = TextEditingController(text: c.date ?? '');
  late String? _negocio = c.negocio ?? PropertyOptions.negocios.first;
  late String? _tipo = c.tipo;
  late String? _tipologia = c.tipologia;
  late Conservation? _conservation = c.conservation;
  late ComparableSource _source = c.source;
  late bool _garage = c.garage;
  late bool _outdoor = c.outdoor;
  late bool _elevator = c.elevator;

  @override
  void dispose() {
    for (final t in [
      _title,
      _price,
      _area,
      _concelho,
      _freguesia,
      _url,
      _notes,
      _date,
    ]) {
      t.dispose();
    }
    super.dispose();
  }

  String? _positive(String? v) => (parseNum(v) ?? 0) > 0 ? null : 'Obrigatório';

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      ComparableListing(
        id: c.id,
        title:
            emptyToNull(_title.text) ??
            [
              _tipo,
              _tipologia,
              emptyToNull(_concelho.text),
            ].nonNulls.join(' · '),
        price: parseNum(_price.text)!,
        area: parseNum(_area.text)!,
        source: _source,
        negocio: _negocio,
        tipo: _tipo,
        tipologia: _tipologia,
        concelho: emptyToNull(_concelho.text),
        freguesia: emptyToNull(_freguesia.text),
        morada: c.morada,
        conservation: _conservation,
        garage: _garage,
        outdoor: _outdoor,
        elevator: _elevator,
        sourceUrl: emptyToNull(_url.text),
        image: c.image,
        notes: emptyToNull(_notes.text),
        date: emptyToNull(_date.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 620,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: FormGrid(
              children: [
                FullWidth(
                  child: SegmentedButton<ComparableSource>(
                    segments: [
                      for (final s in ComparableSource.values)
                        ButtonSegment(value: s, label: Text(s.label)),
                    ],
                    selected: {_source},
                    onSelectionChanged: (v) =>
                        setState(() => _source = v.first),
                  ),
                ),
                FullWidth(
                  child: TextFormField(
                    controller: _title,
                    decoration: const InputDecoration(labelText: 'Título'),
                  ),
                ),
                TextFormField(
                  controller: _price,
                  validator: _positive,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: _source == ComparableSource.venda
                        ? 'Valor de venda (€)'
                        : 'Preço pedido (€)',
                  ),
                ),
                TextFormField(
                  controller: _area,
                  validator: _positive,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Área útil (m²)',
                    helperText: 'Ou área bruta, se for a única no anúncio',
                  ),
                ),
                TextDropdown(
                  label: 'Negócio',
                  value: _negocio,
                  options: PropertyOptions.negocios,
                  onChanged: (v) => setState(() => _negocio = v),
                ),
                TextDropdown(
                  label: 'Tipo',
                  value: _tipo,
                  options: PropertyOptions.tipos,
                  allowEmpty: true,
                  onChanged: (v) => setState(() => _tipo = v),
                ),
                TextDropdown(
                  label: 'Tipologia',
                  value: _tipologia,
                  options: PropertyOptions.tipologias,
                  allowEmpty: true,
                  onChanged: (v) => setState(() => _tipologia = v),
                ),
                DropdownButtonFormField<Conservation?>(
                  initialValue: _conservation,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Estado de conservação',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Usado (por defeito)'),
                    ),
                    for (final c in Conservation.values)
                      DropdownMenuItem(value: c, child: Text(c.label)),
                  ],
                  onChanged: (v) => setState(() => _conservation = v),
                ),
                TextFormField(
                  controller: _concelho,
                  decoration: const InputDecoration(labelText: 'Concelho'),
                ),
                TextFormField(
                  controller: _freguesia,
                  decoration: const InputDecoration(labelText: 'Freguesia'),
                ),
                FullWidth(
                  child: Wrap(
                    spacing: Sizes.p8,
                    children: [
                      FilterChip(
                        label: const Text('Garagem / estacionamento'),
                        selected: _garage,
                        onSelected: (v) => setState(() => _garage = v),
                      ),
                      FilterChip(
                        label: const Text('Varanda / terraço / jardim'),
                        selected: _outdoor,
                        onSelected: (v) => setState(() => _outdoor = v),
                      ),
                      FilterChip(
                        label: const Text('Elevador'),
                        selected: _elevator,
                        onSelected: (v) => setState(() => _elevator = v),
                      ),
                    ],
                  ),
                ),
                TextFormField(
                  controller: _date,
                  decoration: const InputDecoration(
                    labelText: 'Data',
                    hintText: 'aaaa-mm-dd',
                  ),
                ),
                TextFormField(
                  controller: _url,
                  decoration: const InputDecoration(labelText: 'Link'),
                ),
                FullWidth(
                  child: TextFormField(
                    controller: _notes,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Notas'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Guardar')),
      ],
    );
  }
}
