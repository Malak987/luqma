import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_count.dart';
import '../../domain/entities/cart_line.dart';

enum CartStatus { initial, loading, empty, populated, error }

/// One API-backed cart state shared by menu mutations, cart content and badge.
class CartState extends Equatable {
  const CartState({
    required this.status,
    this.cart,
    this.count,
    this.failure,
    this.mutatingLineKeys = const <String>{},
    this.isClearing = false,
    this.isSynchronizing = false,
    this.isSynchronizationFailure = false,
  });

  const CartState.initial() : this(status: CartStatus.initial);

  final CartStatus status;
  final Cart? cart;
  final CartCount? count;
  final Failure? failure;
  final Set<String> mutatingLineKeys;
  final bool isClearing;
  final bool isSynchronizing;
  final bool isSynchronizationFailure;

  /// Compatibility summary: any server mutation is in flight.
  bool get isMutating => isClearing || mutatingLineKeys.isNotEmpty;

  bool isLineMutating(CartLine line) =>
      isClearing || mutatingLineKeys.contains(cartLineMutationKey(line));

  List<CartLine> get items => cart?.items ?? const <CartLine>[];

  /// The badge intentionally uses GetCount.totalQuantity rather than line
  /// count. It is never re-derived from displayed items.
  int get badgeQuantity => count?.totalQuantity ?? 0;

  int get totalQuantity => count?.totalQuantity ?? cart?.totalQuantity ?? 0;
  num? get subTotal => cart?.subTotal;
  bool get isLoading => status == CartStatus.loading;
  bool get isEmpty => status == CartStatus.empty;
  bool get isPopulated => status == CartStatus.populated;
  bool get hasError => status == CartStatus.error;

  CartState copyWith({
    CartStatus? status,
    Cart? cart,
    CartCount? count,
    Failure? failure,
    bool clearFailure = false,
    Set<String>? mutatingLineKeys,
    bool? isClearing,
    bool? isSynchronizing,
    bool? isSynchronizationFailure,
  }) =>
      CartState(
        status: status ?? this.status,
        cart: cart ?? this.cart,
        count: count ?? this.count,
        failure: clearFailure ? null : failure ?? this.failure,
        mutatingLineKeys: mutatingLineKeys ?? this.mutatingLineKeys,
        isClearing: isClearing ?? this.isClearing,
        isSynchronizing: isSynchronizing ?? this.isSynchronizing,
        isSynchronizationFailure:
            isSynchronizationFailure ?? this.isSynchronizationFailure,
      );

  @override
  List<Object?> get props => <Object?>[
        status,
        cart,
        count,
        failure,
        mutatingLineKeys,
        isClearing,
        isSynchronizing,
        isSynchronizationFailure,
      ];
}

String cartLineMutationKey(CartLine line) => cartMutationKey(
      line.menuItemId,
      line.menuItemOptionId,
      line.addons.map((addon) => addon.id).toList(growable: false),
    );

String cartMutationKey(
  String menuItemId,
  String? menuItemOptionId,
  List<String> addonIds,
) {
  final optionId = menuItemOptionId?.trim();
  final normalizedAddonIds = addonIds
      .map((id) => id.trim().toLowerCase())
      .toList()
    ..sort();
  return jsonEncode(<Object?>[
    menuItemId.trim().toLowerCase(),
    optionId == null || optionId.isEmpty ? null : optionId.toLowerCase(),
    normalizedAddonIds,
  ]);
}
