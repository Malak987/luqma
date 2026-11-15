abstract final class AppSizes {
  /// Widest the auth column grows on tablets / desktop / web.
  static const double authContentMaxWidth = 420;
  static const double authFieldHeight = 52;
  static const double authButtonHeight = 54;
  static const double authLinkHeight = 40;
  static const double socialButtonSize = 52;

  /// Upper bound of the logo width. The logo itself scales down on narrow or
  /// short screens (see `AppLogo`).
  static const double logoMaxWidth = 340;
  static const double iconSmall = 16;
  static const double iconMedium = 20;
  static const double iconLarge = 24;
  static const double touchTarget = 48;

  /// Layout breakpoints (logical pixels).
  static const double compactWidth = 360;
  static const double mediumWidth = 600;
}
