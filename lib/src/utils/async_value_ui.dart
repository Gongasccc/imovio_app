import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imovio/src/utils/dialogs.dart';

extension AsyncValueUI on AsyncValue<Object?> {
  /// Mostra um aviso quando um controller termina com erro.
  void showSnackBarOnError(BuildContext context) {
    if (!isLoading && hasError) {
      showSnack(context, 'Erro: $error', error: true);
    }
  }
}
