import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../catalog/domain/entities/store.dart';
import '../../domain/entities/home_category.dart';

enum HomeStatus { initial, loading, loaded, failure }
enum HomeCategoriesStatus { initial, loading, success, empty, error }
enum HomeRestaurantsStatus {
  initial,
  loading,
  success,
  empty,
  error,
  unavailable,
}

class HomeState extends Equatable {
  const HomeState({
    required this.status,
    this.userName,
    this.categories = const <HomeCategory>[],
    this.categoriesStatus = HomeCategoriesStatus.initial,
    this.categoriesFailure,
    this.restaurants = const <Store>[],
    this.restaurantsStatus = HomeRestaurantsStatus.initial,
    this.restaurantsFailure,
    this.failure,
  });

  const HomeState.initial() : this(status: HomeStatus.initial);

  final HomeStatus status;

  /// Display name stored with the session; null until it is read, or when the
  /// profile has none.
  final String? userName;

  /// Active catalog categories in display order, independent of profile state.
  final List<HomeCategory> categories;
  final HomeCategoriesStatus categoriesStatus;
  final Failure? categoriesFailure;

  /// Restaurant preview from the existing Store API. No sample stores are used.
  final List<Store> restaurants;
  final HomeRestaurantsStatus restaurantsStatus;
  final Failure? restaurantsFailure;

  final Failure? failure;

  bool get isLoading => status == HomeStatus.loading;
  bool get hasFailure => status == HomeStatus.failure;

  HomeState copyWith({
    HomeStatus? status,
    String? userName,
    bool clearUserName = false,
    List<HomeCategory>? categories,
    HomeCategoriesStatus? categoriesStatus,
    Failure? categoriesFailure,
    bool clearCategoriesFailure = false,
    List<Store>? restaurants,
    HomeRestaurantsStatus? restaurantsStatus,
    Failure? restaurantsFailure,
    bool clearRestaurantsFailure = false,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return HomeState(
      status: status ?? this.status,
      userName: clearUserName ? null : userName ?? this.userName,
      categories: categories ?? this.categories,
      categoriesStatus: categoriesStatus ?? this.categoriesStatus,
      categoriesFailure: clearCategoriesFailure
          ? null
          : categoriesFailure ?? this.categoriesFailure,
      restaurants: restaurants ?? this.restaurants,
      restaurantsStatus: restaurantsStatus ?? this.restaurantsStatus,
      restaurantsFailure: clearRestaurantsFailure
          ? null
          : restaurantsFailure ?? this.restaurantsFailure,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        userName,
        categories,
        categoriesStatus,
        categoriesFailure,
        restaurants,
        restaurantsStatus,
        restaurantsFailure,
        failure,
      ];
}
