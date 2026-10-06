import 'package:flutter/material.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/widgets/app_text_field.dart';

/// Password behavior lives here, while the actual field rendering remains the
/// same AppTextField used by every other form in the application.
class AuthPasswordField extends StatefulWidget {
  const AuthPasswordField({
    required this.controller,
    required this.hintText,
    required this.lockTooltip,
    super.key,
    this.validator,
    this.onSubmitted,
    this.autofocus = false,
    this.focusNode,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hintText;
  final String lockTooltip;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool enabled;

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
    final isRtl = Directionality.of(context) == TextDirection.rtl;
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
    final lockIcon = Tooltip(
      message: widget.lockTooltip,
      child: const Icon(Icons.lock_outline_rounded),
    );

    // Keep the eye on the visual left and the field-type lock on the visual
    // right, as in the supplied composition, while the text itself remains
    // direction-aware.
    return AppTextField(
      controller: widget.controller,
      hintText: widget.hintText,
      obscureText: _obscured,
      validator: widget.validator,
      onSubmitted: widget.onSubmitted,
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      prefixIcon: isRtl ? lockIcon : visibilityButton,
      suffixIcon: isRtl ? visibilityButton : lockIcon,
      iconColor: colors.mutedText,
      iconSize: AppSizes.iconMedium,
      semanticLabel: l10n.auth.password,
    );
  }
}
