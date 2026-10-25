import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imovio/src/features/contacts/data/contacts_repository.dart';
import 'package:imovio/src/features/properties/data/properties_repository.dart';

/// Escolha de um contacto da lista (como os selects "Cliente Associado").
class ContactPicker extends ConsumerWidget {
  const ContactPicker({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.emptyLabel = 'Nenhum cliente associado',
    this.required = false,
  });
  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String emptyLabel;
  final bool required;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(contactsStreamProvider).value ?? const [];
    final known = contacts.any((c) => c.id == value);
    return DropdownButtonFormField<String>(
      initialValue: known ? value : '',
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        DropdownMenuItem(value: '', child: Text(emptyLabel)),
        for (final c in contacts)
          DropdownMenuItem(value: c.id, child: Text('${c.name} · ${c.type}')),
      ],
      validator: required
          ? (v) => (v == null || v.isEmpty) ? 'Escolha um cliente' : null
          : null,
      onChanged: (v) => onChanged(v == '' ? null : v),
    );
  }
}

class PropertyPicker extends ConsumerWidget {
  const PropertyPicker({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final properties = ref.watch(propertiesStreamProvider).value ?? const [];
    final known = properties.any((p) => p.id == value);
    return DropdownButtonFormField<String>(
      initialValue: known ? value : '',
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        const DropdownMenuItem(value: '', child: Text('Nenhum / Não aplicável')),
        for (final p in properties)
          DropdownMenuItem(value: p.id, child: Text(p.title)),
      ],
      onChanged: (v) => onChanged(v == '' ? null : v),
    );
  }
}
