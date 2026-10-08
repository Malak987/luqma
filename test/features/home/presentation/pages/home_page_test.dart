import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/storage/secure_storage_service.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/core/widgets/app_logo.dart';
import 'package:luqma_app/features/authentication/presentation/cubit/auth_session_cubit.dart';
import 'package:luqma_app/features/authentication/presentation/cubit/auth_session_state.dart';
import 'package:luqma_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:luqma_app/features/home/presentation/pages/home_page.dart';

void main() {
  Future<_HomeHarness> pumpHome(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    String? userName = 'Malak',
    bool failRead = false,
    Locale locale = const Locale('en'),
    ThemeData? theme,
    bool pushHomeRoute = false,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final storage = _FakeSecureStorageService(
      userName: userName,
      failRead: failRead,
    );
    final authSessionCubit = _RecordingAuthSessionCubit(
      secureStorageService: storage,
    );
    addTearDown(authSessionCubit.close);

    final navigatorKey = GlobalKey<NavigatorState>();
    final observer = _RecordingNavigatorObserver();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<AuthSessionCubit>.value(value: authSessionCubit),
          BlocProvider<HomeCubit>(
            create: (_) => HomeCubit(secureStorageService: storage),
          ),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: <NavigatorObserver>[observer],
          theme: theme ?? AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          home: pushHomeRoute
              ? const Scaffold(body: Center(child: Text('root-stub')))
              : const HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    if (pushHomeRoute) {
      // Pushed above a root route so `canPop()` is true — the exact condition
      // the removed navigation used to branch on. The returned future is not
      // awaited: it completes only when the route is popped.
      navigatorKey.currentState!.push<void>(
        MaterialPageRoute<void>(builder: (_) => const HomePage()),
      );
      await tester.pumpAndSettle();
    }

    return _HomeHarness(
      storage: storage,
      authSessionCubit: authSessionCubit,
      observer: observer,
    );
  }

  testWidgets('renders the brand header, the search bar and both sections',
      (tester) async {
    await pumpHome(tester);

    expect(find.byType(AppLogo), findsOneWidget);
    expect(find.text('Welcome back, Malak'), findsOneWidget);
    expect(find.text('Search for a dish or a restaurant'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Restaurants'), findsOneWidget);
    // No sample categories or restaurants until their APIs exist.
    expect(find.text('Categories will appear here soon'), findsOneWidget);
    expect(find.text('Restaurants will appear here soon'), findsOneWidget);
  });

  testWidgets('falls back to a name-less greeting without a stored name',
      (tester) async {
    await pumpHome(tester, userName: null);

    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('renders the Arabic copy when the locale is Arabic',
      (tester) async {
    await pumpHome(tester, locale: const Locale('ar'));

    expect(find.text('أهلاً بعودتك، Malak'), findsOneWidget);
    expect(find.text('الأقسام'), findsOneWidget);
    expect(find.text('المطاعم'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a loading indicator while the profile is read',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final storage = _BlockingSecureStorageService();
    final authSessionCubit = AuthSessionCubit(secureStorageService: storage);
    addTearDown(authSessionCubit.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<AuthSessionCubit>.value(value: authSessionCubit),
          BlocProvider<HomeCubit>(
            create: (_) => HomeCubit(secureStorageService: storage),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const HomePage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Categories'), findsNothing);

    storage.release();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Welcome back, Malak'), findsOneWidget);
  });

  testWidgets('explains a failed load and retries on demand', (tester) async {
    final harness = await pumpHome(tester, failRead: true);

    expect(find.text("We couldn't load your home screen"), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    harness.storage.failRead = false;
    await tester.tap(find.widgetWithText(ElevatedButton, 'Try again'));
    await tester.pumpAndSettle();

    expect(find.text("We couldn't load your home screen"), findsNothing);
    expect(find.text('Welcome back, Malak'), findsOneWidget);
  });

  testWidgets('says that search is not available yet', (tester) async {
    await pumpHome(tester);

    await tester.enterText(find.byType(TextFormField), 'pizza');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('Search will be available soon'), findsOneWidget);
  });

  testWidgets('signs out through AuthSessionCubit after confirmation',
      (tester) async {
    final harness = await pumpHome(tester);

    await tester.tap(find.byTooltip('Log out'));
    await tester.pumpAndSettle();

    expect(find.text('Log out?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Log out'));
    await tester.pumpAndSettle();

    // The existing session cubit performs the sign-out; the home screen only
    // asks for it, so the app-level auth switch can show login again.
    expect(harness.authSessionCubit.logoutCalls, 1);
    expect(harness.storage.clearCalled, isTrue);
    expect(
      harness.authSessionCubit.state.status,
      AuthSessionStatus.unauthenticated,
    );
  });

  testWidgets('keeps the session when the sign-out is dismissed',
      (tester) async {
    final harness = await pumpHome(tester);

    await tester.tap(find.byTooltip('Log out'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(harness.authSessionCubit.logoutCalls, 0);
    expect(harness.storage.clearCalled, isFalse);
    expect(
      harness.authSessionCubit.state.status,
      isNot(AuthSessionStatus.unauthenticated),
    );
  });

  testWidgets('does not pop its own route after signing out', (tester) async {
    // Home sits on a pushed route, so `canPop()` is true and a manual pop would
    // be possible — and is exactly what must not happen.
    final harness = await pumpHome(tester, pushHomeRoute: true);

    expect(harness.observer.pushedPages, hasLength(2));

    await tester.tap(find.byTooltip('Log out'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Log out'));
    await tester.pumpAndSettle();

    expect(harness.authSessionCubit.logoutCalls, 1);
    // Only the confirmation dialog is allowed to pop; the page itself leaves
    // navigation to the app-level auth state.
    expect(harness.observer.poppedPages, isEmpty);
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('does not overflow on a small phone or a wide window',
      (tester) async {
    await pumpHome(tester, size: const Size(320, 568));
    expect(tester.takeException(), isNull);

    await pumpHome(tester, size: const Size(1280, 800), theme: AppTheme.dark);
    expect(tester.takeException(), isNull);
  });
}

class _HomeHarness {
  const _HomeHarness({
    required this.storage,
    required this.authSessionCubit,
    required this.observer,
  });

  final _FakeSecureStorageService storage;
  final _RecordingAuthSessionCubit authSessionCubit;
  final _RecordingNavigatorObserver observer;
}

/// The real session cubit with a counter, so the tests can assert that the
/// screen asked *it* to sign out instead of navigating on its own.
class _RecordingAuthSessionCubit extends AuthSessionCubit {
  _RecordingAuthSessionCubit({required super.secureStorageService});

  int logoutCalls = 0;

  @override
  Future<void> logout() async {
    logoutCalls++;
    await super.logout();
  }
}

/// Records page-level navigation so a manual `pop` in the screen would fail
/// these tests. Dialog routes are tracked separately: dismissing the
/// confirmation dialog is not page navigation.
class _RecordingNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushed = <Route<dynamic>>[];
  final List<Route<dynamic>> popped = <Route<dynamic>>[];

  Iterable<MaterialPageRoute<dynamic>> get pushedPages =>
      pushed.whereType<MaterialPageRoute<dynamic>>();

  Iterable<MaterialPageRoute<dynamic>> get poppedPages =>
      popped.whereType<MaterialPageRoute<dynamic>>();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popped.add(route);
    super.didPop(route, previousRoute);
  }
}

class _FakeSecureStorageService extends SecureStorageService {
  _FakeSecureStorageService({this.userName, this.failRead = false})
      : super(const FlutterSecureStorage());

  String? userName;
  bool failRead;
  bool clearCalled = false;

  @override
  Future<String?> getUserName() async {
    if (failRead) {
      throw StateError('Injected storage failure');
    }
    return userName;
  }

  @override
  Future<void> clearAuthData() async {
    clearCalled = true;
  }
}

/// Holds the profile read open so the loading state can be observed.
class _BlockingSecureStorageService extends SecureStorageService {
  _BlockingSecureStorageService() : super(const FlutterSecureStorage());

  final Completer<void> _gate = Completer<void>();

  void release() => _gate.complete();

  @override
  Future<String?> getUserName() async {
    await _gate.future;
    return 'Malak';
  }
}
