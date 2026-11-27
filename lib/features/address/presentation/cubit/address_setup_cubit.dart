import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/address.dart';
import '../../domain/repositories/address_snapshot_cache.dart';
import '../../domain/usecases/get_my_addresses_use_case.dart';
import 'address_setup_state.dart';

/// Owns the signed-in user's address list and which one Home displays.
///
/// Uses only the existing address use cases — no Dio or data source access.
/// The selection survives reloads and is updated in place when the user selects,
/// adds, or edits an address, so Home never shows a stale value after a
/// successful `PUT /api/Address/Update/{id}`.
class AddressSetupCubit extends Cubit<AddressSetupState> {
  AddressSetupCubit({
    required GetMyAddressesUseCase getMyAddressesUseCase,
    AddressSnapshotCache? snapshotCache,
  })  : _getMyAddressesUseCase = getMyAddressesUseCase,
        _snapshotCache = snapshotCache,
        super(const AddressSetupState.initial());

  final GetMyAddressesUseCase _getMyAddressesUseCase;
  final AddressSnapshotCache? _snapshotCache;

  bool _isLoading = false;

  Future<void> load() async {
    if (isClosed) return;
    if (_isLoading || state.isLoading) {
      return;
    }
    _isLoading = true;
    if (isClosed) {
      _isLoading = false;
      return;
    }
    var previousSelection = state.selectedAddressId;

    // Warm start: on a cold launch the last confirmed addresses open Home at
    // once and the server only refreshes them in the background, so a slow or
    // sleeping backend can no longer hold the whole app behind a spinner.
    var servedFromCache = false;
    if (state.status == AddressSetupStatus.initial) {
      final snapshot = _snapshotCache?.read();
      if (snapshot != null) {
        servedFromCache = true;
        previousSelection = _resolveSelection(
          snapshot.addresses,
          snapshot.selectedAddressId,
        );
        emit(AddressSetupState(
          status: AddressSetupStatus.populated,
          addresses: snapshot.addresses,
          selectedAddressId: previousSelection,
        ));
      }
    }
    if (!servedFromCache) {
      emit(AddressSetupState(
        status: AddressSetupStatus.loading,
        addresses: state.addresses,
        selectedAddressId: previousSelection,
      ));
    }
    try {
      final addresses = await _getMyAddressesUseCase();
      if (isClosed) return;
      if (addresses.isEmpty) {
        unawaited(_snapshotCache?.clear());
        emit(const AddressSetupState(status: AddressSetupStatus.empty));
        return;
      }
      final selection = _resolveSelection(addresses, previousSelection);
      unawaited(_snapshotCache?.write(addresses, selection));
      emit(AddressSetupState(
        status: AddressSetupStatus.populated,
        addresses: List<Address>.unmodifiable(addresses),
        selectedAddressId: selection,
      ));
    } on FailureException catch (error) {
      if (isClosed) return;
      // The cached addresses are still on screen: stay quiet, retry later.
      if (servedFromCache) return;
      emit(AddressSetupState(
        status: AddressSetupStatus.error,
        failure: error.failure,
      ));
    } catch (error) {
      if (isClosed) return;
      if (servedFromCache) return;
      emit(AddressSetupState(
        status: AddressSetupStatus.error,
        failure: Failure(
          FailureCode.unknown,
          debugMessage: error.toString(),
        ),
      ));
    } finally {
      _isLoading = false;
    }
  }

  Future<void> retry() => load();

  /// Reloads the list, for example after returning from the setup screen.
  Future<void> refresh() => load();

  /// Makes [id] the address Home displays. Unknown ids are ignored so a stale
  /// tile cannot blank the header.
  void selectAddress(String id) {
    if (isClosed) return;
    final trimmed = id.trim();
    if (trimmed.isEmpty) return;
    final exists = state.addresses.any((address) => address.id == trimmed);
    if (!exists) return;
    if (state.selectedAddressId == trimmed) return;
    emit(state.copyWith(selectedAddressId: trimmed));
    unawaited(_snapshotCache?.write(state.addresses, trimmed));
  }

  /// Applies a saved address without another network round trip.
  ///
  /// Used after `PUT /api/Address/Update/{id}` and after a successful create:
  /// the returned record is merged into the list, becomes the selection, and
  /// keeps its `isDefault` flag — while any other address that claims the
  /// default loses it, mirroring what the server just accepted.
  void onAddressSaved(Address address) {
    if (isClosed) return;
    final updated = <Address>[];
    var replaced = false;
    for (final existing in state.addresses) {
      if (existing.id == address.id) {
        updated.add(address);
        replaced = true;
      } else {
        updated.add(
          address.isDefault && existing.isDefault
              ? existing.copyWith(isDefault: false)
              : existing,
        );
      }
    }
    if (!replaced) updated.add(address);

    final snapshot = List<Address>.unmodifiable(updated);
    if (!snapshot.any((item) => item.id == address.id)) return;
    emit(AddressSetupState(
      status: AddressSetupStatus.populated,
      addresses: snapshot,
      selectedAddressId: address.id,
    ));
    unawaited(_snapshotCache?.write(snapshot, address.id));
  }

  String? _resolveSelection(List<Address> addresses, String? previousSelection) {
    if (previousSelection != null &&
        addresses.any((address) => address.id == previousSelection)) {
      return previousSelection;
    }
    for (final address in addresses) {
      if (address.isDefault) return address.id;
    }
    return null;
  }

  // For tests only — not used in production.
  void emitForTest(AddressSetupState state) => emit(state);
  void emitErrorForTest() => emit(const AddressSetupState(
        status: AddressSetupStatus.error,
        failure: Failure(FailureCode.unknown),
      ));
  void emitEmptyForTest() =>
      emit(const AddressSetupState(status: AddressSetupStatus.empty));
}
