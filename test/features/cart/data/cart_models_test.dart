import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/features/cart/data/models/cart_count_model.dart';
import 'package:luqma_app/features/cart/data/models/cart_line_model.dart';
import 'package:luqma_app/features/cart/data/models/cart_model.dart';
import 'package:luqma_app/features/cart/data/models/cart_mutation_request_model.dart';
import 'package:luqma_app/features/cart/data/models/cart_response_envelope_model.dart';
import 'package:luqma_app/features/cart/domain/entities/cart_mutation.dart';

import '../support/cart_fixtures.dart';

void main() {
  test('verified cart line fields map exactly, including selected addons', () {
    final model = CartLineModel.fromJson(
      cartLineJson(addons: <Object?>[cartAddonJson()]),
    );
    final line = model.toDomain();
    expect(line.id, cartLineId);
    expect(line.menuItemId, cartMenuItemId);
    expect(line.nameAr, 'وجبة فراخ مشوية');
    expect(line.optionNameEn, 'Double');
    expect(line.optionPrice, 70);
    expect(line.unitPrice, 270);
    expect(line.quantity, 2);
    expect(line.lineTotal, 540);
    expect(line.addons.single.nameEn, 'Extra Rice');
    expect(line.isRemoved, isFalse);
    expect(line.isAvailable, isTrue);
    expect(() => model.addons.clear(), throwsUnsupportedError);
  });

  test(
    'absent option values stay nullable rather than becoming fake choices',
    () {
      final line = CartLineModel.fromJson(
        cartLineJson(
          menuItemOptionId: null,
          optionNameAr: null,
          optionNameEn: null,
          optionPrice: null,
        ),
      ).toDomain();
      expect(line.menuItemOptionId, isNull);
      expect(line.optionNameAr, isNull);
      expect(line.optionNameEn, isNull);
      expect(line.optionPrice, isNull);
    },
  );

  test('GetMyCart and GetCount preserve only documented outer fields', () {
    final cartSnapshot = CartModel.fromJson(
      cartJson(
        items: <Object?>[cartLineJson()],
        totalQuantity: 2,
        subTotal: 540,
      ),
    ).toDomain();
    final count = CartCountModel.fromJson(
      cartCountJson(linesCount: 1, totalQuantity: 2),
    ).toDomain();
    expect(cartSnapshot.items.single.id, cartLineId);
    expect(cartSnapshot.totalQuantity, 2);
    expect(cartSnapshot.subTotal, 540);
    expect(count.linesCount, 1);
    expect(count.totalQuantity, 2);
  });

  test(
    'request sends only documented fields and omits an unselected option',
    () {
      final request = CartMutationRequestModel.fromDomain(
        CartMutation(
          menuItemId: cartMenuItemId,
          quantity: 1,
          addonIds: const <String>[],
        ),
      );
      expect(request.toJson(), <String, Object>{
        'menuItemId': cartMenuItemId,
        'quantity': 1,
        'addonIds': const <String>[],
      });
    },
  );

  test(
    'invalid line and envelope shapes fail rather than being fabricated',
    () {
      expect(
        () => CartLineModel.fromJson(cartLineJson()..['quantity'] = 0),
        throwsFormatException,
      );
      expect(
        () => CartModel.fromJson(cartJson()..['items'] = {}),
        throwsFormatException,
      );
      expect(
        () => CartCountModel.fromJson(cartCountJson()..['linesCount'] = -1),
        throwsFormatException,
      );
      expect(
        () => CartResponseEnvelopeModel.fromJson(<String, Object?>{
          'message': 'ok',
          'isSucceeded': true,
          'timestamp': 'now',
        }),
        throwsFormatException,
      );
    },
  );
}
