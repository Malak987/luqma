import 'package:flutter/material.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/localization/validation_messages.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/validators.dart';
import '../../../shared/widgets/auth_password_field.dart';
import '../../../shared/widgets/password_requirements.dart';

/// Password + live requirements panel + confirmation.
class RegisterPasswordSection extends StatelessWidget {
  const RegisterPasswordSection({
    required this.passwordController,
    required this.confirmController,
    required this.passwordFocusNode,
    required this.confirmFocusNode,
    required this.onSubmit,
    super.key,
  });

  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final FocusNode passwordFocusNode;
  final FocusNode confirmFocusNode;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AuthPasswordField(
          controller: passwordController,
          hintText: l10n.auth.password,
          focusNode: passwordFocusNode,
          textInputAction: TextInputAction.next,
          autofillHints: const <String>[AutofillHints.newPassword],
          validator: (value) =>
              l10n.validationMessage(Validators.strongPassword(value)),
          onSubmitted: (_) => confirmFocusNode.requestFocus(),
        ),
        const SizedBox(height: AppSpacing.sm),
        PasswordRequirements(controller: passwordController),
        const SizedBox(height: AppSpacing.md),
        AuthPasswordField(
          controller: confirmController,
          hintText: l10n.auth.confirmPassword,
          focusNode: confirmFocusNode,
          autofillHints: const <String>[AutofillHints.newPassword],
          validator: (value) => l10n.validationMessage(
            Validators.confirmPassword(value, passwordController.text),
          ),
          onSubmitted: (_) => onSubmit(),
        ),
      ],
    );
  }
}
