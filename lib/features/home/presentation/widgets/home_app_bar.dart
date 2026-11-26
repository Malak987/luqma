import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_logo.dart';

/// Header of the Home tab.
///
/// Three calm rows instead of one crowded line:
///
/// 1. the Luqma wordmark (the same [AppLogo] the login screen uses) with the
///    favourites and notifications actions;
/// 2. the greeting — beside the logo when there is room, below it on narrow
///    screens or with large text, so long names never clip;
/// 3. the delivery address, which opens the address sheet.
///
/// The widget owns no data: the shell feeds it the signed-in name, the selected
/// address summary and the favourites count, so Home never touches cubits it
/// does not own.
class HomeAppBar extends StatelessWidget {
  const HomeAppBar({
    required this.userName,
    this.deliveryAddress,
    this.onNotificationsPressed,
    this.onFavoritesPressed,
    this.onAddressPressed,
    this.favoritesCount = 0,
    this.hasUnreadNotifications = false,
    super.key,
  });

  /// Height of the wordmark. Compact so the header stays a header.
  static const double _logoHeight = 38;

  /// Width below which the greeting moves under the logo instead of beside it.
  /// 340 fits the greeting beside the wordmark on a 390px phone (390 minus the
  /// 32px of page padding) while a 320px phone keeps it on its own row.
  static const double _inlineGreetingMinWidth = 340;

  final String? userName;

  /// Ready-to-display summary (`district, city`), already localized.
  final String? deliveryAddress;
  final VoidCallback? onNotificationsPressed;
  final VoidCallback? onFavoritesPressed;
  final VoidCallback? onAddressPressed;
  final int favoritesCount;
  final bool hasUnreadNotifications;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final inlineGreeting = constraints.maxWidth >=
                    _inlineGreetingMinWidth &&
                textScale <= 1.3;

            final greeting = Text(
              l10n.home.greeting(userName),
              key: const Key('home_greeting'),
              maxLines: inlineGreeting ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colors.headingText,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            );

            final actions = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HeaderAction(
                  key: const Key('home_app_bar_favorites'),
                  icon: Icons.favorite_border_rounded,
                  label: l10n.navigation.favorites,
                  onTap: onFavoritesPressed,
                  count: favoritesCount,
                ),
                const SizedBox(width: AppSpacing.xxs),
                _HeaderAction(
                  key: const Key('home_app_bar_notifications'),
                  icon: Icons.notifications_none_rounded,
                  label: l10n.home.notificationsLabel,
                  onTap: onNotificationsPressed,
                  showDot: hasUnreadNotifications,
                ),
              ],
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (inlineGreeting)
                  Row(
                    children: [
                      const _Wordmark(height: _logoHeight),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: greeting),
                      actions,
                    ],
                  )
                else ...[
                  Row(
                    children: [
                      const _Wordmark(height: _logoHeight),
                      const Spacer(),
                      actions,
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  greeting,
                ],
                const SizedBox(height: AppSpacing.xs),
                _AddressRow(
                  summary: deliveryAddress,
                  onPressed: onAddressPressed,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The Luqma wordmark from [AppLogo], which already picks the light or dark
/// artwork for the current theme.
class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.height});

  final double height;

  /// The wordmark's width for a given height, using the artwork's 1315:841 box.
  static const double _aspect = 1315 / 841;

  @override
  Widget build(BuildContext context) {
    final brandName = AppLocalizations.of(context).common.brandName;
    final width = height * _aspect;
    return SizedBox(
      width: width,
      height: height,
      child: AppLogo(semanticLabel: brandName, maxWidth: width),
    );
  }
}

/// The tappable delivery-address row: pin, summary (or a prompt), chevron.
class _AddressRow extends StatelessWidget {
  const _AddressRow({required this.summary, this.onPressed});

  final String? summary;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final l10n = AppLocalizations.of(context).home;
    final trimmed = summary?.trim() ?? '';
    final hasAddress = trimmed.isNotEmpty;
    final text = hasAddress ? trimmed : l10n.selectDeliveryAddress;
    final chevron = Directionality.of(context) == TextDirection.rtl
        ? Icons.chevron_left_rounded
        : Icons.chevron_right_rounded;

    final content = Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.xxs,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(
            hasAddress
                ? Icons.location_on_rounded
                : Icons.add_location_alt_outlined,
            size: 18,
            color: colors.primary,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Expanded(
            child: Text(
              text,
              key: const Key('home_app_bar_address_text'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: hasAddress ? colors.bodyText : colors.link,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(chevron, size: 20, color: colors.mutedText),
        ],
      ),
    );

    return Semantics(
      button: onPressed != null,
      label: l10n.changeAddressSemanticLabel,
      hint: l10n.changeAddressHint,
      excludeSemantics: true,
      child: Material(
        key: const Key('home_app_bar_address'),
        color: Colors.transparent,
        borderRadius: AppRadius.pillRadius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadius.pillRadius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Flat header action with an optional count badge or unread dot.
class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.label,
    this.onTap,
    this.count = 0,
    this.showDot = false,
    super.key,
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
      label: count > 0 ? '$label ($count)' : label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: colors.headingText, size: 24),
                if (count > 0)
                  PositionedDirectional(
                    top: 2,
                    end: 2,
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
                              key: const Key('home_favorites_badge'),
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
                    top: 8,
                    end: 8,
                    child: Container(
                      key: const Key('home_notifications_unread_dot'),
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: colors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.background, width: 1.5),
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
