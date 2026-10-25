import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imovio/src/common_widgets/section_card.dart';
import 'package:imovio/src/constants/app_sizes.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/expenses/data/expenses_repository.dart';
import 'package:imovio/src/features/expenses/domain/expense.dart';
import 'package:imovio/src/features/expenses/presentation/expense_dialog.dart';
import 'package:imovio/src/utils/format.dart';
import 'package:imovio/src/utils/run_action.dart';

/// Lista de despesas de um imóvel, com total e totais por categoria.
/// As despesas guardam-se logo, sem precisar de "Guardar Alterações".
class PropertyExpensesSection extends ConsumerWidget {
  const PropertyExpensesSection({super.key, required this.propertyId});
  final String propertyId;

  Future<void> _edit(BuildContext context, WidgetRef ref, [Expense? e]) async {
    final result = await showExpenseDialog(
      context,
      propertyId: propertyId,
      expense: e,
    );
    if (result == null || !context.mounted) return;
    final uid = ref.read(currentUidProvider);
    final repo = ref.read(expensesRepositoryProvider);
    await runAction(
      context,
      () => e == null
          ? repo.addExpense(uid: uid, expense: result)
          : repo.updateExpense(uid: uid, expense: result),
      success: e == null ? 'Despesa adicionada' : 'Despesa atualizada',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses =
        ref.watch(expensesByPropertyProvider)[propertyId] ?? const [];
    final total = expenses.fold<num>(0, (s, e) => s + e.amount);
    final byCategory = <String, num>{};
    for (final e in expenses) {
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
    }
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'Despesas do imóvel',
          icon: Icons.receipt_long_outlined,
          trailing: FilledButton.tonalIcon(
            icon: const Icon(Icons.add),
            label: const Text('Nova despesa'),
            onPressed: () => _edit(context, ref),
          ),
          child: expenses.isEmpty
              ? Text(
                  'Sem despesas. Registe aqui fotografia, publicidade, '
                  'certidões, deslocações e outros custos: entram no lucro '
                  'real da venda.',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                )
              : Column(
                  children: [
                    for (final (i, e) in expenses.indexed) ...[
                      if (i > 0) const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        onTap: () => _edit(context, ref, e),
                        leading: CircleAvatar(
                          backgroundColor: scheme.primary.withValues(
                            alpha: 0.12,
                          ),
                          child: Icon(
                            Icons.receipt_outlined,
                            size: 20,
                            color: scheme.primary,
                          ),
                        ),
                        title: Text(
                          e.description,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${e.category} · ${Format.date(e.date)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              Format.eurosWithCents(e.amount),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Eliminar',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => confirmAndDelete(
                                context,
                                () => ref
                                    .read(expensesRepositoryProvider)
                                    .deleteExpense(
                                      uid: ref.read(currentUidProvider),
                                      id: e.id,
                                    ),
                                success: 'Despesa eliminada',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
        ),
        if (expenses.isNotEmpty) ...[
          gapH16,
          SectionCard(
            title: 'Total: ${Format.eurosWithCents(total)}',
            icon: Icons.summarize_outlined,
            child: Column(
              children: [
                for (final entry in byCategory.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text(entry.key)),
                        Text(Format.eurosWithCents(entry.value)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
