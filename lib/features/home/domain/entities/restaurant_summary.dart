import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// One restaurant preview of the home screen.
///
/// This is the UI-side contract for the restaurants endpoint. Keeping it
/// minimal means the section can render real API data as soon as it exists
/// without carrying speculative fields; nothing is mocked until then.
@immutable
class RestaurantSummary extends Equatable {
  const RestaurantSummary({
    required this.id,
    required this.name,
    this.imageUrl,
  });

  final String id;
  final String name;

  /// Remote artwork, when the API supplies one. Null renders a placeholder.
  final String? imageUrl;

  @override
  List<Object?> get props => <Object?>[id, name, imageUrl];
}
