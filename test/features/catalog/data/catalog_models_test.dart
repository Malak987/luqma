import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/features/catalog/data/models/cuisine_model.dart';
import 'package:luqma_app/features/catalog/data/models/cuisine_response_model.dart';
import 'package:luqma_app/features/catalog/data/models/store_model.dart';
import 'package:luqma_app/features/catalog/data/models/store_page_model.dart';

import '../support/catalog_fixtures.dart';

void main() {
  test('Cuisine retains both names, nullable artwork, order and active status',
      () {
    final model = CuisineModel.fromJson(cuisineJson());
    expect(model.toDomain(), cuisine());
    expect(model.imageUrl, isNull);
    expect(
        CuisineModel.fromJson(
                cuisineJson(imageUrl: '  https://example.test/a.png  '))
            .imageUrl,
        'https://example.test/a.png');
    expect(
        CuisineModel.fromJson(cuisineJson(active: false, order: 5)).toDomain(),
        cuisine(active: false, order: 5));
  });

  test('Cuisine envelope accepts an empty list but not an unsuccessful request',
      () {
    expect(CuisineResponseModel.fromJson(catalogEnvelope(data: [])).items,
        isEmpty);
    expect(
        () => CuisineResponseModel.fromJson(catalogEnvelope(
              data: null,
              succeeded: false,
              message: 'Rejected',
            )),
        throwsA(isA<RemoteException>()
            .having((e) => e.code, 'code', FailureCode.validation)));
  });

  test('Cuisine rejects malformed envelopes and entries, never partial success',
      () {
    final responses = <Object?>[
      null,
      [],
      'not JSON',
      {},
      catalogEnvelope(data: null),
      catalogEnvelope(data: {}),
      catalogEnvelope(data: [cuisineJson(), null]),
      catalogEnvelope(data: [cuisineJson()..remove('nameAr')]),
      catalogEnvelope(data: [cuisineJson()..['id'] = 'not-an-id']),
      catalogEnvelope(data: [cuisineJson()..['displayOrder'] = 1.5]),
      catalogEnvelope(data: [cuisineJson()..['isActive'] = 'true']),
      catalogEnvelope(data: [cuisineJson()..['imageUrl'] = 1]),
      catalogEnvelope(data: [])..remove('data'),
      catalogEnvelope(data: [])..['isSucceeded'] = 'true',
      catalogEnvelope(data: [])..['timestamp'] = 7,
    ];
    for (final value in responses) {
      expect(() => CuisineResponseModel.fromJson(value), throwsFormatException);
    }
  });

  test('Store maps localized card fields from the Store response', () {
    final json = storeJson(
      descriptionAr: 'وصف مطعم حقيقي',
      descriptionEn: 'A real restaurant description',
      cuisines: <Object?>[
        <String, Object?>{'nameAr': 'إيطالي', 'nameEn': 'Italian'},
        <String, Object?>{'nameAr': 'مشويات', 'nameEn': 'Grills'},
      ],
      averageRating: 4.5,
      ratingsCount: 18,
      distanceKm: 2.75,
      deliveryTimeMinutes: 35,
      deliveryFee: 20,
      priceLevel: r'$$',
      latitude: 26.56,
      longitude: 31.69,
    );
    final decodedStore = StoreModel.fromJson(json).toDomain();

    expect(decodedStore.nameAr, 'مطعم النيل');
    expect(decodedStore.nameEn, 'Nile Kitchen');
    expect(decodedStore.descriptionAr, 'وصف مطعم حقيقي');
    expect(decodedStore.descriptionEn, 'A real restaurant description');
    expect(decodedStore.cuisines.map((cuisine) => cuisine.nameEn),
        <String?>['Italian', 'Grills']);
    expect(decodedStore.averageRating, 4.5);
    expect(decodedStore.ratingsCount, 18);
    expect(decodedStore.distanceKm, 2.75);
    expect(decodedStore.deliveryTimeMinutes, 35);
    expect(decodedStore.deliveryFee, 20);
    expect(decodedStore.priceLevel, r'$$');
    expect(decodedStore.latitude, 26.56);
    expect(decodedStore.longitude, 31.69);
    expect(StoreModel.fromJson(storeJson(open: false)).toDomain(),
        store(open: false));
  });

  test('missing optional Store card fields stay absent without defaults', () {
    final model = StoreModel.fromJson(storeJson(open: null));
    final store = model.toDomain();

    expect(store.isOpenNow, isNull);
    expect(store.descriptionAr, isNull);
    expect(store.descriptionEn, isNull);
    expect(store.cuisines, isEmpty);
    expect(store.averageRating, isNull);
    expect(store.ratingsCount, isNull);
    expect(store.distanceKm, isNull);
    expect(store.deliveryTimeMinutes, isNull);
    expect(store.deliveryFee, isNull);
    expect(store.priceLevel, isNull);
    expect(store.latitude, isNull);
    expect(store.longitude, isNull);
    expect(StoreModel.fromJson(storeJson(address: null, iconUrl: null)).address,
        isNull);
    expect(StoreModel.fromJson(storeJson()..remove('address')).address, isNull);
  });

  test('invalid optional card values do not become misleading display values',
      () {
    final json = storeJson()
      ..['averageRating'] = double.infinity
      ..['ratingsCount'] = 1.5
      ..['distanceKm'] = double.nan
      ..['deliveryTimeMinutes'] = 20.5
      ..['deliveryFee'] = 'free'
      ..['priceLevel'] = 2
      ..['isOpenNow'] = 'open'
      ..['latitude'] = 91
      ..['longitude'] = 'invalid'
      ..['cuisines'] = <Object?>[
        <String, Object?>{'nameAr': ''},
        <String, Object?>{'nameEn': 42},
        'not an object',
      ];
    final store = StoreModel.fromJson(json).toDomain();

    expect(store.averageRating, isNull);
    expect(store.ratingsCount, isNull);
    expect(store.distanceKm, isNull);
    expect(store.deliveryTimeMinutes, isNull);
    expect(store.deliveryFee, isNull);
    expect(store.priceLevel, isNull);
    expect(store.isOpenNow, isNull);
    expect(store.latitude, 91);
    expect(store.longitude, isNull);
    expect(store.cuisines, isEmpty);
  });

  test(
      'optional documented phone/category text is retained without formatting guesses',
      () {
    final json = storeJson()
      ..['phoneNumber'] = '+20 100 000 0000'
      ..['mainCategoryNameAr'] = 'مطاعم'
      ..['mainCategoryNameEn'] = 'Restaurants';
    expect(
        StoreModel.fromJson(json).toDomain(),
        store(
            phoneNumber: '+20 100 000 0000',
            categoryNameAr: 'مطاعم',
            categoryNameEn: 'Restaurants'));
    expect(() => StoreModel.fromJson(storeJson()..['phoneNumber'] = 123),
        throwsFormatException);
  });

  test('page decoder preserves every authoritative metadata value', () {
    // A short page still has more pages because the SERVER says so.
    final decoded = StorePageModel.fromJson(storeResponseJson(
      items: [storeJson()],
      number: 2,
      pages: 9,
      count: 177,
      previous: true,
      next: true,
    ));
    expect(decoded.items.single.toDomain(), store());
    expect(decoded.pageNumber, 2);
    expect(decoded.totalPages, 9);
    expect(decoded.totalCount, 177);
    expect(decoded.hasPreviousPage, isTrue);
    expect(decoded.hasNextPage, isTrue);
    expect(() => decoded.items.clear(), throwsUnsupportedError);
  });

  test(
      'requires the confirmed data.items envelope, rejecting root pages/wrappers',
      () {
    // Container placement was confirmed by the user; fixtures remain synthetic.
    expect(
        StorePageModel.fromJson(catalogEnvelope(data: storePageJson())).items,
        isEmpty);
    expect(
        () => StorePageModel.fromJson(storePageJson()), throwsFormatException);
    expect(() => StorePageModel.fromJson({'data': storePageJson()}),
        throwsFormatException);
    expect(
        () => StorePageModel.fromJson(
            catalogEnvelope(data: null, succeeded: false)),
        throwsA(isA<RemoteException>()));
  });

  test(
      'Store rejects malformed identifiers, required fields and paging metadata',
      () {
    final invalidStores = <Object?>[
      null,
      1,
      [],
      storeJson()..remove('nameEn'),
      storeJson()..['nameAr'] = ' ',
      storeJson()..['id'] = 3,
      storeJson()..['id'] = 'not-an-id',
      storeJson()..['mainCategoryId'] = '',
      storeJson()..['isActive'] = null,
      storeJson()..['address'] = [],
      storeJson()..['iconUrl'] = 4,
    ];
    for (final json in invalidStores) {
      expect(() => StoreModel.fromJson(json), throwsFormatException);
    }
    final invalidPages = <Object?>[
      null,
      [],
      {'items': []},
      storePageJson()..remove('hasNextPage'),
      storePageJson()..['pageNumber'] = -1,
      storePageJson()..['totalPages'] = -1,
      storePageJson()..['totalCount'] = -1,
      storePageJson()..['hasNextPage'] = 'true',
      storePageJson()..['items'] = {},
      storePageJson(items: [storeJson(), null]),
    ];
    for (final json in invalidPages) {
      expect(() => StorePageModel.fromJson(catalogEnvelope(data: json)),
          throwsFormatException);
    }
  });
}
