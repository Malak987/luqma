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
import 'package:luqma_app/features/authentication/password_reset/presentation/pages/reset_password_page.dart';

import '../../fake_clock.dart';

const _email = 'person@example.test';
const _strongPassword = 'NewPassw0rd!';

void main() {
  testWidgets('shows the handed-over email as read-only text, not a field',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpReset(tester, _FakeRepository(), email: _email);

    expect(find.text('Choose a new password'), findsOneWidget);
    expect(find.textContaining(_email), findsWidgets);
    // The address came from the previous screen and must not be editable here.
    expect(find.widgetWithText(TextFormField, 'Email'), findsNothing);
    expect(find.widgetWithText(TextFormField, 'Reset code'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'New password'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'Confirm new password'),
      findsOneWidget,
    );
    expect(find.byKey(kResetPasswordSubmitKey), findsOneWidget);
    expect(find.byKey(kResetPasswordResendKey), findsOneWidget);
  });

  testWidgets('asks for the email when none was handed over', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpReset(tester, _FakeRepository());

    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
  });

  testWidgets('resets the password and returns to the login screen',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeRepository(
      resetResult:
          const PasswordResetResult(message: 'تم إعادة تعيين كلمة المرور بنجاح'),
    );

    await _pumpReset(tester, repository, email: _email);

    await _fillOtp(tester, '482913');
    await _fillPasswords(tester, _strongPassword, _strongPassword);
    await tester.tap(find.byKey(kResetPasswordSubmitKey));
    await tester.pumpAndSettle();

    expect(repository.resetCalls, hasLength(1));
    expect(repository.resetCalls.single.email, _email);
    expect(repository.resetCalls.single.otp, '482913');
    expect(repository.resetCalls.single.newPassword, _strongPassword);
    expect(repository.forgotCalls, isEmpty,
        reason: 'resetting must not send another code');

    // Resetting issues no token, so the user signs in next.
    expect(find.text('login-stub'), findsOneWidget);
    expect(find.byType(ResetPasswordPage), findsNothing);
  });

  testWidgets('does not reset twice for a double tap', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeRepository(
      resetResult: const PasswordResetResult(message: 'ok'),
    );

    await _pumpReset(tester, repository, email: _email);

    await _fillOtp(tester, '482913');
    await _fillPasswords(tester, _strongPassword, _strongPassword);
    await tester.tap(find.byKey(kResetPasswordSubmitKey));
    await tester.tap(find.byKey(kResetPasswordSubmitKey));
    await tester.pumpAndSettle();

    expect(repository.resetCalls, hasLength(1));
  });

  testWidgets('shows the backend invalid-OTP message and stays on the page',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeRepository(
      resetError: const FailureException(Failure(
        FailureCode.validation,
        debugMessage: 'رمز التحقق غير صحيح أو منتهي الصلاحية',
      )),
    );

    await _pumpReset(tester, repository, email: _email);

    await _fillOtp(tester, '000000');
    await _fillPasswords(tester, _strongPassword, _strongPassword);
    await tester.tap(find.byKey(kResetPasswordSubmitKey));
    await tester.pumpAndSettle();

    expect(
      find.text('رمز التحقق غير صحيح أو منتهي الصلاحية'),
      findsOneWidget,
    );
    expect(find.text('login-stub'), findsNothing);
  });

  testWidgets('rejects a non-numeric code without calling the backend',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeRepository();

    await _pumpReset(tester, repository, email: _email);

    await _fillOtp(tester, 'abcdef');
    await _fillPasswords(tester, _strongPassword, _strongPassword);
    await tester.tap(find.byKey(kResetPasswordSubmitKey));
    await tester.pumpAndSettle();

    expect(repository.resetCalls, isEmpty);
    expect(find.text('The reset code must be 6 digits'), findsOneWidget);
  });

  testWidgets('rejects a short code', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeRepository();

    await _pumpReset(tester, repository, email: _email);

    await _fillOtp(tester, '123');
    await _fillPasswords(tester, _strongPassword, _strongPassword);
    await tester.tap(find.byKey(kResetPasswordSubmitKey));
    await tester.pumpAndSettle();

    expect(repository.resetCalls, isEmpty);
    expect(find.text('The reset code must be 6 digits'), findsOneWidget);
  });

  testWidgets('rejects a weak password', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeRepository();

    await _pumpReset(tester, repository, email: _email);

    await _fillOtp(tester, '482913');
    await _fillPasswords(tester, 'weakpass', 'weakpass');
    await tester.tap(find.byKey(kResetPasswordSubmitKey));
    await tester.pumpAndSettle();

    expect(repository.resetCalls, isEmpty);
    expect(
      find.text('Password must contain at least one uppercase letter'),
      findsOneWidget,
    );
  });

  testWidgets('rejects mismatched passwords', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeRepository();

    await _pumpReset(tester, repository, email: _email);

    await _fillOtp(tester, '482913');
    await _fillPasswords(tester, _strongPassword, 'Different1!');
    await tester.tap(find.byKey(kResetPasswordSubmitKey));
    await tester.pumpAndSettle();

    expect(repository.resetCalls, isEmpty);
    expect(find.text('The two passwords do not match'), findsOneWidget);
  });

  testWidgets('keeps the resend button disabled during the 60-second cooldown '
      'handed over from the previous screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final clock = FakeClock();
    final repository = _FakeRepository(
      forgotResult: const PasswordResetResult(message: 'أُرسل الرمز'),
    );

    final cubit = await _pumpReset(
      tester,
      repository,
      email: _email,
      clock: clock,
    );

    // Arm the cooldown exactly as the Forgot screen would have.
    // Not awaited: inside `testWidgets` the fake repository's
    // `Future.delayed` is a timer that only a pump can fire, so awaiting
    // the call here would deadlock.
    cubit.requestReset(email: _email);
    await tester.pump();
    // The countdown label is driven by the page's 1-second ticker, and
    // `pumpAndSettle` does not advance the fake clock, so advance it here.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.textContaining('Resend available in'), findsOneWidget);
    expect(find.textContaining('60'), findsOneWidget);
    expect(_isResendEnabled(tester), isFalse);

    clock.advance(const Duration(seconds: 45));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.textContaining('15'), findsOneWidget);
    expect(_isResendEnabled(tester), isFalse);

    clock.advance(const Duration(seconds: 15));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.textContaining('Resend available in'), findsNothing);
    expect(_isResendEnabled(tester), isTrue);
  });

  testWidgets('resends by calling ForgotPassword again with the same email',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final clock = FakeClock();
    final repository = _FakeRepository(
      forgotResult: const PasswordResetResult(message: 'أُرسل الرمز مرة أخرى'),
    );

    final cubit = await _pumpReset(
      tester,
      repository,
      email: _email,
      clock: clock,
    );

    // Not awaited: inside `testWidgets` the fake repository's
    // `Future.delayed` is a timer that only a pump can fire, so awaiting
    // the call here would deadlock.
    cubit.requestReset(email: _email);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(repository.forgotCalls, hasLength(1));

    clock.advance(const Duration(seconds: 61));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(kResetPasswordResendKey));
    await tester.pumpAndSettle();

    expect(repository.forgotCalls, hasLength(2));
    expect(repository.forgotCalls.every((email) => email == _email), isTrue,
        reason: 'the resend must reuse the same address');
    expect(repository.resetCalls, isEmpty);
    // The backend confirms the resend, and a fresh window starts.
    expect(find.text('أُرسل الرمز مرة أخرى'), findsOneWidget);
    expect(find.textContaining('Resend available in'), findsOneWidget);
  });

  testWidgets('does not resend twice in quick succession', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final clock = FakeClock();
    final repository = _FakeRepository(
      forgotResult: const PasswordResetResult(message: 'أُرسل الرمز'),
    );

    final cubit = await _pumpReset(
      tester,
      repository,
      email: _email,
      clock: clock,
    );

    // Not awaited: inside `testWidgets` the fake repository's
    // `Future.delayed` is a timer that only a pump can fire, so awaiting
    // the call here would deadlock.
    cubit.requestReset(email: _email);
    await tester.pump();
    await tester.pumpAndSettle();
    clock.advance(const Duration(seconds: 61));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(kResetPasswordResendKey));
    await tester.tap(find.byKey(kResetPasswordResendKey));
    await tester.pumpAndSettle();

    expect(repository.forgotCalls, hasLength(2),
        reason: 'one for the original request, one for the single resend');
  });

  testWidgets('shows the resend failure without leaving the page',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final clock = FakeClock();
    final repository = _FakeRepository(
      forgotResult: const PasswordResetResult(message: 'أُرسل الرمز'),
    );

    final cubit = await _pumpReset(
      tester,
      repository,
      email: _email,
      clock: clock,
    );

    // Not awaited: inside `testWidgets` the fake repository's
    // `Future.delayed` is a timer that only a pump can fire, so awaiting
    // the call here would deadlock.
    cubit.requestReset(email: _email);
    await tester.pump();
    await tester.pumpAndSettle();
    clock.advance(const Duration(seconds: 61));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    repository.forgotError = const FailureException(
      Failure(FailureCode.validation,
          debugMessage: 'البريد الإلكتروني غير موجود'),
    );

    await tester.tap(find.byKey(kResetPasswordResendKey));
    await tester.pumpAndSettle();

    expect(find.text('البريد الإلكتروني غير موجود'), findsOneWidget);
    expect(find.text('login-stub'), findsNothing);
  });

  testWidgets('does not navigate away when a resend succeeds', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final clock = FakeClock();
    final repository = _FakeRepository(
      forgotResult: const PasswordResetResult(message: 'أُرسل الرمز'),
    );

    final cubit = await _pumpReset(
      tester,
      repository,
      email: _email,
      clock: clock,
    );

    // Not awaited: inside `testWidgets` the fake repository's
    // `Future.delayed` is a timer that only a pump can fire, so awaiting
    // the call here would deadlock.
    cubit.requestReset(email: _email);
    await tester.pump();
    await tester.pumpAndSettle();
    clock.advance(const Duration(seconds: 61));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(kResetPasswordResendKey));
    await tester.pumpAndSettle();

    expect(find.byKey(kResetPasswordSubmitKey), findsOneWidget,
        reason: 'a resend must keep the user on the reset form');
    expect(find.text('login-stub'), findsNothing);
  });

  testWidgets('returns to the login screen from the back link', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpReset(tester, _FakeRepository(), email: _email);

    await tester.tap(find.widgetWithText(TextButton, 'Back to sign in'));
    await tester.pumpAndSettle();

    expect(find.text('login-stub'), findsOneWidget);
  });

  testWidgets('sends a typed email when none was handed over', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeRepository(
      resetResult: const PasswordResetResult(message: 'ok'),
    );

    await _pumpReset(tester, repository);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), _email);
    await _fillOtp(tester, '482913');
    await _fillPasswords(tester, _strongPassword, _strongPassword);
    await tester.tap(find.byKey(kResetPasswordSubmitKey));
    await tester.pumpAndSettle();

    expect(repository.resetCalls.single.email, _email);
  });
}

