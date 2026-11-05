import 'package:equatable/equatable.dart';

import 'location_coordinates.dart';

enum LocationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  unknown,
}

enum LocationPermissionRequestMode {
  /// An attempt governed by the persisted two-attempt application policy.
  /// The future UI must explain why location is needed before invoking it.
  automatic,

  /// A user-initiated retry. It does not consume the automatic-attempt budget.
  explicit,
}

enum LocationFailureReason {
  serviceStatusCheckFailed,
  permissionStatusCheckFailed,
  permissionRequestFailed,
  permissionRequestInProgress,
  permissionAttemptCounterPersistenceFailed,
  positionRetrievalFailed,
  positionTimedOut,
  invalidPosition,
}

/// A typed result of checking or retrieving the device's current location.
sealed class CurrentLocationOutcome extends Equatable {
  const CurrentLocationOutcome();
}

final class CurrentLocationSuccess extends CurrentLocationOutcome {
  CurrentLocationSuccess(this.coordinates) {
    if (!coordinates.isDeviceDetected) {
      throw ArgumentError.value(
        coordinates,
        'coordinates',
        'A current-location success must contain a device-detected position',
      );
    }
  }

  final LocationCoordinates coordinates;

  @override
  List<Object> get props => <Object>[coordinates];
}

final class LocationServiceDisabled extends CurrentLocationOutcome {
  const LocationServiceDisabled();

  @override
  List<Object?> get props => const <Object?>[];
}

final class LocationPermissionDenied extends CurrentLocationOutcome {
  const LocationPermissionDenied();

  @override
  List<Object?> get props => const <Object?>[];
}

final class LocationPermanentlyDenied extends CurrentLocationOutcome {
  const LocationPermanentlyDenied();

  @override
  List<Object?> get props => const <Object?>[];
}

/// The caller may explain the need for location, then request it explicitly
/// using [LocationPermissionRequestMode.automatic].
final class LocationPermissionRequestRequired extends CurrentLocationOutcome {
  const LocationPermissionRequestRequired();

  @override
  List<Object?> get props => const <Object?>[];
}

final class LocationRetrievalFailure extends CurrentLocationOutcome {
  const LocationRetrievalFailure(this.reason);

  final LocationFailureReason reason;

  @override
  List<Object> get props => <Object>[reason];
}
