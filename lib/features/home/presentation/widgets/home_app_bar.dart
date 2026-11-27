import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_logo.dart';
import '../utils/home_layout.dart';
import 'home_search_bar.dart';

/// The Home header: one full-width burgundy band at the very top of the screen.
///
/// It paints its own background — including behind the status bar — and rounds
/// only its bottom corners. The burgundy carries a soft light (a diagonal
/// gradient plus two faint radial glows and a soft shadow underneath) so it
/// reads as a lit surface instead of a flat block. Inside:
///
/// 1. one row: the enlarged Luqma wordmark, then the greeting name and the
///    tappable delivery address beside it, then favourites and notifications,
/// 2. the full-width search field.
///
/// Categories, the promotion and the restaurants stay below the header in the
/// scroll view `HomePage` owns. The widget itself owns no data: the shell feeds
/// it the signed-in name, the selected address and the favourites count.
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
  static const double _bottomRadius = 34;

  /// Height of the wordmark (38 originally, then 60, now 76). The row simply
  /// grows with it; every padding and gap around it is unchanged.
  static const double _logoHeight = 76;

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
    final gradient = homeHeaderGradient(theme.brightness);
    const radius = BorderRadius.vertical(
      bottom: Radius.circular(_bottomRadius),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Light status-bar icons: the band behind them is burgundy.
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = homeHorizontalPadding(constraints.maxWidth);

          return DecoratedBox(
            key: const Key('home_header'),
            // The shadow lives on the outer box; the clip below would cut it.
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: gradient.last.withValues(alpha: .38),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                    colors: gradient,
                  ),
                ),
                child: Stack(
                  children: <Widget>[
                    // Key light: a wide, faint glow from the top corner.
                    const Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: AlignmentDirectional(.95, -1.1),
                              radius: 1.05,
                              colors: <Color>[
                                Color(0x2EFFFFFF),
                                Color(0x00FFFFFF),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Fill light: a smaller, softer glow low on the other side
                    // so the band does not look lit from one point only.
                    const Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: AlignmentDirectional(-1, 1.2),
                              radius: .9,
                              colors: <Color>[
                                Color(0x14FFFFFF),
                                Color(0x00FFFFFF),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SafeArea(
                      bottom: false,
                      child: Center(
                        // heightFactor keeps the header as tall as its content
                        // instead of filling the screen; the column is still
                        // centred on wide screens.
                        heightFactor: 1,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: homeContentMaxWidth,
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                              horizontal,
                              AppSpacing.md,
                              horizontal,
                              AppSpacing.xl,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                _TopRow(
                                  logoHeight: _logoHeight,
                                  userName: userName,
                                  deliveryAddress: deliveryAddress,
                                  favoritesCount: favoritesCount,
                                  hasUnreadNotifications:
                                      hasUnreadNotifications,
                                  onFavoritesPressed: onFavoritesPressed,
                                  onNotificationsPressed:
                                      onNotificationsPressed,
                                  onAddressPressed: onAddressPressed,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                HomeSearchBar(
                                  hintText: l10n.home.searchHint,
                                  clearTooltip: l10n.home.clearSearch,
                                  // A light field on the burgundy band keeps
                                  // the search the clearest control in both
                                  // themes.
                                  backgroundColor:
                                      theme.brightness == Brightness.dark
                                          ? colors.surface
                                          : const Color(0xFFFFFBF5),
                                  onSubmitted: onSearchSubmitted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The Luqma wordmark. It always uses the cream/gold artwork because the band
/// behind it is burgundy in both themes.
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
      child: AppLogo(
        semanticLabel: brandName,
        maxWidth: width,
        onDarkBackground: true,
      ),
    );
  }
}

/// Logo, then name + address beside it, then the two actions. The middle block
/// is [Expanded], so a long name or address ellipsizes instead of overflowing.
class _TopRow extends StatelessWidget {
  const _TopRow({
    required this.logoHeight,
    required this.userName,
    required this.deliveryAddress,
    required this.favoritesCount,
    required this.hasUnreadNotifications,
    this.onFavoritesPressed,
    this.onNotificationsPressed,
    this.onAddressPressed,
  });

  final double logoHeight;
  final String? userName;
  final String? deliveryAddress;
  final int favoritesCount;
  final bool hasUnreadNotifications;
  final VoidCallback? onFavoritesPressed;
  final VoidCallback? onNotificationsPressed;
  final VoidCallback? onAddressPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Row(
      children: <Widget>[
        _Wordmark(height: logoHeight),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.home.greeting(userName),
                key: const Key('home_greeting'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              _AddressRow(
                summary: deliveryAddress,
                onPressed: onAddressPressed,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
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

/// The tappable delivery-address line: pin, summary (or a prompt), chevron.
/// It sits directly under the name, on the burgundy band, with no plate.
class _AddressRow extends StatelessWidget {
  const _AddressRow({required this.summary, this.onPressed});

  final String? summary;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context).home;
    final trimmed = summary?.trim() ?? '';
    final hasAddress = trimmed.isNotEmpty;
    final text = hasAddress ? trimmed : l10n.selectDeliveryAddress;
    final soft = Colors.white.withValues(alpha: .82);

    // The row shrinks to its content and is pinned to the start edge, so the
    // arrow sits right after the last word instead of at the far edge.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Semantics(
        button: onPressed != null,
        label: l10n.changeAddressSemanticLabel,
        hint: l10n.changeAddressHint,
        excludeSemantics: true,
        child: Material(
          key: const Key('home_app_bar_address'),
          color: Colors.transparent,
          borderRadius: AppRadius.mediumRadius,
          child: InkWell(
            onTap: onPressed,
            borderRadius: AppRadius.mediumRadius,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 36),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    hasAddress
                        ? Icons.location_on_rounded
                        : Icons.add_location_alt_outlined,
                    size: 16,
                    color: soft,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Flexible(
                    child: Text(
                      text,
                      key: const Key('home_app_bar_address_text'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: soft,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  // Opens a picker, so it points down (no RTL mirroring).
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: soft,
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

/// Frosted-glass header action with an optional count badge or unread dot.
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

  static const Color _cream = Color(0xFFFFF3E2);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final burgundy = homeHeaderGradient(theme.brightness).last;

    return Semantics(
      button: true,
      label: count > 0 ? '$label ($count)' : label,
      excludeSemantics: true,
      child: Material(
        color: Colors.white.withValues(alpha: .14),
        shape: CircleBorder(
          side: BorderSide(color: Colors.white.withValues(alpha: .22)),
        ),
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
                Icon(icon, color: Colors.white, size: 24),
                if (count > 0)
                  PositionedDirectional(
                    top: 0,
                    end: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _cream,
                        borderRadius: AppRadius.pillRadius,
                        border: Border.all(color: burgundy, width: 2),
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
                                color: burgundy,
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
                    top: 9,
                    end: 9,
                    child: Container(
                      key: const Key('home_notifications_unread_dot'),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _cream,
                        shape: BoxShape.circle,
                        border: Border.all(color: burgundy, width: 1.8),
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
