/// The confirmed MainCategory GetAll envelope. As with the other API features,
/// data is validated by the remote source after checking isSucceeded, so a
/// rejected request with null data remains an API failure, not an empty list.
final class MainCategoryResponseEnvelopeModel {
  const MainCategoryResponseEnvelopeModel({
    required this.message,
    required this.data,
    required this.isSucceeded,
    required this.timestamp,
  });

  final String message;
  final Object? data;
  final bool isSucceeded;
  final String timestamp;

  factory MainCategoryResponseEnvelopeModel.fromJson(Object? json) {
    if (json is! Map<Object?, Object?> ||
        json.keys.any((key) => key is! String)) {
      throw const FormatException('Invalid MainCategory response envelope');
    }

    final message = json['message'];
    final isSucceeded = json['isSucceeded'];
    final timestamp = json['timestamp'];
    if (!json.containsKey('data')) {
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
    if (timestamp is! String || DateTime.tryParse(timestamp) == null) {
      throw const FormatException(
          'Missing or invalid response field: timestamp');
    }

    return MainCategoryResponseEnvelopeModel(
      message: message.trim(),
      data: json['data'],
      isSucceeded: isSucceeded,
      timestamp: timestamp,
    );
  }
}
