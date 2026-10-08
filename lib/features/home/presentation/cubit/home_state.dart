import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/home_category.dart';
import '../../domain/entities/restaurant_summary.dart';

enum HomeStatus { initial, loading, loaded, failure }

class HomeState extends Equatable {
  const HomeState({
    required this.status,
    this.userName,
    this.categories = const <HomeCategory>[],
    this.restaurants = const <RestaurantSummary>[],
    this.failure,
  });

  const HomeState.initial() : this(status: HomeStatus.initial);

  final HomeStatus status;

  /// Display name stored with the session; null until it is read, or when the
  /// profile has none.
  final String? userName;

  /// Catalog categories. Empty until the catalog API is connected.
  final List<HomeCategory> categories;

  /// Restaurant previews. Empty until the restaurants API is connected.
  final List<RestaurantSummary> restaurants;

  final Failure? failure;

  bool get isLoading => status == HomeStatus.loading;
  bool get hasFailure => status == HomeStatus.failure;

  @override
  List<Object?> get props => <Object?>[
        status,
        userName,
        categories,
        restaurants,
        failure,
      ];
}
