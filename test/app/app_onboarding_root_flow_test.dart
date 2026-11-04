import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/app/app.dart';
import 'package:luqma_app/core/di/service_locator.dart';
import 'package:luqma_app/core/presentation/cubit/app_settings_cubit.dart';
import 'package:luqma_app/core/storage/preferences_storage_service.dart';
import 'package:luqma_app/features/authentication/login/presentation/pages/login_page.dart';
import 'package:luqma_app/features/authentication/presentation/cubit/auth_session_cubit.dart';
import 'package:luqma_app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:luqma_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:luqma_app/features/splash/presentation/pages/splash_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> setupDependencies({
    bool hasCompletedOnboarding = false,
  }) async {
    await sl.reset();
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues(<String, Object>{
      PreferencesStorageService.hasCompletedOnboardingKey:
          hasCompletedOnboarding,
    });
    final prefs = await SharedPreferences.getInstance();
    await configureDependencies(preferences: prefs);
  }

  tearDown(() async {
    await sl.reset();
  });

  testWidgets(
      'LuqmaApp displays SplashPage on cold launch, then proceeds to OnboardingPage when onboarding is incomplete',
      (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await setupDependencies(hasCompletedOnboarding: false);

    final settingsCubit = sl<AppSettingsCubit>();
    final authSessionCubit = sl<AuthSessionCubit>();
    final onboardingCubit = sl<OnboardingCubit>();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<AppSettingsCubit>.value(value: settingsCubit),
          BlocProvider<AuthSessionCubit>.value(value: authSessionCubit),
          BlocProvider<OnboardingCubit>.value(value: onboardingCubit),
        ],
        child: const LuqmaApp(),
      ),
    );

    // Initial frame shows SplashPage
    expect(find.byType(SplashPage), findsOneWidget);

    // Pump past Splash animation/timer
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    // Splash completes, Onboarding is visible, LoginPage is gated
    expect(find.byType(SplashPage), findsNothing);
    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
  });

  testWidgets(
      'LuqmaApp proceeds from Splash to LoginPage after onboarding is skipped or completed',
      (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await setupDependencies(hasCompletedOnboarding: false);

    final settingsCubit = sl<AppSettingsCubit>();
    final authSessionCubit = sl<AuthSessionCubit>();
    final onboardingCubit = sl<OnboardingCubit>();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<AppSettingsCubit>.value(value: settingsCubit),
          BlocProvider<AuthSessionCubit>.value(value: authSessionCubit),
          BlocProvider<OnboardingCubit>.value(value: onboardingCubit),
        ],
        child: const LuqmaApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    expect(find.byType(OnboardingPage), findsOneWidget);

    // Skip onboarding
    await onboardingCubit.skipOnboarding();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Onboarding is completed, LoginPage is now displayed
    expect(find.byType(OnboardingPage), findsNothing);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets(
      'LuqmaApp displays SplashPage on launch, then bypasses Onboarding to LoginPage when hasCompletedOnboarding is true',
      (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await setupDependencies(hasCompletedOnboarding: true);

    final settingsCubit = sl<AppSettingsCubit>();
    final authSessionCubit = sl<AuthSessionCubit>();
    final onboardingCubit = sl<OnboardingCubit>();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<AppSettingsCubit>.value(value: settingsCubit),
          BlocProvider<AuthSessionCubit>.value(value: authSessionCubit),
          BlocProvider<OnboardingCubit>.value(value: onboardingCubit),
        ],
        child: const LuqmaApp(),
      ),
    );

    // Initial frame shows SplashPage
    expect(find.byType(SplashPage), findsOneWidget);

    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    // Onboarding is bypassed, proceeds directly to auth flow
    expect(find.byType(SplashPage), findsNothing);
    expect(find.byType(OnboardingPage), findsNothing);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets(
      'Rebuilding theme or locale does NOT replay SplashPage after completion',
      (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await setupDependencies(hasCompletedOnboarding: true);

    final settingsCubit = sl<AppSettingsCubit>();
    final authSessionCubit = sl<AuthSessionCubit>();
    final onboardingCubit = sl<OnboardingCubit>();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<AppSettingsCubit>.value(value: settingsCubit),
          BlocProvider<AuthSessionCubit>.value(value: authSessionCubit),
          BlocProvider<OnboardingCubit>.value(value: onboardingCubit),
        ],
        child: const LuqmaApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    expect(find.byType(LoginPage), findsOneWidget);

    // Change theme mode
    await settingsCubit.setThemeMode(ThemeMode.dark);
    await tester.pump();

    // Splash is NOT replayed
    expect(find.byType(SplashPage), findsNothing);
    expect(find.byType(LoginPage), findsOneWidget);
  });
}
