import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight, typed wrapper for non-sensitive local user preferences.
///
/// Authentication credentials and security tokens must remain strictly inside
/// [SecureStorageService], keeping UI flags and display preferences isolated.
class PreferencesStorageService {
  const PreferencesStorageService(this._preferences);

  final SharedPreferences _preferences;

  static const String themeModeKey = 'app_theme_mode';
  static const String localeKey = 'app_locale';
  static const String hasCompletedOnboardingKey = 'has_completed_onboarding';
  static const String onboardingLastIndexKey = 'onboarding_last_index';
  static const String locationPermissionAutomaticAttemptCountKey =
      'location_permission_automatic_attempt_count';

  static const int maxLocationPermissionAutomaticAttempts = 2;

  static const String defaultThemeMode = 'system';
  static const String defaultLocale = 'ar';
  static const bool defaultHasCompletedOnboarding = false;
  static const int defaultOnboardingLastIndex = 0;

  /// Retrieves the persisted theme preference ('system', 'light', or 'dark').
  ///
  /// Defaults to [defaultThemeMode] ('system') when not explicitly set.
  String getThemeMode() {
    return _preferences.getString(themeModeKey) ?? defaultThemeMode;
  }

  /// Persists the selected theme preference.
  Future<bool> setThemeMode(String themeMode) {
    return _preferences.setString(themeModeKey, themeMode);
  }

  /// Retrieves the persisted language code ('ar' or 'en').
  ///
  /// Defaults to [defaultLocale] ('ar') when not explicitly set.
  String getLocale() {
    return _preferences.getString(localeKey) ?? defaultLocale;
  }

  /// Persists the selected language code.
  Future<bool> setLocale(String languageCode) {
    return _preferences.setString(localeKey, languageCode);
  }

  /// Checks whether the user has completed or dismissed the onboarding flow.
  ///
  /// Defaults to [defaultHasCompletedOnboarding] (`false`).
  bool getHasCompletedOnboarding() {
    return _preferences.getBool(hasCompletedOnboardingKey) ??
        defaultHasCompletedOnboarding;
  }

  /// Marks onboarding as completed or resets it.
  Future<bool> setHasCompletedOnboarding(bool completed) {
    return _preferences.setBool(hasCompletedOnboardingKey, completed);
  }

  /// Retrieves the last visited onboarding slide index.
  ///
  /// Defaults to [defaultOnboardingLastIndex] (`0`) and sanitizes negative values.
  int getOnboardingLastIndex() {
    final value = _preferences.getInt(onboardingLastIndexKey);
    if (value == null || value < 0) {
      return defaultOnboardingLastIndex;
    }
    return value;
  }

  /// Persists the last visited onboarding slide index, guarding against negative values.
  Future<bool> setOnboardingLastIndex(int index) {
    final sanitizedIndex = index < 0 ? defaultOnboardingLastIndex : index;
    return _preferences.setInt(onboardingLastIndexKey, sanitizedIndex);
  }

  /// Resets the saved onboarding slide progress back to [defaultOnboardingLastIndex].
  Future<bool> resetOnboardingProgress() {
    return _preferences.setInt(
      onboardingLastIndexKey,
      defaultOnboardingLastIndex,
    );
  }

  /// Retrieves the number of automatic location-permission request calls made.
  ///
  /// Invalid negative values are sanitized to zero and values above the
  /// supported maximum are clamped, so corrupted preferences cannot permit
  /// more automatic attempts than intended.
  int getLocationPermissionAutomaticAttemptCount() {
    final int? value;
    try {
      value = _preferences.getInt(
        locationPermissionAutomaticAttemptCountKey,
      );
    } catch (_) {
      // Fail closed if the stored value cannot be read, avoiding extra prompts.
      return maxLocationPermissionAutomaticAttempts;
    }
    if (value == null || value < 0) {
      return 0;
    }
    if (value > maxLocationPermissionAutomaticAttempts) {
      return maxLocationPermissionAutomaticAttempts;
    }
    return value;
  }

  /// Records one automatic request call, returning false at the two-call cap
  /// or when SharedPreferences could not save the new count.
  Future<bool> recordLocationPermissionAutomaticAttempt() async {
    final currentCount = getLocationPermissionAutomaticAttemptCount();
    if (currentCount >= maxLocationPermissionAutomaticAttempts) {
      return false;
    }
    return _preferences.setInt(
      locationPermissionAutomaticAttemptCountKey,
      currentCount + 1,
    );
  }

  /// Removes user-configurable preference keys.
  ///
  /// The automatic location-permission attempt counter is intentionally
  /// preserved: clearing display preferences must not reset the privacy/safety
  /// cap on automatic system permission requests.
  Future<bool> clearAllPreferences() async {
    final results = await Future.wait<bool>(<Future<bool>>[
      _preferences.remove(themeModeKey),
      _preferences.remove(localeKey),
      _preferences.remove(hasCompletedOnboardingKey),
      _preferences.remove(onboardingLastIndexKey),
    ]);
    return results.every((success) => success);
  }
}
