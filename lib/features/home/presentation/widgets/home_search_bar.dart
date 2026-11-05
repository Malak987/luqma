import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_text_field.dart';

/// Polished search field — compact, elevated, and visually integrated.
/// Keeps existing behavior (onSubmitted → SnackBar) without fake functionality.
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
        borderRadius: AppRadius.mediumRadius,
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.border.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AppTextField(
        hintText: hintText,
        semanticLabel: hintText,
        prefixIcon: Icon(Icons.search, color: colors.mutedText),
        suffixIcon: Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.10),
            borderRadius: AppRadius.smallRadius,
          ),
          child: Icon(Icons.tune, size: 18, color: colors.primary),
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
