import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../domain/entities/current_location_outcome.dart';
import '../../domain/entities/location_coordinates.dart';

/// Geolocator-independent port consumed by the location repository.
abstract interface class LocationDataSource {
  Future<bool> isLocationServiceEnabled();

  Future<LocationPermissionStatus> checkPermission();

  Future<LocationPermissionStatus> requestPermission();

  Future<LocationCoordinates> getCurrentPosition();
}

enum LocationDataSourceFailure {
  serviceStatusCheckFailed,
  permissionStatusCheckFailed,
  permissionRequestFailed,
  permissionRequestInProgress,
  serviceDisabled,
  permissionDenied,
  positionRetrievalFailed,
  positionTimedOut,
  invalidPosition,
}

/// A typed boundary for failures raised by the platform location plugin.
/// Geolocator exceptions and types do not cross into Domain.
final class LocationDataSourceException implements Exception {
  const LocationDataSourceException(this.failure);

  final LocationDataSourceFailure failure;
}

/// Foreground-only adapter around Geolocator.
final class GeolocatorLocationDataSource implements LocationDataSource {
  const GeolocatorLocationDataSource();

  @override
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      throw const LocationDataSourceException(
        LocationDataSourceFailure.serviceStatusCheckFailed,
      );
    }
  }

  @override
  Future<LocationPermissionStatus> checkPermission() async {
    try {
      return mapPermission(await Geolocator.checkPermission());
    } catch (_) {
      throw const LocationDataSourceException(
        LocationDataSourceFailure.permissionStatusCheckFailed,
      );
    }
  }

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    try {
      return mapPermission(await Geolocator.requestPermission());
    } on PermissionRequestInProgressException {
      throw const LocationDataSourceException(
        LocationDataSourceFailure.permissionRequestInProgress,
      );
    } on PermissionDeniedException {
      throw const LocationDataSourceException(
        LocationDataSourceFailure.permissionDenied,
      );
    } catch (_) {
      throw const LocationDataSourceException(
        LocationDataSourceFailure.permissionRequestFailed,
      );
    }
  }

  @override
  Future<LocationCoordinates> getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      return LocationCoordinates.fromDevice(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on LocationServiceDisabledException {
      throw const LocationDataSourceException(
        LocationDataSourceFailure.serviceDisabled,
      );
    } on PermissionDeniedException {
      throw const LocationDataSourceException(
        LocationDataSourceFailure.permissionDenied,
      );
    } on TimeoutException {
      throw const LocationDataSourceException(
        LocationDataSourceFailure.positionTimedOut,
      );
    } on ArgumentError {
      throw const LocationDataSourceException(
        LocationDataSourceFailure.invalidPosition,
      );
    } catch (_) {
      throw const LocationDataSourceException(
        LocationDataSourceFailure.positionRetrievalFailed,
      );
    }
  }

  /// Maps plugin states to the plugin-independent Domain permission states.
  static LocationPermissionStatus mapPermission(
    LocationPermission permission,
  ) {
    switch (permission) {
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return LocationPermissionStatus.granted;
      case LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.permanentlyDenied;
      case LocationPermission.unableToDetermine:
        return LocationPermissionStatus.unknown;
    }
  }
}
