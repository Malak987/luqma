import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// One restaurant preview of the home screen.
///
/// This is the UI-side contract for the restaurants endpoint. Everything but
/// [id] and [name] is optional, so the card renders whatever the API supplies
/// and nothing is mocked until the data exists.
@immutable
class RestaurantSummary extends Equatable {
  const RestaurantSummary({
    required this.id,
    required this.name,
    this.imageUrl,
    this.rating,
    this.deliveryTime,
    this.badge,
  });

  final String id;
  final String name;

  /// Remote artwork, when the API supplies one. Null renders a placeholder.
  final String? imageUrl;

  /// Average rating, e.g. 4.8.
  final double? rating;

  /// Localized delivery estimate, e.g. "20-25 min".
  final String? deliveryTime;

  /// Short promotional label, e.g. "1+1 free".
  final String? badge;

  @override
  List<Object?> get props =>
      <Object?>[id, name, imageUrl, rating, deliveryTime, badge];
}
