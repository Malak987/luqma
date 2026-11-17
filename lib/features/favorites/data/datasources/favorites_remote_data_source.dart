import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/queries/favorite_identifiers.dart';
import '../models/favorite_menu_item_model.dart';
import '../models/favorite_page_model.dart';
import '../models/favorite_response_envelope_model.dart';

abstract interface class FavoritesRemoteDataSource {
  Future<FavoriteMenuItemModel> addToFavorites(String menuItemId);
  Future<String> removeFromFavorites(String menuItemId);
  Future<FavoritePageModel> getMyFavorites({
    required int pageNumber,
    required int pageSize,
  });
  Future<bool> isFavorite(String menuItemId);
  Future<int> getCount();
}

class FavoritesRemoteDataSourceImpl implements FavoritesRemoteDataSource {
  const FavoritesRemoteDataSourceImpl(this._dioClient);

  final DioClient _dioClient;

  Options get _authenticatedOptions => Options(
        extra: <String, dynamic>{
          DioClient.requiresAuthenticationExtraKey: true,
        },
      );

  @override
  Future<FavoriteMenuItemModel> addToFavorites(String menuItemId) => _request(
        () => _dioClient.dio.post<Object?>(
          ApiConstants.addToFavorites,
          data: <String, Object>{'menuItemId': menuItemId},
          options: _authenticatedOptions,
        ),
        'AddToFavorites',
        (body) => FavoriteMenuItemModel.fromJson(
          FavoriteResponseEnvelopeModel.fromJson(body)
              .requireSuccess('AddToFavorites'),
        ),
      );

  @override
  Future<String> removeFromFavorites(String menuItemId) async {
    try {
      // The returned identifier lets the cubit verify this response matches
      // the requested membership transition.
      final response = await _dioClient.dio.delete<Object?>(
        ApiConstants.removeFromFavorites(menuItemId),
        options: _authenticatedOptions,
      );
      final data = FavoriteResponseEnvelopeModel.fromJson(response.data)
          .requireSuccess('Remove');
      if (data is! String || !isFavoriteMenuItemId(data)) {
        throw const FormatException('Invalid Remove data');
      }
      return data;
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on RemoteException {
      rethrow;
    } on FormatException {
      throw const RemoteException(
        code: FailureCode.unknown,
        message: 'Invalid Remove response',
      );
    }
  }

  @override
  Future<FavoritePageModel> getMyFavorites({
    required int pageNumber,
    required int pageSize,
  }) =>
      _request(
        () => _dioClient.dio.get<Object?>(
          ApiConstants.getMyFavorites,
          queryParameters: <String, Object>{
            'pageNumber': pageNumber,
            'pageSize': pageSize,
          },
          options: _authenticatedOptions,
        ),
        'GetMyFavorites',
        FavoritePageModel.fromJson,
      );

  @override
  Future<bool> isFavorite(String menuItemId) => _request(
        () => _dioClient.dio.get<Object?>(
          ApiConstants.isFavorite(menuItemId),
          options: _authenticatedOptions,
        ),
        'IsFavorite',
        (body) {
          final data = FavoriteResponseEnvelopeModel.fromJson(body)
              .requireSuccess('IsFavorite');
          if (data is! bool) {
            throw const FormatException('Invalid IsFavorite data');
          }
          return data;
        },
      );

  @override
  Future<int> getCount() => _request(
        () => _dioClient.dio.get<Object?>(
          ApiConstants.getFavoritesCount,
          options: _authenticatedOptions,
        ),
        'GetCount',
        (body) {
          final data = FavoriteResponseEnvelopeModel.fromJson(body)
              .requireSuccess('GetCount');
          if (data is! num ||
              !data.isFinite ||
              data != data.roundToDouble() ||
              data < 0) {
            throw const FormatException('Invalid Favorite GetCount data');
          }
          return data.toInt();
        },
      );

  Future<T> _request<T>(
    Future<Response<Object?>> Function() request,
    String operation,
    T Function(Object?) parse,
  ) async {
    try {
      final response = await request();
      return parse(response.data);
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on RemoteException {
      rethrow;
    } on FormatException catch (error) {
      throw RemoteException(
        code: FailureCode.unknown,
        message: 'Invalid $operation response: ${error.message}',
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
          message: 'Favorites network request failed',
        );
      case DioExceptionType.badResponse:
        return RemoteException(
          code: _failureCodeForStatus(error.response?.statusCode),
          message: _responseMessage(error.response?.data) ??
              'Favorites request failed',
        );
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return const RemoteException(
          code: FailureCode.unknown,
          message: 'Favorites request failed',
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
