import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';

/// Onboarding page featuring Lottie JSON animations, page indicators,
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
  late final AnimationController _lottieController;

  @override
  void initState() {
    super.initState();
    final initialIndex = context.read<OnboardingCubit>().state.currentIndex;
    _pageController = PageController(initialPage: initialIndex);

    _lottieController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) {
      if (_lottieController.isAnimating) {
        _lottieController.stop();
      }
    } else {
      if (!_lottieController.isAnimating) {
        _lottieController.repeat();
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _lottieController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppSemanticColors>() ??
        (theme.brightness == Brightness.dark
            ? AppSemanticColors.dark
            : AppSemanticColors.light);

    final isDark = theme.brightness == Brightness.dark;
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    final lottieAsset =
        isDark ? AppAssets.logoAnimationDark : AppAssets.logoAnimationLight;
    final fallbackImageAsset =
        isDark ? AppAssets.logoDark : AppAssets.logoLight;
    final l10n = AppLocalizations.of(context).onboarding;

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
                          tooltip: l10n.back,
                        )
                      else
                        const SizedBox.shrink(),
                      TextButton(
                        key: const Key('onboarding_skip_button'),
                        onPressed: () =>
                            context.read<OnboardingCubit>().skipOnboarding(),
                        child: Text(
                          l10n.skip,
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
                  child: PageView(
                    key: const Key('onboarding_page_view'),
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    children: [
                      _buildSlide(
                        key: const Key('onboarding_slide_0'),
                        context: context,
                        title: l10n.slide1Title,
                        subtitle: l10n.slide1Subtitle,
                        lottieAsset: lottieAsset,
                        fallbackAsset: fallbackImageAsset,
                        disableAnimations: disableAnimations,
                        theme: theme,
                        colors: colors,
                      ),
                      _buildSlide(
                        key: const Key('onboarding_slide_1'),
                        context: context,
                        title: l10n.slide2Title,
                        subtitle: l10n.slide2Subtitle,
                        lottieAsset: lottieAsset,
                        fallbackAsset: fallbackImageAsset,
                        disableAnimations: disableAnimations,
                        theme: theme,
                        colors: colors,
                      ),
                      _buildSlide(
                        key: const Key('onboarding_slide_2'),
                        context: context,
                        title: l10n.slide3Title,
                        subtitle: l10n.slide3Subtitle,
                        lottieAsset: lottieAsset,
                        fallbackAsset: fallbackImageAsset,
                        disableAnimations: disableAnimations,
                        theme: theme,
                        colors: colors,
                      ),
                    ],
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
                            state.isLastSlide ? l10n.getStarted : l10n.next,
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
    required BuildContext context,
    required String title,
    required String subtitle,
    required String lottieAsset,
    required String fallbackAsset,
    required bool disableAnimations,
    required ThemeData theme,
    required AppSemanticColors colors,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animation / Image presentation container
          Container(
            key: const Key('onboarding_lottie_animation'),
            height: 220.0,
            width: double.infinity,
            alignment: Alignment.center,
            child: disableAnimations
                ? Image.asset(
                    fallbackAsset,
                    fit: BoxFit.contain,
                    height: 180.0,
                  )
                : Lottie.asset(
                    lottieAsset,
                    controller: _lottieController,
                    fit: BoxFit.contain,
                    height: 200.0,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        fallbackAsset,
                        fit: BoxFit.contain,
                        height: 180.0,
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
