import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/features/onboarding/presentation/utils/onboarding_preloader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'OnboardingPreloader executes asset preloading safely without throwing',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(),
        ),
      ),
    );
    await tester.pump();
    final BuildContext context = tester.element(find.byType(SizedBox));

    await tester.runAsync(() async {
      await OnboardingPreloader.preloadOnboardingAssets(context);
    });

    expect(tester.takeException(), isNull);
  });
}
