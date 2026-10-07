import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Theme-aware layout rhythm for the authentication composition.
///
/// The widget hierarchy stays identical in both themes while the vertical
/// breathing room can honor the supplied dark reference without duplicating a
/// light or dark screen.
@immutable
class AppLayoutMetrics extends ThemeExtension<AppLayoutMetrics> {
  const AppLayoutMetrics({
    required this.authLogoToForm,
    required this.authForgotToDivider,
    required this.authSocialToFooter,
  });

  final double authLogoToForm;
  final double authForgotToDivider;
  final double authSocialToFooter;

  static const AppLayoutMetrics light = AppLayoutMetrics(
    authLogoToForm: 48,
    authForgotToDivider: 32,
    authSocialToFooter: 32,
  );

  static const AppLayoutMetrics dark = AppLayoutMetrics(
    authLogoToForm: 72,
    authForgotToDivider: 72,
    authSocialToFooter: 72,
  );

  @override
  AppLayoutMetrics copyWith({
    double? authLogoToForm,
    double? authForgotToDivider,
    double? authSocialToFooter,
  }) {
    return AppLayoutMetrics(
      authLogoToForm: authLogoToForm ?? this.authLogoToForm,
      authForgotToDivider:
      authForgotToDivider ?? this.authForgotToDivider,
      authSocialToFooter: authSocialToFooter ?? this.authSocialToFooter,
    );
  }

  @override
  AppLayoutMetrics lerp(ThemeExtension<AppLayoutMetrics>? other, double t) {
    if (other is! AppLayoutMetrics) {
      return this;
    }

    return AppLayoutMetrics(
      authLogoToForm:
      lerpDouble(authLogoToForm, other.authLogoToForm, t)!,
      authForgotToDivider:
      lerpDouble(authForgotToDivider, other.authForgotToDivider, t)!,
      authSocialToFooter:
      lerpDouble(authSocialToFooter, other.authSocialToFooter, t)!,
    );
  }
}
