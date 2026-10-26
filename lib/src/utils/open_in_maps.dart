import 'package:flutter/material.dart';
import 'package:imovio/src/utils/launcher.dart';

/// Abre a localização numa app de mapas à escolha. Usa as coordenadas quando
/// existem; senão pesquisa pela morada.
Future<void> showOpenInMapsSheet(
  BuildContext context, {
  double? lat,
  double? lng,
  String? address,
}) async {
  final hasPoint = lat != null && lng != null;
  final query = hasPoint ? '$lat,$lng' : (address ?? '');
  if (query.trim().isEmpty) return;
  final options = <(String, IconData, Uri)>[
    (
      'Google Maps',
      Icons.map_outlined,
      Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': query}),
    ),
    (
      'Apple Mapas',
      Icons.apple,
      Uri.https('maps.apple.com', '/', {
        if (hasPoint) 'll': '$lat,$lng',
        'q': address?.isNotEmpty == true ? address! : query,
      }),
    ),
    (
      'Waze',
      Icons.navigation_outlined,
      Uri.https('waze.com', '/ul', {
        if (hasPoint) 'll': '$lat,$lng' else 'q': query,
        'navigate': 'yes',
      }),
    ),
  ];
  final chosen = await showModalBottomSheet<Uri>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Abrir em',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          for (final (label, icon, uri) in options)
            ListTile(
              leading: Icon(icon),
              title: Text(label),
              onTap: () => Navigator.pop(context, uri),
            ),
        ],
      ),
    ),
  );
  if (chosen != null) await openExternalUrl(chosen.toString());
}
