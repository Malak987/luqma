import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/address_model.dart';
import '../models/address_response_envelope_model.dart';
import '../models/create_address_request_model.dart';

abstract interface class AddressRemoteDataSource {
  Future<List<AddressModel>> getMyAddresses();

  Future<void> createAddress(CreateAddressRequestModel request);
}

class AddressRemoteDataSourceImpl implements AddressRemoteDataSource {
  const AddressRemoteDataSourceImpl(this._dioClient);

  final DioClient _dioClient;

  Options get _authenticatedOptions => Options(
        extra: <String, dynamic>{
          DioClient.requiresAuthenticationExtraKey: true,
        },
      );

  @override
  Future<List<AddressModel>> getMyAddresses() async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        ApiConstants.getMyAddresses,
        options: _authenticatedOptions,
      );

      final envelope = AddressResponseEnvelopeModel.fromJson(response.data);
      _throwIfUnsuccessful(envelope, 'GetMyAddresses');

      final data = envelope.data;
      if (data is! List<Object?>) {
        throw const FormatException(
          'Address GetMyAddresses data must be a list',
        );
      }

      return data
          .map<AddressModel>(AddressModel.fromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on RemoteException {
      rethrow;
    } on FormatException {
      throw const RemoteException(
        code: FailureCode.unknown,
        message: 'Invalid GetMyAddresses response',
      );
    }
  }

  @override
  Future<void> createAddress(CreateAddressRequestModel request) async {
    try {
      final response = await _dioClient.dio.post<Object?>(
        ApiConstants.createAddress,
        data: request.toJson(),
        options: _authenticatedOptions,
      );

      final envelope = AddressResponseEnvelopeModel.fromJson(response.data);
      _throwIfUnsuccessful(envelope, 'Create address');

      // The repository contains no confirmed Create success payload schema.
      // Validate the shared envelope, but deliberately do not infer a returned
      // Address from its operation-specific `data` value.
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on RemoteException {
      rethrow;
    } on FormatException {
      throw const RemoteException(
        code: FailureCode.unknown,
        message: 'Invalid Create address response',
      );
    }
  }

  void _throwIfUnsuccessful(
    AddressResponseEnvelopeModel envelope,
    String operation,
  ) {
    if (!envelope.isSucceeded) {
      throw RemoteException(
        code: FailureCode.validation,
        message: envelope.message.isEmpty
            ? '$operation request was not successful'
            : envelope.message,
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
        return RemoteException(
          code: _failureCodeForStatus(error.response?.statusCode),
          message: _responseMessage(error.response?.data) ??
              'Address request failed',
        );

      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return const RemoteException(
          code: FailureCode.unknown,
          message: 'Address request failed',
        );
    }
  }

  FailureCode _failureCodeForStatus(int? statusCode) {
    if (statusCode == 400) {
      return FailureCode.validation;
    }
    if (statusCode == 401 || statusCode == 403) {
      return FailureCode.invalidCredentials;
    }
    return FailureCode.unknown;
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
