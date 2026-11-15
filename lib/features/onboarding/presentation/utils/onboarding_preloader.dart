import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/constants/app_assets.dart';

/// Preloads onboarding Lottie compositions and fallback images in the background,
/// prioritizing Slide 1 so that entering Onboarding feels instant and smooth.
abstract final class OnboardingPreloader {
  static final Set<String> _preloadedAssets = <String>{};
  static final Map<String, Future<void>> _inFlightPreloads =
      <String, Future<void>>{};

  @visibleForTesting
  static void resetForTest() {
    _preloadedAssets.clear();
    _inFlightPreloads.clear();
  }

  /// Precaches fallback logo images.
  static Future<void> preloadFallbackImages(BuildContext context) async {
    try {
      if (context.mounted) {
        unawaited(
            precacheImage(const AssetImage(AppAssets.logoLight), context));
        unawaited(precacheImage(const AssetImage(AppAssets.logoDark), context));
      }
    } catch (_) {}
  }

  /// Preloads Slide 1 Lottie composition and schedules background preloading for subsequent slides.
  static Future<void> preloadSlide1(BuildContext context) async {
    await preloadFallbackImages(context);

    const animations = AppAssets.onboardingAnimations;
    if (animations.isNotEmpty) {
      await _preloadLottieAsset(animations[0]);
    }

    // Optional progressive background preload for Slide 2 and Slide 3
    if (animations.length > 1) {
      Future.microtask(() async {
        for (var i = 1; i < animations.length; i++) {
          await _preloadLottieAsset(animations[i]);
        }
      });
    }
  }

  /// Asynchronously preloads all onboarding assets.
  static Future<void> preloadOnboardingAssets(BuildContext context) async {
    await preloadSlide1(context);
  }

  static Future<void> _preloadLottieAsset(String assetPath) async {
    if (_preloadedAssets.contains(assetPath)) return;

    // Deduplicate in-flight preload requests for the same asset
    if (_inFlightPreloads.containsKey(assetPath)) {
      await _inFlightPreloads[assetPath];
      return;
    }

    final future = _loadAssetInternal(assetPath);
    _inFlightPreloads[assetPath] = future;

    // Non-blocking background preload: do not block critical readiness
    unawaited(future.whenComplete(() {
      _inFlightPreloads.remove(assetPath);
    }));
  }

  static Future<void> _loadAssetInternal(String assetPath) async {
    try {
      final provider = AssetLottie(assetPath);
      await provider.load();
      _preloadedAssets.add(assetPath);
    } catch (_) {
      // Safe error handling: failure to preload does not crash or block the app.
      // Do NOT add to _preloadedAssets so a later retry can attempt again.
    }
  }
}
