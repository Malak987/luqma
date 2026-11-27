import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/cart_count_model.dart';
import '../models/cart_line_model.dart';
import '../models/cart_model.dart';
import '../models/cart_mutation_request_model.dart';
import '../models/cart_response_envelope_model.dart';
import '../models/cart_update_result_model.dart';

abstract interface class CartRemoteDataSource {
  Future<CartLineModel> addToCart(CartMutationRequestModel request);
  Future<CartUpdateResultModel> updateToCart(CartMutationRequestModel request);
  Future<void> clearCart();
  Future<CartModel> getMyCart();
  Future<CartCountModel> getCount();
}

class CartRemoteDataSourceImpl implements CartRemoteDataSource {
  const CartRemoteDataSourceImpl(this._dioClient);

  final DioClient _dioClient;

  Options get _authenticatedOptions => Options(
        extra: <String, dynamic>{
          DioClient.requiresAuthenticationExtraKey: true,
        },
      );

  @override
  Future<CartLineModel> addToCart(CartMutationRequestModel request) =>
      _postLine(ApiConstants.addToCart, request, 'AddToCart');

  @override
  Future<CartUpdateResultModel> updateToCart(
          CartMutationRequestModel request) =>
      _putUpdateToCart(request);

  @override
  Future<void> clearCart() async {
    try {
      // The confirmed Clear contract specifies the route and method, but not a
      // response body. Empty success is accepted. When an API envelope is
      // present, validate the already-established Cart envelope rather than
      // guessing a Clear-specific data model. The cubit still obtains fresh
      // Cart and GetCount snapshots for the resulting content and badge.
      final response = await _dioClient.dio.delete<Object?>(
        ApiConstants.clearCart,
        options: _authenticatedOptions,
      );
      if (response.data != null) {
        CartResponseEnvelopeModel.fromJson(response.data)
            .requireSuccess('Clear');
      }
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on RemoteException {
      rethrow;
    } on FormatException {
      throw const RemoteException(
        code: FailureCode.unknown,
        message: 'Invalid Clear response',
      );
    }
  }

  @override
  Future<CartModel> getMyCart() async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        ApiConstants.getMyCart,
        options: _authenticatedOptions,
      );
      final data = CartResponseEnvelopeModel.fromJson(
        response.data,
      ).requireSuccess('GetMyCart');
      return CartModel.fromJson(data);
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on RemoteException {
      rethrow;
    } on FormatException {
      throw const RemoteException(
        code: FailureCode.unknown,
        message: 'Invalid GetMyCart response',
      );
    }
  }

  @override
  Future<CartCountModel> getCount() async {
    try {
      final response = await _dioClient.dio.get<Object?>(
        ApiConstants.getCartCount,
        options: _authenticatedOptions,
      );
      final data = CartResponseEnvelopeModel.fromJson(
        response.data,
      ).requireSuccess('GetCount');
      return CartCountModel.fromJson(data);
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on RemoteException {
      rethrow;
    } on FormatException {
      throw const RemoteException(
        code: FailureCode.unknown,
        message: 'Invalid GetCount response',
      );
    }
  }

  Future<CartLineModel> _postLine(
    String path,
    CartMutationRequestModel request,
    String operation,
  ) async {
    try {
      final response = await _dioClient.dio.post<Object?>(
        path,
        data: request.toJson(),
        options: _authenticatedOptions,
      );
      final data = CartResponseEnvelopeModel.fromJson(
        response.data,
      ).requireSuccess(operation);
      return CartLineModel.fromJson(data);
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on RemoteException {
      rethrow;
    } on FormatException {
      throw RemoteException(
        code: FailureCode.unknown,
        message: 'Invalid $operation response',
      );
    }
  }

  Future<CartUpdateResultModel> _putUpdateToCart(
    CartMutationRequestModel request,
  ) async {
    try {
      final response = await _dioClient.dio.put<Object?>(
        ApiConstants.updateToCart,
        // UpdateToCart uses this nullable value to target the exact no-option
        // or selected-option line. Empty add-on lists are likewise retained.
        data: request.toJson(preserveNullOptionId: true),
        options: _authenticatedOptions,
      );
      final data = CartResponseEnvelopeModel.fromJson(
        response.data,
      ).requireSuccess('UpdateToCart');
      return CartUpdateResultModel.fromJson(data);
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on RemoteException {
      rethrow;
    } on FormatException {
      throw const RemoteException(
        code: FailureCode.unknown,
        message: 'Invalid UpdateToCart response',
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
          message: 'Cart network request failed',
        );
      case DioExceptionType.badResponse:
        return RemoteException(
          code: _failureCodeForStatus(error.response?.statusCode),
          message:
              _responseMessage(error.response?.data) ?? 'Cart request failed',
          backendCode: _responseErrorCode(error.response?.data),
        );
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return const RemoteException(
          code: FailureCode.unknown,
          message: 'Cart request failed',
        );
    }
  }

  FailureCode _failureCodeForStatus(int? statusCode) {
    if (statusCode == 400) return FailureCode.validation;
    if (statusCode == 401 || statusCode == 403) {
      return FailureCode.invalidCredentials;
    }
    return FailureCode.unknown;
  }

  String? _responseErrorCode(Object? body) {
    if (body is Map<Object?, Object?> && body['errorCode'] is String) {
      return (body['errorCode'] as String).trim();
    }
    return null;
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
