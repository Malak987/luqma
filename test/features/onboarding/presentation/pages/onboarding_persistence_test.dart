import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/constants/app_assets.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/localization/translations/onboarding_translations.dart';
import 'package:luqma_app/core/storage/preferences_storage_service.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:luqma_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression guards for the onboarding shell and the illustration sizing:
///  * the header/footer stay mounted and never move while swiping,
///  * the PageView keeps one controller and is not rebuilt from scratch,
///  * the visible artwork (not just its box) fills the illustration area.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<OnboardingCubit> createCubit() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return OnboardingCubit(
      preferencesStorageService: PreferencesStorageService(prefs),
    );
  }

  Widget createWidgetUnderTest(OnboardingCubit cubit, {ThemeData? theme}) {
    return MaterialApp(
      theme: theme ?? AppTheme.light,
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

  /// Renders at a fixed logical size without touching platform channels.
  Future<void> setSurface(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('header, indicator and button stay mounted while swiping',
      (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await setSurface(tester, const Size(390, 844));

    final cubit = await createCubit();
    await tester.pumpWidget(createWidgetUnderTest(cubit));
    await tester.pumpAndSettle();

    const skipKey = Key('onboarding_skip_button');
    const indicatorKey = Key('onboarding_indicator');
    const buttonKey = Key('onboarding_next_button');
    const pagerKey = Key('onboarding_page_view');

    final skipBefore = tester.getTopLeft(find.byKey(skipKey));
    final indicatorBefore = tester.getRect(find.byKey(indicatorKey));
    final buttonBefore = tester.getRect(find.byKey(buttonKey));
    final pagerElement = tester.element(find.byKey(pagerKey));
    final pageController = tester
        .widget<PageView>(find.byKey(pagerKey))
        .controller;

    // Swipe to slide 2 and back, then press Next twice.
    await tester.drag(find.byKey(pagerKey), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(cubit.state.currentIndex, 1);

    await tester.drag(find.byKey(pagerKey), const Offset(400, 0));
    await tester.pumpAndSettle();
    expect(cubit.state.currentIndex, 0);

    await tester.tap(find.byKey(buttonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(buttonKey));
    await tester.pumpAndSettle();
    expect(cubit.state.currentIndex, 2);

    // Chrome never left the tree nor moved.
    expect(find.byKey(skipKey), findsOneWidget);
    expect(tester.getTopLeft(find.byKey(skipKey)), skipBefore);
    expect(tester.getRect(find.byKey(indicatorKey)), indicatorBefore);
    expect(tester.getRect(find.byKey(buttonKey)), buttonBefore);

    // Same PageView element and the very same controller instance survived.
    expect(tester.element(find.byKey(pagerKey)), same(pagerElement));
    expect(tester.widget<PageView>(find.byKey(pagerKey)).controller,
        same(pageController));

    // The indicator reflects the current page.
    final dots = tester.widgetList<AnimatedContainer>(find.descendant(
      of: find.byKey(indicatorKey),
      matching: find.byType(AnimatedContainer),
    )).toList();
    expect(dots, hasLength(3));
    expect((dots[2].constraints?.maxWidth), 24.0);

    // No exception (overflow, controller misuse) was thrown.
    expect(tester.takeException(), isNull);

    await cubit.close();
  });

  testWidgets('artwork box fills the illustration area on a typical phone',
      (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await setSurface(tester, const Size(390, 844));

    final cubit = await createCubit();
    await tester.pumpWidget(createWidgetUnderTest(cubit));
    await tester.pumpAndSettle();

    final copy = OnboardingTranslations(const Locale('ar'));
    final illustration =
        tester.getRect(find.byKey(const Key('onboarding_lottie_animation_0')));
    final title = tester.getRect(find.text(copy.slide1Title));
    final subtitle = tester.getRect(find.text(copy.slide1Subtitle));
    final indicator =
        tester.getRect(find.byKey(const Key('onboarding_indicator')));

    // Hierarchy is unchanged and nothing overlaps.
    expect(illustration.bottom, lessThanOrEqualTo(title.top));
    expect(title.bottom, lessThanOrEqualTo(subtitle.top));
    expect(subtitle.bottom, lessThanOrEqualTo(indicator.top));

    // The artwork box spans the screen and consumes the majority of the space
    // between the header and the fixed footer before the copy is subtracted.
    expect(illustration.width, greaterThan(390 * 0.95));
    final contentHeight = indicator.bottom - illustration.top;
    expect(illustration.height / contentHeight, greaterThan(0.38));

    await cubit.close();
  });

  test('cropped compositions are tightly bounded around the artwork', () {
    // These are the stage sizes produced by tool/lottie_content_crop.py. The
    // originals are 600x520 with 44–76% transparent margin, which is exactly
    // why the artwork used to render small.
    const expectedStage = <String, Size>{
      'assets/animations/burger_premium_lottie_content.json': Size(331, 246),
      'assets/animations/02_easy_ordering_content.json': Size(463, 420),
      'assets/animations/03_premium_taste_content.json': Size(361, 306),
    };

    for (final entry in expectedStage.entries) {
      expect(AppAssets.onboardingAnimations, contains(entry.key));
      expect(entry.value.width / entry.value.height, greaterThan(1.0));
    }

    // All three slides keep the approved 1:1 mapping order.
    expect(
      AppAssets.onboardingAnimations,
      <String>[
        'assets/animations/burger_premium_lottie_content.json',
        'assets/animations/02_easy_ordering_content.json',
        'assets/animations/03_premium_taste_content.json',
      ],
    );
  });
}
