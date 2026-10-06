import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _roleKey = 'user_role';
  static const String _expiresAtKey = 'expires_at';

  Future<void> saveAuthData({
    required String token,
    required String userId,
    required String userName,
    required String role,
    required String expiresAt,
  }) async {
    await Future.wait([
      _storage.write(key: _tokenKey, value: token),
      _storage.write(key: _userIdKey, value: userId),
      _storage.write(key: _userNameKey, value: userName),
      _storage.write(key: _roleKey, value: role),
      _storage.write(key: _expiresAtKey, value: expiresAt),
    ]);
  }

  Future<String?> getToken() {
    return _storage.read(key: _tokenKey);
  }

  Future<String?> getUserId() {
    return _storage.read(key: _userIdKey);
  }

  Future<String?> getUserName() {
    return _storage.read(key: _userNameKey);
  }

  Future<String?> getRole() {
    return _storage.read(key: _roleKey);
  }

  Future<String?> getExpiresAt() {
    return _storage.read(key: _expiresAtKey);
  }

  Future<void> clearAuthData() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _userNameKey),
      _storage.delete(key: _roleKey),
      _storage.delete(key: _expiresAtKey),
    ]);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
