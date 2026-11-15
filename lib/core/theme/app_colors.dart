import 'package:flutter/material.dart';

/// Semantic colors used by widgets instead of raw light/dark branches.
///
/// The values are exposed as a ThemeExtension so feature widgets can read the
/// right palette with `Theme.of(context).extension<AppSemanticColors>()`.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.background,
    required this.surface,
    required this.card,
    required this.primary,
    required this.onPrimary,
    required this.headingText,
    required this.bodyText,
    required this.mutedText,
    required this.inactiveNavigation,
    required this.accent,
    required this.link,
    required this.border,
    required this.divider,
    required this.elevatedSurface,
    required this.elevatedBorder,
  });

  final Color background;
  final Color surface;
  final Color card;
  final Color primary;
  final Color onPrimary;
  final Color headingText;
  final Color bodyText;
  final Color mutedText;
  final Color inactiveNavigation;
  final Color accent;
  final Color link;
  final Color border;
  final Color divider;
  final Color elevatedSurface;
  final Color elevatedBorder;

  static const AppSemanticColors light = AppSemanticColors(
    background: Color(0xFFF6F1E7),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFF7B1E28),
    onPrimary: Color(0xFFFFFFFF),
    headingText: Color(0xFF7B1E28),
    bodyText: Color(0xFF2B2B2B),
    mutedText: Color(0xFF5A4A44),
    inactiveNavigation: Color(0xFF9A8A82),
    accent: Color(0xFFC89F6A),
    link: Color(0xFF7B1E28),
    border: Color(0xFFEADBC8),
    divider: Color(0xFFEADBC8),
    elevatedSurface: Color(0xFFFFFFFF),
    elevatedBorder: Color(0xFFEADBC8),
  );

  static const AppSemanticColors dark = AppSemanticColors(
    background: Color(0xFF171717),
    surface: Color(0xFF222222),
    card: Color(0xFF222222),
    primary: Color(0xFF7B1E28),
    onPrimary: Color(0xFFF6F1E7),
    headingText: Color(0xFFF6F1E7),
    bodyText: Color(0xFFF6F1E7),
    mutedText: Color(0xFFCFC6BA),
    inactiveNavigation: Color(0xFF7A756F),
    accent: Color(0xFFC89F6A),
    link: Color(0xFFC89F6A),
    border: Color(0xFF2B2B2B),
    divider: Color(0xFF333333),
    elevatedSurface: Color(0xFF2B2B2B),
    elevatedBorder: Color(0xFF333333),
  );

  @override
  AppSemanticColors copyWith({
    Color? background,
    Color? surface,
    Color? card,
    Color? primary,
    Color? onPrimary,
    Color? headingText,
    Color? bodyText,
    Color? mutedText,
    Color? inactiveNavigation,
    Color? accent,
    Color? link,
    Color? border,
    Color? divider,
    Color? elevatedSurface,
    Color? elevatedBorder,
  }) {
    return AppSemanticColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      headingText: headingText ?? this.headingText,
      bodyText: bodyText ?? this.bodyText,
      mutedText: mutedText ?? this.mutedText,
      inactiveNavigation: inactiveNavigation ?? this.inactiveNavigation,
      accent: accent ?? this.accent,
      link: link ?? this.link,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      elevatedSurface: elevatedSurface ?? this.elevatedSurface,
      elevatedBorder: elevatedBorder ?? this.elevatedBorder,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) {
      return this;
    }

    return AppSemanticColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      headingText: Color.lerp(headingText, other.headingText, t)!,
      bodyText: Color.lerp(bodyText, other.bodyText, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      inactiveNavigation:
          Color.lerp(inactiveNavigation, other.inactiveNavigation, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      link: Color.lerp(link, other.link, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      elevatedSurface: Color.lerp(elevatedSurface, other.elevatedSurface, t)!,
      elevatedBorder: Color.lerp(elevatedBorder, other.elevatedBorder, t)!,
    );
  }
}
