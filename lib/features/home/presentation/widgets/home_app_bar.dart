import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
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
            AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
        child: Row(
          children: [
            // Greeting block (start side)
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
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.primary
                              .withValues(alpha: isDark ? .25 : .08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: colors.primary
                                  .withValues(alpha: isDark ? .6 : .22)),
                        ),
                        child: Text(
                          l10n.common.brandBadge,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(
                                  color: isDark ? colors.accent : colors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  if (deliveryAddress != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.place, size: 14, color: colors.primary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            deliveryAddress!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: colors.mutedText),
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_down,
                            size: 16, color: colors.mutedText),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Bell (end side)
            InkWell(
              onTap: onNotificationsPressed,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.notifications_none_rounded,
                        color: colors.headingText),
                    if (hasUnreadNotifications)
                      PositionedDirectional(
                        top: 12,
                        start: 14,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                              color: colors.accent, shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}