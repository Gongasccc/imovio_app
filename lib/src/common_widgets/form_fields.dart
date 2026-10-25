import 'package:flutter/material.dart';
import 'package:imovio/src/constants/app_sizes.dart';

/// Grelha de campos de formulário: duas colunas em ecrãs largos, uma no
/// telemóvel. Um [FullWidth] ocupa sempre a linha inteira.
class FormGrid extends StatelessWidget {
  const FormGrid({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final twoColumns = constraints.maxWidth >= 560;
      final itemWidth = twoColumns
          ? (constraints.maxWidth - Sizes.p16) / 2
          : constraints.maxWidth;
      return Wrap(
        spacing: Sizes.p16,
        runSpacing: Sizes.p16,
        children: [
          for (final child in children)
            SizedBox(
              width: child is FullWidth ? constraints.maxWidth : itemWidth,
              child: child,
            ),
        ],
      );
    });
  }
}

class FullWidth extends StatelessWidget {
  const FullWidth({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// Dropdown de texto que aceita valores antigos que já não estão na lista.
class TextDropdown extends StatelessWidget {
  const TextDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.optionLabels,
    this.allowEmpty = false,
  });
  final String label;
  final String? value;
  final List<String> options;
  final Map<String, String>? optionLabels;
  final ValueChanged<String?> onChanged;
  final bool allowEmpty;

  @override
  Widget build(BuildContext context) {
    final current = value ?? '';
    final items = [...options];
    if (current.isNotEmpty && !items.contains(current)) {
      items.add(current);
    }
    return DropdownButtonFormField<String>(
      initialValue: current.isEmpty ? (allowEmpty ? '' : null) : current,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        if (allowEmpty) const DropdownMenuItem(value: '', child: Text('—')),
        for (final o in items)
          DropdownMenuItem(value: o, child: Text(optionLabels?[o] ?? o)),
      ],
      onChanged: (v) => onChanged(v == '' ? null : v),
    );
  }
}
