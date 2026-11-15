import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../theme/app_sizes.dart';

/// The Luqma wordmark, rendered from the supplied brand artwork.
///
/// It swaps between the light and dark artwork with the active theme and
/// scales with the screen: as wide as the layout allows (up to
/// [AppSizes.logoMaxWidth]) but never taller than about a third of the
/// screen, so it stays large on phones without crowding the form in landscape.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.semanticLabel, this.maxWidth});

  static const double _aspectRatio = 1315 / 841;
  static const double _maxHeightFraction = 0.34;

  final String? semanticLabel;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return LayoutBuilder(
      builder: (context, constraints) {
        final byHeight = screenHeight * _maxHeightFraction * _aspectRatio;
        final available = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : double.infinity;
        final width = math.min(
          math.min(maxWidth ?? AppSizes.logoMaxWidth, available),
          byHeight,
        );

        return Center(
          child: Semantics(
            image: true,
            label: semanticLabel,
            excludeSemantics: true,
            child: Image.asset(
              isDark ? AppAssets.logoDark : AppAssets.logoLight,
              width: width,
              height: width / _aspectRatio,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) =>
                  SizedBox(width: width, height: width / _aspectRatio),
            ),
          ),
        );
      },
    );
  }
}
