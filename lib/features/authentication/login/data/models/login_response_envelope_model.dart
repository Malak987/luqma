import 'login_response_model.dart';

final class LoginResponseEnvelopeModel {
  const LoginResponseEnvelopeModel({
    required this.isSucceeded,
    this.data,
  });

  final bool isSucceeded;
  final LoginResponseModel? data;

  factory LoginResponseEnvelopeModel.fromJson(Object? json) {
    final envelope = _asStringKeyedMap(json, 'Login response envelope');
    final isSucceeded = envelope['isSucceeded'];

    if (isSucceeded is! bool) {
      throw const FormatException('Invalid login response envelope');
    }

    if (!isSucceeded) {
      return const LoginResponseEnvelopeModel(isSucceeded: false);
    }

    final responseData = _asStringKeyedMap(
      envelope['data'],
      'Login response data',
    );

    return LoginResponseEnvelopeModel(
      isSucceeded: true,
      data: LoginResponseModel.fromJson(responseData),
    );
  }
}

Map<String, dynamic> _asStringKeyedMap(Object? value, String description) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map<Object?, Object?>) {
    final result = <String, dynamic>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) {
        throw FormatException('Invalid $description');
      }
      result[key] = entry.value;
    }
    return result;
  }

  throw FormatException('Invalid $description');
}
