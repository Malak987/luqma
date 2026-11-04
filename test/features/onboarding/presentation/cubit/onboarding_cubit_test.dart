import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/storage/preferences_storage_service.dart';
import 'package:luqma_app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PreferencesStorageService storage;

  Future<OnboardingCubit> createCubit({
    Map<String, Object> initialPrefs = const {},
    bool isReviewMode = false,
    int slideCount = 3,
  }) async {
    SharedPreferences.setMockInitialValues(initialPrefs);
    final prefs = await SharedPreferences.getInstance();
    storage = PreferencesStorageService(prefs);
    return OnboardingCubit(
      preferencesStorageService: storage,
      isReviewMode: isReviewMode,
      slideCount: slideCount,
    );
  }

  group('OnboardingCubit - Initialization', () {
    test('initializes with index 0 and incomplete state when no prefs set',
        () async {
      final cubit = await createCubit();

      expect(cubit.state.currentIndex, 0);
      expect(cubit.state.slideCount, 3);
      expect(cubit.state.isCompleted, false);
      expect(cubit.state.isReviewMode, false);

      await cubit.close();
    });

    test('initializes as completed if has_completed_onboarding is true',
        () async {
      final cubit = await createCubit(
        initialPrefs: {
          PreferencesStorageService.hasCompletedOnboardingKey: true,
        },
      );

      expect(cubit.state.isCompleted, true);

      await cubit.close();
    });

    test('restores saved onboarding slide index on init', () async {
      final cubit = await createCubit(
        initialPrefs: {
          PreferencesStorageService.onboardingLastIndexKey: 1,
        },
      );

      expect(cubit.state.currentIndex, 1);
      expect(cubit.state.isCompleted, false);

      await cubit.close();
    });

    test('sanitizes negative saved slide index to 0', () async {
      final cubit = await createCubit(
        initialPrefs: {
          PreferencesStorageService.onboardingLastIndexKey: -5,
        },
      );

      expect(cubit.state.currentIndex, 0);

      await cubit.close();
    });

    test('sanitizes out-of-bounds saved slide index to slideCount - 1',
        () async {
      final cubit = await createCubit(
        initialPrefs: {
          PreferencesStorageService.onboardingLastIndexKey: 99,
        },
      );

      expect(cubit.state.currentIndex, 2);

      await cubit.close();
    });

    test('initializes with review mode true without reading storage completion',
        () async {
      final cubit = await createCubit(
        initialPrefs: {
          PreferencesStorageService.hasCompletedOnboardingKey: true,
          PreferencesStorageService.onboardingLastIndexKey: 2,
        },
        isReviewMode: true,
      );

      expect(cubit.state.currentIndex, 0);
      expect(cubit.state.isCompleted, false);
      expect(cubit.state.isReviewMode, true);

      await cubit.close();
    });
  });

  group('OnboardingCubit - Navigation and Slide Control', () {
    test('nextSlide advances index and persists change', () async {
      final cubit = await createCubit();

      await cubit.nextSlide();

      expect(cubit.state.currentIndex, 1);
      expect(storage.getOnboardingLastIndex(), 1);

      await cubit.close();
    });

    test('nextSlide on final slide completes onboarding and resets saved index',
        () async {
      final cubit = await createCubit(
        initialPrefs: {
          PreferencesStorageService.onboardingLastIndexKey: 1,
        },
      );

      await cubit.nextSlide(); // advances to index 2
      expect(cubit.state.currentIndex, 2);
      expect(cubit.state.isLastSlide, true);

      await cubit.nextSlide(); // triggers completion
      expect(cubit.state.isCompleted, true);
      expect(storage.getHasCompletedOnboarding(), true);
      expect(storage.getOnboardingLastIndex(), 0);

      await cubit.close();
    });

    test('previousSlide decrements index and persists change', () async {
      final cubit = await createCubit(
        initialPrefs: {
          PreferencesStorageService.onboardingLastIndexKey: 2,
        },
      );

      await cubit.previousSlide();

      expect(cubit.state.currentIndex, 1);
      expect(storage.getOnboardingLastIndex(), 1);

      await cubit.close();
    });

    test('previousSlide does nothing when on first slide', () async {
      final cubit = await createCubit();

      await cubit.previousSlide();

      expect(cubit.state.currentIndex, 0);

      await cubit.close();
    });

    test('goToSlide navigates to valid index and persists change', () async {
      final cubit = await createCubit();

      await cubit.goToSlide(2);

      expect(cubit.state.currentIndex, 2);
      expect(storage.getOnboardingLastIndex(), 2);

      await cubit.close();
    });

    test('goToSlide clamps out-of-bounds target index safely', () async {
      final cubit = await createCubit();

      await cubit.goToSlide(10);
      expect(cubit.state.currentIndex, 2);

      await cubit.goToSlide(-3);
      expect(cubit.state.currentIndex, 0);

      await cubit.close();
    });
  });

  group('OnboardingCubit - Completion & Skip', () {
    test('skipOnboarding completes onboarding and resets saved index',
        () async {
      final cubit = await createCubit(
        initialPrefs: {
          PreferencesStorageService.onboardingLastIndexKey: 1,
        },
      );

      await cubit.skipOnboarding();

      expect(cubit.state.isCompleted, true);
      expect(storage.getHasCompletedOnboarding(), true);
      expect(storage.getOnboardingLastIndex(), 0);

      await cubit.close();
    });

    test('completeOnboarding completes onboarding and resets saved index',
        () async {
      final cubit = await createCubit();

      await cubit.completeOnboarding();

      expect(cubit.state.isCompleted, true);
      expect(storage.getHasCompletedOnboarding(), true);
      expect(storage.getOnboardingLastIndex(), 0);

      await cubit.close();
    });

    test('prepareGuestEntry completes onboarding and resets index', () async {
      final cubit = await createCubit();

      await cubit.prepareGuestEntry();

      expect(cubit.state.isCompleted, true);
      expect(storage.getHasCompletedOnboarding(), true);
      expect(storage.getOnboardingLastIndex(), 0);

      await cubit.close();
    });
  });

  group('OnboardingCubit - Review Mode Isolation', () {
    test('review mode does NOT modify persistent storage', () async {
      final cubit = await createCubit(
        initialPrefs: {
          PreferencesStorageService.hasCompletedOnboardingKey: false,
          PreferencesStorageService.onboardingLastIndexKey: 0,
        },
        isReviewMode: true,
      );

      await cubit.nextSlide();
      expect(cubit.state.currentIndex, 1);
      expect(storage.getOnboardingLastIndex(), 0);

      await cubit.goToSlide(2);
      expect(cubit.state.currentIndex, 2);
      expect(storage.getOnboardingLastIndex(), 0);

      await cubit.skipOnboarding();
      expect(cubit.state.isCompleted, true);
      expect(storage.getHasCompletedOnboarding(), false);
      expect(storage.getOnboardingLastIndex(), 0);

      await cubit.close();
    });
  });
}
