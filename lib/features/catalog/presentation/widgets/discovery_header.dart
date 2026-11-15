import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_circle_icon_button.dart';

/// Title row of the discovery screens: optional back button, centered title
/// and a notifications button.
class DiscoveryHeader extends StatelessWidget {
  const DiscoveryHeader({required this.title, this.showBack = false, super.key});

  final String title;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
      child: Row(
        children: [
          if (showBack)
            AppCircleIconButton(
              key: const Key('discovery_back'),
              icon: Icons.arrow_back_ios_new_rounded,
              tooltip: l10n.common.back,
              borderColor: colors.border,
              onPressed: () => Navigator.of(context).maybePop(),
            )
          else
            const SizedBox(width: AppCircleIconButton.defaultSize),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colors.headingText,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          AppCircleIconButton(
            key: const Key('discovery_notifications'),
            icon: Icons.notifications_none_rounded,
            tooltip: l10n.catalog.notifications,
            borderColor: colors.border,
            onPressed: () => ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                  content: Text(l10n.home.notificationsUnavailable))),
          ),
        ],
      ),
    );
  }
}
