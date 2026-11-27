import '../../../../core/error/failures.dart';
import 'cart_json.dart';

/// Cart API's shared response wrapper.
class CartResponseEnvelopeModel {
  const CartResponseEnvelopeModel({
    required this.message,
    required this.data,
    required this.isSucceeded,
    required this.timestamp,
    this.errorCode,
  });

  final String message;
  final Object? data;
  final bool isSucceeded;
  final String timestamp;
  final String? errorCode;

  factory CartResponseEnvelopeModel.fromJson(Object? value) {
    final json = cartObject(value, 'cart envelope');
    final message = json['message'];
    final timestamp = json['timestamp'];
    if (message is! String ||
        timestamp is! String ||
        !json.containsKey('data')) {
      throw const FormatException('Invalid cart envelope');
    }
    return CartResponseEnvelopeModel(
      message: message.trim(),
      data: json['data'],
      isSucceeded: cartRequiredBool(json, 'isSucceeded'),
      timestamp: timestamp,
      errorCode: json['errorCode'] is String
          ? (json['errorCode'] as String).trim()
          : null,
    );
  }

  Object? requireSuccess(String operation) {
    if (!isSucceeded) {
      throw RemoteException(
        code: FailureCode.validation,
        backendCode: errorCode,
        message:
            message.isEmpty ? '$operation request was not successful' : message,
      );
    }
    return data;
  }
}
