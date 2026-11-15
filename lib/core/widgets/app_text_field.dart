import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_colors.dart';

/// One configurable form field primitive shared by all features.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.textStyle,
    this.hintStyle,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.iconSize,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor,
    this.borderRadius,
    this.contentPadding,
    this.width,
    this.height,
    this.validator,
    this.enabled = true,
    this.readOnly = false,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.focusNode,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.autovalidateMode,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.errorText,
    this.semanticLabel,
    this.autofillHints,
  });

  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final double? iconSize;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? errorBorderColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? contentPadding;
  final double? width;
  final double? height;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final FocusNode? focusNode;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final AutovalidateMode? autovalidateMode;
  final TextAlign textAlign;
  final TextDirection? textDirection;
  final String? errorText;
  final String? semanticLabel;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return _BlurValidation(
      focusNode: focusNode,
      explicitMode: autovalidateMode,
      builder: _buildField,
    );
  }

  Widget _buildField(
    BuildContext context,
    FocusNode node,
    AutovalidateMode? mode,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final semanticColors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final radius = borderRadius ?? AppRadius.largeRadius;
    final normalBorder = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: borderColor ?? semanticColors.border),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(
        color: focusedBorderColor ?? semanticColors.primary,
        width: 1.5,
      ),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(
        color: errorBorderColor ?? scheme.error,
      ),
    );

    final effectiveMaxLines = obscureText ? 1 : maxLines;
    final decoration = InputDecoration(
      hintText: hintText,
      labelText: labelText,
      errorText: errorText,
      filled: true,
      fillColor: backgroundColor ?? semanticColors.surface,
      isDense: true,
      contentPadding: contentPadding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
      hintStyle: hintStyle ??
          theme.textTheme.bodyMedium?.copyWith(
            color: semanticColors.mutedText,
          ),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: semanticColors.mutedText,
      ),
      border: normalBorder,
      enabledBorder: normalBorder,
      focusedBorder: focusedBorder,
      errorBorder: errorBorder,
      focusedErrorBorder: errorBorder,
      prefixIcon: _withIconTheme(prefixIcon),
      suffixIcon: _withIconTheme(suffixIcon),
      prefixIconConstraints: const BoxConstraints(
        minWidth: AppSizes.touchTarget,
        minHeight: AppSizes.touchTarget,
      ),
      suffixIconConstraints: const BoxConstraints(
        minWidth: AppSizes.touchTarget,
        minHeight: AppSizes.touchTarget,
      ),
    );

    Widget field = TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      style: textStyle ?? theme.textTheme.bodyMedium,
      decoration: decoration,
      validator: validator,
      enabled: enabled,
      readOnly: readOnly,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      autofocus: autofocus,
      focusNode: node,
      maxLines: effectiveMaxLines,
      minLines: minLines,
      maxLength: maxLength,
      autovalidateMode: mode,
      textAlign: textAlign,
      textDirection: textDirection ?? Directionality.of(context),
      cursorColor: semanticColors.primary,
      autofillHints: autofillHints,
    );

    if (height != null || width != null) {
      field = SizedBox(width: width, height: height, child: field);
    }

    return Semantics(
      textField: true,
      label: semanticLabel ?? labelText ?? hintText,
      child: field,
    );
  }

  Widget? _withIconTheme(Widget? icon) {
    if (icon == null) {
      return null;
    }
    return IconTheme.merge(
      data: IconThemeData(
        size: iconSize ?? AppSizes.iconMedium,
        color: iconColor,
      ),
      child: icon,
    );
  }
}

/// Delays validation feedback until the user has left the field once.
///
/// While typing nothing is flagged; after the field loses focus it validates
/// live so the error clears the moment it is fixed. A form-level `validate()`
/// (submit) still checks every field regardless.
class _BlurValidation extends StatefulWidget {
  const _BlurValidation({
    required this.focusNode,
    required this.explicitMode,
    required this.builder,
  });

  final FocusNode? focusNode;
  final AutovalidateMode? explicitMode;
  final Widget Function(BuildContext, FocusNode, AutovalidateMode?) builder;

  @override
  State<_BlurValidation> createState() => _BlurValidationState();
}

class _BlurValidationState extends State<_BlurValidation> {
  FocusNode? _owned;
  bool _hadFocus = false;
  bool _touched = false;

  FocusNode get _node => widget.focusNode ?? (_owned ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _BlurValidation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _owned)?.removeListener(_onFocusChanged);
      _node.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    _node.removeListener(_onFocusChanged);
    _owned?.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_node.hasFocus) {
      _hadFocus = true;
    } else if (_hadFocus && !_touched) {
      setState(() => _touched = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      _node,
      widget.explicitMode ??
          (_touched ? AutovalidateMode.always : AutovalidateMode.disabled),
    );
  }
}
