import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/di/service_locator.dart';
import 'package:luqma_app/features/cart/data/datasources/cart_remote_data_source.dart';
import 'package:luqma_app/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:luqma_app/features/cart/domain/repositories/cart_repository.dart';
import 'package:luqma_app/features/cart/domain/usecases/add_to_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/clear_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/get_cart_count_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/get_my_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/update_to_cart_use_case.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await sl.reset();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    await configureDependencies(preferences: preferences);
  });

  tearDown(() => sl.reset());

  test('registers the Cart API data, domain and action dependencies', () {
    expect(sl<CartRemoteDataSource>(), isA<CartRemoteDataSourceImpl>());
    expect(sl<CartRepository>(), isA<CartRepositoryImpl>());
    expect(sl<AddToCartUseCase>(), isA<AddToCartUseCase>());
    expect(sl<UpdateToCartUseCase>(), isA<UpdateToCartUseCase>());
    expect(sl<ClearCartUseCase>(), isA<ClearCartUseCase>());
    expect(sl<GetMyCartUseCase>(), isA<GetMyCartUseCase>());
    expect(sl<GetCartCountUseCase>(), isA<GetCartCountUseCase>());
  });
}
