import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/extensions/locale_extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../domain/entities/home_category.dart';
import '../cubit/home_state.dart';
import 'home_section.dart';

/// Compact horizontal category rail backed by the loaded category snapshot.
///
/// The items are deliberately card-less: a flat circular backdrop, the artwork,
/// then the category name. No box, border, shadow or gradient competes with the
/// illustration. The API image still wins when the category provides one; a
/// bundled transparent SVG illustration is used otherwise.
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

  /// Fixed item height: illustration, gap, one or two label lines. The rail is
  /// tall enough for a 2× text scale.
  static const double _railHeight = 132;

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
          height: _railHeight,
          child: ListView.separated(
            key: const PageStorageKey('home_categories_rail'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) => _CategoryItem(
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

/// One rail item: circular backdrop, artwork, name. No card, no shadow.
class _CategoryItem extends StatelessWidget {
  const _CategoryItem({required this.category, this.onTap});

  final HomeCategory category;
  final VoidCallback? onTap;

  static const double _width = 84;
  static const double _artSize = 64;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final locale = AppLocalizations.of(context).locale;
    final name = locale.isArabic ? category.nameAr : category.nameEn;

    return SizedBox(
      width: _width,
      child: Semantics(
        button: onTap != null,
        label: name,
        excludeSemantics: true,
        child: Material(
          key: Key('category_card_${category.id}'),
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(_artSize / 2),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(_artSize / 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  key: Key('category_icon_background_${category.id}'),
                  width: _artSize,
                  height: _artSize,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colors.iconSurface,
                    shape: BoxShape.circle,
                  ),
                  child: _CategoryArtwork(category: category),
                ),
                const SizedBox(height: AppSpacing.xs),
                Flexible(
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.headingText,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      height: 1.2,
                    ),
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

/// Prefers the API category image; otherwise draws the matching bundled SVG.
class _CategoryArtwork extends StatelessWidget {
  const _CategoryArtwork({required this.category});

  final HomeCategory category;

  /// Bundled transparent-background line art, one per staple category, drawn in
  /// the same burgundy/gold style so the rail reads as one set.
  static const Map<String, String> _assets = <String, String>{
    'pharmacy': 'assets/category_icons/pharmacy.svg',
    'drinks': 'assets/category_icons/drinks.svg',
    'vegetables': 'assets/category_icons/vegetables.svg',
    'dessert': 'assets/category_icons/dessert.svg',
    'bakery': 'assets/category_icons/bakery.svg',
    'grill': 'assets/category_icons/grill.svg',
    'food': 'assets/category_icons/food.svg',
  };

  String? _assetForCategory() {
    final names = '${category.nameAr} ${category.nameEn}'.toLowerCase();
    bool has(List<String> terms) => terms.any(names.contains);

    if (has(const ['صيدليات', 'صيدلية', 'أدوية', 'دواء', 'pharmacy'])) {
      return _assets['pharmacy'];
    }
    if (has(const ['مشروبات', 'مشروب', 'عصائر', 'drinks', 'beverages'])) {
      return _assets['drinks'];
    }
    if (has(const ['خضروات', 'خضار', 'فواكه', 'vegetable', 'vegetables'])) {
      return _assets['vegetables'];
    }
    if (has(const ['حلويات', 'حلوى', 'كيك', 'dessert', 'sweets', 'cakes'])) {
      return _assets['dessert'];
    }
    if (has(const ['مخبوزات', 'خبز', 'معجنات', 'bakery', 'bread', 'pastry'])) {
      return _assets['bakery'];
    }
    if (has(const ['مشويات', 'لحوم', 'شواء', 'grill', 'grills', 'meat', 'bbq'])) {
      return _assets['grill'];
    }
    if (has(const [
      'مأكولات',
      'أطعمة',
      'طعام',
      'مطاعم',
      'مطعم',
      'وجبات',
      'food',
      'foods',
      'restaurant',
      'restaurants',
    ])) {
      return _assets['food'];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = _assetForCategory();

    final fallback = asset == null
        ? Icon(Icons.restaurant_menu, size: 30, color: colors.primary)
        // The artwork palette is fixed (burgundy on cream). In dark mode the
        // same line art is tinted gold so it keeps its contrast.
        : (isDark
            ? ColorFiltered(
                colorFilter: ColorFilter.mode(colors.accent, BlendMode.srcIn),
                child: SvgPicture.asset(
                  asset,
                  key: ValueKey<String>(asset),
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
              )
            : SvgPicture.asset(
                asset,
                key: ValueKey<String>(asset),
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ));

    return AppNetworkImage(
      url: category.iconUrl,
      fit: BoxFit.contain,
      placeholder: fallback,
    );
  }
}
