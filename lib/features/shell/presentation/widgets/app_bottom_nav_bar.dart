import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
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

/// Floating, pill-shaped shell navigation. The shell remains responsible for
/// navigation and badge values; this widget only displays those inputs.
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
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final barColor = theme.brightness == Brightness.dark
        ? colors.elevatedSurface
        : colors.bodyText;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Material(
              key: const Key('bottom_navigation_pill'),
              color: barColor,
              borderRadius: AppRadius.pillRadius,
              elevation: 6,
              shadowColor: colors.bodyText.withValues(alpha: .20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: LayoutBuilder(builder: (context, constraints) {
                  if (items.isEmpty) return const SizedBox(height: 56);
                  // Four inactive controls retain 48px targets on a 320px
                  // screen; the selected item receives the remaining space.
                  final available = constraints.maxWidth;
                  final selectedWidth = math.min(
                    150.0,
                    math.max(48.0, available - 48.0 * (items.length - 1)),
                  );
                  final inactiveWidth = items.length > 1
                      ? math.max(
                          0.0, (available - selectedWidth) / (items.length - 1))
                      : 0.0;
                  return Row(
                    children: <Widget>[
                      for (final item in items)
                        SizedBox(
                          width: item.tab == currentTab
                              ? selectedWidth
                              : inactiveWidth,
                          child: _NavButton(
                            key: Key('nav_${item.tab.name}'),
                            item: item,
                            selected: item.tab == currentTab,
                            colors: colors,
                            onTap: () => onSelected(item.tab),
                          ),
                        ),
                    ],
                  );
                }),
              ),
            ),
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
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final duration = media.disableAnimations || media.accessibleNavigation
        ? Duration.zero
        : const Duration(milliseconds: 200);
    final count = item.badgeCount > 99
        ? '99+'
        : MaterialLocalizations.of(context).formatDecimal(item.badgeCount);
    final label = item.badgeCount > 0 ? '${item.label}, $count' : item.label;
    final iconColor =
        selected ? colors.onPrimary : colors.onPrimary.withValues(alpha: .72);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: Tooltip(
        message: item.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.pillRadius,
            child: AnimatedContainer(
              duration: duration,
              height: 56,
              decoration: BoxDecoration(
                color: selected ? colors.primary : Colors.transparent,
                borderRadius: AppRadius.pillRadius,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _NavIcon(
                      item: item,
                      color: iconColor,
                      colors: colors,
                      selected: selected),
                  if (selected) ...<Widget>[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon(
      {required this.item,
      required this.color,
      required this.colors,
      required this.selected});

  final AppNavItem item;
  final Color color;
  final AppSemanticColors colors;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final count = item.badgeCount > 99
        ? '99+'
        : MaterialLocalizations.of(context).formatDecimal(item.badgeCount);
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Icon(item.icon, color: color, size: 24),
        if (item.badgeCount > 0)
          PositionedDirectional(
            top: -8,
            end: -10,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 3),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? colors.onPrimary : colors.primary,
                borderRadius: AppRadius.pillRadius,
              ),
              child: Text(
                count,
                maxLines: 1,
                textScaler: TextScaler.noScaling,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected ? colors.primary : colors.onPrimary,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}
