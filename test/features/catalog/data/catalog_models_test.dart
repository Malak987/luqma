import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/features/catalog/data/models/cuisine_model.dart';
import 'package:luqma_app/features/catalog/data/models/cuisine_response_model.dart';
import 'package:luqma_app/features/catalog/data/models/store_model.dart';
import 'package:luqma_app/features/catalog/data/models/store_page_model.dart';
import 'package:luqma_app/features/catalog/domain/entities/store.dart';

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
      images: <Object?>[
        'https://luqma-api.runasp.net/uploads/stores/cover-1.jpg',
        'https://luqma-api.runasp.net/uploads/stores/cover-2.jpg',
      ],
      openTime: '10:00:00',
      closeTime: '01:00:00',
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
    expect(decodedStore.images, <String>[
      'https://luqma-api.runasp.net/uploads/stores/cover-1.jpg',
      'https://luqma-api.runasp.net/uploads/stores/cover-2.jpg',
    ]);
    expect(decodedStore.openTime, '10:00:00');
    expect(decodedStore.closeTime, '01:00:00');
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
      ..['priceLevel'] = 9
      ..['isOpenNow'] = 'open'
      ..['images'] = 'https://luqma-api.runasp.net/uploads/stores/one.jpg'
      ..['openTime'] = 42
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
    expect(store.images, isEmpty);
    expect(store.openTime, isNull);
    expect(store.closeTime, isNull);
    expect(store.isOpenNow, isNull);
    expect(store.latitude, 91);
    expect(store.longitude, isNull);
    expect(store.cuisines, isEmpty);
  });

  test('Store accepts the real Store/GetAll payload shape', () {
    // Shape taken from the documented response: numeric priceLevel, images,
    // open/close times, and 0 for every value the owner has not filled in.
    final json = <String, Object?>{
      'id': storeId,
      'nameAr': 'ماروسكا',
      'nameEn': 'Marouska',
      'iconUrl': 'https://luqma-api.runasp.net/uploads/stores/2098.jpg',
      'openTime': '10:00:00',
      'closeTime': '01:00:00',
      'priceLevel': 2,
      'averageRating': 0,
      'ratingsCount': 0,
      'deliveryTimeMinutes': 0,
      'deliveryFee': 0,
      'latitude': 0,
      'longitude': 0,
      'isOpenNow': false,
      'mainCategoryId': categoryId,
      'isActive': true,
      'images': <Object?>[
        'https://luqma-api.runasp.net/uploads/stores/2098.jpg',
      ],
    };

    final store = StoreModel.fromJson(json).toDomain();

    expect(store.priceLevel, r'$$');
    expect(store.images, hasLength(1));
    expect(store.coverImageUrl,
        'https://luqma-api.runasp.net/uploads/stores/2098.jpg');
    expect(store.hasUploadedCover, isTrue);
    expect(store.hasUsableCoordinates, isFalse);
    expect(store.isOpenNow, isFalse);
    expect(store.openTime, '10:00:00');
    expect(store.closeTime, '01:00:00');
  });

  test('priceLevel maps numeric bands and hides unusable values', () {
    expect(
      StoreModel.fromJson(storeJson(priceLevel: 1)).toDomain().priceLevel,
      r'$',
    );
    expect(
      StoreModel.fromJson(storeJson(priceLevel: 4)).toDomain().priceLevel,
      r'$$$$',
    );
    for (final unusable in <Object?>[0, -1, 6, 2.5, '', '   ', true, null]) {
      final json = storeJson()..['priceLevel'] = unusable;
      expect(
        StoreModel.fromJson(json).toDomain().priceLevel,
        isNull,
        reason: 'priceLevel $unusable must not render',
      );
    }
    final text = storeJson()..['priceLevel'] = 'mid';
    expect(StoreModel.fromJson(text).toDomain().priceLevel, 'mid');
  });

  test('images keep only absolute http(s) URLs and preserve the first slot', () {
    final json = storeJson()
      ..['images'] = <Object?>[
        'https://luqma-api.runasp.net/uploads/stores/ok.jpg',
        'not a url',
        '',
        '   ',
        'ftp://example.test/x.jpg',
        '/uploads/relative.jpg',
        42,
        null,
        'https:///no-host.jpg',
        'https://luqma-api.runasp.net/uploads/stores/second.jpg',
      ];
    final store = StoreModel.fromJson(json).toDomain();

    expect(store.images, <String>[
      'https://luqma-api.runasp.net/uploads/stores/ok.jpg',
      'https://luqma-api.runasp.net/uploads/stores/second.jpg',
    ]);
    expect(store.coverImageUrl,
        'https://luqma-api.runasp.net/uploads/stores/ok.jpg');

    final nonList = storeJson()..['images'] = 'https://example.test/x.jpg';
    expect(StoreModel.fromJson(nonList).toDomain().images, isEmpty);
  });

  test('an unusable first photo is never replaced by a later one', () {
    final json = storeJson(
      iconUrl: 'https://luqma-api.runasp.net/uploads/logo.jpg',
    )..['images'] = <Object?>[
        'not a url',
        'https://luqma-api.runasp.net/uploads/stores/second.jpg',
      ];
    final store = StoreModel.fromJson(json).toDomain();

    // Slot 0 stays slot 0 (empty because the first entry is unusable), so the
    // card falls to the logo instead of promoting the second photo.
    expect(store.images, <String>[
      '',
      'https://luqma-api.runasp.net/uploads/stores/second.jpg',
    ]);
    expect(store.hasUploadedCover, isFalse);
    expect(store.coverImageUrl,
        'https://luqma-api.runasp.net/uploads/logo.jpg');
  });

  test('coverImageUrl falls back to iconUrl and then to null', () {
    final withIcon = StoreModel.fromJson(
      storeJson(iconUrl: 'https://luqma-api.runasp.net/uploads/logo.jpg'),
    ).toDomain();
    expect(withIcon.hasUploadedCover, isFalse);
    expect(withIcon.coverImageUrl,
        'https://luqma-api.runasp.net/uploads/logo.jpg');

    final withoutBoth = StoreModel.fromJson(storeJson()).toDomain();
    expect(withoutBoth.coverImageUrl, isNull);
  });

  group('restaurant cover priority', () {
    const logo = 'https://luqma-api.runasp.net/uploads/stores/logo.jpg';
    const cover = 'https://luqma-api.runasp.net/uploads/stores/cover.jpg';
    const second = 'https://luqma-api.runasp.net/uploads/stores/second.jpg';

    Store storeWith({List<String> images = const <String>[], String? iconUrl}) =>
        Store(
          id: 'store-cover',
          nameAr: 'غلاف',
          nameEn: 'Cover',
          mainCategoryId: '6f1c7b8e-1a2b-4c3d-8e4f-000000000001',
          isActive: true,
          iconUrl: iconUrl,
          images: images,
        );

    test('uses images[0] ahead of iconUrl', () {
      final store = storeWith(images: const <String>[cover, second], iconUrl: logo);

      expect(store.coverImageUrl, cover);
      expect(store.hasUploadedCover, isTrue);
    });

    test('never scans for a later photo when images[0] is blank', () {
      final store =
          storeWith(images: const <String>['', second], iconUrl: logo);

      // A blank first entry means "no cover photo"; the second one is not used.
      expect(store.coverImageUrl, logo);
      expect(store.hasUploadedCover, isFalse);
    });

    test('never scans for a later photo when images[0] is not a URL', () {
      for (final unusable in <String>[
        '/uploads/stores/relative.jpg',
        'ftp://example.test/cover.jpg',
        'https:///no-host.jpg',
        'https://luqma-api.runasp.net/uploads/my cover.jpg',
      ]) {
        final store =
            storeWith(images: <String>[unusable, second], iconUrl: logo);

        expect(store.coverImageUrl, logo, reason: 'images[0] was "$unusable"');
        expect(store.hasUploadedCover, isFalse);
      }
    });

    test('falls to iconUrl only when images[0] is unavailable', () {
      expect(storeWith(iconUrl: logo).coverImageUrl, logo);
      expect(
        storeWith(images: const <String>[], iconUrl: logo).coverImageUrl,
        logo,
      );
    });

    test('returns null when neither source is available', () {
      expect(storeWith().coverImageUrl, isNull);
      expect(
        storeWith(images: const <String>['', '  '], iconUrl: '  ')
            .coverImageUrl,
        isNull,
      );
      expect(storeWith(iconUrl: '/uploads/logo.jpg').coverImageUrl, isNull);
    });

    test('trims the cover URL before handing it to the image widget', () {
      final store = storeWith(
        images: const <String>['  $cover  '],
        iconUrl: logo,
      );

      expect(store.coverImageUrl, cover);
    });
  });

  test('hasUsableCoordinates rejects the 0,0 placeholder', () {
    expect(
      StoreModel.fromJson(storeJson(latitude: 0, longitude: 0))
          .toDomain()
          .hasUsableCoordinates,
      isFalse,
    );
    expect(
      StoreModel.fromJson(storeJson(latitude: 26.56, longitude: 31.69))
          .toDomain()
          .hasUsableCoordinates,
      isTrue,
    );
    expect(
      StoreModel.fromJson(storeJson(latitude: 26.56)).toDomain()
          .hasUsableCoordinates,
      isFalse,
      reason: 'both coordinates are required',
    );
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
