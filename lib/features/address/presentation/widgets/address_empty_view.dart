import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';

class AddressEmptyView extends StatelessWidget {
  const AddressEmptyView({super.key, this.onAddAddress});

  final VoidCallback? onAddAddress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context).address;
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;

    return Center(
      key: const Key('address_empty_state'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_outlined,
                size: AppSizes.iconLarge * 2, color: colors.mutedText),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.emptyTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colors.headingText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.emptyMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.mutedText,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              key: const Key('address_add_button'),
              text: l10n.addAddress,
              onPressed: onAddAddress,
              icon: const Icon(Icons.add_location_alt_outlined),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.addAddressHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
