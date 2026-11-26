import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_logo.dart';
import '../utils/home_layout.dart';
import 'home_search_bar.dart';

/// The Home header: one full-width band at the very top of the screen.
///
/// It paints its own background — including behind the status bar — and rounds
/// only its bottom corners, so it reads as part of the app rather than a card
/// floating on the page. Inside, top to bottom:
///
/// 1. the Luqma wordmark with the favourites and notifications actions,
/// 2. the personalized greeting and a short welcoming headline,
/// 3. the tappable delivery address with its change indicator,
/// 4. the full-width search field.
///
/// Categories, the promotion banner and the restaurants stay below the header in
/// the scroll view `HomePage` owns. The widget itself owns no data: the shell
/// feeds it the signed-in name, the selected address and the favourites count,
/// so Home never reaches into cubits it does not own.
class HomeAppBar extends StatelessWidget {
  const HomeAppBar({
    required this.userName,
    this.deliveryAddress,
    this.onNotificationsPressed,
    this.onFavoritesPressed,
    this.onAddressPressed,
    this.onSearchSubmitted,
    this.favoritesCount = 0,
    this.hasUnreadNotifications = false,
    super.key,
  });

  /// Rounds the bottom edge only; the top stays flush with the screen.
  static const double _bottomRadius = 28;

  /// Height of the wordmark. Compact so the header stays a header.
  static const double _logoHeight = 38;

  final String? userName;

  /// Ready-to-display summary (`district, city`), already localized.
  final String? deliveryAddress;
  final VoidCallback? onNotificationsPressed;
  final VoidCallback? onFavoritesPressed;
  final VoidCallback? onAddressPressed;

  /// Search submit callback. Home owns the behaviour (the search API does not
  /// exist yet), the header only renders the field.
  final ValueChanged<String>? onSearchSubmitted;
  final int favoritesCount;
  final bool hasUnreadNotifications;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = homeHorizontalPadding(constraints.maxWidth);

        return DecoratedBox(
          key: const Key('home_header'),
          // The decoration wraps the safe area instead of sitting inside it, so
          // the colour starts at y=0 and runs behind the status bar while the
          // content below stays clear of the system icons.
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(_bottomRadius),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Center(
              // heightFactor keeps the header as tall as its content instead of
              // filling the screen; the column is still centred on wide screens.
              heightFactor: 1,
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: homeContentMaxWidth),
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    horizontal,
                    AppSpacing.sm,
                    horizontal,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _TopRow(
                        logoHeight: _logoHeight,
                        favoritesCount: favoritesCount,
                        hasUnreadNotifications: hasUnreadNotifications,
                        onFavoritesPressed: onFavoritesPressed,
                        onNotificationsPressed: onNotificationsPressed,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.home.greeting(userName),
                        key: const Key('home_greeting'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colors.headingText,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        l10n.home.greetingHeadline,
                        key: const Key('home_headline'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.mutedText,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _AddressRow(
                        summary: deliveryAddress,
                        onPressed: onAddressPressed,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      HomeSearchBar(
                        hintText: l10n.home.searchHint,
                        clearTooltip: l10n.home.clearSearch,
                        // A cream field on the lighter header surface keeps the
                        // search visible in both themes without a shadow.
                        backgroundColor: colors.background,
                        onSubmitted: onSearchSubmitted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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

/// Row 1: logo on the leading edge, favourites and notifications on the trailing
/// edge. Flexible so a long wordmark or large text never overflows.
class _TopRow extends StatelessWidget {
  const _TopRow({
    required this.logoHeight,
    required this.favoritesCount,
    required this.hasUnreadNotifications,
    this.onFavoritesPressed,
    this.onNotificationsPressed,
  });

  final double logoHeight;
  final int favoritesCount;
  final bool hasUnreadNotifications;
  final VoidCallback? onFavoritesPressed;
  final VoidCallback? onNotificationsPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: <Widget>[
        _Wordmark(height: logoHeight),
        const Spacer(),
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
  }
}

/// The tappable delivery-address row: pin, summary (or a prompt), chevron.
///
/// It sits on its own quiet plate so the row reads as a control on the header
/// surface without becoming a card.
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
    // The row opens a picker rather than moving through the hierarchy, so the
    // indicator points down and needs no RTL mirroring.
    const chevron = Icons.keyboard_arrow_down_rounded;

    final content = Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Row(
        children: <Widget>[
          Icon(
            hasAddress
                ? Icons.location_on_rounded
                : Icons.add_location_alt_outlined,
            size: 18,
            color: colors.primary,
          ),
          const SizedBox(width: AppSpacing.xs),
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
        color: colors.background,
        borderRadius: AppRadius.pillRadius,
        clipBehavior: Clip.antiAlias,
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
              children: <Widget>[
                Icon(icon, color: colors.headingText, size: 24),
                if (count > 0)
                  PositionedDirectional(
                    top: 2,
                    end: 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: AppRadius.pillRadius,
                        border: Border.all(color: colors.surface, width: 2),
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
                        border:
                            Border.all(color: colors.surface, width: 1.5),
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
