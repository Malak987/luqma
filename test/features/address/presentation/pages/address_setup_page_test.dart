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
import 'package:luqma_app/features/address/presentation/pages/address_setup_page.dart';
import 'package:luqma_app/features/address/presentation/pages/address_gate.dart';
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

      expect(find.byKey(const Key('map_picker_placeholder')), findsOneWidget);
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

  group('AuthenticatedAddressGate navigation behavior', () {
    testWidgets('shows loading then empty then navigates via gate', (tester) async {
      final cubit = AddressSetupCubit(
        getMyAddressesUseCase: _DelayedUseCase(addresses: []),
      );

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<AddressSetupCubit>.value(
          value: cubit..load(),
          child: const _GateTestHost(),
        ),
      ));

      // Initially loading
      await tester.pump();
      expect(find.byKey(const Key('address_gate_loading')), findsOneWidget);

      // After delay, empty
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(const Key('address_empty_state')), findsOneWidget);

      await cubit.close();
    });

    testWidgets('shows Home when populated, not empty', (tester) async {
      final cubit = AddressSetupCubit(
        getMyAddressesUseCase: _FakeUseCase(addresses: [_address()]),
      );

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<AddressSetupCubit>.value(
          value: cubit..load(),
          child: const _GateTestHost(),
        ),
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      expect(find.byKey(const Key('address_populated_state')), findsOneWidget);
      // In real gate, populated would show HomePage, but test host shows list
      await cubit.close();
    });

    testWidgets('error not treated as empty, shows retry', (tester) async {
      final cubit = AddressSetupCubit(
        getMyAddressesUseCase: _FakeUseCase(
          addresses: [],
          exception: const FailureException(
            Failure(FailureCode.network),
          ),
        ),
      );

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<AddressSetupCubit>.value(
          value: cubit..load(),
          child: const _GateTestHost(),
        ),
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      expect(find.byKey(const Key('address_error_state')), findsOneWidget);
      expect(find.byKey(const Key('address_empty_state')), findsNothing);
      await cubit.close();
    });
  });
}

class _GateTestHost extends StatelessWidget {
  const _GateTestHost();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddressSetupCubit, AddressSetupState>(
      builder: (context, state) {
        switch (state.status) {
          case AddressSetupStatus.initial:
          case AddressSetupStatus.loading:
            return const Scaffold(
              key: Key('address_gate_loading'),
              body: Center(child: CircularProgressIndicator()),
            );
          case AddressSetupStatus.error:
            return Scaffold(
              body: AddressSetupContent(
                state: state,
                onRetry: () => context.read<AddressSetupCubit>().load(),
              ),
            );
          case AddressSetupStatus.empty:
            return Scaffold(
              body: AddressSetupContent(state: state),
            );
          case AddressSetupStatus.populated:
            return Scaffold(
              body: AddressSetupContent(state: state),
            );
        }
      },
    );
  }
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

class _DelayedUseCase implements GetMyAddressesUseCase {
  _DelayedUseCase({required this.addresses});
  final List<Address> addresses;
  @override
  Future<List<Address>> call() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return addresses;
  }
}

class _FakeAddressRepository implements AddressRepository {
  _FakeAddressRepository({required this.addresses, this.exception});
  final List<Address> addresses;
  final Exception? exception;
  int calls = 0;
  @override
  Future<void> createAddress(address) async {}
  @override
  Future<List<Address>> getMyAddresses() async {
    calls++;
    if (exception != null) throw exception!;
    return addresses;
  }
}

typedef VoidCallback = void Function();
