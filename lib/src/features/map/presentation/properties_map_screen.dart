import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:imovio/src/constants/app_theme.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/geo/data/geocoder.dart';
import 'package:imovio/src/features/properties/data/properties_repository.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
import 'package:imovio/src/features/properties/presentation/property_list_tile.dart';
import 'package:imovio/src/utils/format.dart';

/// Mapa dos imóveis. Os que ainda não têm coordenadas são localizados pelo
/// código postal, freguesia ou concelho e as coordenadas ficam guardadas.
class PropertiesMapScreen extends ConsumerStatefulWidget {
  const PropertiesMapScreen({super.key});

  @override
  ConsumerState<PropertiesMapScreen> createState() =>
      _PropertiesMapScreenState();
}

class _PropertiesMapScreenState extends ConsumerState<PropertiesMapScreen> {
  final _client = http.Client();
  final _tried = <String>{};
  var _locating = 0;
  var _showSold = false;
  Property? _selected;

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  /// Localiza, um de cada vez, os imóveis sem coordenadas.
  Future<void> _locateMissing(List<Property> properties) async {
    final missing = properties
        .where((p) => !p.hasLocation && _tried.add(p.id))
        .take(25)
        .toList();
    if (missing.isEmpty) return;
    setState(() => _locating += missing.length);
    final repo = ref.read(propertiesRepositoryProvider);
    final uid = ref.read(currentUidProvider);
    for (final p in missing) {
      final point = await geocodeProperty(_client, p);
      if (point != null) {
        try {
          await repo.setLocation(uid: uid, id: p.id, lat: point.$1, lng: point.$2);
        } catch (_) {
          // Sem gravar, o marcador aparece na próxima vez.
        }
      }
      if (!mounted) return;
      setState(() => _locating--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(propertiesStreamProvider).value ?? const <Property>[];
    WidgetsBinding.instance.addPostFrameCallback((_) => _locateMissing(all));
    final shown = all
        .where((p) => p.hasLocation && (_showSold || !p.isSold))
        .toList();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final points = [for (final p in shown) LatLng(p.lat!, p.lng!)];
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa (${shown.length})'),
        actions: [
          if (_locating > 0)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          FilterChip(
            label: const Text('Vendidos'),
            selected: _showSold,
            onSelected: (v) => setState(() => _showSold = v),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            key: ValueKey(points.length),
            options: MapOptions(
              initialCenter: const LatLng(38.72, -9.14),
              initialZoom: 9,
              initialCameraFit: points.length < 2
                  ? null
                  : CameraFit.bounds(
                      bounds: LatLngBounds.fromPoints(points),
                      padding: const EdgeInsets.all(48),
                      maxZoom: 15,
                    ),
              onTap: (_, _) => setState(() => _selected = null),
            ),
            children: [
              TileLayer(
                // Mapa do OpenStreetMap; no modo escuro as cores são
                // invertidas para combinar com a app.
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'pt.imovio.imovio',
                tileBuilder: dark ? darkModeTileBuilder : null,
              ),
              MarkerLayer(
                markers: [
                  for (final p in shown)
                    Marker(
                      point: LatLng(p.lat!, p.lng!),
                      width: 96,
                      height: 34,
                      child: GestureDetector(
                        onTap: () => setState(() => _selected = p),
                        child: _PriceMarker(
                          label: p.price == null ? '?' : _short(p.price!),
                          color: p.isSold
                              ? AppColors.green
                              : (_selected?.id == p.id
                                  ? scheme.onSurface
                                  : AppColors.gold),
                        ),
                      ),
                    ),
                ],
              ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© OpenStreetMap'),
                ],
              ),
            ],
          ),
          if (all.isNotEmpty && shown.isEmpty && _locating == 0)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Não foi possível localizar os imóveis. Indique o código '
                    'postal, a freguesia ou o concelho na ficha de cada um.',
                  ),
                ),
              ),
            ),
          if (_selected != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: PropertyListTile(property: _selected!),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _short(num price) => price >= 1000000
      ? '${(price / 1000000).toStringAsFixed(1)} M€'
      : price >= 1000
          ? '${(price / 1000).round()} mil €'
          : Format.euros(price);
}

class _PriceMarker extends StatelessWidget {
  const _PriceMarker({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black38)],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.darkBg,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
