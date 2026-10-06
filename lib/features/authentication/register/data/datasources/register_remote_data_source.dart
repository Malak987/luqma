import 'package:dio/dio.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/network/api_constants.dart';
import '../../../../../core/network/dio_client.dart';
import '../models/register_failure_parser.dart';
import '../models/register_request_model.dart';
import '../models/register_response_envelope_model.dart';
import '../models/register_response_model.dart';

abstract interface class RegisterRemoteDataSource {
  Future<RegisterResponseModel> register(RegisterRequestModel request);
}

class RegisterRemoteDataSourceImpl implements RegisterRemoteDataSource {
  const RegisterRemoteDataSourceImpl(this._dioClient);

  final DioClient _dioClient;

  @override
  Future<RegisterResponseModel> register(RegisterRequestModel request) async {
    try {
      final response = await _dioClient.dio.post<Object?>(
        ApiConstants.register,
        data: request.toJson(),
        // Register is a public endpoint. Setting the flag to `false` makes
        // DioClient strip any stale bearer token from this request.
        options: Options(
          extra: <String, dynamic>{
            DioClient.requiresAuthenticationExtraKey: false,
          },
        ),
      );

      final envelope = RegisterResponseEnvelopeModel.fromJson(response.data);

      // Defensive: a 200 that still reports failure has not been observed,
      // but the envelope carries the flag so it is honoured if it happens.
      if (!envelope.isSucceeded || envelope.data == null) {
        throw RemoteException(
          code: FailureCode.validation,
          message: envelope.message ?? 'Register request was not successful',
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
        message: 'Invalid register response',
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
        // The backend answers every domain rejection (duplicate email, weak
        // password, forbidden role) with HTTP 400 and a human-readable Arabic
        // message in the body. Recover that message instead of discarding it,
        // because it is the only description of the failure.
        final message = RegisterFailureParser.parse(error.response?.data);
        return RemoteException(
          code: _codeForStatusCode(error.response?.statusCode),
          message: message ?? 'Register request failed',
        );

      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return const RemoteException(
          code: FailureCode.unknown,
          message: 'Register request failed',
        );
    }
  }

  FailureCode _codeForStatusCode(int? statusCode) {
    if (statusCode == 400) {
      // Includes duplicate email, which maps to the existing validation code.
      return FailureCode.validation;
    }
    if (statusCode == 401 || statusCode == 403) {
      return FailureCode.invalidCredentials;
    }
    return FailureCode.unknown;
  }
}
