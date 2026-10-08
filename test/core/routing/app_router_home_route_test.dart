import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/di/service_locator.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/routing/app_router.dart';
import 'package:luqma_app/core/routing/app_routes.dart';
import 'package:luqma_app/features/home/presentation/pages/home_page.dart';

/// Proves `/home` resolves to the real home screen instead of the temporary
/// coming-soon page, using the real composition root the app uses.
void main() {
  setUpAll(() async {
    await configureDependencies();
  });

  test('maps the route name to a material page', () {
    final route = AppRouter.onGenerateRoute(
      const RouteSettings(name: AppRoutes.home),
    );

    expect(route, isA<MaterialPageRoute<void>>());
    expect(route.settings.name, AppRoutes.home);
  });

  testWidgets('builds the real home page', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRoutes.login,
      ),
    );

    // Push the route under test exactly as the login screen does. Deliberately
    // not awaited: `pushNamed` completes only when the route is popped.
    final context = tester.element(find.byType(Navigator));
    AppRouter.pushNamed<void>(context, AppRoutes.home);

    // Pumped without `pumpAndSettle`: the real composition root backs the page
    // with the real secure storage, whose platform channel has no answer in a
    // unit test, so the screen legitimately stays on its loading indicator.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(HomePage), findsOneWidget);
  });
}
