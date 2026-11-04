import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/presentation/cubit/app_settings_cubit.dart';
import '../../../../core/presentation/cubit/app_settings_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_elevation.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/semantic_icon_button.dart';

/// Header of the home screen: the Luqma wordmark, the signed-in greeting, theme/language controls, and
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
    final cubit = _findAppSettingsCubit(context);

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
        if (cubit != null)
          BlocBuilder<AppSettingsCubit, AppSettingsState>(
            bloc: cubit,
            builder: (context, settingsState) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SemanticIconButton(
                    icon: Icons.language,
                    tooltip: l10n.common.language,
                    color: colors.headingText,
                    onPressed: () {
                      cubit.toggleLocale();
                    },
                  ),
                  PopupMenuButton<ThemeMode>(
                    icon: Icon(
                      _iconForThemeMode(settingsState.themeMode),
                      color: colors.headingText,
                    ),
                    tooltip: l10n.common.theme,
                    onSelected: (mode) {
                      cubit.setThemeMode(mode);
                    },
                    itemBuilder: (context) => <PopupMenuEntry<ThemeMode>>[
                      PopupMenuItem<ThemeMode>(
                        value: ThemeMode.system,
                        child: Text(l10n.common.themeSystem),
                      ),
                      PopupMenuItem<ThemeMode>(
                        value: ThemeMode.light,
                        child: Text(l10n.common.themeLight),
                      ),
                      PopupMenuItem<ThemeMode>(
                        value: ThemeMode.dark,
                        child: Text(l10n.common.themeDark),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
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

  static AppSettingsCubit? _findAppSettingsCubit(BuildContext context) {
    try {
      return context.read<AppSettingsCubit>();
    } catch (_) {
      if (sl.isRegistered<AppSettingsCubit>()) {
        return sl<AppSettingsCubit>();
      }
      return null;
    }
  }

  static IconData _iconForThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }
}
