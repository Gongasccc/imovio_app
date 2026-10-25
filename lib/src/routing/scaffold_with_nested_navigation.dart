import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

/// Barra inferior no telemóvel e barra lateral em ecrãs largos, como a
/// app original (bottom-nav + sidebar). Baseado no esqueleto.
class ScaffoldWithNestedNavigation extends StatelessWidget {
  const ScaffoldWithNestedNavigation({
    Key? key,
    required this.navigationShell,
  }) : super(key: key ?? const ValueKey('ScaffoldWithNestedNavigation'));
  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) {
      return Scaffold(
        body: SafeArea(bottom: false, child: navigationShell),
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _goBranch,
          destinations: [
            for (final d in _destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
          ],
        ),
      );
    }
    final extended = width >= wideBreakpoint + 200;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _goBranch,
            labelType:
                extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: Sizes.p16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.home_work,
                        size: 20, color: AppColors.darkBg),
                  ),
                  if (extended) ...[
                    gapW8,
                    const Text('Imovio',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                  ],
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: Sizes.p16),
                  child: IconButton(
                    tooltip: 'Configurações',
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => context.pushNamed(AppRoute.settings.name),
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
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: SafeArea(left: false, child: navigationShell)),
        ],
      ),
    );
  }
}
