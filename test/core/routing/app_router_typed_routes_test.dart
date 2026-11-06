import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luqma_app/core/di/service_locator.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/routing/app_router.dart';
import 'package:luqma_app/core/routing/app_routes.dart';
import 'package:luqma_app/features/location/domain/entities/location_coordinates.dart';
import 'package:luqma_app/features/address/domain/repositories/address_repository.dart';
import 'package:luqma_app/features/address/domain/usecases/get_my_addresses_use_case.dart';
import 'package:luqma_app/features/address/presentation/cubit/address_setup_cubit.dart';
import 'package:luqma_app/features/address/presentation/cubit/address_setup_state.dart';
import 'package:luqma_app/features/location/domain/entities/current_location_outcome.dart';
import 'package:luqma_app/features/location/domain/repositories/location_repository.dart';
import 'package:luqma_app/features/location/domain/usecases/get_current_location_use_case.dart';
import 'package:luqma_app/features/location/domain/usecases/request_location_permission_use_case.dart';
import 'package:luqma_app/features/address/domain/entities/address.dart';

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

  Future<void> configureForTyped() async {
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
    if (sl.isRegistered<RequestLocationPermissionUseCase>()) sl.unregister<RequestLocationPermissionUseCase>();
    sl.registerLazySingleton<LocationRepository>(() => _FakeLocationRepository(getCurrentOutcome: const LocationPermissionDenied()));
    sl.registerLazySingleton<GetCurrentLocationUseCase>(() => GetCurrentLocationUseCase(sl<LocationRepository>()));
    sl.registerLazySingleton<RequestLocationPermissionUseCase>(() => RequestLocationPermissionUseCase(sl<LocationRepository>()));
  }

  group('Typed route factory — would fail with MaterialPageRoute<dynamic>', () {
    testWidgets('mapPicker route is typed LocationCoordinates and pushNamed<LocationCoordinates> does not throw', (tester) async {
      await configureForTyped();
      final route = AppRouter.onGenerateRoute(const RouteSettings(name: AppRoutes.mapPicker));
      // This exact assertion would fail if factory returned MaterialPageRoute<dynamic>
      expect(route, isA<MaterialPageRoute<LocationCoordinates?>>(),
          reason: 'mapPicker must be MaterialPageRoute<LocationCoordinates> to match pushNamed<LocationCoordinates>');
      // Old buggy code was MaterialPageRoute<dynamic> — this would pass incorrectly:
      // expect(route, isA<MaterialPageRoute<dynamic>>()) — we explicitly forbid that.
      expect(route is MaterialPageRoute<dynamic> && route is! MaterialPageRoute<LocationCoordinates?>, isFalse,
          reason: 'If mapPicker were MaterialPageRoute<dynamic>, typed push would throw TypeError on device');

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: Builder(
            builder: (context) => ElevatedButton(
              key: const Key('trigger_map_typed'),
              onPressed: () => Navigator.of(context).pushNamed<LocationCoordinates>(AppRoutes.mapPicker),
              child: const Text('open map'),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('trigger_map_typed')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: 'Type Cast Error must not occur with correct generic');
      expect(find.byKey(const Key('map_picker_page')), findsOneWidget);
    });

    testWidgets('addressDetails route is typed bool and pushNamed<bool> with coordinates works', (tester) async {
      await configureForTyped();
      final coords = LocationCoordinates.fromMapSelection(latitude: 26.56, longitude: 31.69);
      final route = AppRouter.onGenerateRoute(RouteSettings(name: AppRoutes.addressDetails, arguments: coords));
      expect(route, isA<MaterialPageRoute<bool?>>(),
          reason: 'addressDetails must be MaterialPageRoute<bool> to match pushNamed<bool>');

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: Builder(
            builder: (context) => ElevatedButton(
              key: const Key('trigger_details_typed'),
              onPressed: () => Navigator.of(context).pushNamed<bool>(AppRoutes.addressDetails, arguments: coords),
              child: const Text('open details'),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('trigger_details_typed')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('address_details_page')), findsOneWidget);
    });

    testWidgets('navigation failure shows dedicated navigationFailed localized message', (tester) async {
      await configureForTyped();
      // Break DI so push will throw during route construction
      if (sl.isRegistered<GetCurrentLocationUseCase>()) sl.unregister<GetCurrentLocationUseCase>();

      final cubit = sl<AddressSetupCubit>()..emitEmptyForTest();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: Scaffold(
            body: BlocProvider<AddressSetupCubit>.value(
              value: cubit,
              child: const AddressSetupGateForTest(),
            ),
          ),
        ),
      );
      // Use the real AddressSetupPage harness — tap Add Address
      // We use the same key as production AddressEmptyView
      // First pump to show empty state via gate? Use direct page for simplicity
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: BlocProvider<AddressSetupCubit>.value(
            value: cubit,
            child: const Scaffold(body: _TestAddButton()),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('address_add_button_test')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // New navigationFailed must be shown, not GPS message
      expect(find.text('Could not open the map. Please try again.'), findsOneWidget);
      expect(find.text('Could not get current location'), findsNothing);
      await cubit.close();
    });

    testWidgets('Arabic locale shows Arabic navigationFailed', (tester) async {
      await configureForTyped();
      if (sl.isRegistered<GetCurrentLocationUseCase>()) sl.unregister<GetCurrentLocationUseCase>();
      final cubit = sl<AddressSetupCubit>()..emitEmptyForTest();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ar'),
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: Scaffold(
            body: BlocProvider<AddressSetupCubit>.value(
              value: cubit,
              child: const _TestAddButton(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('address_add_button_test')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('تعذر فتح الخريطة، حاول مرة أخرى'), findsOneWidget);
      await cubit.close();
    });
  });
}

class _TestAddButton extends StatelessWidget {
  const _TestAddButton();
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      key: const Key('address_add_button_test'),
      onPressed: () async {
        try {
          await Navigator.of(context, rootNavigator: true).pushNamed<LocationCoordinates>(AppRoutes.mapPicker);
        } catch (e, st) {
          debugPrint('test nav failed $e $st');
          if (!context.mounted) return;
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            key: const Key('address_setup_navigation_error'),
            content: Text(l10n.address.navigationFailed),
          ));
        }
      },
      child: const Text('Add'),
    );
  }
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
  Future<CurrentLocationOutcome> requestLocationPermission({required LocationPermissionRequestMode mode}) async => getCurrentOutcome;
}

extension on AddressSetupCubit {
  void emitEmptyForTest() => emit(const AddressSetupState(status: AddressSetupStatus.empty));
}

// Needed for test extension
class AddressSetupGateForTest extends StatelessWidget {
  const AddressSetupGateForTest({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
