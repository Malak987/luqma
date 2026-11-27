
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/extensions/locale_extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../domain/entities/home_category.dart';
import '../cubit/home_state.dart';
import 'home_section.dart';

/// Premium category cards backed by the loaded category snapshot.
///
/// Three larger cards are visible, with the next card slightly peeking in.
/// Each card is taller than it is wide to give the artwork more room.
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

        final ordered = _ordered(categories);

        return LayoutBuilder(
          key: const Key('home_categories_grid'),
          builder: (context, constraints) {
            const visibleCount = 3;
            const peek = 0.35;
            const gap = AppSpacing.sm;

            final overflowing = ordered.length > visibleCount;

            // Three cards are visible instead of four.
            // This makes every card and its artwork noticeably larger.
            final shownCount = overflowing
                ? visibleCount + peek
                : ordered.length.toDouble();

            final gapsCount = shownCount.ceil() - 1;

            final tileWidth = (constraints.maxWidth -
                gap * gapsCount) /
                shownCount;

            // A slightly taller card gives the illustration more vertical
            // room without scaling or cropping the original artwork.
            final cardHeight = tileWidth * 1.12;

            if (!overflowing) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (var i = 0; i < ordered.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(width: gap),
                    SizedBox(
                      width: tileWidth,
                      height: cardHeight,
                      child: _item(ordered[i], tileWidth),
                    ),
                  ],
                ],
              );
            }

            return SizedBox(
              height: cardHeight,
              child: ListView.separated(
                key: const PageStorageKey('home_categories_rail'),
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: ordered.length,
                separatorBuilder: (_, __) =>
                const SizedBox(width: gap),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: tileWidth,
                    height: cardHeight,
                    child: _item(ordered[index], tileWidth),
                  );
                },
              ),
            );
          },
        );
    }
  }

  Widget _item(HomeCategory category, double size) {
    return _CategoryItem(
      category: category,
      size: size,
      onTap: onCategoryTap == null
          ? null
          : () => onCategoryTap!(category),
    );
  }

  /// Restaurants, sweets, drinks, pharmacy, then everything else untouched.
  /// The sort is stable, so unknown categories keep the API order.
  static List<HomeCategory> _ordered(List<HomeCategory> input) {
    final indexed = input.asMap().entries.toList()
      ..sort((a, b) {
        final byRank = _rankOf(a.value).compareTo(_rankOf(b.value));
        return byRank != 0 ? byRank : a.key.compareTo(b.key);
      });

    return indexed.map((e) => e.value).toList(growable: false);
  }

  static int _rankOf(HomeCategory category) {
    final names =
    '${category.nameAr} ${category.nameEn}'.toLowerCase();

    bool has(List<String> terms) => terms.any(names.contains);

    if (has(_CategoryTerms.restaurants)) return 0;
    if (has(_CategoryTerms.sweets)) return 1;
    if (has(_CategoryTerms.drinks)) return 2;
    if (has(_CategoryTerms.pharmacy)) return 3;

    return 4;
  }
}

/// Arabic and English terms used to identify the main categories.
abstract final class _CategoryTerms {
  static const pharmacy = <String>[
    'صيدليات',
    'صيدلية',
    'أدوية',
    'دواء',
    'pharmacy',
  ];

  static const drinks = <String>[
    'مشروبات',
    'مشروب',
    'عصائر',
    'drinks',
    'beverages',
  ];

  static const sweets = <String>[
    'حلويات',
    'حلوى',
    'كيك',
    'dessert',
    'sweets',
    'cakes',
  ];

  static const restaurants = <String>[
    'مأكولات',
    'أطعمة',
    'طعام',
    'مطاعم',
    'مطعم',
    'وجبات',
    'وجبات سريعة',
    'food',
    'foods',
    'fast food',
    'restaurant',
    'restaurants',
  ];
}

/// A unified category card with large artwork and a transparent label area.
class _CategoryItem extends StatelessWidget {
  const _CategoryItem({
    required this.category,
    required this.size,
    this.onTap,
  });

