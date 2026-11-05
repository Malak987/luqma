import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';

/// Independent Splash Screen that plays the animated Arabic Luqma logo
/// using Lottie assets on cold application startup.
class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    required this.onSplashCompleted,
    this.minDuration = const Duration(milliseconds: 3000),
    this.maxDuration = const Duration(milliseconds: 5500),
  });

  final VoidCallback onSplashCompleted;
  final Duration minDuration;
  final Duration maxDuration;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _minDurationTimer;
  Timer? _maxDurationTimer;
  bool _hasCompleted = false;
  bool _minDurationReached = false;
  bool _animationFinished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    // Safety fallback timer to prevent infinite splash if animation stalls or fails
    _maxDurationTimer = Timer(widget.maxDuration, _finishSplash);

    // Minimum duration timer for visual polish
    _minDurationTimer = Timer(widget.minDuration, () {
      if (mounted) {
        _minDurationReached = true;
        _checkAndComplete();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) {
      // If Reduce Motion is enabled, complete after minDurationTimer or maxDurationTimer
      _minDurationReached = true;
      _animationFinished = true;
      _checkAndComplete();
    }
  }

  @override
  void dispose() {
    _minDurationTimer?.cancel();
    _maxDurationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onAnimationFinished() {
    if (mounted) {
      _animationFinished = true;
      _checkAndComplete();
    }
  }

  void _checkAndComplete() {
    if (_minDurationReached && _animationFinished) {
      _finishSplash();
    }
  }

  void _finishSplash() {
    if (!mounted || _hasCompleted) return;
    _hasCompleted = true;
    _minDurationTimer?.cancel();
    _maxDurationTimer?.cancel();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onSplashCompleted();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    final colors = theme.extension<AppSemanticColors>() ??
        (isDark ? AppSemanticColors.dark : AppSemanticColors.light);

    final lottieAsset =
        isDark ? AppAssets.logoAnimationDark : AppAssets.logoAnimationLight;
    final fallbackAsset = isDark ? AppAssets.logoDark : AppAssets.logoLight;

    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive width (82% of screen width bounded between 280.0 and 480.0)
    final logoWidth = (screenWidth * 0.82).clamp(280.0, 480.0);
    // Aspect ratio 1659:948 (~1.75 : 1)
    const aspectRatio = 1659 / 948;
    final logoHeight = logoWidth / aspectRatio;

    return Scaffold(
      key: const Key('splash_screen'),
      backgroundColor: colors.background,
      body: Center(
        child: SizedBox(
          key: const Key('splash_logo_container'),
          width: logoWidth,
          height: logoHeight,
          child: disableAnimations
              ? Image.asset(
                  fallbackAsset,
                  key: const Key('splash_static_logo'),
                  fit: BoxFit.contain,
                  width: logoWidth,
                  height: logoHeight,
                )
              : Lottie.asset(
                  lottieAsset,
                  key: const Key('splash_lottie_animation'),
                  controller: _controller,
                  fit: BoxFit.contain,
                  width: logoWidth,
                  height: logoHeight,
                  onLoaded: (composition) {
                    _controller.duration = composition.duration;
                    // Force start from frame 0 explicitly to show complete "لقمة" animation
                    _controller.forward(from: 0.0).then((_) {
                      _onAnimationFinished();
                    });
                  },
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to static logo on load failure — mark animation
                    // as finished so minDuration (3s) is sufficient, not max 5.5s
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _onAnimationFinished();
                    });
                    return Image.asset(
                      fallbackAsset,
                      key: const Key('splash_static_logo'),
                      fit: BoxFit.contain,
                      width: logoWidth,
                      height: logoHeight,
                    );
                  },
                ),
        ),
      ),
    );
  }
}
