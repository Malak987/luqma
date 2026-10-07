import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_elevation.dart';
import 'app_radius.dart';
import 'app_sizes.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(
        brightness: Brightness.light,
        colors: AppSemanticColors.light,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        colors: AppSemanticColors.dark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required AppSemanticColors colors,
  }) {
    final colorScheme = brightness == Brightness.light
        ? ColorScheme.light(
            primary: colors.primary,
            onPrimary: colors.onPrimary,
            secondary: colors.accent,
            onSecondary: colors.bodyText,
            error: const Color(0xFFBA1A1A),
            onError: Colors.white,
            surface: colors.surface,
            onSurface: colors.bodyText,
            outline: colors.border,
          )
        : ColorScheme.dark(
            primary: colors.primary,
            onPrimary: colors.onPrimary,
            secondary: colors.accent,
            onSecondary: colors.bodyText,
            error: const Color(0xFFFFB4AB),
            onError: const Color(0xFF690005),
            surface: colors.surface,
            onSurface: colors.bodyText,
            outline: colors.border,
          );

    final baseTextTheme = ThemeData(
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: AppTextStyles.fontFamily,
      useMaterial3: true,
    ).textTheme;
    final textTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        color: colors.headingText,
        fontFamilyFallback: AppTextStyles.fontFallbacks,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        color: colors.headingText,
        fontWeight: FontWeight.w700,
        fontFamilyFallback: AppTextStyles.fontFallbacks,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        color: colors.headingText,
        fontWeight: FontWeight.w700,
        fontFamilyFallback: AppTextStyles.fontFallbacks,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        color: colors.headingText,
        fontWeight: FontWeight.w700,
        fontFamilyFallback: AppTextStyles.fontFallbacks,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        color: colors.bodyText,
        fontWeight: FontWeight.w600,
        fontFamilyFallback: AppTextStyles.fontFallbacks,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        color: colors.bodyText,
        fontFamilyFallback: AppTextStyles.fontFallbacks,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: colors.bodyText,
        fontFamilyFallback: AppTextStyles.fontFallbacks,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        color: colors.mutedText,
        fontFamilyFallback: AppTextStyles.fontFallbacks,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        color: colors.onPrimary,
        fontWeight: FontWeight.w700,
        fontFamilyFallback: AppTextStyles.fontFallbacks,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        color: colors.mutedText,
        fontFamilyFallback: AppTextStyles.fontFallbacks,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        color: colors.mutedText,
        fontFamilyFallback: AppTextStyles.fontFallbacks,
      ),
    );

    final fieldBorder = OutlineInputBorder(
      borderRadius: AppRadius.largeRadius,
      borderSide: BorderSide(color: colors.border),
    );
    final focusedFieldBorder = OutlineInputBorder(
      borderRadius: AppRadius.largeRadius,
      borderSide: BorderSide(color: colors.primary, width: 1.5),
    );
    final errorFieldBorder = OutlineInputBorder(
      borderRadius: AppRadius.largeRadius,
      borderSide: BorderSide(color: colorScheme.error),
    );

    return ThemeData(
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: AppTextStyles.fontFamily,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[
        colors,
      ],
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: colors.mutedText),
        labelStyle: textTheme.bodyMedium?.copyWith(color: colors.mutedText),
        errorStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.error,
          height: 1.25,
        ),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: focusedFieldBorder,
        errorBorder: errorFieldBorder,
        focusedErrorBorder: errorFieldBorder,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.authButtonHeight),
          shape: const StadiumBorder(),
          elevation: AppElevation.none,
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(AppSizes.touchTarget, AppSizes.touchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          foregroundColor: colors.primary,
          textStyle: textTheme.labelLarge?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.authButtonHeight),
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.border),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge?.copyWith(color: colors.primary),
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.none,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.largeRadius,
          side: BorderSide(color: colors.border),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surface,
        selectedColor: colors.primary,
        disabledColor: colors.elevatedSurface,
        side: BorderSide(color: colors.border),
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.elevatedSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.xlargeRadius,
          side: BorderSide(color: colors.elevatedBorder),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.elevatedSurface,
        indicatorColor: colors.primary.withValues(alpha: .14),
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.elevatedSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors.bodyText,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumRadius),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.onPrimary,
        linearTrackColor: colors.primary.withValues(alpha: .2),
      ),
    );
  }
}
