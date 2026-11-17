import '../../../../core/error/failures.dart';
import 'favorite_json.dart';

/// API response wrapper used by the supplied Favorite operations that return
/// data. Operation-specific shapes are validated only after success handling.
class FavoriteResponseEnvelopeModel {
  const FavoriteResponseEnvelopeModel({
    required this.message,
    required this.data,
    required this.isSucceeded,
    required this.timestamp,
  });

  final String message;
  final Object? data;
  final bool isSucceeded;
  final String timestamp;

  factory FavoriteResponseEnvelopeModel.fromJson(Object? value) {
    final json = favoriteObject(value, 'favorite envelope');
    final message = json['message'];
    final timestamp = json['timestamp'];
    if (message is! String ||
        timestamp is! String ||
        !json.containsKey('data')) {
      throw const FormatException('Invalid favorite envelope');
    }
    return FavoriteResponseEnvelopeModel(
      message: message.trim(),
      data: json['data'],
      isSucceeded: favoriteRequiredBool(json, 'isSucceeded'),
      timestamp: timestamp,
    );
  }

  Object? requireSuccess(String operation) {
    if (!isSucceeded) {
      throw RemoteException(
        code: FailureCode.validation,
        message: message.isEmpty
            ? '$operation request was not successful'
            : message,
      );
    }
    return data;
  }
}
