import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/secure_storage_service.dart';
import 'auth_session_state.dart';

class AuthSessionCubit extends Cubit<AuthSessionState> {
  AuthSessionCubit({
    required SecureStorageService secureStorageService,
    Future<void> Function()? onSessionCleared,
  })  : _secureStorageService = secureStorageService,
        _onSessionCleared = onSessionCleared,
        super(const AuthSessionState.initial());

  final SecureStorageService _secureStorageService;

  /// Runs whenever stored credentials are removed (logout or expired session),
  /// so per-customer caches such as the address snapshot cannot outlive them.
  final Future<void> Function()? _onSessionCleared;

  Future<void> _clearPrivateCaches() async {
    try {
      await _onSessionCleared?.call();
    } catch (_) {}
  }

  Future<void> checkSession() async {
    if (state.status == AuthSessionStatus.checking) {
      return;
    }

    emit(const AuthSessionState.checking());

    try {
      final token = await _secureStorageService.getToken();
      final expiresAt = await _secureStorageService.getExpiresAt();

      if (token == null ||
          token.isEmpty ||
          expiresAt == null ||
          expiresAt.isEmpty) {
        await _clearInvalidSession();
        return;
      }

      final expirationDate = DateTime.tryParse(expiresAt);

      if (expirationDate == null ||
          !expirationDate.isAfter(DateTime.now().toUtc())) {
        await _clearInvalidSession();
        return;
      }

      if (!isClosed) {
        emit(const AuthSessionState.authenticated());
      }
    } catch (_) {
      await _clearInvalidSession();
    }
  }

  Future<void> logout() async {
    await _secureStorageService.clearAuthData();
    await _clearPrivateCaches();

    if (!isClosed) {
      emit(const AuthSessionState.unauthenticated());
    }
  }

  Future<void> _clearInvalidSession() async {
    await _secureStorageService.clearAuthData();
    await _clearPrivateCaches();

    if (!isClosed) {
      emit(const AuthSessionState.unauthenticated());
    }
  }
}
