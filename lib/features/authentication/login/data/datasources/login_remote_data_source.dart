import 'package:dio/dio.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/network/api_constants.dart';
import '../../../../../core/network/dio_client.dart';
import '../models/login_request_model.dart';
import '../models/login_response_envelope_model.dart';
import '../models/login_response_model.dart';

abstract interface class LoginRemoteDataSource {
  Future<LoginResponseModel> login(LoginRequestModel request);
}

class LoginRemoteDataSourceImpl implements LoginRemoteDataSource {
  const LoginRemoteDataSourceImpl(this._dioClient);

  final DioClient _dioClient;

  @override
  Future<LoginResponseModel> login(LoginRequestModel request) async {
    try {
      final response = await _dioClient.dio.post<Object?>(
        ApiConstants.login,
        data: request.toJson(),
        options: Options(
          extra: <String, dynamic>{
            DioClient.requiresAuthenticationExtraKey: false,
          },
        ),
      );

      final envelope = LoginResponseEnvelopeModel.fromJson(response.data);
      if (!envelope.isSucceeded || envelope.data == null) {
        throw const RemoteException(
          code: FailureCode.unknown,
          message: 'Login request was not successful',
        );
      }

      return envelope.data!;
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on RemoteException {
      rethrow;
    } on FormatException {
      throw const RemoteException(
        code: FailureCode.unknown,
        message: 'Invalid login response',
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
        if (error.response?.statusCode == 401) {
          return const RemoteException(
            code: FailureCode.invalidCredentials,
            message: 'Invalid credentials',
          );
        }
        return const RemoteException(
          code: FailureCode.unknown,
          message: 'Login request failed',
        );

      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return const RemoteException(
          code: FailureCode.unknown,
          message: 'Login request failed',
        );
    }
  }
}
