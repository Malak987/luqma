import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/di/service_locator.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/address/domain/entities/address.dart';
import 'package:luqma_app/features/address/domain/entities/address_label.dart';
import 'package:luqma_app/features/address/domain/repositories/address_repository.dart';
import 'package:luqma_app/features/address/domain/usecases/get_my_addresses_use_case.dart';
import 'package:luqma_app/features/address/presentation/cubit/address_setup_cubit.dart';
import 'package:luqma_app/features/address/presentation/cubit/address_setup_state.dart';
import 'package:luqma_app/core/routing/app_router.dart';
import 'package:luqma_app/core/routing/app_routes.dart';
import 'package:luqma_app/features/address/presentation/pages/address_setup_page.dart';
import 'package:luqma_app/features/address/presentation/pages/address_gate.dart';
import 'package:luqma_app/features/home/presentation/pages/home_page.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await sl.reset();
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await configureDependencies(preferences: prefs);
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget _wrapWithCubit(Widget child, AddressSetupCubit cubit) {
    return MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: BlocProvider<AddressSetupCubit>.value(
        value: cubit,
        child: child,
      ),
    );
  }

  group('AddressSetupPage states', () {
    testWidgets('shows loading indicator while loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AddressSetupContent(
              state: AddressSetupState(status: AddressSetupStatus.loading),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('address_setup_loading')), findsOneWidget);
    });

    testWidgets('shows empty state with add button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(
            body: AddressSetupContent(
              state: AddressSetupState(status: AddressSetupStatus.empty),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('address_empty_state')), findsOneWidget);
      expect(find.byKey(const Key('address_add_button')), findsOneWidget);
      expect(find.text('No saved addresses'), findsOneWidget);
    });

    testWidgets('shows populated state with list', (tester) async {
      final address = _address();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: AddressSetupContent(
              state: AddressSetupState(
                status: AddressSetupStatus.populated,
                addresses: [address],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('address_populated_state')), findsOneWidget);
      expect(find.byKey(Key('address_tile_${address.id}')), findsOneWidget);
      expect(find.text('Home'), findsWidgets);
    });

    testWidgets('shows error state with retry', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: AddressSetupContent(
              state: AddressSetupState(
                status: AddressSetupStatus.error,
                failure: Failure(FailureCode.network),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('address_error_state')), findsOneWidget);
      expect(find.byKey(const Key('address_retry_button')), findsOneWidget);
      expect(find.text("We couldn't load your addresses"), findsOneWidget);
    });

    testWidgets('retry button calls cubit load', (tester) async {
      int calls = 0;
      final cubit = _CountingCubit(
        addresses: [],
        onCall: () => calls++,
      );
      // Preload error state via cubit that will be used in page
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: BlocProvider<AddressSetupCubit>.value(
            value: cubit..emitErrorForTest(),
            child: const AddressSetupPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('address_retry_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(calls, greaterThanOrEqualTo(1));
      await cubit.close();
    });

    testWidgets('add address navigates to map picker integration point',
        (tester) async {
      final cubit = AddressSetupCubit(
        getMyAddressesUseCase: _FakeUseCase(addresses: []),
      );

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: BlocProvider<AddressSetupCubit>.value(
          value: cubit..emitEmptyForTest(),
          child: const AddressSetupPage(),
        ),
      ));
      await tester.pump();

      await tester.tap(find.byKey(const Key('address_add_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('map_picker_page')), findsOneWidget);
      // Also ensure legacy placeholder no longer required — real picker is integration point
      expect(find.byKey(const Key('map_picker_placeholder')), findsNothing);
      await cubit.close();
    });

    testWidgets('supports Arabic locale and RTL', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('ar'),
          home: Scaffold(
            body: AddressSetupContent(
              state: AddressSetupState(status: AddressSetupStatus.empty),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('لا يوجد عنوان محفوظ'), findsOneWidget);
      expect(find.text('إضافة عنوان'), findsOneWidget);
    });

    testWidgets('supports dark theme without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: Scaffold(
            body: AddressSetupContent(
              state: AddressSetupState(status: AddressSetupStatus.empty),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('AuthenticatedAddressGate (real gate)', () {
    Future<void> configureGateWithFake({
      required List<Address> addresses,
      Exception? exception,
      Duration delay = Duration.zero,
    }) async {
      await sl.reset();
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await configureDependencies(preferences: prefs);

      // Override AddressRepository with controllable fake
      if (sl.isRegistered<AddressRepository>()) sl.unregister<AddressRepository>();
      if (sl.isRegistered<GetMyAddressesUseCase>()) {
        sl.unregister<GetMyAddressesUseCase>();
      }
      if (sl.isRegistered<AddressSetupCubit>()) sl.unregister<AddressSetupCubit>();

      final fakeRepo = _FakeAddressRepository(
        addresses: addresses,
        exception: exception,
        delay: delay,
      );
      sl.registerLazySingleton<AddressRepository>(() => fakeRepo);
      sl.registerLazySingleton<GetMyAddressesUseCase>(
        () => GetMyAddressesUseCase(sl<AddressRepository>()),
      );
      sl.registerFactory<AddressSetupCubit>(
        () => AddressSetupCubit(
          getMyAddressesUseCase: sl<GetMyAddressesUseCase>(),
        ),
      );
    }

    Future<void> configureGateWithCompleter(
      Completer<List<Address>> completer,
    ) async {
      await sl.reset();
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await configureDependencies(preferences: prefs);

      if (sl.isRegistered<AddressRepository>()) sl.unregister<AddressRepository>();
      if (sl.isRegistered<GetMyAddressesUseCase>()) {
        sl.unregister<GetMyAddressesUseCase>();
      }
      if (sl.isRegistered<AddressSetupCubit>()) sl.unregister<AddressSetupCubit>();

      final fakeRepo = _CompleterAddressRepository(completer);
      sl.registerLazySingleton<AddressRepository>(() => fakeRepo);
      sl.registerLazySingleton<GetMyAddressesUseCase>(
        () => GetMyAddressesUseCase(sl<AddressRepository>()),
      );
      sl.registerFactory<AddressSetupCubit>(
        () => AddressSetupCubit(
          getMyAddressesUseCase: sl<GetMyAddressesUseCase>(),
        ),
      );
    }

    testWidgets('while pending, HomePage is not visible', (tester) async {
      // Use Completer-controlled fake for deterministic pending state.
      final completer = Completer<List<Address>>();
      await configureGateWithCompleter(completer);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AuthenticatedAddressGate(),
        ),
      );

      await tester.pump(); // create() calls load() -> loading state
      expect(find.byKey(const Key('address_gate_loading')), findsOneWidget);
      expect(find.byType(AddressSetupPage), findsNothing);
      expect(find.text('Welcome back'), findsNothing);

      // Complete to avoid dangling future during tearDown
      completer.complete(const <Address>[]);
      await tester.pump(const Duration(milliseconds: 50));
      await sl.reset();
    });

    testWidgets('empty successful response displays AddressSetupPage', (tester) async {
      await configureGateWithFake(addresses: []);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AuthenticatedAddressGate(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('address_setup_page')), findsOneWidget);
      expect(find.byKey(const Key('address_empty_state')), findsOneWidget);
      expect(find.byType(AddressSetupPage), findsOneWidget);
      // Home must not be shown
      expect(find.text('Welcome back'), findsNothing);

      await sl.reset();
    });

    testWidgets('populated response displays actual HomePage', (tester) async {
      await configureGateWithFake(addresses: [_address()]);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AuthenticatedAddressGate(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Gate resolves to Home; AddressSetupPage must not be shown
      expect(find.byType(AddressSetupPage), findsNothing);
      // HomePage content: greeting and search hint are present even while its
      // own HomeCubit is still loading; the widget itself is rendered.
      expect(find.byType(HomePage), findsOneWidget);

      await sl.reset();
    });

    testWidgets('failed request displays error, never empty or Home', (tester) async {
      await configureGateWithFake(
        addresses: [],
        exception: const FailureException(
          Failure(FailureCode.network, debugMessage: 'offline'),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AuthenticatedAddressGate(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('address_error_state')), findsOneWidget);
      expect(find.byKey(const Key('address_empty_state')), findsNothing);
      expect(find.byType(HomePage), findsNothing);
      expect(find.byType(AddressSetupPage), findsOneWidget);

      await sl.reset();
    });

    testWidgets('retry invokes use case again and updates real gate', (tester) async {
      // First call fails, second succeeds with empty — verify gate updates
      int callCount = 0;
      await sl.reset();
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await configureDependencies(preferences: prefs);
      if (sl.isRegistered<AddressRepository>()) sl.unregister<AddressRepository>();
      if (sl.isRegistered<GetMyAddressesUseCase>()) sl.unregister<GetMyAddressesUseCase>();
      if (sl.isRegistered<AddressSetupCubit>()) sl.unregister<AddressSetupCubit>();

      final togglingRepo = _TogglingAddressRepository(
        onCall: () => callCount++,
      );
      sl.registerLazySingleton<AddressRepository>(() => togglingRepo);
      sl.registerLazySingleton<GetMyAddressesUseCase>(
        () => GetMyAddressesUseCase(sl<AddressRepository>()),
      );
      sl.registerFactory<AddressSetupCubit>(
        () => AddressSetupCubit(getMyAddressesUseCase: sl<GetMyAddressesUseCase>()),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AuthenticatedAddressGate(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Initially error
      expect(find.byKey(const Key('address_error_state')), findsOneWidget);
      expect(callCount, 1);

      // Tap retry — gate's AddressSetupPage retry calls the same cubit
      await tester.tap(find.byKey(const Key('address_retry_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(callCount, 2);
      expect(find.byKey(const Key('address_empty_state')), findsOneWidget);
      expect(find.byKey(const Key('address_error_state')), findsNothing);

      await sl.reset();
    });
  });

  group('AppRouter.home uses AuthenticatedAddressGate', () {
    testWidgets('route does not bypass address check (shows gate loading first)', (tester) async {
      final completer = Completer<List<Address>>();
      await sl.reset();
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await configureDependencies(preferences: prefs);
      if (sl.isRegistered<AddressRepository>()) sl.unregister<AddressRepository>();
      if (sl.isRegistered<GetMyAddressesUseCase>()) sl.unregister<GetMyAddressesUseCase>();
      if (sl.isRegistered<AddressSetupCubit>()) sl.unregister<AddressSetupCubit>();
      sl.registerLazySingleton<AddressRepository>(
        () => _CompleterAddressRepository(completer),
      );
      sl.registerLazySingleton<GetMyAddressesUseCase>(
        () => GetMyAddressesUseCase(sl<AddressRepository>()),
      );
      sl.registerFactory<AddressSetupCubit>(
        () => AddressSetupCubit(getMyAddressesUseCase: sl<GetMyAddressesUseCase>()),
      );

      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          onGenerateRoute: AppRouter.onGenerateRoute,
          initialRoute: AppRoutes.login,
          builder: (context, child) {
            capturedContext = context;
            return child!;
          },
        ),
      );
      // Ensure login route is built and context captured
      await tester.pump();

      // Push home exactly as LoginPage does, using a context under MaterialApp
      AppRouter.pushNamed<void>(capturedContext, AppRoutes.home);
      await tester.pump();

      // Gate loading must be shown, not HomePage directly
      expect(find.byKey(const Key('address_gate_loading')), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);

      // Complete pending request to verify gate resolves to empty setup
      completer.complete(const <Address>[]);
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(AddressSetupPage), findsOneWidget);

      await sl.reset();
    });

    testWidgets('route resolves to HomePage when populated', (tester) async {
      await sl.reset();
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await configureDependencies(preferences: prefs);
      if (sl.isRegistered<AddressRepository>()) sl.unregister<AddressRepository>();
      if (sl.isRegistered<GetMyAddressesUseCase>()) sl.unregister<GetMyAddressesUseCase>();
      if (sl.isRegistered<AddressSetupCubit>()) sl.unregister<AddressSetupCubit>();
      sl.registerLazySingleton<AddressRepository>(
        () => _FakeAddressRepository(addresses: [_address()]),
      );
      sl.registerLazySingleton<GetMyAddressesUseCase>(
        () => GetMyAddressesUseCase(sl<AddressRepository>()),
      );
      sl.registerFactory<AddressSetupCubit>(
        () => AddressSetupCubit(getMyAddressesUseCase: sl<GetMyAddressesUseCase>()),
      );

      late BuildContext capturedContext2;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          onGenerateRoute: AppRouter.onGenerateRoute,
          initialRoute: AppRoutes.login,
          builder: (context, child) {
            capturedContext2 = context;
            return child!;
          },
        ),
      );
      await tester.pump();

      AppRouter.pushNamed<void>(capturedContext2, AppRoutes.home);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(AddressSetupPage), findsNothing);

      await sl.reset();
    });
  });
}

Address _address() => const Address(
      id: '1',
      label: AddressLabel.home,
      title: 'Home',
      district: 'District',
      city: 'Sohag',
      details: 'Building 1',
      latitude: 26.56,
      longitude: 31.69,
      isDefault: true,
    );

class _FakeUseCase implements GetMyAddressesUseCase {
  _FakeUseCase({required this.addresses, this.exception});
  final List<Address> addresses;
  final Exception? exception;
  @override
  Future<List<Address>> call() async {
    if (exception != null) throw exception!;
    return addresses;
  }
}

class _CountingCubit extends AddressSetupCubit {
  _CountingCubit({required List<Address> addresses, required this.onCall})
      : super(
          getMyAddressesUseCase: _FakeUseCase(addresses: addresses),
        );
  final VoidCallback onCall;

  @override
  Future<void> load() async {
    onCall();
    return super.load();
  }
}

class _FakeAddressRepository implements AddressRepository {
  _FakeAddressRepository({
    required this.addresses,
    this.exception,
    this.delay = Duration.zero,
  });
  final List<Address> addresses;
  final Exception? exception;
  final Duration delay;
  int calls = 0;
  @override
  Future<void> createAddress(address) async {}
  @override
  Future<List<Address>> getMyAddresses() async {
    calls++;
    if (delay != Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (exception != null) throw exception!;
    return addresses;
  }
}

class _TogglingAddressRepository implements AddressRepository {
  _TogglingAddressRepository({required this.onCall});
  final VoidCallback onCall;
  int _calls = 0;

  @override
  Future<List<Address>> getMyAddresses() async {
    _calls++;
    onCall();
    if (_calls == 1) {
      throw const FailureException(
        Failure(FailureCode.network, debugMessage: 'offline'),
      );
    }
    return const <Address>[];
  }

  @override
  Future<void> createAddress(address) async {}
}

class _CompleterAddressRepository implements AddressRepository {
  _CompleterAddressRepository(this.completer);
  final Completer<List<Address>> completer;

  @override
  Future<List<Address>> getMyAddresses() => completer.future;

  @override
  Future<void> createAddress(address) async {}
}

typedef VoidCallback = void Function();
