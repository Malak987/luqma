import 'package:dio/dio.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/network/api_constants.dart';
import '../../../../../core/network/dio_client.dart';
import '../models/login_model.dart';

abstract interface class LoginRemoteDataSource {
  Future<LoginModel> login({
    required String usernameOrEmail,
    required String password,
  });
}

class LoginRemoteDataSourceImpl implements LoginRemoteDataSource {
  const LoginRemoteDataSourceImpl(this._dioClient);

  final DioClient _dioClient;

  @override
  Future<LoginModel> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.login,
        data: <String, dynamic>{
          'email': usernameOrEmail.trim(),
          'password': password,
        },
      );

      final responseData = response.data;

      if (responseData is! Map<String, dynamic>) {
        throw const RemoteException(
          code: FailureCode.unknown,
          message: 'Invalid server response',
        );
      }

      if (responseData['isSucceeded'] != true) {
        throw RemoteException(
          code: _mapFailureCode(responseData['message']),
          message: responseData['message']?.toString(),
        );
      }

      final data = responseData['data'];

      if (data is! Map<String, dynamic>) {
        throw const RemoteException(
          code: FailureCode.unknown,
          message: 'Login data is missing',
        );
      }

      final model = LoginModel.fromMap(data);

      if (model.token.isEmpty) {
        throw const RemoteException(
          code: FailureCode.unknown,
          message: 'Authentication token is missing',
        );
      }

      return model;
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on RemoteException {
      rethrow;
    } catch (error) {
      throw RemoteException(
        code: FailureCode.unknown,
        message: error.toString(),
      );
    }
  }

  FailureCode _mapFailureCode(dynamic message) {
    final text = message?.toString().toLowerCase() ?? '';

    if (text.contains('password') ||
        text.contains('credentials') ||
        text.contains('كلمة') ||
        text.contains('بيانات') ||
        text.contains('دخول')) {
      return FailureCode.invalidCredentials;
    }

    return FailureCode.unknown;
  }

  RemoteException _mapDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return const RemoteException(
          code: FailureCode.network,
          message: 'Network connection failed',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;

        String? message;

        if (responseData is Map<String, dynamic>) {
          message = responseData['message']?.toString();
        }

        if (statusCode == 401) {
          return RemoteException(
            code: FailureCode.invalidCredentials,
            message: message ?? 'Invalid credentials',
          );
        }

        return RemoteException(
          code: FailureCode.unknown,
          message: message ?? 'Server error: $statusCode',
        );

      case DioExceptionType.cancel:
        return const RemoteException(
          code: FailureCode.network,
          message: 'Request cancelled',
        );

      case DioExceptionType.badCertificate:
        return const RemoteException(
          code: FailureCode.network,
          message: 'Secure connection failed',
        );

      case DioExceptionType.unknown:
        return RemoteException(
          code: FailureCode.unknown,
          message: error.message ?? error.toString(),
        );
    }
  }
}