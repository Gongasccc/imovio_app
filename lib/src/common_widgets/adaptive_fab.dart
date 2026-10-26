import 'package:flutter/material.dart';

/// Botão flutuante: com texto em ecrãs largos e só o ícone no telemóvel,
/// para não tapar os cartões da lista.
class AdaptiveFab extends StatelessWidget {
  const AdaptiveFab({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < 600) {
      return FloatingActionButton(
        tooltip: label,
        onPressed: onPressed,
        child: Icon(icon),
      );
    }
    return FloatingActionButton.extended(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
