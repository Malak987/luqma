import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/main_category_model.dart';
import '../models/main_category_response_envelope_model.dart';

abstract interface class MainCategoryRemoteDataSource {
  Future<List<MainCategoryModel>> getAllMainCategories();
}

class MainCategoryRemoteDataSourceImpl implements MainCategoryRemoteDataSource {
  const MainCategoryRemoteDataSourceImpl(this._dioClient);

  final DioClient _dioClient;

  @override
  Future<List<MainCategoryModel>> getAllMainCategories() async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        ApiConstants.getAllMainCategories,
      );
      final envelope =
          MainCategoryResponseEnvelopeModel.fromJson(response.data);
      if (!envelope.isSucceeded) {
        throw RemoteException(
          code: FailureCode.validation,
          message: envelope.message.isEmpty
              ? 'MainCategory GetAll request was not successful'
              : envelope.message,
        );
      }

      final data = envelope.data;
      if (data is! List<Object?>) {
        throw const FormatException('MainCategory GetAll data must be a list');
      }
      return data
          .map<MainCategoryModel>(MainCategoryModel.fromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on RemoteException {
      rethrow;
    } on FormatException {
      throw const RemoteException(
        code: FailureCode.unknown,
        message: 'Invalid MainCategory GetAll response',
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
          message: 'Network request failed',
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        return RemoteException(
          code: statusCode == 400
              ? FailureCode.validation
              : statusCode == 401 || statusCode == 403
                  ? FailureCode.invalidCredentials
                  : FailureCode.unknown,
          message: _responseMessage(error.response?.data) ??
              'MainCategory GetAll request failed',
        );
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return const RemoteException(
          code: FailureCode.unknown,
          message: 'MainCategory GetAll request failed',
        );
    }
  }

  String? _responseMessage(Object? body) {
    if (body is Map<Object?, Object?>) {
      final message = body['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    return null;
  }
}
