import 'package:equatable/equatable.dart';

/// The only documented field guaranteed by an UpdateToCart response.
///
/// Cart content and quantities always come from the authoritative GetMyCart
/// and GetCount snapshots that follow a successful update.
class CartUpdateResult extends Equatable {
  const CartUpdateResult({required this.isRemoved});

  final bool isRemoved;

  @override
  List<Object> get props => <Object>[isRemoved];
}
