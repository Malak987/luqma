import 'package:flutter/material.dart';

import '../../../../../core/localization/validation_messages.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/widgets/app_text_field.dart';

/// One plain registration field: a leading icon, a hint and a validator. The
/// page passes the controller/focus wiring, nothing else lives here.
class RegisterTextField extends StatelessWidget {
  const RegisterTextField({
    required this.controller,
    required this.hintText,
    required this.semanticLabel,
    required this.icon,
    required this.keyboardType,
    required this.validator,
    required this.onSubmitted,
    super.key,
    this.focusNode,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String hintText;
  final String semanticLabel;
  final IconData icon;
  final TextInputType keyboardType;
  final ValidationErrorKey? Function(String? value) validator;
  final ValueChanged<String> onSubmitted;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;

    return AppTextField(
      controller: controller,
      hintText: hintText,
      semanticLabel: semanticLabel,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      autofillHints: autofillHints,
      validator: (value) => l10n.validationMessage(validator(value)),
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      prefixIcon: Icon(icon),
      iconColor: colors.mutedText,
      iconSize: AppSizes.iconMedium,
    );
  }
}
