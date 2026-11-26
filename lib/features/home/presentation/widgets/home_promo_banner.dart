import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../domain/entities/home_ad_banner.dart';

/// The Home promo area.
///
/// * With active ads from [HomeAdsState] it becomes a calm, swipeable carousel.
/// * With no ads — or while they load, or if they fail — it shows the built-in
///   default banner, so the space is never empty and never shifts.
///
/// The banner is flat: one solid brand colour, a gold badge and CTA, no
/// gradients, no decorative rings, no drop shadow, and no invented percentage.
class HomePromoBanner extends StatelessWidget {
  const HomePromoBanner({
    required this.tag,
    required this.title,
    required this.highlight,
    required this.subtitle,
    required this.ctaLabel,
    this.onCtaPressed,
    this.ads = const <HomeAdBanner>[],
    super.key,
  });

  final String tag;
  final String title;

  /// Second headline line. Presentational only — never a fabricated discount.
  final String highlight;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback? onCtaPressed;

  /// Active ads. Empty keeps the default banner on screen.
  final List<HomeAdBanner> ads;

  /// Reserved height in both states so loading an ad never moves the page.
  static const double bannerHeight = 196;

  @override
  Widget build(BuildContext context) {
    if (ads.isEmpty) {
      // The default banner grows with large text instead of clipping its CTA;
      // [bannerHeight] stays the minimum so loading an ad cannot move the page.
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: bannerHeight),
        child: _DefaultBanner(
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
      child: _AdCarousel(ads: ads),
    );
  }
}

class _DefaultBanner extends StatelessWidget {
  const _DefaultBanner({
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final isDark = theme.brightness == Brightness.dark;
    final onHero = colors.onPrimary;

    return DecoratedBox(
      key: const Key('home_promo_default_banner'),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? colors.border : colors.primary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 420 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.3;
            final copy = _bannerCopy(
              context: context,
              theme: theme,
              colors: colors,
              isDark: isDark,
              onHero: onHero,
            );
            final artwork = _PromoArtwork(
              isDark: isDark,
              colors: colors,
              size: compact ? 76 : 92,
            );

            if (compact) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: copy),
                  const SizedBox(width: AppSpacing.sm),
                  artwork,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: copy),
                const SizedBox(width: AppSpacing.md),
                artwork,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _bannerCopy({
    required BuildContext context,
    required ThemeData theme,
    required AppSemanticColors colors,
    required bool isDark,
    required Color onHero,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.accent.withValues(alpha: .20),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: colors.accent.withValues(alpha: .55)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            child: Text(
              tag,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isDark ? colors.accent : onHero,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            color: onHero,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        Text(
          highlight,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colors.accent,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: onHero.withValues(alpha: .86),
            height: 1.35,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        FilledButton(
          key: const Key('home_promo_cta'),
          onPressed: onCtaPressed,
          style: FilledButton.styleFrom(
            backgroundColor: colors.accent,
            foregroundColor: const Color(0xFF2B2B2B),
            elevation: 0,
            minimumSize: const Size(0, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  ctaLabel,
                  softWrap: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.arrow_back
                    : Icons.arrow_forward,
                size: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Swipeable ad carousel with quiet page indicators.
class _AdCarousel extends StatefulWidget {
  const _AdCarousel({required this.ads});

  final List<HomeAdBanner> ads;

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

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppSemanticColors>() ?? AppSemanticColors.light;
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            key: const Key('home_promo_carousel'),
            controller: _controller,
            // PageView follows the ambient text direction, so a swipe in Arabic
            // moves toward the next ad exactly like it does in English.
            itemCount: widget.ads.length,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (context, index) =>
                _AdSlide(ad: widget.ads[index]),
          ),
        ),
        if (widget.ads.length > 1) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            key: const Key('home_promo_indicators'),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.ads.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxs,
                  ),
                  width: i == _index ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _index ? colors.primary : colors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _AdSlide extends StatelessWidget {
  const _AdSlide({required this.ad});

  final HomeAdBanner ad;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final theme = Theme.of(context);
    final hasCopy = (ad.title?.trim().isNotEmpty ?? false) ||
        (ad.subtitle?.trim().isNotEmpty ?? false);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.iconSurface,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppNetworkImage(
              url: ad.imageUrl,
              fit: BoxFit.cover,
              placeholder: const SizedBox.shrink(),
            ),
            if (hasCopy)
              // Solid, low band keeps the copy readable over any artwork
              // without a gradient or a blur.
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: .92),
                    border: Border(
                      top: BorderSide(color: colors.border),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (ad.title?.trim().isNotEmpty == true)
                          Text(
                            ad.title!.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colors.headingText,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        if (ad.subtitle?.trim().isNotEmpty == true)
                          Text(
                            ad.subtitle!.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: colors.mutedText),
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

/// Simple flat plate mark in the banner. No shadow, no gradient.
class _PromoArtwork extends StatelessWidget {
  const _PromoArtwork({
    required this.isDark,
    required this.colors,
    required this.size,
  });

  final bool isDark;
  final AppSemanticColors colors;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.accent.withValues(alpha: .45)),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.ramen_dining_rounded,
        size: size * .5,
        color: colors.accent,
      ),
    );
  }
}
