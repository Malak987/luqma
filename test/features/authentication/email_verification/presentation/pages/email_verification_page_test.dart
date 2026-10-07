import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/routing/app_routes.dart';
import 'package:luqma_app/features/authentication/email_verification/domain/entities/email_verification_result.dart';
import 'package:luqma_app/features/authentication/email_verification/domain/repositories/email_verification_repository.dart';
import 'package:luqma_app/features/authentication/email_verification/domain/usecases/confirm_email_use_case.dart';
import 'package:luqma_app/features/authentication/email_verification/domain/usecases/resend_otp_use_case.dart';
import 'package:luqma_app/features/authentication/email_verification/presentation/cubit/email_verification_cubit.dart';
import 'package:luqma_app/features/authentication/email_verification/presentation/pages/email_verification_page.dart';

const _email = 'person@example.test';

void main() {
  testWidgets('shows the handed-over email and does not offer an email field',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _harness(_RecordingRepository(),
          page: const EmailVerificationPage(email: _email)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Confirm your email'), findsOneWidget);
    expect(find.textContaining(_email), findsWidgets);
    // The email came from Register, so it must not be editable.
    expect(find.widgetWithText(TextFormField, 'Email'), findsNothing);
    expect(find.widgetWithText(TextFormField, 'Verification code'),
        findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);
    // The first code was already sent by Register, so the cooldown is running.
    expect(find.textContaining('Resend available in'), findsOneWidget);
  });

  testWidgets('asks for the email when none was handed over', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _harness(_RecordingRepository(), page: const EmailVerificationPage()),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
  });

  testWidgets('submits the email and OTP to the confirm use case',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _RecordingRepository(
      confirmResult: const EmailVerificationResult(message: 'تم التأكيد بنجاح'),
    );

    await tester.pumpWidget(
      _harness(repository, page: const EmailVerificationPage(email: _email)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Verification code'),
      '482913',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm'));
    await tester.pumpAndSettle();

    expect(repository.confirmCalls, hasLength(1));
    expect(repository.confirmCalls.single.email, _email);
    expect(repository.confirmCalls.single.otp, '482913');
    expect(repository.resendCalls, isEmpty);

    // Confirming issues no token, so the user is sent to sign in.
    expect(find.text('login-stub'), findsOneWidget);
  });

  testWidgets('rejects a non-numeric OTP without calling the backend',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _RecordingRepository();

    await tester.pumpWidget(
      _harness(repository, page: const EmailVerificationPage(email: _email)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Verification code'),
      'abcdef',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm'));
    await tester.pumpAndSettle();

    expect(repository.confirmCalls, isEmpty);
    expect(
      find.text('The verification code must be 6 digits'),
      findsOneWidget,
    );
  });

  testWidgets('rejects a short OTP without calling the backend',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _RecordingRepository();

    await tester.pumpWidget(
      _harness(repository, page: const EmailVerificationPage(email: _email)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Verification code'),
      '4829',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm'));
    await tester.pumpAndSettle();

    expect(repository.confirmCalls, isEmpty);
  });

  testWidgets('keeps resend disabled during the 60s cooldown, then enables it',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _RecordingRepository(
      resendResult: const EmailVerificationResult(
        message: 'تم إعادة إرسال رمز التحقق بنجاح',
      ),
    );
    final clock = _FakeClock();

    await tester.pumpWidget(
      _harness(
        repository,
        page: const EmailVerificationPage(email: _email),
        clock: clock,
      ),
    );
    await tester.pumpAndSettle();

    // Immediately after Register the cooldown must still be running.
    expect(find.textContaining('Resend available in 60s'), findsOneWidget);
    expect(
      find.textContaining('Resend code'),
      findsNothing,
      reason: 'the resend affordance must be hidden while cooling down',
    );

    // Still cooling down just before the window closes.
    clock.advance(const Duration(seconds: 58));
    await tester.pump(const Duration(seconds: 58));
    expect(find.textContaining('Resend available in'), findsOneWidget);
    expect(find.textContaining('Resend code'), findsNothing);

    // Past the 60-second window the button becomes available.
    clock.advance(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.textContaining('Resend available in'), findsNothing);
    expect(find.textContaining('Resend code'), findsOneWidget);

    await tester.tap(find.byKey(kEmailVerificationResendButtonKey));
    await tester.pumpAndSettle();

    expect(repository.resendCalls, <String>[_email]);
    expect(repository.confirmCalls, isEmpty);

    // A successful resend restarts the cooldown.
    expect(find.textContaining('Resend available in 60s'), findsOneWidget);
  });

  testWidgets('never resends automatically on screen entry', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _RecordingRepository();

    await tester.pumpWidget(
      _harness(repository, page: const EmailVerificationPage(email: _email)),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 61));

    expect(repository.resendCalls, isEmpty);
  });

  testWidgets('shows the backend Arabic message when confirmation fails',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _RecordingRepository(
      confirmFailureMessage: 'رمز التحقق غير صحيح أو منتهي الصلاحية',
    );

    await tester.pumpWidget(
      _harness(repository, page: const EmailVerificationPage(email: _email)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Verification code'),
      '000000',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm'));
    await tester.pumpAndSettle();

    expect(
      find.text('رمز التحقق غير صحيح أو منتهي الصلاحية'),
      findsOneWidget,
    );
    // The user stays on the screen to retry.
    expect(find.text('login-stub'), findsNothing);
  });
}

