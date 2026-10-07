import 'package:flutter/material.dart';

abstract final class AppTextStyles {
  /// Bundled family (Arabic + Latin) so typography is identical on every device.
  static const String fontFamily = 'Tajawal';

  static const List<String> fontFallbacks = <String>[
    'Noto Sans Arabic',
    'Noto Naskh Arabic',
    'Geeza Pro',
    'Arial',
  ];

  static TextStyle withArabicFallback({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      fontFamilyFallback: fontFallbacks,
    );
  }
}
