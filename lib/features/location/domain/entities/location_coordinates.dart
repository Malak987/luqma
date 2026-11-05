import 'package:equatable/equatable.dart';

/// Describes how a coordinate entered the application.
///
/// In particular, [LocationCoordinateSource.mapStartFallback] is never a
/// device-detected position.
enum LocationCoordinateSource {
  device,
  mapSelection,
  mapStartFallback,
}

/// A validated latitude/longitude pair with an explicit origin.
///
/// Public factories reject non-finite values and coordinates outside the
/// latitude/longitude ranges. The Sohag value is a fixed approximate map
/// starting point only; it is not a detected device location.
final class LocationCoordinates extends Equatable {
  const LocationCoordinates._({
    required this.latitude,
    required this.longitude,
    required this.source,
  });

  /// An approximate Sohag city-centre map start, not a GPS fix.
  static const LocationCoordinates sohagMapStartFallback =
      LocationCoordinates._(
    latitude: 26.5600,
    longitude: 31.6900,
    source: LocationCoordinateSource.mapStartFallback,
  );

  /// Creates coordinates returned by the foreground device-location provider.
  factory LocationCoordinates.fromDevice({
    required double latitude,
    required double longitude,
  }) {
    return _validated(
      latitude: latitude,
      longitude: longitude,
      source: LocationCoordinateSource.device,
    );
  }

  /// Creates coordinates selected manually, for example on a future map.
  factory LocationCoordinates.fromMapSelection({
    required double latitude,
    required double longitude,
  }) {
    return _validated(
      latitude: latitude,
      longitude: longitude,
      source: LocationCoordinateSource.mapSelection,
    );
  }

  final double latitude;
  final double longitude;
  final LocationCoordinateSource source;

  bool get isDeviceDetected => source == LocationCoordinateSource.device;

  bool get isMapStartFallback =>
      source == LocationCoordinateSource.mapStartFallback;

  static LocationCoordinates _validated({
    required double latitude,
    required double longitude,
    required LocationCoordinateSource source,
  }) {
    if (!latitude.isFinite || latitude < -90 || latitude > 90) {
      throw ArgumentError.value(
        latitude,
        'latitude',
        'Must be finite and between -90 and 90 degrees',
      );
    }
    if (!longitude.isFinite || longitude < -180 || longitude > 180) {
      throw ArgumentError.value(
        longitude,
        'longitude',
        'Must be finite and between -180 and 180 degrees',
      );
    }

    return LocationCoordinates._(
      latitude: latitude,
      longitude: longitude,
      source: source,
    );
  }

  @override
  List<Object> get props => <Object>[latitude, longitude, source];
}
