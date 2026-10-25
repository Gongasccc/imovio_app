import 'package:flutter/material.dart';

/// Ícone pequeno seguido de texto, para metadados (cliente, imóvel, data).
/// Substitui os emojis, que alguns browsers mostram como quadrados.
class IconLabel extends StatelessWidget {
  const IconLabel({
    super.key,
    required this.icon,
    required this.text,
    this.color,
    this.fontSize = 12,
    this.maxLines = 1,
  });
  final IconData icon;
  final String text;
  final Color? color;
  final double fontSize;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: fontSize + 2, color: c),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: fontSize, color: c),
          ),
        ),
      ],
    );
  }
}
