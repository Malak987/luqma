import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../catalog/presentation/widgets/menu_item_card.dart'
    show MenuArtworkPlaceholder;
import '../../../catalog/presentation/widgets/shared_product_card.dart';
import '../../domain/entities/favorite_menu_item.dart';
import '../cubit/favorites_cubit.dart';
import '../cubit/favorites_state.dart';

/// The persistent-shell Favorites destination. Its count and contents both
/// come from the same authenticated FavoritesCubit that drives menu hearts.
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({this.onBrowseRestaurants, super.key});

  final VoidCallback? onBrowseRestaurants;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    return Scaffold(
      key: const Key('favorites_page'),
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<FavoritesCubit, FavoritesState>(
          buildWhen: (previous, current) =>
              previous.status != current.status ||
              !listEquals(previous.items, current.items) ||
              previous.totalCount != current.totalCount ||
              previous.loadingMore != current.loadingMore ||
              previous.nextPageFailure != current.nextPageFailure ||
              previous.hasNextPage != current.hasNextPage ||
              previous.failure != current.failure,
          builder: (context, state) => FavoritesPageContent(
            state: state,
            onRetry: context.read<FavoritesCubit>().refresh,
            onLoadMore: context.read<FavoritesCubit>().loadNextPage,
            onRetryMore: context.read<FavoritesCubit>().retryNextPage,
            onBrowseRestaurants: onBrowseRestaurants,
          ),
        ),
      ),
    );
  }
}

/// State-only body so empty/loading/error/pagination layouts stay independently
/// testable and keep API/business behavior out of widgets.
class FavoritesPageContent extends StatelessWidget {
  const FavoritesPageContent({
    required this.state,
    required this.onRetry,
    required this.onLoadMore,
    required this.onRetryMore,
    this.onBrowseRestaurants,
    super.key,
  });

  final FavoritesState state;
  final Future<void> Function() onRetry;
  final Future<void> Function() onLoadMore;
  final Future<void> Function() onRetryMore;
  final VoidCallback? onBrowseRestaurants;

  @override
  Widget build(BuildContext context) {
    final copy = AppLocalizations.of(context).favorites;
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    final theme = Theme.of(context);

    if ((state.status == FavoritesStatus.initial || state.isLoading) &&
        state.items.isEmpty) {
      return _CenteredFeedback(
        key: const Key('favorites_loading_state'),
        icon: Icons.favorite_border_rounded,
        title: copy.loading,
        message: copy.loading,
        loading: true,
      );
    }
    if (state.hasError && state.items.isEmpty) {
      return _CenteredFeedback(
        key: const Key('favorites_error_state'),
        icon: Icons.cloud_off_outlined,
        title: copy.loadFailed,
        message: copy.actionFailed,
        action: AppButton(
          key: const Key('favorites_retry_button'),
          width: 220,
          text: copy.retry,
          onPressed: () => onRetry(),
        ),
      );
    }
    if (state.isEmpty) {
      return _CenteredFeedback(
        key: const Key('favorites_empty_state'),
        icon: Icons.favorite_border_rounded,
        title: copy.emptyTitle,
        message: copy.emptyMessage,
        action: onBrowseRestaurants == null
            ? null
            : AppButton(
                key: const Key('favorites_browse_restaurants'),
                width: 220,
                text: copy.browseRestaurants,
                onPressed: onBrowseRestaurants,
              ),
      );
    }

    return RefreshIndicator(
      color: colors.primary,
      onRefresh: onRetry,
      child: CustomScrollView(
        key: const Key('favorites_populated_state'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 360 ||
                      MediaQuery.textScalerOf(context).scale(1) > 1.45;
                  final title = Semantics(
                    header: true,
                    child: Text(
                      copy.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colors.headingText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );
                  final count = Text(
                    copy.count(state.totalCount),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.mutedText,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                  return compact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            title,
                            const SizedBox(height: AppSpacing.xs),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: count,
                            ),
                          ],
                        )
                      : Row(
                          children: <Widget>[Expanded(child: title), count],
                        );
                },
              ),
            ),
          ),
          if (state.hasError && state.items.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: SliverToBoxAdapter(
                child: _FavoritesRefreshFailureBanner(onRetry: onRetry),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverList.separated(
              itemCount: state.items.length,
              itemBuilder: (context, index) => FavoriteMenuItemCard(
                key: Key(
                    'favorite_item_${state.items[index].menuItemId.toLowerCase()}'),
                item: state.items[index],
              ),
              findItemIndexCallback: (key) {
                if (key is! ValueKey<String>) return null;
                final index = state.items.indexWhere((item) =>
                    key.value ==
                    'favorite_item_${item.menuItemId.toLowerCase()}');
                return index < 0 ? null : index;
              },
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
            ),
          ),
          SliverToBoxAdapter(
            child: _FavoritesPaginationFooter(
              state: state,
              onLoadMore: onLoadMore,
              onRetry: onRetryMore,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
        ],
      ),
    );
  }
}

