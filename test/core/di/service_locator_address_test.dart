import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/di/service_locator.dart';
import 'package:luqma_app/features/address/data/datasources/address_remote_data_source.dart';
import 'package:luqma_app/features/address/data/repositories/address_repository_impl.dart';
import 'package:luqma_app/features/address/domain/repositories/address_repository.dart';
import 'package:luqma_app/features/address/domain/usecases/create_address_use_case.dart';
import 'package:luqma_app/features/address/domain/usecases/get_my_addresses_use_case.dart';
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

  test('registers the Address remote source, repository, and use cases', () {
    expect(sl<AddressRemoteDataSource>(), isA<AddressRemoteDataSourceImpl>());
    expect(sl<AddressRepository>(), isA<AddressRepositoryImpl>());
    expect(sl<GetMyAddressesUseCase>(), isA<GetMyAddressesUseCase>());
    expect(sl<CreateAddressUseCase>(), isA<CreateAddressUseCase>());
  });
}
