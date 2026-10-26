import 'package:flutter/material.dart';
import 'package:imovio/src/common_widgets/date_time_field.dart';
import 'package:imovio/src/constants/app_sizes.dart';
import 'package:imovio/src/features/interactions/domain/interaction.dart';

/// Registar à mão um contacto com o cliente (chamada, reunião, nota...) ou a
/// opinião depois de uma visita ([visit] preenchido).
Future<Interaction?> showInteractionDialog(
  BuildContext context, {
  required String contactId,
  String? propertyId,
  String? taskId,
  bool visit = false,
}) =>
    showDialog<Interaction>(
      context: context,
      builder: (_) => _InteractionDialog(
        contactId: contactId,
        propertyId: propertyId,
        taskId: taskId,
        visit: visit,
      ),
    );

class _InteractionDialog extends StatefulWidget {
  const _InteractionDialog({
    required this.contactId,
    required this.propertyId,
    required this.taskId,
    required this.visit,
  });
  final String contactId;
  final String? propertyId;
  final String? taskId;
  final bool visit;

  @override
  State<_InteractionDialog> createState() => _InteractionDialogState();
}

class _InteractionDialogState extends State<_InteractionDialog> {
  final _note = TextEditingController();
  late var _kind = widget.visit ? InteractionKind.visit : InteractionKind.call;
  var _at = DateTime.now();
  int? _rating;
  String? _price;
  bool? _interested;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isVisit = _kind == InteractionKind.visit;
    return AlertDialog(
      title: Text(widget.visit ? 'Como correu a visita?' : 'Registar contacto'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.visit) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final k in InteractionKind.values)
                      ChoiceChip(
                        avatar: Icon(k.icon, size: 16),
                        label: Text(k.label),
                        selected: _kind == k,
                        onSelected: (_) => setState(() => _kind = k),
                      ),
                  ],
                ),
                gapH16,
                DateTimeField(
                  label: 'Quando',
                  value: _at,
                  onChanged: (v) => setState(() => _at = v ?? DateTime.now()),
                ),
                gapH16,
              ],
              if (isVisit) ...[
                const Text('Gostou do imóvel?'),
                Row(
                  children: [
                    for (var i = 1; i <= 5; i++)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          i <= (_rating ?? 0) ? Icons.star : Icons.star_border,
                          color: scheme.primary,
                        ),
                        onPressed: () => setState(() => _rating = i),
                      ),
                  ],
                ),
                gapH8,
                const Text('O preço pareceu-lhe'),
                gapH8,
                Wrap(
                  spacing: 6,
                  children: [
                    for (final p in Interaction.priceOpinions)
                      ChoiceChip(
                        label: Text(p),
                        selected: _price == p,
                        onSelected: (on) =>
                            setState(() => _price = on ? p : null),
                      ),
                  ],
                ),
                gapH12,
                const Text('Ficou interessado?'),
                gapH8,
                Wrap(
                  spacing: 6,
                  children: [
                    ChoiceChip(
                      label: const Text('Sim'),
                      selected: _interested == true,
                      onSelected: (on) =>
                          setState(() => _interested = on ? true : null),
                    ),
                    ChoiceChip(
                      label: const Text('Não'),
                      selected: _interested == false,
                      onSelected: (on) =>
                          setState(() => _interested = on ? false : null),
                    ),
                  ],
                ),
                gapH16,
              ],
              TextField(
                controller: _note,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: isVisit
                      ? 'Objeções e comentários'
                      : 'O que se falou',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.visit ? 'Saltar' : 'Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            Interaction(
              id: '',
              contactId: widget.contactId,
              kind: _kind,
              at: _at,
              propertyId: widget.propertyId,
              taskId: widget.taskId,
              note: _note.text.trim().isEmpty ? null : _note.text.trim(),
              rating: isVisit ? _rating : null,
              priceOpinion: isVisit ? _price : null,
              interested: isVisit ? _interested : null,
            ),
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
