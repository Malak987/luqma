import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_section_feedback.dart';

/// Invalid deep links never resolve a cubit or initiate a network request.
class InvalidCatalogRoutePage extends StatelessWidget {
  const InvalidCatalogRoutePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: SafeArea(
            child: Center(
                child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: AppSectionFeedback(
              icon: Icons.storefront_outlined,
              message: AppLocalizations.of(context).catalog.invalidNavigation),
        ))),
      );
}
