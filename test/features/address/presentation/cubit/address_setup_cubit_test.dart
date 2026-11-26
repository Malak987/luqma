import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/features/address/domain/entities/address.dart';
import 'package:luqma_app/features/address/domain/entities/address_label.dart';
import 'package:luqma_app/features/address/domain/usecases/get_my_addresses_use_case.dart';
import 'package:luqma_app/features/address/presentation/cubit/address_setup_cubit.dart';
import 'package:luqma_app/features/address/presentation/cubit/address_setup_state.dart';

void main() {
  group('AddressSetupCubit', () {
    test('initial state is initial', () {
      final cubit = AddressSetupCubit(
        getMyAddressesUseCase: _FakeGetMyAddressesUseCase(addresses: []),
      );
      expect(cubit.state.status, AddressSetupStatus.initial);
      cubit.close();
    });

    test('emits loading then empty when API returns empty list', () async {
      final cubit = AddressSetupCubit(
        getMyAddressesUseCase: _FakeGetMyAddressesUseCase(addresses: []),
      );

      final states = <AddressSetupState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.load();
      await Future<void>.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0].status, AddressSetupStatus.loading);
      expect(states[1].status, AddressSetupStatus.empty);
      expect(cubit.state.status, AddressSetupStatus.empty);

      await sub.cancel();
      await cubit.close();
    });

    test('emits loading then populated when API returns addresses', () async {
      final address = _address();
      final cubit = AddressSetupCubit(
        getMyAddressesUseCase: _FakeGetMyAddressesUseCase(
          addresses: [address],
        ),
      );

      final states = <AddressSetupState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.load();
      await Future<void>.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0].status, AddressSetupStatus.loading);
      expect(states[1].status, AddressSetupStatus.populated);
      expect(states[1].addresses, [address]);

      await sub.cancel();
      await cubit.close();
    });

    test('emits loading then error on failure and never as empty', () async {
      final cubit = AddressSetupCubit(
        getMyAddressesUseCase: _FakeGetMyAddressesUseCase(
          addresses: [],
          exception: const FailureException(
            Failure(FailureCode.network, debugMessage: 'offline'),
          ),
        ),
      );

      final states = <AddressSetupState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.load();
      await Future<void>.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0].status, AddressSetupStatus.loading);
      expect(states[1].status, AddressSetupStatus.error);
      expect(states[1].failure?.code, FailureCode.network);
      // Ensure not treated as empty
      expect(states[1].status, isNot(AddressSetupStatus.empty));

      await sub.cancel();
      await cubit.close();
    });

    test('retry after error re-invokes use case', () async {
      int callCount = 0;
      final cubit = AddressSetupCubit(
        getMyAddressesUseCase: _TogglingUseCase(
          onCall: () => callCount++,
        ),
      );

      await cubit.load();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.status, AddressSetupStatus.error);
      expect(callCount, 1);

      await cubit.retry();
      await Future<void>.delayed(Duration.zero);

      expect(callCount, 2);
      expect(cubit.state.status, AddressSetupStatus.empty);

      await cubit.close();
    });

    test('prevents duplicate concurrent requests', () async {
      int calls = 0;
      final cubit = AddressSetupCubit(
        getMyAddressesUseCase: _DelayedCountingUseCase(
          addresses: [],
          onCall: () => calls++,
        ),
      );

      // Fire two loads concurrently
      final f1 = cubit.load();
      final f2 = cubit.load();
      await Future.wait([f1, f2]);

      expect(calls, 1);
      expect(cubit.state.status, AddressSetupStatus.empty);

      await cubit.close();
    });

    test('does not emit after close', () async {
      final cubit = AddressSetupCubit(
        getMyAddressesUseCase: _DelayedCountingUseCase(addresses: []),
      );
      await cubit.close();
      // Should not throw
      await cubit.load();
    });
  });

  group('selection and saved updates', () {
    const home = Address(
      id: 'home-1',
      label: AddressLabel.home,
      title: 'Home',
      district: 'Minya',
      city: 'El Minya',
      details: 'Flat 3',
      latitude: 28.1,
      longitude: 30.75,
      isDefault: true,
    );
    const work = Address(
      id: 'work-1',
      label: AddressLabel.work,
      title: 'Office',
      district: 'Downtown',
      city: 'El Minya',
      details: 'Floor 2',
      latitude: 28.11,
      longitude: 30.76,
      isDefault: false,
    );

    test('defaults to the default address and follows selectAddress', () async {
      final cubit = AddressSetupCubit(
        getMyAddressesUseCase:
            _FakeGetMyAddressesUseCase(addresses: <Address>[home, work]),
      );

      await cubit.load();
      expect(cubit.state.selectedAddress, home);

      cubit.selectAddress(work.id);
      expect(cubit.state.selectedAddress, work);

      // Unknown ids must not blank the header.
      cubit.selectAddress('missing');
      expect(cubit.state.selectedAddress, work);
      await cubit.close();
    });

    test('falls back to the first address when none is default', () async {
      const first = Address(
        id: 'a',
        label: AddressLabel.other,
        title: 'A',
        district: 'D',
        city: 'C',
        details: 'X',
        latitude: 1,
        longitude: 1,
        isDefault: false,
      );
      final cubit = AddressSetupCubit(
        getMyAddressesUseCase: _FakeGetMyAddressesUseCase(addresses: <Address>[
          first,
          home.copyWith(isDefault: false),
        ]),
      );

      await cubit.load();
      expect(cubit.state.selectedAddress, first);
      await cubit.close();
    });

    test('keeps the chosen address across a reload', () async {
      final useCase =
          _FakeGetMyAddressesUseCase(addresses: <Address>[home, work]);
      final cubit = AddressSetupCubit(getMyAddressesUseCase: useCase);

      await cubit.load();
      cubit.selectAddress(work.id);
      await cubit.refresh();

      expect(cubit.state.selectedAddress, work);
      await cubit.close();
    });

    test('onAddressSaved replaces the record and selects it', () async {
      final cubit = AddressSetupCubit(
        getMyAddressesUseCase:
            _FakeGetMyAddressesUseCase(addresses: <Address>[home, work]),
      );
      await cubit.load();

      final renamed = work.copyWith(title: 'New office', isDefault: true);
      cubit.onAddressSaved(renamed);

      expect(cubit.state.addresses, hasLength(2));
      expect(cubit.state.selectedAddress?.id, work.id);
      expect(cubit.state.selectedAddress?.title, 'New office');
      expect(cubit.state.selectedAddress?.latitude, work.latitude);
      expect(cubit.state.selectedAddress?.longitude, work.longitude);
      expect(cubit.state.selectedAddress?.label, AddressLabel.work);
      // Only one address may stay default.
      final defaults =
          cubit.state.addresses.where((address) => address.isDefault).toList();
      expect(defaults.single.id, work.id);
      await cubit.close();
    });

    test('onAddressSaved can turn an empty state into a populated one',
        () async {
      final cubit = AddressSetupCubit(
        getMyAddressesUseCase: _FakeGetMyAddressesUseCase(addresses: <Address>[]),
      );
      await cubit.load();
      expect(cubit.state.isEmptyState, isTrue);

      cubit.onAddressSaved(home);

      expect(cubit.state.isPopulated, isTrue);
      expect(cubit.state.selectedAddress, home);
      await cubit.close();
    });
  });
}

