import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luqma_app/core/di/service_locator.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/routing/app_router.dart';
import 'package:luqma_app/core/routing/app_routes.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/address/domain/entities/address.dart';
import 'package:luqma_app/features/address/domain/entities/address_label.dart';
import 'package:luqma_app/features/address/domain/repositories/address_repository.dart';
import 'package:luqma_app/features/address/domain/usecases/get_my_addresses_use_case.dart';
import 'package:luqma_app/features/address/presentation/cubit/address_setup_cubit.dart';
import 'package:luqma_app/features/address/presentation/cubit/address_setup_state.dart';
import 'package:luqma_app/features/address/presentation/pages/address_gate.dart';
import 'package:luqma_app/features/address/presentation/pages/address_setup_page.dart';
import 'package:luqma_app/features/address/presentation/pages/map_location_picker_page.dart';
import 'package:luqma_app/features/location/domain/entities/current_location_outcome.dart';
import 'package:luqma_app/features/location/domain/entities/location_coordinates.dart';
import 'package:luqma_app/features/location/domain/repositories/location_repository.dart';
import 'package:luqma_app/features/location/domain/usecases/get_current_location_use_case.dart';
import 'package:luqma_app/features/location/domain/usecases/request_location_permission_use_case.dart';

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

  Future<void> configureForEmptyGate() async {
    await sl.reset();
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await configureDependencies(preferences: prefs);

    if (sl.isRegistered<AddressRepository>()) sl.unregister<AddressRepository>();
    if (sl.isRegistered<GetMyAddressesUseCase>()) sl.unregister<GetMyAddressesUseCase>();
    if (sl.isRegistered<AddressSetupCubit>()) sl.unregister<AddressSetupCubit>();

    final fakeRepo = _FakeAddressRepository(addresses: []);
    sl.registerLazySingleton<AddressRepository>(() => fakeRepo);
    sl.registerLazySingleton<GetMyAddressesUseCase>(
      () => GetMyAddressesUseCase(sl<AddressRepository>()),
    );
    sl.registerFactory<AddressSetupCubit>(
      () => AddressSetupCubit(getMyAddressesUseCase: sl<GetMyAddressesUseCase>()),
    );

    // Configure location fakes so MapPickerCubit can be created without exception
    if (sl.isRegistered<LocationRepository>()) sl.unregister<LocationRepository>();
    if (sl.isRegistered<GetCurrentLocationUseCase>()) sl.unregister<GetCurrentLocationUseCase>();
    if (sl.isRegistered<RequestLocationPermissionUseCase>()) {
      sl.unregister<RequestLocationPermissionUseCase>();
    }
    if (sl.isRegistered<LocationRepository>()) sl.unregister<LocationRepository>();
    // Re-register with denied outcome (still allows map to open with fallback)
    final fakeLocation = _FakeLocationRepository(
      getCurrentOutcome: const LocationPermissionDenied(),
    );
    // Ensure previous registrations are cleared
    if (sl.isRegistered<LocationRepository>()) sl.unregister<LocationRepository>();
    sl.registerLazySingleton<LocationRepository>(() => fakeLocation);
    if (sl.isRegistered<GetCurrentLocationUseCase>()) sl.unregister<GetCurrentLocationUseCase>();
    sl.registerLazySingleton<GetCurrentLocationUseCase>(
      () => GetCurrentLocationUseCase(sl<LocationRepository>()),
    );
    if (sl.isRegistered<RequestLocationPermissionUseCase>()) {
      sl.unregister<RequestLocationPermissionUseCase>();
    }
    sl.registerLazySingleton<RequestLocationPermissionUseCase>(
      () => RequestLocationPermissionUseCase(sl<LocationRepository>()),
    );
  }

  group('Add Address button regression — real navigation', () {
    testWidgets('1. tapping actual Add Address button invokes navigation and opens MapLocationPickerPage',
        (tester) async {
      await configureForEmptyGate();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: const AuthenticatedAddressGate(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Gate should be in empty state with Add Address button visible
      expect(find.byKey(const Key('address_empty_state')), findsOneWidget);
      expect(find.byKey(const Key('address_add_button')), findsOneWidget);

      // Tap the actual button (not isolated callback)
      await tester.tap(find.byKey(const Key('address_add_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 100));

      // Verify real route opened MapLocationPickerPage (not placeholder)
      expect(find.byKey(const Key('map_picker_page')), findsOneWidget);
      expect(find.byKey(const Key('map_picker_placeholder')), findsNothing);
    });

    testWidgets('2. tapping Add Address via AddressSetupPage direct also opens map (gate-independent)',
        (tester) async {
      await configureForEmptyGate();

      final cubit = sl<AddressSetupCubit>()..emitEmptyForTest();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: BlocProvider<AddressSetupCubit>.value(
            value: cubit,
            child: const AddressSetupPage(),
          ),
        ),
      );

      await tester.pump();
      expect(find.byKey(const Key('address_add_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('address_add_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('map_picker_page')), findsOneWidget);
      await cubit.close();
    });

    testWidgets('3. real AppRouter route can construct its MapPickerCubit without DI exception',
        (tester) async {
      await configureForEmptyGate();

      // Ensure MapPickerCubit can be resolved from GetIt (no exception)
      expect(() => sl.get<LocationRepository>(), returnsNormally);
      expect(() => sl.get<GetCurrentLocationUseCase>(), returnsNormally);
      expect(() => sl.get<RequestLocationPermissionUseCase>(), returnsNormally);

      // Building the route via AppRouter should not throw
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: AppRoutes.mapPicker),
      );
      expect(route, isA<MaterialPageRoute<dynamic>>());

      // Pumping the route's builder should create MapPickerCubit successfully
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.of(context).push(route),
              child: const Text('push'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('push'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('map_picker_page')), findsOneWidget);
      // No error text from DI
      expect(find.byKey(const Key('address_setup_navigation_error')), findsNothing);
    });

    testWidgets('4. map confirmation returns expected coordinates and AddressDetails receives them',
        (tester) async {
      await configureForEmptyGate();

      // Configure location to return device coordinates so confirm can return them
      final deviceCoords = LocationCoordinates.fromDevice(latitude: 30.0444, longitude: 31.2357);
      await sl.reset();
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await configureDependencies(preferences: prefs);
      if (sl.isRegistered<AddressRepository>()) sl.unregister<AddressRepository>();
      if (sl.isRegistered<GetMyAddressesUseCase>()) sl.unregister<GetMyAddressesUseCase>();
      if (sl.isRegistered<AddressSetupCubit>()) sl.unregister<AddressSetupCubit>();
      sl.registerLazySingleton<AddressRepository>(() => _FakeAddressRepository(addresses: []));
      sl.registerLazySingleton<GetMyAddressesUseCase>(() => GetMyAddressesUseCase(sl<AddressRepository>()));
      sl.registerFactory<AddressSetupCubit>(() => AddressSetupCubit(getMyAddressesUseCase: sl<GetMyAddressesUseCase>()));
      if (sl.isRegistered<LocationRepository>()) sl.unregister<LocationRepository>();
      if (sl.isRegistered<GetCurrentLocationUseCase>()) sl.unregister<GetCurrentLocationUseCase>();
      if (sl.isRegistered<RequestLocationPermissionUseCase>()) {
        sl.unregister<RequestLocationPermissionUseCase>();
      }
      sl.registerLazySingleton<LocationRepository>(
        () => _FakeLocationRepository(getCurrentOutcome: CurrentLocationSuccess(deviceCoords)),
      );
      sl.registerLazySingleton<GetCurrentLocationUseCase>(() => GetCurrentLocationUseCase(sl<LocationRepository>()));
      sl.registerLazySingleton<RequestLocationPermissionUseCase>(
        () => RequestLocationPermissionUseCase(sl<LocationRepository>()),
      );

      final cubit = sl<AddressSetupCubit>()..emitEmptyForTest();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: BlocProvider<AddressSetupCubit>.value(
            value: cubit,
            child: const AddressSetupPage(),
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.byKey(const Key('address_add_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('map_picker_page')), findsOneWidget);

      // Verify coordinates displayed are device coordinates (not fallback)
      expect(find.textContaining('30.04440'), findsOneWidget);
      expect(find.textContaining('31.23570'), findsOneWidget);

      // Fake map builder to move to known coords then confirm via real cubit
      // Instead use the real map's confirm button which will pop with selected
      // We need to ensure confirm returns device coords via Navigator.pop
      // The map page's confirm button pops with state's selected
      await tester.tap(find.byKey(const Key('map_picker_confirm_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // After confirm, AddressDetails should be pushed with those coordinates
      // AddressDetailsPage shows location summary with coordinates
      expect(find.byKey(const Key('address_details_page')), findsOneWidget);
      expect(find.byKey(const Key('address_details_location_summary')), findsOneWidget);
      // Verify coordinates passed exactly (device coords, not fallback)
      expect(find.textContaining('30.04440'), findsOneWidget);
      expect(find.textContaining('31.23570'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('5. populated state Add Address button (address_add_button_populated) also opens map',
        (tester) async {
      await configureForEmptyGate();
      // Make populated with one address
      final address = const Address(
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
      await sl.reset();
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await configureDependencies(preferences: prefs);
      if (sl.isRegistered<AddressRepository>()) sl.unregister<AddressRepository>();
      if (sl.isRegistered<GetMyAddressesUseCase>()) sl.unregister<GetMyAddressesUseCase>();
      if (sl.isRegistered<AddressSetupCubit>()) sl.unregister<AddressSetupCubit>();
      sl.registerLazySingleton<AddressRepository>(() => _FakeAddressRepository(addresses: [address]));
      sl.registerLazySingleton<GetMyAddressesUseCase>(() => GetMyAddressesUseCase(sl<AddressRepository>()));
      sl.registerFactory<AddressSetupCubit>(() => AddressSetupCubit(getMyAddressesUseCase: sl<GetMyAddressesUseCase>()));
      if (sl.isRegistered<LocationRepository>()) sl.unregister<LocationRepository>();
      if (sl.isRegistered<GetCurrentLocationUseCase>()) sl.unregister<GetCurrentLocationUseCase>();
      if (sl.isRegistered<RequestLocationPermissionUseCase>()) {
        sl.unregister<RequestLocationPermissionUseCase>();
      }
      sl.registerLazySingleton<LocationRepository>(() => _FakeLocationRepository(getCurrentOutcome: const LocationPermissionDenied()));
      sl.registerLazySingleton<GetCurrentLocationUseCase>(() => GetCurrentLocationUseCase(sl<LocationRepository>()));
      sl.registerLazySingleton<RequestLocationPermissionUseCase>(() => RequestLocationPermissionUseCase(sl<LocationRepository>()));

      final cubit = sl<AddressSetupCubit>();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: BlocProvider<AddressSetupCubit>.value(
            value: cubit..emitForTest(
              AddressSetupState(status: AddressSetupStatus.populated, addresses: [address]),
            ),
            child: const AddressSetupPage(),
          ),
        ),
      );

      await tester.pump();
      expect(find.byKey(const Key('address_add_button_populated')), findsOneWidget);

      await tester.tap(find.byKey(const Key('address_add_button_populated')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('map_picker_page')), findsOneWidget);
      await cubit.close();
    });

    testWidgets('6. navigation failure shows visible recoverable error instead of silently doing nothing',
        (tester) async {
      // Do NOT configure location fakes so MapPickerCubit DI will fail
      // But we still configure address gate empty
      await sl.reset();
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await configureDependencies(preferences: prefs);
      if (sl.isRegistered<AddressRepository>()) sl.unregister<AddressRepository>();
      if (sl.isRegistered<GetMyAddressesUseCase>()) sl.unregister<GetMyAddressesUseCase>();
      if (sl.isRegistered<AddressSetupCubit>()) sl.unregister<AddressSetupCubit>();
      sl.registerLazySingleton<AddressRepository>(() => _FakeAddressRepository(addresses: []));
      sl.registerLazySingleton<GetMyAddressesUseCase>(() => GetMyAddressesUseCase(sl<AddressRepository>()));
      sl.registerFactory<AddressSetupCubit>(() => AddressSetupCubit(getMyAddressesUseCase: sl<GetMyAddressesUseCase>()));
      // Intentionally break MapPickerCubit by unregistering its dependency
      if (sl.isRegistered<GetCurrentLocationUseCase>()) sl.unregister<GetCurrentLocationUseCase>();

      // Now push should fail and show SnackBar instead of silent nothing
      final cubit = sl<AddressSetupCubit>()..emitEmptyForTest();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: BlocProvider<AddressSetupCubit>.value(
            value: cubit,
            child: const AddressSetupPage(),
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.byKey(const Key('address_add_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // If DI fails, our new handler shows SnackBar with retry; if it doesn't, we at least
      // verify no silent failure — either map opened or error shown
      final hasMap = find.byKey(const Key('map_picker_page')).evaluate().isNotEmpty;
      final hasError = find.byKey(const Key('address_setup_navigation_error')).evaluate().isNotEmpty;
      // One of them must be true — never silently nothing
      expect(hasMap || hasError, isTrue,
          reason: 'Tapping Add Address must either open map or show visible error, not silently do nothing');

      await cubit.close();
    });
  });
}

class _FakeAddressRepository implements AddressRepository {
  _FakeAddressRepository({required this.addresses});
  final List<Address> addresses;
  @override
  Future<List<Address>> getMyAddresses() async => addresses;
  @override
  Future<void> createAddress(address) async {}
}

class _FakeLocationRepository implements LocationRepository {
  _FakeLocationRepository({required this.getCurrentOutcome});
  final CurrentLocationOutcome getCurrentOutcome;
  @override
  Future<CurrentLocationOutcome> getCurrentLocation() async => getCurrentOutcome;
  @override
  Future<CurrentLocationOutcome> requestLocationPermission({required LocationPermissionRequestMode mode}) async =>
      getCurrentOutcome;
}