class _FavoritesRefreshFailureBanner extends StatelessWidget {
  const _FavoritesRefreshFailureBanner({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final copy = AppLocalizations.of(context).favorites;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('favorites_refresh_error'),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: AppRadius.smallRadius,
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              copy.actionFailed,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onErrorContainer,
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                key: const Key('favorites_refresh_retry'),
                onPressed: () => onRetry(),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(copy.retry),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FavoriteMenuItemCard extends StatelessWidget {
  const FavoriteMenuItemCard({required this.item, super.key});

  final FavoriteMenuItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arabic = l10n.locale.languageCode == 'ar';
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    return Semantics(
      label: item.nameFor(arabic),
      child: SharedProductCard(
        id: item.menuItemId,
        name: item.nameFor(arabic),
        description: item.descriptionFor(arabic),
        imageUrl: item.imageUrl,
        placeholder: const MenuArtworkPlaceholder(),
        price: Text(l10n.catalog.money(item.price),
            style: theme.textTheme.titleMedium?.copyWith(
                color: colors.headingText, fontWeight: FontWeight.w800)),
        metadata: item.isAvailable
            ? null
            : _AvailabilityPill(text: l10n.favorites.unavailable),
      ),
    );
  }
}

class _AvailabilityPill extends StatelessWidget {
  const _AvailabilityPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: .1),
        borderRadius: AppRadius.smallRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.headingText,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _FavoritesPaginationFooter extends StatelessWidget {
  const _FavoritesPaginationFooter({
    required this.state,
    required this.onLoadMore,
    required this.onRetry,
  });

  final FavoritesState state;
  final Future<void> Function() onLoadMore;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final copy = AppLocalizations.of(context).favorites;
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    final needsFooter =
        state.loadingMore || state.nextPageFailure != null || state.hasNextPage;
    if (!needsFooter) return const SizedBox(height: AppSpacing.lg);
    return Padding(
      key: const Key('favorites_pagination'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (state.loadingMore) ...<Widget>[
            SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(copy.loading),
          ] else if (state.nextPageFailure != null) ...<Widget>[
            Text(copy.paginationFailed, textAlign: TextAlign.center),
            TextButton(
              key: const Key('favorites_pagination_retry'),
              onPressed: () => onRetry(),
              child: Text(copy.retry),
            ),
          ] else
            TextButton(
              key: const Key('favorites_load_more'),
              onPressed: () => onLoadMore(),
              child: Text(copy.loadMore),
            ),
        ],
      ),
    );
  }
}

class _CenteredFeedback extends StatelessWidget {
  const _CenteredFeedback({
    required this.icon,
    required this.title,
    required this.message,
    this.loading = false,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool loading;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (loading)
              CircularProgressIndicator(color: colors.primary)
            else
              Icon(icon, size: 64, color: colors.mutedText),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colors.headingText,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.mutedText,
              ),
            ),
            if (action != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
