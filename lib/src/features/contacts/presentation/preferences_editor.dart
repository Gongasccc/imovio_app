import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imovio/src/common_widgets/choice_chips.dart';
import 'package:imovio/src/common_widgets/form_fields.dart';
import 'package:imovio/src/common_widgets/section_card.dart';
import 'package:imovio/src/constants/app_sizes.dart';
import 'package:imovio/src/features/contacts/domain/property_preferences.dart';
import 'package:imovio/src/features/geo/data/geo_repository.dart';
import 'package:imovio/src/utils/format.dart';

/// Estado editável das preferências do contacto.
class PreferencesController extends ValueNotifier<PropertyPreferences> {
  PreferencesController(super.value);
}

typedef _P = PropertyPreferences;

/// Aba "Imóvel" do contacto, com as três sub-abas da app anterior:
/// Estruturais, Físicas e Comodidades.
class PreferencesEditor extends ConsumerStatefulWidget {
  const PreferencesEditor({super.key, required this.controller});
  final PreferencesController controller;

  @override
  ConsumerState<PreferencesEditor> createState() => _PreferencesEditorState();
}

class _PreferencesEditorState extends ConsumerState<PreferencesEditor> {
  var _section = 0;
  late final Map<String, TextEditingController> _numbers;

  _P get _p => widget.controller.value;

  @override
  void initState() {
    super.initState();
    String n(num? v) => v?.toString() ?? '';
    _numbers = {
      'minPrice': TextEditingController(text: n(_p.minPrice)),
      'maxPrice': TextEditingController(text: n(_p.maxPrice)),
      'minArea': TextEditingController(text: n(_p.minArea)),
      'maxArea': TextEditingController(text: n(_p.maxArea)),
      'areaTerreno': TextEditingController(text: n(_p.areaTerreno)),
      'areaBruta': TextEditingController(text: n(_p.areaBruta)),
      'areaUtil': TextEditingController(text: n(_p.areaUtil)),
    };
  }

