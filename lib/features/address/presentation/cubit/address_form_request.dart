import '../../../location/domain/entities/location_coordinates.dart';
import '../../domain/entities/address.dart';

/// What the address details screen was opened for.
///
/// Creating needs only the point picked on the map; editing also carries the
/// persisted [Address] so the form opens prefilled and every untouched field —
/// `label`, `isDefault`, coordinates — is sent back unchanged.
final class AddressFormRequest {
  const AddressFormRequest.create({required this.coordinates}) : address = null;

  const AddressFormRequest.edit({required this.address}) : coordinates = null;

  final LocationCoordinates? coordinates;
  final Address? address;

  bool get isEditing => address != null;

  /// Coordinates the form starts with: the picked point, or the stored address
  /// position when it is a valid, non-placeholder coordinate pair.
  LocationCoordinates get initialCoordinates {
    final editing = address;
    if (editing != null && _isUsable(editing.latitude, editing.longitude)) {
      return LocationCoordinates.fromMapSelection(
        latitude: editing.latitude,
        longitude: editing.longitude,
      );
    }
    return coordinates ?? LocationCoordinates.sohagMapStartFallback;
  }

  static bool _isUsable(double latitude, double longitude) {
    if (!latitude.isFinite || latitude < -90 || latitude > 90) return false;
    if (!longitude.isFinite || longitude < -180 || longitude > 180) return false;
    return true;
  }
}
