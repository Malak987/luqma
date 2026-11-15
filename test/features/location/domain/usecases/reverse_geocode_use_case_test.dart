import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/features/location/domain/entities/geocoded_address.dart';
import 'package:luqma_app/features/location/domain/entities/location_coordinates.dart';
import 'package:luqma_app/features/location/domain/entities/reverse_geocoding_consent.dart';
import 'package:luqma_app/features/location/domain/repositories/reverse_geocoding_repository.dart';
import 'package:luqma_app/features/location/domain/usecases/reverse_geocode_use_case.dart';

void main() {
  group('ReverseGeocodeUseCase', () {
    final coordinates = LocationCoordinates.fromMapSelection(
      latitude: 35.6895,
      longitude: 139.6917,
    );

    test('rejects missing consent without calling the repository', () async {
      final repository = _FakeReverseGeocodingRepository();
      final useCase = ReverseGeocodeUseCase(repository);

      await expectLater(
        useCase(
          coordinates: coordinates,
          sessionToken: Object(),
          consent: null,
        ),
        throwsA(isA<ReverseGeocodingConsentRequiredException>()),
      );
      expect(repository.calls, 0);
    });

    test('rejects consent from another map-picker session', () async {
      final repository = _FakeReverseGeocodingRepository();
      final useCase = ReverseGeocodeUseCase(repository);
      final oldSession = Object();
      final currentSession = Object();
      final consent = ReverseGeocodingConsent.grantedForSession(
        sessionToken: oldSession,
      );

      await expectLater(
        useCase(
          coordinates: coordinates,
          sessionToken: currentSession,
          consent: consent,
        ),
        throwsA(isA<ReverseGeocodingConsentRequiredException>()),
      );
      expect(repository.calls, 0);
    });

    test('forwards coordinates with valid session consent', () async {
      final address = const GeocodedAddress(city: 'Sohag');
      final repository = _FakeReverseGeocodingRepository(result: address);
      final useCase = ReverseGeocodeUseCase(repository);
      final session = Object();
      final consent = ReverseGeocodingConsent.grantedForSession(
        sessionToken: session,
      );

      final result = await useCase(
        coordinates: coordinates,
        sessionToken: session,
        consent: consent,
      );

      expect(result, address);
      expect(repository.calls, 1);
      expect(repository.requestedCoordinates, coordinates);
    });

    test('preserves no-result and partial-address responses', () async {
      final repository = _FakeReverseGeocodingRepository();
      final useCase = ReverseGeocodeUseCase(repository);
      final session = Object();
      final consent = ReverseGeocodingConsent.grantedForSession(
        sessionToken: session,
      );

      expect(
        await useCase(
          coordinates: coordinates,
          sessionToken: session,
          consent: consent,
        ),
        isNull,
      );

      repository.result = const GeocodedAddress(district: 'A partial result');
      final result = await useCase(
        coordinates: coordinates,
        sessionToken: session,
        consent: consent,
      );
      expect(result?.district, 'A partial result');
      expect(result?.city, isNull);
    });
  });
}

class _FakeReverseGeocodingRepository implements ReverseGeocodingRepository {
  _FakeReverseGeocodingRepository({this.result});

  GeocodedAddress? result;
  int calls = 0;
  LocationCoordinates? requestedCoordinates;

  @override
  Future<GeocodedAddress?> reverseGeocode(
    LocationCoordinates coordinates,
  ) async {
    calls++;
    requestedCoordinates = coordinates;
    return result;
  }
}
