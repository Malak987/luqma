import '../../../../core/storage/preferences_storage_service.dart';
import '../../domain/entities/current_location_outcome.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/geolocator_location_data_source.dart';

final class LocationRepositoryImpl implements LocationRepository {
  LocationRepositoryImpl({
    required LocationDataSource dataSource,
    required PreferencesStorageService preferencesStorageService,
  })  : _dataSource = dataSource,
        _preferencesStorageService = preferencesStorageService;

  final LocationDataSource _dataSource;
  final PreferencesStorageService _preferencesStorageService;

  // This repository is registered as an app-lifetime singleton. These guards
  // reset on a later app launch while the integer attempt budget persists.
  bool _automaticRequestAttemptedThisSession = false;
  bool _permissionDeniedThisSession = false;
  bool _permissionRequestInProgress = false;

  @override
  Future<CurrentLocationOutcome> getCurrentLocation() async {
    final bool servicesEnabled;
    try {
      servicesEnabled = await _dataSource.isLocationServiceEnabled();
    } on LocationDataSourceException catch (error) {
      return _mapDataSourceFailure(error);
    } catch (_) {
      return const LocationRetrievalFailure(
        LocationFailureReason.serviceStatusCheckFailed,
      );
    }
    if (!servicesEnabled) {
      return const LocationServiceDisabled();
    }

    final LocationPermissionStatus permission;
    try {
      permission = await _dataSource.checkPermission();
    } on LocationDataSourceException catch (error) {
      return _mapDataSourceFailure(error);
    } catch (_) {
      return const LocationRetrievalFailure(
        LocationFailureReason.permissionStatusCheckFailed,
      );
    }

    switch (permission) {
      case LocationPermissionStatus.granted:
        return _retrieveCurrentPosition();
      case LocationPermissionStatus.permanentlyDenied:
        _permissionDeniedThisSession = true;
        return const LocationPermanentlyDenied();
      case LocationPermissionStatus.denied:
      case LocationPermissionStatus.unknown:
        return _canAutomaticallyRequestThisSession
            ? const LocationPermissionRequestRequired()
            : const LocationPermissionDenied();
    }
  }

  @override
  Future<CurrentLocationOutcome> requestLocationPermission({
    required LocationPermissionRequestMode mode,
  }) async {
    final bool servicesEnabled;
    try {
      servicesEnabled = await _dataSource.isLocationServiceEnabled();
    } on LocationDataSourceException catch (error) {
      return _mapDataSourceFailure(error);
    } catch (_) {
      return const LocationRetrievalFailure(
        LocationFailureReason.serviceStatusCheckFailed,
      );
    }
    if (!servicesEnabled) {
      return const LocationServiceDisabled();
    }

    final LocationPermissionStatus permission;
    try {
      permission = await _dataSource.checkPermission();
    } on LocationDataSourceException catch (error) {
      return _mapDataSourceFailure(error);
    } catch (_) {
      return const LocationRetrievalFailure(
        LocationFailureReason.permissionStatusCheckFailed,
      );
    }

    switch (permission) {
      case LocationPermissionStatus.granted:
        return _retrieveCurrentPosition();
      case LocationPermissionStatus.permanentlyDenied:
        _permissionDeniedThisSession = true;
        return const LocationPermanentlyDenied();
      case LocationPermissionStatus.denied:
      case LocationPermissionStatus.unknown:
        break;
    }

    if (mode == LocationPermissionRequestMode.automatic &&
        !_canAutomaticallyRequestThisSession) {
      return const LocationPermissionDenied();
    }
    if (_permissionRequestInProgress) {
      return const LocationRetrievalFailure(
        LocationFailureReason.permissionRequestInProgress,
      );
    }

    _permissionRequestInProgress = true;
    try {
      if (mode == LocationPermissionRequestMode.automatic) {
        final currentCount = _preferencesStorageService
            .getLocationPermissionAutomaticAttemptCount();
        if (currentCount >=
            PreferencesStorageService.maxLocationPermissionAutomaticAttempts) {
          return const LocationPermissionDenied();
        }

        final bool wasRecorded;
        try {
          wasRecorded = await _preferencesStorageService
              .recordLocationPermissionAutomaticAttempt();
        } catch (_) {
          return const LocationRetrievalFailure(
            LocationFailureReason.permissionAttemptCounterPersistenceFailed,
          );
        }
        if (!wasRecorded) {
          if (_preferencesStorageService
                  .getLocationPermissionAutomaticAttemptCount() >=
              PreferencesStorageService
                  .maxLocationPermissionAutomaticAttempts) {
            return const LocationPermissionDenied();
          }
          return const LocationRetrievalFailure(
            LocationFailureReason.permissionAttemptCounterPersistenceFailed,
          );
        }

        // Count request calls, not system dialogs. The OS controls whether a
        // dialog is displayed for this call.
        _automaticRequestAttemptedThisSession = true;
      }

      final requestedPermission = await _dataSource.requestPermission();
      switch (requestedPermission) {
        case LocationPermissionStatus.granted:
          return _retrieveCurrentPosition();
        case LocationPermissionStatus.permanentlyDenied:
          _permissionDeniedThisSession = true;
          return const LocationPermanentlyDenied();
        case LocationPermissionStatus.denied:
        case LocationPermissionStatus.unknown:
          _permissionDeniedThisSession = true;
          return const LocationPermissionDenied();
      }
    } on LocationDataSourceException catch (error) {
      if (mode == LocationPermissionRequestMode.automatic) {
        // The plugin request method was called, so the attempt is consumed
        // even if the platform reports an error rather than a dialog result.
        _automaticRequestAttemptedThisSession = true;
      }
      if (error.failure == LocationDataSourceFailure.permissionDenied) {
        return _permissionDeniedOutcome();
      }
      return _mapDataSourceFailure(error);
    } catch (_) {
      if (mode == LocationPermissionRequestMode.automatic) {
        _automaticRequestAttemptedThisSession = true;
      }
      return const LocationRetrievalFailure(
        LocationFailureReason.permissionRequestFailed,
      );
    } finally {
      _permissionRequestInProgress = false;
    }
  }

