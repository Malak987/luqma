import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_text_field.dart';

/// Password behavior (lock icon, show/hide toggle) on top of the shared
/// [AppTextField]. The lock sits at the start of the field and the toggle at
/// the end, mirrored automatically in RTL.
class AuthPasswordField extends StatefulWidget {
  const AuthPasswordField({
    required this.controller,
    required this.hintText,
    super.key,
    this.validator,
    this.onSubmitted,
    this.onChanged,
    this.autofocus = false,
    this.focusNode,
    this.enabled = true,
    this.textInputAction = TextInputAction.done,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String hintText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool enabled;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;

    final visibilityButton = IconButton(
      onPressed: () => setState(() => _obscured = !_obscured),
      tooltip: _obscured ? l10n.auth.showPassword : l10n.auth.hidePassword,
      icon: Icon(
        _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
      iconSize: AppSizes.iconMedium,
      color: colors.mutedText,
      constraints: const BoxConstraints(
        minWidth: AppSizes.touchTarget,
        minHeight: AppSizes.touchTarget,
      ),
      padding: EdgeInsets.zero,
    );

    return AppTextField(
      controller: widget.controller,
      hintText: widget.hintText,
      obscureText: _obscured,
      validator: widget.validator,
      onSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      prefixIcon: const Icon(Icons.lock_outline_rounded),
      suffixIcon: visibilityButton,
      iconColor: colors.mutedText,
      iconSize: AppSizes.iconMedium,
      semanticLabel: widget.hintText,
    );
  }
}
