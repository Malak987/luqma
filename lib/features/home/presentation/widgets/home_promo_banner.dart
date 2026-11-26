import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Hero offer banner. One widget, two looks that share the same layout:
/// light mode is a solid maroon hero with cream text, while dark mode blends
/// the brand color into the dark surface.
class HomePromoBanner extends StatelessWidget {
  const HomePromoBanner({
    required this.tag,
    required this.title,
    required this.discount,
    required this.subtitle,
    required this.ctaLabel,
    this.onCtaPressed,
    super.key,
  });

  final String tag;
  final String title;
  final String discount;
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
    final deepMaroon =
        Color.alphaBlend(Colors.black.withValues(alpha: .28), colors.primary);

    final gradient = isDark
        ? LinearGradient(
            begin: AlignmentDirectional.bottomStart,
            end: AlignmentDirectional.topEnd,
            colors: [colors.primary.withValues(alpha: .35), colors.surface],
          )
        : LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [
              Color.alphaBlend(
                Colors.white.withValues(alpha: .10),
                colors.primary,
              ),
              deepMaroon,
            ],
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          border: Border.all(
            color: isDark ? colors.border : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: .22),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Stack(
          children: [
            PositionedDirectional(
              end: -46,
              bottom: -66,
              child: _Ring(
                size: 190,
                color: onHero.withValues(alpha: .075),
              ),
            ),
            PositionedDirectional(
              start: -36,
              top: -56,
              child: _Ring(
                size: 132,
                color: onHero.withValues(alpha: .055),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 440 ||
                      MediaQuery.textScalerOf(context).scale(1) > 1.3;
                  final artwork = _PromoArtwork(
                    isDark: isDark,
                    colors: colors,
                    size: compact ? 88 : 108,
                  );
                  final copy = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.accent.withValues(alpha: .18),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: colors.accent.withValues(alpha: .42),
                          ),
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
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: onHero,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      Text(
                        discount,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: onHero,
                          fontWeight: FontWeight.w900,
                          fontSize: 28,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: onHero.withValues(alpha: .84),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton(
                        onPressed: onCtaPressed,
                        style: FilledButton.styleFrom(
                          backgroundColor: isDark ? colors.primary : deepMaroon,
                          foregroundColor: onHero,
                          elevation: 0,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
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

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        copy,
                        const SizedBox(height: AppSpacing.md),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: artwork,
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: copy),
                      const SizedBox(width: AppSpacing.md),
                      artwork,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    final plateSize = size * .76;
    return Transform.rotate(
      angle: -.12,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isDark
              ? colors.background
              : Colors.white.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: isDark
                ? colors.border
                : Colors.white.withValues(alpha: .26),
          ),
        ),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: plateSize,
              height: plateSize,
              decoration: BoxDecoration(
                color: const Color(0xFFF6EFDF),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.ramen_dining_rounded,
                size: plateSize * .52,
                color: colors.primary,
              ),
            ),
            PositionedDirectional(
              top: size * .12,
              end: size * .12,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? colors.background : colors.primary,
                    width: 2,
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

class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 14),
        ),
      );
}