Address _address() => const Address(
      id: 'addr-1',
      label: AddressLabel.home,
      title: 'Home',
      district: 'District A',
      city: 'Sohag',
      details: 'Building 1',
      latitude: 26.56,
      longitude: 31.69,
      isDefault: true,
    );

class _FakeGetMyAddressesUseCase implements GetMyAddressesUseCase {
  _FakeGetMyAddressesUseCase({required this.addresses, this.exception});

  final List<Address> addresses;
  final Exception? exception;

  @override
  Future<List<Address>> call() async {
    if (exception != null) throw exception!;
    return addresses;
  }
}

class _DelayedCountingUseCase implements GetMyAddressesUseCase {
  _DelayedCountingUseCase({required this.addresses, this.onCall});

  final List<Address> addresses;
  final VoidCallback? onCall;

  @override
  Future<List<Address>> call() async {
    if (onCall != null) onCall!();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return addresses;
  }
}

class _TogglingUseCase implements GetMyAddressesUseCase {
  _TogglingUseCase({required this.onCall});

  final VoidCallback onCall;
  int _calls = 0;

  @override
  Future<List<Address>> call() async {
    onCall();
    _calls++;
    if (_calls == 1) {
      throw const FailureException(Failure(FailureCode.unknown));
    }
    return const [];
  }
}

typedef VoidCallback = void Function();
