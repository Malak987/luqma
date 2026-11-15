import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/routing/app_router.dart';
import 'package:luqma_app/core/routing/app_routes.dart';

/// Covers the router branch that hands the registered email to the
/// verification screen. Building the route is deliberately **not** asserted
/// here: that resolves `sl<EmailVerificationCubit>()`, and the composition
/// root is not configured in unit tests. The page's own behaviour with a
/// supplied email is covered by `email_verification_page_test.dart`.
void main() {
  group('AppRouter /verification route', () {
    test('maps the route name to a material page and preserves the email', () {
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(
          name: AppRoutes.verification,
          arguments: 'person@example.test',
        ),
      );

      expect(route, isA<MaterialPageRoute<void>>());
      expect(route.settings.name, AppRoutes.verification);
      expect(route.settings.arguments, 'person@example.test');
    });

    test('keeps a blank argument so the page falls back to asking for it', () {
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(
          name: AppRoutes.verification,
          arguments: '   ',
        ),
      );

      expect(route, isA<MaterialPageRoute<void>>());
    });

    test('accepts a route with no arguments at all', () {
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: AppRoutes.verification),
      );

      expect(route, isA<MaterialPageRoute<void>>());
      expect(route.settings.arguments, isNull);
    });

    test('still resolves the other auth routes', () {
      expect(
        AppRouter.onGenerateRoute(
          const RouteSettings(name: AppRoutes.login),
        ),
        isA<MaterialPageRoute<void>>(),
      );
      expect(
        AppRouter.onGenerateRoute(
          const RouteSettings(name: AppRoutes.register),
        ),
        isA<MaterialPageRoute<void>>(),
      );
    });
  });
}
