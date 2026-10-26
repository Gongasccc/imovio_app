import 'package:flutter/material.dart';

/// Mostra um ecrã cujo código só é descarregado quando é aberto pela
/// primeira vez (import "deferred"). Assim a app arranca mais depressa,
/// sobretudo no telemóvel: mapa, PDFs e estudo de mercado não atrasam o
/// início.
class DeferredScreen extends StatefulWidget {
  const DeferredScreen({super.key, required this.load, required this.builder});
  final Future<void> Function() load;
  final WidgetBuilder builder;

  @override
  State<DeferredScreen> createState() => _DeferredScreenState();
}

class _DeferredScreenState extends State<DeferredScreen> {
  late final Future<void> _loading = widget.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loading,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(),
              body: Center(
                child: Text('Não foi possível abrir: ${snapshot.error}'),
              ),
            );
          }
          return widget.builder(context);
        }
        return Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
