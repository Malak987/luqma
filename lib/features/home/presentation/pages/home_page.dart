import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../authentication/presentation/cubit/auth_session_cubit.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_categories.dart';
import '../widgets/home_restaurants_section.dart';
import '../widgets/home_search_bar.dart';

/// The home shell: header, search entry point and the two data-backed sections.
///
/// The page owns no data logic. [HomeCubit] loads what the screen needs and the
/// sections render that state; signing out reuses [AuthSessionCubit], so the
/// app-level auth switch (see `app.dart`) turns the screen back into login.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Widest the home column grows on tablets, desktop and web.
  static const double _contentMaxWidth = 1120;
  static const double _errorActionWidth = 220;

  @override
  void initState() {
    super.initState();
    context.read<HomeCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: colors.background,
          appBar: HomeAppBar(
            userName: state.userName,
            onLogoutPressed: _confirmLogout,
          ),
          body: SafeArea(top: false, child: _bodyFor(context, state)),
        );
      },
    );
  }

  Widget _bodyFor(BuildContext context, HomeState state) {
    switch (state.status) {
      case HomeStatus.initial:
      case HomeStatus.loading:
        return Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      case HomeStatus.failure:
        return _buildErrorView(context);
      case HomeStatus.loaded:
        return _buildContent(context, state);
    }
  }

  Widget _buildContent(BuildContext context, HomeState state) {
    final l10n = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
              child: Padding(
                padding: _paddingFor(constraints),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    HomeSearchBar(
                      hintText: l10n.home.searchHint,
                      onSubmitted: (_) => _showSearchUnavailable(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    HomeCategories(categories: state.categories),
                    const SizedBox(height: AppSpacing.xl),
                    HomeRestaurantsSection(restaurants: state.restaurants),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorView(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.error_outline,
              size: AppSizes.iconLarge,
              color: colors.mutedText,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.home.loadFailed,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: _errorActionWidth,
              child: AppButton(text: l10n.home.retry, onPressed: _retry),
            ),
          ],
        ),
      ),
    );
  }

  /// Responsive page padding, mirroring the breakpoints the auth shell uses.
  EdgeInsets _paddingFor(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final horizontal = width < AppSizes.compactWidth
        ? AppSpacing.md
        : width < AppSizes.mediumWidth
            ? AppSpacing.xl
            : AppSpacing.xxl;

    return EdgeInsets.symmetric(
        horizontal: horizontal, vertical: AppSpacing.lg);
  }

  void _retry() {
    context.read<HomeCubit>().load();
  }

  void _showSearchUnavailable() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).home.searchUnavailable),
        ),
      );
  }

  Future<void> _confirmLogout() async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.home.logoutConfirmTitle),
          content: Text(l10n.home.logoutConfirmMessage),
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
              child: Text(l10n.home.logout),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    // Signing out is entirely the session cubit's job: the app-level auth
    // switch reacts to the unauthenticated state and shows login again, so the
    // screen never navigates by itself. The dialog's own pop is the only route
    // change this screen ever performs.
    await context.read<AuthSessionCubit>().logout();
  }
}
