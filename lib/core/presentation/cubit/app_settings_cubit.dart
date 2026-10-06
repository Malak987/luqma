import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_settings_state.dart';

class AppSettingsCubit extends Cubit<AppSettingsState> {
  AppSettingsCubit() : super(const AppSettingsState.initial());

  void setLocale(Locale locale) {
    if (locale.languageCode != 'ar' && locale.languageCode != 'en') {
      return;
    }
    emit(state.copyWith(locale: Locale(locale.languageCode)));
  }

  void toggleLocale() {
    setLocale(
      state.locale.languageCode == 'ar'
          ? const Locale('en')
          : const Locale('ar'),
    );
  }

  void setThemeMode(ThemeMode mode) {
    emit(state.copyWith(themeMode: mode));
  }

  void toggleTheme() {
    setThemeMode(
      state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }
}