Future<void> _fillOtp(WidgetTester tester, String otp) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Reset code'),
    otp,
  );
  await tester.pumpAndSettle();
}

Future<void> _fillPasswords(
  WidgetTester tester,
  String password,
  String confirmation,
) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'New password'),
    password,
  );
  await tester.pumpAndSettle();
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Confirm new password'),
    confirmation,
  );
  await tester.pumpAndSettle();
}

/// The test key sits on the `AppButton` wrapper, so the underlying
/// `ElevatedButton` is reached through it rather than by the key directly.
Finder _resendButton() =>
    find.descendant(of: find.byKey(kResetPasswordResendKey), matching: find.byType(ElevatedButton));

bool _isResendEnabled(WidgetTester tester) =>
    tester.widget<ElevatedButton>(_resendButton()).onPressed != null;

/// Mirrors `AppRouter`: one shared cubit for the page, and `/login` stubbed
/// because the real route resolves `sl<LoginCubit>()`.
Future<PasswordResetCubit> _pumpReset(
  WidgetTester tester,
  _FakeRepository repository, {
  String? email,
  FakeClock? clock,
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
        if (settings.name == AppRoutes.resetPassword) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => BlocProvider<PasswordResetCubit>.value(
              value: cubit,
              child: ResetPasswordPage(email: email),
            ),
          );
        }
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
  AppRouter.pushNamed<void>(
    context,
    AppRoutes.resetPassword,
    arguments: email,
  );
  await tester.pumpAndSettle();
  return cubit;
}

class _Call {
  const _Call({
    required this.email,
    required this.otp,
    required this.newPassword,
  });

  final String email;
  final String otp;
  final String newPassword;
}

class _FakeRepository implements PasswordResetRepository {
  _FakeRepository({this.forgotResult, this.resetResult, this.resetError});

  final PasswordResetResult? forgotResult;
  final PasswordResetResult? resetResult;

  /// Set by the resend-failure test after the first code was sent.
  Object? forgotError;
  Object? resetError;

  final List<String> forgotCalls = <String>[];
  final List<_Call> resetCalls = <_Call>[];

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
    resetCalls.add(
      _Call(email: email, otp: otp, newPassword: newPassword),
    );
    await Future<void>.delayed(Duration.zero);
    final error = resetError;
    if (error != null) {
      throw error;
    }
    return resetResult!;
  }
}
