import 'package:equatable/equatable.dart';

/// Represents the state of the onboarding flow.
class OnboardingState extends Equatable {
  const OnboardingState({
    required this.currentIndex,
    required this.slideCount,
    required this.isCompleted,
    this.isReviewMode = false,
  });

  /// Factory constructor for initial default state.
  const OnboardingState.initial({
    this.slideCount = 3,
    this.isReviewMode = false,
  })  : currentIndex = 0,
        isCompleted = false;

  final int currentIndex;
  final int slideCount;
  final bool isCompleted;
  final bool isReviewMode;

  bool get isLastSlide => currentIndex >= slideCount - 1;
  bool get isFirstSlide => currentIndex <= 0;

  OnboardingState copyWith({
    int? currentIndex,
    int? slideCount,
    bool? isCompleted,
    bool? isReviewMode,
  }) {
    return OnboardingState(
      currentIndex: currentIndex ?? this.currentIndex,
      slideCount: slideCount ?? this.slideCount,
      isCompleted: isCompleted ?? this.isCompleted,
      isReviewMode: isReviewMode ?? this.isReviewMode,
    );
  }

  @override
  List<Object?> get props => [
        currentIndex,
        slideCount,
        isCompleted,
        isReviewMode,
      ];
}
