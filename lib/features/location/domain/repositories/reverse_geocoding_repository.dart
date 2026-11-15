import '../entities/geocoded_address.dart';
import '../entities/location_coordinates.dart';

/// Provider-independent contract for resolving address details from a point.
///
/// Returns null when no address is available. Implementations must not invent
/// missing components. No provider implementation is registered in Phase 2.
abstract interface class ReverseGeocodingRepository {
  Future<GeocodedAddress?> reverseGeocode(LocationCoordinates coordinates);
}
