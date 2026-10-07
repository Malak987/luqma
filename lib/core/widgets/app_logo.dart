import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../theme/app_sizes.dart';

/// Brand wordmark. Uses the official artwork and switches between the maroon
/// (light theme) and cream (dark theme) versions automatically.
class AppLogo extends StatelessWidget {
  const AppLogo({
    required this.brandName,
    required this.tagline,
    super.key,
    this.height = AppSizes.authLogoHeight,
  });

  final String brandName;
  final String tagline;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      image: true,
      label: '$brandName $tagline',
      child: ExcludeSemantics(
        child: Image.asset(
          isDark ? AppAssets.logoDark : AppAssets.logoLight,
          height: height,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          // Never crash a screen because of a missing image.
          errorBuilder: (context, error, stackTrace) => SizedBox(
            height: height,
            child: Center(
              child: Text(
                brandName,
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
