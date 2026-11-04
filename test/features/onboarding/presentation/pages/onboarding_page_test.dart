import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/storage/preferences_storage_service.dart';
import 'package:luqma_app/core/theme/app_colors.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:luqma_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PreferencesStorageService storage;

  Future<OnboardingCubit> createCubit({
    Map<String, Object> initialPrefs = const {},
    bool isReviewMode = false,
  }) async {
    SharedPreferences.setMockInitialValues(initialPrefs);
    final prefs = await SharedPreferences.getInstance();
    storage = PreferencesStorageService(prefs);
    return OnboardingCubit(
      preferencesStorageService: storage,
      isReviewMode: isReviewMode,
    );
  }

  Widget createWidgetUnderTest(
    OnboardingCubit cubit, {
    bool isReviewMode = false,
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme ?? AppTheme.light,
      darkTheme: AppTheme.dark,
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: BlocProvider<OnboardingCubit>.value(
        value: cubit,
        child: OnboardingPage(isReviewMode: isReviewMode),
      ),
    );
  }

  testWidgets('OnboardingPage renders initial slide and control buttons',
      (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);

    final cubit = await createCubit();
    await tester.pumpWidget(createWidgetUnderTest(cubit));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('onboarding_skip_button')), findsOneWidget);
    expect(find.byKey(const Key('onboarding_page_view')), findsOneWidget);
    expect(find.byKey(const Key('onboarding_slide_0')), findsOneWidget);
    expect(find.byKey(const Key('onboarding_indicator')), findsOneWidget);
    expect(find.byKey(const Key('onboarding_next_button')), findsOneWidget);

    await cubit.close();
  });

  testWidgets(
      'Tapping Next button advances slide until Get Started on final slide',
      (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);

    final cubit = await createCubit();
    await tester.pumpWidget(createWidgetUnderTest(cubit));
    await tester.pumpAndSettle();

    expect(cubit.state.currentIndex, 0);

    // Tap Next to slide 1
    await tester.tap(find.byKey(const Key('onboarding_next_button')));
    await tester.pumpAndSettle();
    expect(cubit.state.currentIndex, 1);

    // Tap Next to slide 2 (last slide)
    await tester.tap(find.byKey(const Key('onboarding_next_button')));
    await tester.pumpAndSettle();
    expect(cubit.state.currentIndex, 2);
    expect(cubit.state.isLastSlide, true);

    // Button should now trigger completion
    await tester.tap(find.byKey(const Key('onboarding_next_button')));
    await tester.pumpAndSettle();
    expect(cubit.state.isCompleted, true);

    await cubit.close();
  });

  testWidgets('Tapping Skip button completes onboarding flow', (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);

    final cubit = await createCubit();
    await tester.pumpWidget(createWidgetUnderTest(cubit));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('onboarding_skip_button')));
    await tester.pumpAndSettle();

    expect(cubit.state.isCompleted, true);
    expect(storage.getHasCompletedOnboarding(), true);

    await cubit.close();
  });

  testWidgets(
      'Review mode renders back button and pops on exit without saving prefs',
      (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);

    final cubit = await createCubit(isReviewMode: true);
    await tester.pumpWidget(createWidgetUnderTest(cubit, isReviewMode: true));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('onboarding_back_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding_skip_button')));
    await tester.pumpAndSettle();

    expect(cubit.state.isCompleted, true);
    expect(storage.getHasCompletedOnboarding(), false);

    await cubit.close();
  });

  testWidgets(
      'OnboardingPage renders static fallback image when Reduce Motion is enabled',
      (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);

    final cubit = await createCubit();
    await tester.pumpWidget(createWidgetUnderTest(cubit));
    await tester.pumpAndSettle();

    // Verify static fallback Image.asset is present when disableAnimations is true
    expect(find.byType(Image), findsWidgets);

    await cubit.close();
  });

  testWidgets('OnboardingPage applies Light theme AppSemanticColors',
      (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);

    final cubit = await createCubit();
    await tester
        .pumpWidget(createWidgetUnderTest(cubit, theme: AppTheme.light));
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(
        scaffold.backgroundColor, equals(AppSemanticColors.light.background));

    await cubit.close();
  });

  testWidgets('OnboardingPage applies Dark theme AppSemanticColors',
      (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);

    final cubit = await createCubit();
    await tester.pumpWidget(createWidgetUnderTest(cubit, theme: AppTheme.dark));
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, equals(AppSemanticColors.dark.background));

    await cubit.close();
  });
}
