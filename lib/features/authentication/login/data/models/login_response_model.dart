final class LoginResponseModel {
  const LoginResponseModel({
    required this.userId,
    required this.userName,
    required this.role,
    required this.token,
    required this.expiresAt,
  });

  final String userId;
  final String userName;
  final String role;
  final String token;
  final DateTime expiresAt;

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      userId: _requiredString(json, 'userId'),
      userName: _requiredString(json, 'userName'),
      role: _requiredString(json, 'role'),
      token: _requiredString(json, 'token').trim(),
      expiresAt: _parseExpiresAt(_requiredString(json, 'expiresAt')),
    );
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing or invalid required field: $key');
  }
  return value;
}

DateTime _parseExpiresAt(String value) {
  // The API emits ISO-8601 timestamps with up to seven fractional digits.
  // Dart DateTime has microsecond precision, so any additional digit is
  // truncated after validating the complete timestamp.
  final match = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.(\d+))?(Z|[+-]\d{2}:\d{2})$',
  ).firstMatch(value);

  if (match == null) {
    throw const FormatException('Invalid expiresAt timestamp');
  }

  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final hour = int.parse(match.group(4)!);
  final minute = int.parse(match.group(5)!);
  final second = int.parse(match.group(6)!);
  final timezone = match.group(8)!;

  if (hour > 23 || minute > 59 || second > 59) {
    throw const FormatException('Invalid expiresAt timestamp');
  }

  if (timezone != 'Z') {
    final offsetHours = int.parse(timezone.substring(1, 3));
    final offsetMinutes = int.parse(timezone.substring(4, 6));
    if (offsetHours > 23 || offsetMinutes > 59) {
      throw const FormatException('Invalid expiresAt timestamp');
    }
  }

  final calendarCheck = DateTime.utc(year, month, day, hour, minute, second);
  if (calendarCheck.year != year ||
      calendarCheck.month != month ||
      calendarCheck.day != day ||
      calendarCheck.hour != hour ||
      calendarCheck.minute != minute ||
      calendarCheck.second != second) {
    throw const FormatException('Invalid expiresAt timestamp');
  }

  final fraction = match.group(7) ?? '';
  final fractionForDateTime = fraction.isEmpty
      ? ''
      : '.${fraction.substring(0, fraction.length > 6 ? 6 : fraction.length)}';
  final normalized = '${match.group(1)}-${match.group(2)}-${match.group(3)}'
      'T${match.group(4)}:${match.group(5)}:${match.group(6)}'
      '$fractionForDateTime$timezone';

  try {
    return DateTime.parse(normalized);
  } on FormatException {
    throw const FormatException('Invalid expiresAt timestamp');
  }
}
