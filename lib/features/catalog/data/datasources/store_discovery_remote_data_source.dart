import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/queries/store_query.dart';
import '../models/cuisine_model.dart';
import '../models/cuisine_response_model.dart';
import '../models/store_page_model.dart';

abstract interface class StoreDiscoveryRemoteDataSource {
  Future<List<CuisineModel>> getActiveCuisines();
  Future<StorePageModel> getStores(StoreQuery query);
}

class StoreDiscoveryRemoteDataSourceImpl
    implements StoreDiscoveryRemoteDataSource {
  const StoreDiscoveryRemoteDataSourceImpl(this._client);
  final DioClient _client;

  @override
  Future<List<CuisineModel>> getActiveCuisines() => _get(
        ApiConstants.getAllCuisines,
        const {'onlyActive': true},
        (data) => CuisineResponseModel.fromJson(data).items,
      );

  @override
  Future<StorePageModel> getStores(StoreQuery query) => _get(
        ApiConstants.getAllStores,
        <String, Object>{
          'mainCategoryId': query.mainCategoryId,
          'isActive': true,
          'pageNumber': query.pageNumber,
          'pageSize': query.pageSize,
          if (query.cuisineId != null) 'cuisineId': query.cuisineId!,
          if (query.openNowOnly) 'isOpenNow': true,
        },
        StorePageModel.fromJson,
      );

  Future<T> _get<T>(
      String path, Map<String, Object> query, T Function(Object?) parse) async {
    try {
      // No authentication extra: shared Dio deliberately strips bearer tokens.
      final response =
          await _client.dio.get<Object?>(path, queryParameters: query);
      return parse(response.data);
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on RemoteException {
      rethrow;
    } on FormatException {
      throw const RemoteException(
        code: FailureCode.unknown,
        message: 'Invalid catalog response',
      );
    }
  }

  RemoteException _mapDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return const RemoteException(
            code: FailureCode.network,
            message: 'Catalog network request failed');
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        return RemoteException(
          code: status == 400
              ? FailureCode.validation
              : status == 401 || status == 403
                  ? FailureCode.invalidCredentials
                  : FailureCode.unknown,
          message: 'Catalog request failed',
        );
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return const RemoteException(
            code: FailureCode.unknown, message: 'Catalog request failed');
    }
  }
}
