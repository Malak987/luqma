import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../domain/entities/home_ad_banner.dart';
import '../utils/home_layout.dart';

/// The Home promo area.
///
/// * With active ads it is a swipeable carousel of full-bleed ad artwork.
/// * With no ads (none returned, still loading, or failed) it shows the
///   built-in premium banner, so the space is never empty and never shifts.
class HomePromoBanner extends StatelessWidget {
  const HomePromoBanner({
    required this.tag,
    required this.title,
    required this.highlight,
    required this.subtitle,
    required this.ctaLabel,
    this.onCtaPressed,
    this.ads = const <HomeAdBanner>[],
    this.onAdTap,
    super.key,
  });

  final String tag;
  final String title;
  final String highlight;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback? onCtaPressed;
  final List<HomeAdBanner> ads;

  /// Overrides the default tap behaviour (opening [HomeAdBanner.targetUrl]).
  final ValueChanged<HomeAdBanner>? onAdTap;

  /// Minimum height in both states, so an ad loading never moves the page.
  static const double bannerHeight = 184;

  @override
  Widget build(BuildContext context) {
    if (ads.isEmpty) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: bannerHeight),
        child: _PremiumBanner(
          tag: tag,
          title: title,
          highlight: highlight,
          subtitle: subtitle,
          ctaLabel: ctaLabel,
          onCtaPressed: onCtaPressed,
        ),
      );
    }
    return SizedBox(
      height: bannerHeight,
      child: _AdCarousel(ads: ads, onAdTap: onAdTap),
    );
  }
}

/// The default banner: a deep burgundy card with a fine gold edge, soft light,
/// copy on the start side and three overlapping food tiles on the end side.

/// The default banner: a deep burgundy card with a single food illustration.
class _PremiumBanner extends StatelessWidget {
  const _PremiumBanner({
    required this.tag,
    required this.title,
    required this.highlight,
    required this.subtitle,
    required this.ctaLabel,
    this.onCtaPressed,
  });

  final String tag;
  final String title;
  final String highlight;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback? onCtaPressed;

  static const double _radius = 28;
  static const Color _gold = Color(0xFFE9C58F);
  static const Color _buttonBackground = Color(0xFF65151F);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradient = homeHeaderGradient(theme.brightness);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3;

        final artWidth = compact ? 116.0 : 148.0;

        return DecoratedBox(
          key: const Key('home_promo_default_banner'),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: gradient.last.withValues(alpha: .35),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radius),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: gradient,
                ),
                borderRadius: BorderRadius.circular(_radius),
                border: Border.all(
                  color: _gold.withValues(alpha: .35),
                  width: 1,
                ),
              ),
              child: Stack(
                children: <Widget>[
                  // Subtle light effect.
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: AlignmentDirectional(.9, -1.1),
                            radius: 1.1,
                            colors: <Color>[
                              Color(0x26FFFFFF),
                              Color(0x00FFFFFF),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Decorative golden rings.
                  PositionedDirectional(
                    end: -artWidth * .30,
                    top: 0,
                    bottom: 0,
                    child: Align(
                      child: _ring(artWidth * 1.45, .22),
                    ),
                  ),
                  PositionedDirectional(
                    end: -artWidth * .08,
                    top: 0,
                    bottom: 0,
                    child: Align(
                      child: _ring(artWidth * .95, .16),
                    ),
                  ),

                  // Single food illustration.
                  PositionedDirectional(
                    end: 0,
                    top: 0,
                    bottom: 0,
                    width: artWidth,
                    child: _FoodArt(compact: compact),
                  ),

                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      artWidth - 8,
                      AppSpacing.lg,
                    ),
                    child: _buildCopy(theme),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  Widget _ring(double size, double alpha) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: _gold.withValues(alpha: alpha),
        width: 1.5,
      ),
    ),
  );

  Widget _buildCopy(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _gold.withValues(alpha: .65),
            ),
            color: Colors.white.withValues(alpha: .08),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            child: Text(
              tag,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: _gold,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        Text.rich(
          TextSpan(
            children: <InlineSpan>[
              TextSpan(text: '$title '),
              TextSpan(
                text: highlight,
                style: const TextStyle(color: _gold),
              ),
            ],
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: .82),
            height: 1.4,
          ),
        ),

        const SizedBox(height: AppSpacing.md-2),

        FilledButton(
          key: const Key('home_promo_cta'),
          onPressed: onCtaPressed,
          style: FilledButton.styleFrom(
            backgroundColor: _buttonBackground,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(0, 42),
            shape: const StadiumBorder(),
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.sm,
              AppSpacing.xs,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: Text(
                  ctaLabel,
                  softWrap: true,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A single food illustration on the end side of the banner.
class _FoodArt extends StatelessWidget {
  const _FoodArt({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 104.0 : 132.0;

    return ExcludeSemantics(
      child: Center(
        child: Image.asset(
          AppAssets.categoryFastFood,
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          cacheWidth: (size * 3).round(),
          errorBuilder: (_, __, ___) {
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}


class _AdCarousel extends StatefulWidget {
  const _AdCarousel({required this.ads, this.onAdTap});

  final List<HomeAdBanner> ads;
  final ValueChanged<HomeAdBanner>? onAdTap;

  @override
  State<_AdCarousel> createState() => _AdCarouselState();
}

class _AdCarouselState extends State<_AdCarousel> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _open(HomeAdBanner ad) async {
    final custom = widget.onAdTap;
    if (custom != null) {
      custom(ad);
      return;
    }
    final uri = Uri.tryParse(ad.targetUrl?.trim() ?? '');
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    return SizedBox.expand(
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: PageView.builder(
              key: const Key('home_promo_carousel'),
              controller: _controller,
              itemCount: widget.ads.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (context, index) {
                final ad = widget.ads[index];
                return Padding(
                  // A hairline between slides so a swipe reads as two cards.
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _AdSlide(ad: ad, onTap: () => _open(ad)),
                );
              },
            ),
          ),
          if (widget.ads.length > 1)
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: AppSpacing.sm,
              child: IgnorePointer(
                child: Row(
                  key: const Key('home_promo_indicators'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    for (var i = 0; i < widget.ads.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _index ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == _index
                              ? colors.onPrimary
                              : colors.onPrimary.withValues(alpha: .55),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdSlide extends StatelessWidget {
  const _AdSlide({required this.ad, required this.onTap});

  final HomeAdBanner ad;
  final VoidCallback onTap;

  static const double _radius = 24;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final title = ad.title?.trim() ?? '';
    final subtitle = ad.subtitle?.trim() ?? '';
    final cta = ad.ctaLabel?.trim() ?? '';
    final hasCopy = title.isNotEmpty || subtitle.isNotEmpty || cta.isNotEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.primary.withValues(alpha: .18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Material(
          color: colors.iconSurface,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                AppNetworkImage(
                  url: ad.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: const SizedBox.shrink(),
                ),
                if (hasCopy) ...<Widget>[
                  // Dark fade from the bottom keeps white copy readable on
                  // any artwork.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                        colors: <Color>[
                          Color(0xCC000000),
                          Color(0x00000000),
                        ],
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    start: AppSpacing.md,
                    end: AppSpacing.md,
                    bottom: AppSpacing.md + 6,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              if (title.isNotEmpty)
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colors.onPrimary,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                  ),
                                ),
                              if (subtitle.isNotEmpty)
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onPrimary.withValues(alpha: .88),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (cta.isNotEmpty) ...<Widget>[
                          const SizedBox(width: AppSpacing.sm),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.accent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              child: Text(
                                cta,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
