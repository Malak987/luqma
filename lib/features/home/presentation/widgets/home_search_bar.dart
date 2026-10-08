import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_text_field.dart';

/// Search entry point of the home screen, built from the shared [AppTextField].
///
/// Only the UI is in place for now: there is no search endpoint to query yet,
/// so the widget stays data-free and delegates the submitted query to
/// [onSubmitted].
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({
    required this.hintText,
    super.key,
    this.onSubmitted,
  });

  final String hintText;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;

    return AppTextField(
      hintText: hintText,
      semanticLabel: hintText,
      prefixIcon: Icon(Icons.search, color: colors.mutedText),
      iconSize: AppSizes.iconMedium,
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmitted,
    );
  }
}
