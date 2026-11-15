import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/services/app_readiness_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Independent Splash Screen that plays the animated Arabic Luqma logo
/// using Lottie assets on cold application startup, synchronizing full
/// animation playback with background application readiness.
class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    required this.onSplashCompleted,
    this.readinessTask,
    this.safetyTimeout = const Duration(seconds: 10),
  });

  final VoidCallback onSplashCompleted;

  /// Optional custom readiness task (defaults to [AppReadinessService.prepareApp]).
  final Future<void> Function(BuildContext context)? readinessTask;

  /// Maximum safety timeout to detect stuck tasks without bypassing readiness.
  final Duration safetyTimeout;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _safetyTimeoutTimer;

  int _readinessRequestId = 0;
  bool _isAnimationCompleted = false;
  bool _isAppReady = false;
  bool _hasCriticalError = false;
  String? _errorMessage;
  bool _hasTransitioned = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    // Safety timeout to flag stuck initialization without bypassing readiness
    _safetyTimeoutTimer = Timer(widget.safetyTimeout, _onSafetyTimeout);

    // Start background app readiness task
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startAppReadiness();
      }
    });
  }

  void _onSafetyTimeout() {
    if (mounted && !_isAppReady && !_hasTransitioned) {
      setState(() {
        _hasCriticalError = true;
        _errorMessage = 'استغرق تحضير التطبيق وقتًا أطول من المتوقع.';
      });
    }
  }

  Future<void> _startAppReadiness() async {
    if (_hasTransitioned) return;

    final requestId = ++_readinessRequestId;

    setState(() {
      _hasCriticalError = false;
      _errorMessage = null;
    });

    try {
      if (widget.readinessTask != null) {
        await widget.readinessTask!(context);
      } else {
        await AppReadinessService.prepareApp(context);
      }

      if (mounted && requestId == _readinessRequestId) {
        _isAppReady = true;
        _checkAndTransition();
      }
    } catch (e, stackTrace) {
      debugPrint('SplashPage readiness error: $e\n$stackTrace');
      if (mounted && requestId == _readinessRequestId) {
        setState(() {
          _hasCriticalError = true;
          _errorMessage = 'تعذر تحضير بيانات التطبيق الرئيسية.';
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) {
      // If Reduce Motion is enabled, mark animation completed
      _isAnimationCompleted = true;
      _checkAndTransition();
    }
  }

  @override
  void dispose() {
    _safetyTimeoutTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onAnimationFinished() {
    if (mounted) {
      _isAnimationCompleted = true;
      _checkAndTransition();
    }
  }

  void _checkAndTransition() {
    if (!mounted || _hasTransitioned || _hasCriticalError) return;
    // Condition A (Animation Completed) AND Condition B (App Ready)
    if (_isAnimationCompleted && _isAppReady) {
      _finishSplash();
    }
  }

  void _finishSplash() {
    if (!mounted || _hasTransitioned) return;
    _hasTransitioned = true;
    _safetyTimeoutTimer?.cancel();

    if (WidgetsBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onSplashCompleted();
        }
      });
    } else {
      widget.onSplashCompleted();
    }
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

    final showErrorUI = _hasCriticalError &&
        (_isAnimationCompleted || disableAnimations) &&
        !_hasTransitioned;

    return Scaffold(
      key: const Key('splash_screen'),
      backgroundColor: colors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
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
                        // Force start from frame 0 explicitly to play complete animation
                        _controller.forward(from: 0.0).then((_) {
                          _onAnimationFinished();
                        });
                      },
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to static logo on load failure
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
            if (showErrorUI) ...[
              const SizedBox(height: 24.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  _errorMessage ?? 'تعذر تحميل البيانات',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.mutedText,
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton.icon(
                key: const Key('splash_retry_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 12.0,
                  ),
                ),
                onPressed: _startAppReadiness,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
