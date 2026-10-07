import 'package:flutter/material.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/localization/validation_messages.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/widgets/app_text_field.dart';

/// Email-only sign-in field.
class LoginEmailField extends StatelessWidget {
  const LoginEmailField({
    required this.controller,
    required this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;

    return AppTextField(
      controller: controller,
      hintText: l10n.auth.email,
      semanticLabel: l10n.auth.emailLabel,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const <String>[AutofillHints.email],
      prefixIcon: const Icon(Icons.alternate_email_rounded),
      iconColor: colors.mutedText,
      iconSize: AppSizes.iconMedium,
      validator: (value) => l10n.validationMessage(Validators.email(value)),
      onSubmitted: onSubmitted,
    );
  }
}
