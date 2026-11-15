import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../constants/app_constants.dart';
import '../../storage/preferences_storage_service.dart';
import 'app_settings_state.dart';

class AppSettingsCubit extends Cubit<AppSettingsState> {
  AppSettingsCubit({
    required PreferencesStorageService preferencesStorageService,
  })  : _preferencesStorageService = preferencesStorageService,
        super(_loadInitialState(preferencesStorageService));

  final PreferencesStorageService _preferencesStorageService;

  static AppSettingsState _loadInitialState(
    PreferencesStorageService storage,
  ) {
    final themeStr = storage.getThemeMode();
    final localeStr = storage.getLocale();

    return AppSettingsState(
      locale: _parseLocale(localeStr),
      themeMode: _parseThemeMode(themeStr),
    );
  }

  static ThemeMode _parseThemeMode(String rawMode) {
    switch (rawMode.toLowerCase().trim()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static Locale _parseLocale(String rawLocale) {
    switch (rawLocale.toLowerCase().trim()) {
      case 'en':
        return const Locale('en');
      case 'ar':
      default:
        return const Locale(AppConstants.defaultLocale);
    }
  }

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  Future<void> setLocale(Locale locale) async {
    final code = locale.languageCode.toLowerCase();
    if (code != 'ar' && code != 'en') {
      return;
    }
    emit(state.copyWith(locale: Locale(code)));
    await _preferencesStorageService.setLocale(code);
  }

  Future<void> toggleLocale() async {
    final nextCode = state.locale.languageCode == 'ar' ? 'en' : 'ar';
    await setLocale(Locale(nextCode));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(state.copyWith(themeMode: mode));
    await _preferencesStorageService.setThemeMode(_themeModeToString(mode));
  }

  Future<void> toggleTheme() async {
    final nextMode =
        state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(nextMode);
  }
}
