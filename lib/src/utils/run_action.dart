import 'package:flutter/material.dart';
import 'package:imovio/src/utils/dialogs.dart';

/// Corre uma ação rápida (eliminar, duplicar, mover) e mostra o resultado
/// numa snackbar em vez dos `alert()` da app original.
Future<bool> runAction(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
}) async {
  try {
    await action();
    if (context.mounted && success != null) showSnack(context, success);
    return true;
  } catch (e) {
    if (context.mounted) showSnack(context, 'Erro: $e', error: true);
    return false;
  }
}

/// Pede confirmação e elimina.
Future<void> confirmAndDelete(
  BuildContext context,
  Future<void> Function() delete, {
  String message = 'Deseja eliminar este registo?',
  String success = 'Registo eliminado',
}) async {
  final ok = await showConfirmDialog(context, message: message);
  if (ok && context.mounted) {
    await runAction(context, delete, success: success);
  }
}
