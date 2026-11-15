import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_section_feedback.dart';

/// Placeholder for a tab whose feature is not built yet. Honest by design:
/// it shows no fake data, only that the destination exists.
class ComingSoonTab extends StatelessWidget {
  const ComingSoonTab({required this.title, required this.icon, super.key});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;

    return ColoredBox(
      color: colors.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppSectionFeedback(
                icon: icon,
                message: AppLocalizations.of(context).common.comingSoon,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
