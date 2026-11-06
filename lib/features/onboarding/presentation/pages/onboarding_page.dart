import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';

/// Onboarding page featuring per-slide Lottie illustrations, page indicators,
/// localized Arabic/English copy, and accessibility (Reduce Motion) support.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    this.isReviewMode = false,
  });

  final bool isReviewMode;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  late final PageController _pageController;

  /// One controller per slide so each illustration loops independently and a
  /// single `Lottie` widget never restarts when the page indicator updates.
  late final List<AnimationController> _lottieControllers;

  @override
  void initState() {
    super.initState();
    final initialIndex = context.read<OnboardingCubit>().state.currentIndex;
    _pageController = PageController(initialPage: initialIndex);

    _lottieControllers = List<AnimationController>.generate(
      AppAssets.onboardingAnimations.length,
      (index) => AnimationController(
        vsync: this,
        // Replaced by each composition's real duration in `onLoaded`.
        duration: const Duration(milliseconds: 4000),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Honour the OS "Reduce Motion" setting: pause the loops instead of
    // restarting them on every rebuild.
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    for (final controller in _lottieControllers) {
      if (disableAnimations) {
        if (controller.isAnimating) controller.stop();
      } else if (!controller.isAnimating) {
        controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _lottieControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onPageChanged(int index) {
    context.read<OnboardingCubit>().goToSlide(index);
  }

  void _syncPageController(int targetIndex) {
    if (_pageController.hasClients &&
        _pageController.page?.round() != targetIndex) {
      _pageController.animateToPage(
        targetIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Slide copy in page order; the illustration is chosen by the same index.
  List<_SlideCopy> _slideCopy(AppLocalizations l10n) {
    final onboarding = l10n.onboarding;
    return [
      _SlideCopy(
        title: onboarding.slide1Title,
        subtitle: onboarding.slide1Subtitle,
      ),
      _SlideCopy(
        title: onboarding.slide2Title,
        subtitle: onboarding.slide2Subtitle,
      ),
      _SlideCopy(
        title: onboarding.slide3Title,
        subtitle: onboarding.slide3Subtitle,
      ),
    ];
  }

  String _animationFor(int index) {
    final assets = AppAssets.onboardingAnimations;
    return assets[index < assets.length ? index : assets.length - 1];
  }

  AnimationController _controllerFor(int index) {
    final controllers = _lottieControllers;
    final safeIndex =
        index < controllers.length ? index : controllers.length - 1;
    return controllers[safeIndex];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppSemanticColors>() ??
        (theme.brightness == Brightness.dark
            ? AppSemanticColors.dark
            : AppSemanticColors.light);

    final isDark = theme.brightness == Brightness.dark;
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    // Static wordmark is only a safety fallback if an illustration fails to
    // load, or when Reduce Motion shows the illustration frozen.
    final fallbackImageAsset =
        isDark ? AppAssets.logoDark : AppAssets.logoLight;
    final l10n = AppLocalizations.of(context);
    final slides = _slideCopy(l10n);

    return BlocConsumer<OnboardingCubit, OnboardingState>(
      listenWhen: (previous, current) =>
          previous.currentIndex != current.currentIndex ||
          previous.isCompleted != current.isCompleted,
      listener: (context, state) {
        if (state.isCompleted) {
          if (widget.isReviewMode || state.isReviewMode) {
            Navigator.of(context).pop();
          }
          return;
        }
        _syncPageController(state.currentIndex);
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: colors.background,
          body: SafeArea(
            child: Column(
              children: [
                // Header Bar with Skip / Close button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (widget.isReviewMode || state.isReviewMode)
                        IconButton(
                          key: const Key('onboarding_back_button'),
                          icon: Icon(Icons.arrow_back, color: colors.primary),
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: l10n.onboarding.back,
                        )
                      else
                        const SizedBox.shrink(),
                      TextButton(
                        key: const Key('onboarding_skip_button'),
                        onPressed: () =>
                            context.read<OnboardingCubit>().skipOnboarding(),
                        child: Text(
                          l10n.onboarding.skip,
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main PageView with Slides
                Expanded(
                  child: PageView.builder(
                    key: const Key('onboarding_page_view'),
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: slides.length,
                    itemBuilder: (context, index) {
                      final copy = slides[index];
                      return _buildSlide(
                        key: Key('onboarding_slide_$index'),
                        animationKey:
                            Key('onboarding_lottie_animation_$index'),
                        title: copy.title,
                        subtitle: copy.subtitle,
                        lottieAsset: _animationFor(index),
                        lottieController: _controllerFor(index),
                        fallbackAsset: fallbackImageAsset,
                        disableAnimations: disableAnimations,
                        theme: theme,
                        colors: colors,
                      );
                    },
                  ),
                ),

                // Footer with Page Indicator and Action Button
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Page indicators
                      Row(
                        key: const Key('onboarding_indicator'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          state.slideCount,
                          (index) => _buildIndicatorDot(
                            isActive: index == state.currentIndex,
                            colors: colors,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24.0),

                      // Next / Get Started button
                      SizedBox(
                        width: double.infinity,
                        height: 52.0,
                        child: ElevatedButton(
                          key: const Key('onboarding_next_button'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () =>
                              context.read<OnboardingCubit>().nextSlide(),
                          child: Text(
                            state.isLastSlide
                                ? l10n.onboarding.getStarted
                                : l10n.onboarding.next,
                            style: const TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlide({
    required Key key,
    required Key animationKey,
    required String title,
    required String subtitle,
    required String lottieAsset,
    required AnimationController lottieController,
    required String fallbackAsset,
    required bool disableAnimations,
    required ThemeData theme,
    required AppSemanticColors colors,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Bounded relative sizing: tall screens get a larger illustration,
          // short screens stay clear of the copy and footer below.
          final illustrationHeight = (constraints.maxHeight * 0.38).clamp(
            140.0,
            260.0,
          );

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Illustration that replaces the previous "لقمة" wordmark.
              SizedBox(
                key: animationKey,
                width: constraints.maxWidth,
                height: illustrationHeight,
                child: disableAnimations
                    ? Image.asset(
                        fallbackAsset,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                      )
                    : Lottie.asset(
                        lottieAsset,
                        controller: lottieController,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        width: constraints.maxWidth,
                        height: illustrationHeight,
                        // Multi-MB JSON: parse away from the UI isolate.
                        backgroundLoading: true,
                        onLoaded: (composition) {
                          if (!mounted) return;
                          // Use the JSON's own timing instead of the guess made
                          // in initState, then loop smoothly.
                          lottieController.duration = composition.duration;
                          if (!disableAnimations &&
                              !lottieController.isAnimating) {
                            lottieController.repeat();
                          }
                        },
                        errorBuilder: (context, error, stackTrace) {
                          // Never break onboarding if an asset fails to load.
                          return Image.asset(
                            fallbackAsset,
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                          );
                        },
                      ),
              ),
              const SizedBox(height: 32.0),

              // Slide Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.headingText,
                ),
              ),
              const SizedBox(height: 12.0),

              // Slide Subtitle
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.mutedText,
                  height: 1.5,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIndicatorDot({
    required bool isActive,
    required AppSemanticColors colors,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: isActive ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive ? colors.primary : colors.inactiveNavigation,
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }
}

/// Title/subtitle pair for a single onboarding slide.
class _SlideCopy {
  const _SlideCopy({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}
