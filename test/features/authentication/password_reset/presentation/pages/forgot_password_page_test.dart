import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/routing/app_router.dart';
import 'package:luqma_app/core/routing/app_routes.dart';
import 'package:luqma_app/features/authentication/password_reset/domain/entities/password_reset_result.dart';
import 'package:luqma_app/features/authentication/password_reset/domain/repositories/password_reset_repository.dart';
import 'package:luqma_app/features/authentication/password_reset/domain/usecases/forgot_password_use_case.dart';
import 'package:luqma_app/features/authentication/password_reset/domain/usecases/reset_password_use_case.dart';
import 'package:luqma_app/features/authentication/password_reset/presentation/cubit/password_reset_cubit.dart';
import 'package:luqma_app/features/authentication/password_reset/presentation/pages/forgot_password_page.dart';

import '../../fake_clock.dart';

const _email = 'person@example.test';

void main() {
  testWidgets('renders the form with an email field and an active send button',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpForgot(tester, _FakeRepository());

    expect(find.text('Reset your password'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.byKey(kForgotPasswordSubmitKey), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Back to sign in'), findsOneWidget);
    expect(_isSendEnabled(tester), isTrue);
    // Nothing has been sent yet, so no countdown is shown.
    expect(find.textContaining('Resend available in'), findsNothing);
  });

  testWidgets('prefills the email handed over through route arguments',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpForgot(tester, _FakeRepository(), email: _email);

    expect(find.text(_email), findsOneWidget);
  });

  testWidgets('sends the email and navigates to the reset screen carrying it',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeRepository(
      forgotResult: const PasswordResetResult(
        message: 'تم إرسال رمز إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
      ),
    );
    Object? resetRouteArguments;

    await _pumpForgot(
      tester,
      repository,
      resetArguments: (arguments) => resetRouteArguments = arguments,
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), _email);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(kForgotPasswordSubmitKey));
    await tester.pumpAndSettle();

    expect(repository.forgotCalls, hasLength(1));
    expect(repository.forgotCalls.single, _email);
    expect(repository.resetCalls, isEmpty);

    // The backend message is surfaced verbatim, then the user moves on.
    expect(
      find.text('تم إرسال رمز إعادة تعيين كلمة المرور إلى بريدك الإلكتروني'),
      findsOneWidget,
    );
    expect(find.text('reset-stub'), findsOneWidget);
    expect(resetRouteArguments, _email,
        reason: 'the Reset screen must not make the user retype the email');
  });

  testWidgets('does not call the backend twice for a double tap',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeRepository(
      forgotResult: const PasswordResetResult(message: 'ok'),
    );

    await _pumpForgot(tester, repository);

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), _email);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(kForgotPasswordSubmitKey));
    await tester.tap(find.byKey(kForgotPasswordSubmitKey));
    await tester.pumpAndSettle();

    expect(repository.forgotCalls, hasLength(1));
  });

  testWidgets('rejects an invalid email without calling the backend',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeRepository();

    await _pumpForgot(tester, repository);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'not-an-email');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(kForgotPasswordSubmitKey));
    await tester.pumpAndSettle();

    expect(repository.forgotCalls, isEmpty);
    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('shows the backend error for an unknown email', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeRepository(
      forgotError: const FailureException(Failure(
        FailureCode.validation,
        debugMessage: 'البريد الإلكتروني غير موجود',
      )),
    );

    await _pumpForgot(tester, repository);

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), _email);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(kForgotPasswordSubmitKey));
    await tester.pumpAndSettle();

    expect(find.text('البريد الإلكتروني غير موجود'), findsOneWidget);
    // The failure must not navigate anywhere.
    expect(find.text('reset-stub'), findsNothing);
  });

  testWidgets('shows the localized fallback for a network failure',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpForgot(
      tester,
      _FakeRepository(
        forgotError: const FailureException(Failure(FailureCode.network)),
      ),
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), _email);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(kForgotPasswordSubmitKey));
    await tester.pumpAndSettle();

    expect(
      find.text('Check your internet connection and try again'),
      findsOneWidget,
    );
  });

  testWidgets('starts a 60-second cooldown after a successful request',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final clock = FakeClock();
    final repository = _FakeRepository(
      forgotResult: const PasswordResetResult(message: 'ok'),
    );

    final cubit = await _pumpForgot(tester, repository, clock: clock);

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), _email);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(kForgotPasswordSubmitKey));
    await tester.pumpAndSettle();

    // Success hands over to the Reset screen, so this page's own button is
    // gone; the armed window is asserted on the shared cubit, which is what the
    // Reset screen's resend button reads.
    expect(find.text('reset-stub'), findsOneWidget);
    expect(cubit.requestCooldownRemaining, 60);
    expect(cubit.canRequest, isFalse);

    clock.advance(const Duration(seconds: 30));
    expect(cubit.requestCooldownRemaining, 30);
    expect(cubit.canRequest, isFalse);

    clock.advance(const Duration(seconds: 30));
    expect(cubit.requestCooldownRemaining, 0);
    expect(cubit.canRequest, isTrue);
  });

  testWidgets(
      'shows the countdown label and counts it down when re-entered '
      'during the cooldown', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final clock = FakeClock();
    final repository = _FakeRepository(
      forgotResult: const PasswordResetResult(message: 'ok'),
    );

    // Arm the cooldown: this visit ends by navigating to the Reset screen.
    final cubit = await _pumpForgot(tester, repository, clock: clock);
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), _email);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(kForgotPasswordSubmitKey));
    await tester.pumpAndSettle();
    expect(cubit.requestCooldownRemaining, 60);

    // Re-entering the screen must show the window still running rather than
    // offering another code straight away.
    final context = tester.element(find.byType(Navigator));
    AppRouter.pushNamed<void>(context, AppRoutes.forgotPassword);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('Resend available in'), findsOneWidget);
    expect(find.textContaining('60'), findsOneWidget);
    expect(_isSendEnabled(tester), isFalse);

    clock.advance(const Duration(seconds: 30));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.textContaining('30'), findsOneWidget);
    expect(_isSendEnabled(tester), isFalse);

    clock.advance(const Duration(seconds: 30));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.textContaining('Resend available in'), findsNothing);
    expect(_isSendEnabled(tester), isTrue);
  });

  testWidgets('never sends a second request automatically', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final clock = FakeClock();
    final repository = _FakeRepository(
      forgotResult: const PasswordResetResult(message: 'ok'),
    );

    await _pumpForgot(tester, repository, clock: clock);

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), _email);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(kForgotPasswordSubmitKey));
    await tester.pumpAndSettle();

    // Rebuilds and a fully elapsed cooldown must not re-fire the request.
    clock.advance(const Duration(seconds: 120));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    expect(repository.forgotCalls, hasLength(1));
  });

  testWidgets('returns to the login screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpForgot(tester, _FakeRepository());

    await tester.tap(find.widgetWithText(TextButton, 'Back to sign in'));
    await tester.pumpAndSettle();

    expect(find.text('login-stub'), findsOneWidget);
  });
}

