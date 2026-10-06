import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';

class AppSettingsState extends Equatable {
  const AppSettingsState({
    required this.locale,
    required this.themeMode,
  });

  const AppSettingsState.initial()
      : locale = const Locale(AppConstants.defaultLocale),
        themeMode = ThemeMode.dark;

  final Locale locale;
  final ThemeMode themeMode;

  AppSettingsState copyWith({
    Locale? locale,
    ThemeMode? themeMode,
  }) {
    return AppSettingsState(
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  List<Object> get props => <Object>[locale, themeMode];
}
