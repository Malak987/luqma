import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AuthBackground extends StatelessWidget {
  const AuthBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        gradient: RadialGradient(
          center: const Alignment(0, -0.72),
          radius: isDark ? 1.05 : 1.15,
          colors: isDark
              ? <Color>[
                  Color.alphaBlend(
                    colors.accent.withValues(alpha: .30),
                    colors.surface,
                  ),
                  colors.surface.withValues(alpha: .72),
                  colors.background,
                ]
              : <Color>[
                  colors.surface.withValues(alpha: .35),
                  colors.background,
                  colors.background,
                ],
          stops: const <double>[0, .44, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (isDark)
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.transparent,
                      colors.background.withValues(alpha: .18),
                      colors.background.withValues(alpha: .88),
                    ],
                    stops: const <double>[0, .46, 1],
                  ),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}
