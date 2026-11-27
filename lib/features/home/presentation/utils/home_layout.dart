import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';

/// Widest the Home content column grows on tablets, desktop and web.
///
/// The header background stays edge to edge at every width; only its content is
/// constrained to this column, so on a wide screen the greeting and the search
/// field line up with the sections below them.
const double homeContentMaxWidth = 1120;

/// Horizontal padding shared by the Home header content and the scroll view
/// below it, so the search field and every section start on the same edge at
/// any width.
double homeHorizontalPadding(double width) {
  if (width < AppSizes.compactWidth) return AppSpacing.md;
  if (width < AppSizes.mediumWidth) return AppSpacing.xl;
  return AppSpacing.xxl;
}

/// The brand burgundy as a *foreground* accent on Home (section bars, links,
/// tags, stripes).
///
/// Home's primary colour is burgundy, not gold. In light mode that is simply
/// `colors.primary`; on the dark surfaces the same burgundy is too dim to read
/// as text, so it lifts to a soft rose of the same hue.
Color homeAccent(BuildContext context) {
  final theme = Theme.of(context);
  final colors =
      theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
  return theme.brightness == Brightness.dark
      ? const Color(0xFFE59AA3)
      : colors.primary;
}

/// Burgundy gradient stops for the Home header (top-start → bottom-end).
List<Color> homeHeaderGradient(Brightness brightness) {
  return brightness == Brightness.dark
      ? const <Color>[Color(0xFF74202B), Color(0xFF4A0F18)]
      : const <Color>[Color(0xFF93283A), Color(0xFF65151F)];
}
