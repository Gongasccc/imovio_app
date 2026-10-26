import 'package:flutter/material.dart';
import 'package:imovio/src/constants/app_sizes.dart';
import 'package:imovio/src/constants/app_theme.dart';
import 'package:imovio/src/features/properties/application/sale_summary.dart';
import 'package:imovio/src/utils/format.dart';

/// Resumo financeiro da venda: do preço anunciado até ao lucro real.
class SaleSummaryCard extends StatelessWidget {
  const SaleSummaryCard({super.key, required this.summary});
  final SaleSummary summary;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    final profitColor = s.profit >= 0 ? AppColors.green : AppColors.red;

    Widget row(
      String label,
      String value, {
      String? note,
      bool strong = false,
      Color? color,
    }) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                if (note != null)
                  Text(note, style: TextStyle(fontSize: 12, color: muted)),
              ],
            ),
          ),
          gapW12,
          Text(
            value,
            style: TextStyle(
              fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
              fontSize: strong ? 16 : 14,
              color: color,
            ),
          ),
        ],
      ),
    );

    final discount = s.discount;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Sizes.p20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  s.isSold ? Icons.verified_outlined : Icons.insights,
                  size: 20,
                  color: scheme.primary,
                ),
                gapW8,
                Expanded(
                  child: Text(
                    s.isSold ? 'Resumo da venda' : 'Previsão da venda',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (s.daysOnMarket != null)
                  Text(
                    '${s.daysOnMarket} dias no mercado',
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
              ],
            ),
            if (!s.isSold)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Muda o estado para "Vendido / Escriturado" quando fechar. '
                  'Até lá, as contas usam o preço anunciado.',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ),
            gapH12,
            row('Preço anunciado', Format.euros(s.listedPrice)),
            row(
              s.isSold ? 'Vendido por' : 'Valor de venda previsto',
              Format.euros(s.salePrice),
              note: discount == null || discount == 0
                  ? null
                  : discount > 0
                  ? '${Format.euros(discount)} abaixo do anunciado '
                        '(${Format.percent(s.discountPct)})'
                  : '${Format.euros(-discount)} acima do anunciado',
            ),
            const Divider(height: 20),
            if (s.isShared)
              row(
                'Comissão total (partilha)',
                Format.eurosWithCents(s.totalCommission),
                note: s.commissionPct == null
                    ? 'Indique a comissão (%)'
                    : '${Format.number(s.commissionPct)} % do valor de venda',
              ),
            row(
              'Comissão da agência',
              Format.eurosWithCents(s.agencyCommission),
              note: s.isShared
                  ? '${Format.number(s.sharePct)} % da comissão (partilha)'
                  : s.commissionPct == null
                  ? 'Indique a comissão (%)'
                  : '${Format.number(s.commissionPct)} % do valor de venda',
            ),
            row(
              'A sua parte',
              Format.eurosWithCents(s.agentShare),
              note: '${Format.number(s.agentSplitPct)} % da comissão',
            ),
            row(
              'IVA',
              '− ${Format.eurosWithCents(s.vat)}',
              note: '${Format.number(s.vatPct)} % da sua parte · fica '
                  '${Format.eurosWithCents(s.agentShareNet)}',
            ),
            row(
              'Despesas do imóvel',
              '− ${Format.eurosWithCents(s.expensesTotal)}',
              note: s.expensesCount == 0
                  ? 'Sem despesas registadas'
                  : '${s.expensesCount} despesa(s), ver aba Despesas',
            ),
            const Divider(height: 20),
            Container(
              padding: const EdgeInsets.all(Sizes.p12),
              decoration: BoxDecoration(
                color: profitColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: row(
                'Lucro real',
                Format.eurosWithCents(s.profit),
                note: s.profitOnSalePct == null
                    ? null
                    : '${Format.percent(s.profitOnSalePct, decimals: 2)} do valor de venda',
                strong: true,
                color: profitColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
