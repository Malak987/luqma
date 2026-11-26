import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/address.dart';

enum AddressSetupStatus { initial, loading, empty, populated, error }

class AddressSetupState extends Equatable {
  const AddressSetupState({
    required this.status,
    this.addresses = const <Address>[],
    this.selectedAddressId,
    this.failure,
  });

  const AddressSetupState.initial() : this(status: AddressSetupStatus.initial);

  final AddressSetupStatus status;
  final List<Address> addresses;

  /// The address the user last chose on Home. Null falls back to the default
  /// address and then to the first one, so the header is never blank while a
  /// usable address exists.
  final String? selectedAddressId;

  final Failure? failure;

  bool get isLoading => status == AddressSetupStatus.loading;
  bool get isEmptyState => status == AddressSetupStatus.empty;
  bool get isPopulated => status == AddressSetupStatus.populated;
  bool get hasError => status == AddressSetupStatus.error;

  /// The address Home should show: the explicit selection, otherwise the
  /// default address, otherwise the first stored address.
  Address? get selectedAddress {
    if (addresses.isEmpty) return null;
    final id = selectedAddressId;
    if (id != null) {
      for (final address in addresses) {
        if (address.id == id) return address;
      }
    }
    for (final address in addresses) {
      if (address.isDefault) return address;
    }
    return addresses.first;
  }

  AddressSetupState copyWith({
    AddressSetupStatus? status,
    List<Address>? addresses,
    String? selectedAddressId,
    bool clearSelectedAddressId = false,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return AddressSetupState(
      status: status ?? this.status,
      addresses: addresses ?? this.addresses,
      selectedAddressId: clearSelectedAddressId
          ? null
          : (selectedAddressId ?? this.selectedAddressId),
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[status, addresses, selectedAddressId, failure];
}
