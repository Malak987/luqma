import '../../../../core/error/failures.dart';
import '../../domain/entities/home_category.dart';
import '../../domain/repositories/main_category_repository.dart';
import '../datasources/main_category_remote_data_source.dart';

class MainCategoryRepositoryImpl implements MainCategoryRepository {
  const MainCategoryRepositoryImpl(this._remoteDataSource);

  final MainCategoryRemoteDataSource _remoteDataSource;

  @override
  Future<List<HomeCategory>> getAllMainCategories() async {
    try {
      final models = await _remoteDataSource.getAllMainCategories();
      return models.map((model) => model.toDomain()).toList(growable: false);
    } on RemoteException catch (error) {
      throw FailureException(
        Failure(error.code, debugMessage: error.message),
      );
    } on FailureException {
      rethrow;
    } catch (_) {
      throw const FailureException(
        Failure(
          FailureCode.unknown,
          debugMessage: 'Get all main categories could not be completed',
        ),
      );
    }
  }
}
