import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/storage/secure_storage_service.dart';
import 'home_state.dart';

/// Owns everything the home shell needs to render.
///
/// The home content endpoints do not exist yet, so the only real data available
/// today is the profile already persisted by the login flow: the cubit reads it
/// through the existing [SecureStorageService], the same dependency
/// `AuthSessionCubit` uses. Categories and restaurants stay empty and the
/// sections render their empty states; when those endpoints arrive they are
/// injected here as use cases and fill the same state.
class HomeCubit extends Cubit<HomeState> {
  HomeCubit({required SecureStorageService secureStorageService})
      : _secureStorageService = secureStorageService,
        super(const HomeState.initial());

  final SecureStorageService _secureStorageService;

  Future<void> load() async {
    if (state.isLoading) {
      return;
    }

    emit(const HomeState(status: HomeStatus.loading));

    try {
      final userName = await _secureStorageService.getUserName();

      if (!isClosed) {
        emit(
          HomeState(
            status: HomeStatus.loaded,
            userName: _normalizedName(userName),
          ),
        );
      }
    } catch (error) {
      if (!isClosed) {
        emit(
          HomeState(
            status: HomeStatus.failure,
            failure: Failure(
              FailureCode.unknown,
              debugMessage: error.toString(),
            ),
          ),
        );
      }
    }
  }

  /// Blank names count as missing, so the header can fall back gracefully.
  String? _normalizedName(String? userName) {
    final trimmed = userName?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
