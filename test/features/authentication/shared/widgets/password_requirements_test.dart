import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/authentication/shared/widgets/password_requirements.dart';

void main() {
  Future<TextEditingController> pump(WidgetTester tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(body: PasswordRequirements(controller: controller)),
      ),
    );
    return controller;
  }

  int checked() => find.byIcon(Icons.check_circle_rounded).evaluate().length;

  testWidgets('ticks each rule as the password satisfies it', (tester) async {
    final controller = await pump(tester);

    expect(find.text('At least 6 characters'), findsOneWidget);
    expect(checked(), 0);

    controller.text = 'abcdef';
    await tester.pumpAndSettle();
    expect(checked(), 2); // length + lowercase

    controller.text = 'Abcdef1';
    await tester.pumpAndSettle();
    expect(checked(), 4); // + uppercase + number

    controller.text = 'Abcdef1!';
    await tester.pumpAndSettle();
    expect(checked(), 5);

    controller.clear();
    await tester.pumpAndSettle();
    expect(checked(), 0);
  });
}
