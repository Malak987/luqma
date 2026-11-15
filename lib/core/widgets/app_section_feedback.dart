import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';

/// Extracted Home placeholder presentation. Callers supply localized copy and
/// callbacks; this widget makes no API, failure-policy or retry decisions.
class AppSectionFeedback extends StatelessWidget {
  const AppSectionFeedback(
      {required this.icon,
      required this.message,
      this.action,
      this.loading = false,
      super.key});

  final IconData icon;
  final String message;
  final Widget? action;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (loading)
            CircularProgressIndicator(
                color: colors.primary, semanticsLabel: message)
          else
            Icon(icon, size: AppSizes.iconLarge, color: colors.mutedText),
          const SizedBox(height: AppSpacing.sm),
          Text(message,
              textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ]),
      ),
    );
  }
}
