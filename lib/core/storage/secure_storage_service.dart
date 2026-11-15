import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  static const String _authDataKey = 'auth_session_v1';

  // Read legacy keys for sessions written by the previous app version.
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _roleKey = 'user_role';
  static const String _expiresAtKey = 'expires_at';

  static const List<String> _legacyKeys = <String>[
    _tokenKey,
    _userIdKey,
    _userNameKey,
    _roleKey,
    _expiresAtKey,
  ];

  static const List<String> _allKeys = <String>[
    _authDataKey,
    ..._legacyKeys,
  ];

  Future<void> saveAuthData({
    required String token,
    required String userId,
    required String userName,
    required String role,
    required String expiresAt,
  }) async {
    final authData = jsonEncode(<String, String>{
      'token': token,
      'userId': userId,
      'userName': userName,
      'role': role,
      'expiresAt': expiresAt,
    });

    // Persist the session snapshot with one secure-storage write so it cannot
    // be left partially updated across independent keys.
    await _storage.write(key: _authDataKey, value: authData);
    await _deleteKeysBestEffort(_legacyKeys);
  }

  Future<String?> getToken() => _readValue('token', _tokenKey);

  Future<String?> getUserId() => _readValue('userId', _userIdKey);

  Future<String?> getUserName() => _readValue('userName', _userNameKey);

  Future<String?> getRole() => _readValue('role', _roleKey);

  Future<String?> getExpiresAt() => _readValue('expiresAt', _expiresAtKey);

  Future<void> clearAuthData() async {
    await Future.wait(
      _allKeys.map((key) => _storage.delete(key: key)),
    );
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> _readValue(String field, String legacyKey) async {
    final encoded = await _storage.read(key: _authDataKey);
    if (encoded == null) {
      return _storage.read(key: legacyKey);
    }

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is Map<String, dynamic>) {
        final value = decoded[field];
        return value is String ? value : null;
      }
    } on FormatException {
      return null;
    }

    return null;
  }

  Future<void> _deleteKeysBestEffort(Iterable<String> keys) async {
    for (final key in keys) {
      try {
        await _storage.delete(key: key);
      } catch (_) {
        // The complete versioned session has already been persisted.
      }
    }
  }
}