  final HomeCategory category;
  final double size;
  final VoidCallback? onTap;

  static const double _radius = 24;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;

    final locale = AppLocalizations.of(context).locale;
    final name = locale.isArabic ? category.nameAr : category.nameEn;

    return Semantics(
      button: onTap != null,
      label: name,
      excludeSemantics: true,
      child: Material(
        color: colors.iconSurface,
        borderRadius: BorderRadius.circular(_radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_radius),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(2, 2, 2, 3),
            child: Column(
              children: [
                // Artwork gets almost all available card height.
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: _CategoryArtwork(
                      category: category,
                      size: size,
                    ),
                  ),
                ),

                // No separate label background or divider.
                SizedBox(
                  height: 21,
                  width: double.infinity,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.bodyText,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
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

/// Resolves category artwork.
///
/// Priority:
/// 1. Bundled 3D artwork for the four main categories.
/// 2. API image for other categories.
/// 3. Bundled SVG line art.
/// 4. A semantic fallback icon.
class _CategoryArtwork extends StatelessWidget {
  const _CategoryArtwork({
    required this.category,
    required this.size,
  });

  final HomeCategory category;
  final double size;

  static const Map<String, String> _assets = <String, String>{
    'vegetables': 'assets/category_icons/vegetables.svg',
    'bakery': 'assets/category_icons/bakery.svg',
    'grill': 'assets/category_icons/grill.svg',
    'food': 'assets/category_icons/food.svg',
  };

  String get _names =>
      '${category.nameAr} ${category.nameEn}'.toLowerCase();

  bool _has(List<String> terms) => terms.any(_names.contains);

  String? _imageForCategory() {
    if (_has(_CategoryTerms.pharmacy)) {
      return AppAssets.categoryPharmacy;
    }
    if (_has(_CategoryTerms.drinks)) {
      return AppAssets.categoryDrinks;
    }
    if (_has(_CategoryTerms.sweets)) {
      return AppAssets.categoryDesserts;
    }
    if (_has(_CategoryTerms.restaurants)) {
      return AppAssets.categoryFastFood;
    }
    return null;
  }

  String? _lineArtForCategory() {
    if (_has(const [
      'خضروات',
      'خضار',
      'فواكه',
      'vegetable',
      'vegetables',
    ])) {
      return _assets['vegetables'];
    }

    if (_has(const [
      'مخبوزات',
      'خبز',
      'معجنات',
      'bakery',
      'bread',
      'pastry',
    ])) {
      return _assets['bakery'];
    }

    if (_has(const [
      'مشويات',
      'لحوم',
      'شواء',
      'grill',
      'grills',
      'meat',
      'bbq',
    ])) {
      return _assets['grill'];
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final image = _imageForCategory();

    if (image != null) {
      return Semantics(
        image: true,
        excludeSemantics: true,
        child: Image.asset(
          image,
          key: ValueKey<String>(image),
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          cacheWidth: (size * 3).round(),
          errorBuilder: (_, __, ___) => _padded(_lineArt(context)),
        ),
      );
    }

    return AppNetworkImage(
      url: category.iconUrl,
      fit: BoxFit.contain,
      placeholder: _padded(_lineArt(context)),
    );
  }

  Widget _padded(Widget child) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(size * .08),
        child: child,
      ),
    );
  }

  Widget _lineArt(BuildContext context) {
    final theme = Theme.of(context);

    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;

    final isDark = theme.brightness == Brightness.dark;
    final asset = _lineArtForCategory();

    if (asset == null) {
      return Icon(
        Icons.restaurant_menu_rounded,
        size: size * .65,
        color: colors.primary,
      );
    }

    final svg = SvgPicture.asset(
      asset,
      key: ValueKey<String>(asset),
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    );

    // Keep the original burgundy line art readable in dark mode.
    return isDark
        ? ColorFiltered(
      colorFilter: const ColorFilter.mode(
        Color(0xFFE59AA3),
        BlendMode.srcIn,
      ),
      child: svg,
    )
        : svg;
  }
}
