import 'dart:async';

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
    Future<void> Function(BuildContext context)? readinessTask,
    ThemeData? theme,
    Duration safetyTimeout = const Duration(seconds: 10),
  }) {
    return MaterialApp(
      theme: theme ?? AppTheme.light,
      darkTheme: AppTheme.dark,
      home: SplashPage(
        onSplashCompleted: onSplashCompleted,
        readinessTask: readinessTask ?? (_) async {},
        safetyTimeout: safetyTimeout,
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

  testWidgets(
      'Scenario 1: App Ready before animation finishes waits for animation completion',
      (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);

    var completed = false;
    await tester.pumpWidget(
      createWidgetUnderTest(
        onSplashCompleted: () => completed = true,
        readinessTask: (_) async {}, // Instant readiness
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(completed, isTrue);
  });

  testWidgets(
      'Scenario 2: Animation finishes before app is ready waits for readiness completion',
      (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);

    final readinessCompleter = Completer<void>();
    var completed = false;

    await tester.pumpWidget(
      createWidgetUnderTest(
        onSplashCompleted: () => completed = true,
        readinessTask: (_) => readinessCompleter.future,
      ),
    );
    await tester.pump();

    // Animation completed (Reduce Motion), but readiness task is still pending -> no transition
    expect(completed, isFalse);

    // Complete background app readiness
    readinessCompleter.complete();
    await tester.pump();

    // Now both conditions are satisfied -> transitioned
    expect(completed, isTrue);
  });

  testWidgets(
      'Critical initialization fails: never marks ready or navigates, shows Retry',
      (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);

    var transitionCalls = 0;
    await tester.pumpWidget(
      createWidgetUnderTest(
        onSplashCompleted: () => transitionCalls++,
        readinessTask: (_) async {
          throw Exception('Simulated critical failure');
        },
      ),
    );
    await tester.pumpAndSettle();

    // Must NOT navigate to an unready destination
    expect(transitionCalls, equals(0));
    // Must display the Retry action button
    expect(find.byKey(const Key('splash_retry_button')), findsOneWidget);
  });

  testWidgets(
      'Safety timeout: flags error without forcing readiness or premature navigation',
      (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);

    final hangingCompleter = Completer<void>();
    var transitionCalls = 0;

    await tester.pumpWidget(
      createWidgetUnderTest(
        onSplashCompleted: () => transitionCalls++,
        readinessTask: (_) => hangingCompleter.future,
        safetyTimeout: const Duration(milliseconds: 100),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    // Timeout must NOT force navigation to unready destination
    expect(transitionCalls, equals(0));
    // Must render error UI and Retry button
    expect(find.byKey(const Key('splash_retry_button')), findsOneWidget);
  });

  testWidgets(
      'Retry action re-executes critical initialization and transitions on success',
      (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);

    var attemptCount = 0;
    var transitionCalls = 0;

    await tester.pumpWidget(
      createWidgetUnderTest(
        onSplashCompleted: () => transitionCalls++,
        readinessTask: (_) async {
          attemptCount++;
          if (attemptCount == 1) {
            throw Exception('Attempt 1 failed');
          }
          // Attempt 2 succeeds
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(attemptCount, equals(1));
    expect(transitionCalls, equals(0));
    expect(find.byKey(const Key('splash_retry_button')), findsOneWidget);

    // Tap Retry
    await tester.tap(find.byKey(const Key('splash_retry_button')));
    await tester.pumpAndSettle();

    expect(attemptCount, equals(2));
    expect(transitionCalls, equals(1));
  });

  testWidgets(
      'Stale request protection: late completion of old request is ignored if new attempt started',
      (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);

    final attempt1Completer = Completer<void>();
    var attemptCount = 0;
    var transitionCalls = 0;

    await tester.pumpWidget(
      createWidgetUnderTest(
        onSplashCompleted: () => transitionCalls++,
        readinessTask: (_) {
          attemptCount++;
          if (attemptCount == 1) {
            return attempt1Completer.future;
          }
          return Future<void>.value(); // Attempt 2 succeeds immediately
        },
        safetyTimeout: const Duration(milliseconds: 50),
      ),
    );
    await tester.pump();

    // Trigger safety timeout for attempt 1
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('splash_retry_button')), findsOneWidget);

    // Tap Retry (starts Attempt 2, requestId = 2)
    await tester.tap(find.byKey(const Key('splash_retry_button')));
    await tester.pumpAndSettle();

    // Attempt 2 completes and transitions
    expect(transitionCalls, equals(1));

    // Now complete stale Attempt 1 — should be safely ignored
    attempt1Completer.complete();
    await tester.pumpAndSettle();

    // Transition count remains 1, no duplicate transitions or errors
    expect(transitionCalls, equals(1));
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
    await tester.pump(const Duration(milliseconds: 100));

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
