import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Hero offer banner. One widget, two looks that share the same layout:
/// light mode is a solid maroon hero with cream text (as in the light design),
/// dark mode fades the maroon into the dark surface.
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

    // `onPrimary` is white (light) / cream (dark): readable on both heroes.
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
                  Colors.white.withValues(alpha: .10), colors.primary),
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
                    color: colors.primary.withValues(alpha: .25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Stack(
          children: [
            // Soft decorative rings (visible mostly on the light hero).
            PositionedDirectional(
              end: -40,
              bottom: -60,
              child: _Ring(size: 190, color: onHero.withValues(alpha: .08)),
            ),
            PositionedDirectional(
              start: -30,
              top: -50,
              child: _Ring(size: 130, color: onHero.withValues(alpha: .06)),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tag,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: onHero,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          discount,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: onHero,
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: onHero.withValues(alpha: .82),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton(
                          onPressed: onCtaPressed,
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                isDark ? colors.primary : deepMaroon,
                            foregroundColor: onHero,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 22, vertical: 12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ctaLabel,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 8),
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
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Transform.rotate(
                    angle: -0.17,
                    child: Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        color: isDark
                            ? colors.background
                            : Colors.white.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? colors.border
                              : Colors.white.withValues(alpha: .28),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6EFDF),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(Icons.room_service_rounded,
                            size: 44, color: colors.primary),
                      ),
                    ),
                  ),
                ],
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
