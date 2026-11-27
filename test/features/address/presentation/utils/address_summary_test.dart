import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/features/address/domain/entities/address.dart';
import 'package:luqma_app/features/address/domain/entities/address_label.dart';
import 'package:luqma_app/features/address/presentation/utils/address_summary.dart';

void main() {
  Address address({
    String district = 'Minya',
    String city = 'El Minya',
    String details = 'Gomhoria Street',
  }) =>
      Address(
        id: 'id',
        label: AddressLabel.home,
        title: 'Home',
        district: district,
        city: city,
        details: details,
        latitude: 28.1,
        longitude: 30.75,
        isDefault: true,
      );

  test('joins district and city with the locale separator', () {
    expect(addressSummaryLine(address(), arabic: false), 'Minya, El Minya');
    expect(addressSummaryLine(address(), arabic: true), 'Minya، El Minya');
  });

  test('keeps the street out of the one-line header summary', () {
    expect(
      addressSummaryLine(
        address(details: 'A very long street name, building 12'),
        arabic: false,
      ),
      'Minya, El Minya',
    );
  });

  test('degrades to whichever part is present', () {
    expect(addressSummaryLine(address(district: ''), arabic: false),
        'El Minya');
    expect(addressSummaryLine(address(city: ''), arabic: false), 'Minya');
    expect(addressSummaryLine(address(district: '', city: ''), arabic: false),
        isEmpty);
    expect(
      addressSummaryLine(address(district: '  ', city: ' '), arabic: true),
      isEmpty,
    );
  });
}
