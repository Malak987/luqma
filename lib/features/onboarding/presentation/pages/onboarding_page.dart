import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';

/// Onboarding screen: one persistent scaffold whose header (Skip / back) and
/// footer (page dots + primary button) never move, with a [PageView] between
/// them that only swaps the illustration and copy.
///
/// Only the slide content is paginated, so swiping animates the artwork and the
/// text while the chrome stays mounted — no reload, no flicker, no jump.
///
/// Accessibility: when the platform requests reduced motion the illustration is
/// frozen on its first frame instead of looping.
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
  /// Visible artwork aspect ratio (width / height) per composition. Values come
  /// from the trimmed `_content` files, so the box hugs the drawing.
  static const Map<String, double> _artworkAspectRatios = {
    'assets/animations/burger_premium_lottie_content.json': 331 / 246,
    'assets/animations/02_easy_ordering_content.json': 463 / 420,
    'assets/animations/03_premium_taste_content.json': 361 / 306,
  };

  late final PageController _pageController;

  /// One controller per slide, created once for the lifetime of the screen so
  /// each illustration keeps its own progress and never restarts on a swipe.
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

  /// Keeps the pager in sync when the index changes from the button, without
  /// touching the controller instance or the mounted pages.
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
    // Static wordmark only acts as a safety fallback if an asset fails to load.
    final fallbackImageAsset =
        isDark ? AppAssets.logoDark : AppAssets.logoLight;
    final l10n = AppLocalizations.of(context);
    final slides = _slideCopy(l10n);
    // Very short phones get tighter chrome so the primary button always stays
    // inside the safe area.
    final isCompact = MediaQuery.sizeOf(context).height < 700.0;

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
                // ---------------- persistent header ----------------
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: isCompact ? 2.0 : 8.0,
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

                // ---------------- paginated content ----------------
                // Only the illustration and the copy scroll horizontally.
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
                        isCompact: isCompact,
                      );
                    },
                  ),
                ),

                // ---------------- persistent footer ----------------
                _buildFooter(
                  state: state,
                  l10n: l10n,
                  colors: colors,
                  isCompact: isCompact,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter({
    required OnboardingState state,
    required AppLocalizations l10n,
    required AppSemanticColors colors,
    required bool isCompact,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24.0,
        isCompact ? 10.0 : 14.0,
        24.0,
        isCompact ? 8.0 : 16.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page indicator dots — animate width/colour, never re-created.
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
          SizedBox(height: isCompact ? 10.0 : 14.0),
          SizedBox(
            width: double.infinity,
            height: isCompact ? 48.0 : 52.0,
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
              onPressed: () => context.read<OnboardingCubit>().nextSlide(),
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
    required bool isCompact,
  }) {
    final gutter = isCompact ? 20.0 : 24.0;

    return MediaQuery.withClampedTextScaling(
      // Keeps the fixed-height slide safe under extreme accessibility text
      // scaling so it never overflows.
      maxScaleFactor: 1.3,
      child: Column(
        key: key,
        // The illustration + copy group is centred as one block, so leftover
        // height becomes balanced breathing room instead of a gap under the
        // header.
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. Illustration — no text gutter, and as large as the available
          // width/height allow. With the trimmed compositions the drawn
          // artwork itself, not just its box, becomes this large.
          // Flexible: it may consume all remaining height (the copy is laid
          // out first), while LayoutBuilder keeps the artwork proportional and
          // never taller than the space actually available.
          Flexible(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final aspect = _aspectRatioFor(lottieAsset);
                final width = math.min(
                  constraints.maxWidth,
                  constraints.maxHeight * aspect,
                );
                return SizedBox(
                  key: animationKey,
                  width: width,
                  height: width / aspect,
                  child: _buildIllustration(
                    lottieAsset: lottieAsset,
                    lottieController: lottieController,
                    fallbackAsset: fallbackAsset,
                    disableAnimations: disableAnimations,
                  ),
                );
              },
            ),
          ),

          // 2. Title — directly beneath the illustration.
          Padding(
            padding: EdgeInsets.only(
              top: isCompact ? 4.0 : 8.0,
              left: gutter,
              right: gutter,
            ),
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.headingText,
                height: 1.25,
              ),
            ),
          ),

          // 3. Subtitle — last item of the paginated area; dots and button
          // live in the fixed footer directly below.
          Padding(
            padding: EdgeInsets.only(top: 6.0, left: gutter, right: gutter),
            child: Text(
              subtitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.mutedText,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Native aspect ratio of the (already trimmed) composition, so the artwork
  /// can be given an exact box instead of relying on intrinsic sizing.
  double _aspectRatioFor(String asset) {
    return _artworkAspectRatios[asset] ?? (331 / 246);
  }

  Widget _buildIllustration({
    required String lottieAsset,
    required AnimationController lottieController,
    required String fallbackAsset,
    required bool disableAnimations,
  }) {
    if (disableAnimations) {
      return Image.asset(
        fallbackAsset,
        fit: BoxFit.contain,
        alignment: Alignment.center,
      );
    }

    return Lottie.asset(
      lottieAsset,
      controller: lottieController,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      // Multi-MB JSON: parse away from the UI isolate.
      backgroundLoading: true,
      onLoaded: (composition) {
        if (!mounted) return;
        // Use the JSON's own timing instead of the guess made in initState,
        // then loop smoothly.
        lottieController.duration = composition.duration;
        if (!disableAnimations && !lottieController.isAnimating) {
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
