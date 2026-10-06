import 'app_elevation.dart';
import 'app_radius.dart';
import 'app_sizes.dart';
import 'app_spacing.dart';

/// Named entry point for the shared design-token modules.
abstract final class AppDesignTokens {
  static const double spaceXxs = AppSpacing.xxs;
  static const double spaceXs = AppSpacing.xs;
  static const double spaceSm = AppSpacing.sm;
  static const double spaceMd = AppSpacing.md;
  static const double spaceLg = AppSpacing.lg;
  static const double spaceXl = AppSpacing.xl;
  static const double spaceXxl = AppSpacing.xxl;
  static const double spaceXxxl = AppSpacing.xxxl;
  static const double authMaxWidth = AppSizes.authContentMaxWidth;
  static const double authFieldHeight = AppSizes.authFieldHeight;
  static const double authButtonHeight = AppSizes.authButtonHeight;
  static const double authLinkHeight = AppSizes.authLinkHeight;
  static const double socialButtonSize = AppSizes.socialButtonSize;
  static const double radiusSmall = AppRadius.small;
  static const double radiusMedium = AppRadius.medium;
  static const double radiusLarge = AppRadius.large;
  static const double radiusPill = AppRadius.pill;
  static const double elevationNone = AppElevation.none;
  static const double elevationSubtle = AppElevation.subtle;
  static const double elevationCard = AppElevation.card;
  static const double elevationFloating = AppElevation.floating;
}
