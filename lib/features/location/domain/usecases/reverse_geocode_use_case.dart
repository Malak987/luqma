import '../entities/geocoded_address.dart';
import '../entities/location_coordinates.dart';
import '../entities/reverse_geocoding_consent.dart';
import '../repositories/reverse_geocoding_repository.dart';

class ReverseGeocodingConsentRequiredException implements Exception {
  const ReverseGeocodingConsentRequiredException();
}

/// Gates a provider-independent reverse-geocoding operation on current-session
/// consent. No consent or result is persisted by this use case.
class ReverseGeocodeUseCase {
  const ReverseGeocodeUseCase(this._repository);

  final ReverseGeocodingRepository _repository;

  Future<GeocodedAddress?> call({
    required LocationCoordinates coordinates,
    required Object sessionToken,
    required ReverseGeocodingConsent? consent,
  }) async {
    if (consent == null || !consent.isValidForSession(sessionToken)) {
      throw const ReverseGeocodingConsentRequiredException();
    }

    return _repository.reverseGeocode(coordinates);
  }
}
