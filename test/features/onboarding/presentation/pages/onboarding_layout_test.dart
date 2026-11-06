import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/localization/translations/onboarding_translations.dart';
import 'package:luqma_app/core/storage/preferences_storage_service.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:luqma_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guards the redesigned onboarding hierarchy:
/// illustration → title → subtitle → indicator dots → Next button.
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

  Future<void> setSurface(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('slide keeps illustration, title, subtitle, dots, button order',
      (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await setSurface(tester, const Size(390, 844));

    final cubit = await createCubit();
    await tester.pumpWidget(createWidgetUnderTest(cubit));
    await tester.pumpAndSettle();

    final copy = OnboardingTranslations(const Locale('ar'));
    final illustrationKey = const Key('onboarding_lottie_animation_0');
    final indicatorKey = const Key('onboarding_indicator');
    final buttonKey = const Key('onboarding_next_button');
    final illustration = tester.getTopLeft(find.byKey(illustrationKey));
    final title = tester.getTopLeft(find.text(copy.slide1Title));
    final subtitle = tester.getTopLeft(find.text(copy.slide1Subtitle));
    final indicator = tester.getTopLeft(find.byKey(indicatorKey));
    final button = tester.getTopLeft(find.byKey(buttonKey));

    expect(illustration.dy, lessThan(title.dy));
    expect(title.dy, lessThan(subtitle.dy));
    expect(subtitle.dy, lessThan(indicator.dy));
    expect(indicator.dy, lessThan(button.dy));

    // Illustration is now the dominant element of the slide.
    final slideHeight = tester
        .getSize(find.byKey(const Key('onboarding_slide_0')))
        .height;
    final illustrationHeight =
        tester.getSize(find.byKey(illustrationKey)).height;
    expect(illustrationHeight / slideHeight, greaterThan(0.45));

    // Next button is fully on screen.
    expect(button.dy + 52.0, lessThanOrEqualTo(844.0));

    await cubit.close();
  });

  testWidgets('short phone screen lays out without overflow', (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await setSurface(tester, const Size(320, 568));

    final cubit = await createCubit();
    await tester.pumpWidget(createWidgetUnderTest(cubit));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    final button =
        tester.getRect(find.byKey(const Key('onboarding_next_button')));
    expect(button.bottom, lessThanOrEqualTo(568.0));
    final illustration = tester
        .getRect(find.byKey(const Key('onboarding_lottie_animation_0')));
    expect(illustration.height, greaterThan(0.0));

    await cubit.close();
  });

  testWidgets('tall phone keeps the same hierarchy on all three slides',
      (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await setSurface(tester, const Size(430, 932));

    final cubit = await createCubit();
    await tester.pumpWidget(createWidgetUnderTest(cubit));
    await tester.pumpAndSettle();

    for (var index = 0; index < 3; index++) {
      expect(
        find.byKey(Key('onboarding_lottie_animation_$index')),
        findsOneWidget,
      );
      final indicatorRect =
          tester.getRect(find.byKey(const Key('onboarding_indicator')));
      final buttonRect =
          tester.getRect(find.byKey(const Key('onboarding_next_button')));
      expect(indicatorRect.bottom, lessThan(buttonRect.top));
      expect(tester.takeException(), isNull);

      if (index < 2) {
        await tester.tap(find.byKey(const Key('onboarding_next_button')));
        await tester.pumpAndSettle();
      }
    }

    await cubit.close();
  });
}
