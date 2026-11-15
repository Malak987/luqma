import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../cubit/main_shell_state.dart';

/// One destination of [AppBottomNavBar].
class AppNavItem {
  const AppNavItem({
    required this.tab,
    required this.icon,
    required this.label,
    this.badgeCount = 0,
  });

  final MainShellTab tab;
  final IconData icon;
  final String label;
  final int badgeCount;
}

/// Presentational bottom navigation bar: it knows nothing about cubits or
/// routing, only which item is selected and what to call when one is tapped.
/// A [Row] follows the ambient text direction, so the order mirrors in Arabic.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    required this.items,
    required this.currentTab,
    required this.onSelected,
    super.key,
  });

  final List<AppNavItem> items;
  final MainShellTab currentTab;
  final ValueChanged<MainShellTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: colors.primary.withValues(alpha: .6)),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          child: Row(
            children: <Widget>[
              for (final item in items)
                Expanded(
                  child: _NavButton(
                    key: Key('nav_${item.tab.name}'),
                    item: item,
                    selected: item.tab == currentTab,
                    colors: colors,
                    onTap: () => onSelected(item.tab),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.colors,
    required this.onTap,
    super.key,
  });

  final AppNavItem item;
  final bool selected;
  final AppSemanticColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: selected ? colors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.icon,
                    color:
                        selected ? colors.onPrimary : colors.inactiveNavigation,
                  ),
                ),
                if (item.badgeCount > 0)
                  PositionedDirectional(
                    top: 2,
                    start: 2,
                    child: Container(
                      constraints:
                          const BoxConstraints(minWidth: 18, minHeight: 18),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: colors.surface, width: 1.5),
                      ),
                      child: Text(
                        item.badgeCount > 99 ? '99+' : '${item.badgeCount}',
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.onPrimary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? colors.headingText : colors.inactiveNavigation,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
