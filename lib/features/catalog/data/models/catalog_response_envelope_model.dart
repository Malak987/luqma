import '../../../../core/error/failures.dart';
import 'catalog_json.dart';

/// Shared only by the documented catalog success/failure envelope.
/// The operation-specific data shape is validated AFTER failure handling.
class CatalogResponseEnvelopeModel {
  const CatalogResponseEnvelopeModel({
    required this.message,
    required this.data,
    required this.isSucceeded,
    required this.timestamp,
  });

  final String message;
  final Object? data;
  final bool isSucceeded;
  final String timestamp;

  factory CatalogResponseEnvelopeModel.fromJson(Object? value) {
    final json = catalogObject(value);
    final message = json['message'];
    final timestamp = json['timestamp'];
    if (message is! String ||
        timestamp is! String ||
        !json.containsKey('data')) {
      throw const FormatException('Invalid catalog envelope');
    }
    return CatalogResponseEnvelopeModel(
      message: message.trim(),
      data: json['data'],
      isSucceeded: catalogBool(json, 'isSucceeded'),
      timestamp: timestamp,
    );
  }

  Object? requireSuccess() {
    if (!isSucceeded) {
      throw RemoteException(
        code: FailureCode.validation,
        message:
            message.isEmpty ? 'Catalog request was not successful' : message,
      );
    }
    return data;
  }
}
