/// Centralized references to assets that can be supplied by product branding.
///
/// The first screen renders its wordmark as text for crisp scaling. Keeping
/// these paths in one place lets a production SVG/image implementation be
/// introduced without leaking asset paths into feature widgets.
abstract final class AppAssets {
  static const String logo = 'assets/brand/luqma_logo.svg';
  static const String apple = 'assets/brand/apple.svg';
  static const String facebook = 'assets/brand/facebook.svg';
  static const String google = 'assets/brand/google.svg';
}
