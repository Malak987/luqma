import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

/// Header of the Home tab: greeting, brand badge, delivery address and bell.
class HomeAppBar extends StatelessWidget {
  const HomeAppBar({
    required this.userName,
    this.deliveryAddress,
    this.onNotificationsPressed,
    this.hasUnreadNotifications = false,
    super.key,
  });

  final String? userName;
  final String? deliveryAddress;
  final VoidCallback? onNotificationsPressed;
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
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          l10n.home.greeting(userName),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colors.headingText,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(
                            alpha: isDark ? .25 : .08,
                          ),
                          borderRadius: AppRadius.pillRadius,
                          border: Border.all(
                            color: colors.primary.withValues(
                              alpha: isDark ? .6 : .22,
                            ),
                          ),
                        ),
                        child: Text(
                          l10n.common.brandBadge,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isDark ? colors.accent : colors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
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
                            Icon(
                              Icons.location_on_outlined,
                              size: 15,
                              color: colors.primary,
                            ),
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
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: colors.mutedText,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Material(
              color: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.largeRadius,
                side: BorderSide(color: colors.border),
              ),
              child: InkWell(
                onTap: onNotificationsPressed,
                borderRadius: AppRadius.largeRadius,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        color: colors.headingText,
                        size: 23,
                      ),
                      if (hasUnreadNotifications)
                        PositionedDirectional(
                          top: 10,
                          end: 10,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: colors.accent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colors.surface,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                    ],
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
