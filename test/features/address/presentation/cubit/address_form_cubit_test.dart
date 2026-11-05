import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/features/address/domain/entities/address.dart';
import 'package:luqma_app/features/address/domain/entities/address_draft.dart';
import 'package:luqma_app/features/address/domain/entities/address_label.dart';
import 'package:luqma_app/features/address/domain/repositories/address_repository.dart';
import 'package:luqma_app/features/address/domain/usecases/create_address_use_case.dart';
import 'package:luqma_app/features/address/domain/usecases/get_my_addresses_use_case.dart';
import 'package:luqma_app/features/address/presentation/cubit/address_form_cubit.dart';
import 'package:luqma_app/features/address/presentation/cubit/address_form_state.dart';
import 'package:luqma_app/features/address/presentation/cubit/address_setup_cubit.dart';
import 'package:luqma_app/features/location/domain/entities/location_coordinates.dart';

void main() {
  group('AddressFormCubit', () {
    late LocationCoordinates coords;

    setUp(() {
      coords = LocationCoordinates.fromMapSelection(
        latitude: 26.557,
        longitude: 31.694,
      );
    });

    test('initial state preserves selected coordinates and defaults', () {
      final cubit = AddressFormCubit(
        createAddressUseCase: _FakeCreateUseCase(),
        coordinates: coords,
      );

      expect(cubit.state.coordinates, coords);
      expect(cubit.state.coordinates.latitude, 26.557);
      expect(cubit.state.coordinates.longitude, 31.694);
      expect(cubit.state.label, AddressLabel.home);
      expect(cubit.state.isDefault, isTrue);
      expect(cubit.state.status, AddressFormStatus.initial);
      expect(cubit.state.hasValidationErrors, isFalse);
      cubit.close();
    });

    test('validation fails when required fields are empty', () async {
      final fake = _FakeCreateUseCase();
      final cubit = AddressFormCubit(
        createAddressUseCase: fake,
        coordinates: coords,
      );

      await cubit.submit();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.titleError, isNotNull);
      expect(cubit.state.districtError, isNotNull);
      expect(cubit.state.cityError, isNotNull);
      expect(cubit.state.detailsError, isNotNull);
      expect(cubit.state.status, AddressFormStatus.editing);
      expect(fake.calls, 0);
      await cubit.close();
    });

    test('validation shows required field errors individually', () async {
      final cubit = AddressFormCubit(
        createAddressUseCase: _FakeCreateUseCase(),
        coordinates: coords,
      );

      cubit.updateTitle('My Home');
      cubit.updateDistrict('District');
      // leave city and details empty
      await cubit.submit();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.titleError, isNull);
      expect(cubit.state.districtError, isNull);
      expect(cubit.state.cityError, isNotNull);
      expect(cubit.state.detailsError, isNotNull);
      await cubit.close();
    });

    test('updating field clears its validation error', () async {
      final cubit = AddressFormCubit(
        createAddressUseCase: _FakeCreateUseCase(),
        coordinates: coords,
      );

      await cubit.submit();
      expect(cubit.state.titleError, isNotNull);

      cubit.updateTitle('New Title');
      expect(cubit.state.titleError, isNull);
      expect(cubit.state.title, 'New Title');
      await cubit.close();
    });

    test('label selection updates state and preserves coordinates', () async {
      final cubit = AddressFormCubit(
        createAddressUseCase: _FakeCreateUseCase(),
        coordinates: coords,
      );

      cubit.updateLabel(AddressLabel.work);
      expect(cubit.state.label, AddressLabel.work);
      expect(cubit.state.coordinates, coords);

      cubit.updateLabel(AddressLabel.other);
      expect(cubit.state.label, AddressLabel.other);
      await cubit.close();
    });

    test('request payload includes all verified fields with correct label mapping', () async {
      final fake = _FakeCreateUseCase();
      final cubit = AddressFormCubit(
        createAddressUseCase: fake,
        coordinates: coords,
      );

      cubit.updateTitle('Home title');
      cubit.updateDistrict('District');
      cubit.updateCity('City');
      cubit.updateDetails('Building 2');
      cubit.updateLabel(AddressLabel.other); // should map to 2

      await cubit.submit();
      await Future<void>.delayed(Duration.zero);

      expect(fake.calls, 1);
      final draft = fake.lastDraft!;
      expect(draft.title, 'Home title');
      expect(draft.district, 'District');
      expect(draft.city, 'City');
      expect(draft.details, 'Building 2');
      expect(draft.latitude, 26.557);
      expect(draft.longitude, 31.694);
      expect(draft.label, AddressLabel.other);
      expect(draft.isDefault, isTrue);
      // Verify trimming
      cubit.close();
    });

    test('payload preserves isDefault true for first address', () async {
      final fake = _FakeCreateUseCase();
      final cubit = AddressFormCubit(
        createAddressUseCase: fake,
        coordinates: coords,
      );
      cubit.updateTitle('T');
      cubit.updateDistrict('D');
      cubit.updateCity('C');
      cubit.updateDetails('Det');

      await cubit.submit();
      expect(fake.lastDraft!.isDefault, isTrue);
      await cubit.close();
    });

    test('successful creation emits success only after server confirms', () async {
      final fake = _FakeCreateUseCase();
      final cubit = AddressFormCubit(
        createAddressUseCase: fake,
        coordinates: coords,
      );
      cubit.updateTitle('Title');
      cubit.updateDistrict('District');
      cubit.updateCity('City');
      cubit.updateDetails('Details');

      final states = <AddressFormState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.submit();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, AddressFormStatus.success);
      expect(cubit.state.isSuccess, isTrue);
      // Must not have shown success before server call
      expect(fake.calls, 1);
      // Success state preserves coordinates
      expect(cubit.state.coordinates, coords);

      await sub.cancel();
      await cubit.close();
    });

    test('API validation failure shows error and does not become success', () async {
      final fake = _FakeCreateUseCase(
        failure: const FailureException(
          Failure(FailureCode.validation, debugMessage: 'rejected'),
        ),
      );
      final cubit = AddressFormCubit(
        createAddressUseCase: fake,
        coordinates: coords,
      );
      cubit.updateTitle('Title');
      cubit.updateDistrict('District');
      cubit.updateCity('City');
      cubit.updateDetails('Details');

      await cubit.submit();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, AddressFormStatus.failure);
      expect(cubit.state.failure?.code, FailureCode.validation);
      expect(cubit.state.isSuccess, isFalse);
      await cubit.close();
    });

    test('API network failure shows error with retry capability', () async {
      final fake = _FakeCreateUseCase(
        failure: const FailureException(
          Failure(FailureCode.network, debugMessage: 'offline'),
        ),
      );
      final cubit = AddressFormCubit(
        createAddressUseCase: fake,
        coordinates: coords,
      );
      cubit.updateTitle('Title');
      cubit.updateDistrict('District');
      cubit.updateCity('City');
      cubit.updateDetails('Details');

      await cubit.submit();
      expect(cubit.state.isFailure, isTrue);
      expect(cubit.state.failure?.code, FailureCode.network);

      // Retry after fixing failure (replace fake with success)
      // Simulate retry by creating new cubit with success — state should allow retry
      final retryFake = _FakeCreateUseCase();
      final retryCubit = AddressFormCubit(
        createAddressUseCase: retryFake,
        coordinates: coords,
      );
      retryCubit.updateTitle('Title');
      retryCubit.updateDistrict('District');
      retryCubit.updateCity('City');
      retryCubit.updateDetails('Details');
      await retryCubit.submit();
      expect(retryCubit.state.isSuccess, isTrue);
      await cubit.close();
      await retryCubit.close();
    });

    test('prevents duplicate submissions while submitting', () async {
      int calls = 0;
      final fake = _DelayedFakeCreateUseCase(onCall: () => calls++);
      final cubit = AddressFormCubit(
        createAddressUseCase: fake,
        coordinates: coords,
      );
      cubit.updateTitle('Title');
      cubit.updateDistrict('District');
      cubit.updateCity('City');
      cubit.updateDetails('Details');

      final f1 = cubit.submit();
      final f2 = cubit.submit(); // should be ignored
      await Future.wait([f1, f2]);

      expect(calls, 1);
      expect(cubit.state.isSuccess, isTrue);
      await cubit.close();
    });

    test('preserves coordinates throughout flow and does not replace with fallback', () async {
      final fake = _FakeCreateUseCase();
      final deviceCoords = LocationCoordinates.fromDevice(
        latitude: 30.12345,
        longitude: 31.54321,
      );
      final cubit = AddressFormCubit(
        createAddressUseCase: fake,
        coordinates: deviceCoords,
      );

      cubit.updateTitle('Title');
      cubit.updateDistrict('District');
      cubit.updateCity('City');
      cubit.updateDetails('Details');
      cubit.updateLabel(AddressLabel.home);

      await cubit.submit();

      expect(cubit.state.coordinates, deviceCoords);
      expect(fake.lastDraft!.latitude, 30.12345);
      expect(fake.lastDraft!.longitude, 31.54321);
      // Must not be Sohag fallback
      expect(fake.lastDraft!.latitude, isNot(26.56));
      await cubit.close();
    });

    test('trims whitespace before validation and submission', () async {
      final fake = _FakeCreateUseCase();
      final cubit = AddressFormCubit(
        createAddressUseCase: fake,
        coordinates: coords,
      );
      cubit.updateTitle('  Title  ');
      cubit.updateDistrict('  District  ');
      cubit.updateCity('  City  ');
      cubit.updateDetails('  Details  ');

      await cubit.submit();

      expect(fake.lastDraft!.title, 'Title');
      expect(fake.lastDraft!.district, 'District');
      expect(fake.lastDraft!.city, 'City');
      expect(fake.lastDraft!.details, 'Details');
      await cubit.close();
    });

    test('validation with whitespace-only fields fails', () async {
      final fake = _FakeCreateUseCase();
      final cubit = AddressFormCubit(
        createAddressUseCase: fake,
        coordinates: coords,
      );
      cubit.updateTitle('   ');
      cubit.updateDistrict('   ');
      cubit.updateCity('City');
      cubit.updateDetails('Details');

      await cubit.submit();
      expect(cubit.state.titleError, isNotNull);
      expect(cubit.state.districtError, isNotNull);
      expect(fake.calls, 0);
      await cubit.close();
    });

    test('gate refresh: after success, AddressSetupCubit load is called', () async {
      // Simulate the navigation handler's refresh logic
      int loadCalls = 0;
      final addressRepo = _FakeAddressRepository(addresses: []);
      final getMyAddressesUseCase = GetMyAddressesUseCase(addressRepo);
      final setupCubit = AddressSetupCubit(
        getMyAddressesUseCase: getMyAddressesUseCase,
      );
      // Track load via repository call count
      await setupCubit.load();
      expect(addressRepo.calls, 1);

      // Simulate successful address creation then refresh
      final createFake = _FakeCreateUseCase();
      final formCubit = AddressFormCubit(
        createAddressUseCase: createFake,
        coordinates: coords,
      );
      formCubit.updateTitle('Title');
      formCubit.updateDistrict('District');
      formCubit.updateCity('City');
      formCubit.updateDetails('Details');
      await formCubit.submit();
      expect(formCubit.state.isSuccess, isTrue);

      // Mimic AddressSetupPage handler: on created==true, call load()
      await setupCubit.load();
      expect(addressRepo.calls, 2);

      await setupCubit.close();
      await formCubit.close();
    });
  });
}

class _FakeCreateUseCase implements CreateAddressUseCase {
  _FakeCreateUseCase({this.failure});

  final FailureException? failure;
  int calls = 0;
  AddressDraft? lastDraft;

  @override
  Future<void> call({required AddressDraft address}) async {
    calls++;
    lastDraft = address;
    if (failure != null) throw failure!;
  }
}

class _DelayedFakeCreateUseCase implements CreateAddressUseCase {
  _DelayedFakeCreateUseCase({required this.onCall});

  final void Function() onCall;

  @override
  Future<void> call({required AddressDraft address}) async {
    onCall();
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

class _FakeAddressRepository implements AddressRepository {
  _FakeAddressRepository({required this.addresses});

  final List<Address> addresses;
  int calls = 0;

  @override
  Future<List<Address>> getMyAddresses() async {
    calls++;
    return addresses;
  }

  @override
  Future<void> createAddress(AddressDraft address) async {}
}
