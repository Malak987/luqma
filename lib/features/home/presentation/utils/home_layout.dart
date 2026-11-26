import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';

/// Widest the Home content column grows on tablets, desktop and web.
///
/// The header background stays edge to edge at every width; only its content is
/// constrained to this column, so on a wide screen the greeting and the search
/// field line up with the sections below them.
const double homeContentMaxWidth = 1120;

/// Horizontal padding shared by the Home header content and the scroll view
/// below it, so the search field and every section start on the same edge at
/// any width.
double homeHorizontalPadding(double width) {
  if (width < AppSizes.compactWidth) return AppSpacing.md;
  if (width < AppSizes.mediumWidth) return AppSpacing.xl;
  return AppSpacing.xxl;
}
