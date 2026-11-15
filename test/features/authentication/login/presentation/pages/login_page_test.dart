import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/core/widgets/app_logo.dart';
import 'package:luqma_app/features/authentication/login/domain/entities/auth_session.dart';
import 'package:luqma_app/features/authentication/login/domain/repositories/login_repository.dart';
import 'package:luqma_app/features/authentication/login/domain/usecases/login_use_case.dart';
import 'package:luqma_app/features/authentication/login/presentation/cubit/login_cubit.dart';
import 'package:luqma_app/features/authentication/login/presentation/pages/login_page.dart';

void main() {
  Future<_FakeLoginRepository> pump(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    ThemeData? theme,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeLoginRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        routes: <String, WidgetBuilder>{
          '/home': (_) => const Scaffold(
                body: Text('Home'),
              ),
        },
        home: BlocProvider<LoginCubit>(
          create: (_) => LoginCubit(loginUseCase: LoginUseCase(repository)),
          child: const LoginPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repository;
  }

  testWidgets('shows the logo and an email-only field', (tester) async {
    await pump(tester);

    expect(find.byType(AppLogo), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Username or email'), findsNothing);
  });

  testWidgets('rejects a username that is not an email', (tester) async {
    final repository = await pump(tester);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'new_user');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'Abcde1!');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(repository.calls, isEmpty);
  });

  testWidgets('submits a valid email and password', (tester) async {
    final repository = await pump(tester);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'person@example.test');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'Abcde1!');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();

    expect(repository.calls, <String>['person@example.test']);
  });

  testWidgets('does not flag a field while the user is still typing',
      (tester) async {
    await pump(tester);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'not-an-email');
    await tester.pump();

    expect(find.text('Enter a valid email address'), findsNothing);
  });

  testWidgets('flags an invalid email after the user leaves the field',
      (tester) async {
    await pump(tester);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'not-an-email');
    await tester.tap(find.widgetWithText(TextFormField, 'Password'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('does not overflow on a small phone or a wide window',
      (tester) async {
    await pump(tester, size: const Size(320, 568));
    expect(tester.takeException(), isNull);

    await pump(tester, size: const Size(1280, 800), theme: AppTheme.dark);
    expect(tester.takeException(), isNull);
  });
}

class _FakeLoginRepository implements LoginRepository {
  final List<String> calls = <String>[];

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    calls.add(email);
    return AuthSession(
      userId: '1',
      userName: 'user',
      role: 'Customer',
      token: 'token',
      expiresAt: DateTime(2100),
    );
  }
}
