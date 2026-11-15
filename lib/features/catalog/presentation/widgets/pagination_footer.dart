import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class PaginationFooter extends StatelessWidget {
  const PaginationFooter(
      {required this.loading,
      required this.failed,
      required this.onRetry,
      required this.canLoadMore,
      required this.onLoadMore,
      this.failureLabel,
      this.loadMoreLabel,
      super.key});
  final bool loading;
  final bool failed;
  final VoidCallback onRetry;
  final bool canLoadMore;
  final VoidCallback onLoadMore;
  final String? failureLabel;
  final String? loadMoreLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    if (!loading && !failed && !canLoadMore) {
      return const SizedBox(height: AppSpacing.lg);
    }
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (loading) ...[
          SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                  semanticsLabel: l10n.catalog.loadingMore)),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.catalog.loadingMore),
        ] else if (failed) ...[
          Text(failureLabel ?? l10n.catalog.paginationFailed,
              textAlign: TextAlign.center),
          TextButton(
              key: const Key('pagination_retry'),
              style: TextButton.styleFrom(foregroundColor: colors.link),
              onPressed: onRetry,
              child: Text(l10n.catalog.retry)),
        ] else
          TextButton(
              key: const Key('pagination_more'),
              style: TextButton.styleFrom(foregroundColor: colors.link),
              onPressed: onLoadMore,
              child: Text(loadMoreLabel ?? l10n.catalog.loadMore)),
      ]),
    );
  }
}
