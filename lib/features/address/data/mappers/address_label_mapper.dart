import '../../domain/entities/address_label.dart';

/// Explicitly maps the Address API's integer label values.
///
/// These values are a confirmed backend contract; enum indexes are never sent
/// directly because their order is not a wire-format guarantee.
abstract final class AddressLabelMapper {
  static AddressLabel fromApiValue(Object? value) {
    if (value is! int) {
      throw const FormatException('Address label must be an integer');
    }

    return switch (value) {
      0 => AddressLabel.home,
      1 => AddressLabel.work,
      2 => AddressLabel.other,
      _ => throw FormatException('Unsupported address label: $value'),
    };
  }

  static int toApiValue(AddressLabel label) {
    return switch (label) {
      AddressLabel.home => 0,
      AddressLabel.work => 1,
      AddressLabel.other => 2,
    };
  }
}
