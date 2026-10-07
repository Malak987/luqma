import 'package:flutter/material.dart';

import '../theme/app_elevation.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';

enum AppButtonIconPosition { leading, trailing }

/// Generic button primitive used by authentication and future application
/// actions. Screen-specific buttons should configure this widget rather than
/// reimplementing its loading, disabled, and accessibility behavior.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.text,
    super.key,
    this.width,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
    this.textStyle,
    this.borderRadius,
    this.padding,
    this.margin,
    this.icon,
    this.iconSize,
    this.iconColor,
    this.iconPosition = AppButtonIconPosition.leading,
    this.border,
    this.elevation,
    this.loading = false,
    this.enabled = true,
    this.onPressed,
    this.semanticLabel,
  });

  final String text;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final TextStyle? textStyle;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Widget? icon;
  final double? iconSize;
  final Color? iconColor;
  final AppButtonIconPosition iconPosition;
  final BorderSide? border;
  final double? elevation;
  final bool loading;
  final bool enabled;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final effectiveForeground = foregroundColor ?? colors.onPrimary;
    final effectiveHeight = height ?? AppSizes.authButtonHeight;
    final effectiveRadius = borderRadius ?? AppRadius.pillRadius;
    final effectivePadding =
        padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.xl);
    final canPress = enabled && !loading && onPressed != null;

    final buttonChild = loading
        ? SizedBox(
            width: AppSizes.iconMedium,
            height: AppSizes.iconMedium,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveForeground),
            ),
          )
        : _ButtonContent(
            text: text,
            textStyle: textStyle ?? theme.textTheme.labelLarge,
            foregroundColor: effectiveForeground,
            icon: icon,
            iconSize: iconSize,
            iconColor: iconColor,
            iconPosition: iconPosition,
          );

    Widget result = SizedBox(
      width: width,
      height: effectiveHeight,
      child: ElevatedButton(
        onPressed: canPress ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? colors.primary,
          foregroundColor: effectiveForeground,
          disabledBackgroundColor:
              (backgroundColor ?? colors.primary).withValues(alpha: .45),
          disabledForegroundColor: effectiveForeground.withValues(alpha: .65),
          elevation: elevation ?? AppElevation.none,
          padding: effectivePadding,
          shape: RoundedRectangleBorder(
            borderRadius: effectiveRadius,
            side: border ?? BorderSide.none,
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: textStyle ?? theme.textTheme.labelLarge,
        ),
        child: buttonChild,
      ),
    );

    if (margin != null) {
      result = Padding(padding: margin!, child: result);
    }

    return Semantics(
      button: true,
      enabled: canPress,
      label: semanticLabel ?? text,
      child: result,
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.text,
    required this.textStyle,
    required this.foregroundColor,
    required this.icon,
    required this.iconSize,
    required this.iconColor,
    required this.iconPosition,
  });

  final String text;
  final TextStyle? textStyle;
  final Color foregroundColor;
  final Widget? icon;
  final double? iconSize;
  final Color? iconColor;
  final AppButtonIconPosition iconPosition;

  @override
  Widget build(BuildContext context) {
    final resolvedIcon = icon == null
        ? null
        : IconTheme.merge(
            data: IconThemeData(
              color: iconColor ?? foregroundColor,
              size: iconSize,
            ),
            child: icon!,
          );
    final label = Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: textStyle?.copyWith(color: foregroundColor),
    );

    if (resolvedIcon == null) {
      return Center(child: label);
    }

    final iconWithSpacing = Padding(
      padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
      child: resolvedIcon,
    );
    final flexibleLabel = Flexible(child: label);
    final children = iconPosition == AppButtonIconPosition.leading
        ? <Widget>[iconWithSpacing, flexibleLabel]
        : <Widget>[
            flexibleLabel,
            Padding(
              padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
              child: resolvedIcon,
            ),
          ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}
