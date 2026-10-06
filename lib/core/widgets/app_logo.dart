import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({required this.brandName, required this.tagline, super.key});

  final String brandName;
  final String tagline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semanticColors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final isArabic = Directionality.of(context) == TextDirection.rtl;

    return Semantics(
      image: true,
      label: '$brandName $tagline',
      child: SizedBox(
        height: AppSizes.logoWordmarkHeight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              brandName,
              textAlign: TextAlign.center,
              style: AppTextStyles.withArabicFallback(
                fontSize: isArabic ? 42 : 36,
                fontWeight: FontWeight.w800,
                color: semanticColors.headingText,
                height: 1,
                letterSpacing: isArabic ? 0 : 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 22,
                  height: 1,
                  color: semanticColors.accent,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Text(
                    tagline,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.withArabicFallback(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: semanticColors.accent,
                      letterSpacing: 2.3,
                      height: 1.1,
                    ),
                  ),
                ),
                Container(
                  width: 22,
                  height: 1,
                  color: semanticColors.accent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
