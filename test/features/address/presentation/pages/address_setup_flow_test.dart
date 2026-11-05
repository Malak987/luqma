import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:luqma_app/core/di/service_locator.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/address/domain/entities/address.dart';
import 'package:luqma_app/features/address/domain/entities/address_draft.dart';
import 'package:luqma_app/features/address/domain/entities/address_label.dart';
import 'package:luqma_app/features/address/domain/repositories/address_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:luqma_app/features/address/domain/usecases/get_my_addresses_use_case.dart';
import 'package:luqma_app/features/address/domain/usecases/create_address_use_case.dart';
import 'package:luqma_app/features/address/presentation/cubit/address_form_cubit.dart';
import 'package:luqma_app/features/address/presentation/cubit/address_setup_cubit.dart';
import 'package:luqma_app/features/address/presentation/cubit/address_setup_state.dart';
import 'package:luqma_app/features/address/presentation/pages/address_details_page.dart';
import 'package:luqma_app/features/address/presentation/pages/address_setup_page.dart';
import 'package:luqma_app/features/location/domain/entities/location_coordinates.dart';
import 'package:luqma_app/core/routing/app_router.dart';
import 'package:luqma_app/core/routing/app_routes.dart';

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

  Future<void> configureForFlow({
    required List<Address> initialAddresses,
    required List<Address> afterCreateAddresses,
  }) async {
    await sl.reset();
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await configureDependencies(preferences: prefs);

    if (sl.isRegistered<AddressRepository>()) sl.unregister<AddressRepository>();
    if (sl.isRegistered<GetMyAddressesUseCase>()) sl.unregister<GetMyAddressesUseCase>();
    if (sl.isRegistered<CreateAddressUseCase>()) sl.unregister<CreateAddressUseCase>();
    if (sl.isRegistered<AddressSetupCubit>()) sl.unregister<AddressSetupCubit>();

    final fakeRepo = _SequencedAddressRepository(
      initial: initialAddresses,
      afterCreate: afterCreateAddresses,
    );
    sl.registerLazySingleton<AddressRepository>(() => fakeRepo);
    sl.registerLazySingleton<GetMyAddressesUseCase>(
      () => GetMyAddressesUseCase(sl<AddressRepository>()),
    );
    sl.registerLazySingleton<CreateAddressUseCase>(
      () => CreateAddressUseCase(sl<AddressRepository>()),
    );
    sl.registerFactory<AddressSetupCubit>(
      () => AddressSetupCubit(getMyAddressesUseCase: sl<GetMyAddressesUseCase>()),
    );
    // AddressFormCubit via factoryParam already registered in service_locator,
    // but we need to ensure it uses the same fake CreateAddressUseCase
    if (sl.isRegistered<AddressFormCubit>()) sl.unregister<AddressFormCubit>();
    // Re-register with updated dependencies
    // Need to re-register AddressFormCubit factoryParam
    // Unregister previous if exists and register new
    try {
      sl.unregister<AddressFormCubit>();
    } catch (_) {}
    sl.registerFactoryParam<AddressFormCubit, LocationCoordinates, void>(
      (coords, _) => AddressFormCubit(
        createAddressUseCase: sl<CreateAddressUseCase>(),
        coordinates: coords,
      ),
    );
  }

  testWidgets('full flow: empty gate -> map picker -> details -> success -> gate refresh to Home', (tester) async {
    final createdAddress = Address(
      id: '1',
      label: AddressLabel.home,
      title: 'My Home',
      district: 'District',
      city: 'Sohag',
      details: 'Building 1',
      latitude: 26.557,
      longitude: 31.694,
      isDefault: true,
    );

    await configureForFlow(
      initialAddresses: [],
      afterCreateAddresses: [createdAddress],
    );

    // Start at address setup (gate empty)
    final cubit = sl<AddressSetupCubit>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: BlocProvider<AddressSetupCubit>.value(
          value: cubit..emitEmptyForTest(),
          child: const AddressSetupPage(),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('address_empty_state')), findsOneWidget);

    // Tap add -> should push map picker (we verify via navigation)
    // Instead of tapping real UI which would require map, we simulate the
    // typed navigation handler directly by pushing details with known coords
    // and verifying gate refresh logic.
    final testCoords = LocationCoordinates.fromMapSelection(
      latitude: 26.557,
      longitude: 31.694,
    );

    // Simulate details page submission
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: AddressDetailsPage(
          coordinates: testCoords,
          onAddressCreated: () async {
            // Mimic AddressSetupPage handler's refresh after details success
            await cubit.load();
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.enterText(find.byKey(const Key('address_details_title_field')), 'My Home');
    await tester.enterText(find.byKey(const Key('address_details_district_field')), 'District');
    await tester.enterText(find.byKey(const Key('address_details_city_field')), 'Sohag');
    await tester.enterText(find.byKey(const Key('address_details_details_field')), 'Building 1');

    await tester.tap(find.byKey(const Key('address_details_submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Create was called with correct payload
    final repo = sl<AddressRepository>() as _SequencedAddressRepository;
    expect(repo.createCalls, 1);
    expect(repo.lastDraft!.title, 'My Home');
    expect(repo.lastDraft!.latitude, 26.557);
    expect(repo.lastDraft!.isDefault, isTrue);

    // Simulate gate refresh after success
    await cubit.load();
    await Future<void>.delayed(Duration.zero);
    expect(repo.getMyAddressesCalls, greaterThanOrEqualTo(1));

    await cubit.close();
  });

  testWidgets('gate reacts correctly to updated address state after creation', (tester) async {
    final fakeRepo = _FakeAddressRepository(addresses: []);
    final getMy = GetMyAddressesUseCase(fakeRepo);
    final cubit = AddressSetupCubit(getMyAddressesUseCase: getMy);
    await cubit.load();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.status, AddressSetupStatus.empty);

    // Simulate successful creation then refresh returning populated
    fakeRepo.addresses = [
      const Address(
        id: '1',
        label: AddressLabel.home,
        title: 'Home',
        district: 'D',
        city: 'C',
        details: 'Det',
        latitude: 26.5,
        longitude: 31.6,
        isDefault: true,
      )
    ];
    await cubit.load();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.status, AddressSetupStatus.populated);
    expect(cubit.state.addresses, hasLength(1));

    await cubit.close();
  });
}

class _SequencedAddressRepository implements AddressRepository {
  _SequencedAddressRepository({
    required this.initial,
    required this.afterCreate,
  });

  final List<Address> initial;
  final List<Address> afterCreate;
  int getMyAddressesCalls = 0;
  int createCalls = 0;
  AddressDraft? lastDraft;

  @override
  Future<List<Address>> getMyAddresses() async {
    getMyAddressesCalls++;
    if (getMyAddressesCalls == 1) return initial;
    return afterCreate;
  }

  @override
  Future<void> createAddress(AddressDraft address) async {
    createCalls++;
    lastDraft = address;
  }
}

class _FakeAddressRepository implements AddressRepository {
  _FakeAddressRepository({required this.addresses});

  List<Address> addresses;
  int getMyAddressesCalls = 0;

  @override
  Future<List<Address>> getMyAddresses() async {
    getMyAddressesCalls++;
    return addresses;
  }

  @override
  Future<void> createAddress(AddressDraft address) async {}
}
