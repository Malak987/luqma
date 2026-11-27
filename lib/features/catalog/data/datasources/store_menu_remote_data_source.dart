import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/queries/menu_item_query.dart';
import '../models/menu_category_model.dart';
import '../models/menu_category_response_model.dart';
import '../models/menu_item_page_model.dart';

abstract interface class StoreMenuRemoteDataSource {
  Future<List<MenuCategoryModel>> getActiveCategories(String storeId);
  Future<MenuItemPageModel> getItems(MenuItemQuery query);
}

class StoreMenuRemoteDataSourceImpl implements StoreMenuRemoteDataSource {
  const StoreMenuRemoteDataSourceImpl(this._client);
  final DioClient _client;

  @override
  Future<List<MenuCategoryModel>> getActiveCategories(String storeId) => _get(
      ApiConstants.getAllMenuCategories,
      {'storeId': storeId, 'onlyActive': true},
      (data) => MenuCategoryResponseModel.fromJson(data).items);

  @override
  Future<MenuItemPageModel> getItems(MenuItemQuery query) {
    final filters = query.filters;
    final search = filters.search?.trim();
    return _get(
        ApiConstants.getAllMenuItems,
        <String, Object>{
          'storeId': query.storeId, 'isActive': true,
          'pageNumber': query.pageNumber, 'pageSize': query.pageSize,
          if (filters.menuCategoryId != null)
            'menuCategoryId': filters.menuCategoryId!,
          if (search != null && search.isNotEmpty) 'search': search,
          if (filters.minPrice != null) 'minPrice': filters.minPrice!,
          if (filters.maxPrice != null) 'maxPrice': filters.maxPrice!,
          if (filters.saleOnly) 'onSale': true,
          // Accepted sortBy values are not verified, so none are sent.
        },
        MenuItemPageModel.fromJson);
  }

  Future<T> _get<T>(
      String path, Map<String, Object> query, T Function(Object?) parse) async {
    try {
      // Public browsing: no auth extra, token read, manual bearer or signout.
      final response =
          await _client.dio.get<Object?>(path, queryParameters: query);
      return parse(response.data);
    } on DioException catch (error) {
      debugPrint('[catalog] GET $path -> ${error.type} '
          'status=${error.response?.statusCode} body=${error.response?.data} '
          'err=${error.error}');
      throw _mapError(error);
    } on RemoteException {
      rethrow;
    } on FormatException catch (error) {
      debugPrint('[catalog] parse error on $path: ${error.message}');
      throw RemoteException(
          code: FailureCode.unknown,
          message: 'Invalid menu response: ${error.message}');
    }
  }

  RemoteException _mapError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return const RemoteException(
            code: FailureCode.network, message: 'Menu network request failed');
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        return RemoteException(
            code: status == 400
                ? FailureCode.validation
                : status == 401 || status == 403
                    ? FailureCode.invalidCredentials
                    : FailureCode.unknown,
            message: 'Menu request failed');
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return const RemoteException(
            code: FailureCode.unknown, message: 'Menu request failed');
    }
  }
}
