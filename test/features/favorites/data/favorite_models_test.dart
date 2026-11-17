import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/features/favorites/data/models/favorite_menu_item_model.dart';
import 'package:luqma_app/features/favorites/data/models/favorite_page_model.dart';
import 'package:luqma_app/features/favorites/data/models/favorite_response_envelope_model.dart';

import '../support/favorite_fixtures.dart';

void main() {
  test('Favorite item and page preserve supplied menu projection fields', () {
    final item = FavoriteMenuItemModel.fromJson(favoriteItemJson()).toDomain();
    final page = FavoritePageModel.fromJson(
      favoriteEnvelope(
        data: favoritePageJson(
          items: <Object?>[favoriteItemJson()],
          totalCount: 1,
        ),
      ),
    );

    expect(item.id, favoriteId);
    expect(item.menuItemId, favoriteMenuItemId);
    expect(item.nameAr, 'طبق النيل');
    expect(item.compareAtPrice, 150);
    expect(item.hasSale, isTrue);
    expect(item.addedAt, isNotEmpty);
    expect(page.items.single.menuItemId, favoriteMenuItemId);
    expect(page.totalCount, 1);
    expect(() => page.items.clear(), throwsUnsupportedError);
  });

  test('invalid Favorite data and envelopes fail rather than being fabricated',
      () {
    expect(
      () => FavoriteMenuItemModel.fromJson(
        favoriteItemJson()..['menuItemId'] = 'not-a-uuid',
      ),
      throwsFormatException,
    );
    expect(
      () => FavoritePageModel.fromJson(
        favoriteEnvelope(data: favoritePageJson()..['items'] = <Object?>{}),
      ),
      throwsFormatException,
    );
    expect(
      () => FavoriteResponseEnvelopeModel.fromJson(<String, Object?>{
        'message': 'ok',
        'isSucceeded': true,
        'timestamp': 'now',
      }),
      throwsFormatException,
    );
  });
}
