import 'package:equatable/equatable.dart';

/// How the list of stores is ordered. [recommended] is the server's own order.
enum StoreSort { recommended, popular, nearest }

/// Delivery or pickup. Kept as UI state until the backend exposes it
/// (see BACKEND_MISSING_DATA.md).
enum StoreOrderMode { delivery, pickup }

/// Inclusive price band chosen in the price range sheet.
class StorePriceRange extends Equatable {
  const StorePriceRange({required this.min, required this.max});

  final num min;
  final num max;

  @override
  List<Object?> get props => <Object?>[min, max];
}
