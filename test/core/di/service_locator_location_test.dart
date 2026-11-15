import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/di/service_locator.dart';
import 'package:luqma_app/features/location/data/datasources/geolocator_location_data_source.dart';
import 'package:luqma_app/features/location/data/repositories/location_repository_impl.dart';
import 'package:luqma_app/features/location/domain/repositories/location_repository.dart';
import 'package:luqma_app/features/location/domain/repositories/reverse_geocoding_repository.dart';
import 'package:luqma_app/features/location/domain/usecases/get_current_location_use_case.dart';
import 'package:luqma_app/features/location/domain/usecases/request_location_permission_use_case.dart';
import 'package:luqma_app/features/location/domain/usecases/reverse_geocode_use_case.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await sl.reset();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    await configureDependencies(preferences: preferences);
  });

  tearDown(() async {
    await sl.reset();
  });

  test('registers and resolves only production location dependencies', () {
    expect(sl<LocationDataSource>(), isA<GeolocatorLocationDataSource>());
    expect(sl<LocationRepository>(), isA<LocationRepositoryImpl>());
    expect(sl<GetCurrentLocationUseCase>(), isA<GetCurrentLocationUseCase>());
    expect(
      sl<RequestLocationPermissionUseCase>(),
      isA<RequestLocationPermissionUseCase>(),
    );

    expect(sl.isRegistered<ReverseGeocodingRepository>(), isFalse);
    expect(sl.isRegistered<ReverseGeocodeUseCase>(), isFalse);
  });
}
