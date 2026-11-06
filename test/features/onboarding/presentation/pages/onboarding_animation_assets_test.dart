import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/constants/app_assets.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/storage/preferences_storage_service.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:luqma_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guards the per-slide onboarding illustrations that replaced the "لقمة"
/// wordmark.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<OnboardingCubit> createCubit() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return OnboardingCubit(
      preferencesStorageService: PreferencesStorageService(prefs),
    );
  }

  Widget createWidgetUnderTest(OnboardingCubit cubit) {
    return MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: BlocProvider<OnboardingCubit>.value(
        value: cubit,
        child: const OnboardingPage(),
      ),
    );
  }

  test('each slide maps to its own cropped illustration asset', () {
    expect(AppAssets.onboardingAnimations, hasLength(3));
    // Slide 1 intentionally keeps the approved burger illustration.
    expect(
      AppAssets.onboardingAnimations[0],
      'assets/animations/burger_premium_lottie_content.json',
    );
    expect(
      AppAssets.onboardingAnimations[1],
      'assets/animations/02_easy_ordering_content.json',
    );
    expect(
      AppAssets.onboardingAnimations[2],
      'assets/animations/03_premium_taste_content.json',
    );
  });

  testWidgets('onboarding renders an illustration container per slide',
      (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);

    final cubit = await createCubit();
    await tester.pumpWidget(createWidgetUnderTest(cubit));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('onboarding_lottie_animation_0')),
      findsOneWidget,
    );
    // Reveal the second slide and confirm its own illustration container.
    await tester.tap(find.byKey(const Key('onboarding_next_button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('onboarding_lottie_animation_1')),
      findsOneWidget,
    );

    await cubit.close();
  });
}
