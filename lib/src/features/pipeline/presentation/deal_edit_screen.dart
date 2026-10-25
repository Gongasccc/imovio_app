import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:imovio/src/common_widgets/async_value_widget.dart';
import 'package:imovio/src/common_widgets/empty_placeholder.dart';
import 'package:imovio/src/common_widgets/form_fields.dart';
import 'package:imovio/src/common_widgets/record_pickers.dart';
import 'package:imovio/src/common_widgets/responsive_center.dart';
import 'package:imovio/src/constants/app_sizes.dart';
import 'package:imovio/src/features/pipeline/data/deals_repository.dart';
import 'package:imovio/src/features/pipeline/domain/deal.dart';
import 'package:imovio/src/features/pipeline/presentation/deal_edit_controller.dart';
import 'package:imovio/src/utils/async_value_ui.dart';
import 'package:imovio/src/utils/dialogs.dart';
import 'package:imovio/src/utils/format.dart';

class DealEditScreen extends ConsumerWidget {
  const DealEditScreen({
    super.key,
    this.dealId,
    this.initialContactId,
    this.initialPropertyId,
  });
  final DealID? dealId;
  final String? initialContactId;
  final String? initialPropertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (dealId == null) {
      return _DealForm(
        deal: Deal(
          id: '',
          title: '',
          contactId: initialContactId,
          propertyId: initialPropertyId,
        ),
        isNew: true,
      );
    }
    return AsyncValueWidget<List<Deal>>(
      value: ref.watch(dealsStreamProvider),
      data: (deals) {
        final deal = deals.where((d) => d.id == dealId).firstOrNull;
        if (deal == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyPlaceholder(
              icon: Icons.handshake_outlined,
              message: 'Este negócio já não existe.',
            ),
          );
        }
        return _DealForm(key: ValueKey(deal.id), deal: deal, isNew: false);
      },
    );
  }
}

class _DealForm extends ConsumerStatefulWidget {
  const _DealForm({super.key, required this.deal, required this.isNew});
  final Deal deal;
  final bool isNew;

  @override
  ConsumerState<_DealForm> createState() => _DealFormState();
}

class _DealFormState extends ConsumerState<_DealForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.deal.title);
  late final _value =
      TextEditingController(text: widget.deal.value?.toString() ?? '');
  late final _notes = TextEditingController(text: widget.deal.notes);
  late String? _contactId = widget.deal.contactId;
  late String? _propertyId = widget.deal.propertyId;
  late String _stage = widget.deal.stage;

  @override
  void dispose() {
    _title.dispose();
    _value.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final deal = Deal(
      id: widget.deal.id,
      title: _title.text.trim(),
      contactId: _contactId,
      propertyId: _propertyId,
      value: parseNum(_value.text),
      stage: _stage,
      notes: emptyToNull(_notes.text),
      createdAt: widget.deal.createdAt,
    );
    final ok = await ref
        .read(dealEditControllerProvider.notifier)
        .submit(deal, isNew: widget.isNew);
    if (ok && mounted) {
      showSnack(context, widget.isNew ? 'Negócio criado' : 'Negócio atualizado');
      context.pop();
    }
  }

  Future<void> _delete() async {
    if (!await showConfirmDialog(context) || !mounted) return;
    final ok = await ref
        .read(dealEditControllerProvider.notifier)
        .delete(widget.deal.id);
    if (ok && mounted) {
      showSnack(context, 'Negócio eliminado');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(dealEditControllerProvider,
        (_, s) => s.showSnackBarOnError(context));
    final saving = ref.watch(dealEditControllerProvider).isLoading;
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.isNew ? 'Novo Negócio no Pipeline' : 'Editar Negócio'),
        actions: [
          if (!widget.isNew)
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline),
              onPressed: saving ? null : _delete,
            ),
          gapW8,
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            ResponsiveCenter(
              maxContentWidth: 720,
              padding: const EdgeInsets.all(Sizes.p16),
              child: FormGrid(children: [
                FullWidth(
                  child: TextFormField(
                    controller: _title,
                    decoration: const InputDecoration(
                      labelText: 'Título do Negócio',
                      hintText:
                          'ex: Terreno Rua João de Deus - Charneca da Caparica',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Indique o título'
                        : null,
                  ),
                ),
                ContactPicker(
                  label: 'Cliente Associado',
                  value: _contactId,
                  emptyLabel: 'Selecionar Cliente...',
                  required: true,
                  onChanged: (v) => setState(() => _contactId = v),
                ),
                PropertyPicker(
                  label: 'Imóvel Associado',
                  value: _propertyId,
                  onChanged: (v) => setState(() => _propertyId = v),
                ),
                TextFormField(
                  controller: _value,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Valor (€)', hintText: '4080'),
                  validator: (v) =>
                      parseNum(v) == null ? 'Indique o valor' : null,
                ),
                TextDropdown(
                  label: 'Fase do Negócio',
                  value: _stage,
                  options: DealStages.all,
                  onChanged: (v) => setState(() => _stage = v ?? _stage),
                ),
                FullWidth(
                  child: TextFormField(
                    controller: _notes,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Notas'),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Sizes.p12),
          child: FilledButton(
            onPressed: saving ? null : _save,
            child: Text(widget.isNew ? 'Guardar Negócio' : 'Guardar alterações'),
          ),
        ),
      ),
    );
  }
}
