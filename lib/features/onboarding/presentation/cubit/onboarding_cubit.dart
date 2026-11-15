import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/preferences_storage_service.dart';
import 'onboarding_state.dart';

/// Cubit managing the onboarding slide flow, progress restoration,
/// review mode, bounds sanitization, and completion state.
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit({
    required PreferencesStorageService preferencesStorageService,
    bool isReviewMode = false,
    int slideCount = 3,
  })  : _storage = preferencesStorageService,
        super(
          _buildInitialState(
            preferencesStorageService,
            isReviewMode: isReviewMode,
            slideCount: slideCount,
          ),
        );

  final PreferencesStorageService _storage;

  static OnboardingState _buildInitialState(
    PreferencesStorageService storage, {
    required bool isReviewMode,
    required int slideCount,
  }) {
    if (isReviewMode) {
      return OnboardingState(
        currentIndex: 0,
        slideCount: slideCount,
        isCompleted: false,
        isReviewMode: true,
      );
    }

    final isCompleted = storage.getHasCompletedOnboarding();
    final savedIndex = storage.getOnboardingLastIndex();
    final sanitizedIndex = _sanitizeIndex(savedIndex, slideCount);

    return OnboardingState(
      currentIndex: sanitizedIndex,
      slideCount: slideCount,
      isCompleted: isCompleted,
      isReviewMode: false,
    );
  }

  static int _sanitizeIndex(int rawIndex, int totalSlides) {
    if (totalSlides <= 0) return 0;
    if (rawIndex < 0) return 0;
    if (rawIndex >= totalSlides) return totalSlides - 1;
    return rawIndex;
  }

  /// Advances to the next slide, or completes onboarding if at the last slide.
  Future<void> nextSlide() async {
    if (state.isCompleted) return;

    if (state.isLastSlide) {
      await completeOnboarding();
      return;
    }

    final newIndex = state.currentIndex + 1;
    if (!state.isReviewMode) {
      await _storage.setOnboardingLastIndex(newIndex);
    }
    emit(state.copyWith(currentIndex: newIndex));
  }

  /// Moves back to the previous slide.
  Future<void> previousSlide() async {
    if (state.isCompleted || state.isFirstSlide) return;

    final newIndex = state.currentIndex - 1;
    if (!state.isReviewMode) {
      await _storage.setOnboardingLastIndex(newIndex);
    }
    emit(state.copyWith(currentIndex: newIndex));
  }

  /// Navigates directly to a specific slide index.
  Future<void> goToSlide(int targetIndex) async {
    if (state.isCompleted) return;

    final sanitizedIndex = _sanitizeIndex(targetIndex, state.slideCount);
    if (sanitizedIndex == state.currentIndex) return;

    if (!state.isReviewMode) {
      await _storage.setOnboardingLastIndex(sanitizedIndex);
    }
    emit(state.copyWith(currentIndex: sanitizedIndex));
  }

  /// Skips onboarding completely, persisting completion if not in review mode.
  Future<void> skipOnboarding() async {
    if (!state.isReviewMode) {
      await _storage.setHasCompletedOnboarding(true);
      await _storage.resetOnboardingProgress();
    }
    emit(state.copyWith(isCompleted: true));
  }

  /// Marks onboarding as completed and resets stored slide progress.
  Future<void> completeOnboarding() async {
    if (!state.isReviewMode) {
      await _storage.setHasCompletedOnboarding(true);
      await _storage.resetOnboardingProgress();
    }
    emit(state.copyWith(isCompleted: true));
  }

  /// Prepares state for guest entry by completing onboarding.
  Future<void> prepareGuestEntry() async {
    await _storage.setHasCompletedOnboarding(true);
    await _storage.resetOnboardingProgress();
    emit(state.copyWith(isCompleted: true));
  }
}
