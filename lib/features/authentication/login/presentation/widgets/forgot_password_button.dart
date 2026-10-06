import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_text_styles.dart';

class ForgotPasswordButton extends StatelessWidget {
  const ForgotPasswordButton({required this.text, required this.onPressed, super.key});

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppSemanticColors>() ?? AppSemanticColors.light;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: colors.mutedText,
        padding: EdgeInsets.zero,
        minimumSize: const Size(AppSizes.touchTarget, AppSizes.authLinkHeight),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTextStyles.withArabicFallback(
          fontSize: 12,
          color: colors.mutedText,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
