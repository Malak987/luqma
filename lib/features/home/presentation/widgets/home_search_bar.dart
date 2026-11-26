import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_text_field.dart';

/// Search entry point. The trailing filter affordance is intentionally omitted
/// until filtering is available, so the field does not imply a fake action.
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

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.largeRadius,
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: .045),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: AppTextField(
        hintText: hintText,
        semanticLabel: hintText,
        prefixIcon: Icon(
          Icons.search_rounded,
          color: colors.mutedText,
          size: AppSizes.iconLarge,
        ),
        iconSize: AppSizes.iconMedium,
        textInputAction: TextInputAction.search,
        onSubmitted: onSubmitted,
        backgroundColor: Colors.transparent,
        borderColor: Colors.transparent,
        focusedBorderColor: Colors.transparent,
      ),
    );
  }
}
