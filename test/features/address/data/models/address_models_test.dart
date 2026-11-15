import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/features/address/data/mappers/address_label_mapper.dart';
import 'package:luqma_app/features/address/data/models/address_model.dart';
import 'package:luqma_app/features/address/data/models/address_response_envelope_model.dart';
import 'package:luqma_app/features/address/data/models/create_address_request_model.dart';
import 'package:luqma_app/features/address/domain/entities/address_draft.dart';
import 'package:luqma_app/features/address/domain/entities/address_label.dart';

void main() {
  group('AddressLabelMapper', () {
    test('maps all confirmed API values to domain labels', () {
      expect(AddressLabelMapper.fromApiValue(0), AddressLabel.home);
      expect(AddressLabelMapper.fromApiValue(1), AddressLabel.work);
      expect(AddressLabelMapper.fromApiValue(2), AddressLabel.other);
    });

    test('maps all domain labels to their explicit API integers', () {
      expect(AddressLabelMapper.toApiValue(AddressLabel.home), 0);
      expect(AddressLabelMapper.toApiValue(AddressLabel.work), 1);
      expect(AddressLabelMapper.toApiValue(AddressLabel.other), 2);
    });

    test('rejects unknown and non-integer API labels', () {
      expect(() => AddressLabelMapper.fromApiValue(3), throwsFormatException);
      expect(() => AddressLabelMapper.fromApiValue(0.0), throwsFormatException);
      expect(
        () => AddressLabelMapper.fromApiValue(null),
        throwsFormatException,
      );
    });
  });

  group('AddressModel', () {
    test('parses the supplied Address response and maps it to the entity', () {
      final model = AddressModel.fromJson(_addressJson());

      expect(model.id, '0ae79d3a-594c-4852-aedf-27d5c176fa70');
      expect(model.label, AddressLabel.home);
      expect(model.title, 'string');
      expect(model.district, 'string');
      expect(model.city, 'string');
      expect(model.details, 'string');
      expect(model.latitude, 0.0);
      expect(model.longitude, 0.0);
      expect(model.isDefault, isTrue);
      expect(model.toDomain().label, AddressLabel.home);
    });

    test('parses each confirmed label value into its domain enum', () {
      final expectedLabels = <int, AddressLabel>{
        0: AddressLabel.home,
        1: AddressLabel.work,
        2: AddressLabel.other,
      };

      for (final entry in expectedLabels.entries) {
        final model = AddressModel.fromJson(_addressJson(label: entry.key));
        expect(model.label, entry.value);
      }
    });

    test('accepts JSON integer coordinate values for double fields', () {
      final model = AddressModel.fromJson(_addressJson());

      expect(model.latitude, isA<double>());
      expect(model.longitude, isA<double>());
    });

    test('rejects each missing required response field', () {
      for (final field in <String>[
        'id',
        'label',
        'title',
        'district',
        'city',
        'details',
        'latitude',
        'longitude',
        'isDefault',
      ]) {
        final json = _addressJson()..remove(field);
        expect(
          () => AddressModel.fromJson(json),
          throwsFormatException,
          reason: 'Missing $field must not be defaulted',
        );
      }
    });

    test('rejects null or wrong-typed required response fields', () {
      final json = _addressJson()..['city'] = null;
      expect(() => AddressModel.fromJson(json), throwsFormatException);

      final wrongType = _addressJson()..['isDefault'] = 'true';
      expect(() => AddressModel.fromJson(wrongType), throwsFormatException);
    });

    test('rejects an empty address id', () {
      final json = _addressJson()..['id'] = '';
      expect(() => AddressModel.fromJson(json), throwsFormatException);
    });
  });

  group('CreateAddressRequestModel', () {
    test('serializes all confirmed fields with an explicit label integer', () {
      final request = CreateAddressRequestModel.fromDomain(_draft(
        label: AddressLabel.work,
        isDefault: true,
      ));

      expect(
        request.toJson(),
        <String, dynamic>{
          'label': 1,
          'title': 'Home title',
          'district': 'District',
          'city': 'City',
          'details': 'Building 2',
          'latitude': 26.5570,
          'longitude': 31.6940,
          'isDefault': true,
        },
      );
    });

    test('serializes all three labels explicitly, not by enum index', () {
      final labels = <AddressLabel, int>{
        AddressLabel.home: 0,
        AddressLabel.work: 1,
        AddressLabel.other: 2,
      };

      for (final entry in labels.entries) {
        final request = CreateAddressRequestModel.fromDomain(
          _draft(label: entry.key),
        );
        expect(request.toJson()['label'], entry.value);
      }
    });

    test('preserves isDefault true for first-address creation', () {
      final request = CreateAddressRequestModel.fromDomain(
        _draft(isDefault: true),
      );

      expect(request.toJson()['isDefault'], isTrue);
    });
  });

  group('AddressResponseEnvelopeModel', () {
    test('parses the confirmed envelope fields and preserves raw data', () {
      final model = AddressResponseEnvelopeModel.fromJson(<String, dynamic>{
        'message': 'تم جلب العناوين بنجاح',
        'data': <Object?>[_addressJson()],
        'isSucceeded': true,
        'timestamp': '2026-11-04T17:16:20.4274824Z',
      });

      expect(model.message, 'تم جلب العناوين بنجاح');
      expect(model.data, isA<List<Object?>>());
      expect(model.isSucceeded, isTrue);
      expect(model.timestamp, '2026-11-04T17:16:20.4274824Z');
    });

    test(
      'rejects missing envelope fields rather than substituting defaults',
      () {
        final base = <String, dynamic>{
          'message': 'ok',
          'data': <Object?>[],
          'isSucceeded': true,
          'timestamp': '2026-11-04T17:16:20Z',
        };

        for (final field in <String>[
          'message',
          'data',
          'isSucceeded',
          'timestamp',
        ]) {
          final json = Map<String, dynamic>.from(base)..remove(field);
          expect(
            () => AddressResponseEnvelopeModel.fromJson(json),
            throwsFormatException,
            reason: 'Missing $field must be a parse failure',
          );
        }
      },
    );
  });
}

Map<String, dynamic> _addressJson({int label = 0}) => <String, dynamic>{
      'id': '0ae79d3a-594c-4852-aedf-27d5c176fa70',
      'label': label,
      'title': 'string',
      'district': 'string',
      'city': 'string',
      'details': 'string',
      'latitude': 0,
      'longitude': 0,
      'isDefault': true,
    };

AddressDraft _draft({
  AddressLabel label = AddressLabel.home,
  bool isDefault = false,
}) {
  return AddressDraft(
    label: label,
    title: 'Home title',
    district: 'District',
    city: 'City',
    details: 'Building 2',
    latitude: 26.557,
    longitude: 31.694,
    isDefault: isDefault,
  );
}
