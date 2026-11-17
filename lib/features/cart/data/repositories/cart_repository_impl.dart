import '../../../../core/error/failures.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_count.dart';
import '../../domain/entities/cart_line.dart';
import '../../domain/entities/cart_mutation.dart';
import '../../domain/entities/cart_update_result.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_remote_data_source.dart';
import '../models/cart_mutation_request_model.dart';

class CartRepositoryImpl implements CartRepository {
  const CartRepositoryImpl(this._remoteDataSource);

  final CartRemoteDataSource _remoteDataSource;

  @override
  Future<CartLine> addToCart(CartMutation mutation) => _mapFailure(
        () async => (await _remoteDataSource.addToCart(
          CartMutationRequestModel.fromDomain(mutation),
        ))
            .toDomain(),
      );

  @override
  Future<CartUpdateResult> updateToCart(CartMutation mutation) => _mapFailure(
        () async => (await _remoteDataSource.updateToCart(
          CartMutationRequestModel.fromDomain(mutation),
        ))
            .toDomain(),
      );

  @override
  Future<void> clearCart() => _mapFailure(_remoteDataSource.clearCart);

  @override
  Future<Cart> getMyCart() => _mapFailure(
        () async => (await _remoteDataSource.getMyCart()).toDomain(),
      );

  @override
  Future<CartCount> getCount() =>
      _mapFailure(() async => (await _remoteDataSource.getCount()).toDomain());

  Future<T> _mapFailure<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on RemoteException catch (error) {
      throw FailureException(Failure(error.code, debugMessage: error.message));
    } on FailureException {
      rethrow;
    } catch (_) {
      throw const FailureException(
        Failure(
          FailureCode.unknown,
          debugMessage: 'Cart operation could not be completed',
        ),
      );
    }
  }
}