/// The test key sits on the `PrimaryAuthButton` wrapper, so the underlying
/// `ElevatedButton` is reached through it rather than by the key directly.
Finder _sendButton() => find.descendant(
    of: find.byKey(kForgotPasswordSubmitKey),
    matching: find.byType(ElevatedButton));

bool _isSendEnabled(WidgetTester tester) =>
    tester.widget<ElevatedButton>(_sendButton()).onPressed != null;

/// Mirrors `AppRouter`, which exposes ONE cubit instance to both
/// password-reset routes. `/reset-password` and `/login` are stubbed because
/// the real routes resolve service-locator dependencies that tests do not
/// configure.
Future<PasswordResetCubit> _pumpForgot(
  WidgetTester tester,
  _FakeRepository repository, {
  String? email,
  FakeClock? clock,
  void Function(Object? arguments)? resetArguments,
}) async {
  final cubit = PasswordResetCubit(
    forgotPasswordUseCase: ForgotPasswordUseCase(repository),
    resetPasswordUseCase: ResetPasswordUseCase(repository),
    now: (clock ?? FakeClock()).now,
  );
  // The cubit runs a periodic cooldown timer; close it so the test does not
  // leave a pending timer behind.
  addTearDown(cubit.close);

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.forgotPassword) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => BlocProvider<PasswordResetCubit>.value(
              value: cubit,
              child: ForgotPasswordPage(email: email),
            ),
          );
        }
        if (settings.name == AppRoutes.resetPassword) {
          resetArguments?.call(settings.arguments);
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('reset-stub')),
          );
        }
        // Always stubbed: it is also the `initialRoute` this harness pushes
        // the page on top of, and where "back to sign in" pops back to.
        if (settings.name == AppRoutes.login) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('login-stub')),
          );
        }
        return null;
      },
      initialRoute: AppRoutes.login,
    ),
  );

  final context = tester.element(find.byType(Navigator));
  // Deliberately not awaited: `pushNamed` completes only when the pushed route
  // is popped, so awaiting it here would hang the test.
  AppRouter.pushNamed<void>(context, AppRoutes.forgotPassword);
  await tester.pumpAndSettle();
  return cubit;
}

class _FakeRepository implements PasswordResetRepository {
  _FakeRepository({this.forgotResult, this.forgotError});

  final PasswordResetResult? forgotResult;
  Object? forgotError;

  final List<String> forgotCalls = <String>[];
  final List<String> resetCalls = <String>[];

  @override
  Future<PasswordResetResult> forgotPassword({required String email}) async {
    forgotCalls.add(email);
    await Future<void>.delayed(Duration.zero);
    final error = forgotError;
    if (error != null) {
      throw error;
    }
    return forgotResult!;
  }

  @override
  Future<PasswordResetResult> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    resetCalls.add(email);
    await Future<void>.delayed(Duration.zero);
    // This screen never resets a password, so a stub result is enough.
    return const PasswordResetResult(message: 'unused');
  }
}
