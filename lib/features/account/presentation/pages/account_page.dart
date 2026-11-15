import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/presentation/cubit/app_settings_cubit.dart';
import '../../../../core/presentation/cubit/app_settings_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../authentication/presentation/cubit/auth_session_cubit.dart';

/// Account tab: language, theme and signing out. These controls used to live in
/// the home header; they belong with the account, so Home stays focused.
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;

    return ColoredBox(
      color: colors.background,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: <Widget>[
            Text(
              l10n.account.title,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.account.preferences,
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: colors.mutedText),
            ),
            const SizedBox(height: AppSpacing.xs),
            BlocBuilder<AppSettingsCubit, AppSettingsState>(
              builder: (context, settings) {
                final cubit = context.read<AppSettingsCubit>();
                return Column(
                  children: <Widget>[
                    _AccountTile(
                      key: const Key('account_language_tile'),
                      icon: Icons.language,
                      title: l10n.common.language,
                      subtitle: l10n.account.languageSubtitle,
                      trailing: Text(
                        settings.locale.languageCode == 'ar'
                            ? l10n.common.languageArabic
                            : l10n.common.languageEnglish,
                        style: theme.textTheme.labelLarge
                            ?.copyWith(color: colors.accent),
                      ),
                      onTap: cubit.toggleLocale,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _ThemeTile(
                      mode: settings.themeMode,
                      onChanged: cubit.setThemeMode,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            _AccountTile(
              key: const Key('account_logout_tile'),
              icon: Icons.logout,
              title: l10n.account.logout,
              destructive: true,
              onTap: () => _confirmLogout(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final session = context.read<AuthSessionCubit>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.account.logoutConfirmTitle),
        content: Text(l10n.account.logoutConfirmMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(l10n.account.logout),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    // Signing out is the session cubit's job: the app-level auth switch reacts
    // to the unauthenticated state and shows login again.
    await session.logout();
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({required this.mode, required this.onChanged});

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context).common;
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.brightness_6_outlined, color: colors.headingText),
              const SizedBox(width: AppSpacing.sm),
              Text(l10n.theme, style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              key: const Key('account_theme_selector'),
              showSelectedIcon: false,
              selected: <ThemeMode>{mode},
              onSelectionChanged: (selection) => onChanged(selection.first),
              segments: <ButtonSegment<ThemeMode>>[
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.system,
                  label: Text(l10n.themeSystem),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  label: Text(l10n.themeLight),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  label: Text(l10n.themeDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.destructive = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool destructive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final tint = destructive ? theme.colorScheme.error : colors.headingText;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: tint),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(color: tint),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: colors.mutedText),
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
