import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/features/authentication/register/domain/entities/register_result.dart';
import 'package:luqma_app/features/authentication/register/domain/repositories/register_repository.dart';
import 'package:luqma_app/features/authentication/register/domain/usecases/register_use_case.dart';
import 'package:luqma_app/features/authentication/register/presentation/cubit/register_cubit.dart';
import 'package:luqma_app/features/authentication/register/presentation/pages/register_page.dart';

void main() {
  testWidgets('RegisterPage renders every contract field and submits them', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _RecordingRegisterRepository(
      const RegisterResult(message: 'Account created'),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        onGenerateRoute: _routes,
        home: BlocProvider<RegisterCubit>(
          create: (_) =>
              RegisterCubit(registerUseCase: RegisterUseCase(repository)),
          child: const RegisterPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Phone number'), findsOneWidget);
    expect(find.text('Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
    expect(find.text('Create account'), findsWidgets);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'new_user',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'person@example.test',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Phone number'),
      '01000000000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Address'),
      '1 Test Street',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'Valid1!pass',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm password'),
      'Valid1!pass',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(repository.calls, hasLength(1));
    expect(repository.calls.single.userName, 'new_user');
    expect(repository.calls.single.email, 'person@example.test');
    expect(repository.calls.single.phoneNumber, '01000000000');
    expect(repository.calls.single.address, '1 Test Street');
    expect(repository.calls.single.password, 'Valid1!pass');
    expect(repository.calls.single.confirmPassword, 'Valid1!pass');

    // Registration issues no token, so the user is returned to sign-in.
    expect(find.text('login-stub'), findsOneWidget);
  });

  testWidgets('blocks submission when the passwords do not match', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _RecordingRegisterRepository(
      const RegisterResult(message: 'Account created'),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        onGenerateRoute: _routes,
        home: BlocProvider<RegisterCubit>(
          create: (_) =>
              RegisterCubit(registerUseCase: RegisterUseCase(repository)),
          child: const RegisterPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'new_user',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'person@example.test',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Phone number'),
      '01000000000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Address'),
      '1 Test Street',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'Valid1!pass',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm password'),
      'Different2@pass',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(repository.calls, isEmpty);
    expect(find.text('The two passwords do not match'), findsOneWidget);
  });
}

class _RegisterCall {
  const _RegisterCall({
    required this.userName,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.phoneNumber,
    required this.address,
  });

  final String userName;
  final String email;
  final String password;
  final String confirmPassword;
  final String phoneNumber;
  final String address;
}

class _RecordingRegisterRepository implements RegisterRepository {
  _RecordingRegisterRepository(this.result);

  final RegisterResult result;
  final List<_RegisterCall> calls = <_RegisterCall>[];

  @override
  Future<RegisterResult> register({
    required String userName,
    required String email,
    required String password,
    required String confirmPassword,
    required String phoneNumber,
    required String address,
  }) async {
    calls.add(
      _RegisterCall(
        userName: userName,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        phoneNumber: phoneNumber,
        address: address,
      ),
    );
    return result;
  }
}

/// Supplies the `/login` route that RegisterPage falls back to after a
/// successful registration. Deliberately a stub: the real route resolves
/// `sl<LoginCubit>()`, and the composition root is not configured in tests.
Route<dynamic>? _routes(RouteSettings settings) {
  if (settings.name == '/login') {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const Scaffold(body: Text('login-stub')),
    );
  }
  return null;
}
