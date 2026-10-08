import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_elevation.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/semantic_icon_button.dart';

/// Header of the home screen: the Luqma wordmark, the signed-in greeting and
/// the sign-out action.
///
/// The bar only reports the tap; the page owns the confirmation flow and the
/// `AuthSessionCubit` call, so no second logout path is introduced here.
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({
    required this.userName,
    required this.onLogoutPressed,
    super.key,
  });

  static const double _toolbarHeight = 76;
  static const double _logoMaxWidth = 92;

  /// Display name of the signed-in user; null renders a name-less greeting.
  final String? userName;

  final VoidCallback onLogoutPressed;

  @override
  Size get preferredSize => const Size.fromHeight(_toolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;

    return AppBar(
      backgroundColor: colors.background,
      surfaceTintColor: Colors.transparent,
      foregroundColor: colors.headingText,
      elevation: AppElevation.none,
      toolbarHeight: _toolbarHeight,
      titleSpacing: AppSpacing.lg,
      title: Row(
        children: <Widget>[
          AppLogo(
            semanticLabel: l10n.common.brandName,
            maxWidth: _logoMaxWidth,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              l10n.home.greeting(userName),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
          ),
        ],
      ),
      actions: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
          child: SemanticIconButton(
            icon: Icons.logout,
            tooltip: l10n.home.logout,
            color: colors.headingText,
            onPressed: onLogoutPressed,
          ),
        ),
      ],
    );
  }
}
