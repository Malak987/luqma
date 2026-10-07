import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_elevation.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import 'brand_icon.dart';

/// Data/configuration for one provider. Adding a provider does not require a
/// new button class.
class SocialLoginConfig {
  const SocialLoginConfig({
    required this.provider,
    required this.tooltip,
    this.icon,
    this.iconSize,
    this.iconColor,
    this.width,
    this.height,
    this.backgroundColor,
    this.border,
    this.borderRadius,
    this.elevation,
    this.loading = false,
    this.enabled = true,
    this.onPressed,
  });

  final SocialProvider provider;
  final Widget? icon;
  final double? iconSize;
  final Color? iconColor;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final BorderSide? border;
  final BorderRadius? borderRadius;
  final double? elevation;
  final bool loading;
  final bool enabled;
  final String tooltip;
  final VoidCallback? onPressed;
}

class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({required this.config, super.key});

  final SocialLoginConfig config;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semanticColors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final size = config.width ?? AppSizes.socialButtonSize;
    final foreground = config.iconColor ?? semanticColors.bodyText;
    final enabled =
        config.enabled && !config.loading && config.onPressed != null;
    final icon = config.loading
        ? SizedBox(
            width: config.iconSize ?? AppSizes.iconMedium,
            height: config.iconSize ?? AppSizes.iconMedium,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foreground),
            ),
          )
        : IconTheme.merge(
            data: IconThemeData(
              color: foreground,
              size: config.iconSize ?? AppSizes.iconMedium,
            ),
            child: config.icon ??
                SocialProviderIcon(
                  provider: config.provider,
                  size: config.iconSize ?? AppSizes.iconMedium,
                  color: config.iconColor,
                ),
          );

    return Semantics(
      button: true,
      enabled: enabled,
      label: config.tooltip,
      child: SizedBox(
        width: size,
        height: config.height ?? AppSizes.socialButtonSize,
        child: Material(
          color: config.backgroundColor ?? semanticColors.surface,
          elevation: config.elevation ?? AppElevation.none,
          shape: RoundedRectangleBorder(
            borderRadius: config.borderRadius ?? AppRadius.pillRadius,
            side: config.border ?? BorderSide(color: semanticColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? config.onPressed : null,
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }
}

class SocialLoginRow extends StatelessWidget {
  const SocialLoginRow({
    required this.providers,
    super.key,
    this.spacing = AppSpacing.xl,
  });

  final List<SocialLoginConfig> providers;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Row(
        textDirection: TextDirection.ltr,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (var index = 0; index < providers.length; index++) ...<Widget>[
            if (index > 0) SizedBox(width: spacing),
            SocialLoginButton(config: providers[index]),
          ],
        ],
      ),
    );
  }
}
