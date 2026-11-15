/// The confirmed Address API response envelope.
///
/// `data` remains raw here because its type is operation-specific: for
/// GetMyAddresses it is a list of addresses, while the Create success payload
/// has not been documented in this repository.
final class AddressResponseEnvelopeModel {
  const AddressResponseEnvelopeModel({
    required this.message,
    required this.data,
    required this.isSucceeded,
    required this.timestamp,
  });

  final String message;
  final Object? data;
  final bool isSucceeded;
  final String timestamp;

  factory AddressResponseEnvelopeModel.fromJson(Object? json) {
    final envelope = _asStringKeyedMap(json);

    final message = envelope['message'];
    final isSucceeded = envelope['isSucceeded'];
    final timestamp = envelope['timestamp'];
    if (!envelope.containsKey('data')) {
      throw const FormatException('Missing required response field: data');
    }
    if (message is! String) {
      throw const FormatException('Missing or invalid response field: message');
    }
    if (isSucceeded is! bool) {
      throw const FormatException(
        'Missing or invalid response field: isSucceeded',
      );
    }
    if (timestamp is! String) {
      throw const FormatException(
        'Missing or invalid response field: timestamp',
      );
    }

    return AddressResponseEnvelopeModel(
      message: message,
      data: envelope['data'],
      isSucceeded: isSucceeded,
      timestamp: timestamp,
    );
  }
}

Map<String, dynamic> _asStringKeyedMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map<Object?, Object?>) {
    final result = <String, dynamic>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) {
        throw const FormatException('Invalid Address response envelope');
      }
      result[key] = entry.value;
    }
    return result;
  }

  throw const FormatException('Invalid Address response envelope');
}
