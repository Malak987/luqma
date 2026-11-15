import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/address.dart';

enum AddressSetupStatus { initial, loading, empty, populated, error }

class AddressSetupState extends Equatable {
  const AddressSetupState({
    required this.status,
    this.addresses = const <Address>[],
    this.failure,
  });

  const AddressSetupState.initial() : this(status: AddressSetupStatus.initial);

  final AddressSetupStatus status;
  final List<Address> addresses;
  final Failure? failure;

  bool get isLoading => status == AddressSetupStatus.loading;
  bool get isEmptyState => status == AddressSetupStatus.empty;
  bool get isPopulated => status == AddressSetupStatus.populated;
  bool get hasError => status == AddressSetupStatus.error;

  @override
  List<Object?> get props => <Object?>[status, addresses, failure];
}
