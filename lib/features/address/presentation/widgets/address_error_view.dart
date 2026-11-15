import 'package:flutter/material.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';

class AddressErrorView extends StatelessWidget {
  const AddressErrorView({super.key, this.failure, this.onRetry});

  final Failure? failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context).address;
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;

    final message = _messageFor(context, failure);

    return Center(
      key: const Key('address_error_state'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: AppSizes.iconLarge * 1.6, color: colors.mutedText),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.loadFailed,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colors.headingText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.mutedText,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: 220,
              child: AppButton(
                key: const Key('address_retry_button'),
                text: l10n.retry,
                onPressed: onRetry,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _messageFor(BuildContext context, Failure? failure) {
    final l10n = AppLocalizations.of(context);
    switch (failure?.code) {
      case FailureCode.network:
        return l10n.auth.networkError;
      case FailureCode.validation:
        return l10n.auth.loginFailed;
      case FailureCode.invalidCredentials:
        return l10n.auth.invalidCredentials;
      case FailureCode.unknown:
      case null:
        return failure?.debugMessage?.isNotEmpty == true
            ? failure!.debugMessage!
            : l10n.auth.unknownError;
    }
  }
}
