import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:imovio/src/common_widgets/empty_placeholder.dart';
import 'package:imovio/src/routing/app_router.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: EmptyPlaceholder(
        icon: Icons.search_off,
        message: 'Página não encontrada.',
        action: FilledButton(
          onPressed: () => context.goNamed(AppRoute.dashboard.name),
          child: const Text('Voltar ao início'),
        ),
      ),
    );
  }
}