  bool get _canAutomaticallyRequestThisSession {
    return !_automaticRequestAttemptedThisSession &&
        !_permissionDeniedThisSession &&
        !_permissionRequestInProgress &&
        _preferencesStorageService
                .getLocationPermissionAutomaticAttemptCount() <
            PreferencesStorageService.maxLocationPermissionAutomaticAttempts;
  }

  Future<CurrentLocationOutcome> _retrieveCurrentPosition() async {
    try {
      final coordinates = await _dataSource.getCurrentPosition();
      return CurrentLocationSuccess(coordinates);
    } on LocationDataSourceException catch (error) {
      if (error.failure == LocationDataSourceFailure.permissionDenied) {
        return _permissionDeniedOutcome();
      }
      return _mapDataSourceFailure(error);
    } on ArgumentError {
      return const LocationRetrievalFailure(
        LocationFailureReason.invalidPosition,
      );
    } catch (_) {
      return const LocationRetrievalFailure(
        LocationFailureReason.positionRetrievalFailed,
      );
    }
  }

  Future<CurrentLocationOutcome> _permissionDeniedOutcome() async {
    _permissionDeniedThisSession = true;
    try {
      if (await _dataSource.checkPermission() ==
          LocationPermissionStatus.permanentlyDenied) {
        return const LocationPermanentlyDenied();
      }
    } catch (_) {
      // Retain the safe, non-permanent denied result if status cannot be read.
    }
    return const LocationPermissionDenied();
  }

  Future<CurrentLocationOutcome> _mapDataSourceFailure(
    LocationDataSourceException error,
  ) async {
    switch (error.failure) {
      case LocationDataSourceFailure.serviceDisabled:
        return const LocationServiceDisabled();
      case LocationDataSourceFailure.permissionDenied:
        return _permissionDeniedOutcome();
      case LocationDataSourceFailure.serviceStatusCheckFailed:
        return const LocationRetrievalFailure(
          LocationFailureReason.serviceStatusCheckFailed,
        );
      case LocationDataSourceFailure.permissionStatusCheckFailed:
        return const LocationRetrievalFailure(
          LocationFailureReason.permissionStatusCheckFailed,
        );
      case LocationDataSourceFailure.permissionRequestFailed:
        return const LocationRetrievalFailure(
          LocationFailureReason.permissionRequestFailed,
        );
      case LocationDataSourceFailure.permissionRequestInProgress:
        return const LocationRetrievalFailure(
          LocationFailureReason.permissionRequestInProgress,
        );
      case LocationDataSourceFailure.positionRetrievalFailed:
        return const LocationRetrievalFailure(
          LocationFailureReason.positionRetrievalFailed,
        );
      case LocationDataSourceFailure.positionTimedOut:
        return const LocationRetrievalFailure(
          LocationFailureReason.positionTimedOut,
        );
      case LocationDataSourceFailure.invalidPosition:
        return const LocationRetrievalFailure(
          LocationFailureReason.invalidPosition,
        );
    }
  }
}
