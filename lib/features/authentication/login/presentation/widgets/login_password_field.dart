import 'package:flutter/material.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/localization/validation_messages.dart';
import '../../../../../core/utils/validators.dart';
import '../../../shared/widgets/auth_password_field.dart';

class LoginPasswordField extends StatelessWidget {
  const LoginPasswordField({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AuthPasswordField(
      controller: controller,
      hintText: l10n.auth.password,
      focusNode: focusNode,
      autofillHints: const <String>[AutofillHints.password],
      validator: (value) =>
          l10n.validationMessage(Validators.loginPassword(value)),
      onSubmitted: (_) => onSubmitted(),
    );
  }
}
