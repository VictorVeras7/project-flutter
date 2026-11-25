import 'package:material_ui/material_ui.dart';

import '../theme/rango_theme.dart';

enum NavTab {
  home('Início', Icons.home_outlined, Icons.home_rounded),
  search('Buscar', Icons.search_rounded, Icons.search_rounded),
  orders('Pedidos', Icons.receipt_long_outlined, Icons.receipt_long_rounded),
  favorites('Favoritos', Icons.favorite_border_rounded, Icons.favorite_rounded),
  profile('Perfil', Icons.person_outline_rounded, Icons.person_rounded);

  const NavTab(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  // Ícone cheio na aba atual, como no protótipo.
  final IconData selectedIcon;
}

// Barra inferior das telas principais (Início, Buscar, Pedidos, Favoritos e Perfil).
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.current,
    required this.onSelect,
    this.badges = const {},
  });

  final NavTab current;
  final ValueChanged<NavTab> onSelect;
  // Número no canto do ícone (pedidos em andamento, favoritos).
  final Map<NavTab, int> badges;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Fica fora do Scaffold da tela: o Material dá base ao efeito de toque.
    return Material(
      color: colors.surface,
      shape: Border(top: BorderSide(color: colors.outline)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          6,
          8,
          6,
          20 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Row(
          children: [
            for (final tab in NavTab.values)
              Expanded(
                child: _NavItem(
                  tab: tab,
                  selected: tab == current,
                  badge: badges[tab] ?? 0,
                  onTap: () => onSelect(tab),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  final NavTab tab;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = selected ? colors.primary : colors.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: badge > 0 ? '${tab.label}, $badge' : tab.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 3,
                children: [
                  Icon(
                    selected ? tab.selectedIcon : tab.icon,
                    size: 23,
                    color: color,
                  ),
                  Text(
                    tab.label,
                    maxLines: 1,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (badge > 0)
              // Canto superior direito do ícone (right: 16px no protótipo).
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Align(
                  alignment: const Alignment(0.55, -1),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 17),
                    height: 17,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: RangoColors.primary,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    // widthFactor 1: o badge fica do tamanho do número.
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
