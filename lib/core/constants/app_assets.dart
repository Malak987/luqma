/// Centralized references to bundled assets.
abstract final class AppAssets {
  /// Maroon/gold wordmark, for light backgrounds.
  static const String logoLight = 'assets/brand/luqma_light.png';

  /// Cream/gold wordmark, for dark backgrounds.
  static const String logoDark = 'assets/brand/luqma_dark.png';

  /// Calligraphy animation for light backgrounds (maroon text, gold leaf).
  static const String logoAnimationLight =
      'assets/animations/luqma_logo_light.json';

  /// Calligraphy animation for dark backgrounds (ivory text, gold leaf).
  static const String logoAnimationDark =
      'assets/animations/luqma_logo_dark.json';

  /// Onboarding slide 1 illustration — "Discover delicious food".
  static const String onboardingDiscoverAnimation =
      'assets/animations/burger_premium_lottie.json';

  /// Onboarding slide 2 illustration — "Easy and smooth ordering".
  static const String onboardingOrderingAnimation =
      'assets/animations/02_easy_ordering.json';

  /// Onboarding slide 3 illustration — "Premium food quality and taste".
  static const String onboardingPremiumTasteAnimation =
      'assets/animations/03_premium_taste.json';

  /// Per-slide onboarding illustrations, indexed by slide.
  static const List<String> onboardingAnimations = [
    onboardingDiscoverAnimation,
    onboardingOrderingAnimation,
    onboardingPremiumTasteAnimation,
  ];

  static const String apple = 'assets/brand/apple.svg';
  static const String facebook = 'assets/brand/facebook.svg';
  static const String google = 'assets/brand/google.svg';
}
