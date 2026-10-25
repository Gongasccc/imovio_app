import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
import 'package:imovio/src/routing/app_router.dart';
import 'package:imovio/src/utils/format.dart';

/// Linha compacta de um imóvel, com miniatura, usada em sugestões e listas.
class PropertyListTile extends StatelessWidget {
  const PropertyListTile({super.key, required this.property});
  final Property property;

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
      subtitle: Text('${p.tags} · ${p.concelho ?? 'Local'}'),
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

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget placeholder(IconData icon) => Container(
          width: width,
          height: height,
          color: bg,
          alignment: Alignment.center,
          child: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
        );
    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      // Na web, fotos de sites sem CORS (portais de anúncios) aparecem
      // através de um elemento <img> em vez de falharem.
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : placeholder(Icons.image_outlined),
      errorBuilder: (_, _, _) => placeholder(Icons.broken_image_outlined),
    );
  }
}
