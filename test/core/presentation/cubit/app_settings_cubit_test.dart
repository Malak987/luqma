import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/presentation/cubit/app_settings_cubit.dart';
import 'package:luqma_app/core/storage/preferences_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late PreferencesStorageService storageService;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    storageService = PreferencesStorageService(prefs);
  });

  group('AppSettingsCubit - Theme Initialization & Persistence', () {
    test('1. Default theme is System when no value is stored', () {
      final cubit = AppSettingsCubit(
        preferencesStorageService: storageService,
      );

      expect(cubit.state.themeMode, equals(ThemeMode.system));
      cubit.close();
    });

    test('2. Saved Light theme is restored', () async {
      await prefs.setString(PreferencesStorageService.themeModeKey, 'light');

      final cubit = AppSettingsCubit(
        preferencesStorageService: storageService,
      );

      expect(cubit.state.themeMode, equals(ThemeMode.light));
      cubit.close();
    });

    test('3. Saved Dark theme is restored', () async {
      await prefs.setString(PreferencesStorageService.themeModeKey, 'dark');

      final cubit = AppSettingsCubit(
        preferencesStorageService: storageService,
      );

      expect(cubit.state.themeMode, equals(ThemeMode.dark));
      cubit.close();
    });

    test('4. Invalid stored theme safely falls back to System', () async {
      await prefs.setString(
        PreferencesStorageService.themeModeKey,
        'invalid_theme_value',
      );

      final cubit = AppSettingsCubit(
        preferencesStorageService: storageService,
      );

      expect(cubit.state.themeMode, equals(ThemeMode.system));
      cubit.close();
    });

    test('5. Changing theme persists the new value', () async {
      final cubit = AppSettingsCubit(
        preferencesStorageService: storageService,
      );

      await cubit.setThemeMode(ThemeMode.light);
      expect(cubit.state.themeMode, equals(ThemeMode.light));
      expect(
        prefs.getString(PreferencesStorageService.themeModeKey),
        equals('light'),
      );

      await cubit.setThemeMode(ThemeMode.dark);
      expect(cubit.state.themeMode, equals(ThemeMode.dark));
      expect(
        prefs.getString(PreferencesStorageService.themeModeKey),
        equals('dark'),
      );

      await cubit.toggleTheme();
      expect(cubit.state.themeMode, equals(ThemeMode.light));
      expect(
        prefs.getString(PreferencesStorageService.themeModeKey),
        equals('light'),
      );

      await cubit.setThemeMode(ThemeMode.system);
      expect(cubit.state.themeMode, equals(ThemeMode.system));
      expect(
        prefs.getString(PreferencesStorageService.themeModeKey),
        equals('system'),
      );

      cubit.close();
    });
  });

  group('AppSettingsCubit - Localization Initialization & Persistence', () {
    test('6. Arabic locale restoration (default for first install)', () async {
      final cubit = AppSettingsCubit(
        preferencesStorageService: storageService,
      );

      expect(cubit.state.locale, equals(const Locale('ar')));
      cubit.close();
    });

    test('7. English locale restoration', () async {
      await prefs.setString(PreferencesStorageService.localeKey, 'en');

      final cubit = AppSettingsCubit(
        preferencesStorageService: storageService,
      );

      expect(cubit.state.locale, equals(const Locale('en')));
      cubit.close();
    });

    test('Invalid stored locale safely falls back to Arabic', () async {
      await prefs.setString(
        PreferencesStorageService.localeKey,
        'unsupported_lang_code',
      );

      final cubit = AppSettingsCubit(
        preferencesStorageService: storageService,
      );

      expect(cubit.state.locale, equals(const Locale('ar')));
      cubit.close();
    });

    test('8. Changing locale persists the new value', () async {
      final cubit = AppSettingsCubit(
        preferencesStorageService: storageService,
      );

      await cubit.setLocale(const Locale('en'));
      expect(cubit.state.locale, equals(const Locale('en')));
      expect(
        prefs.getString(PreferencesStorageService.localeKey),
        equals('en'),
      );

      await cubit.toggleLocale();
      expect(cubit.state.locale, equals(const Locale('ar')));
      expect(
        prefs.getString(PreferencesStorageService.localeKey),
        equals('ar'),
      );

      await cubit.setLocale(const Locale('fr'));
      expect(cubit.state.locale, equals(const Locale('ar')));
      expect(
        prefs.getString(PreferencesStorageService.localeKey),
        equals('ar'),
      );

      cubit.close();
    });
  });
}
