import 'package:flutter/material.dart';

abstract final class AppTextStyles {
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