/// The page ticker is driven by `tester.pump`, but `DateTime.now` is **not**
/// faked by the Flutter test binding — only timers are. The clock is therefore
/// injected so the cooldown can be advanced deterministically.
class _FakeClock {
  DateTime _current = DateTime.utc(2026, 10, 6, 12);

  DateTime now() => _current;

  void advance(Duration by) => _current = _current.add(by);
}

Widget _harness(
  _RecordingRepository repository, {
  required EmailVerificationPage page,
  _FakeClock? clock,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    onGenerateRoute: _routes,
    // Mirrors `AppRouter`, which supplies the cubit for the /verification
    // route.
    home: BlocProvider<EmailVerificationCubit>(
      create: (_) => EmailVerificationCubit(
        confirmEmailUseCase: ConfirmEmailUseCase(repository),
        resendOtpUseCase: ResendOtpUseCase(repository),
        now: (clock ?? _FakeClock()).now,
      ),
      child: page,
    ),
  );
}

/// Stubs the `/login` route, which is where a successful confirmation leads.
/// The real route resolves `sl<LoginCubit>()` and the composition root is not
/// configured in tests.
Route<dynamic>? _routes(RouteSettings settings) {
  if (settings.name == AppRoutes.login) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const Scaffold(body: Text('login-stub')),
    );
  }
  return null;
}

class _Call {
  const _Call({required this.email, required this.otp});

  final String email;
  final String otp;
}

class _RecordingRepository implements EmailVerificationRepository {
  _RecordingRepository({
    this.confirmResult,
    this.resendResult,
    this.confirmFailureMessage,
  });

  final EmailVerificationResult? confirmResult;
  final EmailVerificationResult? resendResult;
  final String? confirmFailureMessage;
  final List<_Call> confirmCalls = <_Call>[];
  final List<String> resendCalls = <String>[];

  @override
  Future<EmailVerificationResult> confirmEmail({
    required String email,
    required String otp,
  }) async {
    confirmCalls.add(_Call(email: email, otp: otp));
    await Future<void>.delayed(Duration.zero);

    final message = confirmFailureMessage;
    if (message != null) {
      throw FailureException(
        Failure(FailureCode.validation, debugMessage: message),
      );
    }
    return confirmResult!;
  }

  @override
  Future<EmailVerificationResult> resendOtp({required String email}) async {
    resendCalls.add(email);
    await Future<void>.delayed(Duration.zero);
    return resendResult!;
  }
}
