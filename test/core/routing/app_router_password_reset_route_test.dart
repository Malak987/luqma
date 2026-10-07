import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/di/service_locator.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/routing/app_router.dart';
import 'package:luqma_app/core/routing/app_routes.dart';
import 'package:luqma_app/features/authentication/login/presentation/pages/login_page.dart';
import 'package:luqma_app/features/authentication/password_reset/presentation/pages/forgot_password_page.dart';
import 'package:luqma_app/features/authentication/password_reset/presentation/pages/reset_password_page.dart';

/// Proves both password-reset routes resolve to the real pages, and that the
/// email handed over through `arguments` reaches them.
///
/// The composition root is configured for real, so the route builders exercise
/// the same service lookups the app does. The app's own Navigator is used
/// (`initialRoute`), which keeps exactly one page instance in the tree.
void main() {
  setUpAll(() async {
    await configureDependencies();
  });

  Future<void> pumpRoute(
    WidgetTester tester,
    String name, {
    Object? arguments,
  }) async {
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

    // Push the route under test with its arguments, exactly as the app does.
    // Deliberately not awaited: `pushNamed` completes only when the pushed
    // route is popped, so awaiting it here would hang the test.
    final context = tester.element(find.byType(Navigator));
    AppRouter.pushNamed<void>(context, name, arguments: arguments);
    await tester.pumpAndSettle();
  }

  group('AppRouter /forgot-password route', () {
    test('maps the route name to a material page', () {
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: AppRoutes.forgotPassword),
      );

      expect(route, isA<MaterialPageRoute<void>>());
      expect(route.settings.name, AppRoutes.forgotPassword);
    });

    testWidgets('builds the real Forgot Password page', (tester) async {
      await pumpRoute(tester, AppRoutes.forgotPassword);

      expect(find.byType(ForgotPasswordPage), findsOneWidget);
      expect(find.byKey(kForgotPasswordSubmitKey), findsOneWidget);
      expect(find.text('Reset your password'), findsOneWidget);
    });

    testWidgets('hands the email argument to the page', (tester) async {
      await pumpRoute(
        tester,
        AppRoutes.forgotPassword,
        arguments: 'person@example.test',
      );

      expect(find.byType(ForgotPasswordPage), findsOneWidget);
      expect(find.text('person@example.test'), findsOneWidget);
    });

    testWidgets('returns to the real login page', (tester) async {
      await pumpRoute(tester, AppRoutes.forgotPassword);

      await tester.tap(find.widgetWithText(TextButton, 'Back to sign in'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(ForgotPasswordPage), findsNothing);
    });
  });

  group('AppRouter /reset-password route', () {
    test('maps the route name to a material page', () {
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: AppRoutes.resetPassword),
      );

      expect(route, isA<MaterialPageRoute<void>>());
      expect(route.settings.name, AppRoutes.resetPassword);
    });

    testWidgets('builds the real Reset Password page', (tester) async {
      await pumpRoute(tester, AppRoutes.resetPassword);

      expect(find.byType(ResetPasswordPage), findsOneWidget);
      expect(find.byKey(kResetPasswordSubmitKey), findsOneWidget);
      expect(find.byKey(kResetPasswordResendKey), findsOneWidget);
      expect(find.text('Choose a new password'), findsOneWidget);
    });

    testWidgets('hands the email argument to the page', (tester) async {
      await pumpRoute(
        tester,
        AppRoutes.resetPassword,
        arguments: 'person@example.test',
      );

      expect(find.byType(ResetPasswordPage), findsOneWidget);
      expect(find.textContaining('person@example.test'), findsWidgets);
      // A handed-over address must not become an editable field.
      expect(find.widgetWithText(TextFormField, 'Email'), findsNothing);
    });
  });

  group('AppRouter password-reset argument handling', () {
    testWidgets('tolerates a non-string argument', (tester) async {
      await pumpRoute(
        tester,
        AppRoutes.resetPassword,
        arguments: <String, dynamic>{'email': 'person@example.test'},
      );

      expect(find.byType(ResetPasswordPage), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget,
          reason: 'an unreadable argument degrades to asking for the address');
    });

    testWidgets('tolerates a blank argument', (tester) async {
      await pumpRoute(tester, AppRoutes.resetPassword, arguments: '   ');

      expect(find.byType(ResetPasswordPage), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    });

    testWidgets('tolerates an absent argument', (tester) async {
      await pumpRoute(tester, AppRoutes.forgotPassword);

      expect(find.byType(ForgotPasswordPage), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    });
  });

  group('AppRouter backward compatibility', () {
    test('still resolves the previously shipped routes', () {
      for (final name in <String>[
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.verification,
        AppRoutes.home,
        '/does-not-exist',
      ]) {
        expect(
          AppRouter.onGenerateRoute(RouteSettings(name: name)),
          isA<MaterialPageRoute<void>>(),
          reason: 'route $name',
        );
      }
    });

    test('exposes the same navigation helpers as before', () {
      expect(AppRouter.pushNamed, isA<Function>());
      expect(AppRouter.replaceWithNamed, isA<Function>());
    });
  });
}
