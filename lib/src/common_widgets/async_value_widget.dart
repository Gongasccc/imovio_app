import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imovio/src/common_widgets/empty_placeholder.dart';

/// Mostra carregamento, erro ou dados de um [AsyncValue] de forma consistente.
class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({super.key, required this.value, required this.data});
  final AsyncValue<T> value;
  final Widget Function(T) data;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      error: (e, st) => EmptyPlaceholder(
        icon: Icons.error_outline,
        message: 'Ocorreu um erro: $e',
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}
