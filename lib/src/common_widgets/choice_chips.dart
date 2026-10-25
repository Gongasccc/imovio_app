import 'package:flutter/material.dart';
import 'package:imovio/src/constants/app_sizes.dart';

/// Grupo de opções de escolha múltipla em chips (selecionado = dourado).
class MultiChoiceChips extends StatelessWidget {
  const MultiChoiceChips({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.labels = const {},
  });
  final String label;
  final List<String> options;
  final List<String> selected;
  final Map<String, String> labels;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant)),
        gapH8,
        Wrap(
          spacing: Sizes.p8,
          runSpacing: Sizes.p8,
          children: [
            for (final o in options)
              FilterChip(
                label: Text(labels[o] ?? o),
                selected: selected.contains(o),
                showCheckmark: false,
                selectedColor: scheme.primary,
                labelStyle: TextStyle(
                  color: selected.contains(o) ? scheme.onPrimary : null,
                  fontWeight:
                      selected.contains(o) ? FontWeight.w600 : FontWeight.w400,
                ),
                onSelected: (on) => onChanged(on
                    ? [...selected, o]
                    : selected.where((s) => s != o).toList()),
              ),
          ],
        ),
      ],
    );
  }
}

/// Campo de escolha múltipla com pesquisa (distritos, concelhos, freguesias):
/// os escolhidos aparecem como chips que se podem remover.
class SearchableMultiSelect extends StatelessWidget {
  const SearchableMultiSelect({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.hint = 'Escolher...',
    this.allowCustom = false,
  });
  final String label;
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final String hint;

  /// Permite acrescentar valores que não estão na lista (ex.: bairros).
  final bool allowCustom;

  Future<void> _open(BuildContext context) async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => _SearchDialog(
        title: label,
        options: options,
        selected: selected,
        allowCustom: allowCustom,
      ),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _open(context),
      child: InputDecorator(
        isEmpty: selected.isEmpty,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: selected.isEmpty
            ? null
            : Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s in selected)
                    InputChip(
                      label: Text(s),
                      visualDensity: VisualDensity.compact,
                      onDeleted: () =>
                          onChanged(selected.where((x) => x != s).toList()),
                    ),
                ],
              ),
      ),
    );
  }
}

class _SearchDialog extends StatefulWidget {
  const _SearchDialog({
    required this.title,
    required this.options,
    required this.selected,
    required this.allowCustom,
  });
  final String title;
  final List<String> options;
  final List<String> selected;
  final bool allowCustom;

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  late final _picked = [...widget.selected];
  var _query = '';

  String _n(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[áàâã]'), 'a')
      .replaceAll(RegExp('[éê]'), 'e')
      .replaceAll('í', 'i')
      .replaceAll(RegExp('[óôõ]'), 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ç', 'c');

  @override
  Widget build(BuildContext context) {
    final q = _n(_query.trim());
    final visible = widget.options
        .where((o) => q.isEmpty || _n(o).contains(q))
        .take(200)
        .toList();
    final canAdd = widget.allowCustom &&
        _query.trim().isNotEmpty &&
        !widget.options.any((o) => _n(o) == q) &&
        !_picked.contains(_query.trim());
    return AlertDialog(
      title: Text(widget.title),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SizedBox(
        width: 420,
        height: 420,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: widget.allowCustom ? 'Pesquisar ou escrever' : 'Pesquisar',
              ),
              onChanged: (v) => setState(() => _query = v),
              onSubmitted: (_) {
                if (canAdd) setState(() => _picked.add(_query.trim()));
              },
            ),
            gapH8,
            if (canAdd)
              ListTile(
                leading: const Icon(Icons.add),
                title: Text('Acrescentar "${_query.trim()}"'),
                onTap: () => setState(() => _picked.add(_query.trim())),
              ),
            Expanded(
              child: widget.options.isEmpty && !widget.allowCustom
                  ? const Center(
                      child: Text('Escolha primeiro o nível acima '
                          '(ex.: distrito antes de concelho).'))
                  : ListView(
                      children: [
                        for (final o in visible)
                          CheckboxListTile(
                            dense: true,
                            value: _picked.contains(o),
                            title: Text(o),
                            onChanged: (on) => setState(() =>
                                on! ? _picked.add(o) : _picked.remove(o)),
                          ),
                        for (final custom in _picked
                            .where((p) => !widget.options.contains(p)))
                          CheckboxListTile(
                            dense: true,
                            value: true,
                            title: Text(custom),
                            onChanged: (_) =>
                                setState(() => _picked.remove(custom)),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(_picked.clear),
          child: const Text('Limpar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _picked),
          child: Text('Confirmar (${_picked.length})'),
        ),
      ],
    );
  }
}
