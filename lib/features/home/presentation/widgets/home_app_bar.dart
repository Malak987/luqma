import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

/// Header of the Home tab: the Luqma wordmark (same artwork as the login
/// screen) with favourites and notifications, then greeting and address.
class HomeAppBar extends StatelessWidget {
  const HomeAppBar({
    required this.userName,
    this.deliveryAddress,
    this.onNotificationsPressed,
    this.onFavoritesPressed,
    this.favoritesCount = 0,
    this.hasUnreadNotifications = false,
    super.key,
  });

  static const double _logoHeight = 56;
  static const double _logoAspect = 1315 / 841;

  final String? userName;
  final String? deliveryAddress;
  final VoidCallback? onNotificationsPressed;
  final VoidCallback? onFavoritesPressed;
  final int favoritesCount;
  final bool hasUnreadNotifications;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Semantics(
                  image: true,
                  label: l10n.common.brandName,
                  excludeSemantics: true,
                  child: Image.asset(
                    isDark ? AppAssets.logoDark : AppAssets.logoLight,
                    height: _logoHeight,
                    width: _logoHeight * _logoAspect,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: _logoHeight,
                      width: _logoHeight * _logoAspect,
                    ),
                  ),
                ),
                const Spacer(),
                _AppBarAction(
                  icon: Icons.favorite_border_rounded,
                  label: l10n.navigation.favorites,
                  onTap: onFavoritesPressed,
                  count: favoritesCount,
                ),
                const SizedBox(width: AppSpacing.xs),
                _AppBarAction(
                  icon: Icons.notifications_none_rounded,
                  label: l10n.home.notificationsLabel,
                  onTap: onNotificationsPressed,
                  showDot: hasUnreadNotifications,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.home.greeting(userName),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colors.headingText,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (deliveryAddress?.trim().isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.xs),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(color: colors.border),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.sm,
                    5,
                    AppSpacing.sm,
                    5,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 15, color: colors.primary),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          deliveryAddress!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.mutedText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Icon(Icons.keyboard_arrow_down_rounded,
                          size: 16, color: colors.mutedText),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AppBarAction extends StatelessWidget {
  const _AppBarAction({
    required this.icon,
    required this.label,
    this.onTap,
    this.count = 0,
    this.showDot = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final int count;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.largeRadius,
          side: BorderSide(color: colors.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.largeRadius,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: colors.headingText, size: 23),
                if (count > 0)
                  PositionedDirectional(
                    top: -4,
                    end: -4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: AppRadius.pillRadius,
                        border: Border.all(color: colors.background, width: 2),
                      ),
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Center(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              count > 99 ? '99+' : '$count',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.onPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else if (showDot)
                  PositionedDirectional(
                    top: 10,
                    end: 10,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: colors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.surface, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
