import 'package:flutter/material.dart';

import '../../../../core/extensions/locale_extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../domain/entities/home_category.dart';
import '../cubit/home_state.dart';
import 'home_section.dart';

/// Compact horizontal category rail backed by the loaded category snapshot.
class HomeCategories extends StatelessWidget {
  const HomeCategories({
    required this.categories,
    this.status = HomeCategoriesStatus.success,
    this.onRetry,
    this.onCategoryTap,
    this.onSeeAll,
    super.key,
  });

  final List<HomeCategory> categories;
  final HomeCategoriesStatus status;
  final VoidCallback? onRetry;
  final ValueChanged<HomeCategory>? onCategoryTap;

  /// "See all" is only shown when a destination exists for it.
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context).home;
    return HomeSection(
      title: l10n.categoriesTitle,
      subtitle: l10n.categoriesSubtitle,
      seeAllLabel: l10n.seeAll,
      onSeeAll: onSeeAll,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context).home;
    switch (status) {
      case HomeCategoriesStatus.initial:
      case HomeCategoriesStatus.loading:
        return Card(
          key: const Key('home_categories_loading'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
                semanticsLabel: l10n.categoriesLoading,
              ),
            ),
          ),
        );
      case HomeCategoriesStatus.error:
        return HomeSectionPlaceholder(
          key: const Key('home_categories_error'),
          icon: Icons.error_outline,
          message: l10n.categoriesLoadFailed,
          action: SizedBox(
            width: 220,
            child: AppButton(
              key: const Key('home_categories_retry'),
              text: l10n.retry,
              onPressed: onRetry,
            ),
          ),
        );
      case HomeCategoriesStatus.empty:
      case HomeCategoriesStatus.success:
        if (categories.isEmpty) {
          return HomeSectionPlaceholder(
            key: const Key('home_categories_empty'),
            icon: Icons.category_outlined,
            message: l10n.categoriesEmpty,
          );
        }
        return SizedBox(
          height: 148,
          child: ListView.separated(
            key: const PageStorageKey('home_categories_rail'),
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) => _CategoryCard(
              category: categories[index],
              onTap: onCategoryTap == null
                  ? null
                  : () => onCategoryTap!(categories[index]),
            ),
          ),
        );
    }
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, this.onTap});

  final HomeCategory category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context).locale;

    return SizedBox(
      width: 104,
      child: Card(
        key: Key('category_card_${category.id}'),
        elevation: 0,
        color: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.largeRadius,
          side: BorderSide(color: colors.border, width: 1),
        ),
        child: InkWell(
          borderRadius: AppRadius.largeRadius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.xs,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  key: Key('category_icon_background_${category.id}'),
                  width: 68,
                  height: 68,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      colors.primary.withValues(
                        alpha: theme.brightness == Brightness.dark ? .14 : .055,
                      ),
                      colors.elevatedSurface,
                    ),
                    borderRadius: AppRadius.mediumRadius,
                  ),
                  child: _CategoryImage(category: category),
                ),
                const SizedBox(height: AppSpacing.sm),
                Flexible(
                  child: Text(
                    locale.isArabic ? category.nameAr : category.nameEn,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.headingText,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Prefers the category image supplied by the API and falls back to the
/// matching bundled illustration when the URL is missing or cannot load.
class _CategoryImage extends StatelessWidget {
  const _CategoryImage({required this.category});

  final HomeCategory category;

  static const Map<String, String> _assets = {
    'drinks': 'assets/category_icons/drinks.png',
    'vegetables': 'assets/category_icons/vegetables.png',
    'dessert': 'assets/category_icons/dessert.png',
    'food': 'assets/category_icons/food.png',
    'pharmacy': 'assets/category_icons/pharmacy.png',
  };

  String? _assetForCategory() {
    final names = '${category.nameAr} ${category.nameEn}'.toLowerCase();
    if (_containsAny(
        names, const ['صيدليات', 'صيدلية', 'أدوية', 'دواء', 'pharmacy'])) {
      return _assets['pharmacy'];
    }
    if (_containsAny(
        names, const ['مشروبات', 'مشروب', 'drinks', 'beverages'])) {
      return _assets['drinks'];
    }
    if (_containsAny(
        names, const ['خضروات', 'خضار', 'vegetable', 'vegetables'])) {
      return _assets['vegetables'];
    }
    if (_containsAny(names, const ['حلويات', 'حلوى', 'dessert', 'sweets'])) {
      return _assets['dessert'];
    }
    if (_containsAny(names, const [
      'مأكولات',
      'أطعمة',
      'طعام',
      'مطاعم',
      'مطعم',
      'food',
      'foods',
      'restaurant',
      'restaurants',
    ])) {
      return _assets['food'];
    }
    return null;
  }

  bool _containsAny(String value, List<String> terms) =>
      terms.any(value.contains);

  @override
  Widget build(BuildContext context) {
    final asset = _assetForCategory();
    final fallback = asset == null
        ? const _CategoryImagePlaceholder()
        : Image.asset(
            asset,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
            errorBuilder: (context, error, stackTrace) =>
                const _CategoryImagePlaceholder(),
          );

    return AppNetworkImage(
      url: category.iconUrl,
      fit: BoxFit.contain,
      placeholder: fallback,
    );
  }
}

class _CategoryImagePlaceholder extends StatelessWidget {
  const _CategoryImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    return Icon(Icons.restaurant_menu, size: 32, color: colors.primary);
  }
}
