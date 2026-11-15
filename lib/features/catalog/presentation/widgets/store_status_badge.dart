import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

class StoreStatusBadge extends StatelessWidget {
  const StoreStatusBadge({required this.isOpenNow, super.key});
  final bool isOpenNow;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    final l10n = AppLocalizations.of(context).catalog;
    final color = isOpenNow ? colors.accent : colors.mutedText;
    return DecoratedBox(
      decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: AppRadius.pillRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          ExcludeSemantics(
              child: Icon(isOpenNow ? Icons.circle : Icons.schedule,
                  size: 10, color: color)),
          const SizedBox(width: AppSpacing.xxs),
          Flexible(
              child: Text(isOpenNow ? l10n.open : l10n.closed,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isOpenNow ? colors.bodyText : colors.mutedText))),
        ]),
      ),
    );
  }
}
