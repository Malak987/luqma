import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../address/domain/entities/address.dart';
import '../../../address/presentation/cubit/address_setup_cubit.dart';
import '../../../address/presentation/cubit/address_setup_state.dart';
import '../../../address/presentation/widgets/address_manager_sheet.dart';
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
          children: <Widget>[
            _ProfileHero(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionTitle(l10n.account.overview),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: _OverviewCard(
                                  icon: Icons.phone_outlined,
                                  title: l10n.account.phone,
                                  value: l10n.account.unavailable)),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: _ProfileAddressCard()),
                        ]),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionTitle(l10n.account.accountSection),
                    const SizedBox(height: AppSpacing.sm),
                    _DisabledProfileAction(
                        icon: Icons.person_outline,
                        title: l10n.account.editProfile),
                    const SizedBox(height: AppSpacing.xs),
                    _DisabledProfileAction(
                        icon: Icons.lock_outline,
                        title: l10n.account.changePassword),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionTitle(l10n.account.appearance),
                    const SizedBox(height: AppSpacing.sm),
                    BlocSelector<AppSettingsCubit, AppSettingsState, Locale>(
                      selector: (state) => state.locale,
                      builder: (context, locale) => _AccountTile(
                        key: const Key('account_language_tile'),
                        icon: Icons.language,
                        title: l10n.common.language,
                        subtitle: l10n.account.languageSubtitle,
                        trailing: Text(
                            locale.languageCode == 'ar'
                                ? l10n.common.languageArabic
                                : l10n.common.languageEnglish,
                            style: theme.textTheme.labelLarge
                                ?.copyWith(color: colors.link)),
                        onTap: context.read<AppSettingsCubit>().toggleLocale,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    BlocSelector<AppSettingsCubit, AppSettingsState, ThemeMode>(
                      selector: (state) => state.themeMode,
                      builder: (context, mode) => _ThemeTile(
                          mode: mode,
                          onChanged:
                              context.read<AppSettingsCubit>().setThemeMode),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _AccountTile(
                      key: const Key('account_logout_tile'),
                      icon: Icons.logout,
                      title: l10n.account.logout,
                      destructive: true,
                      onTap: () => _confirmLogout(context),
                    ),
                  ]),
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

class _ProfileHero extends StatefulWidget {
  @override
  State<_ProfileHero> createState() => _ProfileHeroState();
}

class _ProfileHeroState extends State<_ProfileHero> {
  late final Future<String?> _name;
  @override
  void initState() {
    super.initState();
    _name = sl.isRegistered<SecureStorageService>()
        ? sl<SecureStorageService>().getUserName().catchError((_) => null)
        : Future<String?>.value(null);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    final copy = AppLocalizations.of(context).account;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
      decoration: BoxDecoration(
          color: colors.primary,
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(30))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(copy.title,
            style: theme.textTheme.headlineSmall?.copyWith(
                color: colors.onPrimary, fontWeight: FontWeight.w800)),
        const SizedBox(height: AppSpacing.xs),
        Text(copy.profileSubtitle,
            style:
                theme.textTheme.bodyMedium?.copyWith(color: colors.onPrimary)),
        const SizedBox(height: AppSpacing.lg),
        FutureBuilder<String?>(
            future: _name,
            builder: (context, snapshot) {
              final name = snapshot.data?.trim();
              final displayName =
                  name == null || name.isEmpty ? copy.unavailable : name;
              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                    color: colors.onPrimary.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: colors.onPrimary.withValues(alpha: .20))),
                child: Row(children: [
                  CircleAvatar(
                      radius: 34,
                      backgroundColor: colors.onPrimary.withValues(alpha: .18),
                      child: Icon(Icons.person_outline,
                          color: colors.onPrimary, size: 32)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                      child: Text(displayName,
                          style: theme.textTheme.titleLarge?.copyWith(
                              color: colors.onPrimary,
                              fontWeight: FontWeight.w800))),
                ]),
              );
            }),
      ]),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: (Theme.of(context).extension<AppSemanticColors>() ??
                  AppSemanticColors.light)
              .mutedText,
          fontWeight: FontWeight.w700));
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard(
      {required this.icon,
      required this.title,
      required this.value,
      this.onTap});
  final IconData icon;
  final String title, value;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    return Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              constraints: const BoxConstraints(minHeight: 145),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colors.border)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DecoratedBox(
                        decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            child: Icon(icon, color: colors.link))),
                    const SizedBox(height: AppSpacing.lg),
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(value,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: colors.mutedText)),
                  ]),
            )));
  }
}

class _ProfileAddressCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final copy = AppLocalizations.of(context).account;
    AddressSetupCubit? cubit;
    try {
      cubit = context.read<AddressSetupCubit>();
    } catch (_) {
      cubit = null;
    }
    if (cubit == null)
      return _OverviewCard(
          icon: Icons.location_on_outlined,
          title: copy.address,
          value: copy.unavailable);
    return BlocSelector<AddressSetupCubit, AddressSetupState, Address?>(
      bloc: cubit,
      selector: (state) => state.selectedAddress,
      builder: (context, address) => _OverviewCard(
          icon: Icons.location_on_outlined,
          title: copy.address,
          value: address == null
              ? copy.unavailable
              : [address.title, address.city]
                  .where((e) => e.trim().isNotEmpty)
                  .join('، '),
          onTap: () => showAddressManagerSheet(context)),
    );
  }
}

class _DisabledProfileAction extends StatelessWidget {
  const _DisabledProfileAction({required this.icon, required this.title});
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    return Semantics(
        enabled: false,
        child: Opacity(
            opacity: .65,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border.all(color: colors.border),
                  borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                Icon(icon, color: colors.mutedText),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(title),
                      Text(AppLocalizations.of(context).account.unavailable,
                          style: Theme.of(context).textTheme.bodySmall)
                    ])),
                Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_left
                        : Icons.chevron_right,
                    color: colors.mutedText)
              ]),
            )));
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
