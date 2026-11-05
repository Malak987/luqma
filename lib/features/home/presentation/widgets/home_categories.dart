import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/home_category.dart';
import 'home_section.dart';

/// Catalog grid of the home screen — now TWO columns on mobile for a compact,
/// balanced layout that avoids excessive vertical space.
///
/// Keeps icons proportional and uses Luqma semantic colors for light/dark.
class HomeCategories extends StatelessWidget {
  const HomeCategories({required this.categories, super.key});

  final List<HomeCategory> categories;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return HomeSection(
      title: l10n.home.categoriesTitle,
      child: categories.isEmpty
          ? HomeSectionPlaceholder(
              icon: Icons.category_outlined,
              message: l10n.home.categoriesEmpty,
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                // Two columns on phones (320px+), scales gracefully on tablet
                final isNarrow = constraints.maxWidth < 340;
                final crossAxisCount = isNarrow ? 2 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: isNarrow ? 1.6 : 1.8,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) =>
                      _CategoryCard(category: categories[index]),
                );
              },
            ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});

  final HomeCategory category;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final theme = Theme.of(context);

    return Card(
      key: Key('category_card_${category.id}'),
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mediumRadius,
        side: BorderSide(color: colors.border, width: 1),
      ),
      child: InkWell(
        borderRadius: AppRadius.mediumRadius,
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: AppRadius.smallRadius,
                ),
                child: Icon(
                  Icons.restaurant_menu,
                  size: 20,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.bodyText,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
