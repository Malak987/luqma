import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:luqma_app/core/presentation/cubit/app_settings_cubit.dart';
import 'package:luqma_app/core/storage/preferences_storage_service.dart';
import 'package:luqma_app/core/storage/secure_storage_service.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/account/presentation/pages/account_page.dart';
import 'package:luqma_app/features/authentication/presentation/cubit/auth_session_cubit.dart';
import 'package:luqma_app/features/authentication/presentation/cubit/auth_session_state.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';

void main() {
  Future<_Harness> pumpAccount(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = PreferencesStorageService(
      await SharedPreferences.getInstance(),
    );
    final storage = _TestSecureStorage();
    final session = AuthSessionCubit(secureStorageService: storage);
    await session.checkSession();
    final settings = AppSettingsCubit(preferencesStorageService: preferences);
    addTearDown(session.close);
    addTearDown(settings.close);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<AuthSessionCubit>.value(value: session),
          BlocProvider<AppSettingsCubit>.value(value: settings),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(body: AccountPage()),
        ),
      ),
    );
    return _Harness(session: session, storage: storage);
  }

  testWidgets('account logout entry opens confirmation; cancel keeps session',
      (tester) async {
    final harness = await pumpAccount(tester);
    await tester.tap(find.byKey(const Key('account_logout_tile')));
    await tester.pumpAndSettle();

    expect(find.text('Log out?'), findsOneWidget);
    expect(
      find.text('You will need to sign in again to continue.'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(harness.storage.clearCalled, isFalse);
    expect(harness.session.state.status, AuthSessionStatus.authenticated);
    expect(find.byType(AccountPage), findsOneWidget);
  });

  testWidgets('confirmation signs out through AuthSessionCubit without popping account',
      (tester) async {
    final harness = await pumpAccount(tester);
    await tester.tap(find.byKey(const Key('account_logout_tile')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Log out'));
    await tester.pumpAndSettle();

    expect(harness.storage.clearCalled, isTrue);
    expect(harness.session.state.status, AuthSessionStatus.unauthenticated);
    expect(find.byType(AccountPage), findsOneWidget);
  });
}

class _Harness {
  const _Harness({required this.session, required this.storage});
  final AuthSessionCubit session;
  final _TestSecureStorage storage;
}

class _TestSecureStorage extends SecureStorageService {
  _TestSecureStorage() : super(const FlutterSecureStorage());
  bool clearCalled = false;

  @override
  Future<String?> getToken() async => 'test-token';

  @override
  Future<String?> getExpiresAt() async =>
      DateTime.now().toUtc().add(const Duration(hours: 1)).toIso8601String();

  @override
  Future<void> clearAuthData() async {
    clearCalled = true;
  }
}
