import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/features/home/data/models/main_category_model.dart';
import 'package:luqma_app/features/home/data/models/main_category_response_envelope_model.dart';

import '../../support/main_category_fixtures.dart';

void main() {
  group('MainCategoryModel', () {
    test('parses all fields and maps to the existing HomeCategory entity', () {
      final model = MainCategoryModel.fromJson(mainCategoryJson());

      expect(model.id, mainCategoryId);
      expect(model.nameAr, 'مطاعم');
      expect(model.nameEn, 'Restaurants');
      expect(model.iconUrl, mainCategoryIconUrl);
      expect(model.displayOrder, 1);
      expect(model.isActive, isTrue);
      expect(model.toDomain(), homeCategory(iconUrl: mainCategoryIconUrl));
    });

    test('retains both Arabic and English names and trims surrounding space',
        () {
      final model = MainCategoryModel.fromJson(mainCategoryJson(
        nameAr: '  حلويات  ',
        nameEn: '  Desserts  ',
      ));

      expect(model.toDomain().nameAr, 'حلويات');
      expect(model.toDomain().nameEn, 'Desserts');
    });

    test('accepts absent artwork values without losing category fields', () {
      for (final iconUrl in <String?>[null, '', '   ', 'not a URL']) {
        final model = MainCategoryModel.fromJson(
          mainCategoryJson(iconUrl: iconUrl, displayOrder: 3, isActive: false),
        );

        expect(model.iconUrl, iconUrl?.trim());
        expect(model.toDomain().displayOrder, 3);
        expect(model.toDomain().isActive, isFalse);
      }
    });

    test('rejects every missing required field instead of inventing defaults',
        () {
      for (final field in mainCategoryJson().keys) {
        final json = mainCategoryJson()..remove(field);
        expect(
          () => MainCategoryModel.fromJson(json),
          throwsFormatException,
          reason: 'Missing $field must be a parse failure',
        );
      }
    });

    test('rejects null and wrong-typed required fields', () {
      final invalidValues = <String, List<Object?>>{
        'id': <Object?>[null, 1],
        'nameAr': <Object?>[null, true],
        'nameEn': <Object?>[null, <String>[]],
        'iconUrl': <Object?>[1, false],
        'displayOrder': <Object?>[null, '1', 1.5, 1.0],
        'isActive': <Object?>[null, 'true', 1],
      };
      for (final entry in invalidValues.entries) {
        for (final value in entry.value) {
          final json = mainCategoryJson()..[entry.key] = value;
          expect(
            () => MainCategoryModel.fromJson(json),
            throwsFormatException,
            reason: '${entry.key}: $value must not be coerced',
          );
        }
      }
    });

    test('rejects blank IDs and names instead of rendering an empty card', () {
      for (final field in <String>['id', 'nameAr', 'nameEn']) {
        for (final value in <String>['', '   ']) {
          final json = mainCategoryJson()..[field] = value;
          expect(() => MainCategoryModel.fromJson(json), throwsFormatException);
        }
      }
    });

    test('rejects non-object values and non-string keys safely', () {
      for (final json in <Object?>[
        null,
        'not an object',
        <Object?>[],
        <Object?, Object?>{1: 'invalid key'},
      ]) {
        expect(() => MainCategoryModel.fromJson(json), throwsFormatException);
      }
    });

    test('domain equality includes every API field', () {
      final category = homeCategory();
      expect(category, homeCategory());
      expect(category, isNot(homeCategory(id: 'different')));
      expect(category, isNot(homeCategory(nameAr: 'حلويات')));
      expect(category, isNot(homeCategory(nameEn: 'Desserts')));
      expect(category, isNot(homeCategory(iconUrl: mainCategoryIconUrl)));
      expect(category, isNot(homeCategory(displayOrder: 2)));
      expect(category, isNot(homeCategory(isActive: false)));
    });
  });

  group('MainCategoryResponseEnvelopeModel', () {
    test('parses the complete success envelope and preserves raw list data',
        () {
      final data = <Object?>[
        mainCategoryJson(),
        mainCategoryJson(id: 'second')
      ];
      final envelope = MainCategoryResponseEnvelopeModel.fromJson(
        mainCategoryEnvelope(data: data),
      );

      expect(envelope.message, 'تم جلب الأصناف بنجاح');
      expect(envelope.data, same(data));
      expect(envelope.isSucceeded, isTrue);
      expect(envelope.timestamp, mainCategoryTimestamp);
    });

    test('preserves null data on unsuccessful responses for error handling',
        () {
      final envelope = MainCategoryResponseEnvelopeModel.fromJson(
        mainCategoryEnvelope(data: null, isSucceeded: false, message: ''),
      );

      expect(envelope.data, isNull);
      expect(envelope.isSucceeded, isFalse);
      expect(envelope.message, isEmpty);
    });

    test('requires every envelope field', () {
      for (final field in <String>[
        'message',
        'data',
        'isSucceeded',
        'timestamp',
      ]) {
        final json = mainCategoryEnvelope(data: <Object?>[])..remove(field);
        expect(
          () => MainCategoryResponseEnvelopeModel.fromJson(json),
          throwsFormatException,
          reason: 'Missing $field must be a parse failure',
        );
      }
    });

    test('rejects malformed envelopes, types and timestamps', () {
      final invalidFields = <String, Object?>{
        'message': null,
        'isSucceeded': 'true',
        'timestamp': 'not a timestamp',
      };
      for (final entry in invalidFields.entries) {
        final json = mainCategoryEnvelope(data: <Object?>[])
          ..[entry.key] = entry.value;
        expect(
          () => MainCategoryResponseEnvelopeModel.fromJson(json),
          throwsFormatException,
        );
      }
      for (final timestamp in <Object?>[null, '', '   ', 123]) {
        final json = mainCategoryEnvelope(data: <Object?>[])
          ..['timestamp'] = timestamp;
        expect(
          () => MainCategoryResponseEnvelopeModel.fromJson(json),
          throwsFormatException,
        );
      }
      for (final json in <Object?>[
        null,
        <Object?>[],
        'not an object',
        <Object?, Object?>{0: true},
      ]) {
        expect(
          () => MainCategoryResponseEnvelopeModel.fromJson(json),
          throwsFormatException,
        );
      }
    });
  });
}
