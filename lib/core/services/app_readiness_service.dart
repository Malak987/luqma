import 'package:flutter/widgets.dart';

import '../../features/onboarding/presentation/utils/onboarding_preloader.dart';
import '../di/service_locator.dart';
import '../storage/preferences_storage_service.dart';

/// Coordinates background readiness tasks required before transitioning away from Splash Screen.
abstract final class AppReadinessService {
  /// Prepares critical startup resources asynchronously without blocking the UI thread.
  /// Throws if a critical initialization task fails.
  static Future<void> prepareApp(BuildContext context) async {
    final storage = sl<PreferencesStorageService>();
    final hasCompletedOnboarding = storage.getHasCompletedOnboarding();

    if (!hasCompletedOnboarding) {
      // Critical: Destination is Onboarding — prepare Slide 1 Lottie composition & images
      if (context.mounted) {
        await OnboardingPreloader.preloadSlide1(context);
      }
    } else {
      // Destination is Auth / Home — prepare critical fallback assets
      if (context.mounted) {
        await OnboardingPreloader.preloadFallbackImages(context);
      }
    }
  }
}
