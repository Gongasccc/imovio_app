import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:imovio/src/common_widgets/glass.dart';
import 'package:imovio/src/constants/app_sizes.dart';
import 'package:imovio/src/constants/app_theme.dart';
import 'package:imovio/src/routing/app_router.dart';

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// A mesma ordem dos ramos em [goRouter].
const _destinations = [
  _Destination('Início', Icons.dashboard_outlined, Icons.dashboard),
  _Destination('Contactos', Icons.people_outline, Icons.people),
  _Destination('Imóveis', Icons.home_outlined, Icons.home),
  _Destination('Pipeline', Icons.view_kanban_outlined, Icons.view_kanban),
  _Destination('Tarefas', Icons.task_alt_outlined, Icons.task_alt),
];

/// Páginas que não são separadores (abrem por cima), no menu e na barra
/// lateral.
const _extraPages = [
  (AppRoute.goals, 'Objetivos', Icons.flag_outlined),
  (AppRoute.map, 'Mapa', Icons.map_outlined),
  (AppRoute.settings, 'Configurações', Icons.settings_outlined),
];

/// Quantos destinos aparecem na barra inferior do telemóvel. Os restantes
/// (e as Configurações) ficam no menu lateral.
const _bottomBarCount = 3;

class _Logo extends StatelessWidget {
  const _Logo({this.showName = true});
  final bool showName;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.goldLight, AppColors.gold],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.home_work, size: 20, color: AppColors.darkBg),
        ),
        if (showName) ...[
          gapW8,
          const Text(
            'Imovio',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ],
    );
  }
}

/// Telemóvel: barra inferior com Início, Contactos e Imóveis, e menu lateral
/// com tudo (incluindo Pipeline, Tarefas e Configurações).
/// Ecrãs largos: barra lateral fixa. Baseado no esqueleto.
class ScaffoldWithNestedNavigation extends StatelessWidget {
  const ScaffoldWithNestedNavigation({Key? key, required this.navigationShell})
    : super(key: key ?? const ValueKey('ScaffoldWithNestedNavigation'));
  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    HapticFeedback.selectionClick();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) return _mobile(context);
    final extended = width >= wideBreakpoint + 200;
    final glass = Theme.of(context).extension<GlassTheme>()!;
    return Scaffold(
      body: Row(
        children: [
          ColoredBox(
            color: glass.bar,
            child: NavigationRail(
              extended: extended,
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _goBranch,
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: Sizes.p16),
                child: _Logo(showName: extended),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: Sizes.p16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        for (final (route, label, icon) in _extraPages)
                          IconButton(
                            tooltip: label,
                            icon: Icon(icon),
                            onPressed: () => context.pushNamed(route.name),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
          ),
          VerticalDivider(thickness: 1, width: 1, color: glass.edge),
          Expanded(child: SafeArea(left: false, child: navigationShell)),
        ],
      ),
    );
  }

  Widget _mobile(BuildContext context) {
    final current = navigationShell.currentIndex;
    final inBottomBar = current < _bottomBarCount;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(toolbarHeight: 52, titleSpacing: 0, title: const _Logo()),
      // Deslizar da esquerda para a direita (nos primeiros 80 px) abre o menu.
      drawerEdgeDragWidth: 80,
      drawer: FrostedGlass(
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
        sigma: 24,
        child: NavigationDrawer(
          selectedIndex: current,
          onDestinationSelected: (i) {
            Navigator.of(context).pop();
            if (i < _destinations.length) {
              _goBranch(i);
            } else {
              context.pushNamed(_extraPages[i - _destinations.length].$1.name);
            }
          },
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(28, 20, 16, 16),
              child: Align(alignment: Alignment.centerLeft, child: _Logo()),
            ),
            for (final d in _destinations)
              NavigationDrawerDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: Text(d.label),
              ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 28, vertical: 8),
              child: Divider(),
            ),
            for (final (_, label, icon) in _extraPages)
              NavigationDrawerDestination(icon: Icon(icon), label: Text(label)),
          ],
        ),
      ),
      body: SafeArea(top: false, bottom: false, child: navigationShell),
      // Em Pipeline e Tarefas (que estão no menu) nenhum botão fica marcado.
      // Barra flutuante de vidro, com o fundo desfocado por trás.
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: FrostedGlass(
            borderRadius: BorderRadius.circular(26),
            child: NavigationBarTheme(
              data: theme.navigationBarTheme.copyWith(
                indicatorColor: inBottomBar ? null : Colors.transparent,
              ),
              child: NavigationBar(
                height: 64,
                selectedIndex: inBottomBar ? current : 0,
                onDestinationSelected: _goBranch,
                destinations: [
                  for (final (i, d)
                      in _destinations.take(_bottomBarCount).indexed)
                    NavigationDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(
                        inBottomBar || i != 0 ? d.selectedIcon : d.icon,
                      ),
                      label: d.label,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
