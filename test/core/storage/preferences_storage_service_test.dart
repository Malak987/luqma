import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/di/service_locator.dart';
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

  group('PreferencesStorageService - Theme Mode', () {
    test('returns default theme mode (system) when not set', () {
      expect(
        storageService.getThemeMode(),
        equals(PreferencesStorageService.defaultThemeMode),
      );
      expect(storageService.getThemeMode(), equals('system'));
    });

    test('persists and retrieves custom theme modes', () async {
      final lightResult = await storageService.setThemeMode('light');
      expect(lightResult, isTrue);
      expect(storageService.getThemeMode(), equals('light'));

      final darkResult = await storageService.setThemeMode('dark');
      expect(darkResult, isTrue);
      expect(storageService.getThemeMode(), equals('dark'));

      final systemResult = await storageService.setThemeMode('system');
      expect(systemResult, isTrue);
      expect(storageService.getThemeMode(), equals('system'));
    });
  });

  group('PreferencesStorageService - Locale', () {
    test('returns default locale (ar) when not set', () {
      expect(
        storageService.getLocale(),
        equals(PreferencesStorageService.defaultLocale),
      );
      expect(storageService.getLocale(), equals('ar'));
    });

    test('persists and retrieves custom locale', () async {
      final enResult = await storageService.setLocale('en');
      expect(enResult, isTrue);
      expect(storageService.getLocale(), equals('en'));

      final arResult = await storageService.setLocale('ar');
      expect(arResult, isTrue);
      expect(storageService.getLocale(), equals('ar'));
    });
  });

  group('PreferencesStorageService - Onboarding Completion', () {
    test('returns false by default for onboarding completion', () {
      expect(
        storageService.getHasCompletedOnboarding(),
        equals(PreferencesStorageService.defaultHasCompletedOnboarding),
      );
      expect(storageService.getHasCompletedOnboarding(), isFalse);
    });

    test('persists onboarding completion status', () async {
      final setResult = await storageService.setHasCompletedOnboarding(true);
      expect(setResult, isTrue);
      expect(storageService.getHasCompletedOnboarding(), isTrue);

      final resetResult = await storageService.setHasCompletedOnboarding(false);
      expect(resetResult, isTrue);
      expect(storageService.getHasCompletedOnboarding(), isFalse);
    });
  });

  group('PreferencesStorageService - Onboarding Slide Index', () {
    test('returns 0 by default for onboarding slide index', () {
      expect(
        storageService.getOnboardingLastIndex(),
        equals(PreferencesStorageService.defaultOnboardingLastIndex),
      );
      expect(storageService.getOnboardingLastIndex(), equals(0));
    });

    test('persists valid positive slide indices', () async {
      final result1 = await storageService.setOnboardingLastIndex(1);
      expect(result1, isTrue);
      expect(storageService.getOnboardingLastIndex(), equals(1));

      final result2 = await storageService.setOnboardingLastIndex(3);
      expect(result2, isTrue);
      expect(storageService.getOnboardingLastIndex(), equals(3));
    });

    test('sanitizes negative index inputs to 0 on write', () async {
      final result = await storageService.setOnboardingLastIndex(-5);
      expect(result, isTrue);
      expect(storageService.getOnboardingLastIndex(), equals(0));
    });

    test('sanitizes negative stored index values to 0 on read', () async {
      await prefs.setInt(PreferencesStorageService.onboardingLastIndexKey, -10);
      expect(storageService.getOnboardingLastIndex(), equals(0));
    });

    test('resets onboarding slide progress to 0', () async {
      await storageService.setOnboardingLastIndex(2);
      expect(storageService.getOnboardingLastIndex(), equals(2));

      final resetResult = await storageService.resetOnboardingProgress();
      expect(resetResult, isTrue);
      expect(storageService.getOnboardingLastIndex(), equals(0));
    });
  });

  group('PreferencesStorageService - Location Permission Attempts', () {
    test('defaults to zero and persists at most two automatic attempts', () async {
      expect(storageService.getLocationPermissionAutomaticAttemptCount(), 0);

      expect(
        await storageService.recordLocationPermissionAutomaticAttempt(),
        isTrue,
      );
      expect(storageService.getLocationPermissionAutomaticAttemptCount(), 1);

      expect(
        await storageService.recordLocationPermissionAutomaticAttempt(),
        isTrue,
      );
      expect(storageService.getLocationPermissionAutomaticAttemptCount(), 2);
      expect(
        await storageService.recordLocationPermissionAutomaticAttempt(),
        isFalse,
      );
      expect(
        prefs.getInt(
          PreferencesStorageService.locationPermissionAutomaticAttemptCountKey,
        ),
        2,
      );
    });

    test('sanitizes invalid stored counts without increasing the budget',
        () async {
      await prefs.setInt(
        PreferencesStorageService.locationPermissionAutomaticAttemptCountKey,
        -1,
      );
      expect(storageService.getLocationPermissionAutomaticAttemptCount(), 0);

      await prefs.setInt(
        PreferencesStorageService.locationPermissionAutomaticAttemptCountKey,
        99,
      );
      expect(storageService.getLocationPermissionAutomaticAttemptCount(), 2);
      expect(
        await storageService.recordLocationPermissionAutomaticAttempt(),
        isFalse,
      );

      await prefs.setString(
        PreferencesStorageService.locationPermissionAutomaticAttemptCountKey,
        'corrupt',
      );
      expect(storageService.getLocationPermissionAutomaticAttemptCount(), 2);
      expect(
        await storageService.recordLocationPermissionAutomaticAttempt(),
        isFalse,
      );
    });
  });

  group('PreferencesStorageService - Key Isolation and Clear', () {
    test('ensures preference keys are isolated and do not overwrite each other',
        () async {
      await storageService.setThemeMode('dark');
      await storageService.setLocale('en');
      await storageService.setHasCompletedOnboarding(true);
      await storageService.setOnboardingLastIndex(2);

      expect(storageService.getThemeMode(), equals('dark'));
      expect(storageService.getLocale(), equals('en'));
      expect(storageService.getHasCompletedOnboarding(), isTrue);
      expect(storageService.getOnboardingLastIndex(), equals(2));
    });

    test('clearAllPreferences clears user settings but preserves permission cap',
        () async {
      await storageService.setThemeMode('dark');
      await storageService.setLocale('en');
      await storageService.setHasCompletedOnboarding(true);
      await storageService.setOnboardingLastIndex(2);
      await storageService.recordLocationPermissionAutomaticAttempt();

      final clearResult = await storageService.clearAllPreferences();
      expect(clearResult, isTrue);

      expect(
        storageService.getThemeMode(),
        equals(PreferencesStorageService.defaultThemeMode),
      );
      expect(
        storageService.getLocale(),
        equals(PreferencesStorageService.defaultLocale),
      );
      expect(
        storageService.getHasCompletedOnboarding(),
        equals(PreferencesStorageService.defaultHasCompletedOnboarding),
      );
      expect(
        storageService.getOnboardingLastIndex(),
        equals(PreferencesStorageService.defaultOnboardingLastIndex),
      );
      expect(storageService.getLocationPermissionAutomaticAttemptCount(), 1);
    });
  });

  group('Service Locator Registration', () {
    tearDown(() async {
      await sl.reset();
    });

    test(
        'registers and resolves PreferencesStorageService from service locator',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final mockPrefs = await SharedPreferences.getInstance();

      await configureDependencies(preferences: mockPrefs);

      expect(sl.isRegistered<SharedPreferences>(), isTrue);
      expect(sl.isRegistered<PreferencesStorageService>(), isTrue);

      final resolvedService = sl<PreferencesStorageService>();
      expect(resolvedService, isA<PreferencesStorageService>());
      expect(resolvedService.getThemeMode(), equals('system'));
    });
  });
}
