import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/storage/preferences_storage_service.dart';
import 'package:luqma_app/core/theme/app_colors.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/splash/presentation/pages/splash_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<PreferencesStorageService> createStorage({
    Map<String, Object> initialPrefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(initialPrefs);
    final prefs = await SharedPreferences.getInstance();
    return PreferencesStorageService(prefs);
  }

  Widget createWidgetUnderTest({
    required VoidCallback onSplashCompleted,
    ThemeData? theme,
    Duration minDuration = const Duration(milliseconds: 100),
    Duration maxDuration = const Duration(milliseconds: 300),
  }) {
    return MaterialApp(
      theme: theme ?? AppTheme.light,
      darkTheme: AppTheme.dark,
      home: SplashPage(
        onSplashCompleted: onSplashCompleted,
        minDuration: minDuration,
        maxDuration: maxDuration,
      ),
    );
  }

  testWidgets('SplashPage renders splash screen and logo container',
      (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);

    await tester.pumpWidget(
      createWidgetUnderTest(onSplashCompleted: () {}),
    );
    await tester.pump();

    expect(find.byKey(const Key('splash_screen')), findsOneWidget);
    expect(find.byKey(const Key('splash_logo_container')), findsOneWidget);
  });

  testWidgets('SplashPage triggers onSplashCompleted callback', (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);

    var completed = false;
    await tester.pumpWidget(
      createWidgetUnderTest(
        onSplashCompleted: () => completed = true,
        minDuration: const Duration(milliseconds: 50),
        maxDuration: const Duration(milliseconds: 100),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(completed, isTrue);
  });

  testWidgets(
      'SplashPage renders static fallback image when Reduce Motion is enabled',
      (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);

    await tester.pumpWidget(
      createWidgetUnderTest(onSplashCompleted: () {}),
    );
    await tester.pump();

    expect(find.byKey(const Key('splash_static_logo')), findsOneWidget);
  });

  testWidgets('SplashPage does NOT modify onboarding preferences',
      (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);

    final storage = await createStorage(initialPrefs: {
      PreferencesStorageService.hasCompletedOnboardingKey: false,
      PreferencesStorageService.onboardingLastIndexKey: 0,
    });

    var completed = false;
    await tester.pumpWidget(
      createWidgetUnderTest(
        onSplashCompleted: () => completed = true,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(completed, isTrue);
    expect(storage.getHasCompletedOnboarding(), false);
    expect(storage.getOnboardingLastIndex(), 0);
  });

  testWidgets('SplashPage applies Light theme brand background #F6F1E7',
      (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);

    await tester.pumpWidget(
      createWidgetUnderTest(
        onSplashCompleted: () {},
        theme: AppTheme.light,
      ),
    );
    await tester.pump();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(
      scaffold.backgroundColor,
      equals(AppSemanticColors.light.background),
    );
    expect(
      scaffold.backgroundColor,
      equals(const Color(0xFFF6F1E7)),
    );
  });

  testWidgets('SplashPage applies Dark theme brand background #171717',
      (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);

    await tester.pumpWidget(
      createWidgetUnderTest(
        onSplashCompleted: () {},
        theme: AppTheme.dark,
      ),
    );
    await tester.pump();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(
      scaffold.backgroundColor,
      equals(AppSemanticColors.dark.background),
    );
    expect(
      scaffold.backgroundColor,
      equals(const Color(0xFF171717)),
    );
  });
}