  @override
  void dispose() {
    for (final c in _numbers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Copia [_p] com as listas e números alterados.
  void _set({
    List<String>? negocios,
    List<String>? tipos,
    List<String>? tipologias,
    List<String>? distritos,
    List<String>? concelhos,
    List<String>? freguesias,
    List<String>? bairros,
    List<String>? financiamento,
    List<String>? sinalCpcv,
    List<String>? casasDeBanho,
    List<String>? estados,
    List<String>? pisos,
    List<String>? estacionamento,
    List<String>? exterior,
    List<String>? acessibilidade,
    List<String>? climatizacao,
    List<String>? lazer,
  }) {
    final p = _p;
    num? n(String k) => parseNum(_numbers[k]!.text);
    widget.controller.value = PropertyPreferences(
      negocios: negocios ?? p.negocios,
      tipos: tipos ?? p.tipos,
      tipologias: tipologias ?? p.tipologias,
      distritos: distritos ?? p.distritos,
      concelhos: concelhos ?? p.concelhos,
      freguesias: freguesias ?? p.freguesias,
      bairros: bairros ?? p.bairros,
      minPrice: n('minPrice'),
      maxPrice: n('maxPrice'),
      financiamento: financiamento ?? p.financiamento,
      sinalCpcv: sinalCpcv ?? p.sinalCpcv,
      minArea: n('minArea'),
      maxArea: n('maxArea'),
      casasDeBanho: casasDeBanho ?? p.casasDeBanho,
      estados: estados ?? p.estados,
      pisos: pisos ?? p.pisos,
      areaTerreno: n('areaTerreno'),
      areaBruta: n('areaBruta'),
      areaUtil: n('areaUtil'),
      estacionamento: estacionamento ?? p.estacionamento,
      exterior: exterior ?? p.exterior,
      acessibilidade: acessibilidade ?? p.acessibilidade,
      climatizacao: climatizacao ?? p.climatizacao,
      lazer: lazer ?? p.lazer,
    );
    setState(() {});
  }

  Widget _number(String key, String label, {String suffix = '€'}) =>
      TextFormField(
        controller: _numbers[key],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, suffixText: suffix),
        onChanged: (_) => _set(),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Estruturais')),
            ButtonSegment(value: 1, label: Text('Físicas')),
            ButtonSegment(value: 2, label: Text('Comodidades')),
          ],
          selected: {_section},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(() => _section = s.first),
        ),
        gapH16,
        [_structural, _physical, _amenities][_section](),
      ],
    );
  }

  Widget _structural() {
    final geo = ref.watch(geoDataProvider).value;
    final p = _p;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MultiChoiceChips(
                label: 'Tipo de negócio',
                options: PreferenceOptions.negocios,
                selected: p.negocios,
                onChanged: (v) => _set(negocios: v),
              ),
              gapH16,
              MultiChoiceChips(
                label: 'Tipo de imóvel',
                options: PreferenceOptions.tipos,
                selected: p.tipos,
                onChanged: (v) => _set(tipos: v),
              ),
              gapH16,
              MultiChoiceChips(
                label: 'Tipologia',
                options: PreferenceOptions.tipologias,
                labels: PreferenceOptions.tipologiaLabels,
                selected: p.tipologias,
                onChanged: (v) => _set(tipologias: v),
              ),
            ],
          ),
        ),
        gapH16,
        SectionCard(
          title: 'Localização',
          icon: Icons.place_outlined,
          child: FormGrid(children: [
            SearchableMultiSelect(
              label: 'Distrito',
              options: geo?.distritos ?? const [],
              selected: p.distritos,
              onChanged: (v) => _set(distritos: v),
            ),
            SearchableMultiSelect(
              label: 'Concelho',
              options: geo?.concelhos(p.distritos) ?? const [],
              selected: p.concelhos,
              onChanged: (v) {
                // Escolher um concelho completa o distrito.
                final ds = {
                  ...p.distritos,
                  for (final c in v) ?geo?.distritoOf(c),
                }.toList();
                _set(concelhos: v, distritos: ds);
              },
            ),
            SearchableMultiSelect(
              label: 'Freguesia',
              options: geo?.freguesias(p.concelhos) ?? const [],
              selected: p.freguesias,
              hint: p.concelhos.isEmpty ? 'Escolha primeiro o concelho' : 'Escolher...',
              onChanged: (v) => _set(freguesias: v),
            ),
            SearchableMultiSelect(
              label: 'Bairro',
              options: const [],
              allowCustom: true,
              selected: p.bairros,
              hint: 'Escrever bairros',
              onChanged: (v) => _set(bairros: v),
            ),
          ]),
        ),
        gapH16,
        SectionCard(
          title: 'Preço',
          icon: Icons.euro,
          child: FormGrid(children: [
            _number('minPrice', 'Preço mínimo'),
            _number('maxPrice', 'Preço máximo'),
          ]),
        ),
        gapH16,
        SectionCard(
          title: 'Perfil financeiro',
          icon: Icons.account_balance_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MultiChoiceChips(
                label: 'Modalidade',
                options: PreferenceOptions.financiamento,
                selected: p.financiamento,
                onChanged: (v) => _set(financiamento: v),
              ),
              gapH16,
              MultiChoiceChips(
                label: 'Percentual do sinal (CPCV)',
                options: PreferenceOptions.sinalCpcv,
                selected: p.sinalCpcv,
                onChanged: (v) => _set(sinalCpcv: v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _physical() {
    final p = _p;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FormGrid(children: [
                _number('minArea', 'Área mínima', suffix: 'm²'),
                _number('maxArea', 'Área máxima', suffix: 'm²'),
              ]),
              gapH16,
              MultiChoiceChips(
                label: 'Casas de banho',
                options: PreferenceOptions.casasDeBanho,
                selected: p.casasDeBanho,
                onChanged: (v) => _set(casasDeBanho: v),
              ),
              gapH16,
              MultiChoiceChips(
                label: 'Estado do imóvel',
                options: PreferenceOptions.estados,
                selected: p.estados,
                onChanged: (v) => _set(estados: v),
              ),
              gapH16,
              MultiChoiceChips(
                label: 'Piso',
                options: PreferenceOptions.pisos,
                selected: p.pisos,
                onChanged: (v) => _set(pisos: v),
              ),
            ],
          ),
        ),
        gapH16,
        SectionCard(
          title: 'Áreas do imóvel',
          icon: Icons.square_foot,
          child: FormGrid(children: [
            _number('areaTerreno', 'Área de Terreno', suffix: 'm²'),
            _number('areaBruta', 'Área Bruta', suffix: 'm²'),
            _number('areaUtil', 'Área Útil', suffix: 'm²'),
          ]),
        ),
        gapH16,
        SectionCard(
          child: MultiChoiceChips(
            label: 'Estacionamento',
            options: PreferenceOptions.estacionamento,
            selected: p.estacionamento,
            onChanged: (v) => _set(estacionamento: v),
          ),
        ),
      ],
    );
  }

  Widget _amenities() {
    final p = _p;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MultiChoiceChips(
            label: 'Espaço exterior',
            options: PreferenceOptions.exterior,
            selected: p.exterior,
            onChanged: (v) => _set(exterior: v),
          ),
          gapH16,
          MultiChoiceChips(
            label: 'Acessibilidade',
            options: PreferenceOptions.acessibilidade,
            selected: p.acessibilidade,
            onChanged: (v) => _set(acessibilidade: v),
          ),
          gapH16,
          MultiChoiceChips(
            label: 'Climatização',
            options: PreferenceOptions.climatizacao,
            selected: p.climatizacao,
            onChanged: (v) => _set(climatizacao: v),
          ),
          gapH16,
          MultiChoiceChips(
            label: 'Lazer',
            options: PreferenceOptions.lazer,
            selected: p.lazer,
            onChanged: (v) => _set(lazer: v),
          ),
        ],
      ),
    );
  }
}
