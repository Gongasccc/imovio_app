import 'package:flutter/material.dart';
import 'package:imovio/src/constants/app_sizes.dart';

/// Título e subtítulo de cada página, com as ações à direita (ou por baixo
/// no telemóvel), como o `.page-header` do HTML.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titles = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (subtitle != null) ...[
          gapH4,
          Text(
            subtitle!,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
    return LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < 600;
      final buttons = Wrap(spacing: Sizes.p8, runSpacing: Sizes.p8, children: actions);
      if (narrow) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [titles, if (actions.isNotEmpty) ...[gapH12, buttons]],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Expanded(child: titles), buttons],
      );
    });
  }
}
