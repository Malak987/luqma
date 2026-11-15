import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/home_category.dart';
import '../../domain/usecases/get_all_main_categories_use_case.dart';
import 'home_state.dart';

/// Loads the persisted profile and the customer catalog independently, so an
/// unavailable catalog cannot hide the greeting, search or restaurants section.
class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required SecureStorageService secureStorageService,
    required GetAllMainCategoriesUseCase getAllMainCategoriesUseCase,
  })  : _secureStorageService = secureStorageService,
        _getAllMainCategoriesUseCase = getAllMainCategoriesUseCase,
        super(const HomeState.initial());

  final SecureStorageService _secureStorageService;
  final GetAllMainCategoriesUseCase _getAllMainCategoriesUseCase;

  Future<void> load() async {
    if (isClosed || state.isLoading || state.status == HomeStatus.loaded) {
      return;
    }

    emit(state.copyWith(status: HomeStatus.loading, clearFailure: true));
    await Future.wait<void>(<Future<void>>[
      _loadProfile(),
      loadCategories(),
    ]);
  }

  Future<void> _loadProfile() async {
    try {
      final userName =
          _normalizedName(await _secureStorageService.getUserName());
      if (isClosed) return;
      emit(
        state.copyWith(
          status: HomeStatus.loaded,
          userName: userName,
          clearUserName: userName == null,
          clearFailure: true,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          failure: Failure(
            FailureCode.unknown,
            debugMessage: error.toString(),
          ),
        ),
      );
    }
  }

  /// Successful and empty results are reused for this Home visit. A new route
  /// gets a new cubit through GetIt; explicit retry can reload just the catalog.
  Future<void> loadCategories({bool forceRefresh = false}) async {
    if (isClosed || state.categoriesStatus == HomeCategoriesStatus.loading) {
      return;
    }
    if (!forceRefresh &&
        (state.categoriesStatus == HomeCategoriesStatus.success ||
            state.categoriesStatus == HomeCategoriesStatus.empty)) {
      return;
    }

    emit(
      state.copyWith(
        categoriesStatus: HomeCategoriesStatus.loading,
        clearCategoriesFailure: true,
      ),
    );
    try {
      final categories = await _getAllMainCategoriesUseCase();
      if (isClosed) return;
      emit(
        state.copyWith(
          categoriesStatus: categories.isEmpty
              ? HomeCategoriesStatus.empty
              : HomeCategoriesStatus.success,
          categories: List<HomeCategory>.unmodifiable(categories),
        ),
      );
    } on FailureException catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          categoriesStatus: HomeCategoriesStatus.error,
          categoriesFailure: error.failure,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          categoriesStatus: HomeCategoriesStatus.error,
          categoriesFailure: Failure(
            FailureCode.unknown,
            debugMessage: error.toString(),
          ),
        ),
      );
    }
  }

  Future<void> retryCategories() => loadCategories(forceRefresh: true);

  /// Blank names count as missing, so the header can fall back gracefully.
  String? _normalizedName(String? userName) {
    final trimmed = userName?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
