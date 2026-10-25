import 'package:flutter/material.dart';
import 'package:imovio/src/common_widgets/date_time_field.dart';
import 'package:imovio/src/common_widgets/form_fields.dart';
import 'package:imovio/src/constants/app_sizes.dart';
import 'package:imovio/src/features/expenses/domain/expense.dart';
import 'package:imovio/src/utils/format.dart';

/// Diálogo para criar ou editar uma despesa. Devolve a despesa preenchida,
/// ou null se o utilizador cancelar.
Future<Expense?> showExpenseDialog(
  BuildContext context, {
  required String propertyId,
  Expense? expense,
}) => showDialog<Expense>(
  context: context,
  builder: (_) => _ExpenseDialog(propertyId: propertyId, expense: expense),
);

class _ExpenseDialog extends StatefulWidget {
  const _ExpenseDialog({required this.propertyId, this.expense});
  final String propertyId;
  final Expense? expense;

  @override
  State<_ExpenseDialog> createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends State<_ExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _description = TextEditingController(
    text: widget.expense?.description,
  );
  late final _amount = TextEditingController(
    text: widget.expense?.amount.toString() ?? '',
  );
  late String _category =
      widget.expense?.category ?? ExpenseCategories.all.first;
  late DateTime? _date = widget.expense?.date ?? DateTime.now();

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      Expense(
        id: widget.expense?.id ?? '',
        propertyId: widget.propertyId,
        description: _description.text.trim(),
        category: _category,
        amount: parseNum(_amount.text)!,
        date: _date,
        createdAt: widget.expense?.createdAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.expense == null ? 'Nova despesa' : 'Editar despesa'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _description,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    hintText: 'ex: Sessão fotográfica, certidão de teor...',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Indique a descrição'
                      : null,
                ),
                gapH16,
                TextFormField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Valor',
                    suffixText: '€',
                  ),
                  validator: (v) {
                    final n = parseNum(v);
                    return (n == null || n <= 0) ? 'Indique o valor' : null;
                  },
                ),
                gapH16,
                TextDropdown(
                  label: 'Categoria',
                  value: _category,
                  options: ExpenseCategories.all,
                  onChanged: (v) => setState(() => _category = v ?? _category),
                ),
                gapH16,
                DateTimeField(
                  label: 'Data',
                  withTime: false,
                  value: _date,
                  onChanged: (v) => setState(() => _date = v),
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
