import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Round icon button used for headers and image overlays. Pass [tooltip] so the
/// button always has a spoken label.
class AppCircleIconButton extends StatelessWidget {
  const AppCircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 44,
    this.backgroundColor,
    this.iconColor,
    this.borderColor,
    super.key,
  });

  static const double defaultSize = 44;

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    return Semantics(
      button: true,
      label: tooltip,
      excludeSemantics: true,
      child: Material(
        color: backgroundColor ?? colors.surface,
        shape: CircleBorder(
          side: borderColor == null
              ? BorderSide.none
              : BorderSide(color: borderColor!),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: size,
            child: Icon(icon, size: 20, color: iconColor ?? colors.headingText),
          ),
        ),
      ),
    );
  }
}
