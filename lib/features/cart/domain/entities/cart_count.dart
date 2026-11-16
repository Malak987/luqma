import 'package:equatable/equatable.dart';

/// The exact count payload returned by GetCount.
class CartCount extends Equatable {
  const CartCount({required this.linesCount, required this.totalQuantity});

  final int linesCount;
  final int totalQuantity;

  @override
  List<Object> get props => <Object>[linesCount, totalQuantity];
}
