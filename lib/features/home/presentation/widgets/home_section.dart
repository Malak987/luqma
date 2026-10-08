import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';

/// Section shell shared by the home sections: a title plus its content, so the
/// header and the spacing between them live in exactly one place.
class HomeSection extends StatelessWidget {
  const HomeSection({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

/// Honest placeholder used while a section has no data to show. It exists so a
/// section is never filled with sample data that pretends to come from the API.
class HomeSectionPlaceholder extends StatelessWidget {
  const HomeSectionPlaceholder({
    required this.icon,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: <Widget>[
            Icon(icon, size: AppSizes.iconLarge, color: colors.mutedText),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
