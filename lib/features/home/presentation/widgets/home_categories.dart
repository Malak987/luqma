import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/home_category.dart';
import 'home_section.dart';

/// Catalog rail of the home screen.
///
/// The section renders whatever [categories] holds, so connecting the catalog
/// API later means filling the list — no widget changes and no sample data.
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
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  for (final category in categories)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: AppSpacing.xs,
                      ),
                      child: Chip(label: Text(category.name)),
                    ),
                ],
              ),
            ),
    );
  }
}
