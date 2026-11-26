import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_line.dart';

enum CartStatus { initial, loading, empty, populated, error }

/// One immutable cart state shared by the menu, the cart tab and the badge.
///
/// [cart] is always the *display* cart: the last confirmed server snapshot
/// with the customer's not-yet-confirmed quantity changes already applied, so
/// the UI never has to wait for the network to show a tap.
class CartState extends Equatable {
  const CartState({
    required this.status,
    this.cart,
    this.failure,
    this.mutatingLineKeys = const <String>{},
    this.isClearing = false,
    this.isSynchronizationFailure = false,
    this.hasUnpricedLines = false,
  });

  const CartState.initial() : this(status: CartStatus.initial);

  final CartStatus status;
  final Cart? cart;
  final Failure? failure;

  /// Exact line keys whose latest change is still being confirmed.
  final Set<String> mutatingLineKeys;
  final bool isClearing;

  /// The background reconcile failed; the shown cart may be slightly stale.
  final bool isSynchronizationFailure;

  /// A brand-new line was added and is waiting for its server price. It is
  /// counted in the badge but cannot be listed or priced yet.
  final bool hasUnpricedLines;

  /// Something is waiting on the server. Informational only: it never blocks
  /// taps on other lines.
  bool get isMutating => isClearing || mutatingLineKeys.isNotEmpty;

  bool isLineMutating(CartLine line) =>
      mutatingLineKeys.contains(cartLineMutationKey(line));

  List<CartLine> get items => cart?.items ?? const <CartLine>[];

  /// Badge and header count: the display cart's own total quantity.
  int get badgeQuantity => cart?.totalQuantity ?? 0;
  int get totalQuantity => badgeQuantity;

  num? get subTotal => cart?.subTotal;
  bool get isLoading => status == CartStatus.loading;
  bool get isEmpty => status == CartStatus.empty;
  bool get isPopulated => status == CartStatus.populated;
  bool get hasError => status == CartStatus.error;

  CartState copyWith({
    CartStatus? status,
    Cart? cart,
    Failure? failure,
    bool clearFailure = false,
    Set<String>? mutatingLineKeys,
    bool? isClearing,
    bool? isSynchronizationFailure,
    bool? hasUnpricedLines,
  }) => CartState(
    status: status ?? this.status,
    cart: cart ?? this.cart,
    failure: clearFailure ? null : failure ?? this.failure,
    mutatingLineKeys: mutatingLineKeys ?? this.mutatingLineKeys,
    isClearing: isClearing ?? this.isClearing,
    isSynchronizationFailure:
        isSynchronizationFailure ?? this.isSynchronizationFailure,
    hasUnpricedLines: hasUnpricedLines ?? this.hasUnpricedLines,
  );

  @override
  List<Object?> get props => <Object?>[
    status,
    cart,
    failure,
    mutatingLineKeys,
    isClearing,
    isSynchronizationFailure,
    hasUnpricedLines,
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
  final normalizedAddonIds = addonIds.map((id) => id.trim().toLowerCase()).toList()
    ..sort();
  return jsonEncode(<Object?>[
    menuItemId.trim().toLowerCase(),
    optionId == null || optionId.isEmpty ? null : optionId.toLowerCase(),
    normalizedAddonIds,
  ]);
}
