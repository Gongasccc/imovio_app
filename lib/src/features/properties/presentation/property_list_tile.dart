import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
import 'package:imovio/src/routing/app_router.dart';
import 'package:imovio/src/utils/format.dart';

/// Linha compacta de um imóvel, com miniatura, usada em sugestões e listas.
class PropertyListTile extends StatelessWidget {
  const PropertyListTile({
    super.key,
    required this.property,
    this.subtitleExtra,
  });
  final Property property;
  final String? subtitleExtra;

  @override
  Widget build(BuildContext context) {
    final p = property;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () =>
          context.pushNamed(AppRoute.property.name, pathParameters: {'id': p.id}),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: PropertyImage(url: p.cover, width: 64, height: 48),
      ),
      title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text([
        p.tags,
        p.concelho ?? 'Local',
        ?subtitleExtra,
      ].join(' · ')),
      trailing: Text(
        Format.euros(p.price),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// Imagem de rede com placeholder enquanto carrega e em caso de erro.
///
/// Na web as fotos passam pelo images.weserv.nl, que as redimensiona para o
/// tamanho em que aparecem e acrescenta os cabeçalhos CORS que os portais de
/// anúncios não enviam. Antes usava-se um elemento <img> do browser, que no
/// telemóvel tornava as listas lentas e às vezes "engolia" os toques.
class PropertyImage extends StatelessWidget {
  const PropertyImage({
    super.key,
    required this.url,
    this.width,
    this.height,
  });
  final String url;
  final double? width;
  final double? height;

  static String webUrl(String url, int width, {String format = 'webp'}) {
    if (!url.startsWith('http')) return url;
    final encoded = Uri.encodeComponent(url);
    return 'https://images.weserv.nl/?url=$encoded&w=$width&output=$format&q=80';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget placeholder(IconData icon) => Container(
          width: width,
          height: height,
          color: scheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Icon(icon, color: scheme.onSurfaceVariant),
        );
    return LayoutBuilder(builder: (context, constraints) {
      final dpr = MediaQuery.devicePixelRatioOf(context);
      final logical = width ??
          (constraints.maxWidth.isFinite ? constraints.maxWidth : 600);
      // Arredonda a múltiplos de 200 px para reaproveitar a cache.
      final px = ((logical * dpr / 200).ceil() * 200).clamp(200, 1600).toInt();
      return Image.network(
        kIsWeb ? webUrl(url, px) : url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        cacheWidth: px,
        gaplessPlayback: true,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : placeholder(Icons.image_outlined),
        errorBuilder: (_, _, _) => placeholder(Icons.broken_image_outlined),
      );
    });
  }
}
