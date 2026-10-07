import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/constants/app_constants.dart';
 import '../core/localization/app_localizations.dart';
import '../core/presentation/cubit/app_settings_cubit.dart';
import '../core/presentation/cubit/app_settings_state.dart';
import '../core/routing/app_router.dart';
 import '../core/theme/app_theme.dart';
import '../features/authentication/login/presentation/cubit/login_cubit.dart';
import '../features/authentication/login/presentation/pages/login_page.dart';
import '../features/authentication/presentation/cubit/auth_session_cubit.dart';
import '../features/authentication/presentation/cubit/auth_session_state.dart';
import '../core/di/service_locator.dart';

class LuqmaApp extends StatefulWidget {
  const LuqmaApp({super.key});

  @override
  State<LuqmaApp> createState() => _LuqmaAppState();
}

class _LuqmaAppState extends State<LuqmaApp> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<AuthSessionCubit>().checkSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      buildWhen: (previous, current) => previous != current,
      builder: (context, settings) {
        return MaterialApp(
          title: AppConstants.applicationName,
          debugShowCheckedModeBanner: false,

          // ------------------------------------------------------------
          // Theme
          // ------------------------------------------------------------

          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,

          // ------------------------------------------------------------
          // Localization
          // ------------------------------------------------------------

          locale: settings.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates:
          AppLocalizations.localizationsDelegates,

          localeResolutionCallback: (locale, supportedLocales) {
            final languageCode = locale?.languageCode;

            return supportedLocales.firstWhere(
                  (supported) =>
              supported.languageCode == languageCode,
              orElse: () => supportedLocales.first,
            );
          },

          // ------------------------------------------------------------
          // Routing
          // ------------------------------------------------------------

          onGenerateRoute: AppRouter.onGenerateRoute,

          // ------------------------------------------------------------
          // Initial screen
          // ------------------------------------------------------------

          home: BlocBuilder<AuthSessionCubit, AuthSessionState>(
            buildWhen: (previous, current) =>
            previous.status != current.status,
            builder: (context, authState) {
              switch (authState.status) {
                case AuthSessionStatus.initial:
                case AuthSessionStatus.checking:
                  return const _AuthLoadingScreen();

                case AuthSessionStatus.unauthenticated:
                  return BlocProvider<LoginCubit>(
                    create: (_) => sl<LoginCubit>(),
                    child: const LoginPage(),
                  );

                case AuthSessionStatus.authenticated:
                  return const _AuthenticatedHomeScreen();
              }
            },
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Loading Screen
// -----------------------------------------------------------------------------

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: CircularProgressIndicator(
          color: isDark
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Authenticated Home
// -----------------------------------------------------------------------------

class _AuthenticatedHomeScreen extends StatelessWidget {
  const _AuthenticatedHomeScreen();

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context);

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.common.home),
          ),
          body: Center(
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.common.comingSoon,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}